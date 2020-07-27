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

    .EXAMPLE
        PS C:\> New-ModuleCommandDefinitionsFile -ModuleName "Azure.Storage" -ModuleVersion "4.6.1" -OutputDirectory "C:\users\user\desktop"
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
        $OutputDirectory
    )
    Process
    {
        $defaultParamNames = @("Debug", "ErrorAction", "ErrorVariable", "InformationAction", "InformationVariable", "OutVariable", "OutBuffer", "PipelineVariable", "Verbose", "WarningAction", "WarningVariable")

        $module = Get-Module -ListAvailable | Where-Object { $_.Name -eq $ModuleName -and $_.Version -eq $ModuleVersion } | Select-Object -First 1

        if ($module -eq $null)
        {
            throw "No module was found that matches the specified name and version."
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

                $exportedCommandResults.Add($definition)
            }
            else
            {
                Write-Warning -Message "Command [$($exportedCommandValue.Name)] was defined in the module, but the command definition was not found."
            }
        }

        $outputFile = Join-Path -Path $OutputDirectory -ChildPath "$ModuleName.$ModuleVersion.Cmdlets.json"
        $exportedCommandResults | ConvertTo-Json -Depth 5 -AsArray | Out-File -FilePath $outputFile -Force -Encoding Default
    }
}