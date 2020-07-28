function New-TelemetryClient
{
    <#
    .SYNOPSIS
        Returns a new instance of the TelemetryClient.

    .DESCRIPTION
        Returns a new instance of the TelemetryClient. This is used for sending metrics.

    .EXAMPLE
        PS C:\ New-TelemetryClient
        Returns a new instance of the TelemetryClient.
    #>
    [CmdletBinding()]
    Param
    (
    )
    Process
    {
        $instrumentationKey = $MyInvocation.MyCommand.Module.PrivateData.Constants['PublicTelemetryInstrumentationKey']

        $configuration = New-Object -TypeName Microsoft.ApplicationInsights.Extensibility.TelemetryConfiguration -ArgumentList $instrumentationKey
        $client = New-Object -TypeName Microsoft.ApplicationInsights.TelemetryClient -ArgumentList $configuration

        Write-Output -InputObject $client
    }
}