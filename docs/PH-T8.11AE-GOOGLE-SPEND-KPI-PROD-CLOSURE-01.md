# PH-T8.11AE-GOOGLE-SPEND-KPI-PROD-CLOSURE-01 — TERMINÉ

**Verdict : NO GO — Code Google Ads spend sync présent en PROD, mais credentials ABSENTS. STOP business/config.**

**KEY-194** | Date : 2026-04-28

---

## 1. Résumé exécutif

L'audit PROD complet de Google Ads Spend/KPI révèle que :

- Le **code** Google Ads spend sync (module `google-ads.js`, routes `ad-accounts`) **est déjà compilé et présent** dans l'image PROD `v3.5.123-linkedin-capi-native-prod`
- Les **credentials** Google Ads (4 env vars `GOOGLE_ADS_*`) **sont ABSENTS** du namespace PROD
- Aucun secret K8s `keybuzz-google-ads` n'existe dans `keybuzz-api-prod`
- Le manifest GitOps PROD (`deployment.yaml`) ne référence aucune variable Google Ads
- La DB PROD ne contient **aucun compte Google** dans `ad_platform_accounts`
- 0 rows Google dans `ad_spend_tenant`

**Le bloqueur est infrastructure/config**, pas code. Aucun build ou deploy n'est nécessaire.

---

## 2. Préflight

| Repo | Branche | HEAD | Upstream | Clean | Verdict |
|---|---|---|---|---|---|
| `keybuzz-api` (bastion) | `ph147.4/source-of-truth` | `d90e093` | — | ✅ 0 dirty | ✅ |
| `keybuzz-admin-v2` (local) | `main` | `5cf0bda` | `5cf0bda` | ✅ 0 dirty | ✅ |
| `keybuzz-infra` (local) | `main` | `4c1bffe` | `4c1bffe` | dirty hors scope | ✅ |

Note : le répertoire local `c:\DEV\KeyBuzz\V3\keybuzz-api` est le repo **client** Next.js, pas le Fastify API backend. L'API backend est uniquement sur le bastion.

---

## 3. Sources de vérité relues

| Rapport | Contenu clé |
|---|---|
| PH-T8.11E | Google Ads spend sync implémenté en DEV, commit `b854c470`, image `v3.5.122-google-ads-v24-dev`, sync completed 0 rows |
| PH-T8.11F | Validation runtime DEV : sync fonctionnel, customer `5947963982` canonique, 0 campagnes all-time, GO PARTIEL |
| PH-T8.11AA | Vérification `signup_complete` GA4→Ads : propagation pending, `purchase` visible, pas de tag AW direct |
| process-lock.mdc | Build depuis Git propre, GitOps strict, pas de `kubectl set image/env/patch/edit` |
| git-source-of-truth.mdc | Git = unique source de vérité code produit |

---

## 4. Audit PROD — résultats complets

### 4.1 API PROD

| Élément | Résultat |
|---|---|
| Image actuelle | `ghcr.io/keybuzzio/keybuzz-api:v3.5.123-linkedin-capi-native-prod` |
| Pod | `keybuzz-api-7df9bd76bc-8872h`, Running |
| Module `google-ads.js` | ✅ **PRÉSENT** dans `/app/dist/modules/metrics/ad-platforms/google-ads.js` |
| Routes `ad-accounts` | ✅ **Support `google`** confirmé (switch `meta | google`, import `google_ads_1`) |
| Hint routes | `"Supported: meta, google"` |
| Env `GOOGLE_ADS_DEVELOPER_TOKEN` | ❌ **ABSENT** |
| Env `GOOGLE_ADS_CLIENT_ID` | ❌ **ABSENT** |
| Env `GOOGLE_ADS_CLIENT_SECRET` | ❌ **ABSENT** |
| Env `GOOGLE_ADS_REFRESH_TOKEN` | ❌ **ABSENT** |
| Secret K8s `keybuzz-google-ads` | ❌ **INEXISTANT** |
| Manifest GitOps PROD | ❌ **Aucune ref GOOGLE_ADS** |

