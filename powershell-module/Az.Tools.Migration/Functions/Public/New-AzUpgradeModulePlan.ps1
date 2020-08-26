function New-AzUpgradeModulePlan
{
    <#
    .SYNOPSIS
        Generates a new upgrade plan for migrating to the Az PowerShell module.

    .DESCRIPTION
        Generates a new upgrade plan for migrating to the Az PowerShell module. The upgrade plan details the specific file/offset points that require changes when moving from AzureRM commands to Az commands.

    .PARAMETER FromAzureRmVersion
        Specifies the AzureRM module version used in your existing PowerShell scripts(s) or modules.

    .PARAMETER ToAzVersion
        Specifies the Az module version to upgrade to. Currently, only Az version 4.4.0 is supported.

    .PARAMETER FilePath
        Specifies the path to a single PowerShell file.

    .PARAMETER DirectoryPath
        Specifies the path to a folder where PowerShell scripts or modules reside.

    .PARAMETER AzureRmCmdReference
        Specifies the AzureRM command references output from the Find-AzUpgradeCommandReference cmdlet.

    .EXAMPLE
        The following example generates a new Az module upgrade plan for the script file 'C:\Scripts\my-azure-script.ps1'.

        New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.4.0 -FilePath 'C:\Scripts\my-azure-script.ps1'

    .EXAMPLE
        The following example generates a new Az module upgrade plan for the script and module files located under C:\Scripts.

        New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.4.0 -DirectoryPath 'C:\Scripts'

    .EXAMPLE
        The following example generates a new Az module upgrade plan for the script and module files under C:\Scripts.

        $references = Find-AzUpgradeCommandReference -DirectoryPath 'C:\Scripts' -AzureRmVersion '6.13.1'
        New-AzUpgradeModulePlan -ToAzVersion 4.4.0 -AzureRmCmdReference $references
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            ParameterSetName="FromReferences",
            HelpMessage='Specify the AzureRM command references collection output from the Find-AzUpgradeCommandReference cmdlet.')]
        [CommandReference[]]
        $AzureRmCmdReference,

        [Parameter(
            Mandatory=$true,
            ParameterSetName="FromNewSearchByFile",
            HelpMessage='Specify the Az module version to upgrade to.')]
        [Parameter(
            Mandatory=$true,
            ParameterSetName="FromNewSearchByDirectory",
            HelpMessage='Specify the Az module version to upgrade to.')]
        [System.String]
        [ValidateSet('6.13.1')]
        $FromAzureRmVersion,

        [Parameter(
            Mandatory=$true,
            ParameterSetName="FromNewSearchByFile",
            HelpMessage="Specify the path to a single PowerShell file.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $FilePath,

        [Parameter(
            Mandatory=$true,
            ParameterSetName="FromNewSearchByDirectory",
            HelpMessage="Specify the path to the folder where PowerShell scripts or modules reside.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $DirectoryPath,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the Az module version to upgrade to.')]
        [System.String]
        [ValidateSet('4.4.0')]
        $ToAzVersion
    )
    Process
    {
        $cmdStarted = Get-Date

        # if an existing set of command references was not provided
        # then call the Find cmdlet to search for those references.

        if ($PSCmdlet.ParameterSetName -eq 'FromNewSearchByFile')
        {
            Write-Verbose -Message "Searching for commands to upgrade, by file."
            $AzureRmCmdReference = Find-AzUpgradeCommandReference -FilePath $FilePath -AzureRmVersion $FromAzureRmVersion
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'FromNewSearchByDirectory')
        {
            Write-Verbose -Message "Searching for commands to upgrade, by directory."
            $AzureRmCmdReference = Find-AzUpgradeCommandReference -DirectoryPath $DirectoryPath -AzureRmVersion $FromAzureRmVersion
        }

        # we can't generate an upgrade plan without some cmdlet references, so quit early here if required.

        if ($AzureRmCmdReference -eq $null -or $AzureRmCmdReference.Count -eq 0)
        {
            Write-Verbose -Message "No AzureRm command references were found. No upgrade plan will be generated."
            return
        }
        else
        {
            Write-Verbose -Message "$($AzureRmCmdReference.Count) AzureRm command reference(s) were found. Upgrade plan will be generated."
        }

        Write-Verbose -Message "Importing cmdlet spec for Az $ToAzVersion"
        $azCmdlets = Import-CmdletSpec -ModuleName "Az" -ModuleVersion $ToAzVersion

        Write-Verbose -Message "Importing upgrade alias spec for Az $ToAzVersion"
        $upgradeAliases = Import-AliasSpec -ModuleVersion $ToAzVersion

        $defaultParamNames = @("Debug", "ErrorAction", "ErrorVariable", "InformationAction", "InformationVariable", "OutVariable", "OutBuffer", "PipelineVariable", "Verbose", "WarningAction", "WarningVariable", "WhatIf", "Confirm")

        # synchronous results output instead of async. the reason for this is that
        # we need to sort the object results before returning them to the caller.

        $planSteps = New-Object -TypeName 'System.Collections.Generic.List[UpgradePlan]'
        $planWarningSteps = New-Object -TypeName 'System.Collections.Generic.List[UpgradePlan]'
        $planErrorSteps = New-Object -TypeName 'System.Collections.Generic.List[UpgradePlan]'

        foreach ($rmCmdlet in $AzureRmCmdReference)
        {
            Write-Verbose -Message "Checking upgrade potential for instance of $($rmCmdlet.CommandName)"

            if ($upgradeAliases.ContainsKey($rmCmdlet.CommandName) -eq $false)
            {
                $errorResult = New-Object -TypeName UpgradePlan
                $errorResult.UpgradeType = [UpgradeStepType]::Cmdlet
                $errorResult.SourceCommand = $rmCmdlet
                $errorResult.FullPath = $rmCmdlet.FullPath
                $errorResult.StartOffset = $rmCmdlet.StartOffset
                $errorResult.Location = $rmCmdlet.Location
                $errorResult.Original = $rmCmdlet.CommandName
                $errorResult.PlanResultReason = "No matching upgrade alias found. Command cannot be automatically upgraded."
                $errorResult.PlanResult = [PlanResultReasonCode]::ErrorNoUpgradeAlias
                $errorResult.PlanSeverity = [DiagnosticSeverity]::Error

                $planErrorSteps.Add($errorResult)

                continue
            }

            $resolvedCommandName = $upgradeAliases[$rmCmdlet.CommandName]

            if ($azCmdlets.ContainsKey($resolvedCommandName) -eq $false)
            {
                $errorResult = New-Object -TypeName UpgradePlan
                $errorResult.UpgradeType = [UpgradeStepType]::Cmdlet
                $errorResult.SourceCommand = $rmCmdlet
                $errorResult.FullPath = $rmCmdlet.FullPath
                $errorResult.StartOffset = $rmCmdlet.StartOffset
                $errorResult.Location = $rmCmdlet.Location
                $errorResult.Original = $rmCmdlet.CommandName
                $errorResult.PlanResultReason = "No Az cmdlet spec found for $resolvedCommandName. Command cannot be automatically upgraded."
                $errorResult.PlanResult = [PlanResultReasonCode]::ErrorNoModuleSpecMatch
                $errorResult.PlanSeverity = [DiagnosticSeverity]::Error

                $planErrorSteps.Add($errorResult)

                continue
            }

            $cmdletUpgrade = New-Object -TypeName UpgradePlan
            $cmdletUpgrade.Original = $rmCmdlet.CommandName
            $cmdletUpgrade.Replacement = $resolvedCommandName
            $cmdletUpgrade.UpgradeType = [UpgradeStepType]::Cmdlet
            $cmdletUpgrade.SourceCommand = $rmCmdlet
            $cmdletUpgrade.FullPath = $rmCmdlet.FullPath
            $cmdletUpgrade.StartOffset = $rmCmdlet.StartOffset
            $cmdletUpgrade.Location = $rmCmdlet.Location

            if ($rmCmdlet.HasSplattedArguments -eq $false)
            {
                $cmdletUpgrade.PlanResultReason = "Command can be automatically upgraded."
                $cmdletUpgrade.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
                $cmdletUpgrade.PlanSeverity = [DiagnosticSeverity]::Information
                $planSteps.Add($cmdletUpgrade)
            }
            else
            {
                $cmdletUpgrade.PlanResultReason = "Cmdlet invocation uses splatted parameters. Consider unrolling to allow automated parameter upgrade checks."
                $cmdletUpgrade.PlanResult = [PlanResultReasonCode]::WarningSplattedParameters
                $cmdletUpgrade.PlanSeverity = [DiagnosticSeverity]::Warning
                $planWarningSteps.Add($cmdletUpgrade)
            }

            # check if parameters need to be updated

            if ($rmCmdlet.Parameters.Count -gt 0)
            {
                $resolvedAzCommand = $azCmdlets[$resolvedCommandName]

                foreach ($rmParam in $rmCmdlet.Parameters)
                {
                    if ($defaultParamNames -contains $rmParam.Name)
                    {
                        # direct match to a built-in default parameter
                        # no changes required.
                        continue
                    }

                    $matchedDirectName = $resolvedAzCommand.Parameters | Where-Object -FilterScript { $_.Name -eq $rmParam.Name }

                    if ($matchedDirectName -ne $null)
                    {
                        # direct match to the upgraded cmdlet's parameter name.
                        # no changes required.
                        continue
                    }

                    $matchedAliasName = $resolvedAzCommand.Parameters | Where-Object -FilterScript { $_.Aliases -contains $rmParam.Name }

                    if ($matchedAliasName -ne $null)
                    {
                        # alias match to the upgraded cmdlet's parameter name.
                        # we should add an upgrade step to swap to use the non-aliased name.

                        $paramUpgrade = New-Object -TypeName UpgradePlan
                        $paramUpgrade.Original = $rmParam.Name
                        $paramUpgrade.Replacement = $matchedAliasName.Name
                        $paramUpgrade.UpgradeType = [UpgradeStepType]::CmdletParameter
                        $paramUpgrade.SourceCommand = $rmCmdlet
                        $paramUpgrade.FullPath = $rmCmdlet.FullPath
                        $paramUpgrade.StartOffset = $rmParam.StartOffset
                        $paramUpgrade.SourceCommandParameter = $rmParam
                        $paramUpgrade.Location = $rmParam.Location
                        $paramUpgrade.PlanResultReason = "Command parameter can be automatically upgraded."
                        $paramUpgrade.PlanResult = [PlanResultReasonCode]::ReadyToUpgrade
                        $paramUpgrade.PlanSeverity = [DiagnosticSeverity]::Information

                        $planSteps.Add($paramUpgrade)

                        continue
                    }

                    # no direct match and no alias match?
                    # this could mean a breaking change that requires manual adjustments

                    $paramError = New-Object -TypeName UpgradePlan
                    $paramError.Original = $rmParam.Name
                    $paramError.UpgradeType = [UpgradeStepType]::CmdletParameter
                    $paramError.SourceCommand = $rmCmdlet
                    $paramError.FullPath = $rmCmdlet.FullPath
                    $paramError.StartOffset = $rmParam.StartOffset
                    $paramError.SourceCommandParameter = $rmParam
                    $paramError.Location = $rmParam.Location
                    $paramError.PlanResultReason = "Parameter was not found in $resolvedCommandName or it's aliases."
                    $paramError.PlanResult = [PlanResultReasonCode]::ErrorParameterNotFound
                    $paramError.PlanSeverity = [DiagnosticSeverity]::Error

                    $planErrorSteps.Add($paramError)
                }
            }
        }

        # send metrics, if enabled (and while the collections are still seperated)

        Send-MetricsIfDataCollectionEnabled -Operation Plan `
            -ParameterSetName $PSCmdlet.ParameterSetName `
            -Duration ((Get-Date) - $cmdStarted) `
            -Properties ([PSCustomObject]@{
                ToAzureModuleName = "Az"
                ToAzureModuleVersion = $ToAzVersion
                UpgradeStepsCount = $planSteps.Count
                PlanWarnings = $planWarningSteps
                PlanErrors = $planErrorSteps
            })

        # join the collections into one output result.

        $planSteps.AddRange($planWarningSteps)
        $planSteps.AddRange($planErrorSteps)

        # sort the upgrade steps to by file, then offset descending.
        # the reason for this is updates must be made in descending offset order
        # otherwise file positions will change for subsequent swaps.

        $filter1 = @{ Expression = 'FullPath'; Ascending = $true }
        $filter2 = @{ Expression = 'StartOffset'; Descending = $true }

        $planSteps = $planSteps | Sort-Object -Property $filter1, $filter2

        # now that we have a sorted collection, add in the step order number
        # for extra clarity in the upgrade plan.

        for ([int]$i = 0; $i -lt $planSteps.Count; $i++)
        {
            $planSteps[$i].Order = ($i + 1)
        }

        Write-Output -InputObject $planSteps
    }
}