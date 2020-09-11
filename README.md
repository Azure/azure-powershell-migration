# AzureRM to Az Migration

Effortlessly migrate your PowerShell scripts from AzureRM to the [Az PowerShell module](https://docs.microsoft.com/powershell/azure/install-az-ps).

This repository includes a PowerShell module and a VSCode extension to automate the migration of
your PowerShell scripts and modules from AzureRM to the Az PowerShell module.

## Repository Structure

* common
  * Resources shared by the PowerShell module and the VSCode extension.
  * Script samples used for testing purposes.

* docs
  * Quick starts and additional documentation.

* powershell-module
  * Code for the Az.Tools.Migration PowerShell module.

* vscode-extension
  * Code for the VSCode extension.

The current version of the migration toolkit is aimed at AzureRM to Az migration. We are
considering adding the additional capability to migrate between Az versions.

## Feedback

We welcome issues and PRs. Feel free to open issues for suggestions of new features.

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, see the
[Contributor License Agreement](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a
CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You only need to do this once across all repos using Microsoft's CLA.

## Code of Conduct

This project has adopted the
[Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more
information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or
comments.
