$aliasResults = @{}

$matchPattern = "(\b[a-zA-z]+-?[a-zA-z]+\b)"
$cmdletRegex = New-Object System.Text.RegularExpressions.Regex($matchPattern)
$aliasCmdlets = get-alias | where-object {$cmdletRegex.IsMatch($_.Name)}

for ([int]$i = 0; $i -lt $aliasCmdlets.Count; $i++){
    $aliasCmdlet = $aliasCmdlets[$i]
    $aliasResults[$aliasCmdlet.Name] = $aliasCmdlet.ReferencedCommand.Name
}

$json = $aliasResults | ConvertTo-Json
$json > aliasTocmdlet.json


