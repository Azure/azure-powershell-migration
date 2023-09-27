function Get-AzUpgradeCmdletSpec
{
    <#
    .SYNOPSIS
        Returns a dictionary containing cmdlet specification objects for the specified module.

    .DESCRIPTION
        Returns a dictionary containing cmdlet specification objects for the specified module.

    .PARAMETER ModuleName
        Specify the name of the module to load command definitions from.

    .PARAMETER ModuleVersion
        Specify the version of the module to load command definitions from.

    .EXAMPLE
        PS C:\> Get-AzUpgradeCmdletSpec -AzureRM
        Returns the dictionary containing cmdlet specification objects for AzureRM 6.13.1.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            ParameterSetName = "AzureRM",
            HelpMessage="Import command definitions from AzureRM modules.")]
        [System.Management.Automation.SwitchParameter]
        $AzureRM,

        [Parameter(
            Mandatory=$true,
            ParameterSetName = "Az",
            HelpMessage="Import command definitions from Az modules.")]
        [System.Management.Automation.SwitchParameter]
        $Az,

        [Parameter(
            Mandatory=$true,
            ParameterSetName = "Az",
            HelpMessage="Specify the version of the module to import command definitions from.")]
        [System.String]
        [ValidateSet('latest')]
        [ValidateNotNullOrEmpty()]
        $ModuleVersion
    )
    Process
    {
        $ModuleSpecFolder = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase `
            -ChildPath "Resources\ModuleSpecs"
        if ($PSBoundParameters.ContainsKey('AzureRM')) {
            $ModuleSpecFolder = Join-Path -Path $ModuleSpecFolder -ChildPath "AzureRM\6.13.1"
        } else {
            $version = Get-ChildItem -Path "$ModuleSpecFolder/Az/$ModuleVersion" -Name
            $ModuleSpecFolder = Join-Path -Path $ModuleSpecFolder -ChildPath "Az\$ModuleVersion\$version"
        }

        if ((Test-Path -Path $ModuleSpecFolder) -eq $false)
        {
            throw "No module spec files found for module: $ModuleName $version under $ModuleSpecFolder"
        }

        $ModuleSpecFiles = Get-ChildItem -Path $ModuleSpecFolder -File

        if ($ModuleSpecFiles -eq $null)
        {
            throw "No module spec files found for module: $ModuleName $version under $ModuleSpecFolder"
        }

        $results = New-Object -TypeName 'System.Collections.Generic.Dictionary[System.String,CommandDefinition]' -ArgumentList (, [System.StringComparer]::OrdinalIgnoreCase)

        foreach ($specFile in $ModuleSpecFiles)
        {
            try
            {
                $specFileRawJson = Get-Content -Path $specFile.FullName -Raw
                $specObjects = [Newtonsoft.Json.JsonConvert]::DeserializeObject($specFileRawJson, [CommandDefinition[]])

                foreach ($specObject in $specObjects)
                {
                    $results[$specObject.Command] = $specObject
                }
            }
            catch
            {
                Write-Warning -Message "Failed to load module spec file: $($specFile.Name): $_"
            }
        }

        Write-Output -InputObject $results
    }
}