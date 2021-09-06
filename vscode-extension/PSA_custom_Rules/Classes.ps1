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