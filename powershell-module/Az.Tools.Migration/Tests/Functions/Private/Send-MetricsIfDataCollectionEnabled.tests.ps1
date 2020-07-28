Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Send-MetricsIfDataCollectionEnabled tests' {
        It 'Should not send telemetry if data collection is disabled' {
            # implement
        }
        It 'Should send telemetry if data collection is enabled' {
            # implement
        }
    }
}
