Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Find-AzUpgradeCommandReference tests' {
        It 'Should ignore non-Azure cmdlets found in files' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            Mock -CommandName Find-CmdletsInFile `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $cmd = New-Object -TypeName CommandReference
                $cmd.CommandName = "Test-Connection"
            }

            # act
            $results = Find-AzUpgradeCommandReference -FilePath "testfile.ps1" -AzureRmVersion "6.13.1"

            # assert
            $results | Should Be $null

            Assert-VerifiableMock
        }
        It 'Should correctly detect AzureRM cmdlets found in files by filename' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            Mock -CommandName Find-CmdletsInFile `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $cmd = New-Object -TypeName CommandReference
                $cmd.CommandName = "Login-AzureRmAccount"
                Write-Output -InputObject $cmd
            }

            # act
            $results = Find-AzUpgradeCommandReference -FilePath "testfile.ps1" -AzureRmVersion "6.13.1"

            # assert
            $results | Should Not Be $Null
            $results.Count | Should Be 1
            $results[0].CommandName | Should Be "Login-AzureRmAccount"

            Assert-VerifiableMock
        }
        It 'Should correctly detect AzureRM cmdlets found in files by filename (w/ spec pre-load)' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            Mock -CommandName Find-CmdletsInFile `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $cmd = New-Object -TypeName CommandReference
                $cmd.CommandName = "Login-AzureRmAccount"
                Write-Output -InputObject $cmd
            }

            # act
            $moduleSpec = Get-AzUpgradeCmdletSpec -ModuleName "AzureRM" -ModuleVersion "6.13.1"
            $results = Find-AzUpgradeCommandReference -FilePath "testfile.ps1" -AzureRmModuleSpec $moduleSpec

            # assert
            $results | Should Not Be $Null
            $results.Count | Should Be 1
            $results[0].CommandName | Should Be "Login-AzureRmAccount"

            Assert-VerifiableMock
        }
        It 'Should correctly detect AzureRM cmdlets found in files found by directory search' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }
            Mock -CommandName Get-ChildItem `
                -ParameterFilter { $Path -eq "C:\test" } `
                -MockWith { Write-Output -InputObject ([PSCustomObject]@{ FullName = 'test.ps1' }) }

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            Mock -CommandName Find-CmdletsInFile `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $cmd = New-Object -TypeName CommandReference
                $cmd.CommandName = "Login-AzureRmAccount"
                Write-Output -InputObject $cmd
            }

            # act
            $results = Find-AzUpgradeCommandReference -DirectoryPath "C:\test" -AzureRmVersion "6.13.1"

            # assert
            $results | Should Not Be $Null
            $results.Count | Should Be 1
            $results[0].CommandName | Should Be "Login-AzureRmAccount"

            Assert-VerifiableMock
        }
        It 'Should correctly detect AzureRM cmdlets found in files found by directory search (w/ spec pre-load)' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }
            Mock -CommandName Get-ChildItem `
                -ParameterFilter { $Path -eq "C:\test" } `
                -MockWith { Write-Output -InputObject ([PSCustomObject]@{ FullName = 'test.ps1' }) }

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            Mock -CommandName Find-CmdletsInFile `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $cmd = New-Object -TypeName CommandReference
                $cmd.CommandName = "Login-AzureRmAccount"
                Write-Output -InputObject $cmd
            }

            # act
            $moduleSpec = Get-AzUpgradeCmdletSpec -ModuleName "AzureRM" -ModuleVersion "6.13.1"
            $results = Find-AzUpgradeCommandReference -DirectoryPath "C:\test" -AzureRmModuleSpec $moduleSpec

            # assert
            $results | Should Not Be $Null
            $results.Count | Should Be 1
            $results[0].CommandName | Should Be "Login-AzureRmAccount"

            Assert-VerifiableMock
        }
        It 'Should correctly detect case-insensitive AzureRM cmdlets found in files' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }

            # ensure we don't send telemetry during tests.
            Mock -CommandName Send-MetricsIfDataCollectionEnabled -ModuleName Az.Tools.Migration -MockWith { }

            Mock -CommandName Find-CmdletsInFile `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $cmd = New-Object -TypeName CommandReference
                $cmd.CommandName = "login-azurermaccount"
                Write-Output -InputObject $cmd
            }

            # act
            $results = Find-AzUpgradeCommandReference -FilePath "testfile.ps1" -AzureRmVersion "6.13.1"

            # assert
            $results | Should Not Be $Null
            $results.Count | Should Be 1
            $results[0].CommandName | Should Be "Login-AzureRmAccount"

            Assert-VerifiableMock
        }
    }
}
