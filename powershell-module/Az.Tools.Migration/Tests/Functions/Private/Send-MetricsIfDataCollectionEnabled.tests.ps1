Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Send-MetricsIfDataCollectionEnabled tests' {
        It 'Should not send telemetry if data collection is disabled' {
            # arrange
            Mock -CommandName Get-DataCollectionSettings `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith { return [PsCustomObject]@{ DataCollectionEnabled = $false } }

            Mock -CommandName New-TelemetryClient `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith { }

            $metricProps = [PSCustomObject]@{
                AzureCmdletCount = 24
                AzureModuleName = "AzureRM"
                AzureModuleVersion = "6.13.1"
                FileCount = 7
            }

            # act
            Send-MetricsIfDataCollectionEnabled -Operation 'Find' -Properties $metricProps

            # assert
            Assert-MockCalled New-TelemetryClient -Times 0
            Assert-MockCalled Get-DataCollectionSettings -Times 1
        }
        It 'Should send telemetry if data collection is enabled' {
            # arrange

            Mock -CommandName Get-DataCollectionSettings `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith { return [PsCustomObject]@{ DataCollectionEnabled = $true } }

            Mock -CommandName New-TelemetryClient `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith `
            {
                # return a real telemetry client, but configured to only log locally.
                $instrumentationKey = '00000000-0000-0000-0000-000000000000'
                $configuration = New-Object -TypeName Microsoft.ApplicationInsights.Extensibility.TelemetryConfiguration -ArgumentList $instrumentationKey
                $client = New-Object -TypeName Microsoft.ApplicationInsights.TelemetryClient -ArgumentList $configuration
                return $client
            }

            $metricProps = [PSCustomObject]@{
                AzureCmdletCount = 24
                AzureModuleName = "AzureRM"
                AzureModuleVersion = "6.13.1"
                FileCount = 7
            }

            # act
            Send-MetricsIfDataCollectionEnabled -Operation 'Find' -Properties $metricProps

            # assert
            Assert-MockCalled New-TelemetryClient -Times 1
            Assert-MockCalled Get-DataCollectionSettings -Times 1
        }
    }
}
