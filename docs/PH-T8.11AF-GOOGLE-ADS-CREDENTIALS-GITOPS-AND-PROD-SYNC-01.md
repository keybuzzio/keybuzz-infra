# PH-T8.11AF-GOOGLE-ADS-CREDENTIALS-GITOPS-AND-PROD-SYNC-01 — TERMINÉ

**Verdict : GO**

| Clé | Valeur |
|---|---|
| Phase | PH-T8.11AF |
| Objectif | Débloquer Google Spend/KPI en PROD sans code change |
| Type | Secrets GitOps + DB account + sync runtime |
| Date | 2026-04-28 |
| Auteur | Agent Cursor |
| Linear | KEY-194 (prêt à fermer) |
| Rapport | `keybuzz-infra/docs/PH-T8.11AF-GOOGLE-ADS-CREDENTIALS-GITOPS-AND-PROD-SYNC-01.md` |

---

## Résumé

Google Ads Spend/KPI est maintenant **opérationnel en PROD**.

- Secret K8s `keybuzz-google-ads` créé en DEV et PROD (4 clés chacun)
- Manifests GitOps DEV/PROD mis à jour avec `secretKeyRef` (plus de credentials en plain text)
- Drift DEV corrigé (`kubectl replace` pour éliminer les values plain text)
- Compte Google `5947963982` enregistré en PROD DB
- Sync PROD exécuté : **2 rows réelles** importées (£0.0628 GBP)
- API `/metrics/overview` retourne Google + Meta par channel
- Aucun code change, aucun build image, aucune modification tracking

---

## ÉTAPE 0 — Préflight

| Repo | Branche | HEAD | Upstream | Dirty | Verdict |
|---|---|---|---|---|---|
| `keybuzz-infra` | `main` | `595196a` | `595196a` | ✅ clean | PASS |
| `keybuzz-api` (bastion) | `ph147.4/source-of-truth` | `d90e093` | — | ✅ 0 dirty | PASS |

---

## ÉTAPE 1 — Extraction credentials DEV

Credentials extraits depuis le deployment spec DEV (`keybuzz-api-dev`) sans exposition.

| Variable | Longueur |
|---|---|
| `GOOGLE_ADS_DEVELOPER_TOKEN` | 22 chars |
| `GOOGLE_ADS_CLIENT_ID` | 71 chars |
| `GOOGLE_ADS_CLIENT_SECRET` | 35 chars |
| `GOOGLE_ADS_REFRESH_TOKEN` | 103 chars |

Méthode : `kubectl get deployment -o jsonpath` + `grep` + longueur uniquement. Aucune valeur imprimée.

---

## ÉTAPES 2-3 — Secrets K8s

| Namespace | Secret | Keys | Verdict |
|---|---|---|---|
| `keybuzz-api-dev` | `keybuzz-google-ads` | 4 | ✅ Créé |
| `keybuzz-api-prod` | `keybuzz-google-ads` | 4 | ✅ Créé |

Méthode : `kubectl create secret generic --from-literal` (aucune valeur dans le rapport).
PROD utilise les mêmes credentials que DEV (même compte Google Ads, même OAuth app).

---

## ÉTAPE 4 — Manifests GitOps

| Manifest | Avant | Après | Verdict |
|---|---|---|---|
| `k8s/keybuzz-api-dev/deployment.yaml` | Aucune ref GOOGLE_ADS | 4x `secretKeyRef` via `keybuzz-google-ads` | ✅ |
| `k8s/keybuzz-api-prod/deployment.yaml` | Aucune ref GOOGLE_ADS | 4x `secretKeyRef` via `keybuzz-google-ads` | ✅ |

Aucune valeur plain text dans les manifests. Seul `secretKeyRef` est utilisé.

---

## ÉTAPE 5 — Commit/Push

| Élément | Valeur |
|---|---|
| Commit | `1fde06f` |
| Message | `PH-T8.11AF: configure Google Ads credentials via GitOps secrets DEV/PROD (KEY-194)` |
| Fichiers | `k8s/keybuzz-api-dev/deployment.yaml`, `k8s/keybuzz-api-prod/deployment.yaml` |
| Push | `595196a..1fde06f main -> main` ✅ |

---

## ÉTAPE 6 — Apply GitOps

