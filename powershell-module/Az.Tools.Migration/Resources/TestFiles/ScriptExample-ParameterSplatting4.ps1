# example 4: array splatted arguments (not supported, but should not break parser)
$ArraySplattedArguments = "test.txt", "test2.txt"
Copy-Item @ArraySplattedArguments -WhatIf