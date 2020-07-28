Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Invoke-SamplesTesting tests' {
        $TestFileDirectory = "C:\Users\dcaro\Projects\azure-powershell-migration\common\code-upgrade-samples\"

        foreach ($Item in (Get-ChildITem $TestFileDirectory)) {
            Copy-Item -Path $Item.FullName -Destination "TestDrive:\${Item.name}"
        } 

        It "Can perform upgrade of compute-create-windowsvm-quick.ps1" {
            $AzureRMFile = "compute-create-windowsvm-quick.ps1"
            $AzFile = "compute-create-windowsvm-quick-az.ps1"            
            $AzureRMFilePath = Join-Path $TestDrive $AzureRMFile
            $AzFilePath = Join-Path $TestFileDirectory $AzFile

            $Plan = New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.4.0 -FilePath $AzureRMFilePath
            Invoke-AzUpgradeModulePlan -Plan $Plan

            # act 
            $Results = Get-Content -Path $AzureRMFilePath
            Write-Debug "Converted file content `n $Results"
            $ExpectedResults = Get-Content -Path $AzFilePath
            Write-Debug "Expected results `n $ExpectedResults"
            
            $Delta = Compare-Object $Results $ExpectedResults

            # assertions
            $Results | Should Not Be $null
            $Delta | Should Be $null
        }

        It "Can perform upgrade of compute-create-wordpress-mysql.ps1" { 
            $AzureRMFile = "compute-create-wordpress-mysql.ps1"
            $AzFile = "compute-create-wordpress-mysql-az.ps1"            
            $AzureRMFilePath = Join-Path $TestDrive $AzureRMFile
            $AzFilePath = Join-Path $TestFileDirectory $AzFile

            $Plan = New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.4.0 -FilePath $AzureRMFilePath
            Invoke-AzUpgradeModulePlan -Plan $Plan

            # act 
            $Results = Get-Content -Path $AzureRMFilePath
            Write-Debug "Converted file content `n $Results"
            $ExpectedResults = Get-Content -Path $AzFilePath
            Write-Debug "Expected results `n $ExpectedResults"
            
            $Delta = Compare-Object $Results $ExpectedResults

            # assertions
            $Results | Should Not Be $null
            $Delta | Should Be $null
        }


        It "Can perform upgrade of compute-create-dockerhost.ps1" { 
            $AzureRMFile = "compute-create-dockerhost.ps1"
            $AzFile = "compute-create-dockerhost-az.ps1"            
            $AzureRMFilePath = Join-Path $TestDrive $AzureRMFile
            $AzFilePath = Join-Path $TestFileDirectory $AzFile

            $Plan = New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.4.0 -FilePath $AzureRMFilePath
            Invoke-AzUpgradeModulePlan -Plan $Plan

            # act 
            $Results = Get-Content -Path $AzureRMFilePath
            Write-Debug "Converted file content `n $Results"
            $ExpectedResults = Get-Content -Path $AzFilePath
            Write-Debug "Expected results `n $ExpectedResults"
            
            $Delta = Compare-Object $Results $ExpectedResults

            # assertions
            $Results | Should Not Be $null
            $Delta | Should Be $null
        }


    }
}

