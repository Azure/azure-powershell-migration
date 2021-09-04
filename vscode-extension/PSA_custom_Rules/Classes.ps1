# class Constants
# {
#     static [System.String] $ConfigurationDirectoryName = ".aztoolsmigration"
#     static [System.String] $ConfigurationFileName = "module-preferences.json"
#     static [System.String] $NewFileBaseNameSuffix = "_az_upgraded"
#     static [System.String] $PublicTelemetryInstrumentationKey = "7df6ff70-8353-4672-80d6-568517fed090"
#     static [System.String] $CurrentSessionId = [System.GUID]::NewGuid().ToString()
#     static [Microsoft.ApplicationInsights.TelemetryClient] $TelemetryClient = $null
#     static [System.String] $HashMacAddress = $null
# }

class ModulePreferences {
    [System.Boolean] $DataCollectionEnabled
}

class AliasMapping {
    [System.String] $Name
    [System.String] $ResolvedCommand
}

class CommandDefinitionParameter {
    [System.String] $Name
    [System.String[]] $Aliases
}

class CommandDefinition {
    [System.String] $Command
    [System.Boolean] $IsAlias
    [System.Boolean] $SupportsDynamicParameters
    [System.String] $SourceModule
    [System.String] $Version
    [System.Collections.Generic.List[CommandDefinitionParameter]] $Parameters
}

class CommandReferenceParameter {
    [System.String] $FileName
    [System.String] $FullPath
    [System.String] $Name
    [System.Int32] $StartLine
    [System.Int32] $StartColumn
    [System.Int32] $EndLine
    [System.Int32] $EndPosition
    [System.Int32] $StartOffset
    [System.Int32] $EndOffset
    [System.String] $Location
}

class CommandReference {
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

    CommandReference() {
        $this.Parameters = New-Object -TypeName 'System.Collections.Generic.List[CommandReferenceParameter]'
    }
}

Enum EditMode {
    ModifyExistingFiles
    SaveChangesToNewFiles
}

Enum UpgradeStepType {
    Cmdlet
    CmdletParameter
}

Enum PlanResultReasonCode {
    ReadyToUpgrade = 0
    WarningSplattedParameters = 1 # deprecated
    ErrorNoUpgradeAlias = 2
    ErrorNoModuleSpecMatch = 3
    ErrorParameterNotFound = 4
    WarningDynamicParameter = 5
}

Enum UpgradeResultReasonCode {
    UpgradeCompleted = 0
    UpgradedWithWarnings = 1
    UnableToUpgrade = 2
    UpgradeActionFailed = 3
}

Enum DiagnosticSeverity {
    Error = 1
    Warning = 2
    Information = 3
    Hint = 4
}

class UpgradePlan {
    [System.Int32] $Order
    [UpgradeStepType] $UpgradeType
    [PlanResultReasonCode] $PlanResult
    [DiagnosticSeverity] $PlanSeverity
    [System.String] $PlanResultReason
    [CommandReference] $SourceCommand
    [CommandReferenceParameter] $SourceCommandParameter
    [System.String] $Location
    [System.String] $FullPath
    [System.Int32] $StartOffset
    [System.String] $Original
    [System.String] $Replacement
}

class UpgradeResult {
    [System.Int32] $Order
    [UpgradeStepType] $UpgradeType
    [UpgradeResultReasonCode] $UpgradeResult
    [DiagnosticSeverity] $UpgradeSeverity
    [System.String] $UpgradeResultReason
    [CommandReference] $SourceCommand
    [CommandReferenceParameter] $SourceCommandParameter
    [System.String] $Location
    [System.String] $FullPath
    [System.Int32] $StartOffset
    [System.String] $Original
    [System.String] $Replacement

    UpgradeResult ([UpgradePlan] $Plan) {
        $this.Order = $Plan.Order
        $this.UpgradeType = $Plan.UpgradeType
        $this.SourceCommand = $Plan.SourceCommand
        $this.SourceCommandParameter = $Plan.SourceCommandParameter
        $this.Location = $Plan.Location
        $this.FullPath = $Plan.FullPath
        $this.StartOffset = $Plan.StartOffset
        $this.Original = $Plan.Original
        $this.Replacement = $Plan.Replacement

        # pre-stage the default results.
        # these will be used automatically unless the file fails to write.

        if ($Plan.PlanSeverity -eq [DiagnosticSeverity]::Warning) {
            $this.UpgradeResult = [UpgradeResultReasonCode]::UnableToUpgrade
            $this.UpgradeResultReason = $Plan.PlanResultReason
            $this.UpgradeSeverity = [DiagnosticSeverity]::Warning
        }
        elseif ($Plan.PlanSeverity -eq [DiagnosticSeverity]::Error) {
            $this.UpgradeResult = [UpgradeResultReasonCode]::UnableToUpgrade
            $this.UpgradeResultReason = $Plan.PlanResultReason
            $this.UpgradeSeverity = [DiagnosticSeverity]::Error
        }
        else {
            $this.UpgradeResultReason = "Automatic upgrade completed successfully."
            $this.UpgradeSeverity = [DiagnosticSeverity]::Information
        }
    }
}