# PH-SAAS-T8.12AS.20.14C-SOURCE-PATCH-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14 / PH-20.14A / PH-20.14B / PH-20.14B-PIPE
> Phase : PH-SAAS-T8.12AS.20.14C-SOURCE-PATCH-AMAZON-VALIDATION-PIPELINE-DEV
> Environnement : DEV source patch only (no build, no deploy, no DB mutation)

## 1. Verdict

GO SOURCE PATCH AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14C

Le handler de job OUTBOUND_EMAIL_SEND, stub non implemente depuis PH11-06C, est maintenant implemente proprement et connecte au service SMTP existant. Typecheck OK, 15/15 tests cibles OK (sans DB ni SMTP reels). Aucun build, aucun deploy, aucune mutation DB, aucun email reel. Commit source local cree, non pousse (gate GO push). PH-20.13B push Client reste SUSPENDU.

## 2. Sources relues

| Source | Usage |
|---|---|
| PH-SAAS-T8.12AS.20.14B-PIPE (commit e8a58c3) | root cause: stub OUTBOUND_EMAIL_SEND + aucun jobsWorker deploye |
| PH-SAAS-T8.12AS.20.14B-VERIFY (commit 804d67b) | OutboundEmail vide, adresses PENDING |
| backend src/workers/jobsWorker.ts | stub a implementer + boucle worker |
| backend src/modules/jobs/jobs.service.ts | enqueueJob / claimNextJob / markJobDone / markJobFailed (retry maxAttempts=8) |
| backend src/modules/inboundEmail/inboundEmailValidation.service.ts | sendValidationEmail cree OutboundEmail PENDING + enqueue { outboundEmailId } |
| backend src/modules/outbound/outboundEmail.service.ts | service SMTP existant (nodemailer), sendEmail / retryEmail / sendViaSMTP |
| prisma/schema.prisma | OutboundEmail (toAddress, from, status, provider, error, sentAt), enum OutboundEmailStatus (PENDING/SENT/FAILED/RETRYING), enum OutboundEmailProvider (SMTP/SES) |

## 3. Preflight

