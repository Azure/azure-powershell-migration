Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'New-AzUpgradeModulePlan tests' {
        It 'Should be able to generate cmdlet upgrade plan steps' {
            # arrange
            $cmdlet1 = New-Object -TypeName CommandReference
            $cmdlet1.FileName = "mock-file.ps1"
            $cmdlet1.FullPath = "C:\mock-file.ps1"
            $cmdlet1.CommandName = "Login-AzureRmAccount"
            $cmdlet1.StartOffset = 10

            $foundCmdlets = @()
            $foundCmdlets += $cmdlet1

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            $results = New-AzUpgradeModulePlan -AzureRmCmdReference $foundCmdlets -ToAzVersion latest

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 1

            $results.GetType().FullName | Should Be 'UpgradePlan'
            $results.UpgradeType.ToString() | Should Be 'Cmdlet'
            $results.PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results.PlanSeverity.ToString() | Should Be 'Information'
            $results.Original | Should Be 'Login-AzureRmAccount'
            $results.Replacement | Should Be 'Login-AzAccount'
            $results.StartOffset | Should Be 10
        }
        It 'Should be able to generate cmdlet parameter upgrade plan steps' {
            # arrange
            $cmdlet1 = New-Object -TypeName CommandReference
            $cmdlet1.FileName = "mock-file.ps1"
            $cmdlet1.FullPath = "C:\mock-file.ps1"
            $cmdlet1.CommandName = "Login-AzureRmAccount"
            $cmdlet1.StartOffset = 5

            $cmdlet1Param = New-Object -TypeName CommandReferenceParameter
            $cmdlet1Param.Name = "EnvironmentName"
            $cmdlet1Param.StartOffset = 27

            $cmdlet1.Parameters.Add($cmdlet1Param)

            $foundCmdlets = @()
            $foundCmdlets += $cmdlet1

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            $results = New-AzUpgradeModulePlan -AzureRmCmdReference $foundCmdlets -ToAzVersion latest

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 2

            $results[0].GetType().FullName | Should Be 'UpgradePlan'
            $results[0].UpgradeType.ToString() | Should Be 'CmdletParameter'
            $results[0].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[0].PlanSeverity.ToString() | Should Be 'Information'
            $results[0].Original | Should Be 'EnvironmentName'
            $results[0].Replacement | Should Be 'Environment'
            $results[0].StartOffset | Should Be 27

            $results[1].GetType().FullName | Should Be 'UpgradePlan'
            $results[1].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[1].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[1].PlanSeverity.ToString() | Should Be 'Information'
            $results[1].Original | Should Be 'Login-AzureRmAccount'
            $results[1].Replacement | Should Be 'Login-AzAccount'
            $results[1].StartOffset | Should Be 5
        }
        It 'Should be able to generate upgrade plan steps in the correct offset order' {
            # arrange
            $cmdlet1 = New-Object -TypeName CommandReference
            $cmdlet1.FileName = "mock-file-A.ps1"
            $cmdlet1.FullPath = "C:\mock-file-A.ps1"
            $cmdlet1.CommandName = "Login-AzureRmAccount"
            $cmdlet1.StartOffset = 10

            $cmdlet2 = New-Object -TypeName CommandReference
            $cmdlet2.FileName = "mock-file-A.ps1"
            $cmdlet2.FullPath = "C:\mock-file-A.ps1"
            $cmdlet2.CommandName = "Set-AzureRmWebApp"
            $cmdlet2.StartOffset = 100

            $cmdlet3 = New-Object -TypeName CommandReference
            $cmdlet3.FileName = "mock-file-A.ps1"
            $cmdlet3.FullPath = "C:\mock-file-A.ps1"
            $cmdlet3.CommandName = "Stop-AzureRmWebAppSlot"
            $cmdlet3.StartOffset = 50

            $cmdlet4 = New-Object -TypeName CommandReference
            $cmdlet4.FileName = "mock-file-C.ps1"
            $cmdlet4.FullPath = "C:\mock-file-C.ps1"
            $cmdlet4.CommandName = "Login-AzureRmAccount"
            $cmdlet4.StartOffset = 28

            $cmdlet5 = New-Object -TypeName CommandReference
            $cmdlet5.FileName = "mock-file-B.ps1"
            $cmdlet5.FullPath = "C:\mock-file-B.ps1"
            $cmdlet5.CommandName = "Set-AzureRmWebAppSlot"
            $cmdlet5.StartOffset = 35

            $cmdlet6 = New-Object -TypeName CommandReference
            $cmdlet6.FileName = "mock-file-D.ps1"
            $cmdlet6.FullPath = "C:\mock-file-D.ps1"
            $cmdlet6.CommandName = "Login-AzureRmAccount"
            $cmdlet6.StartOffset = 33

            $cmdlet7 = New-Object -TypeName CommandReference
            $cmdlet7.FileName = "mock-file-B.ps1"
            $cmdlet7.FullPath = "C:\mock-file-B.ps1"
            $cmdlet7.CommandName = "Get-AzureRmSubscription"
            $cmdlet7.StartOffset = 80

            $cmdlet8 = New-Object -TypeName CommandReference
            $cmdlet8.FileName = "mock-file-B.ps1"
            $cmdlet8.FullPath = "C:\mock-file-B.ps1"
            $cmdlet8.CommandName = "Login-AzureRmAccount"
            $cmdlet8.StartOffset = 5

            $cmdlet9 = New-Object -TypeName CommandReference
            $cmdlet9.FileName = "mock-file-A.ps1"
            $cmdlet9.FullPath = "C:\mock-file-A.ps1"
            $cmdlet9.CommandName = "Get-AzureRmWebAppCertificate"
            $cmdlet9.StartOffset = 200

            $foundCmdlets = @()
            $foundCmdlets += $cmdlet1
            $foundCmdlets += $cmdlet2
            $foundCmdlets += $cmdlet3
            $foundCmdlets += $cmdlet4
            $foundCmdlets += $cmdlet5
            $foundCmdlets += $cmdlet6
            $foundCmdlets += $cmdlet7
            $foundCmdlets += $cmdlet8
            $foundCmdlets += $cmdlet9

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            $results = New-AzUpgradeModulePlan -AzureRmCmdReference $foundCmdlets -ToAzVersion latest

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 9

            # upgrade steps should be returned in order by file path (ascending), then offset (descending).

            # file A results, by descending offset

            $results[0].GetType().FullName | Should Be 'UpgradePlan'
            $results[0].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[0].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[0].PlanSeverity.ToString() | Should Be 'Information'
            $results[0].Original | Should Be 'Get-AzureRmWebAppCertificate'
            $results[0].Replacement | Should Be 'Get-AzWebAppCertificate'
            $results[0].StartOffset | Should Be 200

            $results[1].GetType().FullName | Should Be 'UpgradePlan'
            $results[1].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[1].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[1].PlanSeverity.ToString() | Should Be 'Information'
            $results[1].Original | Should Be 'Set-AzureRmWebApp'
            $results[1].Replacement | Should Be 'Set-AzWebApp'
            $results[1].StartOffset | Should Be 100

            $results[2].GetType().FullName | Should Be 'UpgradePlan'
            $results[2].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[2].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[2].PlanSeverity.ToString() | Should Be 'Information'
            $results[2].Original | Should Be 'Stop-AzureRmWebAppSlot'
            $results[2].Replacement | Should Be 'Stop-AzWebAppSlot'
            $results[2].StartOffset | Should Be 50

            $results[3].GetType().FullName | Should Be 'UpgradePlan'
            $results[3].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[3].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[3].PlanSeverity.ToString() | Should Be 'Information'
            $results[3].Original | Should Be 'Login-AzureRmAccount'
            $results[3].Replacement | Should Be 'Login-AzAccount'
            $results[3].StartOffset | Should Be 10

            # file B results, by descending offset

            $results[4].GetType().FullName | Should Be 'UpgradePlan'
            $results[4].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[4].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[4].PlanSeverity.ToString() | Should Be 'Information'
            $results[4].Original | Should Be 'Get-AzureRmSubscription'
            $results[4].Replacement | Should Be 'Get-AzSubscription'
            $results[4].StartOffset | Should Be 80

            $results[5].GetType().FullName | Should Be 'UpgradePlan'
            $results[5].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[5].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[5].PlanSeverity.ToString() | Should Be 'Information'
            $results[5].Original | Should Be 'Set-AzureRmWebAppSlot'
            $results[5].Replacement | Should Be 'Set-AzWebAppSlot'
            $results[5].StartOffset | Should Be 35

            $results[6].GetType().FullName | Should Be 'UpgradePlan'
            $results[6].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[6].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[6].PlanSeverity.ToString() | Should Be 'Information'
            $results[6].Original | Should Be 'Login-AzureRmAccount'
            $results[6].Replacement | Should Be 'Login-AzAccount'
            $results[6].StartOffset | Should Be 5

            # file C results, by descending offset

            $results[7].GetType().FullName | Should Be 'UpgradePlan'
            $results[7].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[7].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[7].PlanSeverity.ToString() | Should Be 'Information'
            $results[7].Original | Should Be 'Login-AzureRmAccount'
            $results[7].Replacement | Should Be 'Login-AzAccount'
            $results[7].StartOffset | Should Be 28

            # file D results, by descending offset

            $results[8].GetType().FullName | Should Be 'UpgradePlan'
            $results[8].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[8].PlanResult.ToString() | Should Be 'ReadyToUpgrade'
            $results[8].PlanSeverity.ToString() | Should Be 'Information'
            $results[8].Original | Should Be 'Login-AzureRmAccount'
            $results[8].Replacement | Should Be 'Login-AzAccount'
            $results[8].StartOffset | Should Be 33
        }
        It 'Should be able to generate errors for source cmdlets missing upgrade aliases' {
            # arrange
            $cmdlet1 = New-Object -TypeName CommandReference
            $cmdlet1.FileName = "mock-file.ps1"
            $cmdlet1.FullPath = "C:\mock-file.ps1"
            $cmdlet1.CommandName = "Invoke-AzureRmFakeCommandNotFoundInAliases"
            $cmdlet1.StartOffset = 10

            $foundCmdlets = @()
            $foundCmdlets += $cmdlet1

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            # should generate a warning, and an upgrade step
            $results = New-AzUpgradeModulePlan -AzureRmCmdReference $foundCmdlets -ToAzVersion latest

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 1

            $results.UpgradeType.ToString() | Should Be 'Cmdlet'
            $results.PlanResult.ToString() | Should Be "ErrorNoUpgradeAlias"
            $results.PlanSeverity.ToString() | Should Be 'Error'
            $results.PlanResultReason.Contains("No matching upgrade alias found") | Should Be $true

            Assert-VerifiableMock
        }
        It 'Should generate warnings for dynamic parameters on cmdlets that support IDynamicParameters' {
            # arrange
            $cmdlet1 = New-Object -TypeName CommandReference
            $cmdlet1.FileName = "mock-file.ps1"
            $cmdlet1.FullPath = "C:\mock-file.ps1"
            $cmdlet1.CommandName = "New-AzureRmResourceGroupDeployment" # a real cmdlet that supports IDynamicParameters
            $cmdlet1.StartOffset = 10

            # add a known static parameter
            $cmdlet1Param1 = New-Object -TypeName CommandReferenceParameter
            $cmdlet1Param1.Name = "TemplateFile"
            $cmdlet1Param1.StartOffset = 27

            # add a dynamic parameter
            $cmdlet1Param2 = New-Object -TypeName CommandReferenceParameter
            $cmdlet1Param2.Name = "DynamicUserParam1"
            $cmdlet1Param2.StartOffset = 50

            $cmdlet1.Parameters.Add($cmdlet1Param1)
            $cmdlet1.Parameters.Add($cmdlet1Param2)

            $foundCmdlets = @()
            $foundCmdlets += $cmdlet1

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            # should generate a warning, and an upgrade step
            $results = New-AzUpgradeModulePlan -AzureRmCmdReference $foundCmdlets -ToAzVersion latest

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 2

            $results[0].UpgradeType.ToString() | Should Be 'CmdletParameter'
            $results[0].PlanResult.ToString() | Should Be "WarningDynamicParameter"
            $results[0].PlanResultReason.Contains("supports dynamic parameters") | Should Be $true
            $results[0].PlanSeverity.ToString() | Should Be 'Warning'

            $results[1].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[1].PlanResult.ToString() | Should Be "ReadyToUpgrade"
            $results[1].PlanSeverity.ToString() | Should Be 'Information'

            Assert-VerifiableMock
        }
        It 'Should generate errors for unknown parameters on cmdlets that dont support IDynamicParameters' {
            # arrange
            $cmdlet1 = New-Object -TypeName CommandReference
            $cmdlet1.FileName = "mock-file.ps1"
            $cmdlet1.FullPath = "C:\mock-file.ps1"
            $cmdlet1.CommandName = "Connect-AzureRmAccount" # a real cmdlet that does not support IDynamicParameters
            $cmdlet1.StartOffset = 10

            # add a known static parameter
            $cmdlet1Param1 = New-Object -TypeName CommandReferenceParameter
            $cmdlet1Param1.Name = "Credential"
            $cmdlet1Param1.StartOffset = 27

            # add a parameter that certainly doesn't exist
            $cmdlet1Param2 = New-Object -TypeName CommandReferenceParameter
            $cmdlet1Param2.Name = "FakeParameterShouldError"
            $cmdlet1Param2.StartOffset = 50

            $cmdlet1.Parameters.Add($cmdlet1Param1)
            $cmdlet1.Parameters.Add($cmdlet1Param2)

            $foundCmdlets = @()
            $foundCmdlets += $cmdlet1

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            # act
            # should generate a warning, and an upgrade step
            $results = New-AzUpgradeModulePlan -AzureRmCmdReference $foundCmdlets -ToAzVersion latest

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 2

            $results[0].UpgradeType.ToString() | Should Be 'CmdletParameter'
            $results[0].PlanResult.ToString() | Should Be "WarningDynamicParameter"
            $results[0].PlanSeverity.ToString() | Should Be 'Warning'

            $results[1].UpgradeType.ToString() | Should Be 'Cmdlet'
            $results[1].PlanResult.ToString() | Should Be "ReadyToUpgrade"
            $results[1].PlanSeverity.ToString() | Should Be 'Information'

            Assert-VerifiableMock
        }
        It 'Should be able to generate errors for source cmdlets that have no target spec' {
            # arrange
            $cmdlet1 = New-Object -TypeName CommandReference
            $cmdlet1.FileName = "mock-file.ps1"
            $cmdlet1.FullPath = "C:\mock-file.ps1"
            $cmdlet1.CommandName = "Invoke-AzureRmFakeCommandFoundInAliasesButNotInSpec"
            $cmdlet1.StartOffset = 10

            $foundCmdlets = @()
            $foundCmdlets += $cmdlet1

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            Mock -CommandName Get-AzUpgradeAliasSpec `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $aliasMap = New-Object -TypeName 'System.Collections.Generic.Dictionary[System.String,System.String]' -ArgumentList (, [System.StringComparer]::OrdinalIgnoreCase)
                $aliasMap.Add("Invoke-AzureRmFakeCommandFoundInAliasesButNotInSpec", "Invoke-AzFakeCommandFoundInAliasesButNotInSpec")
                Write-Output -InputObject $aliasMap
            }

            # act
            # should generate a warning, and an upgrade step
            $results = New-AzUpgradeModulePlan -AzureRmCmdReference $foundCmdlets -ToAzVersion latest

            # assert
            $results | Should Not Be $null
            $results.Count | Should Be 1

            $results.UpgradeType.ToString() | Should Be 'Cmdlet'
            $results.PlanResult.ToString() | Should Be "ErrorNoModuleSpecMatch"
            $results.PlanSeverity.ToString() | Should Be 'Error'
            $results.PlanResultReason.Contains("No Az cmdlet spec found for") | Should Be $true

            Assert-VerifiableMock
        }
    }
}
