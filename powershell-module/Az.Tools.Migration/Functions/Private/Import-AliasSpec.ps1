function Import-AliasSpec
{
    <#
    .SYNOPSIS
        Imports the upgrade alias objects from the specified module specs.

    .DESCRIPTION
        Imports the upgrade alias objects from the specified module specs.

    .PARAMETER ModuleVersion
        Specify the version of the module to import command aliases from.

    .EXAMPLE
        PS C:\> Import-AliasSpec -ModuleVersion "4.2.0"
        Imports the upgrade alias objects for Az 4.2.0.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the version of the module to import command definitions from.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $ModuleVersion
    )
    Process
    {
        $aliasSpecFile = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase `
            -ChildPath "Resources\ModuleSpecs\Az\$ModuleVersion\CmdletAliases\Aliases.json"

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