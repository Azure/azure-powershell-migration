<#

.SYNOPSIS
    Create nuget packages for module.

.PARAMETER ApiKey
    ApiKey used to publish nuget to PS repository.

.PARAMETER RepositoryLocation
    Location we want to publish too.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryLocation
)
try {
    $tempRepoName = ([System.Guid]::NewGuid()).ToString()
    Register-PSRepository -Name $tempRepoName -SourceLocation $RepositoryLocation -PublishLocation $RepositoryLocation -InstallationPolicy Trusted -PackageManagementProvider NuGet
    $modulePath = Join-Path $RepositoryLocation Az.Tools.Migration -Resolve
    Publish-Module -Path $modulePath -Repository $tempRepoName -Force
} catch {
    $Errors = $_
    Write-Error ($_ | Out-String)
} finally {
    Unregister-PSRepository -Name $tempRepoName
}


