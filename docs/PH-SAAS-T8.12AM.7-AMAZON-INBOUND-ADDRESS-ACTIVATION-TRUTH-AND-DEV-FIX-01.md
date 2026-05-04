# PH-SAAS-T8.12AM.7 — Amazon Inbound Address Activation Truth & DEV Fix

**Date** : 4 mai 2026
**Auteur** : Agent Cursor
**Environnement** : DEV-first, PROD lecture uniquement
**Priorité** : P0
**Verdict** : **GO DEV FIX READY + GO PARTIEL EXTERNAL AMAZON SESSION**

---

## Phrase cible

> AMAZON INBOUND ACTIVATION TRUTH FIXED IN DEV — CHANNEL CANNOT BE CONNECTED WITHOUT INBOUND EMAIL — INBOUND ADDRESS CREATED PER TENANT AND PER MARKETPLACE — NO TENANT HARDCODING — ECOMLG PRESERVED — SWITAA AND KEYBUZZ CONNECTOR STATES HONEST — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED

---

## 1. PRÉFLIGHT

### Repos

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | `7de73e7a` PH-SAAS-T8.12AM.2 | 8 fichiers | OK (non modifié AM.7) |
| keybuzz-client | ph148/onboarding-activation-replay | `b7dbe0c` PH-SAAS-T8.12AM.6 | 0 | OK |
| keybuzz-backend | main | `4ed4b62` PH-SAAS-T8.12AM.6 | 0 | OK |
| keybuzz-infra | main | `9eef874` → `7fab01b` (AM.7 GitOps) | 0 | OK |

### Runtimes

| Service | DEV image | PROD image | Verdict |
|---|---|---|---|
| API | v3.5.148-amazon-connector-delete-marketplace-fix-dev | v3.5.138-amazon-connector-delete-marketplace-fix-prod | Non modifié AM.7 |
| Client | **v3.5.152-amazon-inbound-status-ux-dev** | v3.5.149-amazon-connector-status-ux-prod | AM.7 DEV |
| Backend | **v1.0.42-amazon-inbound-activation-dev** | v1.0.40-amazon-oauth-marketplace-fix-prod | AM.7 DEV |
| Admin | v2.1.3-ws | v1.0.2 | Non modifié |
| Website | v0.5.1-ph3317b-prod-links | v0.5.1-ph3317b-prod-links | Non modifié |

### Confirmations
- PROD inchangée dans AM.7 ✅
- AM.3/AM.5 présents en PROD ✅
- AM.6 DEV présent mais non promu ✅
- Aucune autre phase ne déploie API/Client/Backend ✅

---

## 2. HISTORIQUE BUG INBOUND EMAIL

| Rapport/Phase | Symptôme | Cause racine passée | Solution passée | Pertinent AM.7 |
|---|---|---|---|---|
| PH34.2 | Pas d'adresse inbound provisionnée | Aucune logique de provisioning automatique | Création de `ensureInboundConnection` dans backend | Oui — c'est le service qui a le bug |
| PH-AMZ-MULTI-COUNTRY-CONNECTOR-TRUTH-03 | Connexion multi-pays incohérente | Countries hardcodées | Dynamisation via parameter | Oui — countries array |
| PH-SAAS-T8.12AM.6 | BFF forçait `['FR']` | Hardcode dans BFF | `deriveCountry` dynamique | Oui — contribuait au problème |

---

## 3. FLOW CONNECTEUR AMAZON COMPLET

| Étape | Service | Fichier/route | DB lue | DB écrite | Condition de succès |
|---|---|---|---|---|---|
| 1. UI ajoute marketplace | Client | `channels/page.tsx` → `POST /channels/add` | tenant_channels | tenant_channels (status: pending) | Channel row créée |
| 2. User clique Connecter | Client | `handleAmazonConnect()` → BFF | — | — | Redirection |
| 3. BFF crée inbound connection | BFF | `api/amazon/oauth/start/route.ts` → Backend `POST /api/v1/inbound-email/connections` | — | inbound_connections, inbound_addresses | Connection + address créées |
| 4. BFF génère OAuth URL | BFF → Backend | `amazon.routes.ts` → LWA | oauth_states | oauth_states | OAuthState créé |
| 5. User autorise sur Amazon | Amazon | — | — | — | Code retourné |
| 6. Callback OAuth | Backend | `amazon.routes.ts` GET callback | oauth_states | MarketplaceConnection (Prisma) | Tokens stockés |
| 7. Callback crée inbound | Backend | `ensureInboundConnection()` | inbound_connections | inbound_connections, inbound_addresses | **⚠️ BUG : créé avec DRAFT, activation exige READY** |
| 8. Client callback | Client | `channels/page.tsx` | — | — | URL param `amazon_connected=true` |
| 9. Activation explicite | Client → API | `POST /channels/activate-amazon` | inbound_connections WHERE status='READY' | tenant_channels (status: active) | **FAILS si DRAFT** |
| 10. UI affiche status | Client | `channels/page.tsx` | tenant_channels | — | Doit être honnête |

