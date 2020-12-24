Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Get-AzUpgradeCmdletSpec tests' {
        It 'Should be able to import the AzureRM 6.13.1 spec' {
            # arrange/act
            $expectedCommandCount = 2346
            $spec = Get-AzUpgradeCmdletSpec -ModuleName "AzureRM" -ModuleVersion "6.13.1"

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedCommandCount
        }
        It 'Should be able to import the Az 5.2.0 spec' {
            # arrange/act
            $expectedCommandCount = 3416
            $spec = Get-AzUpgradeCmdletSpec -ModuleName "Az" -ModuleVersion "5.2.0"

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedCommandCount
        }
    }
}
