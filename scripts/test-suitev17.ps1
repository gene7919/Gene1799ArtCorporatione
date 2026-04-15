$body = @{
  source = "make"
  scenario = "gen_e1799"
  platform = "discord"
  status = "approved"
  title = "test"
  caption = "ciao"
  media_url = "https://example.com/a.jpg"
  publish_at = (Get-Date).ToString("s")
} | ConvertTo-Json -Depth 5

Invoke-RestMethod `
  -Uri "http://127.0.0.1:3007/api/social/ingest" `
  -Method Post `
  -Headers @{ Authorization = "Bearer YOUR_TOKEN" } `
  -ContentType "application/json" `
  -Body $body
