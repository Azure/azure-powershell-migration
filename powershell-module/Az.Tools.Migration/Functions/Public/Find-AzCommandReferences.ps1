function Find-AzCommandReferences
{
    <#
    .SYNOPSIS
        Searches for Az PowerShell command references in the specified file or folder.

    .DESCRIPTION
        Searches for Az PowerShell command references in the specified file or folder. When reviewing the specified file or folder
        all of the cmdlets used in the files will be analyzed and compared against known Az PowerShell commands. If commands match a known
        Az cmdlet, then output will be returned that shows the position/offset for each usage.

        The output of this command can be pipelined into the New-AzModuleUpgradePlan cmdlet to generate a detailed list of required upgrade changes.

    .PARAMETER FilePath
        Specify the path to a single PowerShell file.

    .PARAMETER DirectoryPath
        Specify the path to the folder where PowerShell scripts or modules reside.

    .PARAMETER AzModuleVersion
        Specify the Az module major version used in your existing PowerShell file(s)/modules. For example: 1, 2, 3, or 4.

    .EXAMPLE
        PS C:\> Find-AzCommandReferences -FilePath "C:\scripts\test.ps1" -AzModuleVersion 1
        Finds Az PowerShell (v1.x) command references in the specified file.

    .EXAMPLE
        PS C:\> Find-AzCommandReferences -DirectoryPath "C:\scripts" -AzModuleVersion 3
        Finds Az PowerShell (v3.x) command references in the specified folder (any .ps1 or .psm1 files).
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
            HelpMessage="Specify the Az module version used in your existing PowerShell file(s)/modules.")]
        [System.Int32]
        [ValidateSet(1, 2, 3, 4)]
        $AzModuleVersion
    )
    Process
    {
        # load the command specs
        switch ($AzModuleVersion)
        {
            1 { $fullAzVersion = "1.8.0" }
            2 { $fullAzVersion = "2.8.0" }
            3 { $fullAzVersion = "3.8.0" }
            4 { $fullAzVersion = "4.4.0" }
        }

        Write-Verbose -Message "Importing cmdlet spec for Az $AzModuleVersion"
        $azSpec = Import-CmdletSpec -ModuleName "Az" -ModuleVersion $fullAzVersion

        # synchronous results output instead of async. the reason for this is that
        # downstream commands will need the entire results object to process at once.
        $azReferenceResults = New-Object -TypeName CommandReferenceCollection

        if ($PSCmdlet.ParameterSetName -eq 'ByFile')
        {
            if ((Test-Path -Path $FilePath) -eq $false)
            {
                throw "File was not found or was not accessible: $FilePath"
            }

            Write-Verbose -Message "Searching for Az references in file: $FilePath"
            $foundCmdlets = Find-CmdletsInFile -FilePath $FilePath | Where-object -FilterScript { $azSpec.ContainsKey($_.CommandName) -eq $true }

            foreach ($foundCmdlet in $foundCmdlets)
            {
                $azReferenceResults.Items.Add($foundCmdlet)
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
                Write-Verbose -Message "Searching for Az references in file: $($file.FullName)"
                $foundCmdlets = Find-CmdletsInFile -FilePath $file.FullName | Where-object -FilterScript { $azSpec.ContainsKey($_.CommandName) -eq $true }

                foreach ($foundCmdlet in $foundCmdlets)
                {
                    $azReferenceResults.Items.Add($foundCmdlet)
                }
            }
        }

        Write-Output -InputObject $azReferenceResults
    }
}