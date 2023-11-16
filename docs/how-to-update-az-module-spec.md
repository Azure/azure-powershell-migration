# How to Update Az Module Spec

The Az PowerShell module command and alias specifications are stored in
`powershell-module\Az.Tools.Migration\Resources\ModuleSpecs\Az\{version}`.

Occasionally, these should be updated to latest. This document describes how to update the spec to latest.

## Requirements

Have the following installed on your system:

* PowerShell 7.x or later.
* Pester 4.10.1 (5.* cannot work due to breaking change)
* Cloned the [azure-powershell-migration](https://github.com/Azure/azure-powershell-migration)
  GitHub repository to your local computer.

## Update Instructions

1. Open a PowerShell 7.x or later prompt.

1. Install the desired target version of the Az PowerShell module to your local computer, specifying
   the `CurrentUser` scope. For example, the following installs v4.6.1 in the current user's scope.

   ```powershell
   Install-Module -Name Az -RequiredVersion 4.6.1 -Repository PSGallery -Scope CurrentUser -AllowClobber -Force
   ```

1. Go the root folder of cloned Github repository

1. Add module path into `$env:PSModulePath`
   ```powershell
   $env:PSModulePath += ';'+ (Join-Path -Path (Get-Location) -ChildPath 'powershell-module')
   ```

1. Import the Az.Tools.Migration PowerShell module.

   ```powershell
   Import-Module -Name Az.Tools.Migration
   ```

1. Run the module spec generation script for the desired version.

   * Update the module repo path to the file system location where you cloned the repository.
   * Ensure the Az PowerShell module version variable is set to the desired version.

   ```powershell
   # setup
   $azModuleVersion = '5.6.0'

   # execute
   .\powershell-module\Scripts\New-AzCmdletSpec.ps1 -AzVersion $azModuleVersion
   ```

1. Remove the old module spec files from module resources:
   `powershell-module\Az.Tools.Migration\Resources\ModuleSpecs\Az\Latest\{old-version}`.

1. Run the unit tests to make sure all unit tests pass.

   It's common for some tests to fail because the expected number of aliases or cmdlets from the specs has changed. If so, please update the `$expectedAliasCount`/`$expectedCommandCount` in test files.

   Restart PowerShell Process and navigate to the root folder of cloned Github repository
   ```powershell
   <# Add the path of parent folder of module to environment variable #>
   $env:PSModulePath += ';'+ (Join-Path -Path (Get-Location) -ChildPath 'powershell-module')

   <# Go to the root folder of module #>
   cd powershell-module\Az.Tools.Migration

   Invoke-Pester
   ```

   Restart PowerShell if test is changed and module needs to be imported again.

1. Add new version and release notes to `powershell-module/ChangeLog.md` and `powershell-module/Az.Tools.Migration/Az.Tools.Migration.psd1`.

   *Note: The major version of Az.Tools.Migration should be the major version of targeted Az Version. *

1. Submit a pull request to commit the new changes.
