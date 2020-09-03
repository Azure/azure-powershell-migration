function Send-MetricsIfDataCollectionEnabled
{
    <#
    .SYNOPSIS
        Sends Az Upgrade Module metrics to Microsoft.

    .DESCRIPTION
        Sends Az Upgrade Module metrics to Microsoft.

        Data collection can be enabled or disabled with the Enable-AzUpgradeDataCollection and Disable-AzUpgradeDataCollection commands.

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
            Write-Verbose -Message "Operation duration: $($Duration.ToString())"

            try
            {
                # telemetry send errors are not surfaced to the end user (verbose only).

                switch ($Operation)
                {
                    "Find"
                    {
                        $operationProps = @{
                            # common props
                            "command" = "Find-AzUpgradeCommandReference"
                            "commandparametersetname" = $ParameterSetName
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
                                if ($planWarning.UpgradeType -eq [UpgradeStepType]::Cmdlet)
                                {
                                    # cmdlet. log just the cmdlet name and the warning reason
                                    $null = $warningsBuilder.AppendLine(("{0}={1}" -f `
                                                $planWarning.Original, `
                                                $planWarning.PlanResult.ToString()))
                                }
                                elseif ($planWarning.UpgradeType -eq [UpgradeStepType]::CmdletParameter)
                                {
                                    # cmdlet parameter. log the cmdlet name and the parameter name, with the warning reason
                                    $null = $warningsBuilder.AppendLine(("{0}.{1}={2}" -f `
                                                $planWarning.SourceCommand.CommandName, `
                                                $planWarning.Original, `
                                                $planWarning.PlanResult.ToString()))
                                }
                                else
                                {
                                    throw "Unexpected plan upgrade step type: $($planWarning.UpgradeType)"
                                }
                            }
                        }

                        if ($Properties.PlanErrors -ne $null)
                        {
                            foreach ($planError in $Properties.PlanErrors)
                            {
                                if ($planError.UpgradeType -eq [UpgradeStepType]::Cmdlet)
                                {
                                    # cmdlet. log just the cmdlet name and the error reason
                                    $null = $errorsBuilder.AppendLine(("{0}={1}" -f `
                                                $planError.Original, `
                                                $planError.PlanResult.ToString()))
                                }
                                elseif ($planError.UpgradeType -eq [UpgradeStepType]::CmdletParameter)
                                {
                                    # cmdlet parameter. log the cmdlet name and the parameter name, with the error reason
                                    $null = $errorsBuilder.AppendLine(("{0}.{1}={2}" -f `
                                                $planError.SourceCommand.CommandName, `
                                                $planError.Original, `
                                                $planError.PlanResult.ToString()))
                                }
                                else
                                {
                                    throw "Unexpected plan upgrade step type: $($planError.UpgradeType)"
                                }
                            }
                        }

                        $operationProps = @{
                            # common props
                            "command" = "New-AzUpgradeModulePlan"
                            "commandparametersetname" = $ParameterSetName
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
                            "command" = "Invoke-AzUpgradeModulePlan"
                            "commandparametersetname" = $ParameterSetName
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