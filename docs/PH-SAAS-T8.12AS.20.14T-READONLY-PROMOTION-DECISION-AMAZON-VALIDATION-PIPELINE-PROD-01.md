# PH-SAAS-T8.12AS.20.14T-READONLY-PROMOTION-DECISION-AMAZON-VALIDATION-PIPELINE-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14S-BIS / PH-20.14X / PH-20.14W / PH-20.14U / PH-20.14S-RCA
> Phase : PH-SAAS-T8.12AS.20.14T (READONLY PROMOTION DECISION PROD)
> Environnement : PROD READ-ONLY strict (aucune mutation)

## 1. Verdict

GO READONLY PROMOTION DECISION AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14T

DEV v1.0.53 est prouve READY (PH-20.14S-BIS : cmk5caxx7 PENDING -> VALIDATED via flow reel complet). Audit PROD read-only termine. La promotion PROD est faisable et a faible risque : aucun jobs-worker PROD n existe (le OUTBOUND_EMAIL_SEND n a jamais eu de consommateur PROD), les tables Job/OutboundEmail PROD sont VIDES (donc deployer un jobs-worker ne consommerait aucun PENDING par surprise), les 11 adresses inbound Amazon PROD sont TOUTES PENDING en attente de validation, et les workers Amazon PROD (v1.0.40) sont des pollers SP-API dedies qui ne consomment PAS la Job queue generique (aucune interference avec le scope OUTBOUND_EMAIL_SEND). Decision : READY pour la phase apply PROD, avec deux points de decision/verification explicites avant trigger (image PROD-taggee a construire ; routage webhook mail-core PROD a confirmer). Aucune mutation PROD effectuee dans cette phase.

Prochaine phrase GO : GO APPLY AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14U-PROD (build image PROD v1.0.53 from 1179c15 + bump API + creer jobs-worker PROD via GitOps strict, STOP avant trigger).

## 2. Sources relues

PH-20.14S-BIS (DEV READY), PH-20.14X (apply DEV v1.0.53), PH-20.14W (push image), PH-20.14U (observabilite+JOB_TYPES), PH-20.14S-RCA. AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, DOCUMENT_MAP. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight

| Repo/service | branche/runtime | HEAD/digest | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-infra | main | HEAD=origin 9fc4fc4 | dirty=0 | OK |
| keybuzz-backend | main | HEAD=origin 1179c15 | dirty=1 (amazon.routes.ts.bak untracked) | OK |
| GHCR v1.0.53-amazon-validation-pipeline-dev | - | sha256:5b893934...886368 | present | OK |
| DEV API + jobs-worker | v1.0.53 | 5b893934 | ready (PH-20.14S-BIS READY) | OK |
| PROD backend API | v1.0.47-cross-env-guard-fix-prod | - | ready | INTACT (audit only) |
| Bastion install-v3 / 46.62.171.61 | - | - | - | OK |

## 4. Runtime PROD actuel (keybuzz-backend-prod)

| Service | image | command | ready | restarts | verdict |
|---|---|---|---|---|---|
| keybuzz-backend (API) | v1.0.47-cross-env-guard-fix-prod | (API) | 1/1 | 0 | a bumper -> v1.0.53 |
| amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod | node dist/workers/ordersWorkerResilient.js | 1/1 | 4 | poller dedie (hors scope) |
| amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod | node dist/workers/itemsWorkerResilient.js | 1/1 | 0 | poller dedie (hors scope) |
| backfill-scheduler | v1.0.42-td02-worker-resilience-prod | (scheduler) | 0/1 | 0 | KO pre-existant (hors scope, distinct) |
| jobs-worker | ABSENT | - | - | - | A CREER (gap central) |

cronjobs : amazon-orders-sync (*/5, image curl), amazon-reports-tracking-sync (0 */6). Sans rapport avec OUTBOUND_EMAIL_SEND.

## 5. Manifests GitOps PROD (k8s/keybuzz-backend-prod/)

