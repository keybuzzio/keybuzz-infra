# PH-AUTOPILOT-BACKEND-DEV-INBOUND-RECEPTION-RECOVERY-01 — Rapport Final

> Date : 2026-04-21
> Type : diagnostic + fix critique — restauration reception inbound DEV
> Image DEV : `ghcr.io/keybuzzio/keybuzz-backend:v1.0.46-ph-recovery-01-dev`
> Digest : `sha256:6aae45da06e556fb74d1bd04d23f434020c59695f4cab634d8dc8ca9326382ed`

---

## Verdict : DEV INBOUND RECEPTION RESTORED — PROD UNTOUCHED — PROD PROMOTION BLOCKED UNTIL TRUE HTTP INBOUND VALIDATED

---

## Observation utilisateur

Ludovic a constate que les messages inbound ne parvenaient plus en DEV apres la phase `PH-AUTOPILOT-BACKEND-CALLBACK-01` (image `v1.0.45`). Les messages envoyés a l'adresse inbound Amazon FR DEV n'arrivaient plus dans les conversations KeyBuzz DEV. La PROD fonctionnait normalement.

---

## Cause racine : P2021 ExternalMessage — incompatibilite code/DB

### Diagnostic

Le code du webhook (`inboundEmailWebhook.routes.ts`) utilisait `prisma.externalMessage.findUnique()` et `prisma.externalMessage.create()` (Prisma ORM), qui se connectent a la DB Prisma `keybuzz_backend`.

Or, la table `ExternalMessage` a ete **supprimee** de `keybuzz_backend` lors de PH-TD-05 (16 mars 2026) et migree vers `keybuzz` (product DB). Le code Prisma cherchait une table inexistante → erreur `PrismaClientKnownRequestError: P2021`.

| Element | Valeur |
|---|---|
| Table `ExternalMessage` dans `keybuzz_backend` | **ABSENTE** (`exists: false`) |
| Table `ExternalMessage` dans `keybuzz` (product DB) | **PRESENTE** (39743 lignes) |
| Code webhook | `prisma.externalMessage.findUnique()` → cherche dans `keybuzz_backend` |
| Resultat | P2021 crash a la ligne 103 → `createInboxConversation()` jamais atteint |
| Consequence | Aucune conversation/message creee, aucun callback Autopilot |

### Pourquoi v1.0.44 fonctionnait-elle ?

Hypothese probable : la table `ExternalMessage` existait encore dans `keybuzz_backend` au moment ou v1.0.44 etait deployee en DEV. PH-TD-05 (16 mars 2026) a ensuite supprime la table sans mettre a jour le code backend. Le probleme existait en latence et est devenu visible lors du redeploy v1.0.45 parce que le code n'avait pas ete modifie pour utiliser `productDb` conformement au contrat PH-TD-05.

### L'erreur P2021 n'est PAS introduite par le callback

Le callback PH-CALLBACK-01 est dans `inboxConversation.service.ts`, pas dans le webhook. L'erreur P2021 est dans `inboundEmailWebhook.routes.ts` (lignes 103 et 143), qui n'a pas ete modifie par PH-CALLBACK-01. Le probleme preexistait — le callback n'a fait que reveler le probleme en deployant une nouvelle image.

---

## Fix applique : Option B — patch minimal

### Changement unique

Fichier : `src/modules/webhooks/inboundEmailWebhook.routes.ts`

| Avant | Apres |
|---|---|
| `prisma.externalMessage.findUnique(...)` | `productDb.query('SELECT id FROM "ExternalMessage" WHERE ...')` |
| `prisma.externalMessage.create(...)` | `productDb.query('INSERT INTO "ExternalMessage" ... ON CONFLICT DO NOTHING')` |

### Details

1. **Import ajoute** : `import { productDb } from "../../lib/productDb";`
2. **Idempotence** : migration de `prisma.externalMessage.findUnique()` vers `productDb.query()` avec les memes criteres (type + connectionId + externalId)
3. **Creation** : migration de `prisma.externalMessage.create()` vers `productDb.query()` avec INSERT ... ON CONFLICT DO NOTHING
4. **ID generation** : ajout de `createExternalMessageId()` (cuid-compatible) pour remplacer l'auto-generation Prisma
5. **Reference corrigee** : `externalMessage.id` → `extMsgId` dans la reponse

### Ce qui n'a PAS ete modifie

- `prisma.inboundAddress.updateMany()` reste sur Prisma (met a jour 0 lignes dans keybuzz_backend, non critique)
- Callback Autopilot dans `inboxConversation.service.ts` (inchange, fonctionne)
- Routes API, Autopilot engine, billing, settings, client, admin

---

## Images DEV avant/apres

| | Avant | Apres |
|---|---|---|
| Image | `v1.0.45-autopilot-backend-callback-dev` | `v1.0.46-ph-recovery-01-dev` |
| ExternalMessage | P2021 crash | productDb OK |
| Webhook inbound | BLOQUE | OPERATIONNEL |
| Callback Autopilot | Present (dans inboxConversation) | Present (inchange) |

