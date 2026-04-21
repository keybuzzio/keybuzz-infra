# PH-AUTOPILOT-BACKEND-REAL-EMAIL-READINESS-01 — Rapport Final

> Date : 2026-04-21
> Type : validation terrain DEV + readiness PROD
> Priorite : P0

---

## Verdict : REAL EMAIL DEV AUTOPILOT PIPELINE VALIDATED — PROD READINESS ESTABLISHED — GO PROD PROMOTION

---

## 1. Validation vrai email SWITAA DEV

### Tenant

| Champ | Valeur |
|---|---|
| Tenant ID | `switaa-sasu-mnc1x4eq` |
| Nom | SWITAA SASU |
| Plan | **AUTOPILOT** |
| Status | active |

### Email reel de Ludovic

| Champ | Valeur |
|---|---|
| Adresse inbound | `amazon.switaa-sasu-mnc1x4eq.fr.ulnllr@inbound.keybuzz.io` |
| Expediteur | `switaa26@gmail.com` (Switaa 26) |
| Heure reception | 2026-04-21 14:36:48 UTC |
| Contenu | Demande concernant reparation article, commande 171-544451-556985, colis 1Z121122512368 |

### Pipeline complet

| Etape | Resultat | Preuve |
|---|---|---|
| Email reel identifie | **OUI** ✅ | ExternalMessage `cmmo8q92bb6c42e7e94ffa2` dans product DB |
| ExternalMessage product DB | **OUI** ✅ | `tenantId=switaa-sasu-mnc1x4eq`, `createdAt=14:36:48.506Z` |
| Conversation creee | **OUI** ✅ | `cmmo8q92di3139f78d18f5098` |
| Message inbound cree | **OUI** ✅ | `cmmo8q92dpad54635086fa65a`, direction=inbound |
| Callback API status | **OUI** ✅ (infere) | `autopilot_reply` dans ai_action_log a 14:36:55 (7s apres inbound) |
| ai_action_log autopilot_reply | **OUI** ✅ | `alog-1776782215100-55yrdhfm9` conversation=`cmmo8q92di3139f78d18f5098` |
| Draft applique | **OUI** ✅ | `alog-1776782383699-ipwbjq4vd` action_type=`draft_applied` a 14:39:43 |
| Reponse outbound envoyee | **OUI** ✅ | Message `msg-1776782383961-bklumrzc6` direction=outbound, contenu professionnel contextualise |

### Preuve Autopilot

La reponse autopilot generee contient :
- Reference a la commande 171-544451-556985
- Reference au colis 1Z121122512368
- Comprehension du contexte (article recupere pour reparation)
- Ton professionnel et engagement de suivi

Delai : 7 secondes entre l'email inbound et `autopilot_reply`, 3 minutes avant `draft_applied` + envoi outbound.

### Pipeline temporel

```
14:36:48.000 — Email reel recu (webhook backend)
14:36:48.506 — ExternalMessage cree (productDb)
14:36:48.xxx — Conversation + message crees
14:36:55.104 — ai_action_log: autopilot_reply (7s)
14:39:43.703 — ai_action_log: draft_applied
14:39:43.965 — Message outbound envoye
```

---

## 2. Audit PROD lecture seule

### ExternalMessage PROD

| Base | Existe ? | Rows |
|---|---|---|
| `keybuzz_prod` (product DB) | **OUI** | 620 |
| `keybuzz_backend_prod` (Prisma DB) | **NON** | - |

### Code v1.0.44 PROD

| Verification | Resultat |
|---|---|
| `prisma.externalMessage` dans webhook | **0 matches** — code absent |
| `productDb.*ExternalMessage` dans webhook | **0 matches** — code absent |
| Callback autopilot dans inboxConversation | **0 matches** — code absent |

**Decouverte critique** : v1.0.44 PROD ne contient NI le check ExternalMessage NI le callback Autopilot. Ces fonctionnalites ont ete ajoutees dans des commits posterieurs au build v1.0.44. Cela explique pourquoi la PROD fonctionne sans probleme : elle n'accede pas du tout a ExternalMessage.

### Environnement PROD