### 4.2 Provenance du code

Le commit `b854c470` (feat: Google Ads spend sync) est **antérieur** aux commits LinkedIn CAPI :

```
d90e0930 fix(linkedin-capi) — HEAD
d1483c3c feat(linkedin-capi)
b854c470 feat(google-ads) ← code inclus
```

L'image `v3.5.123-linkedin-capi-native-prod` a été buildée au commit `d90e0930`, qui inclut `b854c470`. Le code est donc **automatiquement inclus** dans l'image PROD. Aucun build supplémentaire n'est nécessaire.

### 4.3 DB PROD

| Table | Platform | Résultat |
|---|---|---|
| `ad_platform_accounts` | google | **0 rows** |
| `ad_platform_accounts` | meta | 1 row (account `1485150039295668`, active, last_sync `2026-04-23`, tenant `keybuzz-consulting-mo9zndlk`) |
| `ad_spend_tenant` | google | **0 rows** |
| `ad_spend_tenant` | meta | 16 rows (2026-03-16 → 2026-03-31) |

### 4.4 Secrets PROD namespace

```
secret/ghcr-cred
secret/keybuzz-ads-encryption
secret/keybuzz-api-jwt
secret/keybuzz-api-postgres
secret/keybuzz-api-prod-tls
secret/keybuzz-litellm
secret/keybuzz-meta-ads          ← Meta existe
secret/keybuzz-ses
secret/keybuzz-shopify
secret/keybuzz-stripe
secret/minio-credentials
secret/octopia-credentials
secret/redis-credentials
secret/tracking-17track
secret/vault-app-token
secret/vault-root-token
                                 ← Pas de keybuzz-google-ads
```

### 4.5 Comparaison DEV vs PROD

| Élément | DEV | PROD |
|---|---|---|
| Code google-ads.js | ✅ | ✅ |
| Routes support google | ✅ | ✅ |
| GOOGLE_ADS_DEVELOPER_TOKEN | ✅ (plain text) | ❌ |
| GOOGLE_ADS_CLIENT_ID | ✅ (plain text) | ❌ |
| GOOGLE_ADS_CLIENT_SECRET | ✅ (plain text) | ❌ |
| GOOGLE_ADS_REFRESH_TOKEN | ✅ (plain text) | ❌ |
| Secret K8s dédié | ❌ (plain text in spec) | ❌ |
| Manifest GitOps | ❌ (hors GitOps) | ❌ |
| ad_platform_accounts Google | 1 (active, `5947963982`) | 0 |
| ad_spend_tenant Google | 0 | 0 |

**Drift GitOps DEV** : les credentials Google Ads DEV ont été injectés via `kubectl set env` lors de PH-T8.11E (avant le renforcement du process-lock). Ils ne figurent pas dans le manifest `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`.

---

## 5. Google Ads Account — vérité canonique

| Identifiant | Format | Nature | Devise | Accessible | Canonique |
|---|---|---|---|---|---|
| `5947963982` | `594-796-3982` | Compte annonceur | GBP | ✅ (DEV vérifié PH-T8.11F) | **OUI** |
| `5463791796` | `546-379-1796` | MCC (Manager) | GBP | ✅ | Non (MCC) |
| `8173861138` | `817-386-1138` | Inconnu/ancien | — | ❌ (CUSTOMER_NOT_FOUND) | Non |

Le customer ID canonique est **`5947963982`** (confirmé par `listAccessibleCustomers` et GAQL `campaign` query).

---

## 6. Tableau d'audit PROD

| Surface | Google connecté ? | Dernière sync | Spend rows | Verdict |
|---|---|---|---|---|
| API code | ✅ Code présent | — | — | Code OK, credentials manquants |
| DB ad_platform_accounts | ❌ 0 compte Google | — | — | Pas de compte enregistré |
| DB ad_spend_tenant | ❌ | — | 0 | Aucune donnée |
| Env vars PROD | ❌ 0/4 variables | — | — | **BLOQUEUR** |
| Secret K8s | ❌ inexistant | — | — | **BLOQUEUR** |
| Admin /paid-channels | — | — | — | Google affiché comme non connecté |
| Admin /ad-accounts | — | — | — | Aucun compte Google visible |
| Admin /metrics | — | — | — | Pas de data Google (cohérent) |

