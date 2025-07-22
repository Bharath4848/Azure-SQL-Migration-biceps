param environment string
param resourceGroupName string
param location string

var vnetId = resourceId('Microsoft.Network/virtualNetworks', 'dbc-${environment}-app-vnet')

var dnsZoneSqlMI = 'privatelink.database.windows.net'
var dnsZoneStorage = 'privatelink.blob.core.windows.net'

// Create Private DNS Zone for SQL Managed Instance
resource privateDnsZoneSqlMI 'Microsoft.Network/privateDnsZones@2023-01-01' = {
  name: dnsZoneSqlMI
  location: 'Global'
}

// Create Private DNS Zone for Storage Account
resource privateDnsZoneStorage 'Microsoft.Network/privateDnsZones@2023-01-01' = {
  name: dnsZoneStorage
  location: 'Global'
}

// Link SQL MI DNS Zone to VNet
resource privateDnsZoneVnetLinkSqlMI 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2023-01-01' = {
  name: '${environment}-sqlmi-dns-link'
  parent: privateDnsZoneSqlMI
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

// Link Storage DNS Zone to VNet
resource privateDnsZoneVnetLinkStorage 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2023-01-01' = {
  name: '${environment}-storage-dns-link'
  parent: privateDnsZoneStorage
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

// Output DNS Zone IDs (if needed)
output sqlmiDnsZoneId string = privateDnsZoneSqlMI.id
output storageDnsZoneId string = privateDnsZoneStorage.id
