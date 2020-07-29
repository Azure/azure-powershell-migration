Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Invoke-SamplesTesting tests' {
        $TestFileDirectory = Resolve-Path -Path "..\..\common\code-upgrade-samples\"

        foreach ($TestFile in (Get-ChildITem (Join-Path $TestFileDirectory "azurerm") )) {
            Copy-Item -Path $TestFile.FullName -Destination "TestDrive:\$($TestFile.name)"
            Write-Debug "File being tested = $($TestFile.Name)"

            It "Can perform upgrade of $($TestFile.Name)" {         
                $AzureRMFilePath = Join-Path $TestDrive $TestFile.Name
                $AzFilePath = Join-Path $TestFileDirectory "az" $TestFile.Name

                $Plan = New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.4.0 -FilePath $AzureRMFilePath
                Invoke-AzUpgradeModulePlan -Plan $Plan -Confirm:$false

                # act 
                $Results = Get-Content -Path $AzureRMFilePath
                Write-Debug "Converted file content `n $Results `n"
                $ExpectedResults = Get-Content -Path $AzFilePath
                Write-Debug "Expected results `n $ExpectedResults `n"                
                $Delta = Compare-Object $Results $ExpectedResults

                # assertions
                $Results | Should Not Be $null
                $Delta | Should Be $null
            }
        }
    }
}

