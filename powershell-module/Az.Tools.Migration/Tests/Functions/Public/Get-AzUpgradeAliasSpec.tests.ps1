Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Get-AzUpgradeAliasSpec tests' {
        It 'Should be able to import the Az 4.6.1 alias mapping spec' {
            # arrange/act
            $expectedAliasCount = 2573
            $spec = Get-AzUpgradeAliasSpec -ModuleVersion "4.6.1"

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedAliasCount
        }
    }
}