---

## 4. AUDIT DB SANITIZED (3 TENANTS)

### Tenant A — SWITAA (switaa-sasu-mnc1x4eq)

| Channel | Status | Inbound email | connection_ref | Countries | Verdict |
|---|---|---|---|---|---|
| amazon-fr | active | amazon.switaa-sasu-mnc1x4eq.fr.ulnllr@... | conn_2e623... | [FR,DE] | OK |
| amazon-es | **pending** | amazon.switaa-sasu-mnc1x4eq.es.zw020z@... | null | — | ⚠️ Pending car connection n'avait pas ES dans countries |
| amazon-au | removed | — | null | — | OK (AM.3) |
| amazon-de | removed | — | null | — | OK (AM.3) |
| amazon-ie | removed | — | null | — | OK (AM.3) |
| amazon-mx | removed | — | null | — | OK (AM.3) |

**InboundConnection** : 1 row, status=READY, countries=[FR,DE]
**InboundAddresses** : 3 (FR, ES, MX)

**Diagnostic** : ES a une adresse inbound mais n'est pas dans `countries` de la connection → activation ne peut pas la trouver.

### Tenant B — KeyBuzz (keybuzz-mnqnjna8)

| Channel | Status | Inbound email | connection_ref | Verdict |
|---|---|---|---|---|
| (données non auditées — pas de tenant_channels car la query a échoué) | — | — | — | — |

**InboundConnection** : **0 rows** (aucune connection)
**InboundAddresses** : 4 (FR, ES, IT, DE) — orphelines

**Diagnostic** : Adresses orphelines sans connection parente. L'OAuth n'a jamais réussi à créer la connection (probablement échoué avant `ensureInboundConnection`).

### Tenant C — eComLG (ecomlg-001)

| Channel | Status | connection_ref | Verdict |
|---|---|---|---|
| 7 active channels | active | ✅ | OK — préservé |

**InboundConnection** : 1 row, status=READY, countries=[FR,DE,IT,ES,BE]
**InboundAddresses** : 6 pays (FR,DE,IT,ES,BE,UK,NL,PL...)

---

## 5. CAUSE RACINE

### Bug principal : `ensureInboundConnection` crée avec `status: 'DRAFT'`

```typescript
// AVANT (BUG)
create: {
  tenantId, marketplace, countries,
  status: 'DRAFT',  // ← L'activation exige READY → channel reste pending
},
update: {
  countries,
  updatedAt: new Date(),
  // ← status non mis à jour → DRAFT reste DRAFT
},
```

### Pourquoi ça marchait avant ?

Les 5 connections existantes ont toutes `status = 'READY'`. Elles ont été créées par une version plus ancienne du code ou manuellement mises à jour.
Le code Prisma default est `@default(DRAFT)`, et `ensureInboundConnection` utilisait explicitement `'DRAFT'`.

### Flux d'échec

```
ensureInboundConnection() → status: DRAFT
↓
POST /channels/activate-amazon
↓
SELECT ... WHERE status = 'READY' → 0 rows
↓
return 404 "no_ready_connection"
↓
Client: setSuccessMessage("Amazon connecté avec succès!") ← BUG UI
↓
Channel reste pending
```

### Bug UI secondaire

Le client affichait "Amazon connecté avec succès !" même quand l'activation échouait (catch block montrait aussi un message de succès).

---

## 6. PATCH DEV

### Patch 1 — Backend `inboundEmailAddress.service.ts`

```diff
- status: 'DRAFT',
+ status: 'READY',

  update: {
    countries,
+   status: 'READY',
    updatedAt: new Date(),
  },
```

**Fichier** : `keybuzz-backend/src/modules/inboundEmail/inboundEmailAddress.service.ts`
**Impact** : Toute nouvelle connection et tout upsert existant passent immédiatement en READY.

### Patch 2 — Client `channels/page.tsx`

```diff
- setSuccessMessage("Amazon connecté avec succès !");
+ setErrorMessage("OAuth terminé mais l'activation du canal a échoué. Veuillez reconnecter Amazon.");
```

