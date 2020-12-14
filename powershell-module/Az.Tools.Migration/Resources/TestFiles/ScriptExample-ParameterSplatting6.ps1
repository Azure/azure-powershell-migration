# example 1: hashtable splatted arguments with an ordered hashtable (supported)
$splattedParams = [ordered]@{
    TargetName = $TargetName
    Count = 5
    IPv4 = $true
}
Test-Connection @splattedParams -Delay 3