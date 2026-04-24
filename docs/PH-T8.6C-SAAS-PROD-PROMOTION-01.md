# PH-T8.6C — PROD Promotion : Outbound Destinations API + Webhook Conversions

> Phase : PH-T8.6C-SAAS-PROD-PROMOTION-01
> Date : 2026-04-22
> Environnement : PROD
> Auteur : Cursor Agent

---

## 1. Préflight


| Élément                    | Valeur                                                  |
| -------------------------- | ------------------------------------------------------- |
| Branche                    | `ph147.4/source-of-truth`                               |
| HEAD                       | `536d3340` (fix: admin bypass for internal proxy calls) |
| Commit source destinations | `b0b2f898` (PH-T8.6A)                                   |
| Repo clean                 | Oui                                                     |
| Image PROD avant           | `v3.5.94-outbound-conversions-real-value-prod`          |
| Image PROD après           | `v3.5.95-outbound-destinations-api-prod`                |
| Image DEV                  | `v3.5.96-admin-bypass-dev` (avancée post PH-T8.6A)      |


---

## 2. Contenu promu

Cette promotion PROD inclut tout le stack outbound conversions :


| Fonctionnalité                                     | Commit     | Phase d'origine |
| -------------------------------------------------- | ---------- | --------------- |
| StartTrial + Purchase server-side                  | `4c7b2cea` | PH-T8.4         |
| Valeur réelle Stripe (amount_total, items)         | `c47af816` | PH-T8.4.1       |
| API destinations self-service (CRUD + test + logs) | `b0b2f898` | PH-T8.6A        |
| Émetteur multi-destination + delivery logs         | `b0b2f898` | PH-T8.6A        |
| Admin bypass pour proxy interne                    | `536d3340` | Fix             |


---

## 3. Vérification source


| Élément                                                      | Présent |
| ------------------------------------------------------------ | ------- |
| `routes.ts` (destinations CRUD + test + logs)                | ✅       |
| `emitter.ts` (multi-destination + fallback ENV)              | ✅       |
| `app.ts` (registration `/outbound-conversions/destinations`) | ✅       |
| RBAC `owner`/`admin`                                         | ✅       |
| Delivery logs (`outbound_conversion_delivery_logs`)          | ✅       |
| `getActiveDestinations()` (DB → ENV fallback)                | ✅       |
| `sendToDestination()` (HMAC + retry + log)                   | ✅       |


---

## 4. Build PROD


| Élément    | Valeur                                                                    |
| ---------- | ------------------------------------------------------------------------- |
| Tag        | `v3.5.95-outbound-destinations-api-prod`                                  |
| Registry   | `ghcr.io/keybuzzio/keybuzz-api`                                           |
| Digest     | `sha256:f28461e800cb245dbd571ef91b8b1884ab26047fc491e30fcdd2262426a37bd9` |
| Build      | `docker build --no-cache` sur bastion                                     |
| TypeScript | `tsc` clean (0 erreurs)                                                   |


---

## 5. GitOps PROD

Fichier modifié : `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`

```yaml
# PH-T8.6C: outbound destinations self-service API PROD
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.95-outbound-destinations-api-prod
# rollback: v3.5.94-outbound-conversions-real-value-prod
```

Aucune variable d'environnement ajoutée ni modifiée.
Les env vars `OUTBOUND_CONVERSIONS_WEBHOOK_URL` et `OUTBOUND_CONVERSIONS_WEBHOOK_SECRET` restent vides (fallback désactivé — les destinations DB sont la source de vérité).

---

## 6. Déploiement


| Élément  | Valeur                       |
| -------- | ---------------------------- |
| Pod      | `keybuzz-api-685f76c5-pq6cj` |
| Node     | `k8s-worker-01`              |
| Status   | Running                      |
| Restarts | 0                            |
| Rollout  | `successfully rolled out`    |


---

## 7. Validation PROD


| #   | Cas                            | Attendu                        | Résultat                      |
| --- | ------------------------------ | ------------------------------ | ----------------------------- |
| T1  | Health check                   | `{"status":"ok"}`              | ✅ OK                          |
| T2  | Destinations module chargé     | 200 + `destinations: []`       | ✅ OK                          |
| T3  | RBAC rejet (email inconnu)     | 403                            | ✅ 403                         |
| T4  | Créer destination (owner)      | 201 + secret masqué            | ✅ 201                         |
| T5  | Lister destinations            | Secret masqué `pr****6c`       | ✅ OK                          |
| T6  | Test delivery (ConnectionTest) | Requête envoyée                | ✅ 200 (404 = endpoint fictif) |
| T7  | Delivery logs                  | Log créé                       | ✅ 1 log                       |
| T8  | Émetteur module chargé         | `typeof function`              | ✅ OK                          |
| T9  | Exclusion test                 | 14 tenants exempts             | ✅ OK                          |
| T10 | Idempotence table              | `conversion_events` accessible | ✅ 0 events (clean)            |
| T11 | Billing endpoint               | Répond (400 = tenant exempt)   | ✅ attendu                     |


### Données de test nettoyées

Toutes les destinations et logs de validation ont été supprimés après les tests.

---

## 8. Non-régression


| Élément           | Statut                       |
| ----------------- | ---------------------------- |
| API health        | ✅ OK                         |
| Billing endpoint  | ✅ accessible                 |
| Stripe webhooks   | ✅ non impacté (même handler) |
| Metrics           | ✅ non impacté                |
| Exclusion test    | ✅ 14 tenants exempts         |
| Idempotence       | ✅ table intacte              |
| Autopilot         | ✅ non impacté                |
| Payload structure | ✅ identique                  |
| HMAC signature    | ✅ identique                  |
| Env var fallback  | ✅ préservé                   |


---

## 9. Rollback

```bash
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.94-outbound-conversions-real-value-prod \
  -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

Les tables DB restent en place sans impact (vides, auto-migrées).

---

## 10. État final


| Environnement | Image                                    | Status         |
| ------------- | ---------------------------------------- | -------------- |
| **DEV**       | `v3.5.96-admin-bypass-dev`               | ✅ Opérationnel |
| **PROD**      | `v3.5.95-outbound-destinations-api-prod` | ✅ Opérationnel |


### Fonctionnalités PROD actives


| Fonctionnalité                          | Statut  |
| --------------------------------------- | ------- |
| StartTrial / Purchase server-side       | ✅ Actif |
| Valeur réelle Stripe (montant + devise) | ✅ Actif |
| HMAC SHA256 signature                   | ✅ Actif |
| Idempotence (conversion_events)         | ✅ Actif |
| Exclusion test (14 tenants exempts)     | ✅ Actif |
| Attribution (signup_attribution)        | ✅ Actif |
| Retry (3 tentatives, backoff)           | ✅ Actif |
| API destinations self-service           | ✅ Actif |
| RBAC owner/admin                        | ✅ Actif |
| Test delivery (ConnectionTest)          | ✅ Actif |
| Delivery logs par destination           | ✅ Actif |
| Multi-destination (DB + ENV fallback)   | ✅ Actif |
| Secret masqué en lecture                | ✅ Actif |


---

## 11. Verdict

```
OUTBOUND DESTINATIONS PROD READY — WEBHOOK SELF-SERVICE LIVE — SAFE BUILD
```

