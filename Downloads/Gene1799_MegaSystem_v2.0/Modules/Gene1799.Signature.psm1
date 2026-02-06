#Requires -Version 7.0
<#
╔══════════════════════════════════════════════════════════════════╗
║     GENE1799 DIGITAL SIGNATURE MODULE                            ║
║     Firma digitale per NFT, documenti e autenticazione           ║
╚══════════════════════════════════════════════════════════════════╝
#>

$Script:Gene1799Certificate = @{
    Organization = "Gene1799 Art Corporation"
    Founders = @(
        "Marco Antonio Saverio Mazzitelli",
        "Fabio Amedeo Lo Presti (Arthemis Ludovici)"
    )
    License = "16/L4090879L"
    CertificateID = "GENE1799-ART-CORP-2024"
    Version = "1.0.0"
}

function Get-Gene1799Hash {
    param([string]$Content, [string]$Algorithm = 'SHA256')
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $hasher = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    return [BitConverter]::ToString($hasher.ComputeHash($bytes)).Replace('-', '').ToLower()
}

function Get-Gene1799SignatureInfo {
    return $Script:Gene1799Certificate
}

function Sign-Gene1799Json {
    param([hashtable]$Data)
    $signedData = $Data.Clone()
    $contentHash = Get-Gene1799Hash -Content ($Data | ConvertTo-Json -Depth 20 -Compress)
    
    $signature = @{
        signed_by = $Script:Gene1799Certificate.Organization
        founders = $Script:Gene1799Certificate.Founders
        license = $Script:Gene1799Certificate.License
        certificate_id = $Script:Gene1799Certificate.CertificateID
        content_hash = $contentHash
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        signature_hash = Get-Gene1799Hash -Content ($contentHash + $Script:Gene1799Certificate.CertificateID)
    }
    
    $signedData['gene1799_signature'] = $signature
    return $signedData
}

function Test-Gene1799JsonSignature {
    param([hashtable]$SignedData)
    
    if (-not $SignedData.ContainsKey('gene1799_signature')) { return $false }
    
    $signature = $SignedData['gene1799_signature']
    $originalData = $SignedData.Clone()
    $originalData.Remove('gene1799_signature')
    
    $recalculatedHash = Get-Gene1799Hash -Content ($originalData | ConvertTo-Json -Depth 20 -Compress)
    return ($recalculatedHash -eq $signature.content_hash)
}

function New-Gene1799NFTMetadata {
    param(
        [string]$Name,
        [string]$Description,
        [string]$ImageUri,
        [hashtable]$Attributes = @{}
    )
    
    $metadata = @{
        name = $Name
        description = $Description
        image = $ImageUri
        attributes = @(
            @{ trait_type = "Creator"; value = $Script:Gene1799Certificate.Organization }
            @{ trait_type = "License"; value = $Script:Gene1799Certificate.License }
        )
    }
    
    foreach ($key in $Attributes.Keys) {
        $metadata.attributes += @{ trait_type = $key; value = $Attributes[$key] }
    }
    
    return Sign-Gene1799Json -Data $metadata
}

Export-ModuleMember -Function @(
    'Get-Gene1799Hash',
    'Get-Gene1799SignatureInfo',
    'Sign-Gene1799Json',
    'Test-Gene1799JsonSignature',
    'New-Gene1799NFTMetadata'
)
