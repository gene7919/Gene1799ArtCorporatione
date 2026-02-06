"""
╔══════════════════════════════════════════════════════════════════╗
║     GENE1799 DIGITAL SIGNATURE - Python Module                    ║
║     Firma digitale per NFT, documenti e autenticazione           ║
╚══════════════════════════════════════════════════════════════════╝

Gene1799 Art Corporation
Fondatori: Marco Antonio Saverio Mazzitelli & Fabio Amedeo Lo Presti (Arthemis Ludovici)
License: 16/L4090879L
"""

import hashlib
import json
from datetime import datetime
from typing import Dict, Any, List, Optional
import copy


class Gene1799Certificate:
    """Certificato digitale Gene1799"""
    
    ORGANIZATION = "Gene1799 Art Corporation"
    FOUNDERS = [
        "Marco Antonio Saverio Mazzitelli",
        "Fabio Amedeo Lo Presti (Arthemis Ludovici)"
    ]
    LICENSE = "16/L4090879L"
    CERTIFICATE_ID = "GENE1799-ART-CORP-2024"
    VERSION = "1.0.0"
    VALID_FROM = "2024-01-01"
    VALID_TO = "2099-12-31"


class Gene1799Signer:
    """
    Sistema di firma digitale Gene1799
    
    Utilizzo:
        from gene1799_core.signing import signer
        
        # Firma JSON
        signed = signer.sign_json({"name": "NFT #1"})
        
        # Verifica firma
        is_valid = signer.verify_json_signature(signed)
    """
    
    def __init__(self):
        self.cert = Gene1799Certificate()
    
    def _compute_hash(self, content: str, algorithm: str = 'sha256') -> str:
        """Calcola hash del contenuto"""
        hasher = hashlib.new(algorithm)
        hasher.update(content.encode('utf-8'))
        return hasher.hexdigest()
    
    def _compute_file_hash(self, file_path: str, algorithm: str = 'sha256') -> str:
        """Calcola hash di un file"""
        hasher = hashlib.new(algorithm)
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b''):
                hasher.update(chunk)
        return hasher.hexdigest()
    
    def get_signature_info(self) -> Dict[str, Any]:
        """Restituisce informazioni sul certificato"""
        return {
            "organization": Gene1799Certificate.ORGANIZATION,
            "founders": Gene1799Certificate.FOUNDERS,
            "license": Gene1799Certificate.LICENSE,
            "certificate_id": Gene1799Certificate.CERTIFICATE_ID,
            "version": Gene1799Certificate.VERSION,
            "valid_from": Gene1799Certificate.VALID_FROM,
            "valid_to": Gene1799Certificate.VALID_TO
        }
    
    def sign_json(self, data: Dict[str, Any], include_timestamp: bool = True) -> Dict[str, Any]:
        """
        Firma un dizionario/JSON con certificato Gene1799
        
        Args:
            data: Dati da firmare
            include_timestamp: Include timestamp nella firma
            
        Returns:
            Dati firmati con blocco gene1799_signature
        """
        # Crea copia dei dati
        signed_data = copy.deepcopy(data)
        
        # Serializza per hash (ordinato per consistenza)
        content_to_hash = json.dumps(data, sort_keys=True, separators=(',', ':'))
        content_hash = self._compute_hash(content_to_hash)
        
        # Crea blocco firma
        signature = {
            "signed_by": Gene1799Certificate.ORGANIZATION,
            "founders": Gene1799Certificate.FOUNDERS,
            "license": Gene1799Certificate.LICENSE,
            "certificate_id": Gene1799Certificate.CERTIFICATE_ID,
            "content_hash": content_hash,
            "algorithm": "sha256",
            "signature_version": Gene1799Certificate.VERSION
        }
        
        if include_timestamp:
            signature["timestamp"] = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
        
        # Genera signature hash
        signature["signature_hash"] = self._compute_hash(
            content_hash + Gene1799Certificate.CERTIFICATE_ID
        )
        
        # Aggiungi firma ai dati
        signed_data["gene1799_signature"] = signature
        
        return signed_data
    
    def verify_json_signature(self, signed_data: Dict[str, Any]) -> bool:
        """
        Verifica la firma Gene1799 su un dizionario/JSON
        
        Args:
            signed_data: Dati firmati da verificare
            
        Returns:
            True se la firma è valida, False altrimenti
        """
        # Verifica presenza firma
        if "gene1799_signature" not in signed_data:
            return False
        
        signature = signed_data["gene1799_signature"]
        
        # Verifica certificate ID
        if signature.get("certificate_id") != Gene1799Certificate.CERTIFICATE_ID:
            return False
        
        # Ricostruisci dati originali (senza firma)
        original_data = copy.deepcopy(signed_data)
        del original_data["gene1799_signature"]
        
        # Ricalcola hash
        content_to_hash = json.dumps(original_data, sort_keys=True, separators=(',', ':'))
        recalculated_hash = self._compute_hash(content_to_hash)
        
        # Verifica hash contenuto
        if recalculated_hash != signature.get("content_hash"):
            return False
        
        # Verifica signature hash
        expected_sig_hash = self._compute_hash(
            signature["content_hash"] + Gene1799Certificate.CERTIFICATE_ID
        )
        if expected_sig_hash != signature.get("signature_hash"):
            return False
        
        return True
    
    def sign_file(self, file_path: str, output_path: Optional[str] = None) -> Dict[str, Any]:
        """
        Firma un file con certificato Gene1799
        
        Args:
            file_path: Percorso del file da firmare
            output_path: Percorso del file firma (default: file_path + .gene1799sig)
            
        Returns:
            Dati firma
        """
        import os
        
        if output_path is None:
            output_path = file_path + ".gene1799sig"
        
        file_hash = self._compute_file_hash(file_path)
        file_stat = os.stat(file_path)
        
        signature_data = {
            "file_name": os.path.basename(file_path),
            "file_size": file_stat.st_size,
            "file_hash": file_hash,
            "hash_algorithm": "sha256"
        }
        
        signed_data = self.sign_json(signature_data)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(signed_data, f, indent=2)
        
        return signed_data
    
    def verify_file_signature(self, file_path: str, signature_path: Optional[str] = None) -> bool:
        """
        Verifica la firma di un file
        
        Args:
            file_path: Percorso del file originale
            signature_path: Percorso del file firma
            
        Returns:
            True se la firma è valida
        """
        if signature_path is None:
            signature_path = file_path + ".gene1799sig"
        
        try:
            with open(signature_path, 'r', encoding='utf-8') as f:
                signed_data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return False
        
        # Verifica firma Gene1799
        if not self.verify_json_signature(signed_data):
            return False
        
        # Verifica hash file
        current_hash = self._compute_file_hash(file_path)
        if current_hash != signed_data.get("file_hash"):
            return False
        
        return True
    
    def create_nft_metadata(
        self,
        name: str,
        description: str,
        image_uri: str,
        attributes: Optional[Dict[str, Any]] = None,
        external_url: Optional[str] = None,
        animation_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Crea metadata NFT firmato Gene1799
        
        Args:
            name: Nome dell'NFT
            description: Descrizione
            image_uri: URI dell'immagine (IPFS o HTTP)
            attributes: Attributi aggiuntivi
            external_url: URL esterno
            animation_url: URL animazione
            
        Returns:
            Metadata NFT firmato
        """
        metadata = {
            "name": name,
            "description": description,
            "image": image_uri,
            "attributes": [
                {"trait_type": "Creator", "value": Gene1799Certificate.ORGANIZATION},
                {"trait_type": "License", "value": Gene1799Certificate.LICENSE},
                {"trait_type": "Founders", "value": " & ".join(Gene1799Certificate.FOUNDERS)}
            ]
        }
        
        if attributes:
            for key, value in attributes.items():
                metadata["attributes"].append({"trait_type": key, "value": value})
        
        if external_url:
            metadata["external_url"] = external_url
        
        if animation_url:
            metadata["animation_url"] = animation_url
        
        return self.sign_json(metadata)


# Istanza singleton per uso rapido
signer = Gene1799Signer()


# Funzioni di convenienza
def sign_json(data: Dict[str, Any]) -> Dict[str, Any]:
    """Firma rapida JSON"""
    return signer.sign_json(data)


def verify_json_signature(signed_data: Dict[str, Any]) -> bool:
    """Verifica rapida firma JSON"""
    return signer.verify_json_signature(signed_data)


def get_signature_info() -> Dict[str, Any]:
    """Info certificato"""
    return signer.get_signature_info()


# CLI
if __name__ == "__main__":
    import sys
    
    print("=" * 60)
    print("GENE1799 DIGITAL SIGNATURE SYSTEM")
    print("=" * 60)
    print()
    
    # Mostra info certificato
    info = signer.get_signature_info()
    print("Certificato:")
    for k, v in info.items():
        print(f"  {k}: {v}")
    print()
    
    # Test firma
    test_data = {"name": "Test NFT", "value": 100}
    signed = signer.sign_json(test_data)
    
    print("Test firma:")
    print(f"  Dati originali: {test_data}")
    print(f"  Hash contenuto: {signed['gene1799_signature']['content_hash'][:32]}...")
    print(f"  Firma valida: {signer.verify_json_signature(signed)}")
    print()
    
    # Test manipolazione
    tampered = signed.copy()
    tampered["name"] = "MODIFIED"
    print(f"  Dopo manomissione: {signer.verify_json_signature(tampered)}")
