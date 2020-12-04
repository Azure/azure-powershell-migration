# example 1: hashtable splatted arguments (supported)
$splattedParams = @{
    TargetName = $TargetName
    Count = 5
    IPv4 = $true
}
Test-Connection @splattedParams -Delay 3