# dynamic params example 1: a mix of known parameters and user / dynamic parameters should be supported, but provide a warning instead of an error.

New-AzureRmResourceGroupDeployment -ResourceGroupName "ContosoEngineering" `
    -TemplateFile "D:\Azure\Templates\EngineeringSite.json" `
    -TemplateParameterFile "D:\Azure\Templates\EngSiteParms.json" `
    -DynamicUserParam1 "test1" `
    -DynamicUserParam2 "test2"