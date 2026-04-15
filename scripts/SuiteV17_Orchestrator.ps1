$env:PATH += ";C:\Program Files\nodejs;C:\Users\marco\AppData\Roaming\npm"
npm exec pm2 kill
npm install -g pm2

npm exec pm2 start ecosystem.config.js --env production || Write-Host "ecosystem skip"
npm exec pm2 start rag_bridge.js --name rag_bridge || Write-Host "rag_bridge skip"
npm exec pm2 start server_macae.js --name macae || Write-Host "macae skip"
npm exec pm2 start orchestrator.js --name gateway || Write-Host "gateway skip"

npm exec pm2 start "py C:\SuiteV17\kernel\gene1799_rag_core.py" --name rag_core || Write-Host "rag_core skip"
npm exec pm2 start "py C:\SuiteV17\zora_nft_agent.py" --name zora_agent || Write-Host "zora skip"

npm exec pm2 status
Write-Host "Gateway: http://localhost:8080/status"
