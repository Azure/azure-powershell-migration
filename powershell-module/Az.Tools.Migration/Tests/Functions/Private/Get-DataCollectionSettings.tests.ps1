Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Get-DataCollectionSettings tests' {
        It 'Should be able to return the data collection settings object' {
            # arrange/act
            $dataCollectionSettings = Get-DataCollectionSettings

            # assert
            $dataCollectionSettings | Should Not Be $null
            $dataCollectionSettings.GetType().FullName | Should Be 'DataCollectionSettings'
        }
    }
}
