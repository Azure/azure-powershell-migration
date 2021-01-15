# dynamic params example 1: a mix of known parameters and user / dynamic parameters should be supported, but provide a warning instead of an error.

New-AzResourceGroupDeployment -ResourceGroupName "ContosoEngineering" `
    -TemplateFile "D:\Azure\Templates\EngineeringSite.json" `
    -TemplateParameterFile "D:\Azure\Templates\EngSiteParms.json" `
    - "test1" `
    - "test2"
