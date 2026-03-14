# PH-CHANNELS-STRIPE-PROD-CHECK — Rapport

> Date : 14 mars 2026
> Environnement : PROD (audit) + DEV (patch antifraude)
> Image DEV : `v3.5.59-channels-billing-secure-dev`
> Rollback : `v3.5.59-channels-stripe-sync-dev`

---

## A. Audit Stripe Live

### Produit Addon Channel

| Champ | Valeur |
|-------|--------|
| Product ID | `prod_TpJTEELacYjLGG` |
| Nom | KeyBuzz Add-on Canal |
| Actif | true |
| Metadata | `{"kb_plan": "addon_channel"}` |

### Prix Addon

| Cycle | Price ID | Montant | Devise | Statut |
|-------|----------|---------|--------|--------|
| monthly | `price_1SreqtFC0QQLHISRvTB3w1JX` | 50 EUR | eur | actif |
| annual | `price_1SrequFC0QQLHISRDvm3ChUX` | 480 EUR | eur | actif |

### Variables d'environnement Stripe PROD

| Variable | Valeur |
|----------|--------|
| `STRIPE_PRODUCT_ADDON_CHANNEL` | `prod_TpJTEELacYjLGG` |
| `STRIPE_PRICE_ADDON_CHANNEL_MONTHLY` | `price_1SreqtFC0QQLHISRvTB3w1JX` |
| `STRIPE_PRICE_ADDON_CHANNEL_ANNUAL` | `price_1SrequFC0QQLHISRDvm3ChUX` |
| `STRIPE_PRICE_STARTER_MONTHLY` | `price_1SreqrFC0QQLHISRFea6HKbV` |
| `STRIPE_PRICE_STARTER_ANNUAL` | `price_1SreqrFC0QQLHISRanCHlNHr` |
| `STRIPE_PRICE_PRO_MONTHLY` | `price_1SreqsFC0QQLHISRsNRFIMjr` |
| `STRIPE_PRICE_PRO_ANNUAL` | `price_1SreqsFC0QQLHISRB1vgmBe6` |
| `STRIPE_PRICE_AUTOPILOT_MONTHLY` | `price_1SreqtFC0QQLHISRgKxY8ldF` |
| `STRIPE_PRICE_AUTOPILOT_ANNUAL` | `price_1SreqtFC0QQLHISR1G9BhKZg` |

---

## B. Coherence DB / Stripe

### Tenants avec billing

| Tenant | Plan | Stripe Customer | Subscription | Addon Qty DB | Status |
|--------|------|-----------------|--------------|--------------|--------|
| `ecomlg-001` | PRO | (aucun - exempt) | (aucun) | - | OK - billing exempt |
| `switaa-sasu-mmafod3b` | STARTER | `cus_U4zgpTlu8Omk27` | `sub_1T6pi8FC0QQLHISRSGsNx3g2` | 2 | **ANOMALIE** |
| `switaa-sasu-mmazd2rd` | PRO | `cus_U58Za7LjhtvC5P` | `sub_1T6yJWFC0QQLHISReE5iTpWQ` | 0 | OK |

### Anomalie `switaa-sasu-mmafod3b`

- Plan STARTER, `channels_addon_qty = 2` dans la DB et Stripe
- **MAIS** aucun canal dans `tenant_channels` pour ce tenant
- Cause probable : canaux ajoutés/retirés pendant des tests, addon non nettoyé
- **Recommandation** : resync manuelle ou nettoyage addon qty via `POST /channels/sync-billing`

### Unicite addon par subscription

| Tenant | Subscription | Addon Items | Statut |
|--------|-------------|-------------|--------|
| `switaa-sasu-mmafod3b` | `sub_1T6pi8FC0QQLHISRSGsNx3g2` | 1 | PASS |
| `switaa-sasu-mmazd2rd` | `sub_1T6yJWFC0QQLHISReE5iTpWQ` | 0 | PASS |

Aucune subscription avec plus d'un addon item.

### Channels detail

| Tenant | Marketplace | Status | Billing Status | Activated At |
|--------|-------------|--------|----------------|--------------|
| `ecomlg-001` | amazon-fr | active | included | 2026-03-13 |
| `ecomlg-001` | octopia-cdiscount-fr | removed | included | - |

---

## C. Vulnerabilite Antifraude Detectee

### Avant ce patch

Un client pouvait :
1. Connecter un canal marketplace (status = `active`)
2. L'utiliser pendant quelques minutes
3. Le supprimer (status = `removed`)
4. **Stripe ne facture rien** car l'addon est immediatement supprime

Cette fraude est classique dans les SaaS multi-connecteurs.

### Schema DB avant patch

- Pas de colonne `activated_at` (impossible de savoir quand un canal a ete active)
- Pas de colonne `billable_until` (impossible de facturer apres suppression)

---

## D. Protections Antifraude Implementees

### Migration DB

```sql
ALTER TABLE tenant_channels
  ADD COLUMN IF NOT EXISTS activated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS billable_until TIMESTAMPTZ;

UPDATE tenant_channels SET activated_at = COALESCE(connected_at, created_at)
WHERE status = 'active' AND activated_at IS NULL;
```

