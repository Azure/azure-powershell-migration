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
        $scriptAst
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
        $cmdletUsingAlias = Find-CmdletsInFile -RootAstNode $scriptAst
    
        #list of CorrectionExtents
        $corrections = (New-Object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"])

        foreach ($cmdletReference in $cmdletUsingAlias) {
            # If the cmdlet is in the cmdlets alias list
            if ($AliasSpec.cmdlet.Psobject.Properties.Match($cmdletReference.CommandName).Count) {
                [int]$startLineNumber = $cmdletReference.StartLine
                [int]$endLineNumber = $cmdletReference.EndLine
                [int]$startColumnNumber = $cmdletReference.StartColumn
                [int]$endColumnNumber = $cmdletReference.EndPosition
                [string]$CommandName = $cmdletReference.CommandName
                [string]$correction = $AliasSpec.cmdlet.($CommandName)
                [string]$filePath = $cmdletReference.FullPath
                [string]$optionalDescription = 
                "'$CommandName' is an alias of '$correction'. Alias can introduce possible problems and make scripts hard to maintain. Please consider changing alias to its full content."

                $c = (New-Object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                $corrections.Add($c)
                
            }

            # If the cmdlet has one or more parameters having alias
            if ($AliasSpec.para_cmdlet.Psobject.Properties.Match($cmdletReference.CommandName).Count){
                foreach ($para in $cmdletReference.parameters){
                    # If the cmdlet parameters list in alias spec contains the parameter
                    if ($AliasSpec.para_cmdlet.($cmdletReference.CommandName).psobject.properties.match($para.Name).Count){
                        [int]$startLineNumber = $para.StartLine
                        [int]$endLineNumber = $para.EndLine
                        [int]$startColumnNumber = $para.StartColumn
                        [int]$endColumnNumber = $para.EndPosition
                        [string]$CommandName = $cmdletReference.CommandName
                        [string]$ParameterName = $para.Name
                        [string]$correction = $AliasSpec.para_cmdlet.($CommandName).($ParameterName)
                        [string]$filePath = $para.FullPath
                        [string]$optionalDescription = 
                        "'$ParameterName' is an alias of '$correction' in the cmdlet '$CommandName'. Alias can introduce possible problems and make scripts hard to maintain. Please consider changing alias to its full content."

                        $c = (New-Object  Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent $startLineNumber, $endLineNumber, $startColumnNumber, $endColumnNumber, $correction, $filePath, $optionalDescription)
                        $corrections.Add($c)
                    }
                }
            }
        }
        


        $extent = $null
        
        #returned anaylse results
        $diagRecord  = New-Object  `
            -Typename "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
            -ArgumentList "This arugment is not used.", $extent, $PSCmdlet.MyInvocation.InvocationName, Warning, "MyRuleSuppressionID", $corrections
        $diagRecord.SuggestedCorrections = $corrections
        $results += $diagRecord
        return $results
    }
}
Export-ModuleMember -Function Measure*