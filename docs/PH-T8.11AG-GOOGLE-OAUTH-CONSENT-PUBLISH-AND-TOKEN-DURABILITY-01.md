# PH-T8.11AG-GOOGLE-OAUTH-CONSENT-PUBLISH-AND-TOKEN-DURABILITY-01 — TERMINÉ

**Verdict : GO**

| Clé | Valeur |
|---|---|
| Phase | PH-T8.11AG |
| Objectif | Sécuriser la durabilité du refresh token Google Ads OAuth |
| Type | Config externe + secret safety + sync validation |
| Date | 2026-04-28 |
| Auteur | Agent Cursor |
| Linear | KEY-220 (fermable), KEY-194 (confirmé) |
| Rapport | `keybuzz-infra/docs/PH-T8.11AG-GOOGLE-OAUTH-CONSENT-PUBLISH-AND-TOKEN-DURABILITY-01.md` |

---

## Résumé

L'écran de consentement OAuth Google Cloud est **déjà publié ("En production")**. Le refresh token est **durable** et n'expirera pas après 7 jours. Aucune action corrective n'était nécessaire.

Le sync Google Ads PROD a été revalidé avec succès (HTTP 200, 2 rows, £0.0628 GBP) confirmant que le token fonctionne à T+24h de sa création.

---

## ÉTAPE 0 — Préflight

| Surface | Attendu | Constaté | Verdict |
|---|---|---|---|
| Secret DEV `keybuzz-google-ads` | Existe | ✅ Existe | PASS |
| Secret PROD `keybuzz-google-ads` | Existe | ✅ Existe | PASS |
| Pod PROD | Running 1/1 | ✅ `keybuzz-api-99f8f9747-89fnj`, 0 restarts | PASS |
| Image PROD | `v3.5.123-linkedin-capi-native-prod` | ✅ Inchangée | PASS |
| Env PROD | 4/4 non-vides | ✅ 22/71/35/103 chars | PASS |
| Dernier sync (PH-T8.11AF) | last_error=null | ✅ `2026-04-28T20:34:37Z`, 2 rows | PASS |

---

## ÉTAPE 1 — Audit OAuth Consent Screen

### Accès

- **Projet GCP** : `KeyBuzz-Intelligence` (ID: `keybuzz-intelligence`)
- **Compte** : `keybuzz.pro@gmail.com` (KeyBuzz Consulting)
- **URL** : `https://console.cloud.google.com/auth/audience?project=keybuzz-intelligence`

### Résultats

| Champ | Valeur | Impact |
|---|---|---|
| **État de la publication** | **En production** | Token durable, pas d'expiration 7 jours |
| **Type d'utilisateur** | Externe | Accessible à tout compte Google |
| **Limite utilisateurs OAuth** | 1/100 | Suffisant pour API server-to-server |
| **App validation** | Non validée (banner warning) | Limite 100 users, pas bloquant pour notre usage |
| **Bouton "Revenir au mode test"** | Visible | Confirme le statut "En production" |
| **Bouton "Rendre interne"** | Visible | Option disponible mais non nécessaire |

### Conclusion OAuth

L'app OAuth est **publiée** depuis sa configuration initiale. La crainte d'expiration du refresh token après 7 jours était **infondée** car cette limitation ne s'applique qu'aux apps en mode **Testing**.