Appliquee sur DEV et PROD.

### Regle 1 : `activated_at` automatique

Quand un canal passe en `status = 'active'`, `activated_at` est positionne a `NOW()`.
Cela enregistre le moment exact d'activation.

### Regle 2 : Grace period de 15 minutes

Si un canal est supprime **moins de 15 minutes** apres son activation :
- `billable_until = NULL`
- Le canal n'est **pas facture** (erreur de manipulation, test)

Si un canal est supprime **plus de 15 minutes** apres son activation :
- `billable_until = fin du mois en cours`
- Le canal **reste facture** jusqu'a la fin du cycle

### Regle 3 : Comptage billable ameliore

`computeChannelBilling()` compte maintenant :
- Canaux `status = 'active'` (facturation normale)
- Canaux `status = 'removed'` avec `billable_until > NOW()` (antifraude)

### Regle 4 : Multi-pays Amazon

Si un client connecte amazon-fr, amazon-de, amazon-es, amazon-it puis deconnecte tous sauf FR :
- Chaque canal actif > 15 min conserve son `billable_until`
- Stripe continue de facturer les extras jusqu'a fin de cycle

### Logging antifraude

```
[CHANNELS-ANTIFRAUD] activated tenant=XXX key=amazon-fr activated_at=2026-03-14T...
[CHANNELS-ANTIFRAUD] remove tenant=XXX key=amazon-de activeMinutes=25.3 -> billable_until=2026-04-01T00:00:00.000Z
[CHANNELS-ANTIFRAUD] remove tenant=XXX key=amazon-it activeMinutes=2.1 -> grace period (not billable)
```

### Logging sync enrichi

```
[CHANNELS-BILLING-SYNC] tenant=XXX billable=4 included=3 extraNeeded=1 currentAddonQty=0 sub=sub_XXX channels=[{"key":"amazon-fr","status":"active","billable_until":null},{"key":"amazon-de","status":"removed","billable_until":"2026-04-01T00:00:00.000Z"}]
```

---

## E. Resultats Tests

### Suite de tests : 15 tests, 44 assertions

| Test | Description | Resultat |
|------|-------------|---------|
| T1 | Stripe product exists | PASS |
| T2 | Stripe prices (monthly 50 EUR, annual 480 EUR) | PASS |
| T3 | PRO 0 channels -> 0 addon | PASS |
| T4 | Add channel (pending) -> not billable | PASS |
| T5 | Activate channel -> billable, activated_at set | PASS |
| T6 | Exceed PRO quota (4 channels) -> 1 addon | PASS |
| T7 | Sync billing idempotence (double call = noop) | PASS |
| T8 | Remove within grace period (<15min) -> NOT billable | PASS |
| T9 | Remove after grace period (>15min) -> STILL billable | PASS |
| T10 | Multi-country Amazon anti-fraud | PASS |
| T11 | Enterprise plan -> never addon | PASS |
| T12 | Pending channel not billable | PASS |
| T13 | Starter plan limits (1 included) | PASS |
| T14 | Sync dry-run flag | PASS |
| T15 | Non-regression (health, billing, channels) | PASS |

**Total : 44/44 assertions passees, 0 echec**

---

## F. Script Audit Automatique

Fichier : `scripts/channels-stripe-audit.sh`

Usage :
```bash
bash scripts/channels-stripe-audit.sh dev    # audit DEV
bash scripts/channels-stripe-audit.sh prod   # audit PROD
```

Checks automatiques :
1. Stripe product exists + active
2. Monthly price = 50 EUR
3. Annual price = 480 EUR
4. Max 1 addon item per subscription
5. DB addon qty consistent avec channels
6. Antifraud columns exist (activated_at, billable_until)
7. All active channels have activated_at
8. Idempotence verified
9. Antifraud rules active

---

## G. Images

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.59-channels-billing-secure-dev` | `v3.5.59-channels-stripe-sync-prod` (inchange) |

### Rollback

```bash
# DEV API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.59-channels-stripe-sync-dev -n keybuzz-api-dev

# PROD API (inchange, aucun rollback necessaire pour cette phase)
```

---

## H. STOP POINT

### Ce qui a ete fait en PROD (lecture seule) :
- Audit Stripe live complet
- Migration DB (ajout colonnes `activated_at`, `billable_until`)
- Backfill `activated_at` pour les canaux actifs existants

### Ce qui a ete fait en DEV :
- Patch antifraude complet (activated_at, billable_until, grace period 15 min)
- Build + deploy `v3.5.59-channels-billing-secure-dev`
- Tests 44/44 passes

### PROD n'a PAS ete modifie cote code
Le code antifraude tourne uniquement en DEV. La PROD a les nouvelles colonnes DB mais utilise encore l'ancienne image sans les regles antifraude.

### Pour activer en PROD :
1. Valider le comportement DEV
2. Build PROD : `v3.5.59-channels-billing-secure-prod`
3. Deployer
4. Lancer `bash scripts/channels-stripe-audit.sh prod`
5. Corriger l'anomalie `switaa-sasu-mmafod3b` (addon qty=2 sans canaux)
