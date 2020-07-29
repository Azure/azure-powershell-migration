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
            $results[0].Parameters[0].Value | Should Be "`$TargetName"
            $results[0].Parameters[0].StartLine | Should Be 1
            $results[0].Parameters[0].StartColumn | Should Be 17
            $results[0].Parameters[0].EndLine | Should Be 1
            $results[0].Parameters[0].EndPosition | Should Be 28
            $results[0].Parameters[0].StartOffset | Should Be 16
            $results[0].Parameters[0].EndOffset | Should Be 27

            $results[0].Parameters[1].Name | Should Be "IPv4"
            $results[0].Parameters[1].Value | Should Be ([System.String]::Empty)
            $results[0].Parameters[1].StartLine | Should Be 1
            $results[0].Parameters[1].StartColumn | Should Be 41
            $results[0].Parameters[1].EndLine | Should Be 1
            $results[0].Parameters[1].EndPosition | Should Be 46
            $results[0].Parameters[1].StartOffset | Should Be 40
            $results[0].Parameters[1].EndOffset | Should Be 45

            $results[0].Parameters[2].Name | Should Be "Count"
            $results[0].Parameters[2].Value | Should Be "5"
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
            $results[0].Parameters[0].Value | Should Be "`$TargetName"
            $results[0].Parameters[0].StartLine | Should Be 1
            $results[0].Parameters[0].StartColumn | Should Be 17
            $results[0].Parameters[0].EndLine | Should Be 1
            $results[0].Parameters[0].EndPosition | Should Be 28
            $results[0].Parameters[0].StartOffset | Should Be 16
            $results[0].Parameters[0].EndOffset | Should Be 27

            $results[0].Parameters[1].Name | Should Be "IPv4"
            $results[0].Parameters[1].Value | Should Be ([System.String]::Empty)
            $results[0].Parameters[1].StartLine | Should Be 1
            $results[0].Parameters[1].StartColumn | Should Be 41
            $results[0].Parameters[1].EndLine | Should Be 1
            $results[0].Parameters[1].EndPosition | Should Be 46
            $results[0].Parameters[1].StartOffset | Should Be 40
            $results[0].Parameters[1].EndOffset | Should Be 45

            $results[0].Parameters[2].Name | Should Be "Count"
            $results[0].Parameters[2].Value | Should Be "5"
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
            $results[1].Parameters[0].Value | Should Be "`"C:\users\user`""
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
            $results[0].Parameters[0].Value | Should Be "`$TargetName"
            $results[0].Parameters[0].StartLine | Should Be 25
            $results[0].Parameters[0].StartColumn | Should Be 25
            $results[0].Parameters[0].EndLine | Should Be 25
            $results[0].Parameters[0].EndPosition | Should Be 36
            $results[0].Parameters[0].StartOffset | Should Be 469
            $results[0].Parameters[0].EndOffset | Should Be 480

            $results[0].Parameters[1].Name | Should Be "IPv4"
            $results[0].Parameters[1].Value | Should Be ([System.String]::Empty)
            $results[0].Parameters[1].StartLine | Should Be 25
            $results[0].Parameters[1].StartColumn | Should Be 49
            $results[0].Parameters[1].EndLine | Should Be 25
            $results[0].Parameters[1].EndPosition | Should Be 54
            $results[0].Parameters[1].StartOffset | Should Be 493
            $results[0].Parameters[1].EndOffset | Should Be 498

            $results[0].Parameters[2].Name | Should Be "Count"
            $results[0].Parameters[2].Value | Should Be "5"
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
            $results[0].Parameters[0].Value | Should Be "`$TargetName"
            $results[0].Parameters[0].StartLine | Should Be 27
            $results[0].Parameters[0].StartColumn | Should Be 29
            $results[0].Parameters[0].EndLine | Should Be 27
            $results[0].Parameters[0].EndPosition | Should Be 40
            $results[0].Parameters[0].StartOffset | Should Be 497
            $results[0].Parameters[0].EndOffset | Should Be 508

            $results[0].Parameters[1].Name | Should Be "IPv4"
            $results[0].Parameters[1].Value | Should Be ([System.String]::Empty)
            $results[0].Parameters[1].StartLine | Should Be 28
            $results[0].Parameters[1].StartColumn | Should Be 17
            $results[0].Parameters[1].EndLine | Should Be 28
            $results[0].Parameters[1].EndPosition | Should Be 22
            $results[0].Parameters[1].StartOffset | Should Be 540
            $results[0].Parameters[1].EndOffset | Should Be 545

            $results[0].Parameters[2].Name | Should Be "Count"
            $results[0].Parameters[2].Value | Should Be "(Get-RequestCount -Test `"Value`")"
            $results[0].Parameters[2].StartLine | Should Be 29
            $results[0].Parameters[2].StartColumn | Should Be 17
            $results[0].Parameters[2].EndLine | Should Be 29
            $results[0].Parameters[2].EndPosition | Should Be 23
            $results[0].Parameters[2].StartOffset | Should Be 565
            $results[0].Parameters[2].EndOffset | Should Be 571

            $results[0].Parameters[3].Name | Should Be "OriginalCommandParam"
            $results[0].Parameters[3].Value | Should Be "`"Value2`""
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
            $results[1].Parameters[0].Value | Should Be "`"Value`""
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
        It 'Should be able to find cmdlets that have splatted parameters' {
            # arrange
            $testFile = Resolve-Path -Path ".\Resources\TestFiles\ScriptExample-ParameterSplatting.ps1"

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

            $results[0].Parameters.Count | Should Be 0
        }
    }
}
