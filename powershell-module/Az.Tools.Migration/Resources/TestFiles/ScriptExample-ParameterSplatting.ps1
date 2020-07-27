$splattedParams = @{
    TargetName = $TargetName
    Count = 5
    IPv4 = $true
}

Test-Connection @splattedParams