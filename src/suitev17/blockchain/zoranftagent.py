import asyncio
import requests
import os
import json
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# Config SuiteV17 GENE1799
ALCHEMY_KEY = os.getenv("ALCHEMY_KEY", "VPfgdBOReEDP-GkvmgAd")
BASE_RPC = os.getenv("BASE_RPC", "https://mainnet.base.org")
WALLET_TARGET = "0x994b342dd87fc825f66e51ffa3ef71ad818b6893"

class ZoraNFTAgent:
    def __init__(self):
        self.wallet = WALLET_TARGET
        self.rpc = BASE_RPC
        self.headers = {"Content-Type": "application/json"}
        self.log_file = "nft_log.json"

    def log(self, data):
        data["timestamp"] = datetime.utcnow().isoformat()
        print(data)

        with open(self.log_file, "a") as f:
            f.write(json.dumps(data) + "\n")

    def get_nfts(self):
        url = f"https://base-mainnet.g.alchemy.com/nft/v3/{ALCHEMY_KEY}/getNFTsForOwner"
        params = {
            "owner": self.wallet,
            "withMetadata": "true"
        }

        try:
            r = requests.get(url, params=params)
            data = r.json()
            return data.get("ownedNfts", [])
        except Exception as e:
            self.log({"error": str(e)})
            return []

    def analyze_nfts(self, nfts):
        results = []
        for nft in nfts:
            name = nft.get("name")
            contract = nft.get("contract", {}).get("address")

            results.append({
                "name": name,
                "contract": contract
            })

        return results

    async def monitor(self):
        while True:
            nfts = self.get_nfts()
            analyzed = self.analyze_nfts(nfts)

            self.log({
                "wallet": self.wallet,
                "nft_count": len(analyzed),
                "nfts": analyzed
            })

            await asyncio.sleep(30)  # polling

# RUN
if __name__ == "__main__":
    agent = ZoraNFTAgent()
    asyncio.run(agent.monitor())