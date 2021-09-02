#Requires -Version 3.0

<#
.SYNOPSI
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
function Measure-UpcomingBreakingChange {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $testAst
    )
    
    Process {
        $results = @()
        # import functions
        $classFile = "C:\Users\t-zenli\workspace\dev\azure-powershell-migration\vscode-extension\PSA_custom_Rules\Classes.ps1"
        . $classFile
        $findCmdFunctionFile = "C:\Users\t-zenli\workspace\dev\azure-powershell-migration\vscode-extension\PSA_custom_Rules\Find-CmdletsInFile.ps1"
        . $findCmdFunctionFile
        $getBreakingchangeSpecFunctionFile = "C:\Users\t-zenli\workspace\dev\azure-powershell-migration\vscode-extension\PSA_custom_Rules\BreakingChange\Get-BreakingChangeSpec.ps1"
        . $getBreakingchangeSpecFunctionFile

        #get the alias mapping data
        $breakingChangePath = "C:\Users\t-zenli\workspace\dev\azure-powershell-migration\vscode-extension\PSA_custom_Rules\BreakingChange\breakingchange.json"
        $breakingchanges = Get-BreakingChangeSpec -BreakingChangePath $breakingChangePath

        # get the commandAst in the file
        $foundCmdlets = Find-CmdletsInFile -rootAstNode $testAst
        $typesToMessages = @{
            "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.GenericBreakingChangeAttribute" = "The breaking change is expected to take effect from the next version.";
            "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletDeprecationAttribute" = "The cmdlet is being deprecated. There will be no replacement for it.";
            "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletOutputBreakingChangeAttribute" = "The output type is being deprecated without a replacement.";
            "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletParameterBreakingChangeAttribute" = "The parameter is changing."
        }

        $l = (new-object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"])


        foreach ($cmdletReference in $foundCmdlets) {
            if ($breakingchanges.cmdlets.Keys -contains $cmdletReference.CommandName){
                $type = $breakingchanges.cmdlets[$cmdletReference.CommandName]
                [int]$startLineNumber = $cmdletReference.StartLine
                [int]$endLineNumber = $cmdletReference.EndLine
                [int]$startColumnNumber = $cmdletReference.StartColumn
                [int]$endColumnNumber = $cmdletReference.EndPosition
                [string]$correction = ""
                [string]$filePath = $cmdletReference.FullPath
                [string]$optionalDescription = $typesToMessages[$type]

                $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                $l.Add($c)
            }

            if ($breakingchanges.paraCmdlets.Keys -contains $cmdletReference.CommandName){
                if ($cmdletReference.parameters.Count -eq 0){
                    $type = "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletParameterBreakingChangeAttribute"
                        [int]$startLineNumber = $cmdletReference.StartLine
                        [int]$endLineNumber = $cmdletReference.EndLine
                        [int]$startColumnNumber = $cmdletReference.StartColumn
                        [int]$endColumnNumber = $cmdletReference.EndPosition
                        [string]$correction = ""
                        [string]$filePath = $cmdletReference.FullPath
                        [string]$optionalDescription = $typesToMessages[$type]

                        $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                        $l.Add($c)
                }
                foreach ($para in $cmdletReference.parameters){
                    if ($breakingchanges.paraCmdlets[$cmdletReference.CommandName] -contains $para.Name){
                        $type = "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletParameterBreakingChangeAttribute"
                        [int]$startLineNumber = $para.StartLine
                        [int]$endLineNumber = $para.EndLine
                        [int]$startColumnNumber = $para.StartColumn
                        [int]$endColumnNumber = $para.EndPosition
                        [string]$correction = ""
                        [string]$filePath = $para.FullPath
                        [string]$optionalDescription = $typesToMessages[$type]

                        $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                        $l.Add($c)
                    }
                    else{
                        $type = "Microsoft.WindowsAzure.Commands.Common.CustomAttributes.CmdletParameterBreakingChangeAttribute"
                        [int]$startLineNumber = $cmdletReference.StartLine
                        [int]$endLineNumber = $cmdletReference.EndLine
                        [int]$startColumnNumber = $cmdletReference.StartColumn
                        [int]$endColumnNumber = $cmdletReference.EndPosition
                        [string]$correction = ""
                        [string]$filePath = $cmdletReference.FullPath
                        [string]$optionalDescription = $typesToMessages[$type]

                        $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                        $l.Add($c)
                        break
                    }
                }
            }
        }
        


        $extent = $null
        
        $dr = New-Object `
            -Typename "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
            -ArgumentList "This is help", $extent, $PSCmdlet.MyInvocation.InvocationName, Warning, "MyRuleSuppressionID", $l
        $dr.SuggestedCorrections = $l
        $results += $dr
        return $results
    }
}
Export-ModuleMember -Function Measure*