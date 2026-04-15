pm2 del zora_agent
Copy-Item "zora_nft_agent.py" "zoranftagent.py" -Force
pm2 start "py zoranftagent.py" --name zora_agent
pm2 status
