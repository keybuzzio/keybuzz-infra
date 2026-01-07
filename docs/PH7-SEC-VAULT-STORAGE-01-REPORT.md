# PH7-SEC-VAULT-STORAGE-01 — Correction Storage Path Vault

**Date**: 2026-01-07  
**Serveur**: vault-01 (10.0.0.150)  
**Status**: ✅ **CORRIGÉ ET FONCTIONNEL**

---

## 📋 Résumé

| Élément | Status |
|---------|--------|
| Vault initialisé | ✅ Oui |
| Vault unsealed | ✅ Oui |
| Storage path corrigé | ✅ `/data/vault/storage` |
| Backup créé | ✅ 9.4 MB |
| Secrets accessibles | ✅ Oui |
| Applications impactées | ❌ Aucune |

---

## 1. Problème Initial

### Configuration incohérente détectée

| Fichier | Path configuré | Path réel des données |
|---------|----------------|----------------------|
| `/etc/vault.d/vault.hcl` | `/opt/vault/data` | `/data/vault/storage` |

Cette incohérence empêchait Vault de démarrer correctement avec les données existantes.

---

## 2. État AVANT Correction

```
Vault Status (avant):
- Initialized: false (avec mauvais path)
- Sealed: true
- Storage Type: file
```

### Config AVANT (`/etc/vault.d/vault.hcl`)
```hcl
storage "file" {
  path = "/opt/vault/data"  # ← INCORRECT
}
```

### Données réelles
```
/data/vault/storage/
├── auth/
├── core/
├── logical/
└── sys/
```

---

## 3. Correction Appliquée

### Config APRÈS (`/etc/vault.d/vault.hcl`)
```hcl
ui = true

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/etc/vault.d/tls/vault.crt"
  tls_key_file  = "/etc/vault.d/tls/vault.key"
  tls_disable   = false
}

storage "file" {
  path = "/data/vault/storage"  # ← CORRIGÉ
}

disable_mlock = true
```

---

## 4. Backup

| Élément | Valeur |
|---------|--------|
| Fichier | `/root/vault-storage-backup-2026-01-07-131721.tar.gz` |
| Taille | 9.4 MB |
| Contenu | `/data/vault/storage` complet |
| Config backup | `/root/vault.hcl.backup-2026-01-07-*` |

---

## 5. État APRÈS Correction

```
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.21.1
Build Date      2025-11-18T13:04:32Z
Storage Type    file
Cluster Name    keybuzz-vault-cluster
Cluster ID      d8f10f65-dd3d-aeaa-0e1c-ae745f53a7f8
HA Enabled      false
```

### Secrets Engines
```
Path          Type         Description
----          ----         -----------
cubbyhole/    cubbyhole    per-token private secret storage
database/     database     n/a
identity/     identity     identity store
secret/       kv           n/a
sys/          system       system endpoints
```

### Secrets Présents (clés uniquement)
```
secret/keybuzz/
├── ai/
├── amazon_spapi/
├── hetzner/
├── litellm/
├── observability/
├── redis
├── ses
├── smtp
└── tenants/
```

### Auth Methods
```
Path           Type          Description
----           ----          -----------
kubernetes/    kubernetes    n/a
token/         token         token based credentials
```

---

## 6. Vérifications

| Check | Résultat |
|-------|----------|
| `vault status` | ✅ Initialized=true, Sealed=false |
| `vault secrets list` | ✅ 5 engines |
| `vault list secret/keybuzz/` | ✅ 9 secrets paths |
| `vault auth list` | ✅ kubernetes + token |
| Applications | ✅ Aucun restart requis |

---

## 7. Procédure de Rollback (si nécessaire)

```bash
# 1. Arrêter Vault
systemctl stop vault

# 2. Restaurer le backup
cd /
tar -xzf /root/vault-storage-backup-2026-01-07-131721.tar.gz

# 3. Restaurer la config
cp /root/vault.hcl.backup-* /etc/vault.d/vault.hcl

# 4. Redémarrer
systemctl start vault

# 5. Unseal si nécessaire
vault operator unseal <UNSEAL_KEY>
```

---

## 8. Recommandations

### Immédiat
- ✅ Vault fonctionne correctement
- ✅ Aucune action requise

### Moyen terme
| Action | Priorité |
|--------|----------|
| Configurer auto-unseal (AWS KMS ou autre) | Haute |
| Mettre Vault en service systemd avec restart auto | Moyenne |
| Ajouter monitoring Vault (Prometheus) | Moyenne |
| Backup automatique quotidien | Haute |

### Service systemd recommandé
```ini
# /etc/systemd/system/vault.service
[Unit]
Description=HashiCorp Vault
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=vault
Group=vault
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

---

## 9. Logs

| Fichier | Contenu |
|---------|---------|
| `/opt/keybuzz/logs/ph7/ph7-sec-vault-storage-01/00_start.txt` | Timestamp début |
| `/opt/keybuzz/logs/ph7/ph7-sec-vault-storage-01/01_end.txt` | Timestamp fin |

---

**Correction terminée avec succès** ✅  
**Aucune perte de données**  
**Aucun impact applicatif**