### DEV
- `kubectl replace -f` utilisé (au lieu de `apply`) pour éliminer le drift plain text
- Le deployment spec avait des GOOGLE_ADS_* en `value:` (injectés via `kubectl set env` hors GitOps)
- `kubectl apply -f` échouait avec "may not be specified when value is not empty"
- `kubectl replace -f` remplace entièrement le deployment depuis le manifest → drift éliminé
- Annotation `last-applied-configuration` restaurée via `kubectl apply -f` post-replace

### PROD
- `kubectl apply -f` direct (aucun drift — nouvelles variables)
- Rollout réussi

| Namespace | Méthode | Rollout | Pod | Status |
|---|---|---|---|---|
| `keybuzz-api-dev` | `replace` + `apply` | ✅ `successfully rolled out` | `keybuzz-api-df7bc6699-vvl8p` → `keybuzz-api-...` | Running 1/1 |
| `keybuzz-api-prod` | `apply` | ✅ `successfully rolled out` | `keybuzz-api-99f8f9747-89fnj` | Running 1/1 |

### Vérification plain text éliminé

```
DEV:
  GOOGLE_ADS_DEVELOPER_TOKEN: value=False valueFrom=True
  GOOGLE_ADS_CLIENT_ID: value=False valueFrom=True
  GOOGLE_ADS_CLIENT_SECRET: value=False valueFrom=True
  GOOGLE_ADS_REFRESH_TOKEN: value=False valueFrom=True

PROD:
  GOOGLE_ADS_DEVELOPER_TOKEN: value=False valueFrom=True
  GOOGLE_ADS_CLIENT_ID: value=False valueFrom=True
  GOOGLE_ADS_CLIENT_SECRET: value=False valueFrom=True
  GOOGLE_ADS_REFRESH_TOKEN: value=False valueFrom=True
```

---

## ÉTAPE 7 — Credentials runtime

| Namespace | Secret exists | Env non-empty | Plain text absent | Verdict |
|---|---|---|---|---|
| `keybuzz-api-dev` | ✅ | ✅ 4/4 (22/71/35/103) | ✅ | PASS |
| `keybuzz-api-prod` | ✅ | ✅ 4/4 (22/71/35/103) | ✅ | PASS |

---

## ÉTAPE 8 — Compte Google PROD

| Élément | Valeur |
|---|---|
| Méthode | DB insert contrôlé (`ad_platform_accounts`) |
| UUID | `1d813de7-5c9b-4c98-95fe-66f082c874bc` |
| tenant_id | `keybuzz-consulting-mo9zndlk` |
| platform | `google` |
| account_id | `5947963982` |
| account_name | `KeyBuzz Google Ads` |
| currency | `GBP` |
| timezone | `Europe/Paris` |
| status | `active` |
| created_by | `system-ph-t8.11af-google-ads` |
| token_ref | `(not set)` — credentials via env vars |

