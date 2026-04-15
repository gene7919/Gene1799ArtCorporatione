$ErrorActionPreference = "Stop"

Write-Host "`n[SUITEV17] Setup struttura base Orchestrator/Workspaces..." -ForegroundColor Cyan

$root = "C:\SuiteV17"

# 1) Cartelle base
$dirs = @(
  "$root\workspaces",
  "$root\workspaces\default",
  "$root\logs",
  "$root\config",
  "$root\config\agents",
  "$root\config\workspaces",
  "$root\config\tools"
)

foreach ($d in $dirs) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
}

# 2) config\agents\agents.json - registro agenti logici
$agentsJson = @"
{
  "agents": [
    {
      "name": "gene_rag_bridge",
      "type": "rag",
      "capabilities": ["rag_query", "context_injection"],
      "default_workspace": "default",
      "enabled": true,
      "priority": 10
    },
    {
      "name": "gene_rag_core",
      "type": "planner",
      "capabilities": ["plan", "route_tasks", "aggregate_results"],
      "default_workspace": "default",
      "enabled": true,
      "priority": 20
    },
    {
      "name": "macae",
      "type": "devops",
      "capabilities": ["http_api", "pm2_control", "logs_stream"],
      "default_workspace": "default",
      "enabled": true,
      "priority": 5
    }
  ]
}
"@
$agentsJson | Set-Content -Path "$root\config\agents\agents.json" -Encoding UTF8

# 3) config\workspaces\default.json - workspace di default
$wsDefaultJson = @"
{
  "id": "default",
  "name": "Default Workspace",
  "description": "Workspace di default per SuiteV17",
  "vector_store_path": "C:\\SuiteV17\\workspaces\\default\\vectors",
  "enabled_agents": [
    "gene_rag_bridge",
    "gene_rag_core",
    "macae"
  ]
}
"@
$wsDefaultJson | Set-Content -Path "$root\config\workspaces\default.json" -Encoding UTF8

# 4) config\tools\tools.json - scheletro tool-agent
$toolsJson = @"
{
  "tools": [
    {
      "name": "blockchain_rpc_main",
      "type": "blockchain",
      "endpoint": "https://rpc-mainnet-placeholder",
      "healthcheck": {
        "enabled": false,
        "interval_sec": 60
      },
      "retry": {
        "max_attempts": 3,
        "backoff_ms": 500
      }
    },
    {
      "name": "ipfs_pin_node",
      "type": "ipfs",
      "endpoint": "https://ipfs-placeholder",
      "healthcheck": {
        "enabled": false,
        "interval_sec": 60
      },
      "retry": {
        "max_attempts": 3,
        "backoff_ms": 500
      }
    }
  ]
}
"@
$toolsJson | Set-Content -Path "$root\config\tools\tools.json" -Encoding UTF8

Write-Host "[SUITEV17] Struttura cartelle + config base agenti/workspaces creata." -ForegroundColor Green

