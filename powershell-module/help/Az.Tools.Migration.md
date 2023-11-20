---
Module Name: Az.Tools.Migration
Module Guid: cb471070-37cc-4484-9665-adf1502b4e3a
Download Help Link: https://learn.microsoft.com/powershell/module/az.tools.migration
Help Version: 1.0.1.0
Locale: en-US
---

# Az.Tools.Migration Module
## Description
Az.Tools.Migration is a PowerShell module for automatically upgrading your PowerShell scripts and
script modules from AzureRM to the Az PowerShell module.

The major version of Az.Tools.Migration is aligned with the targeted Az Version. For example, if you would like to migrate to `Az 11.0.0`, you should use `Az.Tools.Migration 11.x.x`.

The Az.Tools.Migration PowerShell module contains cmdlets that perform the following actions:

1. Detect AzureRM cmdlet references in PowerShell scripts and script modules.
1. Generate an upgrade plan to convert AzureRM module references to Az module commands.
1. Execute the upgrade plan to modify your PowerShell codebase.

## Az.Tools.Migration Cmdlets
### [Disable-AzUpgradeDataCollection](Disable-AzUpgradeDataCollection.md)
Disables the setting that allows Az.Tools.Migration to send usage metrics to Microsoft.

### [Enable-AzUpgradeDataCollection](Enable-AzUpgradeDataCollection.md)
Enables the setting that allows Az.Tools.Migration to send usage metrics to Microsoft.

### [Find-AzUpgradeCommandReference](Find-AzUpgradeCommandReference.md)
Searches for AzureRM PowerShell command references in the specified file or folder.

### [Get-AzUpgradeAliasSpec](Get-AzUpgradeAliasSpec.md)
Returns a dictionary containing cmdlet alias mappings for the specified Az module version.

### [Get-AzUpgradeCmdletSpec](Get-AzUpgradeCmdletSpec.md)
Returns a dictionary containing cmdlet specification objects for the specified module.

### [Get-AzUpgradeCmdletSpec](Get-AzUpgradeCmdletSpec.md)
Returns a dictionary containing cmdlet specification objects for the specified module.

### [Get-AzUpgradeCmdletSpec](Get-AzUpgradeCmdletSpec.md)
Returns a dictionary containing cmdlet specification objects for the specified module.

