param environment string
param resourceGroupName string
param location string
param privateEndpointSubnetId string // Subnet for Private Endpoints
param sqlmiName string
param storageAccountName string
param dnsZoneSqlMIId string
param dnsZoneStorageId string

// Private Endpoint Names
var privateEndpointNameSqlMI = '${sqlmiName}-pe'
var privateEndpointNameStorage = '${storageAccountName}-pe'

// Create Private Endpoint for SQL Managed Instance
resource sqlMiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndpointNameSqlMI
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${sqlmiName}-pls'
        properties: {
          privateLinkServiceId: resourceId('Microsoft.Sql/managedInstances', sqlmiName)
          groupIds: ['sqlManagedInstance']
        }
      }
    ]
  }
}

// Create Private Endpoint for Storage Account
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndpointNameStorage
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-pls'
        properties: {
          privateLinkServiceId: resourceId('Microsoft.Storage/storageAccounts', storageAccountName)
          groupIds: ['blob']
        }
      }
    ]
  }
}

// Associate SQL MI Private Endpoint with SQL MI Private DNS Zone
resource sqlMiPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  name: '${sqlmiName}-dns-zone-group'
  parent: sqlMiPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: dnsZoneSqlMIId
        }
      }
    ]
  }
}

// Associate Storage Private Endpoint with Storage Private DNS Zone
resource storagePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  name: '${storageAccountName}-dns-zone-group'
  parent: storagePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: dnsZoneStorageId
        }
      }
    ]
  }
}
