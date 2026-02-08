#!/usr/bin/env node

/**
 * GENE1799 Azure One-Click Deployment Generator
 * Generates URLs for Azure Portal one-click deployment
 */

const fs = require('fs');
const path = require('path');

const AzureDeploymentGenerator = {
  // Base Azure Portal Template Deployments URL
  baseUrl: 'https://portal.azure.com/#create/Microsoft.Template/uri/',

  // Repository containing the ARM template
  repositoryUrl: 'https://raw.githubusercontent.com/gene7919/Gene1799ArtCorporatione/main/',

  /**
   * Generate one-click deployment URL
   */
  generateDeploymentUrl() {
    const templateUri = `${this.repositoryUrl}azure-infrastructure-template.json`;
    const encodedUri = encodeURIComponent(templateUri);
    return `${this.baseUrl}${encodedUri}`;
  },

  /**
   * Generate deployment URL with custom parameters
   */
  generateCustomUrl(params = {}) {
    const defaults = {
      projectName: 'gene1799',
      environment: 'production',
      location: 'westeurope',
      appServiceTier: 'B2',
      postgresqlVersion: '14',
      databaseName: 'gene1799db',
      administratorLogin: 'gene1799admin'
    };

    const merged = { ...defaults, ...params };
    const templateUri = `${this.repositoryUrl}azure-infrastructure-template.json`;
    const encodedUri = encodeURIComponent(templateUri);

    // Build parameter string
    let paramString = '';
    for (const [key, value] of Object.entries(merged)) {
      if (key !== 'administratorPassword') {
        paramString += `&${key}=${encodeURIComponent(value)}`;
      }
    }

    return `${this.baseUrl}${encodedUri}${paramString}`;
  },

  /**
   * Generate markdown deployment button
   */
  generateDeployButton(customParams = null) {
    const url = customParams
      ? this.generateCustomUrl(customParams)
      : this.generateDeploymentUrl();

    return `[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](${url})`;
  },

  /**
   * Generate HTML deployment button
   */
  generateHTMLButton(customParams = null) {
    const url = customParams
      ? this.generateCustomUrl(customParams)
      : this.generateDeploymentUrl();

    return `<a href="${url}" target="_blank">
  <img src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure"/>
</a>`;
  },

  /**
   * Generate PowerShell deployment command
   */
  generatePowerShellCommand(resourceGroup, location = 'westeurope') {
    return `# Deploy GENE1799 Infrastructure to Azure
$templateUri = "${this.repositoryUrl}azure-infrastructure-template.json"
$resourceGroup = "${resourceGroup}"
$location = "${location}"

# Create resource group
az group create \\
  --name $resourceGroup \\
  --location $location

# Deploy template
az deployment group create \\
  --resource-group $resourceGroup \\
  --template-uri $templateUri \\
  --parameters @azure-parameters.json`;
  },

  /**
   * Generate Azure CLI deployment command
   */
  generateCLICommand(resourceGroup, location = 'westeurope') {
    return `# Deploy GENE1799 Infrastructure to Azure using Azure CLI

# Login to Azure
az login

# Create resource group
az group create \\
  --name ${resourceGroup} \\
  --location ${location}

# Deploy ARM template
az deployment group create \\
  --resource-group ${resourceGroup} \\
  --template-uri ${this.repositoryUrl}azure-infrastructure-template.json \\
  --parameters \\
    projectName=gene1799 \\
    environment=production \\
    location=${location} \\
    appServiceTier=B2 \\
    postgresqlVersion=14 \\
    databaseName=gene1799db \\
    administratorLogin=gene1799admin \\
    administratorPassword=<SecurePassword>

# Get deployment outputs
az deployment group show \\
  --resource-group ${resourceGroup} \\
  --name azureResourcesDeployment \\
  --query properties.outputs`;
  },

  /**
   * Generate complete deployment documentation
   */
  generateDocumentation() {
    const markdown = `# GENE1799 Azure Deployment

## One-Click Deployment

${this.generateDeployButton()}

## Quick Deploy with Custom Parameters

${this.generateDeployButton({
  projectName: 'gene1799',
  environment: 'production',
  location: 'westeurope'
})}

## Manual Deployment - Azure CLI

### Prerequisites
- Azure CLI installed and configured
- An active Azure subscription
- Appropriate permissions to create resources

### Deployment Steps

\`\`\`bash
${this.generateCLICommand('gene1799-rg', 'westeurope')}
\`\`\`

## Manual Deployment - PowerShell

\`\`\`powershell
${this.generatePowerShellCommand('gene1799-rg', 'westeurope')}
\`\`\`

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

\`\`\`bash
az webapp config appsettings set \\
  --resource-group gene1799-rg \\
  --name gene1799-production-app \\
  --settings \\
    TELEGRAM_BOT_TOKEN=<your-token> \\
    TELEGRAM_CHANNEL_ID=<your-channel> \\
    DATABASE_USER=gene1799admin \\
    DATABASE_PASSWORD=<your-password>
\`\`\`

### 2. Deploy Application Code

\`\`\`bash
# Deploy from GitHub
az webapp deployment source config \\
  --resource-group gene1799-rg \\
  --name gene1799-production-app \\
  --repo-url https://github.com/gene7919/Gene1799ArtCorporatione \\
  --branch main \\
  --manual-integration
\`\`\`

### 3. Configure Database

\`\`\`bash
# Connect to PostgreSQL and run migrations
psql -h gene1799-production-db-server.postgres.database.azure.com \\
  -U gene1799admin \\
  -d gene1799db \\
  -f database-schema.sql
\`\`\`

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
`;
    return markdown;
  }
};

// Main execution
if (require.main === module) {
  console.log('🚀 GENE1799 Azure Deployment URL Generator\n');

  // Generate one-click deployment URL
  const deploymentUrl = AzureDeploymentGenerator.generateDeploymentUrl();
  console.log('📍 One-Click Deployment URL:');
  console.log(deploymentUrl);
  console.log('\n');

  // Generate deployment button
  console.log('📌 Markdown Deployment Button:');
  console.log(AzureDeploymentGenerator.generateDeployButton());
  console.log('\n');

  // Generate CLI command
  console.log('⌨️  Azure CLI Deployment Command:');
  console.log(AzureDeploymentGenerator.generateCLICommand('gene1799-rg'));
  console.log('\n');

  // Save documentation
  const docs = AzureDeploymentGenerator.generateDocumentation();
  fs.writeFileSync(path.join(__dirname, 'AZURE_DEPLOYMENT_QUICK.md'), docs);
  console.log('✅ Documentation saved to: AZURE_DEPLOYMENT_QUICK.md\n');

  // Export for use in other scripts
  module.exports = AzureDeploymentGenerator;
}

module.exports = AzureDeploymentGenerator;