| Manifest | existe | image actuelle | ecart DEV | verdict |
|---|---|---|---|---|
| deployment.yaml (API) | oui | v1.0.47 | bump -> v1.0.53 | a patcher |
| deployment-jobs-worker.yaml | NON | - | manquant | A CREER (mirroir DEV) |
| amazon-orders-worker-deployment.yaml | oui | v1.0.40 | hors scope | inchange |
| amazon-items-worker-deployment.yaml | oui | v1.0.40 | hors scope | inchange |
| deployment-backfill-scheduler.yaml | oui | v1.0.42 | hors scope | inchange |
| externalsecret-db / externalsecret-secrets | oui | - | - | reutilisables (db, secrets) |

Reference DEV jobs-worker (k8s/keybuzz-backend-dev/deployment-jobs-worker.yaml) : command node dist/workers/jobsWorker.js ; envFrom keybuzz-backend-db + keybuzz-backend-secrets + vault-token(optional) + amazon-spapi-creds ; env NODE_ENV=production, VAULT_ADDR, JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP_HOST=49.13.35.167, SMTP_PORT=25, SMTP_SECURE=false ; resources 256Mi/512Mi ; liveness ps jobsWorker. Le manifest PROD = meme structure, namespace keybuzz-backend-prod, secrets PROD (memes noms, tous presents).

## 6. SMTP PROD

| Source config | SMTP_HOST | SMTP_PORT | secure | auth present? | verdict |
|---|---|---|---|---|---|
| API PROD env direct | (absent) | - | - | - | API n envoie pas de validation |
| keybuzz-backend-secrets PROD (cles) | (aucune cle SMTP) | - | - | - | pas de SMTP en secret |
| jobs-worker DEV (inline, reference) | 49.13.35.167 (mail-core-01) | 25 | false | non (unauthenticated) | a repliquer inline en PROD |

Le relay mail-core-01 (49.13.35.167:25, non authentifie) est de l infra PARTAGEE (pas env-specifique) : le jobs-worker PROD utilisera le meme SMTP inline. mail-core stable (PH-20.14S-BIS : relay=webhook status=sent confirme il y a <1h). KEYBUZZ_DEV_MODE=false en PROD (correct ; le trigger PROD ne pourra PAS utiliser X-User-Email dev-mode -> le re-trigger PROD devra passer par l UI authentifiee reelle ou un mecanisme legitime PROD, a cadrer en phase trigger).

## 7. Inbound addresses Amazon PROD (E4)

| Address id | tenant masque | country | marketplace | vStatus | mStatus | lastInboundAt | verdict |
|---|---|---|---|---|---|---|---|
| cmou8lsnw000c7r01j4ntnps8 | bon-kb*** | ES | amazon | PENDING | PENDING | null | a valider |
| cmotxn8bs00067r01ioikv1wj | ecomlg*** | FR | amazon | PENDING | PENDING | null | a valider |
| cmot0g28900037o3ez1ftlg7a | bon-kb*** | FR | amazon | PENDING | PENDING | null | a valider |
| cmo7g2sdw000a4z01acgv6sr1 | ecomlg*** | FR | amazon | PENDING | PENDING | null | a valider |
| cmo6ay5wy00054z01fa27g0dv | ludo-g*** | FR | amazon | PENDING | PENDING | null | a valider |
| cmnvwva6l000f6i0144v9fgy2 | compta*** | FR | amazon | PENDING | PENDING | null | a valider |
| cmnvwsiz2000b6i01k1cwyqqe | ecomlg*** | PL | amazon | PENDING | PENDING | null | a valider |
| cmnvwpyl000076i01ceti7ggf | ecomlg*** | IT | amazon | PENDING | PENDING | null | a valider |
| cmnvwpykn00056i01c3biprug | ecomlg*** | ES | amazon | PENDING | PENDING | null | a valider |
| cmnvwpyk500036i01rm59ill8 | ecomlg*** | BE | amazon | PENDING | PENDING | null | a valider |
| cmmsdn4if0003at01cwu3p6if | ecomlg*** | FR | amazon | PENDING | PENDING | null | a valider |

