<#
    The module manifest (.psd1) defines this file as the entry point or root of the module.
    Ensure that all of the module functionality is loaded directly from this file.
#>

# conditionally load required assemblies (in this case Newtonsoft.Json)
# PowerShell Core has this assembly loaded by default.
# Windows PowerShell does not ship with this so it usually needs to be loaded.

$jsonType = [System.AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object { $_.GetTypes() | Where-Object { $_.FullName -eq "Newtonsoft.Json.JsonConvert" } }

if ($jsonType -eq $null)
{
    # type is not already loaded.
    # attempt to load this assembly from the resources folder.
    Add-Type -Path "$PSScriptRoot\Resources\Assembly\Newtonsoft.Json.12.0.3\Newtonsoft.Json.dll" -ErrorAction Stop
}

# load classes

foreach ($classFile in (Get-ChildItem -Path "$PSScriptRoot\Classes" -Recurse -Include "*.ps1"))
{
    . $classFile
}

# load functions

foreach ($functionFile in (Get-ChildItem -Path "$PSScriptRoot\Functions" -Recurse -Include "*.ps1"))
{
    . $functionFile
}