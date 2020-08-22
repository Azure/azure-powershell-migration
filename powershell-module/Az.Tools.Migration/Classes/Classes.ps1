class Constants
{
    static [System.String] $ConfigurationDirectoryName = ".aztoolsmigration"
    static [System.String] $ConfigurationFileName = "module-preferences.json"
    static [System.String] $PublicTelemetryInstrumentationKey = "7df6ff70-8353-4672-80d6-568517fed090"
    static [System.String] $PublicTelemetryIngestionEndpointUri = "https://dc.services.visualstudio.com/v2/track"
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
    [System.String] $FileName
    [System.String] $FullPath
    [System.String] $Name
    [System.String] $Value
    [System.Int32] $StartLine
    [System.Int32] $StartColumn
    [System.Int32] $EndLine
    [System.Int32] $EndPosition
    [System.Int32] $StartOffset
    [System.Int32] $EndOffset
    [System.String] $Location
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
    [System.String] $Location
    [System.Boolean] $HasSplattedArguments
    [System.String] $CommandName
    [System.Collections.Generic.List[CommandReferenceParameter]] $Parameters

    CommandReference()
    {
        $this.Parameters = New-Object -TypeName 'System.Collections.Generic.List[CommandReferenceParameter]'
    }
}

Enum UpgradeStepType
{
    Cmdlet
    CmdletParameter
}

Enum PlanResultReasonCode
{
    ReadyToUpgrade = 0
    WarningSplattedParameters = 1
    ErrorNoUpgradeAlias = 2
    ErrorNoModuleSpecMatch = 3
    ErrorParameterNotFound = 4
}

Enum UpgradeResultReasonCode
{
    UpgradeCompleted = 0
    UpgradedWithWarnings = 1
    UnableToUpgrade = 2
    UpgradeActionFailed = 3
}

class UpgradePlanResult
{
    [System.Int32] $Order
    [UpgradeStepType] $UpgradeType
    [PlanResultReasonCode] $PlanResult
    [System.String] $PlanResultReason
    [CommandReference] $SourceCommand
    [CommandReferenceParameter] $SourceCommandParameter
    [System.String] $Location
    [System.String] $FullPath
    [System.Int32] $StartOffset
    [System.String] $Original
    [System.String] $Replacement
}

class UpgradeResult
{
    # [UpgradeStep] $Step
    [System.Boolean] $Success
    [System.String] $Reason

    [String] ToString()
    {
        return ("[{0}:{1}:{2}] {3}" -f $this.Step.FileName, $this.Step.StartLine, $this.Step.StartColumn, $this.Reason)
    }
}