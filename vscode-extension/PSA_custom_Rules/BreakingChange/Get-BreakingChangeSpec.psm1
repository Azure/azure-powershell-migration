

function Get-BreakingChangeSpec {
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Specify the path to the file that contains alias mapping.")]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $BreakingChangePath
    )
    
    $breakingchange = Get-Content $BreakingChangePath | ConvertFrom-Json

    $cmdletSet = @{}
    for ([int]$i = 0; $i -lt $breakingchange.cmdlet.Count; $i++){
        $cmdlet = $breakingchange.cmdlet.Name[$i]
        $cmdletSet[$cmdlet] = $breakingchange.cmdlet.TypeBreakingChange[$i]
    }
    
    $cmdlet_para_set = @{}
    for ([int]$i = 0; $i -lt $breakingchange.para_cmdlet.Count; $i++){
        
        $cmdlet = $breakingchange.para_cmdlet.CmdletName[$i]
        if ($cmdlet_para_set.Keys -notcontains $cmdlet){
            $cmdlet_para_set[$cmdlet] = @()
        }
        $cmdlet_para_set[$cmdlet] += $breakingchange.para_cmdlet.Name[$i]
        
    }
    
    
    $breakingchanges = @{
        cmdlets = $cmdletSet;
        paraCmdlets = $cmdlet_para_set
    }
    $breakingchanges.paraCmdlets

    
    return $breakingchanges
}