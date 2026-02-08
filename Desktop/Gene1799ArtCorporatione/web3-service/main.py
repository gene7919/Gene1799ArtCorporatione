#!/usr/bin/env python3
"""
GENE1799 Web3 & NFT Service - Port 8004
Crypto portfolio, NFT gallery, token info, Zora/OpenSea integration.
Uses free public APIs only: DexScreener, Base RPC, Zora GraphQL.
"""

import json
import os
import time
import asyncio
from datetime import datetime
from typing import Optional, Dict, Any, List

import requests
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn

try:
    from web3 import Web3
    WEB3_AVAILABLE = True
except ImportError:
    WEB3_AVAILABLE = False

# ============================================================================
# CONFIGURATION
# ============================================================================

# GENE1799 Token on Base Network
TOKEN_CONTRACT = "0x63800f788e788e0d3a9cc0ce92a8e6c866f0f0f0"
TOKEN_SYMBOL = "GENE1799"
TOKEN_DECIMALS = 18
BASE_CHAIN_ID = 8453
ZORA_PROFILE = "gene1799"

# Free public RPC endpoints
BASE_RPC_URL = os.getenv("BASE_RPC_URL", "https://mainnet.base.org")
ETH_RPC_URL = os.getenv("ETH_RPC_URL", "https://eth.llamarpc.com")

# Free APIs
DEXSCREENER_API = "https://api.dexscreener.com/latest/dex"
ZORA_API = "https://api.zora.co/graphql"
OPENSEA_API = "https://api.opensea.io/api/v2"
COINGECKO_API = "https://api.coingecko.com/api/v3"
BASESCAN_API = "https://api.basescan.org/api"

# ERC20 ABI (minimal for balanceOf, totalSupply, name, symbol, decimals)
ERC20_ABI = json.loads('[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"type":"function"}]')

# Web3 connection
w3 = None
if WEB3_AVAILABLE:
    try:
        w3 = Web3(Web3.HTTPProvider(BASE_RPC_URL))
    except Exception:
        pass

# Cache
_cache: Dict[str, Dict] = {}
CACHE_TTL = 60  # seconds

# ============================================================================
# APP
# ============================================================================

app = FastAPI(
    title="GENE1799 Web3 & NFT Service",
    version="1.0.0",
    description="Crypto portfolio, NFT gallery, token info - Base Network"
)

# ============================================================================
# HELPERS
# ============================================================================

def _cached(key: str, ttl: int = CACHE_TTL) -> Optional[Any]:
    if key in _cache:
        entry = _cache[key]
        if time.time() - entry["ts"] < ttl:
            return entry["data"]
    return None


def _set_cache(key: str, data: Any):
    _cache[key] = {"data": data, "ts": time.time()}


def _format_wei(wei_value: int, decimals: int = 18) -> str:
    return str(round(wei_value / (10 ** decimals), 6))


# ============================================================================
# TOKEN INFO
# ============================================================================

def get_token_info() -> Dict[str, Any]:
    """Get $GENE1799 token contract info from Base blockchain."""
    cached = _cached("token_info", 300)
    if cached:
        return cached

    info = {
        "symbol": TOKEN_SYMBOL,
        "contract": TOKEN_CONTRACT,
        "chain": "Base (L2)",
        "chain_id": BASE_CHAIN_ID,
        "decimals": TOKEN_DECIMALS,
        "explorer": f"https://basescan.org/token/{TOKEN_CONTRACT}",
        "zora_profile": f"https://zora.co/@{ZORA_PROFILE}",
        "opensea": f"https://opensea.io/collection/{ZORA_PROFILE}",
        "dexscreener": f"https://dexscreener.com/base/{TOKEN_CONTRACT}",
    }

    # Try to read on-chain data
    if w3 and w3.is_connected():
        try:
            contract = w3.eth.contract(
                address=Web3.to_checksum_address(TOKEN_CONTRACT),
                abi=ERC20_ABI
            )
            try:
                info["name"] = contract.functions.name().call()
            except Exception:
                info["name"] = TOKEN_SYMBOL
            try:
                total = contract.functions.totalSupply().call()
                info["total_supply"] = _format_wei(total, TOKEN_DECIMALS)
            except Exception:
                info["total_supply"] = "unknown"
        except Exception as e:
            info["rpc_error"] = str(e)

    info["rpc_connected"] = bool(w3 and w3.is_connected())
    info["timestamp"] = datetime.now().isoformat()

    _set_cache("token_info", info)
    return info


