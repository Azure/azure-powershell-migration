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
        PS C:\> Get-AzUpgradeCmdletSpec -ModuleName "AzureRM" -ModuleVersion "6.13.1"
        Returns the dictionary containing cmdlet specification objects for AzureRM 6.13.1.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the name of the module to import command definitions from.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $ModuleName,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the version of the module to import command definitions from.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $ModuleVersion
    )
    Process
    {
        $ModuleSpecFolder = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase `
            -ChildPath "Resources\ModuleSpecs\$ModuleName\$ModuleVersion"

        if ((Test-Path -Path $ModuleSpecFolder) -eq $false)
        {
            throw "No module spec files found for module: $ModuleName $ModuleVersion"
        }

        $ModuleSpecFiles = Get-ChildItem -Path $ModuleSpecFolder -File

        if ($ModuleSpecFiles -eq $null)
        {
            throw "No module spec files found for module: $ModuleName $ModuleVersion"
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