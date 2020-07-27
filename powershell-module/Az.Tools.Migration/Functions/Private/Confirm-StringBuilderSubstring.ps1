function Confirm-StringBuilderSubstring
{
    <#
    .SYNOPSIS
        Confirms that the substring exists at the specified offset in the string builder.

    .DESCRIPTION
        Confirms that the substring exists at the specified offset in the string builder. An error will be thrown if the offset positions do not match expectation.

    .PARAMETER FileContents
        Specify the file contents wrapped in a stringbuilder.

    .PARAMETER Substring
        Specify the substring to validate.

    .PARAMETER StartOffset
        Specify the start offset position.

    .PARAMETER EndOffset
        Specify the end offset position.

    .EXAMPLE
        PS C:\ Confirm-StringBuilderSubstring -FileContents $builder -Substring '-test' -StartOffset 23 -EndOffset 28
        Confirms that the substring '-test' exists at the specified offset.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the file contents wrapped in a stringbuilder.')]
        [System.Text.StringBuilder]
        [ValidateNotNull()]
        $FileContents,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the substring to validate.')]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $Substring,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the start offset position.')]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $StartOffset,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the end offset position.')]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $EndOffset
    )
    Process
    {
        if ($FileContents.Length -lt $StartOffset -or $FileContents.Length -lt $EndOffset)
        {
            throw 'Upgrade step failed: Offset positions are beyond the file range.'
        }

        for (([int]$i = $StartOffset), ([int]$j = 0); $i -lt $EndOffset; ($i++), ($j++))
        {
            if ($FileContents[$i] -ne $Substring[$j])
            {
                throw 'Upgrade step failed: Offset positions are unexpected. This file may have already been upgraded or has changed since the upgrade plan was generated.'
            }
        }
    }
}