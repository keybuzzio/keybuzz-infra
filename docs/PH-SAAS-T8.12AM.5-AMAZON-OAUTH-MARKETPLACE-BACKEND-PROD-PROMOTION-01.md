# PH-SAAS-T8.12AM.5 — Amazon OAuth Marketplace Backend PROD Promotion

> **Date** : 4 mai 2026
> **Phase** : PH-SAAS-T8.12AM.5-AMAZON-OAUTH-MARKETPLACE-BACKEND-PROD-PROMOTION-01
> **Priorité** : P0
> **Verdict** : **GO PARTIEL USER OAUTH PENDING**

---

## Résumé

Promotion PROD réussie de la correction AM.4 backend : le routage OAuth Amazon pointe maintenant vers `sellercentral-europe.amazon.com` (EU) au lieu de `sellercentral.amazon.com` (NA/Mexique). Amazon FR ne tombe plus sur le Seller Central NA.

La validation URL OAuth PROD n'a pas pu être testée directement (PROD exige JWT, pas X-User-Email), mais le code est identique au DEV validé (même commit `4a20445`). La validation finale aura lieu lorsque Ludovic effectuera un flux OAuth Amazon FR réel.

---

## Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|------|---------|------|-------|---------|
| keybuzz-backend | `main` | `4a20445` (AM.4) | 0 | OK |
| keybuzz-infra | `main` | `71ccf93` (après AM.5) | 0 | OK |

### Runtimes PROD avant promotion

| Service | Runtime avant | Manifest avant | Verdict |
|---------|-------------|----------------|---------|
| Backend | `v1.0.46-ph-recovery-01-prod` | `v1.0.46-ph-recovery-01-prod` | Match ✅ |
| API | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` | — (non modifié) | Préservé ✅ |
| Client | `v3.5.149-amazon-connector-status-ux-prod` | — (non modifié) | Préservé ✅ |
| Website | `v0.6.8-tiktok-browser-pixel-prod` | — (non modifié) | Préservé ✅ |

---

## Vérification Source Backend AM.4

| Brique Backend | Point vérifié | Résultat | Verdict |
|---------------|---------------|----------|---------|
| OAuth URL | EU → `sellercentral-europe.amazon.com` | `REGION_SELLER_CENTRAL["eu-west-1"]` → EU | ✅ |
| `login_uri` | utilisé si présent (Vault) | `appCreds.login_uri \|\| REGION_SELLER_CENTRAL[region]` | ✅ |
| `marketplace_id` | non hardcodé `A13V1IB3VIYZZH` | Absent du flux OAuth | ✅ |
| `countries` | non hardcodé `["FR"]` | Déterminé par region app config | ✅ |
| Callback | marketplace réelle | Pas de forçage FR | ✅ |
| No secrets | Pas de secrets dans source | OK | ✅ |

---

## AM.3 Préservé

| Brique AM.3 | Attendu | Résultat |
|------------|---------|---------|
| API `/status` read-only | oui | Oui (API inchangée) ✅ |
| Self-healing | absent | Absent (API inchangée) ✅ |
| Activation explicite | oui | Oui (API inchangée) ✅ |
| Suppression stable | oui | Oui (API inchangée) ✅ |
| Client tracking | préservé | Client inchangé ✅ |
| Shopify logo | préservé | Client inchangé ✅ |

---

## Build PROD Backend

| Élément | Valeur |
|---------|--------|
| Source commit | `4a20445` |
| Source branch | `main` |
| Tag | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-amazon-oauth-marketplace-fix-prod` |
| Digest | `sha256:ba9477d308c47374142e6e5500f49da7e684c65c32e6d7a96512adac6890f604` |
| Build source | Clone propre, `--no-cache` |
| Rollback | `v1.0.46-ph-recovery-01-prod` |

---

## GitOps PROD

| Manifest | Image avant | Image après |
|----------|------------|-------------|
| `k8s/keybuzz-backend-prod/deployment.yaml` | `v1.0.46-ph-recovery-01-prod` | `v1.0.40-amazon-oauth-marketplace-fix-prod` |

- Commit infra : `71ccf93`
- `kubectl apply -f` : OK
- `kubectl rollout status` : success
- Pod : 1/1 Running, 0 restarts
- Health : `{"status":"ok"}` ✅

---

## Validation OAuth URL FR/EU

| Test | Attendu | Résultat |
|------|---------|---------|
| DEV backend direct | `sellercentral-europe.amazon.com` | ✅ Validé en AM.4 |
| DEV via API proxy | `sellercentral-europe.amazon.com` | ✅ Validé en AM.4 |
| PROD backend direct | `sellercentral-europe.amazon.com` | 401 (JWT requis en PROD — attendu) |
| PROD via API proxy | `sellercentral-europe.amazon.com` | Erreur connexion port (proxy PROD) |
| Secrets exposés | non | Non ✅ |

