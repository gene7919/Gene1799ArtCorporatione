# Gene1799 Legal Sign

Seconda patch: integrazione reale del backend verso DSS.

## Cosa aggiunge
- dipendenze DSS nel `pom.xml`
- modalitÃ  token:
  - `MSCAPI`
  - `PKCS11`
  - `PKCS12`
- lettura certificati reali dal token/keystore
- firma PAdES baseline B via DSS
- validazione firma PDF via DSS
- audit log locale

## Limiti attuali
- la firma visibile su coordinate PDF non Ã¨ ancora agganciata
- la qualifica QES dipende dal certificato e dalla catena di trust reale
- per la qualifica piena con Trusted Lists UE/AgID va esteso `CommonCertificateVerifier` con TL/LOTL

## Configurazione
Apri:

`signer-core\src\main\resources\application.yml`

e imposta uno di questi mode:

- `MSCAPI` per Windows certificate store / smart card middleware CAPI
- `PKCS11` per token USB / smart card con DLL PKCS#11
- `PKCS12` per file `.p12` o `.pfx`

## Avvio
```powershell
cd C:\Gene1799LegalSign
.\scripts\start-dev.ps1
```

## Build backend
```powershell
cd C:\Gene1799LegalSign\signer-core
mvn clean package
```
