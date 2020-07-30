# Original source code: https://github.com/Azure/azure-docs-powershell-samples/tree/26f8f493b3c83d23365c2d4a1c4be90ecece1dd4/virtual-network/peer-two-virtual-networks
# Variables for common values
$rgName='MyResourceGroup'
$location='eastus'

# Create a resource group.
New-AzResourceGroup -Name $rgName -Location $location

# Create virtual network 1.
$vnet1 = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'Vnet1' -AddressPrefix '10.0.0.0/16' -Location $location

# Create virtual network 2.
$vnet2 = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'Vnet2' -AddressPrefix '10.1.0.0/16' -Location $location

# Peer VNet1 to VNet2.
Add-AzVirtualNetworkPeering -Name 'LinkVnet1ToVnet2' -VirtualNetwork $vnet1 -RemoteVirtualNetworkId $vnet2.Id

# Peer VNet2 to VNet1.
Add-AzVirtualNetworkPeering -Name 'LinkVnet2ToVnet1' -VirtualNetwork $vnet2 -RemoteVirtualNetworkId $vnet1.Id