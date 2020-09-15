Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'New-ModifiedFileName tests' {
        It 'Can correctly provide a new name for .ps1 files' {
            # arrange / act
            # act
            $result = New-ModifiedFileName -Path 'C:\scripts\test.ps1'

            # assert
            $result | Should Be 'C:\scripts\test_az_upgraded.ps1'
        }
        It 'Can correctly provide a new name for .psm1 files' {
            # arrange / act
            # act
            $result = New-ModifiedFileName -Path 'C:\scripts\test-two-module.psm1'

            # assert
            $result | Should Be 'C:\scripts\test-two-module_az_upgraded.psm1'
        }
        It 'Can correctly provide a new name for extensionless files' {
            # arrange / act
            # act
            $result = New-ModifiedFileName -Path 'C:\scripts\test-two-extensionless'

            # assert
            $result | Should Be 'C:\scripts\test-two-extensionless_az_upgraded'
        }
    }
}