---

## Validation webhook HTTP

| Test | Attendu | Resultat |
|---|---|---|
| Webhook HTTP 200 | OUI | **OUI** ✅ |
| ExternalMessage creee | OUI | **OUI** — `cmmo8pxfvn827d20e49b374` ✅ |
| Plus de P2021 | OUI | **OUI** ✅ |
| Conversation creee | OUI | **OUI** — `cmmo8pxfza0febf5a0f121ed0` ✅ |
| Message cree | OUI | **OUI** — `cmmo8pxfzi228567e35b3802c` ✅ |
| Callback Autopilot | status=200 | **status=200** ✅ |
| API Autopilot log | `MODE_NOT_AUTOPILOT:suggestion` | **Confirme** ✅ |

---

## Idempotence validee

| Test | Resultat |
|---|---|
| Reenvoi meme messageId | `{"success":true,"message":"Already processed"}` ✅ |
| Duplicate ExternalMessages | AUCUN ✅ |

---

## Non-regression DEV

| Verification | Resultat |
|---|---|
| Backend health | 200 OK ✅ |
| API health | 200 OK ✅ |
| Conversations | open=369, pending=50, resolved=58, escalated=2 ✅ |
| Messages total | 1378 ✅ |
| ExternalMessages total | 39744 ✅ |
| Pod restarts backend | 0 ✅ |
| Pod restarts API | 0 ✅ |
| Billing | Non impacte ✅ |
| PROD | Non touchee ✅ |

---

## PROD non touchee

- AUCUNE image PROD buildee
- AUCUN manifest PROD modifie
- AUCUN `kubectl set image` PROD
- Backend PROD : `v1.0.44-ph150-thread-fix-prod` (inchangee)
- API PROD : `v3.5.91-autopilot-escalation-handoff-fix-prod` (inchangee)

---

## Commits source

| Repo | Commit | Message |
|---|---|---|
| `keybuzz-backend` | `f0f0d18` | PH-RECOVERY-01: migrate ExternalMessage from Prisma to productDb (PH-TD-05 contract) |
| `keybuzz-infra` | (ce commit) | PH-RECOVERY-01: update backend-dev manifest to v1.0.46 |

---

## Manifest GitOps DEV

Fichier : `keybuzz-infra/k8s/keybuzz-backend-dev/deployment.yaml`

Image : `ghcr.io/keybuzzio/keybuzz-backend:v1.0.46-ph-recovery-01-dev`
Rollback : `v1.0.45-autopilot-backend-callback-dev`

---

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-backend keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.45-autopilot-backend-callback-dev -n keybuzz-backend-dev
```

---

## Etat du callback Autopilot apres recuperation

Le callback Autopilot de PH-CALLBACK-01 est **toujours present et fonctionnel** dans `inboxConversation.service.ts`. Il n'a pas ete touche par ce fix. Le pipeline complet est :

```
Email entrant
→ Postfix / mail server
→ POST /api/v1/webhooks/inbound-email (backend)
→ ExternalMessage idempotence (productDb ← FIX PH-RECOVERY-01)
→ ExternalMessage create (productDb ← FIX PH-RECOVERY-01)
→ createInboxConversation() (inboxConversation.service.ts)
→ Conversation + Message crees dans keybuzz (product DB)
→ Callback POST /autopilot/evaluate (API interne ← PH-CALLBACK-01)
→ [Autopilot] evaluateAndExecute()
→ Draft suggestion IA
```

---

## Problemes residuels documentes

1. **InboundAddress update** : `prisma.inboundAddress.updateMany()` met a jour `keybuzz_backend` (0 lignes) au lieu de `keybuzz` (1 ligne). Impact faible (metadata non critique). A migrer vers `productDb` dans une phase future.

2. **PROD ExternalMessage** : La PROD (`v1.0.44`) utilise aussi `prisma.externalMessage`. Il faut verifier si la table `ExternalMessage` existe toujours dans `keybuzz_backend_prod` (probable, car PH-TD-05 indique qu'elle a ete supprimee mais la PROD fonctionne). A investiguer avant promotion PROD.

3. **PROD API_INTERNAL_URL port mismatch** : `API_INTERNAL_URL` PROD pointe sur `:3001` mais le Service expose `:80`. A corriger lors de la promotion PROD du callback.

---

## Recommandation prochaine phase

1. **Test vrai email** : Ludovic doit valider en envoyant un vrai email a l'adresse Amazon FR DEV pour confirmer que Postfix/mail server → webhook → conversation fonctionne de bout en bout
2. **Audit PROD ExternalMessage** : verifier si la table existe encore dans `keybuzz_backend_prod` avant de promouvoir ce fix
3. **Migration InboundAddress** : migrer `prisma.inboundAddress.updateMany()` vers `productDb`
4. **Promotion PROD callback + fix** : une fois le vrai email valide, promouvoir v1.0.46 en PROD avec correction du port API_INTERNAL_URL
