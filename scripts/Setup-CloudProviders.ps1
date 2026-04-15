$ErrorActionPreference = "Stop"

Write-Host "`n[SUITEV17] Setup config provider cloud AI..." -ForegroundColor Cyan

$root = "C:\SuiteV17"
$cfgDir = Join-Path $root "config\providers"
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null

$providersJson = @"
{
  "providers": [
    {
      "name": "openai_main",
      "type": "llm",
      "vendor": "openai",
      "base_url": "https://api.openai.com/v1",
      "model": "gpt-4.1-mini",
      "env_api_key": "OPENAI_API_KEY",
      "roles": ["orchestrator", "code_repair", "text_improve"]
    },
    {
      "name": "groq_fast",
      "type": "llm",
      "vendor": "groq",
      "base_url": "https://api.groq.com/openai/v1",
      "model": "llama-3.1-70b-versatile",
      "env_api_key": "GROQ_API_KEY",
      "roles": ["code_gen", "code_refactor"]
    },
    {
      "name": "gemini_vision",
      "type": "multimodal",
      "vendor": "google",
      "base_url": "https://generativelanguage.googleapis.com/v1beta",
      "model": "gemini-1.5-pro",
      "env_api_key": "GEMINI_API_KEY",
      "roles": ["image_restore", "asset_annotate"]
    },
    {
      "name": "perplexity_search",
      "type": "llm",
      "vendor": "perplexity",
      "base_url": "https://api.perplexity.ai",
      "model": "sonar-reasoning",
      "env_api_key": "PERPLEXITY_API_KEY",
      "roles": ["web_research", "reasoning"]
    }
  ]
}
"@

$cfgFile = Join-Path $cfgDir "providers.json"
$providersJson | Set-Content -Path $cfgFile -Encoding UTF8

Write-Host "[SUITEV17] Config cloud providers scritto in $cfgFile" -ForegroundColor Green
Write-Host "Ricordati di impostare le variabili OPENAI_API_KEY, GROQ_API_KEY, GEMINI_API_KEY, PERPLEXITY_API_KEY a livello di sistema o nel servizio." -ForegroundColor Yellow
