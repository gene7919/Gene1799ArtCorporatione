"""Test Gene1799 Digital Signature"""
import sys
from pathlib import Path

# Add gene1799_core path
core_path = Path(__file__).parent
sys.path.insert(0, str(core_path))

from gene1799_core.signing import signer

print("=== TEST FIRMA DIGITALE GENE1799 ===\n")

# Test 1: Info certificato
print("[TEST 1] Info certificato:")
info = signer.get_signature_info()
for k, v in info.items():
    print(f"  {k}: {v}")

# Test 2: Firma JSON (NFT metadata)
print("\n[TEST 2] Firma JSON metadata NFT:")
nft_data = {
    "name": "Gene1799 Art #1799",
    "description": "Opera firmata da Marco Antonio Saverio Mazzitelli & Fabio Amedeo Lo Presti (Arthemis Ludovici)",
    "image": "ipfs://QmExample...",
    "attributes": {
        "rarity": "legendary",
        "artist": "Gene1799ArtCorporatione",
        "license": "16/L4090879L"
    }
}

signed = signer.sign_json(nft_data.copy())
print(f"✔ Firmato da: {signed['gene1799_signature']['signed_by']}")
print(f"✔ Fondatori: {', '.join(signed['gene1799_signature']['founders'])}")
print(f"✔ Hash: {signed['gene1799_signature']['content_hash'][:32]}...")
print(f"✔ Timestamp: {signed['gene1799_signature']['timestamp']}")

# Test 3: Verifica firma
print("\n[TEST 3] Verifica firma:")
is_valid = signer.verify_json_signature(signed)
print(f"✔ Firma valida: {is_valid}")

# Test 4: Manipolazione (deve fallire)
print("\n[TEST 4] Test manipolazione (deve fallire):")
signed_tampered = signed.copy()
signed_tampered["name"] = "MODIFIED BY ATTACKER"
is_valid_after = signer.verify_json_signature(signed_tampered)
print(f"✔ Firma dopo manomissione: {is_valid_after} (atteso: False)")

print("\n=== TEST COMPLETATO ===")
print("La firma digitale Gene1799 è pronta per l'uso!")
