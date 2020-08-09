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

    .PARAMETER ParameterSetName
        Specifies the command parameter set name.

    .PARAMETER Duration
        Specifies the duration (time elapsed) that the operation took.

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
            HelpMessage='Specify the command parameter set used.')]
        [System.String]
        $ParameterSetName,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the duration (time elapsed) that operation took.')]
        [System.TimeSpan]
        [ValidateNotNull()]
        $Duration,

        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage='Specify the metric properties.')]
        [PSCustomObject]
        [ValidateNotNull()]
        $Properties
    )
    Process
    {
        $dataCollectionSettings = Get-ModulePreferences
        if ($dataCollectionSettings.DataCollectionEnabled -eq $true)
        {
            Write-Verbose -Message "Data collection option is enabled. Sending '$Operation' operation metrics."

            try
            {
                # telemetry send errors are not surfaced to the end user (verbose only).

                switch ($Operation)
                {
                    "Find"
                    {
                        $operationProps = @{
                            # common props
                            "powershellversion" = $PSVersionTable.PSVersion.ToString()
                            "command" = "Find-AzUpgradeCommandReference"
                            "commandparametersetname" = $ParameterSetName
                            "moduleversion" = $MyInvocation.MyCommand.Module.Version.ToString()
                            "modulename" = "Az.Tools.Migration"
                            "issuccess" = "True"

                            # custom operation props
                            "find-azure-module-name" = $Properties.AzureModuleName
                            "find-azure-module-version" = $Properties.AzureModuleVersion
                            "find-azure-cmdlet-count" = $Properties.AzureCmdletCount
                            "find-azure-file-count" = $Properties.FileCount
                        }

                        Send-PageViewTelemetry -PageName 'FindAzUpgradeCommandReference' -Duration $Duration -CustomProperties $operationProps
                    }
                    "Plan"
                    {
                        $warningsBuilder = New-Object -TypeName System.Text.StringBuilder
                        $errorsBuilder = New-Object -TypeName System.Text.StringBuilder

                        if ($Properties.PlanWarnings -ne $null)
                        {
                            foreach ($planWarning in $Properties.PlanWarnings)
                            {
                                $null = $warningsBuilder.AppendLine(("{0}={1}" -f $planWarning.Command.CommandName, $planWarning.ReasonCode.ToString()))
                            }
                        }

                        if ($Properties.PlanErrors -ne $null)
                        {
                            foreach ($planError in $Properties.PlanErrors)
                            {
                                $null = $warningsBuilder.AppendLine(("{0}={1}" -f $planError.Command.CommandName, $planError.ReasonCode.ToString()))
                            }
                        }

                        $operationProps = @{
                            # common props
                            "powershellversion" = $PSVersionTable.PSVersion.ToString()
                            "command" = "New-AzUpgradeModulePlan"
                            "commandparametersetname" = $ParameterSetName
                            "moduleversion" = $MyInvocation.MyCommand.Module.Version.ToString()
                            "modulename" = "Az.Tools.Migration"
                            "issuccess" = "True"

                            # custom operation props
                            "plan-to-azure-modulename" = $Properties.ToAzureModuleName
                            "plan-to-azure-moduleversion" = $Properties.ToAzureModuleVersion
                            "plan-upgrade-steps-count" = $Properties.UpgradeStepsCount
                            "plan-warning-steps-count" = $Properties.PlanWarnings.Count
                            "plan-warning-steps" = $warningsBuilder.ToString()
                            "plan-error-steps-count" = $Properties.PlanErrors.Count
                            "plan-error-steps" = $errorsBuilder.ToString()
                        }

                        Send-PageViewTelemetry -PageName 'NewAzUpgradeModulePlan' -Duration $Duration -CustomProperties $operationProps
                    }
                    "Upgrade"
                    {
                        $operationProps = @{
                            # common props
                            "powershellversion" = $PSVersionTable.PSVersion.ToString()
                            "command" = "Invoke-AzUpgradeModulePlan"
                            "commandparametersetname" = $ParameterSetName
                            "moduleversion" = $MyInvocation.MyCommand.Module.Version.ToString()
                            "modulename" = "Az.Tools.Migration"
                            "issuccess" = "True"

                            # custom operation props
                            "upgrade-success-file-count" = $Properties.SuccessFileUpdateCount
                            "upgrade-success-command-count" = $Properties.SuccessCommandUpdateCount
                            "upgrade-failed-file-count" = $Properties.FailedFileUpdateCount
                            "upgrade-failed-command-count" = $Properties.FailedCommandUpdateCount
                        }

                        Send-PageViewTelemetry -PageName 'InvokeAzUpgradeModulePlan' -Duration $Duration -CustomProperties $operationProps
                    }
                }
            }
            catch
            {
                Write-Verbose -Message "Telemetry send failure: $_"
            }
        }
        else
        {
            Write-Verbose -Message "Data collection option is disabled. Metrics will not be sent."
        }
    }
}