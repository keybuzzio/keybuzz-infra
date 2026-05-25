# PH-SAAS-T8.12AS.20.14G-TER-RETRIGGER-AMAZON-INBOUND-VALIDATION-DEV-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14G / C-TER / F-TER
> Phase : PH-SAAS-T8.12AS.20.14G-TER (validation fonctionnelle controlee DEV)
> Environnement : DEV uniquement

## 1. Verdict

GO RETRIGGER AMAZON INBOUND VALIDATION DEV PARTIAL PH-SAAS-T8.12AS.20.14G-TER

Le pipeline mecanique fonctionne de bout en bout (le correctif schema toAddress @map("to") est PROUVE) : route send-validation 200 (plus de HTTP 500 toAddress), OutboundEmail cree + SENT, job OUTBOUND_EMAIL_SEND claim + DONE par jobs-worker scope, SMTP self-test parti, mail-core delivre relay=webhook, webhook /inbound-email recu et processValidationEmail execute. MAIS l adresse PENDING ciblee (cmk5caxx7, vrai destinataire du token) n est PAS passee VALIDATED. Cause : processValidationEmail resout l adresse par cle (tenant, marketplace, country) sans desambiguiser par token/connection/id ; tenant_test_dev ayant 2 adresses FR amazon (2 connections), le findUnique a mis a jour l AUTRE adresse (deja VALIDATED) au lieu de la PENDING. validationStatus global inchange (39 PENDING / 4 VALIDATED).

NE PAS promouvoir en PROD (PH-20.14H) : la condition "adresse DEV reellement passee PENDING->VALIDATED via le flow" n est pas remplie. Aucun flip DB effectue. Prochaine etape = corriger la resolution d adresse dans processValidationEmail (sous-phase source DEV).

## 2. Sources relues

PH-20.14G (echec toAddress), PH-20.14C-TER (schema map), PH-20.14F-TER (deploy v1.0.50), PH-20.14F-BIS, KEY-323 mail-core containment. AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, OPERATIONAL_SOURCE_OF_TRUTH.

## 3. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| infra HEAD | 17ef573 main | OK |
| API DEV image | v1.0.50-amazon-validation-pipeline-dev, Running, restarts=0 | OK |
| jobs-worker DEV image | v1.0.50, Running, restarts=0, scope types=OUTBOUND_EMAIL_SEND | OK |
| KEYBUZZ_DEV_MODE (API) | true | OK (auth DEV-mode legitime) |

## 4. Snapshot before

| Source | Before | Verdict |
|---|---|---|
| Amazon inbound par validationStatus | PENDING 39 / VALIDATED 4 | OK |
| OutboundEmail | SENT 10 / FAILED 14 | OK |
| Job OUTBOUND_EMAIL_SEND | DONE 9 / FAILED 16 ; PENDING/RUNNING 0 | OK (pas de job ambigu) |
| jobs-worker | healthy, 0 AMAZON_POLL claim | OK |

## 5. Adresse cible

| Ref | Tenant | Country | Status | emailAddress | Choisie |
|---|---|---|---|---|---|
| cmk5caxx7 | tenant_test_dev (interne) | FR | PENDING | amazon.tenant_test_dev.fr.TOKEN@inbound.keybuzz.io | OUI |

Seul tenant DEV interne avec User en DB (dev@keybuzz.io SUPER_ADMIN) et adresse amazon PENDING. NB : tenant_test_dev possede DEUX adresses FR amazon (2 connections cmj9z9qwu DRAFT + cmk5caxwe DRAFT) ; l autre (cmj9z9r1k) etait deja VALIDATED.

## 6. Auth / flow legitime

| Element | Valeur | Verdict |
|---|---|---|
| Endpoint | POST /api/v1/marketplaces/amazon/inbound-address/send-validation | OK |
| Methode | curl interne pod -> service keybuzz-backend:4000 | OK |
| Auth | devAuthenticateOrJwt DEV-mode : header X-User-Email + KEYBUZZ_DEV_MODE=true, user resolu en DB | legitime (pas un bypass) |
| Tenant cible | tenant_test_dev (resolu depuis le user) | OK |
| Payload | {"country":"FR"} | OK |

Aucun JWT forge, aucun secret lu, aucun appel direct a sendValidationEmail, aucun SQL.

## 7. Trigger

| Ref | Trigger time UTC | HTTP status | Response | Verdict |
|---|---|---|---|---|
| cmk5caxx7 (FR) | 2026-05-25T21:32:38Z | 200 | {"ok":true,"message":"Validation email sent"} | OK (plus de 500 toAddress) |

Une seule requete. Plus d erreur Prisma toAddress : le correctif @map("to") est valide au runtime.

## 8. OutboundEmail / Job

| Objet | Avant | Apres | Delta | Verdict |
|---|---|---|---|---|
| OutboundEmail SENT | 10 | 11 | +1 | OK (cree + envoye) |
| Job OUTBOUND_EMAIL_SEND DONE | 9 | 10 (cmplq2ti1 done) | +1 | OK |
| sendOutboundEmailById (worker) | n/a | log "[OutboundEmail] cmplq2t9n sent (provider=smtp)" | present | OK |
| AMAZON_POLL claim par worker | 0 | 0 | 0 | OK |

Logs worker : Claimed OUTBOUND_EMAIL_SEND ... tenant tenant_test_dev -> sent (provider=smtp) -> done status=SENT. Aucune erreur.

## 9. SMTP / webhook

