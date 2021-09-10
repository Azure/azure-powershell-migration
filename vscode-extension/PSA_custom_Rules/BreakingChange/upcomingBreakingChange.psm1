#Requires -Version 3.0

<#
.SYNOPSI
    Give the tips in the upcoming breaking change places that there will be changes in the upcoming feature.
.DESCRIPTION
    Find all breaking change cmdlets or parameters that appear in the powershell script.
    And give the tips that there will be changes in the feature and which breaking change there will be.
.EXAMPLE
    Measure-UpcomingBreakingChange -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
.NOTES
    None
#>
function Measure-UpcomingBreakingChange {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $scriptAst
    )

    Process {
        $results = @()
        # import functions
        $findCmdFunctionFile = ".\PSA_custom_Rules\Find-CmdletsInFile.psm1"
        Import-Module $findCmdFunctionFile
        $getBreakingchangeSpecFunctionFile = ".\PSA_custom_Rules\BreakingChange\Get-BreakingChangeSpec.psm1"
        Import-Module $getBreakingchangeSpecFunctionFile

        #get the alias mapping data
        $breakingChangePath = ".\PSA_custom_Rules\BreakingChange\BreakingchangeSpec.json"
        $breakingchanges = Get-BreakingChangeSpec -BreakingChangePath $breakingChangePath

        # get the commandAst in the file
        $cmdletBreakingchange = Find-CmdletsInFile -RootAstNode $scriptAst
        $typesToMessages = @{
            "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.GenericBreakingChangeAttribute"         = "The breaking change is expected to take effect from the next version.";
            "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletDeprecationAttribute"             = "The cmdlet is being deprecated. There will be no replacement for it.";
            "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletOutputBreakingChangeAttribute"    = "The output type is being deprecated without a replacement.";
            "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletParameterBreakingChangeAttribute" = "The parameter is changing."
        }

        $corrections = (new-object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"])

        foreach ($cmdletReference in $cmdletBreakingchange) {
            if ($breakingchanges.cmdlets.Keys -contains $cmdletReference.CommandName) {
                $type = $breakingchanges.cmdlets[$cmdletReference.CommandName]
                [int]$startLineNumber = $cmdletReference.StartLine
                [int]$endLineNumber = $cmdletReference.EndLine
                [int]$startColumnNumber = $cmdletReference.StartColumn
                [int]$endColumnNumber = $cmdletReference.EndPosition
                [string]$correction = ""
                [string]$filePath = $cmdletReference.FullPath
                [string]$optionalDescription = $typesToMessages[$type]

                $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                $corrections.Add($c)
            }

            if ($breakingchanges.paraCmdlets.Keys -contains $cmdletReference.CommandName) {
                if ($cmdletReference.parameters.Count -eq 0) {
                    $type = "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletParameterBreakingChangeAttribute"
                    [int]$startLineNumber = $cmdletReference.StartLine
                    [int]$endLineNumber = $cmdletReference.EndLine
                    [int]$startColumnNumber = $cmdletReference.StartColumn
                    [int]$endColumnNumber = $cmdletReference.EndPosition
                    [string]$correction = ""
                    [string]$filePath = $cmdletReference.FullPath
                    [string]$optionalDescription = $typesToMessages[$type]

                    $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                    $corrections.Add($c)
                }
                foreach ($para in $cmdletReference.parameters) {
                    if ($breakingchanges.paraCmdlets[$cmdletReference.CommandName] -contains $para.Name) {
                        $type = "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletParameterBreakingChangeAttribute"
                        [int]$startLineNumber = $para.StartLine
                        [int]$endLineNumber = $para.EndLine
                        [int]$startColumnNumber = $para.StartColumn
                        [int]$endColumnNumber = $para.EndPosition
                        [string]$correction = ""
                        [string]$filePath = $para.FullPath
                        [string]$optionalDescription = $typesToMessages[$type]

                        $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                        $corrections.Add($c)
                    }
                    else {
                        $type = "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletParameterBreakingChangeAttribute"
                        [int]$startLineNumber = $cmdletReference.StartLine
                        [int]$endLineNumber = $cmdletReference.EndLine
                        [int]$startColumnNumber = $cmdletReference.StartColumn
                        [int]$endColumnNumber = $cmdletReference.EndPosition
                        [string]$correction = ""
                        [string]$filePath = $cmdletReference.FullPath
                        [string]$optionalDescription = $typesToMessages[$type]

                        $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                        $corrections.Add($c)
                        break
                    }
                }
            }
        }

        $extent = $null

        $diagRecord = New-Object `
            -Typename "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
            -ArgumentList "This arugment is not used.", $extent, $PSCmdlet.MyInvocation.InvocationName, Warning, "MyRuleSuppressionID", $corrections
        $diagRecord.SuggestedCorrections = $corrections
        $results += $diagRecord
        return $results
    }
}
Export-ModuleMember -Function Measure*
