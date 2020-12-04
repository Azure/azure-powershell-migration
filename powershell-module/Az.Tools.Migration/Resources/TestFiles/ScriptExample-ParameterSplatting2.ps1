# example 2: hashtable splatted arguments with quote characters around key names (supported)
$splattedParams = @{
    "TargetName" = $TargetName
    "Count" = 5
    'IPv4' = $true
}
Test-Connection @splattedParams -Delay 3