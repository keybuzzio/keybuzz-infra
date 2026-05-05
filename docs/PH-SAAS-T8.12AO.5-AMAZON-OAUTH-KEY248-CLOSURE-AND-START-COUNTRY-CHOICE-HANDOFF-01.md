# PH-SAAS-T8.12AO.5 — Amazon OAuth KEY-248 Closure and Start Country Choice Handoff

> Phase : PH-SAAS-T8.12AO.5-AMAZON-OAUTH-KEY248-CLOSURE-AND-START-COUNTRY-CHOICE-HANDOFF-01
> Date : 5 mai 2026
> Environnement : PROD (read-only, documentation uniquement)
> Type : cloture documentaire + handoff produit
> Priorite : P1
> Ticket : KEY-248 (CLOSED), KEY-249 (CREATED, not started)
> Phase precedente : PH-SAAS-T8.12AO.4 (FK violation fix, Backend v1.0.46)
> Verdict : **GO KEY-248 CLOSED**

---

## Phrase cible

AMAZON OAUTH KEY-248 CLOSED — USER VALIDATION CONFIRMED — RETURN HOST CORRECT — CHANNEL ACTIVATION WORKS — INBOUND EMAIL VISIBLE — CONNECTOR STATE STABLE — BACKEND/API DB SPLIT FIX CONFIRMED — NO CONNECTOR RESURRECTION — NO TENANT HARDCODING — START COUNTRY CHOICE MOVED TO KEY-249 — NO CODE — NO BUILD — NO DEPLOY — PROD BASELINES PRESERVED

---

## 1. Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-infra | main | `048102d` | docs non lies (safe) | OK |

Phase documentation uniquement : aucune modification code, build, deploy ou runtime.

---

## 2. Baselines PROD verifiees (read-only, 5 mai 2026 21h47 UTC+2)

| Service | Manifest image | Runtime image | Restarts | Health | Rollout | Verdict |
|---|---|---|---|---|---|---|
| Backend PROD | `v1.0.46-amazon-oauth-activation-bridge-prod` | `v1.0.46-amazon-oauth-activation-bridge-prod` | 0 | OK (uptime 1888s) | Complete | **BASELINE AO.4** |
| API PROD | `v3.5.142-promo-retry-email-prod` | `v3.5.142-promo-retry-email-prod` | 0 | OK | Complete | **INCHANGE** |
| Client PROD | `v3.5.153-promo-visible-price-prod` | `v3.5.153-promo-visible-price-prod` | 0 | OK | Complete | **INCHANGE** |
| Website PROD | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | — | — | — | **INCHANGE** |
| OW PROD | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | 7 (preexist.) | — | — | **INCHANGE** |

Backend PROD `v1.0.46` est la baseline verrouilllee issue de AO.4. Aucun rollout en cours. Aucun restart anormal.

---

## 3. Synthese AO.4

| Element | Valeur |
|---|---|
| **Root cause** | Tenant `bon-kb-mosf283z` existait dans API DB (`keybuzz`) mais absent de Backend DB (`keybuzz_backend`). La FK `inbound_connections_tenantId_fkey` bloquait `prisma.inboundConnection.upsert()` avec `Foreign key constraint violated`. |
| **Consequence** | Aucune `inbound_connection` creee → BFF bridge 404 → API activation impossible → UI "OAuth termine mais l'activation du canal a echoue" |
| **Fix** | Ajout `prisma.tenant.upsert()` dans `ensureInboundConnection()` — auto-provisionne le tenant dans Backend DB si absent. Idempotent (`update: {}`). Handler P2002 pour conflits slug. |
| **Fichier modifie** | `src/modules/inboundEmail/inboundEmailAddress.service.ts` (Backend uniquement) |
| **Service modifie** | Backend uniquement |
| **Image PROD** | `v1.0.46-amazon-oauth-activation-bridge-prod` |
| **Source commit** | `d7f48fc` |
| **Digest** | `sha256:4a3529d3b4a4453a272a20c14e8651b2ec7abd37ebf5b4a2de2d1d3ff448bc3c` |
| **Multi-tenant** | Generique — zero hardcoding tenant/pays/seller/marketplace |
| **Validation eComLG** | 5 pays READY, slug/name inchanges |
| **Validation SWITAA** | 2 connections READY inchangees (API DB) |
| **Validation Bon KB** | Tenant auto-cree, connection READY, address `amazon.bon-kb-mosf283z.fr.fq7fep@inbound.keybuzz.io` |
| **Risque restant** | Backend/API DB desynchronisation subsiste structurellement, mais le fix auto-provisionne a la volee. Pas bloquant. |

---

## 4. Validation utilisateur Ludovic

Ludovic a confirme le fonctionnement du flux Amazon OAuth PROD apres le deploy AO.4 :

