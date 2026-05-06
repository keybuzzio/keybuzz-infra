# PH-SAAS-T8.12AO.9 — Amazon /start Activation Contract Fix — PROD Promotion

> Phase : PH-SAAS-T8.12AO.9-AMAZON-START-ACTIVATION-CONTRACT-PROD-PROMOTION-01
> Date : 2026-05-06
> Environnement : PROD
> Priorité : P0
> Ticket : KEY-249 (ouvert)

---

## 1. Contexte

Promotion PROD du fix AO.8 :
- `/start` n'appelait pas `activateAmazonChannels()` après retour OAuth
- Il affichait "Amazon connecté avec succès" sans activation réelle
- `/channels` montrait ensuite le connecteur en "En attente"
- Fix : `/start` appelle maintenant la même fonction `activateAmazonChannels` que `/channels`
- Succès uniquement si `res.activated?.length > 0`
- Erreur honnête + CTA si activation échoue

---

## 2. Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `f2e9bfc5` | Non | OK |
| keybuzz-infra | `main` | `7550df2` | Non | OK |

| Service | Env | Image | Verdict |
|---|---|---|---|
| Client PROD | PROD | `v3.5.159-amazon-marketplace-routing-source-prod` | Cible promotion |
| Client DEV | DEV | `v3.5.160-amazon-start-activation-contract-dev` | Fix AO.8 validé |
| API PROD | PROD | `v3.5.142-promo-retry-email-prod` | INCHANGÉ |
| Backend PROD | PROD | `v1.0.47-cross-env-guard-fix-prod` | INCHANGÉ |
| Website PROD | PROD | `v0.6.9-promo-forwarding-prod` | INCHANGÉ |
| OW PROD | PROD | `v3.5.165-escalation-flow-prod` | INCHANGÉ |

---

## 3. Source lock AO.8

| Brique | Point vérifié | Résultat |
|---|---|---|
| Commit `f2e9bfc5` | Présent, 1 fichier modifié | OK |
| `activateAmazonChannels(tenantId, expectedChannel)` | Ligne 59 | OK |
| Loading "Activation du canal Amazon en cours..." | Ligne 195 | OK |
| Succès `res.activated?.length > 0` | Ligne 61 | OK |
| Erreur honnête | Lignes 64, 68 | OK |
| CTA "Gérer dans Canaux" | Ligne 210 | OK |
| `/channels` non modifié | Aucun commit AO.8 | OK |

---

## 4. Build

| Tag | Source commit | Digest | Build args | Verdict |
|---|---|---|---|---|
| `v3.5.160-amazon-start-activation-contract-prod` | `f2e9bfc5` | `sha256:fce3acf59fa23e83a2484b68fa818707899b38ad7210fcee54e05429f02f12ab` | `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production` | OK |

---

## 5. Bundle audit

| Signal | Résultat |
|---|---|
| Fix `/start` activation | Présent (`page-17d1535b947593d0.js`) |
| `activate-channels` service chunk | Présent (`2113-*.js`) |
| `expected_channel` dans /start | 1 occurrence |
| "Relancez" error message | 1 occurrence |
| Meta Purchase browser (`fbq Purchase`) | **ABSENT** (OK) |
| TikTok CompletePayment browser | **ABSENT** (OK) |
| Tracking architecture identique build précédent | Confirmé |

---

## 6. GitOps

