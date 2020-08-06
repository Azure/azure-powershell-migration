function Enable-AzUpgradeDataCollection
{
    <#
    .SYNOPSIS
        Enables the setting that allows Az.Tools.Migration to send usage metrics to Microsoft.

    .DESCRIPTION
        Enables the setting that allows Az.Tools.Migration to send usage metrics to Microsoft.

        Usage metrics are opted-in by default. To disable usage metrics, run the Disabled-AzUpgradeDataCollection cmdlet.

        This setting is scoped to the user profile and persists between PowerShell sessions.

    .EXAMPLE
        PS C:\ Enable-AzUpgradeDataCollection
        Enables the metrics collection for Az.Tools.Migration.
    #>
    [CmdletBinding()]
    Param
    (
    )
    Process
    {
        Set-ModulePreference -DataCollectionEnabled $true
    }
}