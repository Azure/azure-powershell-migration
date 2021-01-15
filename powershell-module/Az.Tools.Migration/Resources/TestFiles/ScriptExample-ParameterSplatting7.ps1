# example 7: tests for GitHub issue #73
# assigning a hashtable to an object property (member) shouldn't break the splatted parameter detection.

$testObject.Property1 = @{ key1 = $value1 }

if ($true) {
    $testObject.Property2 += @{ key2 = $value2 }
}

Test-Connection -TargetName $TargetName -IPv4 -Count 5