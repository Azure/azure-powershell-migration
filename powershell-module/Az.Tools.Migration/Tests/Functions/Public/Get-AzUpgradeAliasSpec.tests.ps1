Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Get-AzUpgradeAliasSpec tests' {
        It 'Should be able to import the Az 4.8.0 alias mapping spec' {
            # arrange/act
            $expectedAliasCount = 2580
            $spec = Get-AzUpgradeAliasSpec -ModuleVersion "4.8.0"

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedAliasCount
        }
    }
}
