pm2 kill
npm install -g pm2
pm2 start rag_bridge.js --name rag_bridge
pm2 start server_macae.js --name macae
pm2 start "py -3 kernel\gene1799_rag_core.py" --interpreter py --interpreter-args "-3" --name rag_core
pm2 start "py -3 zora_nft_agent.py" --interpreter py --interpreter-args "-3" --name zora_agent
pm2 start orchestrator.js --name gateway
pm2 save
pm2 status
