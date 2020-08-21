function Find-CmdletsInFile
{
    <#
    .SYNOPSIS
        Finds any cmdlets used in the specified PowerShell file.

    .DESCRIPTION
        Finds any cmdlets used in the specified PowerShell file.

    .PARAMETER FilePath
        Specify the path to the file that should be searched.

    .EXAMPLE
        PS C:\> Find-CmdletsInFile -FilePath "C:\scripts\file.ps1"
        Finds cmdlets used in the specified file.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify the path to the file that should be searched.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $FilePath
    )
    Process
    {
        $matchPattern = "(\b[a-zA-z]+-[a-zA-z]+\b)"
        $cmdletRegex = New-Object System.Text.RegularExpressions.Regex($matchPattern)

        # ref output vars
        $parserErrors = $null
        $parsedTokens = $null

        $rootAstNode = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$parsedTokens, [ref]$parserErrors)

        if ($parserErrors.Count -gt 0)
        {
            if ($parserErrors[0].ErrorID -eq "FileReadError")
            {
                throw "The PowerShell file provided [$FilePath] was not found or not accessible."
            }
            else
            {
                throw "The PowerShell file provided [$FilePath] has $($parserErrors.Count) syntax error(s). Please correct the syntax errors then try again."
            }
        }

        $predicate = { param($astObject) $astObject -is [System.Management.Automation.Language.CommandAst] }
        $recurse = $true

        $commandAstNodes = $rootAstNode.FindAll($predicate, $recurse)

        for ([int]$i = 0; $i -lt $commandAstNodes.Count; $i++)
        {
            $currentAstNode = $commandAstNodes[$i]

            # is the first command element a cmdlet?
            # then we have the start of a cmdlet expression

            if ($currentAstNode.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] `
                    -and $cmdletRegex.IsMatch($currentAstNode.CommandElements[0].Extent.Text))
            {
                $cmdletRef = New-Object -TypeName CommandReference
                $cmdletRef.FullPath = $currentAstNode.CommandElements[0].Extent.File
                $cmdletRef.FileName = Split-Path -Path $currentAstNode.CommandElements[0].Extent.File -Leaf
                $cmdletRef.StartLine = $currentAstNode.CommandElements[0].Extent.StartLineNumber
                $cmdletRef.StartColumn = $currentAstNode.CommandElements[0].Extent.StartColumnNumber
                $cmdletRef.EndLine = $currentAstNode.CommandElements[0].Extent.EndLineNumber
                $cmdletRef.EndPosition = $currentAstNode.CommandElements[0].Extent.EndColumnNumber
                $cmdletRef.CommandName = $currentAstNode.CommandElements[0].Extent.Text
                $cmdletRef.StartOffset = $currentAstNode.CommandElements[0].Extent.StartOffset
                $cmdletRef.EndOffset = $currentAstNode.CommandElements[0].Extent.EndOffset

                if ($currentAstNode.CommandElements.Count -gt 1)
                {
                    # this cmdlet likely has parameters supplied to it.

                    for ([int]$j = 1; $j -lt $currentAstNode.CommandElements.Count; $j++)
                    {
                        $currentAstNodeCmdElement = $currentAstNode.CommandElements[$j]

                        if ($currentAstNodeCmdElement -is [System.Management.Automation.Language.CommandParameterAst])
                        {
                            $paramRef = New-Object -TypeName CommandReferenceParameter

                            # substring to cut off the dash (-) character we dont need
                            $paramRef.Name = $currentAstNodeCmdElement.Extent.Text.Substring(1)

                            # check for the parameter value.
                            # if this is the last element in the list, or the next item is also a
                            # parameter, then this parameter has no value (switch parameter)

                            if ($j -eq ($currentAstNode.CommandElements.Count -1) `
                                    -or $currentAstNode.CommandElements[($j + 1)] -is [System.Management.Automation.Language.CommandParameterAst])
                            {
                                # switch param (no value)
                                $paramRef.Value = $null
                            }
                            else
                            {
                                # regular param (has value)
                                $paramRef.Value = $currentAstNode.CommandElements[($j + 1)].Extent.Text
                            }

                            $paramRef.FullPath = $cmdletRef.FullPath
                            $paramRef.FileName = $cmdletRef.FileName
                            $paramRef.StartLine = $currentAstNodeCmdElement.Extent.StartLineNumber
                            $paramRef.StartColumn = $currentAstNodeCmdElement.Extent.StartColumnNumber
                            $paramRef.EndLine = $currentAstNodeCmdElement.Extent.EndLineNumber
                            $paramRef.EndPosition = $currentAstNodeCmdElement.Extent.EndColumnNumber
                            $paramRef.StartOffset = $currentAstNodeCmdElement.Extent.StartOffset
                            $paramRef.EndOffset = $currentAstNodeCmdElement.Extent.EndOffset

                            $cmdletRef.Parameters.Add($paramRef)
                        }
                        elseif ($currentAstNodeCmdElement -is [System.Management.Automation.Language.VariableExpressionAst] `
                                -and $currentAstNodeCmdElement.Splatted -eq $true)
                        {
                            $cmdletRef.HasSplattedArguments = $true
                        }
                    }
                }

                Write-Output -InputObject $cmdletRef
            }
        }
    }
}