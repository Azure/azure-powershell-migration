Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Get-ModulePreferences tests' {
        It 'Should be able to generate a new module preferences object' {
            # arrange
            # mock that the file doesn't exist
            Mock -CommandName Test-Path -Verifiable -MockWith { return $false }

            # mock that the folder creation worked
            Mock -CommandName New-Item -Verifiable -MockWith { }

            # mock that the config file save worked
            Mock -CommandName Out-File -Verifiable -MockWith { }

            # act
            $result = Get-ModulePreferences

            # assert
            $result | Should Not Be $null
            $result.GetType().FullName | Should Be 'ModulePreferences'
            $result.DataCollectionEnabled | Should Be $true
            Assert-VerifiableMock
        }
        It 'Should be able to return an existing module preferences object with data collection enabled' {
            # arrange
            # mock that the file does exist
            Mock -CommandName Test-Path -Verifiable -MockWith { return $true }

            # mock the file contents
            Mock -CommandName Get-Content -Verifiable -MockWith { return '{ "DataCollectionEnabled": true }' }

            # act
            $result = Get-ModulePreferences

            # assert
            $result | Should Not Be $null
            $result.GetType().FullName | Should Be 'ModulePreferences'
            $result.DataCollectionEnabled | Should Be $true
            Assert-VerifiableMock
        }
        It 'Should be able to return an existing module preferences object with data collection disabled' {
            # arrange
            # mock that the file does exist
            Mock -CommandName Test-Path -Verifiable -MockWith { return $true }

            # mock the file contents
            Mock -CommandName Get-Content -Verifiable -MockWith { return '{ "DataCollectionEnabled": false }' }

            # act
            $result = Get-ModulePreferences

            # assert
            $result | Should Not Be $null
            $result.GetType().FullName | Should Be 'ModulePreferences'
            $result.DataCollectionEnabled | Should Be $false
            Assert-VerifiableMock
        }
        It 'Should still return module preferences in case of error' {
            # arrange
            # mock that the file does exist
            Mock -CommandName Test-Path -Verifiable -MockWith { return $true }

            # mock an I/O error from get-content
            Mock -CommandName Get-Content -Verifiable -MockWith { throw 'FileNotFound' }

            # act
            $result = Get-ModulePreferences

            # assert
            $result | Should Not Be $null
            $result.GetType().FullName | Should Be 'ModulePreferences'
            $result.DataCollectionEnabled | Should Be $false
            Assert-VerifiableMock
        }
    }
}
