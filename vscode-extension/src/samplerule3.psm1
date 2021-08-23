#Requires -Version 3.0

<#
.SYNOPSIS
    Uses #Requires -RunAsAdministrator instead of your own methods.
.DESCRIPTION
    The #Requires statement prevents a script from running unless the Windows PowerShell version, modules, snap-ins, and module and snap-in version prerequisites are met.
    From Windows PowerShell 4.0, the #Requires statement let script developers require that sessions be run with elevated user rights (run as Administrator).
    Script developers does not need to write their own methods any more.
    To fix a violation of this rule, please consider to use #Requires -RunAsAdministrator instead of your own methods.
.EXAMPLE
    Measure-RequiresRunAsAdministrator -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [OutputType([PSCustomObject[])]
.NOTES
    None
#>
function Measure-RequiresRunAsAdministrator {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $testAst
    )


    $l = (new-object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"])

    $matchPattern = "(\b[a-zA-z]+-[a-zA-z]+\b)"
    $recurse = $true
    $commandPredicate = { param($astObject) $astObject -is [System.Management.Automation.Language.CommandAst] }
    $commandAstNodes = $testAst.FindAll($commandPredicate, $recurse)
    $cmdletRegex = New-Object System.Text.RegularExpressions.Regex($matchPattern)


    $commandAstNodes > commandAstNodes.json

    for ([int]$i = 0; $i -lt $commandAstNodes.Count; $i++) {
        $currentVarAstNode = $commandAstNodes[$i]
        for ([int]$j = 0; $j -lt $currentVarAstNode.CommandElements.Count; $j++) {
            $currentCommandElement = $currentVarAstNode.CommandElements[$j]

            if ($currentCommandElement.Extent.Text -eq "import-module") {
                # Write-Error $currentCommandElement.Extent
                $currentCommandElement.Extent > currentVarAstNode$i.json

                [int]$startLineNumber = $currentCommandElement.Extent.StartLineNumber
                [int]$endLineNumber = $currentCommandElement.Extent.EndLineNumber
                [int]$startColumnNumber = $currentCommandElement.Extent.StartColumnNumber
                [int]$endColumnNumber = $currentCommandElement.Extent.EndColumnNumber
                [string]$correction = "Alias_Formal_name"
                [string]$filePath = $currentCommandElement.Extent.File
                [string]$optionalDescription = 'Useful but optional description text'


                $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                $l.Add($c)
            }
        }



        # if ($currentAstNode.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] `
        #         -and $cmdletRegex.IsMatch($currentAstNode.CommandElements[0].Extent.Text))
        # {
        #     $currentVarAstNode.CommandElements[0].Extent.EndLineNumber > assignmentAstNodes+$i.json
        # }
    }

    # The implementation is mocked out for testing purposes only and many properties are deliberately set to null to test if PSSA can cope with it


    $extent = $null
    $dr = New-Object `
        -Typename "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
        -ArgumentList "This is help", $extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null, $l
    $dr.RuleSuppressionID = "MyRuleSuppressionID"
    $dr.SuggestedCorrections = $l
    $dr.SuggestedCorrections > SuggestedCorrections.json
    return $dr
}
Export-ModuleMember -Function Measure*