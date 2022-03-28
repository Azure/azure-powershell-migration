#generate the json includes breaking change information

class breakingchangeResult {
    [System.String] $Name
    [System.String] $TypeBreakingChange
    [System.String] $Message
}

class breakingchangeParaFunc {
    [System.String] $Name
    [System.String] $TypeBreakingChange
    [System.String] $FuncName
    [System.String] $Message
}

class breakingchangeParaCmdlet {
    [System.String] $Name
    [System.String] $TypeBreakingChange
    [System.String] $CmdletName
    [System.String] $Message
}

$results = @{}

$results["updateTime"] = Get-Date
$results["func"] = @()
$results["cmdlet"] = @()
$results["para_func"] = @()
$results["para_cmdlet"] = @()

$results["updateTime"] = $results["updateTime"].ToString()

$az_modules = Get-Module az.* -ListAvailable | Where-object { $_.Name -ne "Az.Tools.Migration" }

for ([int]$i = 0; $i -lt $az_modules.Count; $i++) {

    import-module $az_modules[$i].name
    $module = get-module $az_modules[$i].name

    $exportedFunctions = $module.ExportedFunctions
    $exportedCmdlets = $module.ExportedCmdlets

    foreach ($key in $exportedFunctions.Keys) {
        $func = $exportedFunctions[$key]

        #attributes of functions
        foreach ($Attribute in $func.ScriptBlock.Attributes) {

            if ($Attribute.TypeId.BaseType.Name -eq "GenericBreakingChangeAttribute" -or $Attribute.TypeId.Name -eq "GenericBreakingChangeAttribute") {
                #$Attribute.TypeId.Name
                $result = New-Object -TypeName breakingchangeResult
                $result.Name = $func.name
                $result.TypeBreakingChange = $Attribute.TypeId.FullName
                $result.Message = $Attribute.ConstructorArguments.Value
                $results["func"] += $result
            }
        }

        #attributes of parameters in function
        foreach ($parameter_key in $func.Parameters.keys) {
            $parameter = $func.Parameters[$parameter_key]
            for ([int]$k = 0; $k -lt $parameter.Attributes.Count; $k++) {
                $Attribute = $parameter.Attributes[$k]
                if ($Attribute.TypeId.BaseType.Name -eq "GenericBreakingChangeAttribute" -or $Attribute.TypeId.Name -eq "GenericBreakingChangeAttribute") {
                    #$Attribute.TypeId.Name
                    $result = New-Object -TypeName breakingchangeParaFunc
                    $result.Name = $parameter_key
                    $result.TypeBreakingChange = $Attribute.TypeId.FullName
                    $result.FuncName = $func.name
                    $result.Message = $Attribute.ChangeDescription
                    $results["para_func"] += $result
                }
            }
        }
    }

    foreach ($key in $exportedCmdlets.Keys) {
        $Cmdlet = $exportedCmdlets[$key]

        #attributes of cmdlets
        foreach ($Attribute in $Cmdlet.ImplementingType.GetCustomAttributes($true)) {
            if ($Attribute.GetType().BaseType.Name -eq "GenericBreakingChangeAttribute" -or $Attribute.GetType().Name -eq "GenericBreakingChangeAttribute") {
                $result = New-Object -TypeName breakingchangeResult
                $result.Name = $Cmdlet.Name
                $result.TypeBreakingChange = $Attribute.GetType().FullName
                $result.Message = $Attribute.GetBreakingChangeTextFromAttribute($null, $false)
                $results["cmdlet"] += $result
            }
        }

        #attributes of parameters in cmdlet
        foreach ($parameter_key in $Cmdlet.Parameters.keys) {
            $parameter = $Cmdlet.Parameters[$parameter_key]
            for ([int]$k = 0; $k -lt $parameter.Attributes.Count; $k++) {
                $Attribute = $parameter.Attributes[$k]
                if ($Attribute.TypeId.BaseType.Name -eq "GenericBreakingChangeAttribute" -or $Attribute.TypeId.Name -eq "GenericBreakingChangeAttribute") {
                    # $Attribute.TypeId.Name
                    $result = New-Object -TypeName breakingchangeParaCmdlet
                    $result.Name = $parameter_key
                    $result.TypeBreakingChange = $Attribute.TypeId.FullName
                    $result.CmdletName = $Cmdlet.Name
                    $result.Message = $Attribute.GetBreakingChangeTextFromAttribute($null, $false)
                    $results["para_cmdlet"] += $result
                }
            }
        }
    }
}
$json = $results | ConvertTo-Json
$json > BreakingchangeSpec.json
