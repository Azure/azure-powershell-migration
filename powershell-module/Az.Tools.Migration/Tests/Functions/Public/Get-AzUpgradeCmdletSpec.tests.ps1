Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Get-AzUpgradeCmdletSpec tests' {
        It 'Should be able to import the AzureRM 6.13.1 spec' {
            # arrange/act
            $expectedCommandCount = 2346
            $spec = Get-AzUpgradeCmdletSpec -AzureRM

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedCommandCount
        }
        It 'Should be able to import the Az 9.3.0 spec' {
            # arrange/act
            $expectedCommandCount = 4979
            $spec = Get-AzUpgradeCmdletSpec -Az -ModuleVersion latest

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedCommandCount
        }
    }
}
