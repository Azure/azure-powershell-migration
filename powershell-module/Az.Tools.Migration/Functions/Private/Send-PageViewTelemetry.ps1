function Send-PageViewTelemetry
{
    <#
    .SYNOPSIS
        Sends a page view telemetry item to an Azure Application Insights instance.

    .DESCRIPTION
        Sends a page view telemetry item to an Azure Application Insights instance. This function uses the Azure Application Insights REST API instead of a compiled client library, so it works without additional dependencies.

    .PARAMETER PageName
        Specifies the page or operation name.

    .PARAMETER Duration
        Specifies the duration (time elapsed) that view or operation took.

    .PARAMETER CustomProperties
        Additional custom properties in the form of a hashtable (key-value pairs) that should be logged with this telemetry.

    .EXAMPLE
        C:\> Send-PageViewTelemetry -PageName 'MyOperationName' -Duration <timespan> -CustomProperties <hashtable>
        Sends a page view telemetry to application insights.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the page or operation name.')]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $PageName,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the duration (time elapsed) that view or operation took.')]
        [System.TimeSpan]
        [ValidateNotNull()]
        $Duration,

        [Parameter(Mandatory=$false)]
        [Hashtable]
        $CustomProperties
    )
    Process
    {
        if($null -eq [Constants]::TelemetryClient) {
            $TelemetryClient = New-Object Microsoft.ApplicationInsights.TelemetryClient
            $TelemetryClient.InstrumentationKey = [Constants]::PublicTelemetryInstrumentationKey
            $TelemetryClient.Context.Session.Id = $CurrentSessionId
            $TelemetryClient.Context.Device.OperatingSystem = [System.Environment]::OSVersion.ToString()
            [Constants]::TelemetryClient = $TelemetryClient
        }

        $client = [Constants]::TelemetryClient

        $page = New-Object Microsoft.ApplicationInsights.DataContracts.PageViewTelemetry
        $page.Name = "cmdletInvocation"
        $page.Duration = $Duration

        $page.Properties["IsSuccess"] = $True.ToString()
        $page.Properties["OS"] = [System.Environment]::OSVersion.ToString()

        $page.Properties["x-ms-client-request-id"]= [Constants]::CurrentSessionId
        $page.Properties["PowerShellVersion"]= $PSVersionTable.PSVersion.ToString();
        
        if($null -ne $MyInvocation.MyCommand) {
            $page.Properties["ModuleName"] = $MyInvocation.MyCommand.ModuleName
            if($null -ne $MyInvocation.MyCommand.Module -and $null -ne $MyInvocation.MyCommand.Module.Version) {
                $page.Properties["ModuleVersion"] = $MyInvocation.MyCommand.Module.Version.ToString()
            }
        }
        $page.Properties["end-time"]= (Get-Date).ToUniversalTime().ToString("o")
        $page.Properties["duration"]= $Duration.ToString("c");
        
        # prepare custom properties
        # convert the hashtable to a custom object, if properties were supplied.

        if ($PSBoundParameters.ContainsKey('CustomProperties') -and $CustomProperties.Count -gt 0)
        {
            foreach ($Key in $CustomProperties.Keys) {
                $page.Properties[$Key] = $CustomProperties[$Key]
            }
        }

        $client.TrackPageView($page)

        try {
            $client.Flush()
        } catch {
            Write-Log -Level Warning -Exception $_ -Message "Encountered exception while trying to flush telemetry events."
        }
    }
}
