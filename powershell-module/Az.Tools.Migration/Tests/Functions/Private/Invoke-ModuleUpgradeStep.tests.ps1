Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Invoke-ModuleUpgradeStep tests' {
        It 'Should be able to update a cmdlet reference in place' {
            # arrange
            $scriptBuilder = New-Object -TypeName System.Text.StringBuilder
            $null = $scriptBuilder.AppendLine("Write-host 'test'")
            $null = $scriptBuilder.AppendLine("Set-AzureRmWebApp -ResourceGroupName 'Default-Web-WestUS' ``")
            $null = $scriptBuilder.AppendLine("     -Name 'ContosoWebApp' ``")
            $null = $scriptBuilder.AppendLine("     -HttpLoggingEnabled `$true")

            $expectedBuilder = New-Object -TypeName System.Text.StringBuilder
            $null = $expectedBuilder.AppendLine("Write-host 'test'")
            $null = $expectedBuilder.AppendLine("Set-AzWebApp -ResourceGroupName 'Default-Web-WestUS' ``")
            $null = $expectedBuilder.AppendLine("     -Name 'ContosoWebApp' ``")
            $null = $expectedBuilder.AppendLine("     -HttpLoggingEnabled `$true")

            $step = New-Object -TypeName UpgradePlan
            $step.UpgradeType = [UpgradeStepType]::Cmdlet
            $step.Original = "Set-AzureRmWebApp"
            $step.Replacement = "Set-AzWebApp"
            $step.Location = "test.ps1:2:0"
            $step.SourceCommand = New-Object -TypeName CommandReference
            $step.SourceCommand.StartOffset = 19
            $step.SourceCommand.EndOffset = 36

            # act
            Invoke-ModuleUpgradeStep -Step $step -FileContent $scriptBuilder

            # assert
            $scriptBuilder.ToString() | Should Be $expectedBuilder.ToString()
        }
        It 'Should be able to update a cmdlet parameter reference in place' {
            # arrange
            $scriptBuilder = New-Object -TypeName System.Text.StringBuilder
            $null = $scriptBuilder.AppendLine("Write-host 'test'")
            $null = $scriptBuilder.AppendLine("Set-AzWebApp -ResourceGroupName 'Default-Web-WestUS' ``")
            $null = $scriptBuilder.AppendLine("     -Name 'ContosoWebApp' ``")
            $null = $scriptBuilder.AppendLine("     -HttpLoggingEnabled `$true")

            $expectedBuilder = New-Object -TypeName System.Text.StringBuilder
            $null = $expectedBuilder.AppendLine("Write-host 'test'")
            $null = $expectedBuilder.AppendLine("Set-AzWebApp -ResourceGroupName 'Default-Web-WestUS' ``")
            $null = $expectedBuilder.AppendLine("     -AppName 'ContosoWebApp' ``")
            $null = $expectedBuilder.AppendLine("     -HttpLoggingEnabled `$true")

            $step = New-Object -TypeName UpgradePlan
            $step.UpgradeType = [UpgradeStepType]::CmdletParameter

            # Set-AzWebApp doesn't use the 'AppName' parameter...
            # so provide a fake/test replacement to exercise the code.
            $step.Original = "Name"
            $step.Replacement = "AppName"

            $step.Location = "test.ps1:3:5"
            $step.SourceCommandParameter = New-Object -TypeName CommandReferenceParameter
            $step.SourceCommandParameter.StartOffset = 80
            $step.SourceCommandParameter.EndOffset = 85

            # act
            Invoke-ModuleUpgradeStep -Step $step -FileContent $scriptBuilder

            # assert
            $scriptBuilder.ToString() | Should Be $expectedBuilder.ToString()
        }
        It 'Should not update a cmdlet reference if the string offset does not match' {
            # arrange
            $scriptBuilder = New-Object -TypeName System.Text.StringBuilder
            $null = $scriptBuilder.AppendLine("Write-host 'test'")
            $null = $scriptBuilder.AppendLine("Set-AzureRmWebApp -ResourceGroupName 'Default-Web-WestUS' ``")
            $null = $scriptBuilder.AppendLine("     -Name 'ContosoWebApp' ``")
            $null = $scriptBuilder.AppendLine("     -HttpLoggingEnabled `$true")

            $step = New-Object -TypeName UpgradePlan
            $step.UpgradeType = [UpgradeStepType]::Cmdlet
            $step.Original = "Set-AzureRmWebApp"
            $step.Replacement = "Set-AzWebApp"
            $step.Location = "test.ps1:2:0"
            $step.SourceCommand = New-Object -TypeName CommandReference
            $step.SourceCommand.StartOffset = 19
            $step.SourceCommand.EndOffset = 36

            # act
            Invoke-ModuleUpgradeStep -Step $step -FileContent $scriptBuilder

            # assert (second attempt should throw since it has already been upgraded)
            { Invoke-ModuleUpgradeStep -Step $step -FileContent $scriptBuilder } | Should Throw "Upgrade step failed: Offset positions"
        }
        It 'Should not update a cmdlet parameter reference if the string offset does not match' {
            # arrange
            $scriptBuilder = New-Object -TypeName System.Text.StringBuilder
            $null = $scriptBuilder.AppendLine("Write-host 'test'")
            $null = $scriptBuilder.AppendLine("Set-AzWebApp -ResourceGroupName 'Default-Web-WestUS' ``")
            $null = $scriptBuilder.AppendLine("     -Name 'ContosoWebApp' ``")
            $null = $scriptBuilder.AppendLine("     -HttpLoggingEnabled `$true")

            $step = New-Object -TypeName UpgradePlan
            $step.UpgradeType = [UpgradeStepType]::CmdletParameter

            # Set-AzWebApp doesn't use the 'AppName' parameter...
            # so provide a fake/test replacement to exercise the code.
            $step.Original = "Name"
            $step.Replacement = "AppName"

            $step.Location = "test.ps1:3:5"
            $step.SourceCommandParameter = New-Object -TypeName CommandReferenceParameter
            $step.SourceCommandParameter.StartOffset = 80
            $step.SourceCommandParameter.EndOffset = 85

            # act
            Invoke-ModuleUpgradeStep -Step $step -FileContent $scriptBuilder

            # assert (second attempt should throw since it has already been upgraded)
            { Invoke-ModuleUpgradeStep -Step $step -FileContent $scriptBuilder } | Should Throw "Upgrade step failed: Offset positions"
        }
    }
}
