<#
.SYNOPSIS
    Generates Az module cmdlet spec files.

.DESCRIPTION
    Generates Az module cmdlet spec files. This script makes the following assumptions:
    1. You already have the target Az module installed to the local user scope from a PowerShell Core session.
    2. This script is executed from a PowerShell Core session.
    3. This script is running from a Windows machine.

.PARAMETER AzVersion
    Specify the exact Az version you would like to generate specs for.

.PARAMETER OutputDirectory
    Specify the output folder for where the files will be generated.

.EXAMPLE
    PS C:\ .\New-AzCmdletSpecs.ps1 -AzVersion "4.4.0" -OutputDirectory "$home\desktop\AzCmdletSpec"
    Generates a new Az module 4.4.0 cmdlet spec in the user's desktop folder.
#>
[CmdletBinding()]
Param
(
    [Parameter(
        Mandatory=$true,
        HelpMessage='Specify the exact Az version you would like to generate specs for.')]
    [System.String]
    [ValidateNotNullOrEmpty()]
    $AzVersion,

    [Parameter(
        Mandatory=$true,
        HelpMessage='Specify the output folder for where the files will be generated.')]
    [System.String]
    [ValidateNotNullOrEmpty()]
    $OutputDirectory
)

# create the output directories if they do not exist.

if (!(Test-Path $OutputDirectory))
{
    $null = New-Item -Path $OutputDirectory -Type Directory
}

$AliasOutputDirectory = Join-Path -Path $OutputDirectory -ChildPath "CmdletAliases"
if (!(Test-Path $AliasOutputDirectory))
{
    $null = New-Item -Path $AliasOutputDirectory -Type Directory
}

# load the module entrypoint .psm1 file because it lists all of the sub-modules to import.
# parse this output to find each sub-module.
# then call the function to generate a module spec for each one.

Write-Host "Importing Az module version $AzVersion"
Import-Module -Name Az -RequiredVersion $AzVersion -ErrorAction Stop

$moduleEntrypoint = "$Home\Documents\WindowsPowerShell\Modules\Az\$AzVersion\Az.psm1"
$moduleImportStatements = Get-Content $moduleEntrypoint | Select-String -Pattern "Import-Module Az." | ForEach-Object -Process { $_.Line.Trim() }

foreach ($importStatement in $moduleImportStatements)
{
    $splitLine = $importStatement.Split(' ')
    if ($splitLine.Length -ge 4)
    {
        $SubModuleName = $splitLine[1]
        $SubModuleVersion = $splitLine[3]

        Write-Host "Building module spec for $SubModuleName $SubModuleVersion"

        New-ModuleCommandDefinitionsFile -ModuleName $SubModuleName -ModuleVersion $SubModuleVersion -OutputDirectory $OutputDirectory
    }
}

# phase 2: create AzureRM alias mappings file.

Write-Host "Creating AzureRM alias mapping file for Az version $AzVersion"

$existingAliasesSet = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]'
foreach ($alias in (Get-Alias))
{
    if ($alias.Name -notlike "*Azure*" -and $alias.Name -notlike "*-Az*" -and $alias.Name -notin @('Resolve-Error'))
    {
        $null = $existingAliasesSet.Add($alias.Name)
    }
}

# add the transition aliases to the current user scope
Enable-AzureRmAlias -Scope 'Process'

# find the new aliases added to the session.
$azureRmMappings = New-Object -TypeName 'System.Collections.Generic.List[PSCustomObject]'

foreach ($alias in (Get-Alias))
{
    if ($existingAliasesSet.Contains($alias.Name) -eq $false)
    {
        $mapping = [PSCustomObject]@{
            Name = $alias.Name;
            ResolvedCommand = $alias.Definition;
        }

        $azureRmMappings.Add($mapping)
    }
}

# save the output
$aliasOutputFile = Join-Path -Path $AliasOutputDirectory -ChildPath "Aliases.json"
$azureRmMappings | ConvertTo-Json -Depth 5 | Out-File -FilePath $aliasOutputFile -Force -Encoding Default

Write-Host "Script completed."