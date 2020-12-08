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
        [UpgradePlan]
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
                Write-Verbose -Message ("[{0}] Updating Cmdlet {1} to {2}." `
                        -f $Step.Location, $Step.Original, $Step.Replacement)

                # safety check
                # ensure that the file offsets are an exact match.
                Confirm-StringBuilderSubstring -FileContent $FileContent -Substring $Step.Original `
                    -StartOffset $Step.SourceCommand.StartOffset -EndOffset $Step.SourceCommand.EndOffset

                # replacement code
                $null = $FileContent.Remove($Step.SourceCommand.StartOffset, ($Step.SourceCommand.EndOffset - $Step.SourceCommand.StartOffset));
                $null = $FileContent.Insert($Step.SourceCommand.StartOffset, $Step.Replacement);
            }
            "CmdletParameter"
            {
                Write-Verbose -Message ("[{0}] Updating CmdletParameter {1} to {2}." `
                        -f $Step.Location, $Step.Original, $Step.Replacement)

                # safety check
                # ensure that the file offsets are an exact match.
                Confirm-StringBuilderSubstring -FileContent $FileContent -Substring $Step.Original `
                    -StartOffset $Step.SourceCommandParameter.StartOffset -EndOffset $Step.SourceCommandParameter.EndOffset

                # replacement code
                $null = $FileContent.Remove($Step.SourceCommandParameter.StartOffset, ($Step.SourceCommandParameter.EndOffset - $Step.SourceCommandParameter.StartOffset));
                $null = $FileContent.Insert($Step.SourceCommandParameter.StartOffset, $Step.Replacement);
            }
            default
            {
                throw 'Unexpected upgrade step type found.'
            }
        }
    }
}