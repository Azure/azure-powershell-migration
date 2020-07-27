function Invoke-ModuleUpgradeStep
{
    <#
    .SYNOPSIS
        Runs the individual module upgrade step against the file contents.

    .DESCRIPTION
        Runs the individual module upgrade step against the file contents. The file contents are passed in as a stringbuilder
        and the edits for this individual upgrade step are performed against that directly.

    .PARAMETER Step
        Specify the upgrade step.

    .PARAMETER FileContents
        Specify the file contents wrapped in a stringbuilder.

    .EXAMPLE
        PS C:\ Invoke-ModuleUpgradeStep -Step $upgradeStep -FileContent $contentsBuilder
        Performs an in-line text update for the specified module upgrade step.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the upgrade step.')]
        [UpgradeStep]
        [ValidateNotNull()]
        $Step,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the file contents wrapped in a stringbuilder.')]
        [System.Text.StringBuilder]
        [ValidateNotNull()]
        $FileContent
    )
    Process
    {
        switch ($Step.UpgradeType)
        {
            "Cmdlet"
            {
                Write-Verbose -Message ("[{0}:{1}:{2}] Updating cmdlet {3} to {4}." `
                        -f $Step.FileName, $Step.StartLine, $Step.StartColumn, `
                        $Step.OriginalCmdletName, $Step.ReplacementCmdletName)

                # safety check
                # ensure that the file offsets are an exact match.
                Confirm-StringBuilderSubstring -FileContent $FileContent -Substring $Step.OriginalCmdletName `
                    -StartOffset $Step.StartOffset -EndOffset $Step.EndOffset

                # replacement code
                $null = $FileContent.Remove($Step.StartOffset, ($Step.EndOffset - $Step.StartOffset));
                $null = $FileContent.Insert($Step.StartOffset, $Step.ReplacementCmdletName);
            }
            "CmdletParameter"
            {
                Write-Verbose -Message ("[{0}:{1}:{2}] Updating cmdlet parameter {3} to {4}." `
                        -f $Step.FileName, $Step.StartLine, $Step.StartColumn, `
                        $Step.OriginalParameterName, $Step.ReplacementParameterName)

                # safety check
                # ensure that the file offsets are an exact match.
                Confirm-StringBuilderSubstring -FileContent $FileContent -Substring ("-{0}" -f $Step.OriginalParameterName) `
                    -StartOffset $Step.StartOffset -EndOffset $Step.EndOffset

                # replacement code
                $null = $FileContent.Remove($Step.StartOffset, ($Step.EndOffset - $Step.StartOffset));
                $null = $FileContent.Insert($Step.StartOffset, ("-{0}" -f $Step.ReplacementParameterName));
            }
            default
            {
                throw 'Unexpected upgrade step type found.'
            }
        }
    }
}