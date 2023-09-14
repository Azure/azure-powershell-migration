Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Get-AzUpgradeAliasSpec tests' {
        It 'Should be able to import the Az 9.3.0 alias mapping spec' {
            # arrange/act
            $expectedAliasCount = 2623
            $spec = Get-AzUpgradeAliasSpec -ModuleVersion latest

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedAliasCount
        }
    }
}
