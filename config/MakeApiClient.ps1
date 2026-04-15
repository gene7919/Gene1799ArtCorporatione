param(
  [string]$MakeConfigPath = "C:\SuiteV17\config\make.config.json"
)

#region Initialize from config

function Initialize-MakeFromConfig {
  param(
    [string]$ConfigPath = $MakeConfigPath
  )

  if (-not (Test-Path $ConfigPath)) {
    throw "Config Make non trovata: $ConfigPath"
  }

  $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json

  $script:Zone    = $cfg.environment.zone
  $script:BaseUrl = $cfg.environment.base_url

  $script:TeamId       = $cfg.auth.team_id
  $script:MakeApiToken = $cfg.auth.api_token
  $script:Headers      = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Token $($cfg.auth.api_token)"
  }

  $script:MakeScenarios = @{}
  $cfg.scenarios.PSObject.Properties | ForEach-Object {
    $script:MakeScenarios[$_.Name] = $_.Value
  }

  $script:MakeWebhooks = $cfg.webhooks
  $script:MakeActions  = $cfg.actions

  return $cfg
}

#endregion Initialize from config

#region Scenarios: GET list

function Get-MakeScenariosByTeam {
  param(
    [string]    $Zone    = $script:Zone,
    [int]       $TeamId  = $script:TeamId,
    [hashtable] $Headers = $script:Headers
  )

  if (-not $TeamId) {
    Write-Host "Devi passare un TeamId valido." -ForegroundColor Red
    return
  }

  $BaseUrl = "https://$Zone.make.com/api"
  $uri     = "$BaseUrl/v2/scenarios?teamId=$TeamId"

  $resp = Invoke-RestMethod -Method GET -Uri $uri -Headers $Headers

  # Supporta sia .scenarios che .items a seconda della versione API
  if ($resp.scenarios) {
    return $resp.scenarios | Select-Object id, name, teamId
  } elseif ($resp.items) {
    return $resp.items | Select-Object id, name, teamId
  } else {
    return $resp
  }
}

#endregion Scenarios: GET list

#region PATCH: rename scenario

function Rename-MakeScenario {
  param(
    [string]    $Zone        = $script:Zone,
    [int]       $ScenarioId,
    [string]    $NewName,
    [hashtable] $Headers     = $script:Headers
  )

  if (-not $ScenarioId -or -not $NewName) {
    Write-Host "Serve ScenarioId e NewName." -ForegroundColor Red
    return
  }

  $BaseUrl = "https://$Zone.make.com/api"
  $uri     = "$BaseUrl/v2/scenarios/$ScenarioId"

  $bodyObj = @{
    name = $NewName
  }
  $bodyJson = $bodyObj | ConvertTo-Json -Depth 5

  Invoke-RestMethod -Method PATCH `
    -Uri $uri `
    -Headers $Headers `
    -Body $bodyJson `
    -ContentType "application/json"
}

#endregion PATCH: rename scenario

#region Start / Stop scenario

function Start-MakeScenario {
  param(
    [string]    $Zone        = $script:Zone,
    [int]       $ScenarioId,
    [hashtable] $Headers     = $script:Headers
  )

  if (-not $ScenarioId) {
    Write-Host "Serve uno ScenarioId valido." -ForegroundColor Red
    return
  }

  $BaseUrl = "https://$Zone.make.com/api"
  $uri     = "$BaseUrl/v2/scenarios/$ScenarioId/start"

  Invoke-RestMethod -Method POST `
    -Uri $uri `
    -Headers $Headers `
    -ContentType "application/json"
}

function Stop-MakeScenario {
  param(
    [string]    $Zone        = $script:Zone,
    [int]       $ScenarioId,
    [hashtable] $Headers     = $script:Headers
  )

  if (-not $ScenarioId) {
    Write-Host "Serve uno ScenarioId valido." -ForegroundColor Red
    return
  }

  $BaseUrl = "https://$Zone.make.com/api"
  $uri     = "$BaseUrl/v2/scenarios/$ScenarioId/stop"

  Invoke-RestMethod -Method POST `
    -Uri $uri `
    -Headers $Headers `
    -ContentType "application/json"
}

#endregion Start / Stop scenario

#region Run scenario with data

function Run-MakeScenario {
  param(
    [string]    $Zone        = $script:Zone,
    [int]       $ScenarioId,
    [hashtable] $Headers     = $script:Headers,
    [hashtable] $Data,
    [switch]    $WaitResult
  )

  if (-not $ScenarioId) {
    Write-Host "Serve uno ScenarioId valido." -ForegroundColor Red
    return
  }

  $BaseUrl = "https://$Zone.make.com/api"
  $uri     = "$BaseUrl/v2/scenarios/$ScenarioId/run"

  $bodyObj = @{
    data = $Data
  }

  if ($WaitResult.IsPresent) {
    $bodyObj.responsive = $true
  }

  $bodyJson = $bodyObj | ConvertTo-Json -Depth 10

  Invoke-RestMethod -Method POST `
    -Uri $uri `
    -Headers $Headers `
    -Body $bodyJson `
    -ContentType "application/json"
}

#endregion Run scenario with data