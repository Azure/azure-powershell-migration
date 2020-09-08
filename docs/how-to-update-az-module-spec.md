# How to Update Az Module Spec

The Az module command and alias specifications are stored in `powershell-module\Az.Tools.Migration\Resources\ModuleSpecs\Az\{version}`.

Occasionally these should be updated to latest. This document describes how to update the spec to latest.

## Requirements

* You have PowerShell Core 7.x or later installed on your system.
* You have installed the `Az.Tools.Migration` module and it is available in your PSModulePath.
* You have cloned this Git repository to your local computer.

## Update Instructions

1. Open a PowerShell Core (7.x or later) prompt.

2. Install the desired target version of Az to your local user scope. For example, this would install it for v4.6.1.

    ```powershell
    Install-Module -Name Az -RequiredVersion 4.6.1 -Scope CurrentUser -AllowClobber -SkipPublisherCheck -Force
    ```

3. Import the Az.Tools.Migration module.

    ```powershell
    Import-Module Az.Tools.Migration
    ```

4. Run the module spec generation script for the desired version.

    * Update the module repo path to where you have cloned the repository.
    * Ensure the Az module version variable is also set correctly to the desired version.

    ```powershell
    # setup
    $moduleRepo = "C:\source\azure-powershell-migration"
    $azModuleVersion = "4.6.1"
    $outputDirectory = Join-Path -Path $moduleRepo -ChildPath "powershell-module\Az.Tools.Migration\Resources\ModuleSpecs\Az\$azModuleVersion"

    # execute
    . $moduleRepo\powershell-module\Scripts\New-AzCmdletSpec.ps1 -AzVersion $azModuleVersion -OutputDirectory $outputDirectory
    ```

5. Update the Az version listed in documentation, function help, function parameter validation, and unit tests. The easiest way to do this is to do a search and replace on the old version. For example search for '4.4.0' and replace with '4.6.1'.

6. Remove the old module spec files from module resources: `powershell-module\Az.Tools.Migration\Resources\ModuleSpecs\Az\{old-version}`

7. Run the unit tests to make sure all of the unit tests still pass. Usually a couple of tests will fail because the expected number of aliases or cmdlets from the specs has changed.

8. Submit a pull request to commit the new changes.