Distribution : PENDING 11 / VALIDATED 0. Toutes marketplace="amazon" (minuscule) -> le fix casse 14O (resolution emailAddress exact insensible) est requis et present dans v1.0.53. Tokens presents (redacted). lastInboundAt null = jamais valide via aucun chemin. Ambiguite tenant+country : les slugs "ecomlg-*" sont des tenants DISTINCTS (ecomlg-motxke32, ecomlg-mo4h93e7, ecomlg-001, compta-ecomlg) ; pas de doublon meme-tenant+meme-country observe ; la garde 14I/14O resout par emailAddress exact de toute facon. Re-trigger PROD = UNE adresse a la fois.

## 8. Deliveries Amazon bloquees (E5)

| Scope | count | verdict |
|---|---|---|
| MarketplaceOutboundMessage (tous status) | 0 (table vide) | aucun backlog a retry |

Aucune delivery Amazon enregistree/bloquee en PROD. La phase "retry deliveries" n a aucun backlog a drainer : les messages marketplace couleront naturellement une fois les adresses VALIDATED (guard validationStatus=VALIDATED). Pas de retry de masse.

## 9. Job / OutboundEmail PROD (E6)

| Table | status | count | risk | verdict |
|---|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND | (aucun) | 0 | aucun | VIDE |
| OutboundEmail | (aucun) | 0 | aucun | VIDE |

Point critique resolu : deployer un jobs-worker PROD ne consommerait AUCUN OUTBOUND_EMAIL_SEND PENDING par surprise (0 PENDING). Pas de triage/purge requis avant apply. Le worker ne traitera que les jobs crees par des triggers send-validation explicites futurs.

## 10. Workers Amazon v1.0.40 / JOB_TYPES (E7)

| Worker | env JOB_TYPES | image | consomme Job queue generique ? | risk | action future |
|---|---|---|---|---|---|
| amazon-orders-worker | absent | v1.0.40 | NON (command ordersWorkerResilient.js ; claimNextJob uniquement dans jobsWorker.js) | aucun pour OUTBOUND | upgrade hygiene hors v1.0.40 (phase separee) |
| amazon-items-worker | absent | v1.0.40 | NON (command itemsWorkerResilient.js) | aucun | idem |
| jobs-worker PROD (futur) | OUTBOUND_EMAIL_SEND | v1.0.53 | OUI mais scope OUTBOUND_EMAIL_SEND seul | seul consommateur, jamais AMAZON_POLL | a creer |

Le hazard JOB_TYPES="" (RCA 14S) ne s applique PAS aux workers Amazon PROD : ils lancent des pollers dedies (ordersWorkerResilient/itemsWorkerResilient) qui n appellent jamais claimNextJob. Aucune interference avec le jobs-worker OUTBOUND_EMAIL_SEND. L upgrade hors v1.0.40 reste une hygiene separee, NON bloquante pour cette promotion.

## 11. Plan promotion PROD minimal (E8)

Phase suivante : GO APPLY AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14U-PROD.

DECISION IMAGE (point a confirmer avec Ludovic) : convention PROD = tags suffixes -prod (v1.0.47-...-prod, v1.0.40-...-prod). Deux options :
- (A recommandee) build v1.0.53-amazon-validation-pipeline-PROD from-git commit 1179c15 (convention respectee ; 1179c15 inclut le cross-env guard c62f376, donc superset de v1.0.47-cross-env-guard-fix-prod). Sous-etapes build + push + apply.
- (B) reutiliser l image -dev en PROD (plus rapide mais casse la convention -dev/-prod et le marquage d env). Non recommande.

Sequence apply (GitOps strict, option A) :
1. (si A) build v1.0.53-amazon-validation-pipeline-prod from 1179c15 -> push GHCR -> verifier digest.
2. Bump API deployment.yaml PROD v1.0.47 -> v1.0.53(-prod).
3. Creer deployment-jobs-worker.yaml PROD (mirroir DEV : command jobsWorker.js, JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP inline mail-core-01 49.13.35.167:25 secure=false, envFrom db/secrets/vault-token/amazon-spapi-creds, imagePullSecrets ghcr, namespace keybuzz-backend-prod).
4. dry-run client + server.
5. commit + push infra AVANT apply.
6. kubectl apply -f (API puis jobs-worker) + rollout status.
7. verifier runtime = manifest = last-applied = digest.
8. verifier no unintended processing : Job/OutboundEmail PROD restent vides (aucun trigger), AMAZON_POLL non impacte, mail-core stable, API boot sans erreur Prisma, startup observabilite jobs-worker visible.
9. STOP.

