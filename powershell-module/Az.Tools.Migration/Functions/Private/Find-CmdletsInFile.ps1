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
        # constants
        $matchPattern = "(\b[a-zA-z]+-[a-zA-z]+\b)"
        $doubleQuoteCharacter = '"'
        $singleQuoteCharacter = ''''
        $orderedTypeName = 'ordered'

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

        # search for variable assignment statements
        # the goal here is to build a table with the hastable variable sets (if any are present), to support splatted parameter names.
        $recurse = $true
        $assignmentPredicate = { param($astObject) $astObject -is [System.Management.Automation.Language.AssignmentStatementAst] }
        $assignmentAstNodes = $rootAstNode.FindAll($assignmentPredicate, $recurse)
        $hashtableVariables = New-Object -TypeName 'System.Collections.Generic.Dictionary[System.String, System.Collections.Generic.List[System.Management.Automation.Language.StringConstantExpressionAst]]'

        for ([int]$i = 0; $i -lt $assignmentAstNodes.Count; $i++)
        {
            $currentVarAstNode = $assignmentAstNodes[$i]

            # is the left hand side of the expression a variable expression? (ex: $var = 1)
            # or is it a member expression? (ex: $var.Property = 1)
            # only variable expressions are supported at this time.

            if ($currentVarAstNode.Left -is [System.Management.Automation.Language.VariableExpressionAst])
            {
                # is the right hand side of the expression statement a hashtable node?
                if ($currentVarAstNode.Right.Expression -is [System.Management.Automation.Language.HashtableAst])
                {
                    # capture the hashtable variable name
                    $htVariableName = $currentVarAstNode.Left.VariablePath.UserPath
                    $hashtableVariables[$htVariableName] = New-Object -TypeName 'System.Collections.Generic.List[System.Management.Automation.Language.StringConstantExpressionAst]'

                    # capture the hashtable key name extents. 
                    # -- the tuple's .Item1 contains the key name AST (which may represent a splatted parameter name).
                    # -- the tuple's .Item2 contains the key value AST (we dont need to capture this)
                    # -- also make sure to only grab hashtable key names that come from ConstantExpressionAst (to avoid unsupported subexpression keyname scenarios).
                    foreach ($expressionAst in $currentVarAstNode.Right.Expression.KeyValuePairs)
                    {
                        if ($expressionAst.Item1 -is [System.Management.Automation.Language.StringConstantExpressionAst])
                        {
                            $hashtableVariables[$htVariableName].Add($expressionAst.Item1)
                        }
                    }
                }
                elseif ($currentVarAstNode.Right.Expression -is [System.Management.Automation.Language.ConvertExpressionAst] `
                    -and $currentVarAstNode.Right.Expression.Type.TypeName.FullName -eq $orderedTypeName `
                    -and $currentVarAstNode.Right.Expression.Child -is [System.Management.Automation.Language.HashtableAst])
                {
                    # same as the above 'if' condition case, but special handling for [ordered] hashtable objects.
                    # we have to check the .Child [HashtableAst] of the ConvertExpressionAst.

                    $htVariableName = $currentVarAstNode.Left.VariablePath.UserPath
                    $hashtableVariables[$htVariableName] = New-Object -TypeName 'System.Collections.Generic.List[System.Management.Automation.Language.StringConstantExpressionAst]'
                    
                    foreach ($expressionAst in $currentVarAstNode.Right.Expression.Child.KeyValuePairs)
                    {
                        if ($expressionAst.Item1 -is [System.Management.Automation.Language.StringConstantExpressionAst])
                        {
                            $hashtableVariables[$htVariableName].Add($expressionAst.Item1)
                        }
                    }
                }
            }
        }

        # search for command statements
        $commandPredicate = { param($astObject) $astObject -is [System.Management.Automation.Language.CommandAst] }
        $commandAstNodes = $rootAstNode.FindAll($commandPredicate, $recurse)
        $cmdletRegex = New-Object System.Text.RegularExpressions.Regex($matchPattern)

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
                $cmdletRef.Location = "{0}:{1}:{2}" -f $cmdletRef.FileName, $cmdletRef.StartLine, $cmdletRef.StartColumn

                if ($currentAstNode.CommandElements.Count -gt 1)
                {
                    # this cmdlet likely has parameters supplied to it.

                    for ([int]$j = 1; $j -lt $currentAstNode.CommandElements.Count; $j++)
                    {
                        $currentAstNodeCmdElement = $currentAstNode.CommandElements[$j]

                        if ($currentAstNodeCmdElement -is [System.Management.Automation.Language.CommandParameterAst])
                        {
                            $paramRef = New-Object -TypeName CommandReferenceParameter

                            # grab the parameter name with no dash value
                            # the extent offsets here include the dash, so add +1 to the starting values
                            # construct the parameter object with location details
                            $paramRef.Name = $currentAstNodeCmdElement.ParameterName
                            $paramRef.FullPath = $cmdletRef.FullPath
                            $paramRef.FileName = $cmdletRef.FileName
                            $paramRef.StartLine = $currentAstNodeCmdElement.Extent.StartLineNumber
                            $paramRef.StartColumn = ($currentAstNodeCmdElement.Extent.StartColumnNumber + 1)
                            $paramRef.EndLine = $currentAstNodeCmdElement.Extent.EndLineNumber
                            $paramRef.EndPosition = $currentAstNodeCmdElement.Extent.EndColumnNumber
                            $paramRef.StartOffset = ($currentAstNodeCmdElement.Extent.StartOffset + 1)
                            $paramRef.EndOffset = $currentAstNodeCmdElement.Extent.EndOffset
                            $paramRef.Location = "{0}:{1}:{2}" -f $paramRef.FileName, $paramRef.StartLine, $paramRef.StartColumn

                            $cmdletRef.Parameters.Add($paramRef)
                        }
                        elseif ($currentAstNodeCmdElement -is [System.Management.Automation.Language.VariableExpressionAst] `
                                -and $currentAstNodeCmdElement.Splatted -eq $true)
                        {
                            $cmdletRef.HasSplattedArguments = $true

                            # grab the splatted parameter name without the '@' character prefix.
                            # we can then look this up in our known hashtable variables table.
                            $hashtableVariableName = $currentAstNodeCmdElement.VariablePath.UserPath

                            if ($hashtableVariables.ContainsKey($hashtableVariableName))
                            {
                                foreach ($splattedParameter in $hashtableVariables[$hashtableVariableName])
                                {
                                    $paramRef = New-Object -TypeName CommandReferenceParameter

                                    # add new parameter, similar to above, however a hashtable key name is the parameter name.
                                    $paramRef.Name = $splattedParameter.Value
                                    $paramRef.FullPath = $cmdletRef.FullPath
                                    $paramRef.FileName = $cmdletRef.FileName

                                    if ($splattedParameter.Extent.Text[0] -ne $doubleQuoteCharacter -and $splattedParameter.Extent.Text[0] -ne $singleQuoteCharacter)
                                    {
                                        # normal hash table key (not wrapped in quote characters)
                                        $paramRef.StartLine = $splattedParameter.Extent.StartLineNumber
                                        $paramRef.StartColumn = $splattedParameter.Extent.StartColumnNumber
                                        $paramRef.EndLine = $splattedParameter.Extent.EndLineNumber
                                        $paramRef.EndPosition = $splattedParameter.Extent.EndColumnNumber
                                        $paramRef.StartOffset = $splattedParameter.Extent.StartOffset
                                        $paramRef.EndOffset = $splattedParameter.Extent.EndOffset
                                    }
                                    else
                                    {
                                        # hash table key wrapped in quotes
                                        # use special offset handling to account for quote wrapper characters.
                                        $paramRef.StartLine = $splattedParameter.Extent.StartLineNumber
                                        $paramRef.StartColumn = ($splattedParameter.Extent.StartColumnNumber + 1)
                                        $paramRef.EndLine = $splattedParameter.Extent.EndLineNumber
                                        $paramRef.EndPosition = ($splattedParameter.Extent.EndColumnNumber - 1)
                                        $paramRef.StartOffset = ($splattedParameter.Extent.StartOffset + 1)
                                        $paramRef.EndOffset = ($splattedParameter.Extent.EndOffset - 1)
                                    }

                                    $paramRef.Location = "{0}:{1}:{2}" -f $paramRef.FileName, $paramRef.StartLine, $paramRef.StartColumn

                                    $cmdletRef.Parameters.Add($paramRef)
                                }
                            }
                        }
                    }
                }

                Write-Output -InputObject $cmdletRef
            }
        }
    }
}