| Variable | Valeur | Statut |
|---|---|---|
| `API_INTERNAL_URL` | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:3001` | **A CORRIGER** → `:80` |
| Service API port | `80:3001` (port 80 → targetPort 3001) | Mismatch avec `API_INTERNAL_URL` |
| `DATABASE_URL` | `keybuzz_backend_prod` | OK |
| `PRODUCT_DATABASE_URL` | `keybuzz_prod` | OK |
| Image backend PROD | `v1.0.44-ph150-thread-fix-prod` | Non touchee |

### Risques PROD

| Risque | Statut |
|---|---|
| P2021 ExternalMessage (actuel) | **AUCUN** — v1.0.44 n'utilise pas ExternalMessage |
| P2021 ExternalMessage (apres promo v1.0.46) | **AUCUN** — v1.0.46 utilise productDb (fixe) |
| Callback port mismatch (actuel) | **AUCUN** — v1.0.44 n'a pas de callback |
| Callback port mismatch (apres promo) | **A CORRIGER** — changer `API_INTERNAL_URL` en `:80` |

---

## 3. Verdict : GO PROD PROMOTION

### Conditions validees

1. ✅ Vrai email SWITAA DEV valide de bout en bout
2. ✅ Callback Autopilot confirme sur tenant plan AUTOPILOT
3. ✅ ExternalMessage PROD compris (product DB, pas de risque)
4. ✅ Correction PROD limitee a : image backend + API_INTERNAL_URL
5. ✅ Rollback clair : `v1.0.44-ph150-thread-fix-prod`

### Plan de promotion recommande

```bash
# 1. Build image PROD (meme commit f0f0d18, meme code que DEV)
cd /opt/keybuzz/keybuzz-backend
PROD_TAG="ghcr.io/keybuzzio/keybuzz-backend:v1.0.46-ph-recovery-01-prod"
docker build --no-cache -t "$PROD_TAG" .
docker push "$PROD_TAG"

# 2. Corriger API_INTERNAL_URL PROD (port 80, pas 3001)
kubectl set env deployment/keybuzz-backend -n keybuzz-backend-prod \
  API_INTERNAL_URL=http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:80

# 3. Deployer image PROD
kubectl set image deployment/keybuzz-backend keybuzz-backend="$PROD_TAG" -n keybuzz-backend-prod
kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-prod

# 4. Verifier
kubectl get pods -n keybuzz-backend-prod -l app=keybuzz-backend
curl -s https://backend.keybuzz.io/health

# 5. GitOps : mettre a jour keybuzz-infra/k8s/keybuzz-backend-prod/deployment.yaml
```

### Rollback PROD d'urgence

```bash
kubectl set image deployment/keybuzz-backend \
  keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-ph150-thread-fix-prod \
  -n keybuzz-backend-prod
kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-prod
```

---

## 4. Ce qui change en PROD avec v1.0.46

| Fonctionnalite | v1.0.44 (actuel) | v1.0.46 (apres promo) |
|---|---|---|
| ExternalMessage idempotence | ABSENT | productDb (keybuzz_prod) |
| ExternalMessage create | ABSENT | productDb (keybuzz_prod) |
| Callback Autopilot | ABSENT | POST /autopilot/evaluate (API interne) |
| Stubs backfill | ABSENTS | Presents (compilation) |
| InboundAddress update | Prisma (keybuzz_backend_prod, 0 rows) | Prisma (keybuzz_backend_prod, 0 rows) — inchange |

### Nouveau comportement attendu en PROD

Apres v1.0.46, chaque email inbound PROD :
1. Creera un `ExternalMessage` dans `keybuzz_prod` (idempotent)
2. Creera une conversation + message via `createInboxConversation()`
3. Declenchera le callback `POST /autopilot/evaluate` vers l'API
4. L'API evaluera et executera l'Autopilot selon les settings du tenant

---

## 5. PROD non touchee

- AUCUNE image PROD buildee
- AUCUN manifest PROD modifie
- AUCUN `kubectl set image` PROD
- AUCUN `kubectl set env` PROD
- AUCUNE donnee PROD modifiee
- Image PROD : `v1.0.44-ph150-thread-fix-prod` (inchangee)

---

## 6. Preflight

| Element | Valeur |
|---|---|
| Image backend DEV | `v1.0.46-ph-recovery-01-dev` ✅ |
| Image backend PROD | `v1.0.44-ph150-thread-fix-prod` ✅ |
| Image API DEV | `v3.5.91-autopilot-escalation-handoff-fix-dev` ✅ |
| Image API PROD | `v3.5.91-autopilot-escalation-handoff-fix-prod` ✅ |
| Branche backend | `main` ✅ |
| HEAD | `f0f0d18` PH-RECOVERY-01 ✅ |
| Repo clean | 0 dirty files ✅ |
| Backend DEV health | OK ✅ |
| API DEV health | OK ✅ |
| Backend DEV restarts | 0 ✅ |

---

## 7. Historique des images backend

| Version | Tag | Phase | Etat |
|---|---|---|---|
| v1.0.44 | `ph150-thread-fix-prod` | PH150 | PROD actuelle |
| v1.0.45 | `autopilot-backend-callback-dev` | PH-CALLBACK-01 | DEV remplacee (P2021) |
| v1.0.46 | `ph-recovery-01-dev` | PH-RECOVERY-01 | **DEV actuelle** ✅ |
| v1.0.46 | `ph-recovery-01-prod` | PH-RECOVERY-01 | **A BUILDER pour PROD** |
