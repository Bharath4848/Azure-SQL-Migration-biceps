param environment string
param location string = 'westeurope'
param resourceGroupName string
param administratorLogin string = 'sqlmiadmin'
@secure()
param administratorPassword string
param collation string = 'Latin1_General_CI_AS'
param cores int = 16
param storageSizeGB int = 16384
param timeZoneId string = 'UTC+1'
param tlsVersion string = '1.2'
param publicEndpointEnabled bool = false
param adminObjectId string // Microsoft Entra Admin Object ID
param tenantId string // Azure AD Tenant ID
param subnetId string // SQL Managed Instance Subnet ID
param enableDefender bool = true

var managedInstanceName = 'dbc-${environment}-app-SQLMI001'
var vnetName = 'dbc-${environment}-app-Vnet'
var subnetName = 'dbc-${environment}-app-SubNet'

// Deploy SQL Managed Instance
resource sqlManagedInstance 'Microsoft.Sql/managedInstances@2021-11-01' = {
  name: managedInstanceName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    collation: collation
    vCores: cores
    storageSizeInGB: storageSizeGB
    timezoneId: timeZoneId
    minimalTlsVersion: tlsVersion
    publicDataEndpointEnabled: publicEndpointEnabled
    zoneRedundant: false
    proxyOverride: 'Redirect'
    subnetId: subnetId
    licenseType: 'LicenseIncluded'
    requestedBackupStorageRedundancy: 'Local'
  }
  sku: {
    name: 'GP_PremiumSeries'
    tier: 'GeneralPurpose'
    family: 'PremiumSeries'
  }
  identity: {
    type: 'SystemAssigned'
  }
} 

// Assign Microsoft Entra ID Admin
resource sqlEntraAdmin 'Microsoft.Sql/managedInstances/administrators@2021-11-01' = {
  parent: sqlManagedInstance
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: 'DatabaseAdmin'
    sid: adminObjectId
    tenantId: tenantId
  }
}

// Enable Defender for SQL
resource sqlMiVulnerabilityAssessment 'Microsoft.Sql/managedInstances/securityAlertPolicies@2021-11-01' = if (enableDefender) {
  parent: sqlManagedInstance
  name: 'Default'
  properties: {
    state: 'Enabled' // Enables Defender for this specific SQL Managed Instance
  }
}
  

// Create NSG for SQL MI (Allow ports 11000-11999)
resource sqlMiNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: '${managedInstanceName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_SQL_MI_Redirect'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [ '11000-11999' ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Fetch the existing Virtual Network
resource existingVnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

// Associate NSG with the SQL MI Subnet
resource sqlMiSubnetNsgAssociation 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: subnetName
  parent: existingVnet
  properties: {
    networkSecurityGroup: {
      id: sqlMiNsg.id
    }
  }
}

// Output the storage account name and ID
output sqlmiName string = sqlManagedInstance.name
output sqlmiId string = sqlManagedInstance.id
