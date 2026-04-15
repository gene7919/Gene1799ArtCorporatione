# SuiteV17 Orchestrator v3 - Node.js Ready
$env:PATH += ";C:\Program Files\nodejs;C:\Users\marco\AppData\Roaming\npm"
npm install -g pm2

pm2 kill
pm2 start ecosystem.config.js --env production || Write-Host "No ecosystem"
pm2 start rag_bridge.js --name rag_bridge || Write-Host "No rag_bridge"
pm2 start server_macae.js --name macae || Write-Host "No macae"
pm2 start orchestrator.js --name gateway || Write-Host "No orchestrator"

pm2 start "py kernel\gene1799_rag_core.py" --name rag_core || Write-Host "No rag_core"
pm2 start "py zora_nft_agent.py" --name zora_agent || Write-Host "No zora"

pm2 status
Write-Host "SuiteV17 Live: http://localhost:8080/status | http://localhost:4000"
