param environment string
param resourceGroupName string
param location string
param administratorLogin string
@secure()
param administratorPassword string
param collation string
param cores int
param storageSizeGB int
param timeZoneId string
param tlsVersion string
param publicEndpointEnabled bool
param adminObjectId string
param tenantId string
param enableDefender bool
param vnetAddressSpace string
param subnetAddressSpaceSQLMI string
param subnetAddressSpacePrivateEndpoint string
param privateEndpointSubnetId string
param sqlmiName string
param storageAccountName string
param dnsZoneSqlMIId string
param dnsZoneStorageId string

module vnet './Vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    environment: environment
    resourceGroupName: resourceGroupName
    location: location
    vnetAddressSpace: vnetAddressSpace
    subnetAddressSpaceSQLMI: subnetAddressSpaceSQLMI
    subnetAddressSpacePrivateEndpoint: subnetAddressSpacePrivateEndpoint
  }
}

module dnsZones './dnsZones.bicep' = {
  name: 'dnsZonesDeployment'
  params: {
    environment: environment
    resourceGroupName: resourceGroupName
    location: location
  }
}

module sqlmi './sqlmi.bicep' = {
  name: 'sqlmiDeployment'
  params: {
    environment: environment
    location: location
    resourceGroupName: resourceGroupName
    administratorLogin: administratorLogin
    administratorPassword: administratorPassword
    collation: collation
    cores: cores
    storageSizeGB: storageSizeGB
    timeZoneId: timeZoneId
    tlsVersion: tlsVersion
    publicEndpointEnabled: publicEndpointEnabled
    adminObjectId: adminObjectId
    tenantId: tenantId
    subnetId: vnet.outputs.sqlmiSubnetId
    enableDefender: enableDefender
  }
}

module storage './storageAccount.bicep' = {
  name: 'storageDeployment'
  params: {
    environment: environment
    resourceGroupName: resourceGroupName
    location: location
  }
}

module privateEndpoints './privateEndpoints.bicep' = {
  name: 'privateEndpointsDeployment'
  params: {
    environment: environment
    resourceGroupName: resourceGroupName
    location: location
    privateEndpointSubnetId: vnet.outputs.privateEndpointSubnetId
    sqlmiName: sqlmi.outputs.sqlmiName
    storageAccountName: storage.outputs.storageAccountName
    dnsZoneSqlMIId: dnsZones.outputs.sqlmiDnsZoneId
    dnsZoneStorageId: dnsZones.outputs.storageDnsZoneId
  }
}
