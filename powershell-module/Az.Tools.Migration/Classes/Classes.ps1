class Constants
{
    static [System.String] $ConfigurationDirectoryName = ".aztoolsmigration"
    static [System.String] $ConfigurationFileName = "module-preferences.json"
    static [System.String] $PublicTelemetryInstrumentationKey = "f1e252c1-5cb5-4ddb-8a2a-66e6a16d1c71"
}

class ModulePreferences
{
    [System.Boolean] $DataCollectionEnabled
}

class AliasMapping
{
    [System.String] $Name
    [System.String] $ResolvedCommand
}

class CommandDefinitionParameter
{
    [System.String] $Name
    [System.String[]] $Aliases
}

class CommandDefinition
{
    [System.String] $Command
    [System.Boolean] $IsAlias
    [System.String] $SourceModule
    [System.String] $Version
    [System.Collections.Generic.List[CommandDefinitionParameter]] $Parameters

    CommandDefinition()
    {
        $this.Parameters = New-Object -TypeName 'System.Collections.Generic.List[CommandDefinitionParameter]'
    }
}

class CommandReferenceParameter
{
    [System.String] $Name
    [System.String] $Value
    [System.Int32] $StartLine
    [System.Int32] $StartColumn
    [System.Int32] $EndLine
    [System.Int32] $EndPosition
    [System.Int32] $StartOffset
    [System.Int32] $EndOffset
}

class CommandReference
{
    [System.String] $FileName
    [System.String] $FullPath
    [System.Int32] $StartLine
    [System.Int32] $StartColumn
    [System.Int32] $EndLine
    [System.Int32] $EndPosition
    [System.Int32] $StartOffset
    [System.Int32] $EndOffset
    [System.Boolean] $HasSplattedArguments
    [System.String] $CommandName
    [System.Collections.Generic.List[CommandReferenceParameter]] $Parameters

    CommandReference()
    {
        $this.Parameters = New-Object -TypeName 'System.Collections.Generic.List[CommandReferenceParameter]'
    }

    [String] ToString()
    {
        return ("{0} [{1}:{2}:{3}]" -f $this.CommandName, $this.FileName, $this.StartLine, $this.StartColumn)
    }
}

class CommandReferenceCollection
{
    [System.Collections.Generic.List[CommandReference]] $Items

    CommandReferenceCollection()
    {
        $this.Items = New-Object -TypeName 'System.Collections.Generic.List[CommandReference]'
    }
}

Enum UpgradeStepType
{
    Cmdlet
    CmdletParameter
}

class UpgradeStep
{
    [System.Int32] $StepNumber
    [UpgradeStepType] $UpgradeType
    [System.String] $FileName
    [System.String] $FullPath
    [System.Int32] $StartLine
    [System.Int32] $StartColumn
    [System.Int32] $EndLine
    [System.Int32] $EndPosition
    [System.Int32] $StartOffset
    [System.Int32] $EndOffset
}

class CmdletUpgradeStep : UpgradeStep
{
    [System.String] $OriginalCmdletName
    [System.String] $ReplacementCmdletName

    CmdletUpgradeStep()
    {
        $this.UpgradeType = [UpgradeStepType]::Cmdlet
    }

    [String] ToString()
    {
        return ("Cmdlet {0} to {1} [{2}:{3}:{4}]" -f $this.OriginalCmdletName, $this.ReplacementCmdletName, $this.FileName, $this.StartLine, $this.StartColumn)
    }
}

class CmdletParameterUpgradeStep : UpgradeStep
{
    [System.String] $OriginalParameterName
    [System.String] $ReplacementParameterName

    CmdletParameterUpgradeStep()
    {
        $this.UpgradeType = [UpgradeStepType]::CmdletParameter
    }

    [String] ToString()
    {
        return ("Parameter -{0} to -{1} [{2}:{3}:{4}]" -f $this.OriginalParameterName, $this.ReplacementParameterName, $this.FileName, $this.StartLine, $this.StartColumn)
    }
}

Enum UpgradePlanResultReasonCode
{
    WarningSplattedParameters = 1
    ErrorNoUpgradeAlias = 2
    ErrorNoModuleSpecMatch = 3
    ErrorParameterNotFound = 4
}

class UpgradePlanResult
{
    [CommandReference] $Command
    [System.String] $Reason
    [UpgradePlanResultReasonCode] $ReasonCode

    [String] ToString()
    {
        return ("[{0}:{1}:{2}] {3}" -f $this.Command.FileName, $this.Command.StartLine, $this.Command.StartColumn, $this.Reason)
    }
}

class UpgradePlan
{
    [System.Collections.Generic.List[UpgradeStep]] $UpgradeSteps
    [System.Collections.Generic.List[UpgradePlanResult]] $Warnings
    [System.Collections.Generic.List[UpgradePlanResult]] $Errors

    UpgradePlan()
    {
        $this.UpgradeSteps = New-Object -TypeName 'System.Collections.Generic.List[UpgradeStep]'
        $this.Warnings = New-Object -TypeName 'System.Collections.Generic.List[UpgradePlanResult]'
        $this.Errors = New-Object -TypeName 'System.Collections.Generic.List[UpgradePlanResult]'
    }
}

class UpgradeResult
{
    [UpgradeStep] $Step
    [System.Boolean] $Success
    [System.String] $Reason

    [String] ToString()
    {
        return ("[{0}:{1}:{2}] {3}" -f $this.Step.FileName, $this.Step.StartLine, $this.Step.StartColumn, $this.Reason)
    }
}