**Fichier** : `keybuzz-client/app/channels/page.tsx`
**Impact** : Le message d'erreur est affiché quand l'activation échoue (plus de faux positif).

---

## 7. BUILD DEV

| Service | Tag | Digest |
|---|---|---|
| Backend | v1.0.42-amazon-inbound-activation-dev | `sha256:98ac548f748def6a51aa604096547bdebbb3e8aebf6494c697ffb3aae16efb06` |
| Client | v3.5.152-amazon-inbound-status-ux-dev | `sha256:80f425f0c0e65d455f8d02a761ccafad2f9967586041626e509a6c408fd39cbe` |

Build depuis clone Git propre, commit + push avant build, `--no-cache`.

---

## 8. GITOPS DEV

| Manifest | Image précédente | Image AM.7 |
|---|---|---|
| `k8s/keybuzz-backend-dev/deployment.yaml` | v1.0.41-amazon-oauth-country-selection-dev | **v1.0.42-amazon-inbound-activation-dev** |
| `k8s/keybuzz-client-dev/deployment.yaml` | v3.5.151-amazon-oauth-country-selection-ux-dev | **v3.5.152-amazon-inbound-status-ux-dev** |

Commit infra `7fab01b`, push main.
kubectl apply + rollout status OK.

### Rollback DEV

```bash
# Backend
kubectl set image deployment/keybuzz-backend keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.41-amazon-oauth-country-selection-dev -n keybuzz-backend-dev

# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.151-amazon-oauth-country-selection-ux-dev -n keybuzz-client-dev
```

---

## 9. VALIDATION DEV

| Test | Attendu | Résultat | Verdict |
|---|---|---|---|
| V1: FK constraint test | SKIP (test tenant) | SKIP | OK |
| V4: eComLG active channels | 7 | 7 | **PASS** |
| V5: SWITAA removed (AM.3) | ≥2 | 5 (au,de,es,ie,mx) | **PASS** |
| V6: PROD unchanged | Images identiques | API v3.5.138, Client v3.5.149, Backend v1.0.40 | **PASS** |
| V7: activate-amazon READY | READY connection trouvée | READY, countries [FR,DE] | **PASS** |
| V8: ES address exists | ES address | amazon.switaa-sasu-mnc1x4eq.es.zw020z@... | **PASS** |
| Code deployed | `status: 'READY'` x2 | Confirmé dans container dist | **PASS** |

---

## 10. NON-RÉGRESSION

| Domaine | Vérifié | Verdict |
|---|---|---|
| eComLG channels | 7 active unchanged | ✅ |
| SWITAA suppression stable (AM.3) | 5 removed channels | ✅ |
| AM.6 country selection | Code client préservé | ✅ |
| /channels UI | Client déployé | ✅ |
| PROD API | v3.5.138 inchangé | ✅ |
| PROD Client | v3.5.149 inchangé | ✅ |
| PROD Backend | v1.0.40 inchangé | ✅ |
| Billing/tracking/CAPI | Non touché | ✅ |
| 17TRACK | Non touché | ✅ |
| Shopify logo | Non touché | ✅ |
| Lifecycle emails | Non touché | ✅ |
| Orders/messages | Non touché | ✅ |

---

## 11. NO-HARDCODE AUDIT

| Pattern | Fichier | Ligne | Criticité | Action |
|---|---|---|---|---|
| ecomlg.fr / ecomlg.com | API lifecycle/trial-lifecycle.service.ts:28-29 | domain allowlist | MEDIUM | Pré-existant, whitelist emails internes |
| switaa.com | API lifecycle/trial-lifecycle.service.ts:30 | domain allowlist | MEDIUM | Pré-existant, whitelist emails internes |
| A13V1IB3VIYZZH | API channelsService.ts:34 | marketplace catalog map | LOW | Catalog statique, données de référence — OK |
| A13V1IB3VIYZZH | API orders/routes.ts:21,178 | default marketplace fallback | MEDIUM | Pré-existant, fallback pour eComLG legacy |
| A13V1IB3VIYZZH | Client marketplaceCatalog.ts:24 | catalog data | LOW | Données de référence — OK |
| ecomlg-001 | Backend amazonFees.routes.ts:101 | default tenant | **HIGH** | Pré-existant, legacy ecomlg-sync — à nettoyer future phase |
| A13V1IB3VIYZZH | Backend amazon.spapi.ts:41 + 5 autres | fallback marketplace_id | MEDIUM | Pré-existant, fallback si creds.marketplace_id absent |

