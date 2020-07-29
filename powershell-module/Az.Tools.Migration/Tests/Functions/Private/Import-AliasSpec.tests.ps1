Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Import-AliasSpec tests' {
        It 'Should be able to import the Az 4.4.0 alias mapping spec' {
            # arrange/act
            $expectedAliasCount = 2573
            $spec = Import-AliasSpec -ModuleVersion "4.4.0"

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedAliasCount
        }
    }
}
