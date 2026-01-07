# PH11-MAIL-REALITY-CHECK-01 — Audit Réel Mail

**Date**: 2026-01-07  
**Status**: ⚠️ PROBLÈMES CRITIQUES IDENTIFIÉS

---

## 📋 Résumé Exécutif

| Composant | Status | Preuve |
|-----------|--------|--------|
| Vault (vault-01) | ❌ ARRÊTÉ | `vault.service: Failed` |
| keybuzz-backend | ✅ Actif | `systemctl status` OK sur backend-01 |
| Service outbound email | ✅ Implémenté | `outboundEmail.service.ts` |
| nodemailer (SMTP) | ✅ Installé | `package.json` |
| @aws-sdk/client-ses | ✅ Installé | `package.json` |
| SES fallback | ⚠️ STUB | Fait fallback vers SMTP |
| DB write | ❌ **READ-ONLY BUG** | Logs actifs |

**Conclusion : MAIL CASSÉ pour raison DATABASE_URL pointe vers replica**

---

## 1. Vault — État réel

### Serveur vault-01 (10.0.0.150)
```
vault.service: Failed (Result: exit-code)
Active: failed since Mon 2025-12-15
Cause: permission denied on /var/log/vault/vault.log
```

**Status**: ❌ ARRÊTÉ depuis 3 semaines

### Impact
- Impossible de récupérer les secrets SMTP/SES depuis Vault
- Le backend doit utiliser des variables d'environnement locales

---

## 2. Service Outbound Email — Localisation réelle

### Repo correct
- **Repo**: `keybuzz-backend` (PAS keybuzz-api)
- **Serveur**: `backend-01` (10.0.0.250)
- **Fichier**: `src/modules/outbound/outboundEmail.service.ts`

### Dépendances installées
```json
{
  "@aws-sdk/client-ses": "^3.948.0",
  "nodemailer": "...",
  "@prisma/client": "^6.3.0"
}
```

### Code implémenté
```typescript
// SMTP via nodemailer ✅
function getSmtpTransporter(): Transporter {
  smtpTransporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || "localhost",
    port: parseInt(process.env.SMTP_PORT || "587"),
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
  });
}

// SES ⚠️ STUB
async function sendViaSES(...) {
  console.log("[OutboundEmail] SES not implemented, falling back to SMTP");
  await sendViaSMTP(email);  // Fallback direct
}
```

---

## 3. Problème CRITIQUE — Read-Only Transaction

### Logs backend-01 (07 janvier 2026)
```
PostgresError { 
  code: "25006", 
  message: "cannot execute UPDATE in a read-only transaction"
}
```

### Cause identifiée
```
DATABASE_URL="postgresql://kb_backend:***@10.0.0.122:5432/keybuzz_backend"
                                        ^^^^^^^^^^^^
                                        db-postgres-03 = REPLICA !
```

### Solution requise
Changer DATABASE_URL vers :
- HAProxy write (port 5432 write) : `10.0.0.10:5432`
- Ou leader direct : `10.0.0.120:5432` (db-postgres-01)

---

## 4. Variables d'environnement requises

### SMTP (sur backend-01)
| Variable | Valeur attendue | Status |
|----------|-----------------|--------|
| SMTP_HOST | mail-core-01 (10.0.0.160) | ❓ Non vérifié |
| SMTP_PORT | 587 | ❓ Non vérifié |
| SMTP_USER | postmaster@keybuzz.io | ❓ Non vérifié |
| SMTP_PASS | (depuis Vault) | ❌ Vault arrêté |
| EMAIL_PROVIDER | smtp | Par défaut |

### SES (optionnel)
| Variable | Status |
|----------|--------|
| AWS_SES_ACCESS_KEY | ❌ Non configuré |
| AWS_SES_SECRET_KEY | ❌ Non configuré |
| AWS_SES_REGION | ❌ Non configuré |

---

## 5. Conclusion

### État actuel
- **SMTP** : Code présent mais non testable (DB cassée)
- **SES** : Code stub (fallback vers SMTP)
- **DB** : ❌ BLOQUANT — read-only transaction

### Actions requises (par priorité)

1. **[CRITIQUE]** Corriger DATABASE_URL sur backend-01
   ```bash
   # Sur backend-01
   sed -i 's/10.0.0.122/10.0.0.10/' /opt/keybuzz/keybuzz-backend/.env
   systemctl restart keybuzz-backend
   ```

2. **[HAUTE]** Redémarrer Vault sur vault-01
   ```bash
   # Sur vault-01
   mkdir -p /var/log/vault && chown vault:vault /var/log/vault
   systemctl start vault
   ```

3. **[MOYENNE]** Configurer variables SMTP sur backend-01

4. **[BASSE]** Implémenter réellement SES (actuellement stub)

---

## Verdict Final

| Question | Réponse |
|----------|---------|
| MAIL OK ? | ❌ NON |
| MAIL OK sauf X ? | ❌ NON |
| MAIL BLOQUANT ? | ✅ **OUI — DB read-only** |

Le mail ne peut pas fonctionner tant que le problème `read-only transaction` n'est pas corrigé.

---

**Audit terminé** ✅
