Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Invoke-AzUpgradeModulePlan tests' {
        It 'Should be able to execute an update plan (single-file)' {
            # arrange
            $step = New-Object -TypeName UpgradePlan
            $step.FullPath = "C:\mock-file.ps1"
            $step.UpgradeType = [UpgradeStepType]::Cmdlet
            $step.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
            $step.PlanSeverity = [DiagnosticSeverity]::Information
            $step.Location = "mocked-file.ps1:10:5"
            $step.Original = "Login-AzureRmAccount"
            $step.Replacement = "Login-AzAccount"

            Mock -CommandName Invoke-ModuleUpgradeStep -ModuleName Az.Tools.Migration -MockWith { } -Verifiable
            Mock -CommandName Get-Content -MockWith { return "mock-file-contents" } -Verifiable
            Mock -CommandName Set-Content -MockWith { } -Verifiable

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            $result = Invoke-AzUpgradeModulePlan -Plan $step -Confirm:$false

            # assert
            $result | Should Not Be $null
            $result.Count | Should Be 1
            $result.GetType().FullName | Should Be 'UpgradeResult'
            $result.UpgradeResult.ToString() | Should Be 'UpgradeCompleted'
            $result.UpgradeSeverity.ToString() | Should Be 'Information'

            Assert-VerifiableMock
        }
        It 'Should be able to execute an update plan (multi-file)' {
            # arrange
            $step1 = New-Object -TypeName UpgradePlan
            $step1.FullPath = "C:\mock-file.ps1"
            $step1.UpgradeType = [UpgradeStepType]::Cmdlet
            $step1.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
            $step1.PlanSeverity = [DiagnosticSeverity]::Information
            $step1.Location = "mocked-file.ps1:10:5"
            $step1.Original = "Login-AzureRmAccount"
            $step1.Replacement = "Login-AzAccount"

            $step2 = New-Object -TypeName UpgradePlan
            $step2.FullPath = "C:\mock-file.ps1"
            $step2.UpgradeType = [UpgradeStepType]::Cmdlet
            $step2.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
            $step2.PlanSeverity = [DiagnosticSeverity]::Information
            $step2.Location = "mocked-file.ps1:20:1"
            $step2.Original = "Get-AzureRmWebApp"
            $step2.Replacement = "Get-AzWebApp"

            $step3 = New-Object -TypeName UpgradePlan
            $step3.FullPath = "C:\mock-file2.ps1"
            $step3.UpgradeType = [UpgradeStepType]::Cmdlet
            $step3.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
            $step3.PlanSeverity = [DiagnosticSeverity]::Information
            $step3.Location = "mocked-file2.ps1:20:1"
            $step3.Original = "Set-AzureRmWebApp"
            $step3.Replacement = "Set-AzWebApp"

            $step4 = New-Object -TypeName UpgradePlan
            $step4.FullPath = "C:\mock-file2.ps1"
            $step4.UpgradeType = [UpgradeStepType]::CmdletParameter
            $step4.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
            $step4.PlanSeverity = [DiagnosticSeverity]::Information
            $step4.Location = "mocked-file2.ps1:25:12"
            $step4.Original = "SiteName"
            $step4.Replacement = "Name"

            $plan = @( $step1, $step2, $step3, $step4 )

            Mock -CommandName Invoke-ModuleUpgradeStep -ModuleName Az.Tools.Migration -MockWith { } -Verifiable
            Mock -CommandName Get-Content -MockWith { return "mock-file-contents" } -Verifiable
            Mock -CommandName Set-Content -MockWith { } -Verifiable

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            $results = Invoke-AzUpgradeModulePlan -Plan $plan -Confirm:$false

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 4

            foreach ($result in $results)
            {
                $result.GetType().FullName | Should Be 'UpgradeResult'
                $result.UpgradeResult.ToString() | Should Be 'UpgradeCompleted'
                $result.UpgradeSeverity.ToString() | Should Be 'Information'
            }

            Assert-VerifiableMock
        }
        It 'Should be able to skip plan steps with error state' {
            # arrange
            $step1 = New-Object -TypeName UpgradePlan
            $step1.FullPath = "C:\mock-file.ps1"
            $step1.UpgradeType = [UpgradeStepType]::Cmdlet
            $step1.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
            $step1.PlanSeverity = [DiagnosticSeverity]::Information
            $step1.Location = "mocked-file.ps1:10:5"
            $step1.Original = "Login-AzureRmAccount"
            $step1.Replacement = "Login-AzAccount"

            $step2 = New-Object -TypeName UpgradePlan
            $step2.FullPath = "C:\mock-file.ps1"
            $step2.UpgradeType = [UpgradeStepType]::Cmdlet
            $step2.PlanResult = [PlanResultReasonCode]::ErrorNoUpgradeAlias
            $step2.PlanSeverity = [DiagnosticSeverity]::Error
            $step2.Location = "mocked-file.ps1:20:1"
            $step2.Original = "Get-AzureRmCommandThatDoesntHaveAnUpgradeAlias"
            $step2.Replacement = "" # no replacement, since it can't be upgraded

            $plan = @( $step1, $step2 )

            Mock -CommandName Invoke-ModuleUpgradeStep -ModuleName Az.Tools.Migration -MockWith { } -Verifiable
            Mock -CommandName Get-Content -MockWith { return "mock-file-contents" } -Verifiable
            Mock -CommandName Set-Content -MockWith { } -Verifiable

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            $results = Invoke-AzUpgradeModulePlan -Plan $plan -Confirm:$false

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 2

            # first plan step should have upgraded fine.
            $results[0].GetType().FullName | Should Be 'UpgradeResult'
            $results[0].UpgradeResult.ToString() | Should Be 'UpgradeCompleted'
            $results[0].UpgradeSeverity.ToString() | Should Be 'Information'

            # second plan step should be skipped, since it cannot be auto-upgraded.
            $results[1].GetType().FullName | Should Be 'UpgradeResult'
            $results[1].UpgradeResult.ToString() | Should Be 'UnableToUpgrade'
            $results[1].UpgradeSeverity.ToString() | Should Be 'Error'

            Assert-VerifiableMock
        }
        It 'Should be able to execute plan steps with warning state' {
            # arrange
            $step1 = New-Object -TypeName UpgradePlan
            $step1.FullPath = "C:\mock-file.ps1"
            $step1.UpgradeType = [UpgradeStepType]::Cmdlet
            $step1.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
            $step1.PlanSeverity = [DiagnosticSeverity]::Information
            $step1.Location = "mocked-file.ps1:10:5"
            $step1.Original = "Login-AzureRmAccount"
            $step1.Replacement = "Login-AzAccount"

            $step2 = New-Object -TypeName UpgradePlan
            $step2.FullPath = "C:\mock-file.ps1"
            $step2.UpgradeType = [UpgradeStepType]::Cmdlet
            $step2.PlanResult = [PlanResultReasonCode]::WarningSplattedParameters
            $step2.PlanSeverity = [DiagnosticSeverity]::Warning
            $step2.Location = "mocked-file.ps1:20:1"
            $step2.Original = "Get-AzureRmCommandThatIsUsingSplattedParameters"
            $step2.Replacement = "Get-AzCommandThatIsUsingSplattedParameters" # has a replacement, but is in warning state.

            $plan = @( $step1, $step2 )

            Mock -CommandName Invoke-ModuleUpgradeStep -ModuleName Az.Tools.Migration -MockWith { } -Verifiable
            Mock -CommandName Get-Content -MockWith { return "mock-file-contents" } -Verifiable
            Mock -CommandName Set-Content -MockWith { } -Verifiable

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            $results = Invoke-AzUpgradeModulePlan -Plan $plan -Confirm:$false

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 2

            # first plan step should have upgraded fine.
            $results[0].GetType().FullName | Should Be 'UpgradeResult'
            $results[0].UpgradeResult.ToString() | Should Be 'UpgradeCompleted'
            $results[0].UpgradeSeverity.ToString() | Should Be 'Information'

            # second plan step should be executed, but return a Completed w/ warnings state.
            $results[1].GetType().FullName | Should Be 'UpgradeResult'
            $results[1].UpgradeResult.ToString() | Should Be 'UpgradedWithWarnings'
            $results[1].UpgradeSeverity.ToString() | Should Be 'Warning'

            Assert-VerifiableMock
        }
        It 'Should be able to handle file upgrade errors' {
            # arrange
            $step1 = New-Object -TypeName UpgradePlan
            $step1.FullPath = "C:\mock-file.ps1"
            $step1.UpgradeType = [UpgradeStepType]::Cmdlet
            $step1.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
            $step1.PlanSeverity = [DiagnosticSeverity]::Information
            $step1.Location = "mocked-file.ps1:10:5"
            $step1.Original = "Login-AzureRmAccount"
            $step1.Replacement = "Login-AzAccount"

            $step2 = New-Object -TypeName UpgradePlan
            $step2.FullPath = "C:\mock-file.ps1"
            $step2.UpgradeType = [UpgradeStepType]::Cmdlet
            $step2.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
            $step2.PlanSeverity = [DiagnosticSeverity]::Information
            $step2.Location = "mocked-file.ps1:20:1"
            $step2.Original = "Get-AzureRmWebApp"
            $step2.Replacement = "Get-AzWebApp"

            $plan = @( $step1, $step2 )

            Mock -CommandName Invoke-ModuleUpgradeStep -ModuleName Az.Tools.Migration -MockWith { throw 'Module update step failed!' } -Verifiable
            Mock -CommandName Get-Content -MockWith { return "mock-file-contents" } -Verifiable
            Mock -CommandName Set-Content -MockWith { }

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            $results = Invoke-AzUpgradeModulePlan -Plan $plan -Confirm:$false

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 2

            foreach ($result in $results)
            {
                $result.GetType().FullName | Should Be 'UpgradeResult'
                $result.UpgradeResult.ToString() | Should Be 'UpgradeActionFailed'
                $result.UpgradeSeverity.ToString() | Should Be 'Error'
            }

            Assert-VerifiableMock
        }
    }
}
