function Get-DataCollectionSettings
{
    <#
    .SYNOPSIS
        Returns the current data collection settings for this module.

    .DESCRIPTION
        Returns the current data collection settings for this module.

        Data collection can be enabled or disabled with the Enable-AzUpgradeDataCollection and Disabled-AzUpgradeDataCollection commands.

    .EXAMPLE
        PS C:\ Get-DataCollectionSettings
        Returns the data collection settings.
    #>
    [CmdletBinding()]
    Param
    (
    )
    Process
    {
        # pull settings from persisted storage.
        # if they don't exist, create new settings with default.
        # if we can't pull the settings for some reason, then ensure we run without data collection.

        $settings = New-Object -TypeName DataCollectionSettings
        $settings.DataCollectionEnabled = $true

        Write-Output -InputObject $settings
    }
}