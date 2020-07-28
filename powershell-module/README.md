# Az.Tools.Migration

Az.Tools.Migration is a PowerShell module for automatically upgrading your PowerShell scripts and
script modules from AzureRM to the Az PowerShell module.

## Contents

* [Description](#description)
* [Usage Instructions](#usage-instructions)
* [Limitations](#limitations)

## Description

The Az.Tools.Migration PowerShell module contains cmdlets that perform the following actions:

1. Detect AzureRM cmdlet references in PowerShell scripts and script modules.
1. Generate an upgrade plan to convert AzureRM module references to Az module commands.
1. Execute the upgrade plan to modify your PowerShell codebase.

## Usage Instructions

### Requirements

Update your existing PowerShell codebase to the latest version of the AzureRM PowerShell module. The
Az.Tools.Migration module detects commands based on AzureRM 6.13.1.

### Step 1: Backup your code

**IMPORTANT**: This module performs an in-place upgrade of the codebase you specify. Be certain that
your target code is backed-up or checked-in to source control before proceeding.

### Step 2: Generate an upgrade plan

Generate an upgrade plan for moving the AzureRM references in your codebase to the Az PowerShell
module. This step doesn't execute the plan, it only generates the upgrade steps.

**IMPORTANT**: Review the warnings and errors in the plan results. The `Errors` collection may
contain commands or parameters that couldn't be upgraded automatically. These items require manual
intervention during the upgrade.

This step can optionally be run for a single file by specifying the `FilePath` parameter instead of the
`DirectoryPath` parameter.

```powershell
# Generate the upgrade plan.
$plan = New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.4.0 -DirectoryPath 'C:\Scripts'

# Review the list of upgrade steps.
$plan.UpgradeSteps | Format-List

# Review the plan to determine if any errors or warnings exist.
$plan.Warnings | Format-Table
$plan.Errors | Format-Table
```

### Step 3: Execute the upgrade plan

Execute the upgrade plan. This step performs an in-place upgrade of the specified codebase with the
exception of the warning and errors from the previous step.

```powershell
# Execute the upgrade plan. This step prompts for confirmation.
$result = Invoke-AzUpgradeModulePlan -Plan $plan -Verbose

# Review the results.
$result | Format-Table -Property Success, Reason, Step
```

## Limitations

* Automated parameter name updates to splatted parameter sets aren't supported. If any are found
  during upgrade plan generation, a warning is returned.
* File I/O operations use default encoding. Unusual file encoding situations may cause problems.
* AzureRM cmdlets passed as arguments to Pester unit test mock statements aren't detected.
