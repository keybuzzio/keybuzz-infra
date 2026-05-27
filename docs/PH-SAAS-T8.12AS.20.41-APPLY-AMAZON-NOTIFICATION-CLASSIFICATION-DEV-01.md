# PH-SAAS-T8.12AS.20.41-APPLY-AMAZON-NOTIFICATION-CLASSIFICATION-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.41 (APPLY AMAZON NOTIFICATION CLASSIFICATION DEV GITOPS)
> Environnement : DEV runtime, GitOps strict ; AUCUN apply PROD, build, docker push, DB mutation

## 1. Verdict

GO APPLY AMAZON NOTIFICATION CLASSIFICATION DEV GITOPS READY PH-SAAS-T8.12AS.20.41

Les 3 deployments DEV (keybuzz-backend, jobs-worker, keybuzz-api) sont bumpes vers les images PH-20.40 via GitOps strict : manifests modifies (ligne image uniquement), commit+push infra AVANT apply, kubectl apply -f, rollout OK, runtime=manifest=last-applied=digest GHCR attendu. No unintended processing (aucun outbound / AI suggestion / KBActions debit / claim declenche par l'apply). PROD strictement intact. jobs-worker conserve command jobsWorker.js + JOB_TYPES=OUTBOUND_EMAIL_SEND. message_source=SYSTEM non introduit. Aucun fake event/metric.

## 2. GitOps commit deploy

- Commit manifest DEV : 057c670 (98cf6a4..057c670), push origin main AVANT apply, ahead=0 dirty=0.
- 3 fichiers, ligne image uniquement : k8s/keybuzz-backend-dev/deployment.yaml, k8s/keybuzz-backend-dev/deployment-jobs-worker.yaml, k8s/keybuzz-api-dev/deployment.yaml.
- dry-run client+server : 3x "configured", 0 schema error, 0 ref :latest.

## 3. Services before / after

| service | namespace | image avant | image apres |
|---|---|---|---|
| keybuzz-backend | keybuzz-backend-dev | v1.0.56-amazon-inbound-dedup-dev | v1.0.57-amazon-notification-classification-dev |
| jobs-worker | keybuzz-backend-dev | v1.0.56-amazon-inbound-dedup-dev | v1.0.57-amazon-notification-classification-dev |
| keybuzz-api | keybuzz-api-dev | v3.5.256-autopilot-no-reply-kbactions-dev | v3.5.258-amazon-notification-classification-dev |

## 4. Runtime equality (E8)

| service | namespace | manifest=last-applied=pod (tag) | imageID digest | ready | restarts |
|---|---|---|---|---:|---:|
| keybuzz-backend | keybuzz-backend-dev | v1.0.57-amazon-notification-classification-dev | sha256:ab583b9c57bb47bddb35be594ffb8938bf7bd57d6f79b6f8906c341083c5d806 | true | 0 |
| jobs-worker | keybuzz-backend-dev | v1.0.57-amazon-notification-classification-dev | sha256:ab583b9c57bb47bddb35be594ffb8938bf7bd57d6f79b6f8906c341083c5d806 | true | 0 |
| keybuzz-api | keybuzz-api-dev | v3.5.258-amazon-notification-classification-dev | sha256:732e307befa75c23945fd3088b90e23361dba1ea98efa84245da6aa37d9a033b | true | 0 |

imageID digests == manifest digests GHCR PH-20.40 (backend ab583b9c, api 732e307b). jobs-worker pod : command ["node","dist/workers/jobsWorker.js"], JOB_TYPES=OUTBOUND_EMAIL_SEND (inchanges). NB : un pod api ancien (v3.5.256) etait encore en phase Running/Terminating juste apres rollout ; le pod courant du nouveau ReplicaSet (keybuzz-api-6c7b89d96f-wjzvb) porte bien v3.5.258 / digest 732e307b.

## 5. Snapshot before / after (E2/E9) - no unintended processing

| signal | before | after | verdict |
|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND DONE | 13 | 13 | inchange |
| Job OUTBOUND_EMAIL_SEND FAILED | 16 | 16 | inchange |
| OutboundEmail SENT | 13 | 13 | inchange (aucun envoi spontane) |
| OutboundEmail PENDING / FAILED | 1 / 14 | 1 / 14 | inchange |
| AMAZON_POLL lockedBy worker-1 | 0 | 0 | inchange (jobs-worker ne claim pas AMAZON_POLL) |
| MarketplaceOutboundMessage | 2 | 2 | inchange |
| ai_suggestion_events | 2660 | 2660 | inchange (aucune suggestion spontanee) |
| ai_actions_ledger (total) | 538 | 538 | inchange (aucun debit spontane) |
| ai_actions_ledger reason=ai_generation | 445 | 445 | inchange |
| AMAZON_POLL PENDING / DONE | 7 / 160806 | 9 / 160824 | scheduler poll cron continu, NON lie a l'apply (jobs-worker JOB_TYPES=OUTBOUND_EMAIL_SEND only) |

jobs-worker log apres apply : "Starting worker worker-1 types=OUTBOUND_EMAIL_SEND", heartbeat polls=30/60/90 claimed=0 "no job this poll". Aucun outbound declenche.

## 6. PROD intact (E10)

| service PROD | image | restarts | verdict |
|---|---|---:|---|
| keybuzz-backend (keybuzz-backend-prod) | v1.0.56-amazon-inbound-dedup-prod | 0 | intact |
| jobs-worker (keybuzz-backend-prod) | v1.0.56-amazon-inbound-dedup-prod | n/a | intact |
| keybuzz-api (keybuzz-api-prod) | v3.5.257-autopilot-no-reply-kbactions-prod | n/a | intact |

Aucun manifest PROD modifie, aucun apply PROD.

## 7. AI feature parity / no fake metrics

- Messages buyer Amazon (metadata.amazonIds.messageId) : jamais classes notification (guard !stableAmazonMessageKey) -- code embarque dans v1.0.57.
- Advisory lock amzmsg PH-20.26 (pg_advisory_xact_lock + computeInboundDedupLockScope) : present dans l'image deployee (verifie dist PH-20.39), P0 KEY-323 non regresse.
- Outbound KEY-323 + jobs-worker OUTBOUND_EMAIL_SEND : intacts (command/JOB_TYPES inchanges, 0 envoi spontane).
- Autopilot skip PH-20.12B : conserve dans v3.5.258 (engine.ts step 6.5).
- Nouveau skip AI Assist no-reply : deploye via keybuzz-api v3.5.258.
- BUYER_HANDLE_RX / buyer-wins : present.
- Conversations mixtes non modifiees ; pas de masquage conversation.
- message_source=SYSTEM non introduit.
- Aucun fake event/metric/webhook/ledger ; phase GitOps image-bump, 0 ecriture DB applicative.

## 8. No side-effect

- Aucun build, docker push, kubectl set/patch/edit, rollout restart.
- Aucune mutation DB, migration, trigger, replay, fake event.
- latest non touche.
- Seuls 3 manifests DEV modifies (ligne image) ; PROD intact ; infra clean apres push.

## 9. Rollback

git revert 057c670 dans keybuzz-infra (rouvre les lignes image precedentes v1.0.56-amazon-inbound-dedup-dev / v3.5.256-autopilot-no-reply-kbactions-dev) puis kubectl apply -f des 3 manifests DEV ; rollout. Images precedentes restent disponibles GHCR.

## 10. Limites restantes

- ph119 api non relance depuis PH-20.39 (toolchain) ; couvert par tsc-clean + classifier inchange + miroir backend 8/8.
- message_source=SYSTEM differe (phase Client-aware).
- Validation fonctionnelle runtime (notification reelle taggee platformNotification, SLA non arme, AI Assist skip) a faire en PH-20.42 read-only/QA controlee ; si aucun trafic notification, verdict ACTION_REQUIRED plutot que simulation.
- Cleanup historique, contraintes uniques DB, cross-tenant : phases separees.

## 11. Phrase cible

GO APPLY AMAZON NOTIFICATION CLASSIFICATION DEV GITOPS READY PH-SAAS-T8.12AS.20.41

STOP.
