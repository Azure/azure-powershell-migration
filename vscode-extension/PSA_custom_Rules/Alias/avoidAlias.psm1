#Requires -Version 3.0

<#
.SYNOPSI
    Avoid alias in powershell script.
.DESCRIPTION
    Find all aliases that appear in the powershell script. And give the suggestion to change them to formal name.
.EXAMPLE
    Measure-AvoidAlias -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
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
        $findCmdFunctionFile = ".\PSA_custom_Rules\Find-CmdletsInFile.psm1"
        Import-Module $findCmdFunctionFile
        $getAliasSpecFunctionFile = ".\PSA_custom_Rules\Alias\Get-AliasSpec.psm1"
        Import-Module $getAliasSpecFunctionFile

        #get the alias mapping data
        $aliasSpecFile = ".\PSA_custom_Rules\Alias\AliasSpec.json"
        $AliasSpec = Get-AliasSpec -AliasPath $aliasSpecFile

        # get the commandAst in the file
        $foundCmdlets = Find-CmdletsInFile -rootAstNode $testAst
    
        #list of CorrectionExtents
        $l = (new-object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"])

        foreach ($cmdletReference in $foundCmdlets) {
            if ($AliasSpec.cmdlet.psobject.properties.match($cmdletReference.CommandName).Count) {
                [int]$startLineNumber = $cmdletReference.StartLine
                [int]$endLineNumber = $cmdletReference.EndLine
                [int]$startColumnNumber = $cmdletReference.StartColumn
                [int]$endColumnNumber = $cmdletReference.EndPosition
                [string]$correction = $AliasSpec.cmdlet.($cmdletReference.CommandName)
                [string]$filePath = $cmdletReference.FullPath
                [string]$optionalDescription = 'The alias can be changed to be formal name.'

                $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                $l.Add($c)
                
            }

            if ($AliasSpec.para_cmdlet.psobject.properties.match($cmdletReference.CommandName).Count){
                foreach ($para in $cmdletReference.parameters){
                    if ($AliasSpec.para_cmdlet.($cmdletReference.CommandName).psobject.properties.match($para.Name).Count){
                        [int]$startLineNumber = $para.StartLine
                        [int]$endLineNumber = $para.EndLine
                        [int]$startColumnNumber = $para.StartColumn
                        [int]$endColumnNumber = $para.EndPosition
                        [string]$correction = $AliasSpec.para_cmdlet.($cmdletReference.CommandName).($para.Name)
                        [string]$filePath = $para.FullPath
                        [string]$optionalDescription = 'The alias can be changed to be formal name.'

                        $c = (new-object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                        $l.Add($c)
                    }
                }
            }
        }
        


        $extent = $null
        
        #returned anaylse results
        $dr = New-Object `
            -Typename "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
            -ArgumentList "This is help", $extent, $PSCmdlet.MyInvocation.InvocationName, Warning, "MyRuleSuppressionID", $l
        $dr.SuggestedCorrections = $l
        $results += $dr
        return $results
    }
}
Export-ModuleMember -Function Measure*