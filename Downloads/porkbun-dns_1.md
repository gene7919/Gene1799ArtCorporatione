# Configurazione DNS Sicura - Porkbun
## gene1799artcorporatione.mom

### Record DNS da configurare su porkbun.com/account/domainsSpeedy

| Tipo   | Host | Valore                                          | TTL  | Priorità |
|--------|------|-------------------------------------------------|------|----------|
| A      | @    | (IP del tuo hosting WordPress)                  | 300  | —        |
| CNAME  | www  | gene1799artcorporatione.mom                     | 300  | —        |
| CAA    | @    | 0 issue "letsencrypt.org"                       | 3600 | —        |
| CAA    | @    | 0 issuewild ";"                                 | 3600 | —        |
| TXT    | @    | v=spf1 -all                                     | 3600 | —        |
| TXT    | _dmarc | v=DMARC1; p=reject; rua=mailto:tuaemail@gmail.com | 3600 | — |

### Sicurezza Dominio su Porkbun:

1. **DNSSEC**: Abilita in Domain Settings > DNSSEC
2. **Domain Lock**: Abilita in Domain Settings > Transfer Lock  
3. **WHOIS Privacy**: Già incluso gratuitamente su Porkbun
4. **Auto-Renew**: Attiva il rinnovo automatico

### Se usi Render.com come hosting:

| Tipo   | Host | Valore                                          |
|--------|------|-------------------------------------------------|
| CNAME  | @    | gene1799-api.onrender.com                       |
| CNAME  | www  | gene1799-api.onrender.com                       |

### Verifica:
```
# Testa i record DNS (da terminale)
dig gene1799artcorporatione.mom +short
dig CAA gene1799artcorporatione.mom
dig TXT gene1799artcorporatione.mom
```
