Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Invoke-AzUpgradeModulePlan tests' {
        It 'Should immediately return if no upgrade steps are provided' {
            # arrange
            $plan = New-Object -TypeName UpgradePlan

            # act
            # this should not produce any output at all.
            $results = Invoke-AzUpgradeModulePlan -Plan $plan

            # assert
            $results | Should Be $null
        }
        It 'Should be able to execute an update plan (single-file)' {
            # arrange
            $step = New-Object -TypeName CmdletUpgradeStep
            $step.FileName = "mock-file.ps1"
            $step.FullPath = "C:\mock-file.ps1"
            $step.OriginalCmdletName = "Login-AzureRmAccount"
            $step.ReplacementCmdletName = "Login-AzAccount"

            $plan = New-Object -TypeName UpgradePlan
            $plan.UpgradeSteps.Add($step)

            Mock -CommandName Invoke-ModuleUpgradeStep -ModuleName Az.Tools.Migration -MockWith { } -Verifiable
            Mock -CommandName Get-Content -MockWith { return "mock-file-contents" } -Verifiable
            Mock -CommandName Set-Content -MockWith { } -Verifiable

            # act
            $result = Invoke-AzUpgradeModulePlan -Plan $plan -Confirm:$false

            # assert
            $result | Should Not Be $null
            $result.Count | Should Be 1
            $result.GetType().FullName | Should Be 'UpgradeResult'
            $result.Success | Should Be $true
            $result.Reason | Should Not Be $null

            Assert-VerifiableMock
        }
        It 'Should be able to execute an update plan (multi-file)' {
            # arrange
            $step1 = New-Object -TypeName CmdletUpgradeStep
            $step1.FileName = "mock-file1.ps1"
            $step1.FullPath = "C:\mock-file1.ps1"
            $step1.OriginalCmdletName = "Login-AzureRmAccount"
            $step1.ReplacementCmdletName = "Login-AzAccount"

            $step2 = New-Object -TypeName CmdletUpgradeStep
            $step2.FileName = "mock-file1.ps1"
            $step2.FullPath = "C:\mock-file1.ps1"
            $step2.OriginalCmdletName = "Get-AzureRmWebApp"
            $step2.ReplacementCmdletName = "Get-AzWebApp"

            $step3 = New-Object -TypeName CmdletUpgradeStep
            $step3.FileName = "mock-file2.ps1"
            $step3.FullPath = "C:\mock-file2.ps1"
            $step3.OriginalCmdletName = "Set-AzureRmWebApp"
            $step3.ReplacementCmdletName = "Set-AzWebApp"

            $step4 = New-Object -TypeName CmdletParameterUpgradeStep
            $step4.FileName = "mock-file2.ps1"
            $step4.FullPath = "C:\mock-file2.ps1"
            $step4.OriginalParameterName = "SiteName"
            $step4.ReplacementParameterName = "Name"

            $plan = New-Object -TypeName UpgradePlan
            $plan.UpgradeSteps.Add($step1)
            $plan.UpgradeSteps.Add($step2)
            $plan.UpgradeSteps.Add($step3)
            $plan.UpgradeSteps.Add($step4)

            Mock -CommandName Invoke-ModuleUpgradeStep -ModuleName Az.Tools.Migration -MockWith { } -Verifiable
            Mock -CommandName Get-Content -MockWith { return "mock-file-contents" } -Verifiable
            Mock -CommandName Set-Content -MockWith { } -Verifiable

            # act
            $results = Invoke-AzUpgradeModulePlan -Plan $plan -Confirm:$false

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 4

            foreach ($result in $results)
            {
                $result.GetType().FullName | Should Be 'UpgradeResult'
                $result.Success | Should Be $true
                $result.Reason | Should Not Be $null
            }

            Assert-VerifiableMock
        }
        It 'Should be able to handle file upgrade errors' {
            # arrange
            $step1 = New-Object -TypeName CmdletUpgradeStep
            $step1.FileName = "mock-file1.ps1"
            $step1.FullPath = "C:\mock-file1.ps1"
            $step1.OriginalCmdletName = "Login-AzureRmAccount"
            $step1.ReplacementCmdletName = "Login-AzAccount"

            $step2 = New-Object -TypeName CmdletUpgradeStep
            $step2.FileName = "mock-file1.ps1"
            $step2.FullPath = "C:\mock-file1.ps1"
            $step2.OriginalCmdletName = "Get-AzureRmWebApp"
            $step2.ReplacementCmdletName = "Get-AzWebApp"

            $plan = New-Object -TypeName UpgradePlan
            $plan.UpgradeSteps.Add($step1)
            $plan.UpgradeSteps.Add($step2)

            Mock -CommandName Invoke-ModuleUpgradeStep -ModuleName Az.Tools.Migration -MockWith { throw 'Module update step failed!' } -Verifiable
            Mock -CommandName Get-Content -MockWith { return "mock-file-contents" } -Verifiable
            Mock -CommandName Set-Content -MockWith { }

            # act
            $results = Invoke-AzUpgradeModulePlan -Plan $plan -Confirm:$false

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 2

            foreach ($result in $results)
            {
                $result.GetType().FullName | Should Be 'UpgradeResult'
                $result.Success | Should Be $false
                $result.Reason | Should Not Be $null
            }

            Assert-VerifiableMock
        }
    }
}
