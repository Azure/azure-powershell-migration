# How to generate Az Module alias spec and breaking change spec

The alias specifications and breaking change specifications are separately stored in `vscode-extension/PSA_Custom_Rules/Alias/AliasSpec.json` and `vscode-extension/PSA_Custom_Rules/BreakingChange/BreakingchangeSpec.json`

## Generation Instruction

1. Install all az.* modules by `Install-Module azpreview`

2. Import all az.* modules
   ```powershell
   $az_modules = gmo az.* -ListAvailable
   for ([int]$i = 0; $i -lt $az_modules.Count; $i++){
        import-module $az_modules[$i].name
    }
   ```

3. Get the Az Modules alias information and save into `vscode-extension/PSA_Custom_Rules/Alias/AliasSpec.json`
   ```powershell
   cd vscode-extension/PSA_Custom_Rules/Alias
   ./geneAlias.ps1
   ```

3. Get the Az Modules breaking change information and save into `vscode-extension/PSA_Custom_Rules/BreakingChange/BreakingchangeSpec.json`
   ```powershell
   cd vscode-extension/PSA_Custom_Rules/BreakingChange
   ./geneBreakingChange.ps1
   ```

## Specification Instruction

1. Alias Spec
   ```json
   {
        "cmdlet":    //The alias of cmdlets
       {
           "{Alias Cmdlet Name}": "{Formal Name of the Cmdlet}",
           ...
       },
       "para_cmdlet":   //The alias of cmdlets' parameters 
       {
           "{Name of Cmdlet}":
           {
               "{Alias Parameter Name}": "{Formal Name of the Parameter}",
               ...
           },
           ...
       }
   }
   ```

2. Breaking Change Spec
   ```json
   {
        "cmdlet":    //The breaking changes of cmdlets
        [
            {
                "Name": "{The name of the cmdlet}",
                "TypeBreakingChange": "The type of breaking change attribution"
            },
            ...
        ]
       
       "para_cmdlet":   //The breaking changes of cmdlets' parameters 
       [
           {
               "Name": "{The name of the parameter}",
                "TypeBreakingChange": "The type of breaking change attribution",
                "CmdletName": "{The name of the cmdlet which the parameter belongs to}"
           },
           ...
       ]
       "func":    //The breaking changes of functions
       [
           {
                "Name": "{The name of the function}",
                "TypeBreakingChange": "The type of breaking change attribution"
           },
           ...
       ]
       "para_func":   //The breaking changes of functions' parameters
       [
           {
                "Name": "{The name of the parameter}",
                "TypeBreakingChange": "The type of breaking change attribution",
                "FuncName": "{The name of the function which the parameter belongs to}"
           },
           ...
       ] 
   }
   ```