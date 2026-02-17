param environment string
param location string
param vnetAddressSpace string
param subnetAddressSpaceSQLMI string
param subnetAddressSpacePrivateEndpoint string

resource sqlMiNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'dbc-${environment}-app-sqlmi-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow_management_inbound'
        properties: {
          priority: 106
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9000-9003'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow_redirect_inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '11000-11999'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'dbc-${environment}-app-Vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressSpace]
    }
  }
}

resource sqlmiSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  parent: vnet
  name: 'dbc-${environment}-app-SQLM1001-SubNet'
  properties: {
    addressPrefix: subnetAddressSpaceSQLMI
    networkSecurityGroup: {
      id: sqlMiNsg.id
    }
    delegations: [
      {
        name: 'sqlMiDelegation'
        properties: {
          serviceName: 'Microsoft.Sql/managedInstances'
        }
      }
    ]
  }
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  parent: vnet
  name: 'dbc-${environment}-app-PrivateEndpoint-SubNet'
  properties: {
    addressPrefix: subnetAddressSpacePrivateEndpoint
    privateEndpointNetworkPolicies: 'Disabled'
  }
  dependsOn: [
    sqlmiSubnet
  ]
}

output sqlmiSubnetId string = sqlmiSubnet.id
output privateEndpointSubnetId string = privateEndpointSubnet.id
output vnetId string = vnet.id