---

## 7. Diagnostic — Pourquoi STOP

### Bloqueur : credentials PROD absents

Le code Google Ads spend sync est dans l'image PROD mais ne peut pas fonctionner car :

1. **Aucun secret K8s** `keybuzz-google-ads` n'existe dans le namespace `keybuzz-api-prod`
2. **Aucune variable** `GOOGLE_ADS_*` n'est définie dans le deployment PROD
3. **Le manifest GitOps** ne référence aucune configuration Google Ads
4. **Aucun compte** Google n'est enregistré dans la DB PROD `ad_platform_accounts`

Sans ces 4 éléments, toute tentative de sync échouerait immédiatement (le module `getGoogleAdsEnv()` lirait `undefined` pour toutes les variables).

### Ce n'est PAS un problème de code

Le code est identique entre DEV et PROD. Le module `google-ads.js` et les routes `ad-accounts` supportent Google. Aucun build ni deploy n'est nécessaire.

---

## 8. Actions requises — business/config (par Ludovic)

### Action 1 : Créer le secret K8s PROD

```bash
kubectl create secret generic keybuzz-google-ads \
  --namespace keybuzz-api-prod \
  --from-literal=GOOGLE_ADS_DEVELOPER_TOKEN='<VALUE>' \
  --from-literal=GOOGLE_ADS_CLIENT_ID='<VALUE>' \
  --from-literal=GOOGLE_ADS_CLIENT_SECRET='<VALUE>' \
  --from-literal=GOOGLE_ADS_REFRESH_TOKEN='<VALUE>'
```

Les valeurs sont identiques à celles du DEV (même compte Google Ads `594-796-3982`, mêmes OAuth credentials).

### Action 2 : Mettre à jour le manifest GitOps PROD

Ajouter dans `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` (après le bloc Meta Ads) :

```yaml
            # PH-T8.11AE: Google Ads spend sync credentials (KEY-194)
            - name: GOOGLE_ADS_DEVELOPER_TOKEN
              valueFrom:
                secretKeyRef:
                  name: keybuzz-google-ads
                  key: GOOGLE_ADS_DEVELOPER_TOKEN
            - name: GOOGLE_ADS_CLIENT_ID
              valueFrom:
                secretKeyRef:
                  name: keybuzz-google-ads
                  key: GOOGLE_ADS_CLIENT_ID
            - name: GOOGLE_ADS_CLIENT_SECRET
              valueFrom:
                secretKeyRef:
                  name: keybuzz-google-ads
                  key: GOOGLE_ADS_CLIENT_SECRET
            - name: GOOGLE_ADS_REFRESH_TOKEN
              valueFrom:
                secretKeyRef:
                  name: keybuzz-google-ads
                  key: GOOGLE_ADS_REFRESH_TOKEN
```

### Action 3 : Appliquer GitOps

