Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Set-ModulePreference tests' {
        It 'Can correctly disable data collection preference' {
            # arrange
            Mock -CommandName Out-File -Verifiable -MockWith { }
            Mock -CommandName Get-ModulePreferences `
                -Verifiable `
                -ModuleName Az.Tools.Migration `
                -MockWith `
            {
                return ([PSCustomObject]@{
                        DataCollectionEnabled = $true
                    })
            }

            # act
            $result = Set-ModulePreference -DataCollectionEnabled $false

            # assert
            $result | Should Not Be $null
            $result.DataCollectionEnabled | Should Be $false
        }
        It 'Can correctly enable data collection preference' {
            # arrange
            Mock -CommandName Out-File -Verifiable -MockWith { }
            Mock -CommandName Get-ModulePreferences `
                -Verifiable `
                -ModuleName Az.Tools.Migration `
                -MockWith `
            {
                return ([PSCustomObject]@{
                        DataCollectionEnabled = $false
                    })
            }

            # act
            $result = Set-ModulePreference -DataCollectionEnabled $true

            # assert
            $result | Should Not Be $null
            $result.DataCollectionEnabled | Should Be $true
        }
    }
}