| Repo/Service | Branche/Image | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| Bastion install-v3 | 46.62.171.61 | n/a | n/a | OK |
| keybuzz-backend | main | b183817 (avant patch) | 1 untracked amazon.routes.ts.bak | OK explique |
| keybuzz-api | ph147.4/source-of-truth | 38c048c | dist/*.js supprimes (dette PH147 connue) | OK attendu, non touche |
| keybuzz-infra | main | e8a58c3 | clean | OK |

Note dirty backend : amazon.routes.ts.bak est un backup untracked anterieur au fix OAuth (commit 1a4f141), 19246 vs 21180 octets, residu inoffensif. Non supprime (pas de git clean), non commit.

API PH147 non modifie : la route send-validation cote API est un proxy compat vers le backend ; le correctif est entierement cote backend.

## 4. Root cause reprise (PH-20.14B-PIPE)

Double rupture, independante du mail-core KEY-323 (contenu/stable) :
1. OUTBOUND_EMAIL_SEND etait un stub TODO ("not implemented") dans jobsWorker.ts depuis PH11-06C.
2. Aucun deploy/cronjob ne lance jobsWorker en PROD.

Consequence : sendValidationEmail cree un OutboundEmail PENDING + enqueue OUTBOUND_EMAIL_SEND, mais le job n etait jamais traite et le code ne savait pas envoyer -> email self-test jamais parti -> adresse Amazon bloquee PENDING.

Cette phase corrige (1) cote source. Le point (2) deploiement jobsWorker sera traite en PH-20.14D.

## 5. Design patch

| Decision | Choix | Justification | Risque |
|---|---|---|---|
| Le worker ne cree PAS de nouvel OutboundEmail | sendOutboundEmailById(id) recupere le record existant cree par sendValidationEmail | eviter doublons ; sendEmail() cree un record (inadapte ici) | nul |
| Idempotence | skip si statut deja SENT | reprise de job apres crash post-envoi | nul |
| Echec SMTP | marque FAILED + relance l exception | laisse le retry/backoff du Job queue (markJobFailed, maxAttempts=8) operer | nul |
| Provider persiste | mappe vers enum SMTP/SES (au lieu de la chaine minuscule via as any) | corrige bug latent : une ecriture SENT avec "smtp" minuscule serait rejetee par l enum DB | corrige un bug |
| Testabilite | injection optionnelle { sender, store } (defauts prod = nodemailer / prisma) | tests sans DB ni SMTP reels | faible |
| From | utilise email.from du record (validator@inbound.keybuzz.io) | ne reecrit jamais l expediteur ; contrat Amazon outbound intact | nul |
| Mode --once worker | opt-in minimal, defaut (boucle continue) inchange | worker:jobs:once deja declare dans package.json ; utile a la validation DEV PH-20.14D | faible |

Flow cible (inchange dans son intention) :
UI authenticated -> route send-validation -> sendValidationEmail (cree OutboundEmail PENDING + enqueue OUTBOUND_EMAIL_SEND { outboundEmailId }) -> jobsWorker OUTBOUND_EMAIL_SEND -> sendOutboundEmailById -> SMTP (service existant) -> email vers amazon.<tenant>.<country>.<token>@inbound.keybuzz.io -> mail-core -> webhook inbound -> processValidationEmail -> validationStatus=VALIDATED.

Cette phase corrige uniquement le segment OutboundEmail/job -> worker -> SMTP. Le segment webhook -> VALIDATED n est pas modifie. Pas de validation runtime dans cette phase.

## 6. Fichiers modifies

| Fichier | Changement | Risque | Test |
|---|---|---|---|
| src/modules/outbound/outboundEmail.service.ts | + parseOutboundEmailJobPayload, decideOutboundEmailAction, sendOutboundEmailById, types EmailSender/OutboundEmailStore/OutboundEmailRecord, defaultSender, prismaStore ; fix provider enum (helpers resolveProvider/providerEnum) applique aussi a sendEmail | faible | tsc + ts-node 15/15 |
| src/workers/jobsWorker.ts | OUTBOUND_EMAIL_SEND : parse payload + sendOutboundEmailById + log id/status ; runWorker(once) opt-in ; --once dans require.main | faible | tsc |
| tests/ph2014c-outboundEmail.test.ts | nouveau test standalone ts-node (hors src, non build) | nul | execute |

Diff total : 3 files changed, 375 insertions, 17 deletions. Le .bak untracked n est PAS commit.

## 7. Tests

| Test | Commande | Resultat | Verdict |
|---|---|---|---|
| Typecheck complet | npx tsc --noEmit -p tsconfig.json | TSC_OK | OK |
| parse payload valide / manquant / null / vide | ts-node | 4/4 PASS | OK |
| decide SENT->skip, PENDING/FAILED->send | ts-node | 3/3 PASS | OK |
| succes : retourne SENT, From preserve, enum provider majuscule | ts-node | 3/3 PASS | OK |
| echec : marque FAILED + relance | ts-node | 3/3 PASS | OK |
| idempotence : deja SENT -> sender non appele | ts-node | 1/1 PASS | OK |
| not found -> throw | ts-node | 1/1 PASS | OK |
| Total | ts-node | 15 passed, 0 failed (exit 0) | OK |

Aucun framework de test n existe dans keybuzz-backend ("test": echo no tests). Le test ajoute est un script standalone ts-node avec mocks injectes : aucune connexion DB (DATABASE_URL factice non joignable, store mocke), aucun SMTP reel (sender mocke), aucun email envoye. Le typecheck couvre l ensemble de src.

## 8. Anti-regression Amazon / AI feature parity

| Feature | Contrat | Impact patch | Verdict |
|---|---|---|---|
| Amazon outbound From | amazon.<tenant>.<country>.<token>@inbound.keybuzz.io via outboundWorker (keybuzz-api) | non touche (chemin different) | PRESERVE |
| Guard outbound validationStatus=VALIDATED | bloque tant que non VALIDATED | non touche, non bypasse | PRESERVE |
| Validation self-test From | validator@inbound.keybuzz.io (sendValidationEmail) | worker utilise email.from, ne reecrit pas | PRESERVE |
| Webhook inbound -> VALIDATED | processValidationEmail | non touche | PRESERVE |
| PH-20.11C guardrail guidance | inchange | aucun rapport | PRESERVE |
| PH-20.12B no-reply KBActions | inchange | aucun rapport | PRESERVE |
| PH-20.13B Client KBActions anxiety | image locale suspendue | non repris | SUSPENDU |
| Order-centric Amazon threading | inchange | aucun rapport | PRESERVE |
| outbound_deliveries marketplace | inchange | sendOutboundEmailById ne touche que OutboundEmail | PRESERVE |
| AMAZON_POLL / AMAZON_SEND_REPLY / INBOUND_EMAIL_PROCESS | handlers worker existants | inchanges (seul OUTBOUND_EMAIL_SEND modifie) | PRESERVE |

## 9. No fake metrics / no fake events

| Objet | Autorise en test | Interdit runtime | Verdict |
|---|---|---|---|
| OutboundEmail | store mocke en memoire | aucune ecriture DB runtime | OK |
| Validation VALIDATED | n/a | aucun flip DB | OK |
| Webhook inbound | n/a | aucun fake webhook | OK |
| Email SMTP | sender mocke | aucun email reel | OK |
| outbound delivery | n/a | aucun fake delivery | OK |

Aucun fake event, aucun fake KPI, aucun flip statut. validationStatus reste l etat reel (PENDING).

## 10. Side effects verification

| Side effect | Preuve | Verdict |
|---|---|---|
| Build image | docker images : aucune image 20.14/ph2014c | AUCUN |
| Deploy / kubectl mutation | aucune commande deploy/apply executee | AUCUN |
| dist/ modifie | tsc --noEmit n emet pas ; git status dist propre | AUCUN |
| Mutation DB | test = store mocke + DATABASE_URL factice non joignable | AUCUN |
| Email reel | sender mocke | AUCUN |
| Manifests PROD | infra clean, HEAD e8a58c3 inchange | AUCUN |
| PH-20.13B Client | non repris | SUSPENDU |
| Bastion / IP | install-v3 / 46.62.171.61 | OK |

## 11. Commits source

| Repo | Branche | Commit local | Pousse | Gate |
|---|---|---|---|---|
| keybuzz-backend | main | d6846b1 | NON | GO push requis |
| keybuzz-infra | main | (ce rapport, local) | NON | GO push requis |

Commit backend message : "fix(amazon): implementer envoi worker OUTBOUND_EMAIL_SEND (self-test validation PH-20.14C)". 3 fichiers, 375 insertions, 17 deletions. Le .bak untracked exclu.

## 12. Gaps restants

- Deploiement jobsWorker absent en PROD (et DEV) : a creer en PH-20.14D (manifest GitOps). Sans ce deploy, aucun worker ne consommera OUTBOUND_EMAIL_SEND meme apres build.
- inboundConnection des tenants PENDING : la route send-validation renvoie 404 "No inbound connection" si absente. A verifier avant re-trigger (PH-20.14B post-deploy).
- sendValidationEmail filtre par marketplaceStatus !== VALIDATED quand country absent ; comportement existant non modifie.
- jobsWorker conserve une seule instance PrismaClient (pattern existant). Non modifie.
- backfill-scheduler ImagePullBackOff : incident infra distinct, hors scope.
- Pas de validation runtime du segment webhook -> VALIDATED (hors scope, sera couvert au deploy + re-trigger).

## 13. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Commit backend d6846b1 | git revert d6846b1 (apres push) ou reset local si non pousse | aucun (pas deploye) |
| Rapport infra | git revert du commit docs | aucun |
| Runtime | n/a, rien deploye | aucun |

## 14. Prochaine phrase GO

GO BUILD AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14D

PH-20.14D devra : (a) builder l image backend DEV depuis Git (build-from-git, tag immuable), ET (b) ajouter un deploiement jobsWorker DEV en GitOps (aucun n existe). Puis re-trigger validation authentifie + verify (PH-20.14B). Ne PAS proposer GO RETRY AMAZON OUTBOUND DELIVERIES tant que les adresses restent PENDING.

STOP.