```bash
cd /opt/keybuzz/keybuzz-infra
git fetch origin && git reset --hard origin/main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

### Action 4 : Enregistrer le compte Google dans ad_platform_accounts PROD

Soit via l'UI Admin `/marketing/ad-accounts`, soit via l'API :

```
POST /ad-accounts
{
  "platform": "google",
  "account_id": "5947963982",
  "account_name": "KeyBuzz Google Ads",
  "currency": "GBP"
}
```

Avec tenant PROD `keybuzz-consulting-mo9zndlk`.

### Action 5 : Lancer le sync

```
POST /ad-accounts/<uuid>/sync
```

### Action bonus : corriger le drift GitOps DEV

Les credentials DEV sont en plain text dans le deployment spec (injectés via `kubectl set env`). Ils devraient être migrés vers un secret K8s `keybuzz-google-ads` dans le namespace `keybuzz-api-dev` et référencés via `secretKeyRef` dans le manifest DEV.

---

## 9. Attention : refresh token

Comme documenté dans PH-T8.11E et PH-T8.11F :

- Le refresh token a été obtenu le 27 avril 2026
- L'écran de consentement OAuth est en mode **"Testing"**
- En mode Testing, les refresh tokens expirent après **7 jours**
- Si le token a expiré (après le 4 mai 2026), il faudra :
  1. Publier l'écran de consentement OAuth dans GCP (mode "Published")
  2. Générer un nouveau refresh token
  3. Mettre à jour le secret K8s

---

## 10. Non-régression

| Vérification | Résultat |
|---|---|
| Meta spend intact | ✅ 16 rows PROD, account active, last_sync 2026-04-23 |
| TikTok spend | N/A (non connecté, bloqué business — attendu) |
| LinkedIn spend | N/A (hors scope — attendu) |
| GA4 import intact | ✅ (pas de modification, configuration inchangée) |
| API health | ✅ (pod Running, deployment stable) |
| Admin pages | ✅ (aucune modification Admin dans cette phase) |
| Fuite secrets | ✅ Aucun secret dans le rapport (valeurs masquées) |
| Modification effectuée | **Aucune** — audit uniquement |

---

## 11. Linear

### KEY-194 — Google Ads spend sync

**Statut recommandé : NE PAS FERMER**

Raison : Le code est en PROD mais les credentials ne sont pas configurés. Le ticket ne peut être fermé que quand :
1. Secret PROD créé
2. Manifest GitOps mis à jour
3. Compte Google enregistré en PROD DB
4. Sync exécuté avec succès
5. Admin Paid Channels reflète la vérité

### KEY-199 — Ad Accounts multi-plateforme

Pas d'action. Le code supporte déjà multi-plateforme (`meta | google`).

### KEY-217 — `signup_complete` Google Ads

Pas d'action dans cette phase. Hors scope (suivi indépendant).

---

## 12. Gaps restants

| # | Gap | Sévérité | Action | Responsable |
|---|---|---|---|---|
| G1 | Credentials Google Ads absents en PROD | **BLOQUEUR** | Créer secret K8s + mettre à jour manifest | Ludovic |
| G2 | Compte Google non enregistré en PROD DB | **BLOQUEUR** | Enregistrer via API/UI après G1 | Ludovic/CE |
| G3 | Refresh token potentiellement expiré (7j) | **MOYEN** | Vérifier, re-générer si nécessaire, publier OAuth consent screen | Ludovic |
| G4 | Drift GitOps DEV (credentials plain text, hors manifest) | **MOYEN** | Migrer vers secret K8s + ajouter au manifest DEV | CE (phase suivante) |
| G5 | 0 campagnes Google Ads sur `594-796-3982` au 27 avril | **INFO** | Ludovic a lancé une campagne test — re-vérifier post-sync | Ludovic |
| G6 | Paid Channels Google Spend/KPI non coché | **Attendu** | Se résoudra automatiquement quand sync PROD fonctionnel | — |

---

## 13. Aucune modification effectuée

Oui — aucun fichier modifié, aucun build, aucun deploy, aucun secret créé dans cette phase. Audit pur.

---

## 14. PROD inchangée

Oui — aucune modification PROD.

---

## Rapport

`keybuzz-infra/docs/PH-T8.11AE-GOOGLE-SPEND-KPI-PROD-CLOSURE-01.md`

---

## VERDICT

```
GOOGLE SPEND/KPI PROD AUDIT COMPLETED — CODE PRESENT IN PROD IMAGE — CREDENTIALS NOT CONFIGURED
— NO K8S SECRET — NO GOOGLE ACCOUNT IN PROD DB — 0 SPEND ROWS — STOP BUSINESS/CONFIG
— NO BUILD NEEDED — NO DEPLOY NEEDED — ACTIONS DOCUMENTED FOR LUDOVIC
— META SPEND INTACT — NO TRACKING DRIFT — NO SECRETS EXPOSED IN REPORT
```
