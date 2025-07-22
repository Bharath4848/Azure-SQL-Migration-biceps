param environment string
param resourceGroupName string
param location string
param vnetAddressSpace string
param subnetAddressSpaceSQLMI string
param subnetAddressSpacePrivateEndpoint string

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'dbc-${environment}-app-Vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressSpace]
    }
    subnets: [
      {
        name: 'dbc-${environment}-app-SQLM1001-SubNet'
        properties: {
          addressPrefix: subnetAddressSpaceSQLMI
        }
      }
      {
        name: 'dbc-${environment}-app-PrivateEndpoint-SubNet'
        properties: {
          addressPrefix: subnetAddressSpacePrivateEndpoint
        }
      }
    ]
  }
}

// Output subnet IDs
output sqlmiSubnetId string = vnet.properties.subnets[0].id
output privateEndpointSubnetId string = vnet.properties.subnets[1].id