| Signal | Observe | Verdict |
|---|---|---|
| API log | [Validation] Queued email to amazon.tenant_test_dev.fr.812g37@inbound.keybuzz.io | OK |
| mail-core outbound | 39CCE3E61E from validator@inbound.keybuzz.io, DKIM signe | OK |
| mail-core delivery | to=amazon.tenant_test_dev.fr.812g37@inbound.keybuzz.io relay=webhook status=sent (delivered via webhook service) | OK |
| Backend webhook | POST /api/v1/webhooks/inbound-email recu ; [Webhook] Received inbound email | OK |
| processValidation | [Validation] Address amazon.tenant_test_dev.fr.812g37@inbound.keybuzz.io pipelineStatus marked as VALIDATED ; processed | EXECUTE mais mauvaise ligne (voir 10/15) |
| mail-core storm 421/454 | 0 nouveau | STABLE |

## 10. DB validation

| Ref | Status before | Status after | lastInboundAt before | lastInboundAt after | Verdict |
|---|---|---|---|---|---|
| cmk5caxx7 (PENDING cible, token 812g37) | PENDING/PENDING | PENDING/PENDING (inchange, updatedAt Jan-08) | null | null | NON VALIDE |
| cmj9z9r1k (autre FR, deja VALIDATED) | VALIDATED/VALIDATED | VALIDATED/VALIDATED, updatedAt=2026-05-25T21:32:41 (touche) | - | - | re-valide a tort |
| Amazon validationStatus counts | PENDING 39 / VALIDATED 4 | PENDING 39 / VALIDATED 4 | - | - | INCHANGE |

L adresse cible n est pas passee VALIDATED. PAS de flip DB manuel (interdit respecte). Chain break documente section 15.

## 11. Non-regression

| Check | Before | After | Verdict |
|---|---|---|---|
| jobs-worker healthy | Running restarts=0 | Running restarts=0 | OK |
| AMAZON_POLL claim par worker | 0 | 0 | OK |
| Workers amazon dedies (orders/items) | gerent AMAZON_POLL | inchange | OK |
| mail-core | stable | stable (1 self-test legitime, 0 storm) | OK |
| outbound_deliveries retry | 0 | 0 | OK |
| PROD | non touche | non touche | OK |

## 12. Anti-regression / AI feature parity

| Feature | Contrat | Change cette phase | Verdict |
|---|---|---|---|
| Amazon outbound From | tenant inbound address | inchange | OK |
| Guard validationStatus=VALIDATED | non bypasse | non bypasse (validationStatus cible reste PENDING) | OK |
| Inbound webhook reel | utilise | oui (relay=webhook reel) | OK |
| PH-20.11C guardrails | preserve | non touche | OK |
| PH-20.12B no-reply KBActions | preserve | non touche | OK |
| PH-20.13B Client | suspendu | non touche | OK |
| outbound deliveries | pas de retry | 0 | OK |

## 13. No fake metrics / events

| Objet | Change | Verdict |
|---|---|---|
| validation / webhook / OutboundEmail / delivery / KBActions | reels (flow reel), aucun fake, aucun flip DB | OK |

OutboundEmail et webhook sont reels (flow legitime). Aucun fake event, aucun forcage de validationStatus.

## 14. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| PROD | OUI | DEV namespace + DB DEV uniquement |
| retry outbound / message marketplace | OUI | 0 |
| fake webhook | OUI | webhook reel via mail-core |
| DB UPDATE manuel | OUI | aucun (constat read-only ; aucun flip) |
| build / push / deploy / GitOps | OUI | 0 |
| mail-core / MX / DNS | OUI | non touche |
| JWT forge / secret / bypass | OUI | DEV-mode legitime documente |
| Client PH-20.13B | OUI | non touche |

## 15. Gaps (chain break)

1. **Resolution d adresse dans processValidationEmail (inbound.service.ts ~L213-238)** : utilise findUnique({ tenantId_marketplace_country }) -> ne desambiguise pas par token/connectionId/id. Quand un tenant a plusieurs adresses pour le meme (marketplace,country) (multi-connection), la mauvaise adresse est validee. Ici : recipient = cmk5caxx7 (token 812g37, PENDING) mais update applique a cmj9z9r1k (deja VALIDATED). Correctif propose (sous-phase source DEV) : resoudre l adresse cible par token (parsed.token) ou par emailAddress exact, pas par (tenant,marketplace,country).
2. **send-validation : resolution connection sans country/address-id** : la route resout la connection par tenant+marketplace ; a verifier qu elle vise bien l adresse PENDING attendue quand plusieurs connections existent.
3. **pipelineStatus vs validationStatus** : processValidationEmail met les deux a VALIDATED (correct), mais sur la mauvaise ligne. Pas de divergence de colonne en soi.
4. Connections tenant_test_dev en DRAFT (pas READY) : a clarifier si attendu en DEV.

Aucune de ces causes ne remet en cause le correctif toAddress (PH-20.14C-TER), qui est prouve fonctionnel.

## 16. Prochaine phrase GO

NE PAS proposer GO PROMOTE AMAZON VALIDATION PIPELINE PROD PH-20.14H tant que la validation DEV n aboutit pas reellement sur une adresse PENDING.

Phrase recommandee : GO SOURCE PATCH VALIDATION ADDRESS RESOLUTION DEV PH-SAAS-T8.12AS.20.14I (corriger processValidationEmail pour cibler l adresse exacte par token/emailAddress), puis re-trigger PH-20.14G-QUATER sur l adresse PENDING, AVANT toute promotion PROD.

STOP.
