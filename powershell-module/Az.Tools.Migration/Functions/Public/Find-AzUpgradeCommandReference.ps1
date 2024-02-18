function Find-AzUpgradeCommandReference
{
    <#
    .SYNOPSIS
        Searches for AzureRM PowerShell command references in the specified file or folder.

    .DESCRIPTION
        Searches for AzureRM PowerShell command references in the specified file or folder. When reviewing the specified file or folder, all of the cmdlets used in the files will be analyzed and compared against known AzureRM PowerShell commands. If commands match a known
        AzureRM cmdlet, then output will be returned that shows the position/offset for each usage.

    .PARAMETER FilePath
        Specifies the path to a single PowerShell file.

    .PARAMETER DirectoryPath
        Specifies the path to the folder where PowerShell scripts or modules reside.

    .PARAMETER AzureRmVersion
        Specifies the AzureRM module version used in your existing PowerShell file(s) or modules.

    .PARAMETER AzureRmModuleSpec
        Specifies a dictionary containing cmdlet specification objects, returned from Get-AzUpgradeCmdletSpec.

    .EXAMPLE
        The following example finds AzureRM PowerShell command references in the specified file.

        Find-AzUpgradeCommandReference -FilePath 'C:\Scripts\test.ps1' -AzureRmVersion '6.13.1'

    .EXAMPLE
        The following example finds AzureRM PowerShell command references in the specified directory and subfolders.

        Find-AzUpgradeCommandReference -DirectoryPath 'C:\Scripts' -AzureRmVersion '6.13.1'

    .EXAMPLE
        The following example finds AzureRM PowerShell command references in the specified directory and subfolders but with a pre-loaded module specification.
        This is helpful to avoid reloading the module specification if the Find-AzUpgradeCommandReference command needs to be executed several times.

        $moduleSpec = Get-AzUpgradeCmdletSpec -AzureRM
        Find-AzUpgradeCommandReference -DirectoryPath 'C:\Scripts1' -AzureRmModuleSpec $moduleSpec
        Find-AzUpgradeCommandReference -DirectoryPath 'C:\Scripts2' -AzureRmModuleSpec $moduleSpec
        Find-AzUpgradeCommandReference -DirectoryPath 'C:\Scripts3' -AzureRmModuleSpec $moduleSpec
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            ParameterSetName="ByFileAndModuleVersion",
            HelpMessage="Specify the path to a single PowerShell file.")]
        [Parameter(
            Mandatory=$true,
            ParameterSetName="ByFileAndModuleSpec",
            HelpMessage="Specify the path to a single PowerShell file.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $FilePath,

        [Parameter(
            Mandatory=$true,
            ParameterSetName="ByDirectoryAndModuleVersion",
            HelpMessage="Specify the path to the folder where PowerShell scripts or modules reside.")]
        [Parameter(
            Mandatory=$true,
            ParameterSetName="ByDirectoryAndModuleSpec",
            HelpMessage="Specify the path to the folder where PowerShell scripts or modules reside.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $DirectoryPath,

        [Parameter(
            Mandatory=$true,
            ParameterSetName="ByFileAndModuleVersion",
            HelpMessage="Specify the AzureRM module version used in your existing PowerShell file(s)/modules. Supported versions include: '6.13.1', '6.13.2'")]
        [Parameter(
            Mandatory=$true,
            ParameterSetName="ByDirectoryAndModuleVersion",
            HelpMessage="Specify the AzureRM module version used in your existing PowerShell file(s)/modules. Supported versions include: '6.13.1', '6.13.2'")]
        [System.String]
        $AzureRmVersion,

        [Parameter(
            Mandatory=$true,
            ParameterSetName="ByFileAndModuleSpec",
            HelpMessage="Specify a dictionary containing cmdlet specification objects, returned from Get-AzUpgradeCmdletSpec.")]
        [Parameter(
            Mandatory=$true,
            ParameterSetName="ByDirectoryAndModuleSpec",
            HelpMessage="Specify a dictionary containing cmdlet specification objects, returned from Get-AzUpgradeCmdletSpec.")]
        [System.Collections.Generic.Dictionary[System.String, CommandDefinition]]
        $AzureRmModuleSpec
    )
    Process
    {
        # write warning if given azurerm version is not supported
        $supportedAzureRmVersion = @('6.13.1', '6.13.2')
        if (-not $supportedAzureRmVersion.Contains($FromAzureRmVersion)) {
            Write-Error "AzureRm $FromAzureRmVersion is currently not supported. Supported AzureRm versions include '6.13.1', '6.13.2'." -ErrorAction Stop
        } else {
            $FromAzureRmVersion = '6.13.1'
        }

        $cmdStarted = Get-Date

        if ($PSBoundParameters.ContainsKey('AzureRmModuleSpec') -eq $false)
        {
            # load the command specs
            Write-Verbose -Message "Loading cmdlet spec for AzureRM $AzureRmVersion"
            $AzureRmModuleSpec = Get-AzUpgradeCmdletSpec -AzureRM
        }
        else
        {
            Write-Verbose -Message "Module specification was provided at runtime. Skipping spec load operation."
        }

        if ($PSCmdlet.ParameterSetName.StartsWith('ByFile'))
        {
            if ((Test-Path -Path $FilePath) -eq $false)
            {
                throw "File was not found or was not accessible: $FilePath"
            }

            $FilePath = (Resolve-Path $FilePath).Path
            Write-Verbose -Message "Searching for AzureRM references in file: $FilePath"
            $foundCmdlets = Find-CmdletsInFile -FilePath $FilePath | Where-object -FilterScript { $AzureRmModuleSpec.ContainsKey($_.CommandName) -eq $true }

            if ($foundCmdlets -ne $null -and $foundCmdlets.Count -gt 0)
            {
                # dont want to write null to the pipeline output
                Write-Output -InputObject $foundCmdlets
            }

            Send-MetricsIfDataCollectionEnabled -Operation Find `
                -ParameterSetName $PSCmdlet.ParameterSetName `
                -Duration ((Get-Date) - $cmdStarted) `
                -Properties ([PSCustomObject]@{
                    AzureCmdletCount = $foundCmdlets.Count
                    AzureModuleName = "AzureRM"
                    AzureModuleVersion = $AzureRmVersion
                    FileCount = 1
                })
        }
        elseif ($PSCmdlet.ParameterSetName.StartsWith('ByDirectory'))
        {
            if ((Test-Path -Path $DirectoryPath) -eq $false)
            {
                throw "Directory was not found or was not accessible: $DirectoryPath"
            }

            $DirectoryPath = (Resolve-Path $DirectoryPath).Path
            $filesToSearch = Get-ChildItem -Path $DirectoryPath -Recurse -Include *.ps1, *.psm1
            $commandCounter = 0

            foreach ($file in $filesToSearch)
            {
                Write-Verbose -Message "Searching for AzureRM references in file: $($file.FullName)"
                $foundCmdlets = Find-CmdletsInFile -FilePath $file.FullName | Where-object -FilterScript { $AzureRmModuleSpec.ContainsKey($_.CommandName) -eq $true }

                if ($foundCmdlets -ne $null -and $foundCmdlets.Count -gt 0)
                {
                    # dont want to write null to the pipeline output
                    Write-Output -InputObject $foundCmdlets
                }

                $commandCounter += $foundCmdlets.Count
            }

            Send-MetricsIfDataCollectionEnabled -Operation Find `
                -ParameterSetName $PSCmdlet.ParameterSetName `
                -Duration ((Get-Date) - $cmdStarted) `
                -Properties ([PSCustomObject]@{
                    AzureCmdletCount = $commandCounter
                    AzureModuleName = "AzureRM"
                    AzureModuleVersion = $AzureRmVersion
                    FileCount = $filesToSearch.Count
                })
        }
    }
}