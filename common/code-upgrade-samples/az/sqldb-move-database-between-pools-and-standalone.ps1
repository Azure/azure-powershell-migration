# Original source code: https://github.com/Azure/azure-docs-powershell-samples/blob/5513f8ea73e2b9630311d7ea27372cddc4e65cae/sql-database/move-database-between-pools-and-standalone/move-database-between-pools-and-standalone.ps1
# Set the resource group name and location for your server
$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "southcentralus"
# Set elastic pool names
$firstPoolName = "MyFirstPool"
$secondPoolName = "MySecondPool"
# Set an admin login and password for your server
$adminlogin = "ServerAdmin"
$password = "<EnterYourComplexPasswordHere>"
# The logical server name has to be unique in the system
$serverName = "server-$(Get-Random)"
# The sample database names
$firstDatabaseName = "myFirstSampleDatabase"
$secondDatabaseName = "mySecondSampleDatabase"
# The ip address range that you want to allow to access your server
$startIp = "0.0.0.0"
$endIp = "0.0.0.0"

# Create a new resource group
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a new server with a system wide unique server name
$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp

# Create two elastic database pools
$firstPool = New-AzSqlElasticPool -ResourceGroupName $resourceGroupName `
    -ServerName $servername `
    -ElasticPoolName $firstPoolName `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 20
$secondPool = New-AzSqlElasticPool -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -ElasticPoolName $secondPoolName `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50

# Create two blank databases in the first pool
$firstDatabase = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $firstDatabaseName `
    -ElasticPoolName $firstPoolName
$secondDatabase = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $secondDatabaseName `
    -ElasticPoolName $secondPoolName

# Move the database to the second pool
$firstDatabase = Set-AzSqlDatabase -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $firstDatabaseName `
    -ElasticPoolName $secondPoolName

# Move the database into a standalone performance level
$firstDatabase = Set-AzSqlDatabase -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $firstDatabaseName `
    -RequestedServiceObjectiveName "S0"