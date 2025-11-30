param environment string

var vnetId = resourceId('Microsoft.Network/virtualNetworks', 'dbc-${environment}-app-Vnet')
var dnsZoneSqlMI = 'privatelink.database.windows.net'
var dnsZoneStorage = 'privatelink.blob.core.windows.net'

// Create Private DNS Zone for SQL Managed Instance
resource privateDnsZoneSqlMI 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: dnsZoneSqlMI
  location: 'global'
}

// Create Private DNS Zone for Storage Account
resource privateDnsZoneStorage 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: dnsZoneStorage
  location: 'global'
}

// Link SQL MI DNS Zone to VNet
resource privateDnsZoneVnetLinkSqlMI 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: '${environment}-sqlmi-dns-link'
  parent: privateDnsZoneSqlMI
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

// Link Storage DNS Zone to VNet
resource privateDnsZoneVnetLinkStorage 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: '${environment}-storage-dns-link'
  parent: privateDnsZoneStorage
  location: 'global'
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