| Manifest | Image avant | Image après | Commit |
|---|---|---|---|
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.159-amazon-marketplace-routing-source-prod` | `v3.5.160-amazon-start-activation-contract-prod` | `89dffec` |

---

## 7. Rollout

| Pod | Image | Ready | Restarts | Verdict |
|---|---|---|---|---|
| `keybuzz-client-8fd9c9857-m58d4` | `v3.5.160-amazon-start-activation-contract-prod` | 1/1 | 0 | OK |

Runtime = manifest. Health PROD = 200.

---

## 8. Validation structurelle PROD

| Page | HTTP | Verdict |
|---|---|---|
| `/login` | 200 | OK |
| `/register` | 200 | OK |
| `/start` | 307 (auth) | OK |
| `/channels` | 307 (auth) | OK |
| `/dashboard` | 307 (auth) | OK |
| `/billing/plan` | 307 (auth) | OK |

Bundle `/start` contient :
- "Activation du canal Amazon en cours" ✓
- `expected_channel` extraction ✓
- "Relancez la connexion" erreur honnête ✓
- `activate-channels` dans service partagé ✓

---

## 9. Tracking Client PROD

| Page | Tracking | Verdict |
|---|---|---|
| `/register`, `/login` | Scripts source présents dans `SaaSAnalytics.tsx` | OK |
| `/start` | Dans `BLOCKED_PREFIXES` — aucun tracking | OK |
| Toutes pages protégées | Dans `BLOCKED_PREFIXES` | OK |
| Meta Purchase browser | ABSENT | OK |
| TikTok CompletePayment browser | ABSENT | OK |
| Architecture tracking = build PROD précédent | Confirmé (pas de `fbevents`/`googletagmanager` inline dans les chunks, identique à `v3.5.159`) | OK |

---

## 10. Validation utilisateur Ludovic — PENDING

**À tester par Ludovic :**

1. Aller sur `https://client.keybuzz.io/start`
2. Choisir Amazon France
3. Compléter l'OAuth Amazon (MFA humain requis)
4. Retour sur `/start`
5. Vérifier :
   - Loading "Activation du canal Amazon en cours..." pendant activation
   - Succès "Amazon connecté et activé avec succès" seulement si activation OK
   - Aller dans `/channels` — le connecteur doit être "Connecté" + inbound email visible
6. Si activation échoue :
   - Message "OAuth terminé, mais l'activation du canal n'est pas complète"
   - CTA "Gérer dans Canaux"
   - Pas de faux succès

---

## 11. Non-régression PROD

| Surface | Résultat |
|---|---|
| API PROD | OK — INCHANGÉE (`v3.5.142-promo-retry-email-prod`) |
| Backend PROD | OK — INCHANGÉ (`v1.0.47-cross-env-guard-fix-prod`) |
| Website PROD | OK — INCHANGÉ (`v0.6.9-promo-forwarding-prod`, 200) |
| OW PROD | OK — INCHANGÉ (`v3.5.165-escalation-flow-prod`) |
| Billing | Non touché |
| Tracking | Non-régression confirmée |
| No checkout/email/CAPI/fake event | Aucun |

---

## 12. KEY-249

- Image PROD : `v3.5.160-amazon-start-activation-contract-prod`
- Validation structurelle : OK
- Validation utilisateur : PENDING (Ludovic)
- Ticket : **NON FERMÉ**

---

## 13. Rollback PROD (GitOps strict)

```yaml
# keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.159-amazon-marketplace-routing-source-prod
```

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.159-amazon-marketplace-routing-source-prod \
  -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## 14. Interdits respectés

| Interdit | Respecté |
|---|---|
| Pas de modification Backend | OUI |
| Pas de modification API | OUI |
| Pas de modification Website/Admin/OW | OUI |
| Pas de hardcoding tenant/seller/email/pays | OUI |
| Pas de secrets dans logs/rapport | OUI |
| Pas de mutation billing/Stripe/CAPI | OUI |
| Pas de fermeture KEY-249 | OUI |
| GitOps strict uniquement | OUI |
| Build depuis source prouvée (`f2e9bfc5`) | OUI |
| Tag immuable + digest documenté | OUI |
| Meta Purchase browser absent | OUI |
| TikTok CompletePayment browser absent | OUI |

---

## 15. Historique AO complet

| Phase | Description | Env | Image Client | Image Backend |
|---|---|---|---|---|
| AO.6 | Sélecteur pays Amazon dans /start | DEV | `v3.5.158` | — |
| AO.6.1 | EU-only filter + expected_channel | DEV | `v3.5.159` | — |
| AO.6.2 | Validation OAuth réel DEV + cross-env guard fix | DEV | — | `v1.0.47` |
| AO.7 | Promotion PROD | PROD | `v3.5.159` | `v1.0.47` |
| AO.8 | Fix activation contract /start | DEV | `v3.5.160` | — |
| **AO.9** | **Promotion PROD activation fix** | **PROD** | **`v3.5.160`** | — |

---

## 16. Verdict

### GO PARTIEL — USER OAUTH VALIDATION PENDING

AMAZON START ACTIVATION CONTRACT LIVE IN PROD — /START NO LONGER SHOWS FALSE SUCCESS — POST-OAUTH ACTIVATION MATCHES /CHANNELS — SUCCESS REQUIRES ACTIVATED CHANNEL — ERROR STATE HONEST — /CHANNELS UNCHANGED — CLIENT TRACKING PRESERVED — NO TENANT HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT — USER OAUTH VALIDATION PENDING
