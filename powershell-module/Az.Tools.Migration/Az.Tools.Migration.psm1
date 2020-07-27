<#
    The module manifest (.psd1) defines this file as the entry point or root of the module.
    Ensure that all of the module functionality is loaded directly from this file.
#>

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