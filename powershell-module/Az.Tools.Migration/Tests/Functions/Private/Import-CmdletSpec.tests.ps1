Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Import-CmdletSpec tests' {
        It 'Should be able to import the AzureRM 6.13.1 spec' {
            # arrange/act
            $expectedCommandCount = 2346
            $spec = Import-CmdletSpec -ModuleName "AzureRM" -ModuleVersion "6.13.1"

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedCommandCount
        }
        It 'Should be able to import the Az 4.4.0 spec' {
            # arrange/act
            $expectedCommandCount = 3210
            $spec = Import-CmdletSpec -ModuleName "Az" -ModuleVersion "4.4.0"

            # assert
            $spec | Should Not Be $null
            $spec.Count | Should Be $expectedCommandCount
        }
    }
}
