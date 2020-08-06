function Set-ModulePreference
{
    <#
    .SYNOPSIS
        Sets the user's module preferences.

    .DESCRIPTION
        Sets the user's module preferences. Preferences are stored in a JSON config file under the user's home directory.

    .PARAMETER DataCollection
        Specifies the value for the data collection preference.

    .EXAMPLE
        PS C:\ Set-ModulePreference -DataCollectionEnabled $false
        Sets the data collection preference to false.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            ParameterSetName='DataCollection',
            HelpMessage='Specify the value for the data collection preference.')]
        [System.Boolean]
        $DataCollectionEnabled
    )
    Process
    {
        # this will create the preferences if they haven't been initialized yet.
        $existingModulePreferences = Get-ModulePreferences

        $configurationDirectory = "$home\" + ([Constants]::ConfigurationDirectoryName)
        $configurationFileFullPath = Join-Path -Path $configurationDirectory -ChildPath ([Constants]::ConfigurationFileName)

        if ($PSCmdlet.ParameterSetName -eq 'DataCollection')
        {
            if ($existingModulePreferences.DataCollectionEnabled -ne $DataCollectionEnabled)
            {
                Write-Verbose -Message "Setting module preference DataCollectionEnabled to $DataCollectionEnabled"
                $existingModulePreferences.DataCollectionEnabled = $DataCollectionEnabled
                $null = $existingModulePreferences | ConvertTo-Json | Out-File -FilePath $configurationFileFullPath -Force -Encoding Default
            }
            else
            {
                Write-Verbose -Message "Module preference DataCollectionEnabled is already set to $DataCollectionEnabled"
            }
        }

        Write-Output -InputObject $existingModulePreferences
    }
}