Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Find-AzureRmCommandReferences tests' {
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
            $results = Find-AzureRmCommandReferences -FilePath "testfile.ps1" -AzureRmModuleVersion "6.13.1"

            # assert
            $results | Should Not Be $Null
            $results.GetType().FullName | Should Be "CommandReferenceCollection"
            $results.Items.Count | Should Be 0

            Assert-VerifiableMock
        }
        It 'Should correctly detect AzureRM cmdlets found in files by filename' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }

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
            $results = Find-AzureRmCommandReferences -FilePath "testfile.ps1" -AzureRmModuleVersion "6.13.1"

            # assert
            $results | Should Not Be $Null
            $results.GetType().FullName | Should Be "CommandReferenceCollection"
            $results.Items.Count | Should Be 1
            $results.Items[0].CommandName | Should Be "Login-AzureRmAccount"

            Assert-VerifiableMock
        }
        It 'Should correctly detect AzureRM cmdlets found in files found by directory search' {
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
                $cmd.CommandName = "Login-AzureRmAccount"
                Write-Output -InputObject $cmd
            }

            # act
            $results = Find-AzureRmCommandReferences -DirectoryPath "C:\test" -AzureRmModuleVersion "6.13.1"

            # assert
            $results | Should Not Be $Null
            $results.GetType().FullName | Should Be "CommandReferenceCollection"
            $results.Items.Count | Should Be 1
            $results.Items[0].CommandName | Should Be "Login-AzureRmAccount"

            Assert-VerifiableMock
        }
        It 'Should correctly detect case-insensitive AzureRM cmdlets found in files' {
            # arrange
            Mock -CommandName Test-Path -MockWith { Write-Output -InputObject $true }

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
            $results = Find-AzureRmCommandReferences -FilePath "testfile.ps1" -AzureRmModuleVersion "6.13.1"

            # assert
            $results | Should Not Be $Null
            $results.GetType().FullName | Should Be "CommandReferenceCollection"
            $results.Items.Count | Should Be 1
            $results.Items[0].CommandName | Should Be "Login-AzureRmAccount"

            Assert-VerifiableMock
        }
    }
}
