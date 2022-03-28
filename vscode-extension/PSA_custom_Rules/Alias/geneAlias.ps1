#generate the json file includes alias information

$az_modules = Get-Module az.* -ListAvailable | Where-object { $_.Name -ne "Az.Tools.Migration" }
for ([int]$i = 0; $i -lt $az_modules.Count; $i++) {
    import-module $az_modules[$i].name
}

$aliasResults = @{}

$matchPattern = "(\b[a-zA-z]+-?[a-zA-z]+\b)"    # matches any alias
$matchPatternFormalName = "(\b[a-zA-z]+-?[Az][a-zA-z]+\b)"  # matches formal names of Az cmdlets
$cmdletRegex = New-Object System.Text.RegularExpressions.Regex($matchPattern)
$cmdletRegexFormal = New-Object System.Text.RegularExpressions.Regex($matchPatternFormalName)
$aliasCmdlets = get-alias | where-object { $cmdletRegex.IsMatch($_.Name) -and $cmdletRegexFormal.IsMatch($_.ReferencedCommand.Name) }

for ([int]$i = 0; $i -lt $aliasCmdlets.Count; $i++) {
    $aliasCmdlet = $aliasCmdlets[$i]
    $aliasResults[$aliasCmdlet.Name] = $aliasCmdlet.ReferencedCommand.Name
}

class getBreakingchangeResult_paraCmdlet {
    [System.String] $Name
    [System.String] $TypeBreakingChange
}

$results = @{}

$results["updateTime"] = Get-Date
$results["cmdlet"] = $aliasResults
$results["para_cmdlet"] = @{}
$results["updateTime"] = $results["updateTime"].ToString()

$paraBlockList = @("InformationVariable",
                "OutVariable",
                "WhatIf",
                "PipelineVariable",
                "OutBuffer",
                "WarningVariable",
                "ErrorVariable",
                "InformationAction",
                "Verbose",
                "ErrorAction",
                "Debug",
                "WarningAction",
                "Confirm")
for ([int]$i = 0; $i -lt $az_modules.Count; $i++) {
    # import-module $az_modules[$i].name
    $module = get-module $az_modules[$i].name

    $exportedCmdlets = $module.ExportedCmdlets

    foreach ($key in $exportedCmdlets.Keys) {
        $Cmdlet = $exportedCmdlets[$key]

        #attributes of parameters in cmdlet
        $results["para_cmdlet"][$Cmdlet.Name] = @{}

        foreach ($parameter_key in $Cmdlet.Parameters.keys) {
            $parameter = $Cmdlet.Parameters[$parameter_key]

            for ([int]$j = 0; $j -lt $parameter.Aliases.Count; $j++) {
                $paraAlias = $parameter.Aliases[$j]
                $paraFormal = $parameter_key
                if ($paraBlockList -notcontains $paraFormal){
                    $results["para_cmdlet"][$Cmdlet.Name][$paraAlias] = $paraFormal
                }
            }
        }
    }
}
$json = $results | ConvertTo-Json -depth 10
$json > AliasSpec.json
