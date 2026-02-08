#!/usr/bin/env pwsh

<#
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║     ☁️  GENE1799 - AZURE AI SETUP & CONFIGURATION ☁️                   ║
║                                                                           ║
║  Configure and integrate Azure AI Agents with GENE1799                   ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
#>

param(
    [ValidateSet('Setup', 'Config', 'Test', 'Run', 'Full')]
    [string]$Action = 'Full'
)

# ═══════════════════════════════════════════════════════════════════════════
# AZURE CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

$AzureConfig = @{
    Endpoint = "https://gene1799artcorporatione-resource.services.ai.azure.com/api/projects/gene1799artcorporatione-3261"
    ProjectId = "gene1799artcorporatione-3261"
    SubscriptionId = "f5117908-9b03-4041-a740-87bd287f8c55"
    ResourceGroup = "rg-gene1799artcorporatione-3269"
    TenantId = "cfc35dee-c900-4747-b9a1-0c2d6dcd9eda"
    Location = "eastus"
    Port = 8001
}

function Write-Status {
    param([string]$Message, [string]$Type = "info")

    $color = @{
        "info" = "Cyan"
        "success" = "Green"
        "warning" = "Yellow"
        "error" = "Red"
    }[$Type]

    $symbol = @{
        "info" = "ℹ️"
        "success" = "✅"
        "warning" = "⚠️"
        "error" = "❌"
    }[$Type]

    Write-Host "$symbol $Message" -ForegroundColor $color
}

function Setup-AzureEnvironment {
    Write-Host "`n📋 SETTING UP AZURE ENVIRONMENT`n" -ForegroundColor Magenta

    Write-Status "Installing Azure SDK..." "info"

    # Create requirements file for Azure
    $PythonRequirements = @"
# Azure AI Projects SDK
azure-ai-projects>=2.0.0b1
azure-identity
azure-core

# FastAPI for local API
fastapi
uvicorn
pydantic
python-multipart

# Additional dependencies
requests
aiohttp
python-dotenv
"@

    $PythonRequirements | Out-File -FilePath "requirements-azure.txt" -Encoding UTF8 -Force
    Write-Status "Created: requirements-azure.txt" "success"

    # Install packages
    Write-Status "Installing Python packages..." "info"
    pip install -r requirements-azure.txt | Out-Null
    Write-Status "Packages installed" "success"
}

function Create-AzureConfig {
    Write-Host "`n⚙️  CREATING AZURE CONFIGURATION`n" -ForegroundColor Magenta

    # Create .env.azure file
    $AzureEnv = @"
# Azure AI Configuration
AZURE_ENDPOINT=https://gene1799artcorporatione-resource.services.ai.azure.com/api/projects/gene1799artcorporatione-3261
AZURE_PROJECT_ID=gene1799artcorporatione-3261
AZURE_SUBSCRIPTION_ID=f5117908-9b03-4041-a740-87bd287f8c55
AZURE_RESOURCE_GROUP=rg-gene1799artcorporatione-3269
AZURE_TENANT_ID=cfc35dee-c900-4747-b9a1-0c2d6dcd9eda
AZURE_LOCATION=eastus

# Authentication (uses DefaultAzureCredential)
# Set environment variables or use Azure CLI login:
# az login --tenant cfc35dee-c900-4747-b9a1-0c2d6dcd9eda

# API Configuration
API_PORT=8001
API_HOST=0.0.0.0

# Available Agents
AZURE_AGENTS=alMedicochelante

# Service Configuration
SERVICE_NAME=GENE1799 Azure AI Integration
SERVICE_VERSION=1.0.0
LOG_LEVEL=INFO
"@

    $AzureEnv | Out-File -FilePath ".env.azure" -Encoding UTF8 -Force
    Write-Status "Created: .env.azure" "success"

    # Create azure_config.json
    $ConfigJson = @{
        endpoint = $AzureConfig.Endpoint
        project_id = $AzureConfig.ProjectId
        subscription_id = $AzureConfig.SubscriptionId
        resource_group = $AzureConfig.ResourceGroup
        tenant_id = $AzureConfig.TenantId
        location = $AzureConfig.Location
        api_port = $AzureConfig.Port
        agents = @(
            @{
                name = "alMedicochelante"
                type = "medical"
                description = "Medical AI specialist"
                capabilities = @(
                    "tumor_classification",
                    "drug_targeting",
                    "clinical_trials",
                    "healthcare_integration"
                )
            }
        )
        created = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    } | ConvertTo-Json -Depth 10

    $ConfigJson | Out-File -FilePath "config/azure_config.json" -Encoding UTF8 -Force
    Write-Status "Created: config/azure_config.json" "success"
}

