export enum UpgradeStepType {
    Cmdlet,
    CmdletParameter
}

export enum PlanResultReasonCode {
    ReadyToUpgrade = 0,
    WarningSplattedParameters = 1, // deprecated
    ErrorNoUpgradeAlias = 2,
    ErrorNoModuleSpecMatch = 3,
    ErrorParameterNotFound = 4,
    WarningDynamicParameter = 5
}

export enum DiagnosticSeverity {
    Error = 1,
    Warning = 2,
    Information = 3,
    Hint = 4
}

export interface CommandReferenceParameter {
    FileName: string;
    FullPath: string;
    Name: string;
    StartLine: number;
    StartColumn: number;
    EndLine: number;
    EndPosition: number;
    StartOffset: number;
    EndOffset: number;
    Location: string;
}

export interface CommandReference {
    FileName: string;
    FullPath: string;
    StartLine: number;
    StartColumn: number;
    EndLine: number;
    EndPosition: number;
    StartOffset: number;
    EndOffset: number;
    Location: string;
    HasSplattedArguments: boolean;
    CommandName: string;
    Parameters: CommandReferenceParameter[];
}

export interface UpgradePlan {
    Order: number;
    UpgradeType: UpgradeStepType;
    PlanResult: PlanResultReasonCode;
    PlanSeverity: DiagnosticSeverity;
    PlanResultReason: string;
    SourceCommand: CommandReference;
    SourceCommandParameter: CommandReferenceParameter;
    Location: string;
    FullPath: string;
    StartOffset: number;
    Original: string;
    Replacement: string;
}
