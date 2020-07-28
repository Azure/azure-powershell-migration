function Send-MetricsIfDataCollectionEnabled
{
    <#
    .SYNOPSIS
        Sends Az Upgrade Module metrics to Microsoft.

    .DESCRIPTION
        Sends Az Upgrade Module metrics to Microsoft.

        Data collection can be enabled or disabled with the Enable-AzUpgradeDataCollection and Disabled-AzUpgradeDataCollection commands.

    .PARAMETER Operation
        Specifies the operation or context for the metrics.

    .PARAMETER Properties
        Specifies the metric properties.

    .EXAMPLE
        PS C:\ Send-MetricsIfDataCollectionEnabled -Operation Plan -Properties $propertyBag
        Sends 'Plan' operation metrics with the specified properties, if data collection is enabled.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the operation or context for the metrics.')]
        [System.String]
        [ValidateSet('Find', 'Plan', 'Upgrade')]
        $Operation,

        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage='Specify the metric properties.')]
        [PSCustomObject]
        [ValidateNotNull()]
        $Properties
    )
    Begin
    {
        $dataCollectionSettings = Get-ModulePreferences
        if ($dataCollectionSettings.DataCollectionEnabled -eq $true)
        {
            $telemetryClient = New-TelemetryClient
        }
    }
    Process
    {
        if ($dataCollectionSettings.DataCollectionEnabled -eq $true)
        {
            Write-Verbose -Message "Data collection option is enabled. Sending '$Operation' operation metrics."

            switch ($Operation)
            {
                "Find"
                {
                    $eventProps = New-Object -TypeName 'System.Collections.Generic.Dictionary[System.String, System.String]'
                    $eventProps.Add("AzureModuleName", $Properties.AzureModuleName)
                    $eventProps.Add("AzureModuleVersion", $Properties.AzureModuleVersion)

                    $eventMetrics = New-Object -TypeName 'System.Collections.Generic.Dictionary[System.String, System.Double]'
                    $eventMetrics.Add("Find.AzureCmdletCount", [System.Double]($Properties.AzureCmdletCount))
                    $eventMetrics.Add("Find.FileCount", [System.Double]($Properties.FileCount))

                    $telemetryClient.TrackEvent("FindAzUpgradeCommandReference", $eventProps, $eventMetrics)
                }
                "Plan"
                {
                    $eventProps = New-Object -TypeName 'System.Collections.Generic.Dictionary[System.String, System.String]'
                    $eventProps.Add("ToAzureModuleName", $Properties.ToAzureModuleName)
                    $eventProps.Add("ToAzureModuleVersion", $Properties.ToAzureModuleVersion)

                    $eventMetrics = New-Object -TypeName 'System.Collections.Generic.Dictionary[System.String, System.Double]'
                    $eventMetrics.Add("Plan.UpgradeStepsCount", [System.Double]($Properties.UpgradeStepsCount))
                    $eventMetrics.Add("Plan.WarningsCount", [System.Double]($Properties.PlanWarnings.Count))
                    $eventMetrics.Add("Plan.ErrorsCount", [System.Double]($Properties.PlanErrors.Count))

                    $telemetryClient.TrackEvent("NewAzUpgradeModulePlan", $eventProps, $eventMetrics)

                    if ($Properties.PlanWarnings -ne $null)
                    {
                        foreach ($planError in $Properties.PlanWarnings)
                        {
                            $eventProps["Command"] = $planError.Command.CommandName
                            $eventProps["ReasonCode"] = $planError.ReasonCode.ToString()
                            $telemetryClient.TrackEvent("NewAzUpgradeModulePlanWarning", $eventProps)
                        }
                    }

                    if ($Properties.PlanErrors -ne $null)
                    {
                        foreach ($planError in $Properties.PlanErrors)
                        {
                            $eventProps["Command"] = $planError.Command.CommandName
                            $eventProps["ReasonCode"] = $planError.ReasonCode.ToString()
                            $telemetryClient.TrackEvent("NewAzUpgradeModulePlanError", $eventProps)
                        }
                    }
                }
                "Upgrade"
                {
                    $eventMetrics = New-Object -TypeName 'System.Collections.Generic.Dictionary[System.String, System.Double]'
                    $eventMetrics.Add("Upgrade.SuccessFileUpdateCount", [System.Double]($Properties.SuccessFileUpdateCount))
                    $eventMetrics.Add("Upgrade.SuccessCommandUpdateCount", [System.Double]($Properties.SuccessCommandUpdateCount))
                    $eventMetrics.Add("Upgrade.FailedFileUpdateCount", [System.Double]($Properties.FailedFileUpdateCount))
                    $eventMetrics.Add("Upgrade.FailedCommandUpdateCount", [System.Double]($Properties.FailedCommandUpdateCount))

                    $telemetryClient.TrackEvent("InvokeAzUpgradeModulePlan", $null, $eventMetrics)
                }
            }
        }
        else
        {
            Write-Verbose -Message "Data collection option is disabled. Metrics will not be sent."
        }
    }
    End
    {
        if ($dataCollectionSettings.DataCollectionEnabled -eq $true)
        {
            $telemetryClient.Flush()
        }
    }
}