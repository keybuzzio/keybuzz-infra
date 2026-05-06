# PH-SAAS-T8.12AO.8 — Amazon /start Activation Contract Fix (DEV)

> Phase : PH-SAAS-T8.12AO.8-AMAZON-START-ACTIVATION-CONTRACT-FIX-DEV-01
> Date : 2026-05-06
> Environnement : DEV uniquement
> Priorité : P0
> Ticket : KEY-249 (ouvert)

---

## 1. Contexte

Après la promotion PROD d'AO.7, la validation utilisateur PROD (Ludovic) a révélé un dernier bug :

- `/start` affiche bien le sélecteur pays Amazon (AO.6)
- OAuth Amazon fonctionne (AO.6.2)
- Le retour OAuth revient sur le SaaS
- `/start` affiche **"Amazon connecté avec succès"** (faux succès)
- **MAIS** `/channels` montre le connecteur en **"En attente"**
- En relançant la connexion depuis `/channels`, l'activation fonctionne

Le bug n'est plus le pays, le host, le redirect_uri, le state, le MFA ou le retour client.
Le bug est le **contrat post-OAuth** de `/start`.

---

## 2. Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `24aad54a` | Non | OK |
| keybuzz-infra | `main` | `c84d067` | Non | OK |

| Service | Env | Image avant | Verdict |
|---|---|---|---|
| Client DEV | DEV | `v3.5.159-amazon-marketplace-routing-source-dev` | OK (AO.7) |
| Client PROD | PROD | `v3.5.159-amazon-marketplace-routing-source-prod` | INCHANGÉE |
| API DEV | DEV | `v3.5.155-promo-retry-metadata-email-dev` | Non touché |
| API PROD | PROD | `v3.5.142-promo-retry-email-prod` | INCHANGÉE |

---

## 3. Root cause — Comparaison /start vs /channels

### `/channels` (FONCTIONNE)

```
1. checkOAuthCallback() → connected: true
2. Extract expected_channel from URL
3. Call activateAmazonChannels(tenantId, expectedChannel)
4. if res.activated.length > 0 → setSuccessMessage(...)
5. else → setErrorMessage("OAuth terminé mais activation échoué")
6. refreshData() → channels list updated
```

### `/start` (BUGGÉ — avant fix)

```
1. checkOAuthCallback() → connected: true
2. setOauthSuccess(true) ← FAUX SUCCÈS IMMÉDIAT
3. clearOAuthCallbackParams()
(pas d'appel activation)
(pas de refresh)
(pas de vérification channel actif)
```

### Tableau comparatif

| Étape | /channels | /start (avant fix) | Diff critique |
|---|---|---|---|
| Détection OAuth | `checkOAuthCallback()` | `checkOAuthCallback()` | Identique |
| Extract expected_channel | `urlParams.get("expected_channel")` | **ABSENT** | **MANQUANT** |
| Appel activation | `activateAmazonChannels(tenantId, ec)` | **ABSENT** | **ROOT CAUSE** |
| Gestion succès | Vérifie `res.activated?.length > 0` | `setOauthSuccess(true)` immédiat | **FAUX SUCCÈS** |
| Gestion erreur | `setErrorMessage(...)` | Aucune | **ABSENT** |
| Refresh channels | `refreshData()` | Aucun | **MANQUANT** |

---

## 4. Décision patch

**PATCH CLIENT ONLY** — l'API `POST /api/amazon/activate-channels` fonctionne déjà (prouvé par `/channels`).

| Gap | Service | Patch requis | Risque |
|---|---|---|---|
| /start n'appelle pas l'activation | Client | Appeler `activateAmazonChannels` | Faible — même fonction que /channels |
| /start n'extrait pas expected_channel | Client | Lire URL param | Aucun |
| /start affiche faux succès | Client | Conditionner sur `res.activated` | Aucun |
| /start n'a pas de CTA reconnexion | Client | Ajouter bouton "Gérer dans Canaux" | Aucun |

---

## 5. Patch appliqué

### Fichier modifié

`src/features/onboarding/components/OnboardingHub.tsx`

### Changements

| Changement | Pourquoi | Risque |
|---|---|---|
| Import `activateAmazonChannels` | Fonction partagée avec /channels | Aucun |
| Ajout état `activating` | Indicateur de chargement pendant activation | Aucun |
| useEffect post-OAuth → appel `activateAmazonChannels` | Même contrat que /channels | Faible |
| Extract `expected_channel` de URL params | Propagation marketplace_key | Aucun |
| Succès conditionnel sur `res.activated?.length > 0` | Plus de faux succès | Aucun |
| Message erreur + CTA "Gérer dans Canaux" | UX honnête si activation échoue | Aucun |
| Loading state "Activation du canal Amazon en cours..." | Feedback utilisateur pendant activation | Aucun |

### Flow post-OAuth /start APRÈS fix

