function Get-AzUpgradeAliasSpec
{
    <#
    .SYNOPSIS
        Returns a dictionary containing cmdlet alias mappings for the specified Az module version.

    .DESCRIPTION
        Returns a dictionary containing cmdlet alias mappings for the specified Az module version.

    .PARAMETER ModuleVersion
        Specify the version of the module to import command aliases from.

    .EXAMPLE
        PS C:\> Get-AzUpgradeAliasSpec -ModuleVersion latest
        Returns the cmdlet alias mappings table for current Az version which is 10.3.0.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the version of the module to import command definitions from.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('latest')]
        $ModuleVersion
    )
    Process
    {
        $path = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath "\Resources\ModuleSpecs\Az\$ModuleVersion"
        $version = Get-ChildItem -Path $path -Name

        $aliasSpecFile = Join-Path -Path $path `
            -ChildPath "$version\CmdletAliases\Aliases.json"

        if ((Test-Path -Path $aliasSpecFile) -eq $false)
        {
            throw "No alias spec files found for Az $ModuleVersion"
        }

        $specFileRawJson = Get-Content -Path $aliasSpecFile -Raw
        $specObjects = [Newtonsoft.Json.JsonConvert]::DeserializeObject($specFileRawJson, [AliasMapping[]])

        $aliasMap = New-Object -TypeName 'System.Collections.Generic.Dictionary[System.String,System.String]' -ArgumentList (, [System.StringComparer]::OrdinalIgnoreCase)

        foreach ($aliasObject in $specObjects)
        {
            $aliasMap[$aliasObject.Name] = $aliasObject.ResolvedCommand
        }

        Write-Output -InputObject $aliasMap
    }
}