| Validation utilisateur | Resultat |
|---|---|
| Retour OAuth sur `client.keybuzz.io` | **OK** |
| Plus de redirect vers `backend.keybuzz.io/start` | **OK** |
| Canal Amazon connecte | **OK** |
| Adresse inbound email visible | **OK** |
| Statut stable apres navigation (aller-retour pages) | **OK** |
| Pas de resurrection connecteur supprime | **OK** |
| Pas de `invalid_state` | **OK** |
| Activation fonctionnelle depuis `/channels` | **OK** |

### Citation

> "Ok, ca fonctionne" — Ludovic, 5 mai 2026

---

## 5. Cloture KEY-248

### Commentaire Linear (pret a copier)

```
KEY-248 — Amazon OAuth Connector Activation — CLOSED

Root cause finale (AO.4) : le tenant existait dans l'API DB (keybuzz) mais pas dans la Backend DB (keybuzz_backend). La FK inbound_connections_tenantId_fkey bloquait la creation de la connection inbound.

Fix : auto-provision du tenant dans Backend DB via prisma.tenant.upsert() dans ensureInboundConnection(). Fix generique multi-tenant, Backend-only.

Phases du chantier :
- AO: env var overrides Vault redirect_uri (Backend v1.0.44)
- AO.1: PROD promotion env var override
- AO.2: safe returnTo redirect + CLIENT_APP_URL + open redirect guard (Backend v1.0.45)
- AO.3: PROD promotion returnTo fix
- AO.4: FK violation fix — auto-provision tenant in Backend DB (Backend v1.0.46)
- AO.5: closure documentaire (aucun runtime)

Backend PROD baseline : v1.0.46-amazon-oauth-activation-bridge-prod
API PROD : v3.5.142-promo-retry-email-prod (inchange)
Client PROD : v3.5.153-promo-visible-price-prod (inchange)

Validation Ludovic : OK — retour client, activation, inbound email visible, statut stable.

Gap restant non bloquant : /start ne demande pas le pays Amazon avant OAuth.
Transfere vers KEY-249 (PH-SAAS-T8.12AO.6).
```

### Action Linear manuelle

Passer KEY-248 a **Done**.

---

## 6. Handoff KEY-249

### Gap non bloquant

Dans le flow `/start`, KeyBuzz lance l'OAuth Amazon sans demander explicitement le pays/marketplace au vendeur. Amazon Seller Central Europe peut afficher un pays dependant de la session browser du vendeur (ex: Allemagne au lieu de France). Ce comportement est externe a KeyBuzz et ne peut pas etre controle.

KeyBuzz doit reduire l'ambiguite en demandant explicitement le marketplace avant de lancer l'OAuth depuis `/start`.

| Gap | Ticket | Phase recommandee | Bloquant KEY-248 ? |
|---|---|---|---|
| `/start` ne demande pas le pays Amazon avant OAuth | KEY-249 | PH-SAAS-T8.12AO.6-AMAZON-START-MARKETPLACE-CHOICE-UX-DEV-01 | **NON** |

### Specification fonctionnelle KEY-249

- Ajouter un selecteur de marketplace (FR/ES/IT/DE/PL/NL/BE/SE/UK) dans `/start` avant le bouton "Connecter Amazon"
- Le marketplace selectionne doit etre transporte comme `expected_channel` dans l'OAuth state
- Le flow OAuth reste identique a `/channels` apres le choix
- Si l'utilisateur ne choisit pas, proposer un defaut raisonnable (FR) ou rendre le choix obligatoire
- Le pays affiche par Amazon Seller Central Europe reste dependant de la session Amazon (comportement externe)
- La carte post-OAuth dans `/start` doit afficher le pays reellement active, pas le pays Amazon

### Architecture cible

```
/start
  → Step: "Choisir votre marketplace Amazon" (dropdown/cards)
  → Bouton "Connecter Amazon [FR/ES/...]"
  → OAuth Amazon (expected_channel=amazon-xx dans state)
  → Callback Backend → ensureInboundConnection
  → Redirect Client → BFF bridge → API activation
  → Carte connecteur avec statut + inbound email
```

---

## 7. Non-regression documentaire

Phase AO.5 est **documentation uniquement**. Aucune action runtime.

| Surface | Resultat |
|---|---|
| Code modifie | 0 fichier |
| Build Docker | 0 |
| Deploy K8s | 0 |
| Mutation DB | 0 |
| Email envoye | 0 |
| Checkout Stripe | 0 |
| Faux event CAPI | 0 |
| Tracking drift | 0 |
| Billing drift | 0 |
| PROD runtime modifie | 0 — baselines identiques avant/apres AO.5 |
| Secret expose | 0 |
| Rollback effectue | 0 |
| `kubectl set image` | 0 |
| `kubectl set env` | 0 |
| `kubectl patch` | 0 |
| `kubectl edit` | 0 |

---

## 8. Chronologie Amazon OAuth complete (finale)

