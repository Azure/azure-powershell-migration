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

            $step = New-Object -TypeName CmdletUpgradeStep
            $step.FileName = "test.ps1"
            $step.StartLine = "2"
            $step.StartColumn = "0"
            $step.StartOffset = "19"
            $step.EndOffset = "36"
            $step.OriginalCmdletName = "Set-AzureRmWebApp"
            $step.ReplacementCmdletName = "Set-AzWebApp"

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

            $step = New-Object -TypeName CmdletParameterUpgradeStep
            $step.FileName = "test.ps1"
            $step.StartLine = "3"
            $step.StartColumn = "5"
            $step.StartOffset = "80"
            $step.EndOffset = "85"

            # Set-AzWebApp doesn't use the 'AppName' parameter...
            # so provide a fake/test replacement to exercise the code.
            $step.OriginalParameterName = "Name"
            $step.ReplacementParameterName = "AppName"

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

            $step = New-Object -TypeName CmdletUpgradeStep
            $step.FileName = "test.ps1"
            $step.StartLine = "2"
            $step.StartColumn = "0"
            $step.StartOffset = "19"
            $step.EndOffset = "36"
            $step.OriginalCmdletName = "Set-AzureRmWebApp"
            $step.ReplacementCmdletName = "Set-AzWebApp"

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

            $step = New-Object -TypeName CmdletParameterUpgradeStep
            $step.FileName = "test.ps1"
            $step.StartLine = "3"
            $step.StartColumn = "5"
            $step.StartOffset = "80"
            $step.EndOffset = "85"

            # Set-AzWebApp doesn't use the 'AppName' parameter...
            # so provide a fake/test replacement to exercise the code.
            $step.OriginalParameterName = "Name"
            $step.ReplacementParameterName = "AppName"

            # act
            Invoke-ModuleUpgradeStep -Step $step -FileContent $scriptBuilder

            # assert (second attempt should throw since it has already been upgraded)
            { Invoke-ModuleUpgradeStep -Step $step -FileContent $scriptBuilder } | Should Throw "Upgrade step failed: Offset positions"
        }
    }
}
