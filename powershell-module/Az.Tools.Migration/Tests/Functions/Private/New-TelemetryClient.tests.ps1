Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'New-TelemetryClient tests' {
        It 'Should be able to instantiate the telemetry client' {
            # arrange/act
            $client = New-TelemetryClient

            # assert
            $client | Should Not Be $null
            $client.GetType().FullName | Should Be 'Microsoft.ApplicationInsights.TelemetryClient'
        }
    }
}