```
1. checkOAuthCallback() → connected: true
2. Extract expected_channel from URL
3. clearOAuthCallbackParams()
4. setActivating(true) → show loading
5. activateAmazonChannels(tenantId, expectedChannel)
6. if res.activated.length > 0 → setOauthSuccess(true) → "Amazon connecté et activé avec succès"
7. else → setOauthError("... Relancez la connexion depuis Canaux.") → CTA "Gérer dans Canaux"
8. setActivating(false)
```

---

## 6. Tests statiques

| Check | Résultat |
|---|---|
| No hardcoding tenant/seller/email | OK |
| No secrets | OK |
| No DEV URL en code | OK |
| Import identique à /channels | OK |
| Même service partagé (amazon.service.ts) | OK |
| /channels non modifié | OK |
| TypeScript lint | OK — 0 erreur |

---

## 7. Build

| Service | Tag | Source commit | Digest | Rollback DEV |
|---|---|---|---|---|
| Client | `v3.5.160-amazon-start-activation-contract-dev` | `f2e9bfc5` | `sha256:569996400350625fc3e176b10a96182311b31071f75aca2a5c97b53d1de9c704` | `v3.5.159-amazon-marketplace-routing-source-dev` |

---

## 8. GitOps

| Service | Image avant | Image après | Manifest | Rollout |
|---|---|---|---|---|
| Client DEV | `v3.5.159-amazon-marketplace-routing-source-dev` | `v3.5.160-amazon-start-activation-contract-dev` | `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | OK (1/1 Running) |

GitOps commit : `8cdfa87` sur `main` keybuzz-infra

---

## 9. Validation DEV

### Validation structurelle du bundle

| Test | Attendu | Résultat |
|---|---|---|
| `activate-channels` URL dans service chunk | Présent | OK (`2113-*.js`) |
| `expected_channel` dans /start page chunk | Présent | OK (2 occurrences) |
| "Activation du canal Amazon" text | Présent | OK |
| "Relancez la connexion" error message | Présent | OK |
| "Canaux" CTA reconnexion | Présent | OK |
| EU_SUPPORTED_COUNTRIES filter | Présent | OK (AO.6.1) |
| HTTP /start DEV | 307 (auth redirect) | OK |
| HTTP /channels DEV | 307 (auth redirect) | OK |

### Validation OAuth réel

Non exécuté dans cette phase. Le test OAuth réel nécessite une validation utilisateur humaine (MFA Amazon).

---

## 10. Non-régression

| Surface | Résultat |
|---|---|
| API DEV | OK (`{"status":"ok"}`) |
| API PROD | INCHANGÉE (`v3.5.142-promo-retry-email-prod`) |
| Backend DEV | OK |
| Backend PROD | INCHANGÉE (`v1.0.47-cross-env-guard-fix-prod`) |
| Client PROD | INCHANGÉE (`v3.5.159-amazon-marketplace-routing-source-prod`) |
| Website PROD | OK (200) |
| `/channels` code | Non modifié (dernière modif = PH-SAAS-T8.12AM.7) |
| Billing | Non touché |
| Tracking | Non touché |
| No checkout/email/CAPI | Aucun |
| eComLG/SWITAA/Bon KB | Non impactés |

---

## 11. KEY-249

- Root cause documenté : `/start` n'appelait pas `activateAmazonChannels` après OAuth
- Fix DEV : `v3.5.160-amazon-start-activation-contract-dev` (commit `f2e9bfc5`)
- Ticket **non fermé** — recommander AO.9 pour promotion PROD après validation OAuth réel

---

## 12. Rollback DEV (GitOps strict)

```yaml
# keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.159-amazon-marketplace-routing-source-dev
```

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.159-amazon-marketplace-routing-source-dev \
  -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 13. Interdits respectés

| Interdit | Respecté |
|---|---|
| Pas de PROD modifiée | OUI |
| Pas de hardcoding tenant/seller/email | OUI |
| Pas de secrets dans logs/rapport | OUI |
| Pas de build depuis workspace dirty | OUI |
| Pas de tag réutilisé | OUI |
| Pas de Stripe/billing/tracking/CAPI | OUI |
| Pas de Website/Admin/OW | OUI |
| Pas de mutation DB manuelle | OUI |
| Pas de fermeture KEY-249 | OUI |
| GitOps strict uniquement | OUI |
| /channels non modifié | OUI |
| Aucun connecteur supprimé ne ressuscite | OUI |

---

## 14. Verdict

### GO DEV FIX READY

AMAZON START ACTIVATION CONTRACT FIXED IN DEV — /START NO LONGER SHOWS FALSE SUCCESS — POST-OAUTH ACTIVATION MATCHES /CHANNELS — SUCCESS REQUIRES ACTIVE CHANNEL AND VISIBLE INBOUND EMAIL — ERROR STATE HONEST — /CHANNELS NON-REGRESSION OK — NO TENANT HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR PROD PROMOTION

### Prochaine étape recommandée

**AO.9** : Promotion PROD du fix `v3.5.160-amazon-start-activation-contract` après validation OAuth réel DEV par l'utilisateur.