def get_token_price() -> Dict[str, Any]:
    """Get live token price from DexScreener (free, no API key)."""
    cached = _cached("token_price", 30)
    if cached:
        return cached

    try:
        resp = requests.get(
            f"{DEXSCREENER_API}/tokens/{TOKEN_CONTRACT}",
            timeout=10
        )
        data = resp.json()

        if data.get("pairs") and len(data["pairs"]) > 0:
            pair = data["pairs"][0]
            result = {
                "symbol": TOKEN_SYMBOL,
                "price_usd": pair.get("priceUsd", "0"),
                "price_native": pair.get("priceNative", "0"),
                "volume_24h": pair.get("volume", {}).get("h24", "0"),
                "price_change_24h": pair.get("priceChange", {}).get("h24", "0"),
                "liquidity_usd": pair.get("liquidity", {}).get("usd", "0"),
                "market_cap": pair.get("marketCap", "0"),
                "fdv": pair.get("fdv", "0"),
                "dex": pair.get("dexId", "unknown"),
                "pair_address": pair.get("pairAddress", ""),
                "base_token": pair.get("baseToken", {}).get("symbol", TOKEN_SYMBOL),
                "quote_token": pair.get("quoteToken", {}).get("symbol", "ETH"),
                "url": pair.get("url", f"https://dexscreener.com/base/{TOKEN_CONTRACT}"),
                "source": "dexscreener",
                "timestamp": datetime.now().isoformat()
            }
        else:
            result = {
                "symbol": TOKEN_SYMBOL,
                "price_usd": "0",
                "message": "No trading pairs found on DexScreener",
                "contract": TOKEN_CONTRACT,
                "chain": "base",
                "timestamp": datetime.now().isoformat()
            }

        _set_cache("token_price", result)
        return result

    except Exception as e:
        return {
            "symbol": TOKEN_SYMBOL,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }


# ============================================================================
# WALLET / PORTFOLIO
# ============================================================================

def get_wallet_portfolio(address: str) -> Dict[str, Any]:
    """Get wallet portfolio: ETH balance + GENE1799 token balance on Base."""
    if not w3 or not w3.is_connected():
        return {"error": "Base RPC not connected", "address": address}

    try:
        checksum = Web3.to_checksum_address(address)
    except Exception:
        return {"error": f"Invalid address: {address}"}

    portfolio = {
        "address": address,
        "chain": "Base",
        "chain_id": BASE_CHAIN_ID,
    }

    # ETH balance
    try:
        eth_bal = w3.eth.get_balance(checksum)
        portfolio["eth_balance"] = _format_wei(eth_bal, 18)
        portfolio["eth_balance_wei"] = str(eth_bal)
    except Exception as e:
        portfolio["eth_balance"] = "0"
        portfolio["eth_error"] = str(e)

    # GENE1799 token balance
    try:
        contract = w3.eth.contract(
            address=Web3.to_checksum_address(TOKEN_CONTRACT),
            abi=ERC20_ABI
        )
        token_bal = contract.functions.balanceOf(checksum).call()
        portfolio["gene1799_balance"] = _format_wei(token_bal, TOKEN_DECIMALS)
        portfolio["gene1799_balance_raw"] = str(token_bal)
    except Exception as e:
        portfolio["gene1799_balance"] = "0"
        portfolio["token_error"] = str(e)

    # Add price if available
    price_data = get_token_price()
    if price_data.get("price_usd") and price_data["price_usd"] != "0":
        try:
            token_val = float(portfolio.get("gene1799_balance", "0")) * float(price_data["price_usd"])
            portfolio["gene1799_value_usd"] = f"{token_val:.4f}"
        except Exception:
            pass

    portfolio["explorer"] = f"https://basescan.org/address/{address}"
    portfolio["timestamp"] = datetime.now().isoformat()
    return portfolio


