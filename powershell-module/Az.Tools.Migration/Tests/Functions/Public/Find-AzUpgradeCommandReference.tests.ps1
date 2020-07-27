Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Find-AzUpgradeCommandReference tests' {
        It 'Should ignore non-Azure cmdlets found in files' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }

            Mock -CommandName Find-CmdletsInFile `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $cmd = New-Object -TypeName CommandReference
                $cmd.CommandName = "Test-Connection"
            }

            # act
            $results = Find-AzUpgradeCommandReference -FilePath "testfile.ps1" -AzModuleVersion 4

            # assert
            $results | Should Not Be $Null
            $results.GetType().FullName | Should Be "CommandReferenceCollection"
            $results.Items.Count | Should Be 0

            Assert-VerifiableMock
        }
        It 'Should correctly detect Az cmdlets found in files by filename' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }

            Mock -CommandName Find-CmdletsInFile `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $cmd = New-Object -TypeName CommandReference
                $cmd.CommandName = "Login-AzAccount"
                Write-Output -InputObject $cmd
            }

            # act
            $results = Find-AzUpgradeCommandReference -FilePath "testfile.ps1" -AzModuleVersion 4

            # assert
            $results | Should Not Be $Null
            $results.GetType().FullName | Should Be "CommandReferenceCollection"
            $results.Items.Count | Should Be 1
            $results.Items[0].CommandName | Should Be "Login-AzAccount"

            Assert-VerifiableMock
        }
        It 'Should correctly detect Az cmdlets found in files found by directory search' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }
            Mock -CommandName Get-ChildItem `
                -ParameterFilter { $Path -eq "C:\test" } `
                -MockWith { Write-Output -InputObject ([PSCustomObject]@{ FullName = 'test.ps1' }) }

            Mock -CommandName Find-CmdletsInFile `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $cmd = New-Object -TypeName CommandReference
                $cmd.CommandName = "Login-AzAccount"
                Write-Output -InputObject $cmd
            }

            # act
            $results = Find-AzUpgradeCommandReference -DirectoryPath "C:\test" -AzModuleVersion 4

            # assert
            $results | Should Not Be $Null
            $results.GetType().FullName | Should Be "CommandReferenceCollection"
            $results.Items.Count | Should Be 1
            $results.Items[0].CommandName | Should Be "Login-AzAccount"

            Assert-VerifiableMock
        }
        It 'Should correctly detect case-insensitive Az cmdlets found in files' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }

            Mock -CommandName Find-CmdletsInFile `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                $cmd = New-Object -TypeName CommandReference
                $cmd.CommandName = "login-azaccount"
                Write-Output -InputObject $cmd
            }

            # act
            $results = Find-AzUpgradeCommandReference -FilePath "testfile.ps1" -AzModuleVersion 4

            # assert
            $results | Should Not Be $Null
            $results.GetType().FullName | Should Be "CommandReferenceCollection"
            $results.Items.Count | Should Be 1
            $results.Items[0].CommandName | Should Be "Login-AzAccount"

            Assert-VerifiableMock
        }
    }
}
