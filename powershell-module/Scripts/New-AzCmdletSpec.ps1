<#
.SYNOPSIS
    Generates Az module cmdlet spec files.

.DESCRIPTION
    Generates Az module cmdlet spec files. This script makes the following assumptions:
    1. You already have the target Az module installed to the local user scope from a PowerShell Core session.
    2. You have already loaded the Az.Tools.Migration module into this PowerShell session.
    3. This script is executed from a PowerShell Core session.
    4. This script is running from a Windows machine.

.PARAMETER AzVersion
    Specify the exact Az version you would like to generate specs for.

.PARAMETER OutputDirectory
    Specify the output folder for where the files will be generated.

.EXAMPLE
    PS C:\ .\New-AzCmdletSpec.ps1 -AzVersion "5.2.0" -OutputDirectory "$home\desktop\AzCmdletSpec"
    Generates a new Az module 5.2.0 cmdlet spec in the user's desktop folder.
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

function New-ModuleCommandDefinitionsFile
{
    <#
    .SYNOPSIS
        Creates a new command definition file for the given module.

    .DESCRIPTION
        Creates a new command definition file for the given module. The command definition files are used to help identify command upgrade spots.

    .PARAMETER ModuleName
        Specify the name of the module to create a command definitions file for.

    .PARAMETER ModuleVersion
        Specify the name of the module to create a command definitions file for.

    .PARAMETER OutputDirectory
        Specify the folder location to save the new definitions file.

    .PARAMETER MinimumVersion
        Specify to use a 'minimumversion' flag when searching, instead of required version.

    .EXAMPLE
        PS C:\> New-ModuleCommandDefinitionsFile -ModuleName "Azure.Storage" -ModuleVersion "5.2.0" -OutputDirectory "C:\users\user\desktop"
        Creates a new module definition json file for the given module.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the name of the module to create a command definitions file for.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $ModuleName,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the version of the module to create a command definitions file for.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $ModuleVersion,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the folder location to save the new definitions file.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $OutputDirectory,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Use the -MinimumVersion flag when searching for the module.")]
        [Switch]
        $MinimumVersion
    )
    Process
    {
        $defaultParamNames = @("Debug", "ErrorAction", "ErrorVariable", "InformationAction", "InformationVariable", "OutVariable", "OutBuffer", "PipelineVariable", "Verbose", "WarningAction", "WarningVariable")

        if ($PSBoundParameters.ContainsKey('MinimumVersion'))
        {
            $module = Get-Module -ListAvailable | Where-Object { $_.Name -eq $ModuleName -and $_.Version -ge $ModuleVersion } | Select-Object -First 1
        }
        else
        {
            $module = Get-Module -ListAvailable | Where-Object { $_.Name -eq $ModuleName -and $_.Version -eq $ModuleVersion } | Select-Object -First 1
        }

        if ($module -eq $null)
        {
            throw "No module was found that matches the specified name [$ModuleName] and version number [$ModuleVersion]."
        }

        $exportedCommandResults = New-Object -TypeName 'System.collections.Generic.List[CommandDefinition]'

        foreach ($exportedCommand in $module.ExportedCommands.GetEnumerator())
        {
            Write-Verbose -Message "Processing command: $($exportedCommand.Key)"

            $exportedCommandValue = $exportedCommand.Value

            $definition = New-Object CommandDefinition
            $definition.Command = $exportedCommandValue.Name
            $definition.SourceModule = $exportedCommandValue.ModuleName
            $definition.Version = $exportedCommandValue.Version
            $definition.Parameters = New-Object -TypeName 'System.Collections.Generic.List[CommandDefinitionParameter]'

            if ($exportedCommandValue.Value.CommandType -eq "Cmdlet")
            {
                $definition.IsAlias = $false
            }
            elseif ($exportedCommandValue.Value.CommandType -eq "Alias")
            {
                $definition.IsAlias = $true
            }

            # lookup the command to find the parameters

            $moduleCommand = Get-Command -Name $exportedCommandValue.Name -ErrorAction SilentlyContinue -FullyQualifiedModule @{ ModuleName = $exportedCommandValue.ModuleName; ModuleVersion = $exportedCommandValue.Version } | Select-Object -First 1

            if ($moduleCommand -ne $null)
            {
                foreach ($moduleCommandParam in $moduleCommand.Parameters.GetEnumerator())
                {
                    $moduleCommandParamValue = $moduleCommandParam.Value

                    if ($moduleCommandParamValue.Name -notin $defaultParamNames)
                    {
                        $moduleCommandParamDefinition = New-Object -TypeName CommandDefinitionParameter
                        $moduleCommandParamDefinition.Name = $moduleCommandParamValue.Name

                        if ($moduleCommandParamValue.Aliases.Count -gt 0)
                        {
                            $commandParamAliases = New-Object -TypeName 'System.String[]' -ArgumentList $moduleCommandParamValue.Aliases.Count
                            $moduleCommandParamValue.Aliases.CopyTo($commandParamAliases, 0)

                            $moduleCommandParamDefinition.Aliases = $commandParamAliases
                        }

                        $definition.Parameters.Add($moduleCommandParamDefinition)
                    }
                }

                # does this command support dynamic parameters?
                $dynamicImplemented = $moduleCommand.ImplementingType.ImplementedInterfaces | Where-Object -FilterScript { $_.Name -eq 'IDynamicParameters' }
                if ($dynamicImplemented -ne $null)
                {
                    $definition.SupportsDynamicParameters = $true
                }

                $exportedCommandResults.Add($definition)
            }
            else
            {
                Write-Warning -Message "Command [$($exportedCommandValue.Name)] was defined in the module, but the command definition was not found."
            }
        }

        $outputFile = Join-Path -Path $OutputDirectory -ChildPath "$ModuleName.$ModuleVersion.Cmdlets.json"
        $exportedCommandResults | ConvertTo-Json -Depth 5 -AsArray | Out-File -FilePath $outputFile -Force
    }
}

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

$moduleEntrypoint = "$Home\Documents\PowerShell\Modules\Az\$AzVersion\Az.psm1"
$moduleImportStatements = Get-Content $moduleEntrypoint | Select-String -Pattern "Import-Module Az." | ForEach-Object -Process { $_.Line.Trim() }

foreach ($importStatement in $moduleImportStatements)
{
    $splitLine = $importStatement.Split(' ')
    if ($splitLine.Length -ge 4)
    {
        $SubModuleName = $splitLine[1]
        $SubModuleVersion = $splitLine[3]

        Write-Host "Building module spec for $SubModuleName $SubModuleVersion"

        if ($importStatement -match "MinimumVersion")
        {
            New-ModuleCommandDefinitionsFile -ModuleName $SubModuleName -ModuleVersion $SubModuleVersion -OutputDirectory $OutputDirectory -MinimumVersion
        }
        else
        {
            New-ModuleCommandDefinitionsFile -ModuleName $SubModuleName -ModuleVersion $SubModuleVersion -OutputDirectory $OutputDirectory
        }
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
$azureRmMappings | ConvertTo-Json -Depth 5 | Out-File -FilePath $aliasOutputFile -Force

Write-Host "Script completed."