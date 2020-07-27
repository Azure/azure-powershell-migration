function New-AzUpgradeModulePlan
{
    <#
    .SYNOPSIS
        Generates a new upgrade plan for migrating to the Az module.

    .DESCRIPTION
        Generates a new upgrade plan for migrating to the Az module. The upgrade plan details the specific file/offset
        points that require changes move AzureRM commands to Az commands.

        The input to this command should be the output from the Find-AzureRmCommandReferences cmdlet.

    .PARAMETER AzureRmCmdReferences
        Specify the AzureRM command references collection output from the Find-AzureRmCommandReferences cmdlet.

    .PARAMETER AzModuleVersion
        Specify the Az module version to upgrade to.

    .EXAMPLE
        PS C:\ Find-AzureRmCommandReferences -FilePath "C:\scripts\test.ps1" -AzureRmModuleVersion 6.13.1 | New-AzUpgradeModulePlan -AzModuleVersion 4.4.0
        Generates a new Az module upgrade plan for the test.ps1 script.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage='Specify the AzureRM command references collection output from the Find-AzureRmCommandReferences cmdlet.')]
        [CommandReferenceCollection]
        $AzureRmCmdReference,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the Az module version to upgrade to.')]
        [System.String]
        [ValidateSet('4.4.0')]
        $AzModuleVersion
    )
    Process
    {
        if ($AzureRmCmdReference -eq $null -or $AzureRmCmdReference.Items.Count -eq 0)
        {
            Write-Verbose -Message "No AzureRm command references were provided. No upgrade plan will be generated."
            return
        }
        else
        {
            Write-Verbose -Message "$($AzureRmCmdReference.Items.Count) AzureRm command reference(s) were provided. Upgrade plan will be generated."
        }

        Write-Verbose -Message "Importing cmdlet spec for Az $AzModuleVersion"
        $azCmdlets = Import-CmdletSpec -ModuleName "Az" -ModuleVersion $AzModuleVersion

        Write-Verbose -Message "Importing upgrade alias spec for Az $AzModuleVersion"
        $upgradeAliases = Import-AliasSpec -ModuleVersion $AzModuleVersion

        $defaultParamNames = @("Debug", "ErrorAction", "ErrorVariable", "InformationAction", "InformationVariable", "OutVariable", "OutBuffer", "PipelineVariable", "Verbose", "WarningAction", "WarningVariable", "WhatIf", "Confirm")

        # synchronous results output instead of async. the reason for this is that
        # downstream commands will need the entire results object to process at once.
        $upgradePlan = New-Object -TypeName UpgradePlan

        foreach ($rmCmdlet in $AzureRmCmdReference.Items)
        {
            Write-Verbose -Message "Checking upgrade potential for instance of $($rmCmdlet.CommandName)"

            if ($rmCmdlet.HasSplattedArguments -eq $true)
            {
                $warningMsg = New-Object -TypeName UpgradePlanResult
                $warningMsg.Command = $rmCmdlet
                $warningMsg.Reason = "Cmdlet invocation uses splatted parameters. Consider unrolling to allow automated parameter upgrade checks."

                $upgradePlan.Warnings.Add($warningMsg)
            }

            if ($upgradeAliases.ContainsKey($rmCmdlet.CommandName) -eq $false)
            {
                $errorMsg = New-Object -TypeName UpgradePlanResult
                $errorMsg.Command = $rmCmdlet
                $errorMsg.Reason = "No matching upgrade alias found. Command cannot be automatically upgraded."

                $upgradePlan.Errors.Add($errorMsg)

                continue
            }

            $resolvedCommandName = $upgradeAliases[$rmCmdlet.CommandName]

            if ($azCmdlets.ContainsKey($resolvedCommandName) -eq $false)
            {
                $errorMsg = New-Object -TypeName UpgradePlanResult
                $errorMsg.Command = $rmCmdlet
                $errorMsg.Reason = "No Az cmdlet spec found for $resolvedCommandName. Command cannot be automatically upgraded."

                $upgradePlan.Errors.Add($errorMsg)

                continue
            }

            $cmdletUpgrade = New-Object -TypeName CmdletUpgradeStep
            $cmdletUpgrade.OriginalCmdletName = $rmCmdlet.CommandName
            $cmdletUpgrade.ReplacementCmdletName = $resolvedCommandName
            $cmdletUpgrade.FullPath = $rmCmdlet.FullPath
            $cmdletUpgrade.FileName = $rmCmdlet.FileName
            $cmdletUpgrade.StartLine = $rmCmdlet.StartLine
            $cmdletUpgrade.StartColumn = $rmCmdlet.StartColumn
            $cmdletUpgrade.EndLine = $rmCmdlet.EndLine
            $cmdletUpgrade.EndPosition = $rmCmdlet.EndPosition
            $cmdletUpgrade.StartOffset = $rmCmdlet.StartOffset
            $cmdletUpgrade.EndOffset = $rmCmdlet.EndOffset

            $upgradePlan.UpgradeSteps.Add($cmdletUpgrade)

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

                        $paramUpgrade = New-Object -TypeName CmdletParameterUpgradeStep
                        $paramUpgrade.OriginalParameterName = $rmParam.Name
                        $paramUpgrade.ReplacementParameterName = $matchedAliasName.Name

                        # properties from the parent cmdlet
                        $paramUpgrade.FullPath = $rmCmdlet.FullPath
                        $paramUpgrade.FileName = $rmCmdlet.FileName

                        # properties from the parameter itself
                        $paramUpgrade.StartLine = $rmParam.StartLine
                        $paramUpgrade.StartColumn = $rmParam.StartColumn
                        $paramUpgrade.EndLine = $rmParam.EndLine
                        $paramUpgrade.EndPosition = $rmParam.EndPosition
                        $paramUpgrade.StartOffset = $rmParam.StartOffset
                        $paramUpgrade.EndOffset = $rmParam.EndOffset

                        $upgradePlan.UpgradeSteps.Add($paramUpgrade)

                        continue
                    }

                    # no direct match and no alias match?
                    # this could mean a breaking change that requires manual adjustments

                    $errorMsg = New-Object -TypeName UpgradePlanResult
                    $errorMsg.Command = $rmCmdlet
                    $errorMsg.Reason = "Parameter [$($rmParam.Name)] was not found in $resolvedCommandName or it's aliases."

                    $upgradePlan.Errors.Add($errorMsg)
                }
            }
        }

        # sort the upgrade steps to by file, then offset descending.
        # the reason for this is updates must be made in descending offset order
        # otherwise file positions will change for subsequent swaps.

        $filter1 = @{ Expression = 'FullPath'; Ascending = $true }
        $filter2 = @{ Expression = 'StartOffset'; Descending = $true }

        $upgradePlan.UpgradeSteps = $upgradePlan.UpgradeSteps | Sort-Object -Property $filter1, $filter2

        # now that we have a sorted collection, add in the step order number
        # for extra clarity in the upgrade plan.

        for ([int]$i = 0; $i -lt $upgradePlan.UpgradeSteps.Count; $i++)
        {
            $upgradePlan.UpgradeSteps[$i].StepNumber = ($i + 1)
        }

        Write-Output -InputObject $upgradePlan
    }
}