Pour les apps **"En production"** :
- Les refresh tokens sont durables (pas d'expiration automatique)
- Le token n'expire que si : l'utilisateur révoque l'accès, l'app change de scopes, le compte est désactivé, ou 6 mois d'inactivité (politique Google 2024+)
- Notre sync automatique prévient l'inactivité

---

## ÉTAPE 2 — Décision

**Cas A — Déjà Published / In production** ✅

- Token durable confirmé
- Aucune modification du consent screen nécessaire
- Aucune régénération de token nécessaire
- Passage direct à la validation sync

---

## ÉTAPE 3/4 — Aucune action requise

Aucune publication ni régénération de token n'était nécessaire. Le consent screen est déjà en production et le token existant est valide.

---

## ÉTAPE 5 — Validation Sync Google PROD

### Sync exécuté

```
POST /ad-accounts/1d813de7-5c9b-4c98-95fe-66f082c874bc/sync
Status: 200
```

| Check | Attendu | Résultat |
|---|---|---|
| HTTP status | 200 | ✅ 200 |
| sync | completed | ✅ completed |
| rows_upserted | ≥ 1 | ✅ 2 |
| total_spend | > 0 | ✅ £0.0628 GBP |
| last_error | null | ✅ null |
| last_sync_at | mis à jour | ✅ `2026-04-28T20:50:06.360Z` |
| Auth error | absent | ✅ Aucune erreur d'auth |

### Données Google actuelles

| Date | Campagne | Spend | Impressions | Clicks |
|---|---|---|---|---|
| 2026-04-28 | `kb-google-search-awareness-fr-q2` | £0.0228 | 223 | 1 |
| 2026-04-28 | `kb-google-youtube-awareness-fr-q2` | £0.0400 | 4 | 0 |

### Metrics API

```
GET /metrics/overview — Status 200
  meta: spend=445.2 GBP, impressions=45374, clicks=892
  google: spend=0.0628 GBP, impressions=227, clicks=1
```

---

## ÉTAPE 6 — Non-régression

| Check | Résultat |
|---|---|
| API health PROD | `{"status":"ok"}` ✅ |
| API PROD image | `v3.5.123-linkedin-capi-native-prod` (inchangée) ✅ |
| API DEV image | `v3.5.123-linkedin-capi-native-dev` (inchangée) ✅ |
| Client PROD image | `v3.5.125-register-console-cleanup-prod` (inchangée) ✅ |
| Meta spend | 16 rows, £445.20 (intact) ✅ |
| Google spend | 2 rows, £0.0628 (intact) ✅ |
| CAPI Meta/TikTok/LinkedIn | Inchangés ✅ |
| GA4 conversions | Inchangées ✅ |
| Secrets exposés | Aucun ✅ |
| Code change | Aucun ✅ |
| Build/deploy image | Aucun ✅ |
| Manifest plain text | Aucun ✅ |

---

## ÉTAPE 7 — Linear

### KEY-220 — Google OAuth Token Durability

**Fermable** :
- ✅ OAuth consent screen : "En production" (Published)
- ✅ Refresh token durable confirmé
- ✅ Sync PROD validé avec token actuel
- ✅ Aucun secret exposé
- ✅ Aucune action corrective nécessaire

### KEY-194 — Google Ads Spend Sync

Mise à jour : token durability confirmée par PH-T8.11AG. Le risque d'expiration à 7 jours est levé.

---

## Recommandations futures

### App validation (non urgent)

L'app OAuth n'est pas "validée" par Google (banner warning), ce qui impose une limite de 100 utilisateurs OAuth. Pour notre cas d'usage (1 seul utilisateur server-to-server), cette limite est largement suffisante. Une validation Google ne serait utile que si l'app devait servir à des utilisateurs finaux multiples.

### Token refresh proactif

Bien que le token soit durable, il est recommandé de :
- Monitorer les erreurs `UNAUTHENTICATED` ou `INVALID_GRANT` dans les logs de sync
- Si détectée : régénérer le token via OAuth Playground et mettre à jour le secret K8s
- Le sync automatique (si configuré en CronJob) préviendra l'inactivité de 6 mois

---

## Artefacts

| Élément | Valeur |
|---|---|
| Rapport | `keybuzz-infra/docs/PH-T8.11AG-GOOGLE-OAUTH-CONSENT-PUBLISH-AND-TOKEN-DURABILITY-01.md` |
| OAuth status | **En production** (Published, External) |
| Token status | Durable, validé à T+24h |
| Sync PROD | 200 OK, 2 rows, £0.0628 GBP, `2026-04-28T20:50:06Z` |
| Secret modifié | Non — aucune modification |
| Image modifiée | Non — aucune modification |
| Manifest modifié | Non — aucune modification |

---

## VERDICT

**GOOGLE ADS OAUTH TOKEN DURABILITY SECURED — CONSENT SCREEN IN PRODUCTION (NOT TESTING) — PROD SYNC VALIDATED — NO SECRET EXPOSURE — NO TOKEN REGENERATION NEEDED — NO TRACKING DRIFT**
