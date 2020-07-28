Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Invoke-SamplesTesting tests' {
        $TestFileDirectory = "C:\Users\dcaro\Projects\azure-powershell-migration\common\code-upgrade-samples\"

        foreach ($Item in (Get-ChildITem (Join-Path $TestFileDirectory "azurerm") )) {
            Copy-Item -Path $Item.FullName -Destination "TestDrive:\${Item.name}"
        } 

        It "Can perform upgrade of compute-create-windowsvm-quick.ps1" {
            $TestFile = "compute-create-windowsvm-quick.ps1"           
            $AzureRMFilePath = Join-Path $TestDrive $TestFile
            $AzFilePath = Join-Path $TestFileDirectory "az" $TestFile

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
            $TestFile = "compute-create-wordpress-mysql.ps1"
            $AzureRMFilePath = Join-Path $TestDrive $TestFile
            $AzFilePath = Join-Path $TestFileDirectory "az" $TestFile

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
            $TestFile = "compute-create-dockerhost.ps1"
            $AzureRMFilePath = Join-Path $TestDrive $TestFile
            $AzFilePath = Join-Path $TestFileDirectory "az" $TestFile

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

