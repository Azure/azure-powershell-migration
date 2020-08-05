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
        $AppInsightsIngestionEndpoint = [Constants]::PublicTelemetryIngestionEndpointUri
        $InstrumentationKey = [Constants]::PublicTelemetryInstrumentationKey

        # prepare custom properties
        # convert the hashtable to a custom object, if properties were supplied.

        if ($PSBoundParameters.ContainsKey('CustomProperties') -and $CustomProperties.Count -gt 0)
        {
            $customPropertiesObj = [PSCustomObject]$CustomProperties
        }
        else
        {
            $customPropertiesObj = [PSCustomObject]@{}
        }

        # prepare the REST request body schema (version 2.x).

        $bodyObject = [PSCustomObject]@{
            'name' = "AppPageViews"
            'time' = ([System.DateTime]::UtcNow.ToString('o'))
            'iKey' = $InstrumentationKey
            'tags' = [PSCustomObject]@{
                'ai.internal.sdkVersion' = ('Az.Tools.Migration.' + $MyInvocation.MyCommand.Module.ModuleVersion)
            }
            'data' = [PSCustomObject]@{
                'baseType' = 'PageViewData'
                'baseData' = [PSCustomObject]@{
                    'ver' = '2'
                    'name' = $PageName
                    'duration' = $Duration.ToString()
                    'properties' = $customPropertiesObj
                }
            }
        }

        # convert the body object into a json blob.
        # prepare the headers
        # send the request

        $bodyAsCompressedJson = $bodyObject | ConvertTo-JSON -Depth 5 -Compress
        $headers = @{
            'Content-Type' = 'application/x-json-stream';
        }

        Invoke-RestMethod -Uri $AppInsightsIngestionEndpoint -Method Post -Headers $headers -Body $bodyAsCompressedJson
    }
}