# Original source code: https://github.com/Azure/azure-docs-powershell-samples/blob/77c8876ed0d79ba5538e3e583fe03aa514ae7661/app-service/backup-restore/backup-restore.ps1
$resourceGroupName = "myResourceGroup"
$webappname = "<replace-with-your-app-name>"


# List statuses of all backups that are complete or currently executing.
Get-AzureRmWebAppBackupList -ResourceGroupName $resourceGroupName -Name $webappname

# Note the BackupID property of the backup you want to restore

# Get the backup object that you want to restore by specifying the BackupID
$backup = (Get-AzureRmWebAppBackupList -ResourceGroupName $resourceGroupName -Name $webappname | where {$_.BackupId -eq '<replace-with-BackupID>'}) 

# Restore the app by overwriting it with the backup data
$backup | Restore-AzureRmWebAppBackup -Overwrite