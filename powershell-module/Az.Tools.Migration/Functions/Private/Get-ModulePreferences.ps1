function Get-ModulePreferences
{
    <#
    .SYNOPSIS
        Returns the current data collection settings for this module.

    .DESCRIPTION
        Returns the current data collection settings for this module.

        Data collection can be enabled or disabled with the Enable-AzUpgradeDataCollection and Disabled-AzUpgradeDataCollection commands.

    .EXAMPLE
        PS C:\ Get-ModulePreferences
        Returns the data collection settings.
    #>
    [CmdletBinding()]
    Param
    (
    )
    Process
    {
        $configurationDirectory = "$home\" + ([Constants]::ConfigurationDirectoryName)
        $configurationFileFullPath = Join-Path -Path $configurationDirectory -ChildPath ([Constants]::ConfigurationFileName)

        try
        {
            if ((Test-Path -Path $configurationFileFullPath) -eq $false)
            {
                Write-Verbose -Message "Module configuration file $configurationFileFullPath does not exist, creating it now."

                $null = New-Item -Path $configurationDirectory -ItemType Directory -Force

                $newConfig = New-Object -TypeName ModulePreferences
                $newConfig.DataCollectionEnabled = $true

                $null = $newConfig | ConvertTo-Json | Out-File -FilePath $configurationFileFullPath -Force -Encoding Default

                Write-Output -InputObject $newConfig
            }
            else
            {
                Write-Verbose -Message "Module configuration file $configurationFileFullPath exists, loading it now."

                $modulePreferencesRawJson = Get-Content -Path $configurationFileFullPath -Raw
                $existingConfig = [Newtonsoft.Json.JsonConvert]::DeserializeObject($modulePreferencesRawJson, [ModulePreferences])

                Write-Output -InputObject $existingConfig
            }
        }
        catch
        {
            Write-Verbose -Message "Configuration file error: $_"

            # if we hit configuration file serialization issues, or file i/o
            # problems, then return an option set that assumes the user has
            # turned off data collection -- just to be safe.

            $newConfig = New-Object -TypeName ModulePreferences
            $newConfig.DataCollectionEnabled = $false
            Write-Output -InputObject $newConfig
        }
    }
}