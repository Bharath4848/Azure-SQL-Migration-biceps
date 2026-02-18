param environment string
param location string = 'eastasia'
param administratorLogin string = 'sqlmiadmin'
@secure()
param administratorPassword string
param collation string = 'Latin1_General_CI_AS'
param storageSizeGB int = 16384
param timeZoneId string = 'UTC'
param tlsVersion string = '1.2'
param publicEndpointEnabled bool = false
param adminObjectId string // Microsoft Entra Admin Object ID
param tenantId string // Azure AD Tenant ID
param subnetId string // SQL Managed Instance Subnet ID (existing)
param enableDefender bool = true
skuName: skuName
skuTier: skuTier
skuFamily: skuFamily
skuCapacity: skuCapacity


var managedInstanceName = 'dbc-${environment}-app-sqlmi001'

// --------------------------
// Deploy SQL Managed Instance
// --------------------------
resource sqlManagedInstance 'Microsoft.Sql/managedInstances@2021-11-01' = {
  name: managedInstanceName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    collation: collation
    vCores: skuCapacity
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
    name: skuName
    tier: skuTier
    family: skuFamily
    capacity: skuCapacity
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// --------------------------
// Assign Microsoft Entra ID Admin
// --------------------------
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

// --------------------------
// Enable Defender for SQL
// --------------------------
resource sqlMiVulnerabilityAssessment 'Microsoft.Sql/managedInstances/securityAlertPolicies@2021-11-01' = if (enableDefender) {
  parent: sqlManagedInstance
  name: 'Default'
  properties: {
    state: 'Enabled'
  }
}

// --------------------------
// Outputs
// --------------------------
output sqlmiName string = sqlManagedInstance.name
output sqlmiId string = sqlManagedInstance.id
