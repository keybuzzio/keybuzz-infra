# PH-SAAS-T8.12AS.20.44-PUSH-IMAGE-AI-ASSIST-NOTIFICATION-SKIP-SCOPE-FIX-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.44 (PUSH IMAGE ONLY AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV)
> Environnement : DEV preparation, PUSH IMAGE ONLY ; aucun build/deploy/kubectl/DB/fake event

## 1. Verdict

GO PUSH IMAGE AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV DONE PH-SAAS-T8.12AS.20.44

Les 2 images DEV PH-20.43 sont poussees sur GHCR ; pull-back frais confirme config digest
remote == Image ID local pour les deux, RepoDigests = manifest digests, OCI labels conformes.
Bundle Client DEV re-verifie sur l'image remote (api-dev seul, PROD=0). latest non touche.
Runtime DEV/PROD inchanges, aucun manifest GitOps modifie, aucun build/deploy/kubectl/DB.

## 2. API push / pull-back

| signal | valeur |
|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.259-ai-assist-notification-scope-dev |
| Image ID local | sha256:499993fdb18d101f1a8dc836b7df7db211c3e47755608909253325173c57f05e |
| manifest digest (RepoDigest) | sha256:e31ff645deed1b1d8f906f138b18bd8804dd5cc75782994aa52a48449156a5e3 |
| config digest remote | sha256:499993fdb18d101f1a8dc836b7df7db211c3e47755608909253325173c57f05e |
| pull-back Image ID | sha256:499993fdb18d... (== local) |
| OCI revision / version | 15f0e5e570c26286bcf394d55718684a5574bec5 / v3.5.259-ai-assist-notification-scope-dev |
| verdict | MATCH (config digest == Image ID local ; pull-back identique) |

Layers : 3 pushed + 4 already-exist. Aucune reference latest dans le push.

## 3. Client push / pull-back

| signal | valeur |
|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev |
| Image ID local | sha256:8f41c7a48896d506e159d1b443e700717d4a73d55bd8747f6489f83dc374804b |
| manifest digest (RepoDigest) | sha256:019dea6325fcdfba47ec0d9fa2ee425b30287eb2c7a6e4e58f6178cea82e104e |
| config digest remote | sha256:8f41c7a48896d506e159d1b443e700717d4a73d55bd8747f6489f83dc374804b |
| pull-back Image ID | sha256:8f41c7a48896... (== local) |
| OCI revision / version | ad4e862a2e635de251757f382a6d00b8fd063748 / v3.5.259-ai-assist-notification-scope-dev |
| bundle DEV (pull-back) | verify-client-bundle-api-url.sh development : api-dev=2, api.keybuzz.io(PROD)=0 -> OK |
| verdict | MATCH (config digest == Image ID local ; pull-back identique ; bundle DEV conserve) |

Layers : 3 pushed + 4 already-exist. Aucune reference latest dans le push.

## 4. Latest / no side-effect

| signal | attendu | resultat |
|---|---|---|
| api:latest / client:latest GHCR | non touche | present remote, JAMAIS reference dans nos push (push explicite des seuls tags v3.5.259) |
| runtime api-dev | v3.5.258 inchange | v3.5.258-amazon-notification-classification-dev |
| runtime api-prod | v3.5.257 inchange | v3.5.257-autopilot-no-reply-kbactions-prod |
| runtime client-dev | v3.5.214 inchange | v3.5.214-ai-draft-blocked-reason-dev |
| runtime client-prod | v3.5.217 inchange | v3.5.217-clarity-client-restore-prod |
| runtime backend-dev | v1.0.57 inchange | v1.0.57-amazon-notification-classification-dev |
| api-dev pod restarts | 0 | 0 |
| manifests GitOps v3.5.259 | absent | absent |
| GHCR tags cibles | presents apres push | api + client v3.5.259 ON GHCR |

Aucun build, aucun kubectl, aucune DB mutation, aucun fake event/KBActions/ledger.

## 5. AI feature parity (preserve, audit image PH-20.43 + pre-push)

- API determineAiAssistNotificationSkip present (dist) ; garde amazonIds (BUYER_AMAZON_IDS_PRESENT) ;
  skip message-level (direction='inbound') ; reponse NO_REPLY_PLATFORM_NOTIFICATION ; debitKBActions
  (chemin normal) present.
- Client bundle DEV : skipped marker + texte neutre present ; api base = api-dev (PROD=0) ; Clarity
  wuk12h9i33 present ; vraies erreurs conservees (chemin error inchange).

## 6. No fake metrics / events

Aucun ai_suggestion_events, KBActions, ledger, webhook, replay, appel AI. Phase strictement
push image + verification digests.

## 7. Limites

- LiteLLM/Anthropic credits DEV : hors scope.
- v3.5.259 pousse mais NON deploye : runtime DEV reste v3.5.258 (api) / v3.5.214 (client).
- Validation runtime (skip message-level + UX skip neutre + parite buyer) a faire APRES apply DEV.

## 8. Prochaine etape

GO APPLY AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV GITOPS PH-SAAS-T8.12AS.20.45 :
- bump manifests DEV (commit+push AVANT apply) : keybuzz-api DEV v3.5.258 -> v3.5.259 ; keybuzz-client
  DEV v3.5.214 -> v3.5.259 ; kubectl apply -f uniquement ; rollout ; runtime=manifest=last-applied=digest.
- verify Client bundle/runtime + no unintended processing. PROD reste bloque jusqu'a validation DEV.

## 9. Phrase cible

GO PUSH IMAGE AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV DONE PH-SAAS-T8.12AS.20.44

STOP.
