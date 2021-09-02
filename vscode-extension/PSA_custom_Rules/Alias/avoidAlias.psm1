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
function Measure-AvoidAlias {
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
        $getAliasSpecFunctionFile = "C:\Users\t-zenli\workspace\dev\azure-powershell-migration\vscode-extension\PSA_custom_Rules\Alias\Get-AliasSpec.ps1"
        . $getAliasSpecFunctionFile

        #get the alias mapping data
        $aliasSpecFile = "C:\Users\t-zenli\workspace\dev\azure-powershell-migration\vscode-extension\PSA_custom_Rules\Alias\aliasTocmdlet.json"
        $aliasTocmdlets = Get-AliasSpec -AliasPath $aliasSpecFile

        # get the commandAst in the file
        $foundCmdlets = Find-CmdletsInFile -rootAstNode $testAst
    

        $l = (new-object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"])

        foreach ($cmdletReference in $foundCmdlets) {
            if ($aliasTocmdlets.psobject.properties.match($cmdletReference.CommandName).Count){
                [int]$startLineNumber = $cmdletReference.StartLine
                [int]$endLineNumber = $cmdletReference.EndLine
                [int]$startColumnNumber = $cmdletReference.StartColumn
                [int]$endColumnNumber = $cmdletReference.EndPosition
                [string]$correction = $aliasTocmdlets.($cmdletReference.CommandName)
                [string]$filePath = $cmdletReference.FullPath
                [string]$optionalDescription = 'The alias can be changed to be formal name.'

                $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                $l.Add($c)
                
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