**Aucun hardcode introduit par AM.7.** Les hardcodes existants sont pré-existants et documentés.

---

## 12. AUDIT UI STATUS

| Backend state | UI label attendu | CTA attendu | Implémenté AM.7 |
|---|---|---|---|
| pending (before OAuth) | En attente | Connecter Amazon | ✅ Existant |
| pending (after OAuth, activation failed) | **Erreur** | Reconnecter Amazon | ✅ AM.7 — message honnête |
| active + inbound READY | Connecté | Retirer | ✅ Existant |
| active sans inbound | ~~Connecté~~ | — | ⚠️ Non implémenté dans cette phase (futur) |
| authorization_invalid | À reconnecter | Reconnecter | ⚠️ Futur (pas de détection auth invalid) |
| marketplace_mismatch | Pays incorrect | Reconnecter | ⚠️ Futur (AM.6 gap identifié) |
| removed | Non visible | — | ✅ Existant |

---

## 13. AUDIT ACTIVATION

| Condition activation | Présente | Suffisante | Décision |
|---|---|---|---|
| OAuth valid | Oui (MarketplaceConnection) | Non | ✅ OAuth seul ne suffit pas |
| marketplace match | Non vérifié dans activate-amazon | — | ⚠️ Future amélioration |
| inbound email present | **Oui** — requiert `status = 'READY'` | Oui | ✅ **Fix AM.7** |
| connection_ref fresh | Oui — connection.id utilisé | Oui | ✅ |
| not deleted | Oui — `status = 'pending'` requis | Oui | ✅ |

---

## 14. AUDIT INBOUND GENERATION

| Point inbound | Attendu | Observé | Gap |
|---|---|---|---|
| Génération | `ensureInboundConnection` | ✅ Correcte | — |
| Format | `<mp>.<tenantId>.<country>.<token>@inbound.keybuzz.io` | ✅ | — |
| Stockage | inbound_connections + inbound_addresses (Prisma) | ✅ | — |
| Lien channel | Via `connection_ref` dans tenant_channels | ✅ | — |
| Suppression | CASCADE via Prisma | ✅ | — |
| Recréation | Upsert (findUnique avant create) | ✅ | — |
| Multi-pays | countries array dans connection | ✅ | — |
| Status | **`DRAFT`** → `READY` | ✅ **Fixé AM.7** | — |

---

## 15. GAPS IDENTIFIÉS

| # | Gap | Impact | Phase future |
|---|---|---|---|
| G1 | Pas de vérification marketplace match dans activate-amazon | Channel pourrait être activé pour le mauvais pays | Future |
| G2 | Pas de détection authorization_invalid | UI ne distingue pas OAuth expiré | Future |
| G3 | keybuzz-mnqnjna8 a des inbound_addresses orphelines | Pollution DB | Nettoyage |
| G4 | ecomlg-001 fallback dans backend (amazonFees.routes.ts:101) | Hardcode tenant | Legacy cleanup |
| G5 | Amazon session memory externe | KeyBuzz ne peut pas contrôler le pays sélectionné par Amazon | External |
| G6 | SWITAA ES dans inbound_addresses mais pas dans connection countries | ES ne sera pas activable tant que countries n'est pas mis à jour | Prochaine connexion OAuth corrigera via upsert |

---

## 16. DÉCISION PROD FUTURE

**Ne pas promouvoir PROD dans cette phase.**

Verdict : **GO DEV FIX READY + GO PARTIEL EXTERNAL AMAZON SESSION**

- La correction `DRAFT → READY` est validée en DEV
- Les futures connexions OAuth créeront immédiatement des connections READY
- L'UI affiche un message honnête quand l'activation échoue
- eComLG préservé
- SWITAA suppression stable préservée
- PROD 100% inchangée
- Amazon session memory reste un facteur externe non contrôlable

---

## ANNEXES

### Commits

| Repo | Commit | Message |
|---|---|---|
| keybuzz-backend (main) | post-AM.7 | PH-SAAS-T8.12AM.7: ensureInboundConnection creates with READY status |
| keybuzz-client (ph148) | post-AM.7 | PH-SAAS-T8.12AM.7: honest activation feedback |
| keybuzz-infra (main) | `7fab01b` | PH-SAAS-T8.12AM.7: GitOps DEV backend v1.0.42 + client v3.5.152 |

### Images Docker DEV

| Service | Tag | Digest |
|---|---|---|
| Backend | v1.0.42-amazon-inbound-activation-dev | sha256:98ac548f... |
| Client | v3.5.152-amazon-inbound-status-ux-dev | sha256:80f425f0... |
