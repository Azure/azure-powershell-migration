# Azure Powershell Tools

[![Version](https://vsmarketplacebadge.apphb.com/version/azps-tools.azps-tools.svg)](https://marketplace.visualstudio.com/items?itemName=azps-tools.azps-tools)
[![Installs](https://vsmarketplacebadge.apphb.com/installs-short/azps-tools.azps-tools.svg)](https://marketplace.visualstudio.com/items?itemName=azps-tools.azps-tools)

Effortlessly migrate your PowerShell scripts from AzureRM to the Az PowerShell module.

![Azure Powershell Tools overview](resources/readme/overview.gif)

## Features

- AzureRM commands highlighting.
- Quick Fix for some AzureRM commands.

## Installing the Extension

You can install the official release of the Azure PowerShell extension by following the steps
in the [Visual Studio Code documentation](https://code.visualstudio.com/docs/editor/extension-gallery).
In the Extensions pane, search for "Azure PowerShell" extension and install it there.  You will
get notified automatically about any future extension updates!

In order to use the extension, you will also need to have the [Az.Tools.Migration](https://learn.microsoft.com/en-us/powershell/azure/quickstart-migrate-azurerm-to-az-automatically?view=azps-10.0.0) Powershell Module installed. Due to the way Powershell generates the PSModulePath environment variable, viewing `$env:PSModulePath` in a Powershell window may show more paths than are actually available to the extension. The module will have to be located in one of the locations in the **system level** PSModulePath. You can view the locations in the system level path with `echo %psmodulepath%` in a command prompt.

## Usage

PowerShell scripts are analyzed automatically whenever they are opened or saved. AzureRM cmdlets will be identified and marked with suggestions of how to migrate.

- Quick Fix
![quick-fix](resources/readme/quick-fix.png)

## License

This extension is [licensed under the MIT License](LICENSE.txt).
