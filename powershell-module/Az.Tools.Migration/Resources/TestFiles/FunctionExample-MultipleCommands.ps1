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
        Test-Connection -TargetName $TargetName -IPv4 -Count 5

        try
        {
            Get-ChildItem -Path "C:\users\user"
        }
        catch
        {
            throw "Error!"
        }

        Get-Help *content*
    }
}