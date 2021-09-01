

function Get-AliasSpec {
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Specify the path to the file that contains alias mapping.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $AliasPath
    )
    
    $aliasTocmdlets = Get-Content $AliasPath | ConvertFrom-Json
    
    return $aliasTocmdlets
}