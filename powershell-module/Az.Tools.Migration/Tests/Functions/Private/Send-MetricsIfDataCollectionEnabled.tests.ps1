Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Send-MetricsIfDataCollectionEnabled tests' {
        It 'Should not send telemetry if data collection is disabled' {
            # arrange
            Mock -CommandName Get-ModulePreferences `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith { return [PsCustomObject]@{ DataCollectionEnabled = $false } }

            Mock -CommandName Send-PageViewTelemetry `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith { }

            $metricProps = [PSCustomObject]@{
                AzureCmdletCount = 24
                AzureModuleName = "AzureRM"
                AzureModuleVersion = "6.13.1"
                FileCount = 7
            }

            $duration = [System.Timespan]::FromSeconds(1)

            # act
            Send-MetricsIfDataCollectionEnabled -Operation 'Find' -ParameterSetName 'TestParamSet' -Duration $duration -Properties $metricProps

            # assert
            Assert-MockCalled Send-PageViewTelemetry -Times 0
            Assert-MockCalled Get-ModulePreferences -Times 1
        }
        It 'Should send telemetry if data collection is enabled' {
            # arrange

            Mock -CommandName Get-ModulePreferences `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith { return [PsCustomObject]@{ DataCollectionEnabled = $true } }

            Mock -CommandName Send-PageViewTelemetry `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith { }

            $metricProps = [PSCustomObject]@{
                AzureCmdletCount = 24
                AzureModuleName = "AzureRM"
                AzureModuleVersion = "6.13.1"
                FileCount = 7
            }

            $duration = [System.Timespan]::FromSeconds(1)

            # act
            Send-MetricsIfDataCollectionEnabled -Operation 'Find' -ParameterSetName 'TestParamSet' -Duration $duration -Properties $metricProps

            # assert
            Assert-MockCalled Send-PageViewTelemetry -Times 1
            Assert-MockCalled Get-ModulePreferences -Times 1
        }
        It 'Should not bubble up exceptions to the caller.' {
            # arrange

            Mock -CommandName Get-ModulePreferences `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith { return [PsCustomObject]@{ DataCollectionEnabled = $true } }

            Mock -CommandName Send-PageViewTelemetry `
                -ModuleName Az.Tools.Migration `
                -Verifiable `
                -MockWith { throw 'test error' }

            $metricProps = [PSCustomObject]@{
                AzureCmdletCount = 24
                AzureModuleName = "AzureRM"
                AzureModuleVersion = "6.13.1"
                FileCount = 7
            }

            $duration = [System.Timespan]::FromSeconds(1)

            # act / assert
            {
                Send-MetricsIfDataCollectionEnabled -Operation 'Find' -ParameterSetName 'TestParamSet' -Duration $duration -Properties $metricProps
            } | Should Not Throw

            Assert-MockCalled Send-PageViewTelemetry -Times 1
            Assert-MockCalled Get-ModulePreferences -Times 1
        }
    }
}
