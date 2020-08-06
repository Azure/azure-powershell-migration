Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Enable-AzUpgradeDataCollection tests' {
        It 'Should be able to set the data collection setting correctly' {
            # arrange
            Mock -CommandName Set-ModulePreference `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $DataCollectionEnabled -eq $true }

            # act
            Enable-AzUpgradeDataCollection

            # assert
            Assert-MockCalled Set-ModulePreference -Times 1 -ParameterFilter { $DataCollectionEnabled -eq $true }
        }
    }
}
