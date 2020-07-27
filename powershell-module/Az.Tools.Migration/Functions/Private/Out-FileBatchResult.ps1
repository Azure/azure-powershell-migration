function Out-FileBatchResult
{
    <#
    .SYNOPSIS
        Writes a batch of file update results to the pipeline.

    .DESCRIPTION
        Writes a batch of file update results to the pipeline.

    .PARAMETER Results
        Specify the results batch.

    .PARAMETER Success
        Specify if this batch of updates was successful.

    .PARAMETER Reason
        Specify the reason/message for success or failure.

    .EXAMPLE
        PS C:\ Out-FileBatchResult -ResultBatch $resultsBatch -Success $true -Reason "Completed successfully"
        Writes the current batch of file update results to the pipeline.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the results batch.')]
        [System.Collections.Generic.List[UpgradeResult]]
        [ValidateNotNull()]
        $ResultBatch,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify if this batch of updates was successful.')]
        [System.Boolean]
        [ValidateNotNull()]
        $Success,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the reason/message for success or failure.')]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $Reason
    )
    Process
    {
        foreach ($result in $ResultBatch)
        {
            # set the reason and success flag
            $result.Success = $Success
            $result.Reason = $Reason

            # write the output object
            Write-Output -InputObject $result
        }
    }
}