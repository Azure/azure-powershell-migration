# example 3: hashtable splatted arguments with variable expressions in keynames (not supported, but should not break parser)
$keyName1 = "TargetName"
$keyName2 = "Count"
$keyName3 = "IPv4"
$splattedParams = @{
    "$keyName1" = $TargetName
    "$($keyName2)" = 5
    $keyName3 = $true
}
Test-Connection @splattedParams -Delay 3