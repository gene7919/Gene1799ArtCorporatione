# GENE1799 Azure Deployment

## One-Click Deployment

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgene7919%2FGene1799ArtCorporatione%2Fmain%2Fazure-infrastructure-template.json)

## Quick Deploy with Custom Parameters

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgene7919%2FGene1799ArtCorporatione%2Fmain%2Fazure-infrastructure-template.json&projectName=gene1799&environment=production&location=westeurope&appServiceTier=B2&postgresqlVersion=14&databaseName=gene1799db&administratorLogin=gene1799admin)

## Manual Deployment - Azure CLI

### Prerequisites
- Azure CLI installed and configured
- An active Azure subscription
- Appropriate permissions to create resources

### Deployment Steps

```bash
# Deploy GENE1799 Infrastructure to Azure using Azure CLI

# Login to Azure
az login

# Create resource group
az group create \
  --name gene1799-rg \
  --location westeurope

# Deploy ARM template
az deployment group create \
  --resource-group gene1799-rg \
  --template-uri https://raw.githubusercontent.com/gene7919/Gene1799ArtCorporatione/main/azure-infrastructure-template.json \
  --parameters \
    projectName=gene1799 \
    environment=production \
    location=westeurope \
    appServiceTier=B2 \
    postgresqlVersion=14 \
    databaseName=gene1799db \
    administratorLogin=gene1799admin \
    administratorPassword=<SecurePassword>

# Get deployment outputs
az deployment group show \
  --resource-group gene1799-rg \
  --name azureResourcesDeployment \
  --query properties.outputs
```

## Manual Deployment - PowerShell

```powershell
# Deploy GENE1799 Infrastructure to Azure
$templateUri = "https://raw.githubusercontent.com/gene7919/Gene1799ArtCorporatione/main/azure-infrastructure-template.json"
$resourceGroup = "gene1799-rg"
$location = "westeurope"

# Create resource group
az group create \
  --name $resourceGroup \
  --location $location

# Deploy template
az deployment group create \
  --resource-group $resourceGroup \
  --template-uri $templateUri \
  --parameters @azure-parameters.json
```

## Template Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| projectName | gene1799 | Project name (used for naming resources) |
| environment | production | Environment (development/staging/production) |
| location | westeurope | Azure region |
| appServiceTier | B2 | App Service plan tier |
| postgresqlVersion | 14 | PostgreSQL server version |
| databaseName | gene1799db | PostgreSQL database name |
| administratorLogin | gene1799admin | PostgreSQL admin username |

## Resources Deployed

1. **App Service Plan** - B2 tier (2 cores, 3.5GB RAM)
2. **App Service** - Node.js 18 LTS runtime
3. **PostgreSQL Server** - Version 14, 50GB storage
4. **Blob Storage** - Hot tier, Geo-redundant (GRS)
5. **Redis Cache** - Standard tier, 1GB
6. **Application Insights** - Monitoring and diagnostics
7. **Log Analytics Workspace** - Centralized logging
8. **Auto-scaling Rules** - CPU-based (1-5 instances)

## Deployment Outputs

After deployment, you'll receive:
- App Service URL
- PostgreSQL hostname
- Redis cache hostname
- Storage account name
- Application Insights key

## Post-Deployment Configuration

### 1. Set Application Settings

```bash
az webapp config appsettings set \
  --resource-group gene1799-rg \
  --name gene1799-production-app \
  --settings \
    TELEGRAM_BOT_TOKEN=<your-token> \
    TELEGRAM_CHANNEL_ID=<your-channel> \
    DATABASE_USER=gene1799admin \
    DATABASE_PASSWORD=<your-password>
```

### 2. Deploy Application Code

```bash
# Deploy from GitHub
az webapp deployment source config \
  --resource-group gene1799-rg \
  --name gene1799-production-app \
  --repo-url https://github.com/gene7919/Gene1799ArtCorporatione \
  --branch main \
  --manual-integration
```

### 3. Configure Database

```bash
# Connect to PostgreSQL and run migrations
psql -h gene1799-production-db-server.postgres.database.azure.com \
  -U gene1799admin \
  -d gene1799db \
  -f database-schema.sql
```

## Monitoring

Monitor your deployment in Azure Portal:
- **Application Insights**: View real-time metrics and logs
- **Log Analytics**: Centralized diagnostic logging
- **Auto-scale Settings**: Monitor scaling events

## Support

For more information:
- Azure Templates: https://github.com/gene7919/Gene1799ArtCorporatione
- Documentation: https://github.com/gene7919/Gene1799ArtCorporatione/blob/main/AZURE_INTEGRATION_GUIDE.md
- Telegram: @gene1799_art_bot