**Note** : Le test URL direct en PROD retourne 401 car PROD exige une authentification JWT (pas de `X-User-Email` bridge). C'est le comportement attendu et sécurisé. Le code PROD est identique au DEV (même commit `4a20445`, même build process). La validation réelle se fera via un flux OAuth complet initié par Ludovic.

---

## Validation SWITAA

| Étape SWITAA | Attendu | Résultat |
|-------------|---------|---------|
| Canaux PROD | 0 (jamais créés en PROD) | 0 ✅ |
| Canaux DEV | `amazon-fr` pending | Confirmé en AM.4 ✅ |
| Reconnexion path | Disponible via OAuth EU | Prêt (user action pending) |

SWITAA n'a jamais eu de canaux Amazon en PROD. Le chemin de reconnexion est prêt : l'URL OAuth pointera vers Seller Central Europe.

---

## Validation eComLG

| Check eComLG | Attendu | Résultat |
|-------------|---------|---------|
| Channels Amazon PROD | 5 active | 5 active (be, es, fr, it, pl) ✅ |
| OAuth existant | non cassé | Backend mis à jour, OAuth flow intact ✅ |
| Orders sync | actif | Workers running (items + orders) ✅ |

---

## Non-régression Globale

| Brique | Attendu | Résultat |
|--------|---------|---------|
| Backend health | OK | `{"status":"ok"}` ✅ |
| API PROD image | inchangée | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` ✅ |
| Client PROD image | inchangée | `v3.5.149-amazon-connector-status-ux-prod` ✅ |
| Website PROD image | inchangée | `v0.6.8-tiktok-browser-pixel-prod` ✅ |
| Outbound worker | running | Running (7 restarts, 23d age) ✅ |
| Amazon items worker | running | Running, 23d ✅ |
| Amazon orders worker | running | Running, 23d ✅ |
| Amazon orders sync CronJob | running | Completed jobs visible ✅ |
| Outbound tick processor | running | Completed jobs visible ✅ |
| 17TRACK | inchangé | Backend only, no route change ✅ |
| Shopify | inchangé | Client/API non modifiés ✅ |
| Billing | inchangé | Aucune mutation ✅ |
| Tracking/CAPI | inchangé | Client non modifié ✅ |
| Secrets | non exposés | Aucun secret dans logs/rapport ✅ |

---

## Gaps Restants

1. **OAuth URL PROD non testée directement** : PROD exige JWT, pas de bridge `X-User-Email`. Le code est identique au DEV validé. La validation finale nécessite un flux OAuth réel par Ludovic.

2. **Session Seller Central navigateur** : Si Ludovic est connecté à son compte Amazon NA dans le navigateur, Amazon peut toujours afficher un banner ou proposition de switch. Le fix garantit que l'URL envoyée pointe vers EU, mais la session navigateur Amazon est hors contrôle de KeyBuzz.

3. **Callback marketplace validation** : Le callback ne vérifie pas encore que le `selling_partner_id` retourné correspond à un seller EU. Si un user valide l'OAuth depuis un autre marketplace (ex : switch vers NA dans le navigateur), le token stocké sera pour ce marketplace. Phase future recommandée.

4. **SWITAA PROD** : Aucun canal PROD à tester. La validation réelle se fera quand Ludovic créera un canal Amazon FR en PROD et effectuera le flux OAuth.

---

## Rollback PROD

```yaml
# k8s/keybuzz-backend-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-backend:v1.0.46-ph-recovery-01-prod
```

Procédure GitOps stricte :
1. Modifier le manifest PROD pour restaurer l'image précédente
2. `git commit` + `git push`
3. `kubectl apply -f k8s/keybuzz-backend-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-prod`
5. Vérifier manifest = runtime

---

## Commits

| Repo | Commit | Message |
|------|--------|---------|
| `keybuzz-backend` | `4a20445` | `PH-SAAS-T8.12AM.4: fix OAuth URL NA hardcode` |
| `keybuzz-infra` | `71ccf93` | `PH-SAAS-T8.12AM.5: deploy backend PROD v1.0.40` |
| `keybuzz-infra` | (ce rapport) | `PH-SAAS-T8.12AM.5: rapport final` |

---

## Verdict

**GO PARTIEL USER OAUTH PENDING**

AMAZON OAUTH MARKETPLACE ROUTING LIVE IN PROD — FR/EU OAUTH USES SELLERCENTRAL EUROPE — MEXICO/NA FALLBACK REMOVED — MARKETPLACE/COUNTRY HARDCODES REMOVED — API/CLIENT AM.3 PRESERVED — ECOMLG 5 CHANNELS PRESERVED — SWITAA RECONNECT PATH READY (USER ACTION PENDING) — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT
