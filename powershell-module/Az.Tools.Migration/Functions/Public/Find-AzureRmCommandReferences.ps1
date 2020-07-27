function Find-AzureRmCommandReferences
{
    <#
    .SYNOPSIS
        Searches for AzureRM command references in the specified file or folder.

    .DESCRIPTION
        Searches for AzureRM command references in the specified file or folder. When reviewing the specified file or folder
        all of the cmdlets used in the files will be analyzed and compared against known AzureRM commands. If commands match a known
        AzureRM cmdlet, then output will be returned that shows the position/offset for each usage.

        The output of this command can be pipelined into the New-AzModuleUpgradePlan cmdlet to generate a detailed list of required upgrade changes.

    .PARAMETER FilePath
        Specify the path to a single PowerShell file.

    .PARAMETER DirectoryPath
        Specify the path to the folder where PowerShell scripts or modules reside.

    .PARAMETER AzureRmModuleVersion
        Specify the AzureRM module version used in your existing PowerShell file(s)/modules. At this time only AzureRM 6.13.1 is supported.

    .EXAMPLE
        PS C:\> Find-AzureRmCommandReferences -FilePath "C:\scripts\test.ps1" -AzureRmModuleVersion 6.13.1
        Finds AzureRM command references in the specified file.

    .EXAMPLE
        PS C:\> Find-AzureRmCommandReferences -DirectoryPath "C:\scripts" -AzureRmModuleVersion 6.13.1
        Finds AzureRM command references in the specified folder (any .ps1 or .psm1 files).
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
            HelpMessage="Specify the AzureRM module version used in your existing PowerShell file(s)/modules. At this time only AzureRM 6.13.1 is supported.")]
        [System.String]
        [ValidateSet("6.13.1")]
        $AzureRmModuleVersion
    )
    Process
    {
        # load the command specs
        Write-Verbose -Message "Importing cmdlet spec for AzureRM $AzureRmModuleVersion"
        $azureRmSpec = Import-CmdletSpec -ModuleName "AzureRM" -ModuleVersion $AzureRmModuleVersion

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