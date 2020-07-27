function Invoke-MyCmdlet
{
    <#
    .SYNOPSIS
        Invokes my test cmdlet.

    .DESCRIPTION
        Invokes my test cmdlet.

    .EXAMPLE
        PS C:\> Invoke-MyCmdlet
        Runs the test cmdlet.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the target name.")]
        [System.String]
        $TargetName
    )
    Process
    {
        try
        {
            Test-Connection -TargetName $TargetName `
                -IPv4 `
                -Count (Get-RequestCount -Test "Value") `
                -OriginalCommandParam "Value2"
        }
        catch
        {
            throw "Error!"
        }
    }
}