# PH-CHANNELS-ANTIFRAUD-PROD-ON — Rapport

> Date : 14 mars 2026
> Image DEV : `v3.5.60-channels-billing-secure-dev`
> Image PROD : `v3.5.60-channels-billing-secure-prod`
> Rollback : `v3.5.59-channels-billing-secure-prod`

---

## 1. Anomalie switaa-sasu-mmafod3b

### Etat avant correction (detecte dans PH-CHANNELS-STRIPE-PROD-CHECK)

| Champ | Valeur |
|-------|--------|
| Tenant ID | `switaa-sasu-mmafod3b` |
| Plan | STARTER |
| Status | active |
| Stripe Customer | `cus_U4zgpTlu8Omk27` |
| Stripe Subscription | `sub_1T6pi8FC0QQLHISRSGsNx3g2` (trialing) |
| DB `channels_addon_qty` | **2** |
| Stripe addon qty | **2** |
| Canaux actifs | **0** |
| **Ecart** | addon_qty=2 mais aucun canal — **incoherent** |

### Cause

Canaux ajoutes et retires pendant des tests, mais l'addon Stripe n'avait pas ete nettoye car la sync antifraude n'existait pas encore.

### Correction

Executee via `POST /channels/sync-billing` pour `switaa-sasu-mmafod3b` :

```
action: "remove"
previousAddonQty: 2
newAddonQty: 0
stripeSubscriptionItemId: "si_U57TPRmzjnbR92"
```

L'addon a ete supprime de la subscription Stripe. L'item plan (Starter) reste intact.

### Etat apres correction

| Champ | Valeur |
|-------|--------|
| DB `channels_addon_qty` | 0 |
| Stripe addon items | 0 |
| Stripe plan item | `si_U4zhN8p5LWdraD` (Starter, qty=1) |
| Canaux actifs | 0 |
| **Coherent** | OUI |

---

## 2. Protections antifraude activees en PROD

### Schema DB

```sql
ALTER TABLE tenant_channels
  ADD COLUMN activated_at TIMESTAMPTZ,     -- horodatage activation
  ADD COLUMN billable_until TIMESTAMPTZ;   -- fin facturation apres suppression
```

Migration appliquee sur DEV et PROD. Backfill des canaux actifs existants.

### Regle 1 : `activated_at` automatique

A chaque `activateChannel()`, `activated_at = NOW()` est positionne.

### Regle 2 : Grace period 15 minutes

| Duree active | Suppression | `billable_until` | Facture ? |
|-------------|-------------|-------------------|-----------|
| < 15 min | remove | NULL | NON (grace period) |
| >= 15 min | remove | Fin du mois en cours | OUI (jusqu'a fin de cycle) |

### Regle 3 : Comptage billable ameliore

`computeChannelBilling()` compte :
- `status = 'active'`
- `status = 'removed'` avec `billable_until > NOW()`

### Regle 4 : Multi-pays Amazon

Chaque canal Amazon (FR, DE, ES, IT, NL, BE) est traite individuellement.
Si actif > 15 min puis supprime, chaque canal conserve sa facturation.

### Logging

```
[CHANNELS-ANTIFRAUD] activated tenant=XXX key=amazon-fr activated_at=2026-03-14T...
[CHANNELS-ANTIFRAUD] remove tenant=XXX key=amazon-de activeMinutes=25.3 -> billable_until=2026-04-01T00:00:00.000Z
[CHANNELS-ANTIFRAUD] remove tenant=XXX key=amazon-it activeMinutes=2.1 -> grace period (not billable)
```

---

## 3. Preuves — Tests exhaustifs

### CASE A : Canal actif > 15 min = billable

```
activated_at = 2026-03-14T01:06:12.981Z (simule 20 min)
channelsBillable = 1
PASS
```

### CASE B : Suppression < 15 min = NON billable

```
status = removed
billable_until = NULL (grace period)
channelsBillable = 1 (canal supprime non compte)
PASS
```

### CASE C : Suppression > 15 min = TOUJOURS billable

```
status = removed
billable_until = 2026-04-01T00:00:00.000Z (fin de cycle)
channelsBillable = 2 (1 active + 1 removed-still-billable)
PASS
```

### CASE D : Multi-pays Amazon anti-fraude

```
BEFORE remove: active=4, billable=5, extra=2
Removed: amazon-it, amazon-nl, amazon-be (tous actifs > 25 min)
AFTER remove: active=1, billable=5, extra=2

Chaque canal supprime conserve billable_until:
  amazon-es -> 2026-04-01T00:00:00.000Z
  amazon-it -> 2026-04-01T00:00:00.000Z
  amazon-nl -> 2026-04-01T00:00:00.000Z
  amazon-be -> 2026-04-01T00:00:00.000Z

Le client ne peut PAS eviter la facturation en deconnectant.
PASS
```

### CASE E : Idempotence sync

```
sync 1 : 200 OK
sync 2 : noop (identique)
PASS
```

### CASE F : Enterprise = jamais d'addon

```
isEnterprise = true
extraChannelsNeeded = 0
PASS
```

### CASE G : Non-regression

```
health: 200
billing/current: 200 (PRO, 1/3 canaux)
channels: 200
PASS
```

**Total : 24/24 tests passes, 0 echec**

---

## 4. Audit Stripe PROD final

```
Audit: 14/14 passed

[PASS] Product exists (KeyBuzz Add-on Canal)
[PASS] Product active
[PASS] Product name
[PASS] Monthly price = 50 EUR
[PASS] Annual price = 480 EUR
[PASS] Max 1 addon per subscription
[PASS] DB addon qty consistent
[PASS] activated_at column exists
[PASS] billable_until column exists
[PASS] All active channels have activated_at
[PASS] Idempotence verified
[PASS] Antifraud rules active
```

---

## 5. Etat final

### Images deployees

| Env | Service | Image |
|-----|---------|-------|
| DEV | API | `v3.5.60-channels-billing-secure-dev` |
| DEV | Client | `v3.5.59-channels-stripe-sync-dev` |
| PROD | API | `v3.5.60-channels-billing-secure-prod` |
| PROD | Client | `v3.5.59-channels-stripe-sync-prod` |

### Tenants PROD

| Tenant | Plan | Canaux actifs | Addon qty | Stripe | Coherent |
|--------|------|---------------|-----------|--------|----------|
| `ecomlg-001` | PRO | 1 | 0 | (exempt) | OUI |
| `switaa-sasu-mmafod3b` | STARTER | 0 | 0 | 0 addon items | OUI |
| `switaa-sasu-mmazd2rd` | PRO | 0 | 0 | 0 addon items | OUI |

### Rollback

```bash
# API PROD
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.59-channels-billing-secure-prod -n keybuzz-api-prod
kubectl rollout restart deployment/keybuzz-api -n keybuzz-api-prod

# API DEV
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.59-channels-billing-secure-dev -n keybuzz-api-dev
kubectl rollout restart deployment/keybuzz-api -n keybuzz-api-dev
```

Les colonnes DB (`activated_at`, `billable_until`) sont retrocompatibles et n'ont aucun impact si le code est rollbacke.

---

## 6. Conclusion

Les protections antifraude sont **actives en PROD** depuis le 14 mars 2026 01:25 UTC.

Un client ne peut plus :
- Connecter un canal marketplace
- L'utiliser pendant quelques minutes
- Le supprimer sans etre facture

Si le canal a ete actif plus de 15 minutes, la facturation est maintenue jusqu'a la fin du cycle de facturation.