Route officielle non utilisée (pas d'UI Admin pour créer un compte ad). Insert DB direct aligné sur le modèle Meta existant (`b8b89a18`, `created_by: system-migration-ph-t8.8a-prod`).

---

## ÉTAPE 9 — Sync Google PROD

```
POST /ad-accounts/1d813de7-5c9b-4c98-95fe-66f082c874bc/sync
Status: 200
```

| Élément | Valeur |
|---|---|
| sync | `completed` |
| period | 2026-03-29 → 2026-04-28 |
| rows_upserted | **2** |
| total_spend | **£0.0628 GBP** |

### Données synchronisées (réelles)

| Date | Campaign ID | Campaign Name | Spend | Impressions | Clicks |
|---|---|---|---|---|---|
| 2026-04-28 | `23794293252` | `kb-google-search-awareness-fr-q2` | £0.0228 | 223 | 1 |
| 2026-04-28 | `23804250643` | `kb-google-youtube-awareness-fr-q2` | £0.0400 | 4 | 0 |

### État post-sync

```json
{
  "last_sync_at": "2026-04-28T20:34:37.576Z",
  "last_error": null,
  "status": "active"
}
```

---

## ÉTAPE 10 — Validation Admin/Metrics

### API `/metrics/overview`

```json
{
  "spend": {
    "source": "ad_spend_tenant",
    "by_channel": [
      {"channel": "meta", "spend_raw": 445.20, "currency_raw": "GBP", "impressions": 45374, "clicks": 892},
      {"channel": "google", "spend_raw": 0.0628, "currency_raw": "GBP", "impressions": 227, "clicks": 1}
    ]
  }
}
```

| Page | Attendu | Résultat |
|---|---|---|
| `/metrics` | Google + Meta spend par channel | ✅ Google et Meta visibles |
| `/marketing/paid-channels` | Google connecté, spend réel | ✅ Via API spend data |
| `/marketing/ad-accounts` | Google + Meta listés | ✅ Deux comptes actifs |
| `/marketing/acquisition-playbook` | Pas de changement | ✅ Inchangé |

### API `/ad-accounts`

Retourne 2 comptes actifs :
- `google` / `5947963982` / `active` / last_sync `2026-04-28T20:34`
- `meta` / `1485150039295668` / `active` / last_sync `2026-04-23T09:01`

---

## ÉTAPE 11 — Non-régression

| Check | Résultat |
|---|---|
| API health PROD | `{"status":"ok"}` ✅ |
| API health DEV | Running 1/1, 0 restarts ✅ |
| Meta spend intact | 16 rows, £445.20 ✅ |
| CAPI Meta/TikTok/LinkedIn | Inchangés (pas de modification config) ✅ |
| GA4 conversions | Inchangées (pas de modification) ✅ |
| Image API PROD | `v3.5.123-linkedin-capi-native-prod` (inchangée) ✅ |
| Image API DEV | `v3.5.123-linkedin-capi-native-dev` (inchangée) ✅ |
| Image Client PROD | `v3.5.125-register-console-cleanup-prod` (inchangée) ✅ |
| Secrets exposés | ❌ Aucune valeur dans ce rapport ✅ |
| Code change | ❌ Aucun ✅ |
| Build image | ❌ Aucun ✅ |

---

## ÉTAPE 12 — Linear

### KEY-194 — Google Ads spend sync

**Prêt à fermer** :
- ✅ Secrets DEV/PROD propres (K8s secret, secretKeyRef)
- ✅ Manifests GitOps committés/pushés
- ✅ Compte Google PROD enregistré
- ✅ Sync Google PROD completed (2 rows réelles)
- ✅ Metrics API retourne Google spend
- ✅ Aucun secret exposé

### KEY-199 — Ad Accounts multi-plateforme

Situation : 2/4 plateformes avec spend data (Meta, Google). TikTok et LinkedIn n'ont pas de spend API intégrée. Pas de bloqueur immédiat.

---

## Risques et recommandations

### Refresh Token (P1)

Le refresh token Google Ads a été créé le 27 avril 2026. Si l'OAuth consent screen reste en mode **Testing** :
- Le token expire après **7 jours** (4 mai 2026)
- **Action requise** : publier l'OAuth consent screen sur Google Cloud Console, ou régénérer le token avant expiration

### Spend très faible

Le spend Google total est de £0.0628 (6 centimes). C'est cohérent avec le lancement récent des campagnes, mais vérifier que Google Ads distribue correctement le budget.

### Drift corrigé

Le drift DEV (credentials plain text via `kubectl set env`) a été éliminé par `kubectl replace`. Aucun credential en plain text ne subsiste dans les deployment specs.

---

## Artefacts

| Élément | Valeur |
|---|---|
| Infra commit | `1fde06f` |
| Secret DEV | `keybuzz-google-ads` (keybuzz-api-dev) |
| Secret PROD | `keybuzz-google-ads` (keybuzz-api-prod) |
| Compte Google PROD | `1d813de7-5c9b-4c98-95fe-66f082c874bc` |
| Sync date | 2026-04-28T20:34:37 UTC |
| Spend sync | 2 rows, £0.0628 GBP |
| Rollback | Retirer les 4 env vars GOOGLE_ADS des manifests, commit, apply |
| Rapport | `keybuzz-infra/docs/PH-T8.11AF-GOOGLE-ADS-CREDENTIALS-GITOPS-AND-PROD-SYNC-01.md` |

---

## VERDICT

**GOOGLE ADS CREDENTIALS GITOPS-CLEAN — PROD SECRET CONFIGURED — GOOGLE ACCOUNT REGISTERED — SYNC EXECUTED — PAID CHANNELS HONEST — NO SECRET EXPOSURE — NO TRACKING DRIFT**
