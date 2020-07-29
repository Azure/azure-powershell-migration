Import-Module Az.Tools.Migration -Force

InModuleScope -ModuleName Az.Tools.Migration -ScriptBlock {
    Describe 'Confirm-StringBuilderSubstring tests' {
        It 'Should not throw if the offset matches' {
            # arrange
            $scriptBuilder = New-Object -TypeName System.Text.StringBuilder
            $null = $scriptBuilder.AppendLine("Write-host 'test'")
            $null = $scriptBuilder.AppendLine("Set-AzureRmWebApp -ResourceGroupName 'Default-Web-WestUS' ``")
            $null = $scriptBuilder.AppendLine("     -Name 'ContosoWebApp' ``")
            $null = $scriptBuilder.AppendLine("     -HttpLoggingEnabled `$true")

            # act / assert
            { Confirm-StringBuilderSubstring -FileContent $scriptBuilder -Substring 'Set-AzureRmWebApp' -StartOffset 19 -EndOffset 35 } | Should Not Throw
        }
        It 'Should throw if the offset does not match' {
            # arrange
            $scriptBuilder = New-Object -TypeName System.Text.StringBuilder
            $null = $scriptBuilder.AppendLine("Write-host 'test'")
            $null = $scriptBuilder.AppendLine("Set-AzWebApp -ResourceGroupName 'Default-Web-WestUS' ``") # does not match, because it has already been upgraded.
            $null = $scriptBuilder.AppendLine("     -Name 'ContosoWebApp' ``")
            $null = $scriptBuilder.AppendLine("     -HttpLoggingEnabled `$true")

            # act / assert
            { Confirm-StringBuilderSubstring -FileContent $scriptBuilder -Substring 'Set-AzureRmWebApp' -StartOffset 19 -EndOffset 35 } | Should Throw "Upgrade step failed: Offset positions are unexpected"
        }
        It 'Should throw if the offset extends past the file contents length' {
            # arrange
            $scriptBuilder = New-Object -TypeName System.Text.StringBuilder
            $null = $scriptBuilder.AppendLine("Write-host 'test'")
            $null = $scriptBuilder.AppendLine("Set-AzWebApp -ResourceGroupName 'Default-Web-WestUS' ``")
            $null = $scriptBuilder.AppendLine("     -Name 'ContosoWebApp' ``")
            $null = $scriptBuilder.AppendLine("     -HttpLoggingEnabled `$true")

            # act / assert
            { Confirm-StringBuilderSubstring -FileContent $scriptBuilder -Substring 'Set-AzureRmWebApp' -StartOffset 1119 -EndOffset 1135 } | Should Throw "Upgrade step failed: Offset positions are beyond"
        }
    }
}
