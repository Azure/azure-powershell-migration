function Get-MigrateSpec
{
    <#
    .SYNOPSIS
        Returns a MigrateSpec include the information about migrate

    .DESCRIPTION
        Returns a MigrateSpec include the information about migrate

    .EXAMPLE
        PS C:\> Get-MigrateSpec -ModuleVersion "4.8.0"
        Returns the migrate spec
    #>
    [CmdletBinding()]
    Param
    (
    )
    Process
    {
        $migrateSpecFile = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase `
            -ChildPath "Resources\ModuleSpecs\spec.json"

        if ((Test-Path -Path $migrateSpecFile) -eq $false)
        {
            throw "No spec files found"
        }

        $specFileRawJson = Get-Content -Path $migrateSpecFile -Raw

        $specObject = [Newtonsoft.Json.JsonConvert]::DeserializeObject($specFileRawJson, [MigrateSpec])

        Write-Output -InputObject $specObject
    }
}