function Test-AzureConnection {
    Write-Host "`n🧪 TESTING AZURE CONNECTION`n" -ForegroundColor Magenta

    Write-Status "Checking Azure CLI..." "info"

    try {
        $azVersion = az --version 2>&1 | head -1
        Write-Status "Azure CLI found: $azVersion" "success"
    } catch {
        Write-Status "Azure CLI not found - install from https://aka.ms/azcli-wsl" "warning"
    }

    Write-Status "Testing credentials..." "info"

    try {
        # Try to get current context
        $context = az account show 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Azure credentials valid" "success"
            Write-Host "`n$context`n" -ForegroundColor Gray
        } else {
            Write-Status "Azure login required - run: az login" "warning"
        }
    } catch {
        Write-Status "Could not verify credentials" "warning"
    }
}

function Run-AzureService {
    Write-Host "`n🚀 STARTING AZURE AI SERVICE`n" -ForegroundColor Magenta

    Write-Status "Starting Python service..." "info"
    Write-Status "Service will run on: http://localhost:$($AzureConfig.Port)" "info"

    Write-Host "`nAPI Endpoints:
    GET  /health               - Health check
    GET  /agents               - List agents
    GET  /agents/{name}        - Get agent info
    POST /query                - Query agent
    GET  /config               - Configuration
    GET  /status               - Service status

Swagger UI: http://localhost:$($AzureConfig.Port)/docs
ReDoc: http://localhost:$($AzureConfig.Port)/redoc

Press Ctrl+C to stop`n" -ForegroundColor Cyan

    python azure_ai_integration.py
}

function Show-Documentation {
    Write-Host @"

╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                  AZURE AI INTEGRATION SETUP COMPLETE                      ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

📋 CONFIGURATION:
   Endpoint: $($AzureConfig.Endpoint)
   Project: $($AzureConfig.ProjectId)
   Subscription: $($AzureConfig.SubscriptionId)

🤖 AVAILABLE AGENTS:
   • alMedicochelante (Medical AI specialist)

🔐 AUTHENTICATION:
   Using Azure DefaultAzureCredential

   Option 1: Azure CLI
     az login --tenant $($AzureConfig.TenantId)

   Option 2: Environment Variables
     Set AZURE_SUBSCRIPTION_ID, etc.

   Option 3: Service Principal
     Set AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID

📚 NEXT STEPS:

1. Authenticate with Azure:
   az login --tenant $($AzureConfig.TenantId)

2. Run the service:
   python azure_ai_integration.py

3. Test the API:
   curl http://localhost:$($AzureConfig.Port)/health
   curl http://localhost:$($AzureConfig.Port)/agents

4. Query an agent:
   curl -X POST http://localhost:$($AzureConfig.Port)/query \
        -H "Content-Type: application/json" \
        -d '{
          "agent_name": "alMedicochelante",
          "message": "What medical conditions can you help with?"
        }'

📖 FILES CREATED:
   • azure_ai_integration.py (Main service)
   • requirements-azure.txt (Python dependencies)
   • .env.azure (Environment configuration)
   • config/azure_config.json (Azure configuration)
   • setup-azure.ps1 (This setup script)

💡 INTEGRATION WITH GENE1799:

The Azure AI service runs on port $($AzureConfig.Port) and can be accessed from:

1. Local Dashboard:
   http://localhost:5173 → connects to port $($AzureConfig.Port)

2. Master Orchestrator:
   http://localhost:5000 → routes to Azure agents

3. Direct API:
   http://localhost:$($AzureConfig.Port)/docs (Swagger UI)

🔗 GITHUB INTEGRATION:
   Repository: https://github.com/gene7919/Gene1799ArtCorporatione
   Latest commit includes azure_ai_integration.py

════════════════════════════════════════════════════════════════════════════

For troubleshooting, see: AZURE_AI_SETUP_GUIDE.txt

"@ -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║      ☁️  GENE1799 AZURE AI SETUP SCRIPT ☁️                             ║
║                                                                           ║
║      Setup and configure Azure AI integration                            ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Magenta

switch ($Action) {
    'Setup' {
        Setup-AzureEnvironment
    }
    'Config' {
        Create-AzureConfig
    }
    'Test' {
        Test-AzureConnection
    }
    'Run' {
        Run-AzureService
    }
    'Full' {
        Setup-AzureEnvironment
        Create-AzureConfig
        Test-AzureConnection
        Show-Documentation
    }
}