Phase suivante (apres apply) : re-trigger validation PROD CIBLEE, UNE adresse a la fois, sous observabilite ; verifier PENDING -> VALIDATED. NB : KEYBUZZ_DEV_MODE=false en PROD -> le trigger devra etre un appel send-validation authentifie reel (UI seller / session legitime), PAS le header X-User-Email dev-mode. A cadrer dans le prompt re-trigger PROD.

Phase suivante : retry outbound deliveries CIBLEES seulement apres VALIDATED (actuellement 0 backlog ; surveiller la reprise naturelle).

VERIFICATION BLOQUANTE avant re-trigger PROD (pas avant apply) : confirmer que mail-core route les adresses inbound PROD (@inbound.keybuzz.io) vers le webhook PROD (backend PROD /api/v1/webhooks/inbound-email), et non vers backend-dev. Signal positif : l API PROD porte le secret inbound-webhook-key (envFrom) -> PROD est cable pour recevoir le webhook. A confirmer explicitement en phase trigger.

## 12. Rollback (pour la phase apply future)

| Element | Rollback | Runtime impact |
|---|---|---|
| API PROD | re-apply deployment.yaml avec image v1.0.47 (commentaire rollback) via GitOps (git revert + apply), jamais kubectl set image | retour v1.0.47 |
| jobs-worker PROD (nouveau) | kubectl delete -f deployment-jobs-worker.yaml (ressource neuve) + git revert du manifest | suppression worker, aucun autre service impacte |
| Image v1.0.53-prod (si build) | immuable, conservee | aucun |

## 13. AI feature parity / anti-regression (E9)

| Feature | Etat | Verdict |
|---|---|---|
| Guard outbound validationStatus=VALIDATED | intact (non touche, audit only) | OK |
| From Amazon amazon.<tenant>.<country>.<token>@inbound.keybuzz.io | intact | OK |
| activation SP-API messaging | aucune | OK |
| retry outbound / fake webhook / fake email / fake job | 0 | OK |
| PH-20.11C / PH-20.12B / PH-20.13B | preserves | OK |
| PH-20.13B Client push | reste suspendu | OK |

## 14. No fake metrics / no fake events (E10)

| Objet | Etat | Verdict |
|---|---|---|
| fake metric / event / webhook / OutboundEmail / Job | 0 | OK |
| DB mutation / migration / validationStatus flip | 0 (SELECT only) | OK |

## 15. Interdits respectes

git reset/clean 0, docker build/push 0, kubectl apply/set/patch/edit 0, rollout restart 0, manifest edit 0, mutation DB/UPDATE/INSERT/DELETE 0, prisma migrate 0, trigger/email/retry 0, message marketplace 0, fake 0, secret/DSN/token/email complet affiche 0, deploy PROD 0, credentials/secrets non touches. Tous les acces DB = SELECT/groupBy/count read-only via pod API PROD.

## 16. Prochaine phase

GO APPLY AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14U-PROD : (option A recommandee) build v1.0.53-amazon-validation-pipeline-prod from 1179c15 -> push -> bump API PROD + creer jobs-worker PROD -> GitOps strict apply -> verifier digest + no unintended processing -> STOP avant trigger. Decision image (A/B) a confirmer. Phases ulterieures : re-trigger PROD cible (1 adresse, send-validation authentifie reel car KEYBUZZ_DEV_MODE=false) sous observabilite -> verify VALIDATED -> retry deliveries (0 backlog actuel). Verification bloquante avant trigger : routage webhook mail-core PROD. Hygiene separee : upgrade amazon-orders/items-worker hors v1.0.40. AUCUNE mutation PROD sans GO explicite de Ludovic.

Phrase cible : GO READONLY PROMOTION DECISION AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14T

STOP.
