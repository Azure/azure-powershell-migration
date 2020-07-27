function Find-AzUpgradeCommandReference
{
    <#
    .SYNOPSIS
        Searches for AzureRM PowerShell command references in the specified file or folder.

    .DESCRIPTION
        Searches for AzureRM PowerShell command references in the specified file or folder. When reviewing the specified file or folder, all of the cmdlets used in the files will be analyzed and compared against known AzureRM PowerShell commands. If commands match a known
        AzureRM cmdlet, then output will be returned that shows the position/offset for each usage.

        The output of this command can be pipelined into the New-AzUpgradeModulePlan cmdlet to generate a detailed list of required upgrade changes.

    .PARAMETER FilePath
        Specifies the path to a single PowerShell file.

    .PARAMETER DirectoryPath
        Specifies the path to the folder where PowerShell scripts or modules reside.

    .PARAMETER AzureRmVersion
        Specifies the AzureRM module version used in your existing PowerShell file(s) or modules.

    .EXAMPLE
        The following example finds AzureRM PowerShell command references in the specified file.

        Find-AzUpgradeCommandReference -FilePath 'C:\Scripts\test.ps1' -AzureRmVersion '6.13.1'

    .EXAMPLE
        The following example finds AzureRM PowerShell command references in the specified directory and subfolders.

        Find-AzUpgradeCommandReference -DirectoryPath 'C:\Scripts' -AzureRmVersion '6.13.1'
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            ParameterSetName="ByFile",
            HelpMessage="Specify the path to a single PowerShell file.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $FilePath,

        [Parameter(
            Mandatory=$true,
            ParameterSetName="ByDirectory",
            HelpMessage="Specify the path to the folder where PowerShell scripts or modules reside.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $DirectoryPath,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the AzureRM module version used in your existing PowerShell file(s)/modules.")]
        [System.String]
        [ValidateSet("6.13.1")]
        $AzureRmVersion
    )
    Process
    {
        # load the command specs
        Write-Verbose -Message "Importing cmdlet spec for AzureRM $AzureRmVersion"
        $azureRmSpec = Import-CmdletSpec -ModuleName "AzureRM" -ModuleVersion $AzureRmVersion

        # synchronous results output instead of async. the reason for this is that
        # downstream commands will need the entire results object to process at once.
        $azureRmReferenceResults = New-Object -TypeName CommandReferenceCollection

        if ($PSCmdlet.ParameterSetName -eq 'ByFile')
        {
            if ((Test-Path -Path $FilePath) -eq $false)
            {
                throw "File was not found or was not accessible: $FilePath"
            }

            Write-Verbose -Message "Searching for AzureRM references in file: $FilePath"
            $foundCmdlets = Find-CmdletsInFile -FilePath $FilePath | Where-object -FilterScript { $azureRmSpec.ContainsKey($_.CommandName) -eq $true }

            foreach ($foundCmdlet in $foundCmdlets)
            {
                $azureRmReferenceResults.Items.Add($foundCmdlet)
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByDirectory')
        {
            if ((Test-Path -Path $DirectoryPath) -eq $false)
            {
                throw "Directory was not found or was not accessible: $DirectoryPath"
            }

            $filesToSearch = Get-ChildItem -Path $DirectoryPath -Recurse -Include *.ps1, *.psm1

            foreach ($file in $filesToSearch)
            {
                Write-Verbose -Message "Searching for AzureRM references in file: $($file.FullName)"
                $foundCmdlets = Find-CmdletsInFile -FilePath $file.FullName | Where-object -FilterScript { $azureRmSpec.ContainsKey($_.CommandName) -eq $true }

                foreach ($foundCmdlet in $foundCmdlets)
                {
                    $azureRmReferenceResults.Items.Add($foundCmdlet)
                }
            }
        }

        Write-Output -InputObject $azureRmReferenceResults
    }
}