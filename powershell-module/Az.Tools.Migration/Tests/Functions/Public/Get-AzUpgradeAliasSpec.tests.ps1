Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Get-AzUpgradeAliasSpec tests' {
        It 'Should be able to import the Az alias mapping spec' {
            # arrange/act
            $expectedAliasCount = 2628
            $spec = Get-AzUpgradeAliasSpec -ModuleVersion latest

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedAliasCount
        }
    }
}