| Phase | Description | Backend | API | Client | Verdict |
|---|---|---|---|---|---|
| AM.3 | Delete marketplace connector | v1.0.38 | v3.5.138 | — | DONE |
| AM.5 | Seller Central Europe OAuth | v1.0.39 | — | — | DONE |
| AM.6 | Callback reads expected_channel from returnTo | v1.0.39 | — | — | DONE |
| AM.7 | ensureInboundConnection creates with READY | v1.0.40 | — | — | DONE |
| AM.9 | Dual DB fix — GET inbound-connection route for BFF bridge | v1.0.41 | v3.5.139 | v3.5.151 | DONE |
| AM.9.1 | Inbound addresses + email in activation | v1.0.41 | v3.5.139 | v3.5.151 | DONE |
| AM.10 | PROD promotion AM.9 + AM.9.1 | v1.0.42 | v3.5.139 | v3.5.151 | DONE |
| AO | DEV fix — env var overrides Vault redirect_uri + cross-env guard | v1.0.44 | — | — | DONE |
| AO.1 | PROD promotion AO — Backend + LEGACY_BACKEND_URL fix | v1.0.44 | — | — | DONE |
| AO.2 | DEV fix — safe returnTo redirect + CLIENT_APP_URL + open redirect guard | v1.0.45 | — | — | DONE |
| AO.3 | PROD promotion AO.2 | v1.0.45 | — | — | DONE |
| **AO.4** | **Fix FK violation — auto-provision tenant in Backend DB** | **v1.0.46** | — | — | **DONE** |
| **AO.5** | **Closure KEY-248 + handoff KEY-249 (documentation uniquement)** | — | — | — | **DONE** |

### Baseline PROD finale

| Service | Image | Stable depuis |
|---|---|---|
| Backend | `v1.0.46-amazon-oauth-activation-bridge-prod` | AO.4 (5 mai 2026) |
| API | `v3.5.142-promo-retry-email-prod` | Pre-AO |
| Client | `v3.5.153-promo-visible-price-prod` | Pre-AO |
| Website | `v0.6.9-promo-forwarding-prod` | Pre-AO |
| OW | `v3.5.165-escalation-flow-prod` | Pre-AO |

---

## 9. Rollback GitOps strict (documentation reference)

Si un probleme apparait avec le Backend PROD AO.4 :

1. Modifier `keybuzz-infra/k8s/keybuzz-backend-prod/deployment.yaml` :
   ```yaml
   image: ghcr.io/keybuzzio/keybuzz-backend:v1.0.45-amazon-oauth-returnto-guard-prod
   ```
2. `git commit -m "rollback: Backend PROD to v1.0.45"` + `git push origin main`
3. Sur le bastion (`46.62.171.61`) : `git pull origin main`
4. `kubectl apply -f k8s/keybuzz-backend-prod/deployment.yaml`
5. `kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-prod`
6. Verifier : runtime = manifest = `v1.0.45-amazon-oauth-returnto-guard-prod`

Interdit : `kubectl set image`.

---

## 10. Interdits respectes

| Interdit | Respecte |
|---|---|
| Aucun code modifie | OUI |
| Aucun build Docker | OUI |
| Aucun deploy | OUI |
| Aucun `kubectl set image` | OUI |
| Aucune mutation DB | OUI |
| Aucun secret dans logs/rapport | OUI |
| Aucun hardcoding tenant/pays/seller | OUI (aucun code) |
| Aucun rollback | OUI |
| Aucune fermeture KEY-249 | OUI |
| Bastion : uniquement `46.62.171.61` | OUI |
| Aucune IP interdite | OUI |

---

## 11. Commits

| Repo | Commit | Message |
|---|---|---|
| keybuzz-infra | (ce rapport) | docs: PH-SAAS-T8.12AO.5 — KEY-248 closure + KEY-249 handoff |

---

## VERDICT

### GO KEY-248 CLOSED

AMAZON OAUTH KEY-248 CLOSED — USER VALIDATION CONFIRMED — RETURN HOST CORRECT (`client.keybuzz.io`) — CHANNEL ACTIVATION WORKS — INBOUND EMAIL VISIBLE — CONNECTOR STATE STABLE — BACKEND/API DB SPLIT FIX CONFIRMED (AO.4 `prisma.tenant.upsert()`) — NO CONNECTOR RESURRECTION — NO TENANT HARDCODING — ECOMLG/SWITAA/BON-KB SAFE — START COUNTRY CHOICE MOVED TO KEY-249 (PH-SAAS-T8.12AO.6) — NO CODE — NO BUILD — NO DEPLOY — PROD BASELINES PRESERVED — BILLING/TRACKING/CAPI UNCHANGED — GITOPS STRICT

---

**Rapport :** `keybuzz-infra/docs/PH-SAAS-T8.12AO.5-AMAZON-OAUTH-KEY248-CLOSURE-AND-START-COUNTRY-CHOICE-HANDOFF-01.md`
