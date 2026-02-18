# Azure SQL Migration with Bicep Templates

A complete infrastructure setup for migrating SQL Server to Azure SQL Managed Instance. Includes networking, security, private endpoints, and CI/CD pipeline.

---

## Why I Built This

Here's the thing - when I got tasked with migrating our SQL databases to Azure, I thought I'd just Google some Bicep templates and be done in an hour. 

Yeah, that didn't happen.

After spending days searching GitHub, Stack Overflow, and Microsoft Docs, I realized there wasn't a single complete example that showed:
- How to set up the networking properly
- Where to configure subnet delegation (spoiler: it's required and not obvious)
- How to get the NSG rules right
- How to make everything private (no public internet access)
- How to automate it with CI/CD

Most examples were either incomplete, used old ARM templates, or were just SQL MI deployment without any of the infrastructure around it.

So I built it myself, figured out all the gotchas, and decided to share it. If this saves someone else a week of headaches, it's worth it.

---

## What You Get

Here's everything included in this repo:

**Infrastructure:**
- Virtual Network with properly configured subnets
- Network Security Group with all the SQL MI rules you need
- Subnet delegation (this one's critical - SQL MI won't deploy without it)
- SQL Managed Instance with Entra ID admin and Defender enabled
- Private DNS Zones for secure name resolution
- Private Endpoints for both SQL MI and Storage (zero public access)
- Storage Account for SQL backups

**Automation:**
- Azure DevOps pipeline that handles everything
- Multi-environment support (dev and prod configs included)
- Key Vault integration for secrets

**Documentation:**
- This README (obviously)
- Comments in the code explaining the tricky parts
- Troubleshooting section based on issues I actually hit

---

## How It All Fits Together

```
Resource Group
├── Virtual Network (your main network)
│   ├── SQL MI Subnet (delegated, with NSG attached)
│   │   └── SQL Managed Instance (your database)
│   └── Private Endpoint Subnet
│       └── Private Endpoints (for SQL MI and Storage)
│
├── Private DNS Zones
│   ├── privatelink.database.windows.net (for SQL MI)
│   └── privatelink.blob.core.windows.net (for Storage)
│
└── Storage Account (for backups and stuff)
```

The deployment happens in this order:
1. VNet, NSG, and subnets get created first
2. DNS zones get set up and linked to the VNet
3. SQL Managed Instance deploys (this takes about 45 minutes)
4. Storage account gets created
5. Private endpoints connect everything together

---

## Project Structure

```
Azure-SQL-Migration-biceps/
├── bicep/
│   ├── main.bicep                      # Starts everything
│   └── modules/                        # Individual components
│       ├── Vnet.bicep                  # Network, NSG, subnets
│       ├── sqlmi.bicep                 # SQL Managed Instance
│       ├── dnsZones.bicep              # Private DNS zones
│       ├── storageAccount.bicep        # Storage for backups
│       └── privateEndpoints.bicep      # Private endpoints
├── variables/                          
│   ├── dev-config.yml                  # Dev environment settings
│   └── prd-config.yml                  # Prod environment settings
└── pipelines/                          
    └── azure-pipelines.yml             # CI/CD pipeline
```

---

## Getting Started

### What You'll Need

Before you start, make sure you have:
- An Azure subscription (obviously)
- Azure CLI installed on your machine
- Bicep CLI installed (`az bicep install`)
- A Key Vault to store the SQL admin password
- A resource group already created
- About an hour of time (SQL MI deployment is slow)

### Quick Setup

**1. Clone this repo:**
```bash
git clone https://github.com/Bharath4848/Azure-SQL-Migration-biceps.git
cd Azure-SQL-Migration-biceps
```

**2. Update the config file:**

Open `variables/dev-config.yml` and update these values:
- `subscriptionID` - Your Azure subscription ID
- `tenantId` - Your Azure AD tenant ID
- `adminObjectId` - Object ID of the person/group who'll be the SQL admin
- `resourceGroupName` - Name of your resource group
- `location` - Azure region (eastasia, westus, etc.)
- `keyVaultName` - Your Key Vault name
- Network ranges (adjust if needed):
  - `vnetAddressSpace` - Main network range (like 10.0.0.0/16)
  - `subnetAddressSpaceSQLMI` - SQL MI subnet (like 10.0.1.0/24)
  - `subnetAddressSpacePrivateEndpoint` - PE subnet (like 10.0.2.0/24)

**3. Store your SQL password in Key Vault:**
```bash
az keyvault secret set \
  --vault-name your-keyvault-name \
  --name sqlmi-admin-password \
  --value 'YourSecurePassword123!'
```

**4. Test it first (always a good idea):**
```bash
az deployment group validate \
  --resource-group your-rg-name \
  --template-file bicep/main.bicep \
  --parameters \
    environment=dev \
    location=eastasia \
    vnetAddressSpace="10.0.0.0/16" \
    subnetAddressSpaceSQLMI="10.0.1.0/24" \
    subnetAddressSpacePrivateEndpoint="10.0.2.0/24" \
    administratorPassword='YourPassword123!' \
    adminObjectId='your-admin-object-id' \
    tenantId='your-tenant-id'
```

**5. Deploy it:**
```bash
az deployment group create \
  --resource-group your-rg-name \
  --template-file bicep/main.bicep \
  --parameters \
    environment=dev \
    location=eastasia \
    vnetAddressSpace="10.0.0.0/16" \
    subnetAddressSpaceSQLMI="10.0.1.0/24" \
    subnetAddressSpacePrivateEndpoint="10.0.2.0/24" \
    administratorPassword='YourPassword123!' \
    adminObjectId='your-admin-object-id' \
    tenantId='your-tenant-id'
```

Now go grab a coffee. SQL MI deployment takes 45-60 minutes.

### Using Azure DevOps Instead

If you prefer using pipelines:

1. Import `pipelines/azure-pipelines.yml` into Azure DevOps
2. Set up a service connection to your Azure subscription
3. Update the config file with your values
4. Run the pipeline and select your environment (dev or prod)

The pipeline handles validation and deployment automatically.

---

## Important Configuration Stuff

### Subnet Delegation (Don't Skip This!)

This one tripped me up for hours. SQL Managed Instance **requires** the subnet to be delegated to the SQL MI service. If you forget this, the deployment just fails with a cryptic error.

The good news: it's already configured in the `Vnet.bicep` module. Just don't remove it.

### Network Security Group Rules

SQL MI needs specific ports open. The NSG is configured with:
- Ports 9000-9003 for Azure management
- Ports 11000-11999 for redirect connections
- Port 5022 for geo-replication

### Private DNS Zones

Two DNS zones get created:
- `privatelink.database.windows.net` - For SQL MI name resolution
- `privatelink.blob.core.windows.net` - For Storage Account

These are linked to your VNet so resources can resolve each other's private IPs.

---

## What This Costs

Rough monthly costs in East Asia region:

| What | How Much |
|------|----------|
| SQL Managed Instance (16 vCores) | ~$1,440 |
| Virtual Network | Free |
| Private DNS Zones | ~$1 |
| Private Endpoints | ~$14 |
| Storage Account (1 TB) | ~$20 |
| **Total** | **~$1,475/month** |

Obviously this varies by region and how much storage you use. Use the Azure pricing calculator for exact numbers.

The big cost is SQL MI. If you don't need 16 vCores, you can go smaller and save money.

---

## Customizing It

### Change SQL MI Size

Edit `bicep/modules/sqlmi.bicep` and change these:
```bicep
param cores int = 16                    # vCores (4, 8, 16, 24, 32...)
param storageSizeGB int = 16384        # Storage size
```

### Use Different Network Ranges

Update `variables/dev-config.yml`:
```yaml
vnetAddressSpace: '10.0.0.0/16'                    # Your network
subnetAddressSpaceSQLMI: '10.0.1.0/24'            # SQL MI subnet
subnetAddressSpacePrivateEndpoint: '10.0.2.0/24'  # PE subnet
```

Make sure these don't overlap with your existing networks.

### Change Resource Names

Resources get named like this:
- VNet: `dbc-dev-app-vnet`
- SQL MI: `dbc-dev-app-sqlmi001`
- NSG: `dbc-dev-app-sqlmi-nsg`

If you want different names, you'll need to edit the modules. Look for the `name:` properties.

---

## Troubleshooting

### "Subnet delegation required" Error

**What happened:** Subnet doesn't have delegation configured.

**Fix:** Make sure you're using the `Vnet.bicep` from this repo. It has the delegation already set up.

### "Cannot modify subnet" Error

**What happened:** Trying to change the subnet while SQL MI is deploying.

**Fix:** The NSG needs to be attached before SQL MI starts. This is handled in the Vnet module, but if you modified it, double-check the order.

### DNS Zones Can't Find VNet

**What happened:** Missing parameter in main.bicep.

**Fix:** In `main.bicep`, make sure the dnsZones module has this line:
```bicep
vnetId: vnet.outputs.vnetId
```

### Pipeline Fails with Parameter Errors

**What happened:** Pipeline parameters don't match what main.bicep expects.

**Fix:** Check that your pipeline passes all required parameters: environment, location, network ranges, password, adminObjectId, and tenantId.

### Deployment is Taking Forever

**What happened:** Nothing, this is normal.

**Reality check:** SQL MI deployment takes 45-60 minutes. Grab lunch, it'll be done when you get back.

---

## Security Features

Everything runs privately by default:
- SQL MI only has a private IP (no public internet access)
- Storage Account is accessible only through private endpoint
- All traffic stays within the VNet
- TLS 1.2 is enforced everywhere
- Microsoft Defender is enabled on SQL MI
- Entra ID (Azure AD) authentication is configured
- Secrets are in Key Vault, not in code

---

## Contributing

Found a bug? Want to add something? Here's how:

1. Fork this repo
2. Make your changes in a new branch
3. Test it (please actually test it)
4. Submit a pull request

Some guidelines:
- Don't commit secrets or passwords
- Test in a dev environment first
- Keep the code clean and commented
- One feature per PR

---

## What's in the Modules

**Vnet.bicep** - Sets up the network
- Creates the VNet
- Creates and configures the NSG
- Creates two subnets (one for SQL MI with delegation, one for private endpoints)

**sqlmi.bicep** - Deploys SQL Managed Instance
- Creates the SQL MI instance
- Sets up Entra ID admin
- Enables Microsoft Defender

**dnsZones.bicep** - DNS setup
- Creates private DNS zones
- Links them to the VNet

**storageAccount.bicep** - Storage for backups
- Creates a storage account
- Configures for private access only

**privateEndpoints.bicep** - Connects everything
- Creates private endpoints for SQL MI and Storage
- Links them to the DNS zones

---

## Additional Resources

If you want to learn more:
- [SQL Managed Instance docs](https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/)
- [Bicep language docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Private Link documentation](https://docs.microsoft.com/en-us/azure/private-link/)

---

## Support

Running into issues? Here's what you can do:
- Check the troubleshooting section above
- Open an issue on GitHub
- Check if someone else had the same problem in the Issues tab

I'll try to help when I can, but I'm doing this in my spare time.

---

## Current Status

What's working:
- ✅ Complete infrastructure deployment
- ✅ Private networking setup
- ✅ CI/CD pipeline
- ✅ Multi-environment support

What's planned:
- Monitoring and alerting setup
- Multi-region deployment support
- Automated backup configuration
- Performance tuning guide

---

## A Few Things to Note

**This is production-tested code.** I'm using this for actual SQL migrations, not just as a demo project.

**It's not perfect.** There's always room for improvement. If you have suggestions, let me know.

**The naming convention is specific.** Resources are named like `dbc-{env}-app-{resource}`. You can change this, but you'll need to update the modules.

**SQL MI is expensive.** Make sure you understand the costs before deploying. You can use smaller sizes for dev/test.

**Deployment is slow.** SQL MI just takes a long time to deploy. There's no way around it. Plan accordingly.

---

## Why Share This?

Because I spent way too much time figuring this out, and maybe I can save someone else the trouble.

If this helps you, that's awesome. If you find bugs or have improvements, even better - send a PR.

And if you're using this for something cool, let me know. Always curious to see what people are building.

---

**Star the repo if you found it useful!**

Questions? Open an issue or start a discussion.

---

**Built by someone who just wanted SQL MI to work, not to become an expert in Bicep. But here we are.**

🚀