# ============================================================================
# NFT - ZORA
# ============================================================================

def get_zora_nfts() -> Dict[str, Any]:
    """Load NFTs from zora.co/@gene1799 using Zora's free API."""
    cached = _cached("zora_nfts", 120)
    if cached:
        return cached

    # Zora API - get tokens created by profile
    query = """
    query GetTokens($creator: String!) {
        tokens(
            where: { creatorAddress: $creator }
            sort: { sortKey: CREATED, sortDirection: DESC }
            pagination: { limit: 50 }
        ) {
            nodes {
                token {
                    tokenId
                    name
                    description
                    image { url }
                    content { url mimeType }
                    metadata
                    mintable
                    totalMinted
                    tokenContract { name collectionAddress chain }
                }
            }
        }
    }
    """

    # Also try the simpler collections endpoint
    try:
        resp = requests.get(
            f"https://api.zora.co/discover/user/{ZORA_PROFILE}",
            timeout=15,
            headers={"Accept": "application/json"}
        )
        if resp.status_code == 200:
            data = resp.json()
            result = {
                "platform": "zora",
                "profile": f"https://zora.co/@{ZORA_PROFILE}",
                "data": data,
                "timestamp": datetime.now().isoformat()
            }
            _set_cache("zora_nfts", result)
            return result
    except Exception:
        pass

    # Fallback: try GraphQL
    try:
        resp = requests.post(
            ZORA_API,
            json={"query": query, "variables": {"creator": ZORA_PROFILE}},
            timeout=15,
            headers={"Content-Type": "application/json"}
        )

        if resp.status_code == 200:
            data = resp.json()
            nfts = []
            nodes = data.get("data", {}).get("tokens", {}).get("nodes", [])
            for node in nodes:
                token = node.get("token", {})
                nfts.append({
                    "token_id": token.get("tokenId"),
                    "name": token.get("name", "Untitled"),
                    "description": token.get("description", ""),
                    "image": token.get("image", {}).get("url", ""),
                    "content_url": token.get("content", {}).get("url", ""),
                    "content_type": token.get("content", {}).get("mimeType", ""),
                    "mintable": token.get("mintable", False),
                    "total_minted": token.get("totalMinted", "0"),
                    "collection": token.get("tokenContract", {}).get("name", ""),
                    "contract": token.get("tokenContract", {}).get("collectionAddress", ""),
                    "chain": token.get("tokenContract", {}).get("chain", "BASE"),
                })

            result = {
                "platform": "zora",
                "profile": f"https://zora.co/@{ZORA_PROFILE}",
                "nft_count": len(nfts),
                "nfts": nfts,
                "timestamp": datetime.now().isoformat()
            }
            _set_cache("zora_nfts", result)
            return result

    except Exception as e:
        pass

    # Static fallback with profile link
    result = {
        "platform": "zora",
        "profile": f"https://zora.co/@{ZORA_PROFILE}",
        "nft_count": 0,
        "nfts": [],
        "message": "Visit zora.co/@gene1799 for the full collection",
        "links": {
            "profile": f"https://zora.co/@{ZORA_PROFILE}",
            "mint": f"https://zora.co/@{ZORA_PROFILE}",
            "create": "https://zora.co/create"
        },
        "timestamp": datetime.now().isoformat()
    }
    _set_cache("zora_nfts", result)
    return result


# ============================================================================
# NFT - OPENSEA
# ============================================================================

