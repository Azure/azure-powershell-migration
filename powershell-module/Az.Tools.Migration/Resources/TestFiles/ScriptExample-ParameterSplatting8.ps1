# example 8: tests for GitHub issue #73
# assigning a nested hashtable to an object property (member) shouldn't break the splatted parameter detection.

if ($true) {
    $testObject.Property1 = @{
        NestedTable = @{
            NestedProperty = $true
        }
    }
}

Test-Connection -TargetName $TargetName -IPv4 -Count 5