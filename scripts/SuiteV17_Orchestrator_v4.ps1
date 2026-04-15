pm2 kill
pm2 start rag_bridge.js --name rag_bridge || Write-Host "No rag_bridge"
pm2 start server_macae.js --name macae || Write-Host "No macae"
pm2 start "py -3 kernel\gene1799_rag_core.py" --name rag_core || Write-Host "No rag_core"
pm2 start "py -3 zora_nft_agent.py" --name zora_agent || Write-Host "No zora_agent"
pm2 status