def get_opensea_nfts() -> Dict[str, Any]:
    """Load NFTs from OpenSea (free tier, no API key for basic reads)."""
    cached = _cached("opensea_nfts", 120)
    if cached:
        return cached

    collection_slug = "gene1799"
    api_key = os.getenv("OPENSEA_API_KEY", "")

    headers = {"Accept": "application/json"}
    if api_key:
        headers["X-API-KEY"] = api_key

    try:
        # Get collection info
        resp = requests.get(
            f"{OPENSEA_API}/collections/{collection_slug}",
            headers=headers,
            timeout=15
        )

        if resp.status_code == 200:
            data = resp.json()
            result = {
                "platform": "opensea",
                "collection": collection_slug,
                "url": f"https://opensea.io/collection/{collection_slug}",
                "data": data,
                "timestamp": datetime.now().isoformat()
            }
            _set_cache("opensea_nfts", result)
            return result

        # If 401/403, no API key or collection not found
        result = {
            "platform": "opensea",
            "collection": collection_slug,
            "url": f"https://opensea.io/collection/{collection_slug}",
            "status": resp.status_code,
            "message": "Collection available at opensea.io/collection/gene1799",
            "api_key_configured": bool(api_key),
            "timestamp": datetime.now().isoformat()
        }
        _set_cache("opensea_nfts", result)
        return result

    except Exception as e:
        return {
            "platform": "opensea",
            "url": f"https://opensea.io/collection/{collection_slug}",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }


# ============================================================================
# NFT - AGGREGATED
# ============================================================================

def get_all_nfts() -> Dict[str, Any]:
    """Aggregate NFTs from all platforms."""
    return {
        "zora": get_zora_nfts(),
        "opensea": get_opensea_nfts(),
        "links": {
            "zora": f"https://zora.co/@{ZORA_PROFILE}",
            "opensea": f"https://opensea.io/collection/{ZORA_PROFILE}",
            "rarible": f"https://rarible.com/{ZORA_PROFILE}",
            "superrare": f"https://superrare.com/{ZORA_PROFILE}",
            "foundation": f"https://foundation.app/@{ZORA_PROFILE}",
        },
        "token": {
            "symbol": TOKEN_SYMBOL,
            "contract": TOKEN_CONTRACT,
            "chain": "Base",
            "dexscreener": f"https://dexscreener.com/base/{TOKEN_CONTRACT}",
        },
        "timestamp": datetime.now().isoformat()
    }


# ============================================================================
# ZORA PROFILE
# ============================================================================

def get_zora_profile() -> Dict[str, Any]:
    """Get Zora profile info for @gene1799."""
    cached = _cached("zora_profile", 300)
    if cached:
        return cached

    result = {
        "username": ZORA_PROFILE,
        "profile_url": f"https://zora.co/@{ZORA_PROFILE}",
        "mint_url": f"https://zora.co/@{ZORA_PROFILE}",
        "create_url": "https://zora.co/create",
        "token": {
            "symbol": TOKEN_SYMBOL,
            "contract": TOKEN_CONTRACT,
            "chain": "Base",
            "chain_id": BASE_CHAIN_ID,
        },
        "nft_platforms": {
            "zora": f"https://zora.co/@{ZORA_PROFILE}",
            "opensea": f"https://opensea.io/collection/{ZORA_PROFILE}",
            "rarible": f"https://rarible.com/{ZORA_PROFILE}",
            "superrare": f"https://superrare.com/{ZORA_PROFILE}",
            "foundation": f"https://foundation.app/@{ZORA_PROFILE}",
        },
        "social": {
            "twitter": "https://x.com/gene1799",
            "instagram": "https://instagram.com/gene1799",
            "telegram": "https://t.me/gene1799",
        },
        "timestamp": datetime.now().isoformat()
    }

    _set_cache("zora_profile", result)
    return result


# ============================================================================
# MINT PREPARATION
# ============================================================================

class MintRequest(BaseModel):
    collection_address: str
    token_id: Optional[str] = None
    quantity: int = 1
    minter_address: str


