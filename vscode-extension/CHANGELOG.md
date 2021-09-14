# Azure PowerShell Extension Release History

## 0.3.0
Add new features:
- Detect alias cmdlets or parameters, then you can quick-fix it to formal name
- Detect upcoming breaking change cmdlets or paramters and give some message about the change

## 0.2.0

Code refactoring and user experience optimization:
- Adjusted product architecture - let extension communicate to Az.Tools.Migration directly
- Displayed the diagnostic with migration information automatically when open a Powershell file
- Made extension more lightweight and use fewer resources

## 0.1.0

First preview release with the following features:
- AzureRM commands highlighting
- Quick Fix for compatible AzureRM cmdlets
