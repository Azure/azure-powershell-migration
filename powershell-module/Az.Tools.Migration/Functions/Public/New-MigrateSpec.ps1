function New-MigrateSpec
{
    <#
    .SYNOPSIS
        Generate new migration sepc file based on current spec files.

    .DESCRIPTION
        Generate new migration sepc file based on current spec files.

    .PARAMETER SourceModuleName
        The name of the source moudle like "AzureRM" and "Az".

    .PARAMETER SourceVersion
        The version of the source module.

    .PARAMETER TargetModuleName
        The name of the target module like "Az".

    .PARAMETER TargetVersion
        The version of the target module.

    .EXAMPLE
        New-MigrateSpec -SourceModuleName "AzureRM" -SourceVersion "6.13.1" `
                        -TargetModuleName "Az" -TargetVersion "4.8.0"
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the cmdlet type of the source module.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $SourceModuleName,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the version of the source module.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $SourceVersion,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the cmdlet type of the target module.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $TargetModuleName,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the version of the target module.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $TargetVersion
    )
    Process
    {
        $sourceModuleSpec = Get-AzUpgradeCmdletSpec -ModuleName $SourceModuleName -ModuleVersion $SourceVersion
        $targetModuleSpec = Get-AzUpgradeCmdletSpec -ModuleName $TargetModuleName -ModuleVersion $TargetVersion
        $aliasMappingSpec = Get-AzUpgradeAliasSpec -ModuleVersion $TargetVersion

        $defaultParamNames = @("Debug", "ErrorAction", "ErrorVariable", "InformationAction", "InformationVariable", "OutVariable", "OutBuffer", "PipelineVariable", "Verbose", "WarningAction", "WarningVariable", "WhatIf", "Confirm", "DefaultProfile")

        $cmdletList = New-Object -TypeName 'System.Collections.Generic.List[PScustomObject]'
        $commonSuggestions = New-Object -TypeName 'System.Collections.Generic.List[PScustomObject]'
        $commonSuggestionsSet = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]'

        foreach ($sourceCmdletName in $sourceModuleSpec.Keys)
        {
            $sourceCmdlet = $sourceModuleSpec[$sourceCmdletName]

            $suggestionList = New-Object -TypeName 'System.Collections.Generic.List[PSCustomObject]'

            if ($aliasMappingSpec.ContainsKey($sourceCmdletName) -and
                -not($targetModuleSpec.ContainsKey($aliasMappingSpec[$sourceCmdletName])))
            {
                $suggestion = [PSCustomObject]@{
                    Type = "CmdletNotFound"
                }
                $suggestionList.Add($suggestion)
            }
            elseif ($aliasMappingSpec.ContainsKey($sourceCmdletName))
            {
                $targetCmdletName = $aliasMappingSpec[$sourceCmdletName]
                $targetCmdlet = $targetModuleSpec[$targetCmdletName]

                $suggestion = [PSCustomObject]@{
                    Type = "CmdletRename"
                    ResolvedName = $targetCmdletName
                }
                $suggestionList.Add($suggestion)

                if ($targetCmdlet.Aliases)
                {
                    $suggestion = [PSCustomObject]@{
                        Type = "CmdletAlias"
                        CmdletAlias = $targetCmdlet.Aliases
                    }
                    $suggestionList.Add($suggestion)
                }

                foreach ($sourceParameter in $sourceCmdlet.Parameters)
                {
                    $matchedDirectName = $targetCmdlet.Parameters | `
                            Where-Object -FilterScript { $_.Name -eq $sourceParameter.Name }
                    $matchedAliasName = $tragetCmdlet.Parameters | `
                            Where-Object -FilterScript { $_.Aliases -contains $sourceParameter.Name }
                    if ($matchedDirectName -eq $null -and $matchedAliasName -eq $null)
                    {
                        $suggestion = [PSCustomObject]@{
                            Type = "ParameterNotFound"
                            ParameterName = $sourceParameter.Name
                            ParameterAliases = $sourceParameter.Aliases
                        }
                        $suggestionList.Add($suggestion)
                    }

                    if ($sourceParameter.Aliases)
                    {
                        $suggestion = [PSCustomObject]@{
                            Type = "ParameterAlias"
                            ParameterName = $sourceParameter.Name
                            ParameterAliases = $sourceParameter.Aliases
                        }
                        if ($defaultParamNames.Contains($sourceParameter.Name))
                        {
                            if (-not $commonSuggestionsSet.Contains($sourceParameter.Name))
                            {
                                $commonSuggestions.Add($suggestion)
                                $commonSuggestionsSet.Add($sourceParameter.Name)
                            }
                        }
                        else
                        {
                            $suggestionList.Add($suggestion)
                        }
                    }
                }

                foreach ($targetParameter in $targetCmdlet.Parameters)
                {
                    if ($defaultParamNames -contains $targetParameter.Name)
                    {
                        continue;
                    }
                    $matchedDirectName = $sourceCmdlet.Parameters | `
                            Where-Object -FilterScript { $_.Name -eq $targetParameter.Name }
                    $matchedAliasName = $sourceCmdlet.Parameters | `
                            Where-Object -FilterScript { $_.Aliases -contains $targetParameter.Name }
                    if ($matchedDirectName -eq $null -and $matchedAliasName -eq $null)
                    {
                        $suggestion = [PSCustomObject]@{
                            Type = "ParameterRequired"
                            ParameterName = $targetParameter.Name
                        }
                        $suggestionList.Add($suggestion)
                    }
                }
            }

            if ($suggestionList.count)
            {
                $cmdlet = [PSCustomObject]@{
                    CmdletName = $sourceCmdletName
                    Suggestions = $suggestionList
                }
                $cmdletList.Add($cmdlet)
            }
        }

        $spec = [PSCustomObject]@{
            Version = "1.0"
            SourceModuleName = $sourceModuleName
            SourceVersion = $sourceVersion
            TargetModuleName = $targetModuleName
            TargetVersion = $targetVersion
            CommonSuggestions = $commonSuggestions
            Cmdlets = $CmdletList
        }

        $specOutputFile = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase `
            -ChildPath "Resources\ModuleSpecs\spec.json"
        $spec | ConvertTo-Json -Depth 5 | Out-File -FilePath $specOutputFile -Force
    }
}