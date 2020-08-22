function Invoke-AzUpgradeModulePlan
{
    <#
    .SYNOPSIS
        Invokes the specified module upgrade plan.

    .DESCRIPTION
        Invokes the specified module upgrade plan.

        IMPORTANT: This step is destructive. It makes file edits in-place according to the module upgrade plan. NOTE: There is no "undo" operation. Always ensure that you have a backup copy of the target PowerShell script or module.

        The upgrade plan is generated by running the New-AzUpgradeModulePlan cmdlet.

    .PARAMETER Plan
        Specifies the upgrade plan steps to execute. This is generated from New-AzUpgradeModulePlan.

    .EXAMPLE
        The following example invokes the upgrade plan for a PowerShell module named "myModule". Generate a plan, review the upgrade steps, warnings, and errors, and then perform the upgrade.

        # generate a plan and save it to a variable.
        $plan = New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.4.0 -DirectoryPath 'C:\Scripts\myModule'

        # write the plan to the console to review the upgrade steps, warnings, and errors.
        $plan

        # run the automatic upgrade plan and save the results to a variable.
        $results = Invoke-AzUpgradeModulePlan -Plan $Plan

        # write the upgrade results to the console.
        $results
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the upgrade plan steps to follow. This is generated from New-AzUpgradeModulePlan')]
        [UpgradePlan[]]
        $Plan
    )
    Process
    {
        $cmdStarted = Get-Date

        if ($Plan -eq $null -or $Plan.Count -eq 0)
        {
            Write-Verbose -Message "No module upgrade plan steps were provided. No upgrade will be executed."
            return
        }

        if ($PSCmdlet.ShouldProcess("$($Plan.Count) module upgrade steps will be executed and PowerShell files will be edited in place. This action is not reversable."))
        {
            $currentFile = $null
            $currentFileContents = $null

            $successFileUpdateCount = 0
            $successCommandUpdateCount = 0
            $failedFileUpdateCount = 0
            $failedCommandUpdateCount = 0

            $fileBatchResults = New-Object -TypeName 'System.Collections.Generic.List[UpgradeResult]'

            for ([int]$i = 0; $i -lt $Plan.Count; $i++)
            {
                $upgradeStep = $Plan[$i]
                $resetFileBuilder = $false

                $result = New-Object -TypeName UpgradeResult -ArgumentList $upgradeStep
                $fileBatchResults.Add($result)

                try
                {
                    if ($currentFile -eq $null)
                    {
                        Write-Verbose -Message ("[{0}] Reading file contents." -f $upgradeStep.FullPath)

                        $currentFile = $upgradeStep.FullPath
                        $fileContents = Get-Content -Path $currentFile -Raw
                        $currentFileContents = New-Object -TypeName System.Text.StringBuilder -ArgumentList $fileContents
                    }

                    if ($upgradeStep.PlanResult.ToString().StartsWith("Error") -eq $false)
                    {
                        Invoke-ModuleUpgradeStep -Step $upgradeStep -FileContent $currentFileContents
                    }
                    else
                    {
                        Write-Verbose -Message ("[{0}] Skipping {1} {2} due to error: {2}." -f `
                                $upgradeStep.Location, $upgradeStep.UpgradeType, `
                                $upgradeStep.Original, $upgradeStep.PlanResult)

                        $result.UpgradeResult = [UpgradeResultReasonCode]::UnableToUpgrade
                        $result.UpgradeResultReason = $upgradeStep.PlanResultReason
                    }

                    # on the final upgrade step? or the next step is a different file?
                    # then write/close the currently in-process file.

                    if ($i -eq ($Plan.Count - 1) -or ($Plan[($i + 1)].FullPath) -ne $currentFile)
                    {
                        Write-Verbose -Message ("[{0}] Saving file contents." -f $upgradeStep.FullPath)

                        Set-Content -Path $currentFile -Value $currentFileContents.ToString()

                        Out-FileBatchResult -ResultBatch $fileBatchResults -Success $true -Reason "Completed successfully."
                        $resetFileBuilder = $true
                        $successFileUpdateCount++
                        $successCommandUpdateCount += $fileBatchResults.Count
                    }
                }
                catch
                {
                    Out-FileBatchResult -ResultBatch $fileBatchResults -Success $false -Reason "A general error has occurred: $_"
                    $resetFileBuilder = $true
                    $failedFileUpdateCount++
                    $failedCommandUpdateCount += $fileBatchResults.Count
                }
                finally
                {
                    if ($resetFileBuilder -eq $true)
                    {
                        $currentFile = $null
                        $currentFileContents = $null
                        $fileBatchResults.Clear()
                    }
                }
            }

            Send-MetricsIfDataCollectionEnabled -Operation Upgrade `
                -ParameterSetName $PSCmdlet.ParameterSetName `
                -Duration ((Get-Date) - $cmdStarted) `
                -Properties ([PSCustomObject]@{
                    SuccessFileUpdateCount = $successFileUpdateCount
                    SuccessCommandUpdateCount = $successCommandUpdateCount
                    FailedFileUpdateCount = $failedFileUpdateCount
                    FailedCommandUpdateCount = $failedCommandUpdateCount
                })
        }
    }
}