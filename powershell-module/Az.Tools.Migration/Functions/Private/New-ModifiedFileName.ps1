function New-ModifiedFileName
{
    <#
    .SYNOPSIS
        Generates a new file name for a modified PowerShell file.

    .DESCRIPTION
        Generates a new file name for a modified PowerShell file.

    .PARAMETER Path
        Specify the existing/original file path.

    .EXAMPLE
        PS C:\> New-ModifiedFileName -Path 'C:\scripts\test.ps1'
        Returns a new modified file name.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the existing/original file path.')]
        [System.String]
        $Path
    )
    Process
    {
        # create a FileInfo object so we can quickly retrieve parts of the path and/or filename.
        $fileInfo = New-Object -TypeName 'System.IO.FileInfo' -ArgumentList $Path

        if ($fileInfo.Extension.Length -gt 0)
        {
            # handling for normal files with extensions
            $baseFileName = ($fileInfo.Name.Remove($fileInfo.Name.Length - $fileInfo.Extension.Length))
            $newFileName = $baseFileName + [Constants]::NewFileBaseNameSuffix + $fileInfo.Extension
        }
        else
        {
            # extensionless file handling
            $newFileName = $fileInfo.Name + [Constants]::NewFileBaseNameSuffix
        }

        Write-Output -InputObject (Join-Path -Path $fileInfo.DirectoryName -ChildPath $newFileName)
    }
}