# Az.Tools.Migration
Az.Tools.Migration contains cmdlets to automatically upgrade a PowerShell script or module codebase from AzureRM to Az.

# Contents
* [Description](#description)
* [Usage Instructions](#usage-instructions)
* [Limitations](#limitations)

# Description
The Az.Tools.Migration PowerShell module contains cmdlets that can perform the following actions:

1. Detect AzureRM cmdlet references in PowerShell script or function files.
2. Generate an upgrade plan to convert these AzureRM module references to Az module commands.
3. Execute the upgrade plan to modify your PowerShell codebase in-place.

# Usage Instructions

## Prerequisites

If your PowerShell codebase hasn't already been updated to the latest AzureRM module (6.13.1), we recommend you do that first. This module detects commands based on this version.

## Step 1: Backup your code

**Important**: This module performs an in-place upgrade of the codebase you specify. Be certain that your target code is backed-up or checked-in to source control before starting this work.

## Step 2: Detect AzureRM references

Run this step to generate a list of all the AzureRM references in your codebase and save it to a variable.

This can optionally be run for a single file by specifying the **-FilePath** parameter instead of the **-DirectoryPath** parameter.

``` powershell
# find AzureRM references
$references = Find-AzureRmCommandReferences -DirectoryPath 'C:\source\my-project' -AzureRmModuleVersion 6.13.1

# print out the references to the console
$references.Items | Format-List
```

## Step 3: Generate an upgrade plan

Run this step to generate an upgrade plan for moving the AzureRM references in your codebase to the Az module. This does not execute the plan, it only generates the upgrade steps.

**Important**: Review the Warnings and Errors in the plan results. The Errors collection may contain commands or parameters that could not be upgraded automatically and will require manual intervention during the upgrade.

``` powershell
# generate the plan
$plan = New-AzUpgradeModulePlan -AzureRmCmdReferences $references -AzModuleVersion 4.2.0

# print out the upgrade steps to the console
$plan.UpgradeSteps | Format-List

# review the plan to see if any errors or warnings were generated
$plan.Warnings | Format-Table
$plan.Errors | Format-Table
```

## Step 4: Execute the upgrade plan

Run this step to execute all of the steps in your upgrade plan to Az.

``` powershell
# execute the upgrade plan.
# this will prompt for confirmation.
$result = Invoke-AzUpgradeModulePlan -Plan $plan -Verbose

# print the results to the console
$result | Format-Table Success, Reason, Step
```

# Limitations

* Automated parameter name updates to splatted parameter sets are not supported. If any are found during upgrade plan generation, a warning will be returned.
* File I/O operations use default encoding. Unusual file encoding situations may cause problems.
* AzureRM cmdlets passed as arguments to Pester unit test mock statements are not detected.