def prepare_mint(req: MintRequest) -> Dict[str, Any]:
    """Prepare a Zora mint transaction (returns unsigned tx data for frontend signing)."""
    # Zora 1155 mint ABI
    mint_abi = json.loads('[{"inputs":[{"name":"minter","type":"address"},{"name":"tokenId","type":"uint256"},{"name":"quantity","type":"uint256"},{"name":"minterArguments","type":"bytes"}],"name":"mint","outputs":[],"stateMutability":"payable","type":"function"}]')

    if not w3 or not w3.is_connected():
        return {
            "error": "Base RPC not connected",
            "fallback_url": f"https://zora.co/@{ZORA_PROFILE}",
            "message": "Mint directly on zora.co"
        }

    try:
        contract = w3.eth.contract(
            address=Web3.to_checksum_address(req.collection_address),
            abi=mint_abi
        )

        # Build unsigned transaction
        tx_data = contract.functions.mint(
            Web3.to_checksum_address(req.minter_address),
            int(req.token_id or "1"),
            req.quantity,
            b""
        ).build_transaction({
            "from": Web3.to_checksum_address(req.minter_address),
            "value": 0,
            "chainId": BASE_CHAIN_ID,
            "gas": 200000,
            "nonce": w3.eth.get_transaction_count(
                Web3.to_checksum_address(req.minter_address)
            ),
        })

        return {
            "unsigned_tx": {
                "to": req.collection_address,
                "data": tx_data.get("data", ""),
                "value": str(tx_data.get("value", 0)),
                "gas": tx_data.get("gas", 200000),
                "chainId": BASE_CHAIN_ID,
            },
            "message": "Sign this transaction with your wallet (MetaMask)",
            "collection": req.collection_address,
            "token_id": req.token_id,
            "quantity": req.quantity,
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        return {
            "error": str(e),
            "fallback_url": f"https://zora.co/@{ZORA_PROFILE}",
            "message": "Mint directly on zora.co if transaction preparation failed"
        }


# ============================================================================
# ENDPOINTS
# ============================================================================

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "GENE1799 Web3 & NFT Service",
        "web3_available": WEB3_AVAILABLE,
        "rpc_connected": bool(w3 and w3.is_connected()),
        "chain": "Base",
        "token": TOKEN_SYMBOL,
    }


@app.get("/status")
async def status():
    return {
        "service": "GENE1799 Web3 & NFT Service",
        "version": "1.0.0",
        "port": 8004,
        "web3_available": WEB3_AVAILABLE,
        "rpc_connected": bool(w3 and w3.is_connected()),
        "chain": "Base (L2)",
        "chain_id": BASE_CHAIN_ID,
        "token_contract": TOKEN_CONTRACT,
        "token_symbol": TOKEN_SYMBOL,
        "zora_profile": f"https://zora.co/@{ZORA_PROFILE}",
        "cache_entries": len(_cache),
        "timestamp": datetime.now().isoformat()
    }


@app.get("/token/info")
async def token_info():
    return get_token_info()


@app.get("/token/price")
async def token_price():
    return get_token_price()


@app.get("/wallet/{address}/portfolio")
async def wallet_portfolio(address: str):
    return get_wallet_portfolio(address)


@app.get("/nft/zora")
async def nft_zora():
    return get_zora_nfts()


@app.get("/nft/opensea")
async def nft_opensea():
    return get_opensea_nfts()


@app.get("/nft/all")
async def nft_all():
    return get_all_nfts()


@app.get("/zora/profile")
async def zora_profile():
    return get_zora_profile()


@app.post("/nft/mint/prepare")
async def nft_mint_prepare(req: MintRequest):
    return prepare_mint(req)


# ============================================================================
# STARTUP
# ============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("  GENE1799 Web3 & NFT Service")
    print(f"  Web3: {'OK' if WEB3_AVAILABLE else 'NOT AVAILABLE'}")
    print(f"  RPC: {'Connected' if w3 and w3.is_connected() else 'Not connected'}")
    print(f"  Chain: Base (ID {BASE_CHAIN_ID})")
    print(f"  Token: {TOKEN_SYMBOL} ({TOKEN_CONTRACT[:10]}...)")
    print(f"  Zora: zora.co/@{ZORA_PROFILE}")
    print("=" * 60)
    print("  Starting on http://0.0.0.0:8004")
    print("=" * 60)
    uvicorn.run(app, host="0.0.0.0", port=8004, reload=False)
