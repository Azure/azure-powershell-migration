# Az.Tools.Migration

Az.Tools.Migration is a PowerShell module for automatically upgrading your PowerShell scripts and
script modules from AzureRM to the Az PowerShell module.

The version of Az.Tools.Migration is aligned with the targeted Az Version. For example, if you would like to migrate to `Az 11.0.0`, you should use `Az.Tools.Migration 11.0.0`.

## Contents

* [Getting started](#getting-started)
* [Description](#description)
* [Usage Instructions](#usage-instructions)
* [Limitations](#limitations)

## Description

The Az.Tools.Migration PowerShell module contains cmdlets that perform the following actions:

1. Detect AzureRM cmdlet references in PowerShell scripts and script modules.
1. Generate an upgrade plan to convert AzureRM module references to Az module commands.
1. Execute the upgrade plan to modify your PowerShell codebase.

## Getting started

You can use either method to use this module:

1. Install this module from the [PowerShell gallery](https://www.powershellgallery.com/packages/Az.Tools.Migration).

```
Install-Module -Name Az.Tools.Migration
```

2. Clone this repository and import the module locally.
Use this option if you want to make changes to the module and test it out.

```
git clone https://github.com/Azure/azure-powershell-migration.git
import-module './azure-powershell-migration/powershell-module/Az.Tools.Migration/Az.Tools.Migration.psd1'
```

## Usage Instructions

### Requirements

Update your existing PowerShell codebase to the latest version of the AzureRM PowerShell module. The
Az.Tools.Migration module detects commands based on AzureRM 6.13.1.

### Step 1: Backup your code

**IMPORTANT**: There is no undo operation. Always ensure that you have a backup copy of your PowerShell scripts
and modules that you're attempting to upgrade.

### Step 2: Generate an upgrade plan

Generate an upgrade plan for moving the AzureRM references in your codebase to the Az PowerShell
module. This step doesn't execute the plan, it only generates the upgrade steps.

**IMPORTANT**: Review the warnings and errors in the plan results. The output may
contain commands or parameters that couldn't be upgraded automatically. These items require manual
intervention during the upgrade.

This step can optionally be run for a single file by specifying the `FilePath` parameter instead of the
`DirectoryPath` parameter.

```powershell
# Generate an upgrade plan for the script and module files in the specified folder and save it to a variable.
$plan = New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion latest -DirectoryPath 'C:\Scripts'

# shows the entire upgrade plan
$plan

# filter plan result to only show warnings and errors
$plan | where PlanResult -ne ReadyToUpgrade | format-list
```

### Step 3: Execute the upgrade plan

The upgrade plan is executed when you run the `Invoke-AzUpgradeModulePlan` cmdlet. This command performs
an upgrade of the specified file or folders except for any errors that were identified by the `New-AzUpgradeModulePlan` cmdlet.

This command requires you to specify if the files should be modified in place or if new files should be saved
alongside your original files (leaving originals unmodified).

```powershell
# Execute the automatic upgrade plan and save the results to a variable.
# Specify 'ModifyExistingFiles' to the -FileEditMode parameter if you would like the files to be modified in place instead of having new files created.
$result = Invoke-AzUpgradeModulePlan -Plan $plan -FileEditMode SaveChangesToNewFiles

# shows the entire upgrade operation result
$result

# filter results to show errors
$results | where UpgradeResult -ne UpgradeCompleted | format-list
```

## Limitations

* File I/O operations use default encoding. Unusual file encoding situations may cause problems.
* AzureRM cmdlets passed as arguments to Pester unit test mock statements aren't detected.
