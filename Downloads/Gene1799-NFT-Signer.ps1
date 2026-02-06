<#
.SYNOPSIS
Firma metadati NFT con Gene1799 Digital Signature

.DESCRIPTION
Script per firmare e verificare metadati NFT utilizzando 
il sistema di firma digitale Gene1799 Core
#>

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$NFTMetadata,
    [switch]$Verify = $false
)

# Caricamento modulo Python
try {
    $pyCmd = @"
import json
from gene1799_core.signing import signer

# Metadati NFT
nft_metadata = json.loads('''$($NFTMetadata | ConvertTo-Json -Depth 10)''')

# Firma dei metadati
signed_nft = signer.sign_json(nft_metadata)

# Output risultati
print(json.dumps(signed_nft, indent=2))

# Verifica firma se richiesto
if $($Verify.ToString().ToLower()):
    is_valid = signer.verify_json_signature(signed_nft)
    print(f"\nFirma Valida: {is_valid}")
"@

    $result = python -c $pyCmd
    
    Write-Host "=== RISULTATO FIRMA NFT ===" -ForegroundColor Green
    Write-Host $result
}
catch {
    Write-Host "Errore durante la firma NFT: $_" -ForegroundColor Red
}
