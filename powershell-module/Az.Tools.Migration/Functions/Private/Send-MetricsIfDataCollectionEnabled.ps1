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
        PS C:\ Verb-Noun -Name 'Test'
        Example description goes here.
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
        $dataCollectionSettings = Get-DataCollectionSettings
        if ($dataCollectionSettings.DataCollectionEnabled -eq $true)
        {
            $telemetryClient = New-TelemetryClient
        }
    }
    Process
    {
        if ($dataCollectionSettings.DataCollectionEnabled -eq $true)
        {
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
                    # implement
                }
            }
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