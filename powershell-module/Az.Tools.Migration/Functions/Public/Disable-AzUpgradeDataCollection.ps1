function Disable-AzUpgradeDataCollection
{
    <#
    .SYNOPSIS
        Disables the setting that allows Az.Tools.Migration to send usage metrics to Microsoft.

    .DESCRIPTION
        Disables the setting that allows Az.Tools.Migration to send usage metrics to Microsoft.

        Usage metrics are opted-in by default. To disable usage metrics, run this cmdlet.

        This setting is scoped to the user profile and persists between PowerShell sessions.

    .EXAMPLE
        PS C:\ Disable-AzUpgradeDataCollection
        Disables the metrics collection for Az.Tools.Migration.
    #>
    [CmdletBinding()]
    Param
    (
    )
    Process
    {
        Set-ModulePreference -DataCollectionEnabled $false
    }
}