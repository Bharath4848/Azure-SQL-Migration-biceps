targetScope = 'resourceGroup'

param environment string
param location string

@secure()
param administratorPassword string          // from Key Vault

param adminObjectId string                  // from config file
param tenantId string                       // from config file

param vnetAddressSpace string               // from config file
param subnetAddressSpaceSQLMI string        // from config file
param subnetAddressSpacePrivateEndpoint string

// Deploy VNet & Subnets
module vnet './modules/Vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    environment: environment
    location: location
    vnetAddressSpace: vnetAddressSpace
    subnetAddressSpaceSQLMI: subnetAddressSpaceSQLMI
    subnetAddressSpacePrivateEndpoint: subnetAddressSpacePrivateEndpoint
  }
}

// DNS Zones
module dnsZones './modules/dnsZones.bicep' = {
  name: 'dnsZonesDeployment'
  params: {
    environment: environment
    vnetId: vnet.outputs.vnetId
  }
  dependsOn: [
    vnet
  ]
}

// SQL Managed Instance
module sqlmi './modules/sqlmi.bicep' = {
  name: 'sqlmiDeployment'
  params: {
    environment: environment
    location: location
    // Provided by pipeline
    administratorPassword: administratorPassword
    adminObjectId: adminObjectId
    tenantId: tenantId

    // Subnet from VNet module output
    subnetId: vnet.outputs.sqlmiSubnetId
  }
  dependsOn: [
    vnet
    dnsZones
  ]
}

// Storage Account
module storage './modules/storageAccount.bicep' = {
  name: 'storageDeployment'
  params: {
    environment: environment
    location: location
  }
  dependsOn: [
    dnsZones
  ]
}

// Private Endpoints + DNS Zone Linking
module privateEndpoints './modules/privateEndpoints.bicep' = {
  name: 'privateEndpointsDeployment'
  params: {
    location: location

    privateEndpointSubnetId: vnet.outputs.privateEndpointSubnetId
    sqlmiName: sqlmi.outputs.sqlmiName
    storageAccountName: storage.outputs.storageAccountName
    dnsZoneSqlMIId: dnsZones.outputs.sqlmiDnsZoneId
    dnsZoneStorageId: dnsZones.outputs.storageDnsZoneId
  }
  dependsOn: [
    sqlmi
    storage
    dnsZones
  ]
}
