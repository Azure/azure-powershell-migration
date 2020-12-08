Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Find-CmdletsInFile tests' {
        It 'Should be able to find cmdlets used in OneCommand script file' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-OneCommand.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 1

            $results[0].GetType().FullName | Should Be "CommandReference"

            $results[0].FullPath | Should Be $testFile.Path
            $results[0].FileName | Should Be "ScriptExample-OneCommand.ps1"

            $results[0].StartLine | Should Be 1
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 1
            $results[0].EndPosition | Should Be 16
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].StartOffset | Should Be 0
            $results[0].EndOffset | Should Be 15
            $results[0].HasSplattedArguments | Should Be $false

            $results[0].Parameters.Count | Should Be 3
            $results[0].Parameters[0].Name | Should Be "TargetName"
            $results[0].Parameters[0].StartLine | Should Be 1
            $results[0].Parameters[0].StartColumn | Should Be 17
            $results[0].Parameters[0].EndLine | Should Be 1
            $results[0].Parameters[0].EndPosition | Should Be 28
            $results[0].Parameters[0].StartOffset | Should Be 16
            $results[0].Parameters[0].EndOffset | Should Be 27

            $results[0].Parameters[1].Name | Should Be "IPv4"
            $results[0].Parameters[1].StartLine | Should Be 1
            $results[0].Parameters[1].StartColumn | Should Be 41
            $results[0].Parameters[1].EndLine | Should Be 1
            $results[0].Parameters[1].EndPosition | Should Be 46
            $results[0].Parameters[1].StartOffset | Should Be 40
            $results[0].Parameters[1].EndOffset | Should Be 45

            $results[0].Parameters[2].Name | Should Be "Count"
            $results[0].Parameters[2].StartLine | Should Be 1
            $results[0].Parameters[2].StartColumn | Should Be 47
            $results[0].Parameters[2].EndLine | Should Be 1
            $results[0].Parameters[2].EndPosition | Should Be 53
            $results[0].Parameters[2].StartOffset | Should Be 46
            $results[0].Parameters[2].EndOffset | Should Be 52
        }
        It 'Should be able to find cmdlets used in MultipleCommands script file' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-MultipleCommands.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 3

            $results[0].StartLine | Should Be 1
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 1
            $results[0].EndPosition | Should Be 16
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].StartOffset | Should Be 0
            $results[0].EndOffset | Should Be 15
            $results[0].HasSplattedArguments | Should Be $false

            $results[0].Parameters.Count | Should Be 3
            $results[0].Parameters[0].Name | Should Be "TargetName"
            $results[0].Parameters[0].StartLine | Should Be 1
            $results[0].Parameters[0].StartColumn | Should Be 17
            $results[0].Parameters[0].EndLine | Should Be 1
            $results[0].Parameters[0].EndPosition | Should Be 28
            $results[0].Parameters[0].StartOffset | Should Be 16
            $results[0].Parameters[0].EndOffset | Should Be 27

            $results[0].Parameters[1].Name | Should Be "IPv4"
            $results[0].Parameters[1].StartLine | Should Be 1
            $results[0].Parameters[1].StartColumn | Should Be 41
            $results[0].Parameters[1].EndLine | Should Be 1
            $results[0].Parameters[1].EndPosition | Should Be 46
            $results[0].Parameters[1].StartOffset | Should Be 40
            $results[0].Parameters[1].EndOffset | Should Be 45

            $results[0].Parameters[2].Name | Should Be "Count"
            $results[0].Parameters[2].StartLine | Should Be 1
            $results[0].Parameters[2].StartColumn | Should Be 47
            $results[0].Parameters[2].EndLine | Should Be 1
            $results[0].Parameters[2].EndPosition | Should Be 53
            $results[0].Parameters[2].StartOffset | Should Be 46
            $results[0].Parameters[2].EndOffset | Should Be 52

            $results[1].StartLine | Should Be 3
            $results[1].StartColumn | Should Be 1
            $results[1].EndLine | Should Be 3
            $results[1].EndPosition | Should Be 14
            $results[1].CommandName | Should Be "Get-ChildItem"
            $results[1].StartOffset | Should Be 58
            $results[1].EndOffset | Should Be 71

            $results[1].Parameters.Count | Should Be 1
            $results[1].Parameters[0].Name | Should Be "Path"
            $results[1].Parameters[0].StartLine | Should Be 3
            $results[1].Parameters[0].StartColumn | Should Be 15
            $results[1].Parameters[0].EndLine | Should Be 3
            $results[1].Parameters[0].EndPosition | Should Be 20
            $results[1].Parameters[0].StartOffset | Should Be 72
            $results[1].Parameters[0].EndOffset | Should Be 77

            $results[2].StartLine | Should Be 5
            $results[2].StartColumn | Should Be 1
            $results[2].EndLine | Should Be 5
            $results[2].EndPosition | Should Be 9
            $results[2].CommandName | Should Be "Get-Help"
            $results[2].Parameters.Count | Should Be 0
        }
        It 'Should be able to find cmdlets used in OneCommand function file' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\FunctionExample-OneCommand.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 1
            $results[0].StartLine | Should Be 25
            $results[0].StartColumn | Should Be 9
            $results[0].EndLine | Should Be 25
            $results[0].EndPosition | Should Be 24
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].StartOffset | Should Be 453
            $results[0].EndOffset | Should Be 468
            $results[0].HasSplattedArguments | Should Be $false

            $results[0].Parameters.Count | Should Be 3
            $results[0].Parameters[0].Name | Should Be "TargetName"
            $results[0].Parameters[0].StartLine | Should Be 25
            $results[0].Parameters[0].StartColumn | Should Be 25
            $results[0].Parameters[0].EndLine | Should Be 25
            $results[0].Parameters[0].EndPosition | Should Be 36
            $results[0].Parameters[0].StartOffset | Should Be 469
            $results[0].Parameters[0].EndOffset | Should Be 480

            $results[0].Parameters[1].Name | Should Be "IPv4"
            $results[0].Parameters[1].StartLine | Should Be 25
            $results[0].Parameters[1].StartColumn | Should Be 49
            $results[0].Parameters[1].EndLine | Should Be 25
            $results[0].Parameters[1].EndPosition | Should Be 54
            $results[0].Parameters[1].StartOffset | Should Be 493
            $results[0].Parameters[1].EndOffset | Should Be 498

            $results[0].Parameters[2].Name | Should Be "Count"
            $results[0].Parameters[2].StartLine | Should Be 25
            $results[0].Parameters[2].StartColumn | Should Be 55
            $results[0].Parameters[2].EndLine | Should Be 25
            $results[0].Parameters[2].EndPosition | Should Be 61
            $results[0].Parameters[2].StartOffset | Should Be 499
            $results[0].Parameters[2].EndOffset | Should Be 505
        }
        It 'Should be able to find cmdlets used in MultipleCommands function file' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\FunctionExample-MultipleCommands.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 3

            $results[0].StartLine | Should Be 25
            $results[0].StartColumn | Should Be 9
            $results[0].EndLine | Should Be 25
            $results[0].EndPosition | Should Be 24
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].HasSplattedArguments | Should Be $false
        }
        It 'Should be able to find cmdlets used in SubExpression-LineContinuation function file' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\FunctionExample-SubExpressionLineContinuation.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 2

            $results[0].StartLine | Should Be 27
            $results[0].StartColumn | Should Be 13
            $results[0].EndLine | Should Be 27
            $results[0].EndPosition | Should Be 28
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].StartOffset | Should Be 481
            $results[0].EndOffset | Should Be 496
            $results[0].HasSplattedArguments | Should Be $false

            $results[0].Parameters.Count | Should Be 4

            $results[0].Parameters[0].Name | Should Be "TargetName"
            $results[0].Parameters[0].StartLine | Should Be 27
            $results[0].Parameters[0].StartColumn | Should Be 29
            $results[0].Parameters[0].EndLine | Should Be 27
            $results[0].Parameters[0].EndPosition | Should Be 40
            $results[0].Parameters[0].StartOffset | Should Be 497
            $results[0].Parameters[0].EndOffset | Should Be 508

            $results[0].Parameters[1].Name | Should Be "IPv4"
            $results[0].Parameters[1].StartLine | Should Be 28
            $results[0].Parameters[1].StartColumn | Should Be 17
            $results[0].Parameters[1].EndLine | Should Be 28
            $results[0].Parameters[1].EndPosition | Should Be 22
            $results[0].Parameters[1].StartOffset | Should Be 540
            $results[0].Parameters[1].EndOffset | Should Be 545

            $results[0].Parameters[2].Name | Should Be "Count"
            $results[0].Parameters[2].StartLine | Should Be 29
            $results[0].Parameters[2].StartColumn | Should Be 17
            $results[0].Parameters[2].EndLine | Should Be 29
            $results[0].Parameters[2].EndPosition | Should Be 23
            $results[0].Parameters[2].StartOffset | Should Be 565
            $results[0].Parameters[2].EndOffset | Should Be 571

            $results[0].Parameters[3].Name | Should Be "OriginalCommandParam"
            $results[0].Parameters[3].StartLine | Should Be 30
            $results[0].Parameters[3].StartColumn | Should Be 17
            $results[0].Parameters[3].EndLine | Should Be 30
            $results[0].Parameters[3].EndPosition | Should Be 38
            $results[0].Parameters[3].StartOffset | Should Be 624
            $results[0].Parameters[3].EndOffset | Should Be 645

            $results[1].StartLine | Should Be 29
            $results[1].StartColumn | Should Be 25
            $results[1].EndLine | Should Be 29
            $results[1].EndPosition | Should Be 41
            $results[1].CommandName | Should Be "Get-RequestCount"
            $results[1].StartOffset | Should Be 573
            $results[1].EndOffset | Should Be 589
            $results[1].HasSplattedArguments | Should Be $false

            $results[1].Parameters.Count | Should Be 1

            $results[1].Parameters[0].Name | Should Be "Test"
            $results[1].Parameters[0].StartLine | Should Be 29
            $results[1].Parameters[0].StartColumn | Should Be 42
            $results[1].Parameters[0].EndLine | Should Be 29
            $results[1].Parameters[0].EndPosition | Should Be 47
            $results[1].Parameters[0].StartOffset | Should Be 590
            $results[1].Parameters[0].EndOffset | Should Be 595
        }
        It 'Should be able to find cmdlets used in LineContinuation script file' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-LineContinuation.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 1

            $results[0].StartLine | Should Be 1
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 1
            $results[0].EndPosition | Should Be 16
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].HasSplattedArguments | Should Be $false
        }
        It 'Should be able to find cmdlets used in SubExpression-1 script file' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-SubExpressionCommand.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 2

            $results[0].StartLine | Should Be 1
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 1
            $results[0].EndPosition | Should Be 16
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].HasSplattedArguments | Should Be $false

            $results[1].StartLine | Should Be 1
            $results[1].StartColumn | Should Be 55
            $results[1].EndLine | Should Be 1
            $results[1].EndPosition | Should Be 71
            $results[1].CommandName | Should Be "Get-RequestCount"
            $results[1].HasSplattedArguments | Should Be $false
        }
        It 'Should be able to find cmdlets used in SubExpression-2 script file' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-SubExpressionCommandAfterParams.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 2

            $results[0].StartLine | Should Be 1
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 1
            $results[0].EndPosition | Should Be 16
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].HasSplattedArguments | Should Be $false

            $results[1].StartLine | Should Be 1
            $results[1].StartColumn | Should Be 55
            $results[1].EndLine | Should Be 1
            $results[1].EndPosition | Should Be 71
            $results[1].CommandName | Should Be "Get-RequestCount"
            $results[1].HasSplattedArguments | Should Be $false
        }
        It 'Should be able to find cmdlets used in SubExpression-3 script file' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-SubExpressionLineContinuation.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 2

            $results[0].StartLine | Should Be 1
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 1
            $results[0].EndPosition | Should Be 16
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].HasSplattedArguments | Should Be $false

            $results[1].StartLine | Should Be 3
            $results[1].StartColumn | Should Be 13
            $results[1].EndLine | Should Be 3
            $results[1].EndPosition | Should Be 29
            $results[1].CommandName | Should Be "Get-RequestCount"
            $results[1].HasSplattedArguments | Should Be $false
        }
        It 'Should be able to find splatted parameters' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-ParameterSplatting1.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 1
            $results[0].StartLine | Should Be 7
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 7
            $results[0].EndPosition | Should Be 16
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].HasSplattedArguments | Should Be $true
            
            # we should have 4 valid parameters here, but order is not guaranteed due to enumeration
            # over an unsorted dictionary. avoid using an ordered index check for the tests.

            $expectedParameters = @(
                [PSCustomObject]@{
                    Name = "TargetName"
                    StartLine = 3
                    StartColumn = 5
                    EndLine = 3
                    EndPosition = 15
                    StartOffset = 81
                    EndOffset = 91
                },
                [PSCustomObject]@{
                    Name = "Count"
                    StartLine = 4
                    StartColumn = 5
                    EndLine = 4
                    EndPosition = 10
                    StartOffset = 111
                    EndOffset = 116
                },
                [PSCustomObject]@{
                    Name = "IPv4"
                    StartLine = 5
                    StartColumn = 5
                    EndLine = 5
                    EndPosition = 9
                    StartOffset = 126
                    EndOffset = 130
                },
                [PSCustomObject]@{
                    Name = "Delay"
                    StartLine = 7
                    StartColumn = 33
                    EndLine = 7
                    EndPosition = 39
                    StartOffset = 175
                    EndOffset = 181
                }
            )

            $results[0].Parameters.Count | Should Be $expectedParameters.Count

            foreach ($expectedParam in $expectedParameters)
            {
                $paramSearch = $results[0].Parameters | Where-Object -FilterScript { $_.Name -eq $expectedParam.Name }

                $paramSearch | Should Not Be Null
                $paramSearch.StartLine | Should Be $expectedParam.StartLine
                $paramSearch.StartColumn | Should Be $expectedParam.StartColumn
                $paramSearch.EndLine | Should Be $expectedParam.EndLine
                $paramSearch.EndPosition | Should Be $expectedParam.EndPosition
                $paramSearch.StartOffset | Should Be $expectedParam.StartOffset
                $paramSearch.EndOffset | Should Be $expectedParam.EndOffset
            }
        }
        It 'Should be able to find splatted parameters wrapped with quote characters' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-ParameterSplatting2.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 1
            $results[0].StartLine | Should Be 7
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 7
            $results[0].EndPosition | Should Be 16
            $results[0].CommandName | Should Be "Test-Connection"
            $results[0].HasSplattedArguments | Should Be $true
            
            # we should have 4 valid parameters here, but order is not guaranteed due to enumeration
            # over an unsorted dictionary. avoid using an ordered index check for the tests.
            
            # difference here over the first example is the addition of quote characters.
            # we want to make sure we index/offset at the right locations to account for the quotes.

            $expectedParameters = @(
                [PSCustomObject]@{
                    Name = "TargetName"
                    StartLine = 3
                    StartColumn = 6
                    EndLine = 3
                    EndPosition = 16
                    StartOffset = 121
                    EndOffset = 131
                },
                [PSCustomObject]@{
                    Name = "Count"
                    StartLine = 4
                    StartColumn = 6
                    EndLine = 4
                    EndPosition = 11
                    StartOffset = 153
                    EndOffset = 158
                },
                [PSCustomObject]@{
                    Name = "IPv4"
                    StartLine = 5
                    StartColumn = 6
                    EndLine = 5
                    EndPosition = 10
                    StartOffset = 170
                    EndOffset = 174
                },
                [PSCustomObject]@{
                    Name = "Delay"
                    StartLine = 7
                    StartColumn = 33
                    EndLine = 7
                    EndPosition = 39
                    StartOffset = 220
                    EndOffset = 226
                }
            )

            $results[0].Parameters.Count | Should Be $expectedParameters.Count

            foreach ($expectedParam in $expectedParameters)
            {
                $paramSearch = $results[0].Parameters | Where-Object -FilterScript { $_.Name -eq $expectedParam.Name }

                $paramSearch | Should Not Be Null
                $paramSearch.StartLine | Should Be $expectedParam.StartLine
                $paramSearch.StartColumn | Should Be $expectedParam.StartColumn
                $paramSearch.EndLine | Should Be $expectedParam.EndLine
                $paramSearch.EndPosition | Should Be $expectedParam.EndPosition
                $paramSearch.StartOffset | Should Be $expectedParam.StartOffset
                $paramSearch.EndOffset | Should Be $expectedParam.EndOffset
            }
        }
        It 'Should not detect splatted parameter key names defined using expressions' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-ParameterSplatting3.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 1
            $results[0].StartLine | Should Be 10
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 10
            $results[0].EndPosition | Should Be 16
            $results[0].CommandName | Should Be "Test-Connection"

            # this scenario uses key names determined by other expressions.
            # this is out of scope/unsupported, but should not break the parser.
            # it should indicate that we have splatted arguments, but only detect the single valid parameter.

            $results[0].HasSplattedArguments | Should Be $true
            $results[0].Parameters.Count | Should Be 1
            $results[0].Parameters[0].Name | Should Be "Delay"
            $results[0].Parameters[0].StartLine | Should Be 10
            $results[0].Parameters[0].StartColumn | Should Be 33
            $results[0].Parameters[0].EndLine | Should Be 10
            $results[0].Parameters[0].EndPosition | Should Be 39
            $results[0].Parameters[0].StartOffset | Should Be 328
            $results[0].Parameters[0].EndOffset | Should Be 334
        }
        It 'Should not detect positional argument array splatted arguments' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-ParameterSplatting4.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 1
            $results[0].StartLine | Should Be 3
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 3
            $results[0].EndPosition | Should Be 10
            $results[0].CommandName | Should Be "Copy-Item"

            # this scenario uses positional argument arrays as splatted parameters.
            # these are positional arguments (unsupported because they have no key names).
            # however it should indicate that we have splatted arguments and only detect the single valid parameter.

            $results[0].HasSplattedArguments | Should Be $true
            $results[0].Parameters.Count | Should Be 1
            $results[0].Parameters[0].Name | Should Be "WhatIf"
            $results[0].Parameters[0].StartLine | Should Be 3
            $results[0].Parameters[0].StartColumn | Should Be 35
            $results[0].Parameters[0].EndLine | Should Be 3
            $results[0].Parameters[0].EndPosition | Should Be 42
            $results[0].Parameters[0].StartOffset | Should Be 169
            $results[0].Parameters[0].EndOffset | Should Be 176
        }
        It 'Should not detect splatted arguments defined outside the file scope' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-ParameterSplatting5.ps1"

            # act
            $results = Find-CmdletsInFile -FilePath $testFile.Path

            # assert
            $results | Should Not Be Null
            $results.Count | Should Be 1
            $results[0].StartLine | Should Be 4
            $results[0].StartColumn | Should Be 1
            $results[0].EndLine | Should Be 4
            $results[0].EndPosition | Should Be 16
            $results[0].CommandName | Should Be "Test-Connection"

            # this scenario references a hashtable argument that doesn't exist in the scope of the file.
            # this obviously isn't supported because we can't expand the search beyond the scope of the file.
            # however it should indicate that we have splatted arguments and only detect the single valid parameter.

            $results[0].HasSplattedArguments | Should Be $true
            $results[0].Parameters.Count | Should Be 1
            $results[0].Parameters[0].Name | Should Be "Delay"
            $results[0].Parameters[0].StartLine | Should Be 4
            $results[0].Parameters[0].StartColumn | Should Be 33
            $results[0].Parameters[0].EndLine | Should Be 4
            $results[0].Parameters[0].EndPosition | Should Be 39
            $results[0].Parameters[0].StartOffset | Should Be 193
            $results[0].Parameters[0].EndOffset | Should Be 199
        }
    }
}
