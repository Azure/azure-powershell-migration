Test-Connection -TargetName $TargetName `
    -IPv4 `
    -Count (Get-RequestCount -Test "Value") `
    -OriginalCommandParam "Value2"