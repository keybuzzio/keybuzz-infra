# PH-SAAS-T8.12AS.20.14B-RETRIGGER-AMAZON-INBOUND-VALIDATION-PROD-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; KEY-348 observation deferred ; references PH-20.14 / PH-20.14A / KEY-231
> Phase : PH-SAAS-T8.12AS.20.14B-RETRIGGER-AMAZON-INBOUND-VALIDATION-PROD
> Environnement : PROD (read-only first ; AUCUNE mutation executee)

## 1. Verdict

GO RETRIGGER AMAZON INBOUND VALIDATION PROD BLOCKED PH-SAAS-T8.12AS.20.14B

Le gate mail est OK (containment KEY-323 tient, 0 storm). Les 3 adresses Amazon PENDING sont identifiees. Le flow legitime de re-trigger est identifie (POST /api/v1/marketplaces/amazon/inbound-address/send-validation). MAIS ce flow exige une SESSION AUTHENTIFIEE (JWT tenant, ou super_admin) : le handler resout le tenant depuis l utilisateur authentifie (preHandler: authenticate = devAuthenticateOrJwt). Le CE ne peut pas invoquer ce flow en headless sans (a) forger un JWT (necessiterait la cle de signature dans les secrets = interdit), ou (b) exploiter le bridge DEV X-User-Email en PROD (bypass d authentification = interdit et risque securite). Aucune autre voie interne non-authentifiee n existe pour ce endpoint.

Donc : trigger NON execute, AUCUNE mutation, AUCUN flip DB, AUCUN bypass. Le re-trigger doit etre fait par une action utilisateur authentifiee (Ludovic dans Settings > Channels, ou un appel super_admin authentifie), puis une phase de verification confirmera PENDING -> VALIDATED.

PH-20.13B push Client reste SUSPENDU.

## 2. Sources relues

PH-20.14, PH-20.14A, KEY-323 FIX/ESCALATE/READONLY-AUDIT/APPLY ; PH-MAIL-INBOUND-DIAGNOSTIC-03, PH-MAIL-OBSERVE-07 ; PH-AMAZON-OUTBOUND-TRUTH-03, AMAZON-OUTBOUND-SOURCE-OF-TRUTH ; AI_MEMORY RULES_AND_RISKS.

## 3. Preflight

| Service/Host | Etat | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| infra main | 7bc5f35 | OK |
| keybuzz-api PROD | 1/1 Running | OK |
| keybuzz-outbound-worker PROD | 1/1 Running | OK |
| keybuzz-backend PROD (84996c47fd-rhzrf) | 1/1 Running 7j23h | OK |
| mail-core-01 postfix | active, check OK | OK |

## 4. Mail stability gate (KEY-323 containment)

| Signal | Attendu | Resultat | Verdict |
|---|---|---|---|
| postfix active + check | OK | active + CHECK_OK | OK |
| Queue mail-core | en baisse | 1118 requests / 4070 Ko (1910 -> 1755 -> 1118) | drainage OK |
| 454/421 storm (15 min) | 0 | 0 | STABLE |
| transport inbound.keybuzz.io | webhook: | inbound.keybuzz.io -> webhook: | PRESERVE |

## 5. Adresses Amazon PENDING (avant, product DB lue par le worker)

| Ref | Tenant masque | Country | Email masque | Status | lastInboundAt | createdAt |
|---|---|---|---|---|---|---|
| A1 | bon-kb-mos... | ES | amazon.bon-kb-mo... | PENDING | null | 2026-05-06 |
| A2 | bon-kb-mos... | FR | amazon.bon-kb-mo... | PENDING | null | 2026-05-05 |
| A3 | ecomlg-mot... | FR | amazon.ecomlg-mo... | PENDING | null | 2026-05-06 |

Total amazon : PENDING=3 (2 tenants), VALIDATED=8 (inchange). 3 PENDING = limite du prompt (pas de depassement). 1 @inbound + 1 @amazonses encore en queue mail = a preserver.

## 6. Flow legitime de validation (identifie)

| Endpoint/Flow | Fichier | Action | Cible email | Mutation attendue | Verdict |
|---|---|---|---|---|---|
| POST /api/v1/marketplaces/amazon/inbound-address/send-validation | keybuzz-api compat/routes.ts:154 (proxy) -> backend amazon.routes.ts:533 | sendValidationEmail(connection.id, country) | self-test vers amazon.<tenant>.<country>.<token>@inbound.keybuzz.io (PAS marketplace) | validationStatus PENDING->VALIDATED a la reception webhook | flow OK mais AUTH requise |

Detail backend amazon.routes.ts:533 : preHandler = authenticate (devAuthenticateOrJwt) ; resout tenantId depuis user authentifie ; super_admin peut cibler un tenant ; reponse "Validation email sent. The validation becomes effective upon receiving a message (or forwarded email)." -> confirme self-test inbound, pas un message marketplace.

Chaine technique attendue (self-test loop) : backend sendValidationEmail -> job OUTBOUND_EMAIL_SEND -> SMTP mail-core-01 -> recipient @inbound.keybuzz.io -> transport webhook: LOCAL -> processValidationEmail -> VALIDATED + lastInboundAt. Independant des MX.

## 7. Trigger : NON execute (BLOCKED)

Aucun trigger execute. Raison : authentification requise non disponible au CE.

Options ecartees (toutes interdites/risquees) :
- Forger un JWT tenant/super_admin : necessite la cle de signature (secrets) -> INTERDIT (ne pas lire /opt/keybuzz/secrets).
- Bridge DEV X-User-Email en PROD : bypass d authentification -> INTERDIT (et risque securite).
- Appeler sendValidationEmail directement dans le pod backend (contourner l auth) : ce n est PAS le flow legitime authentifie ; ecarte.
- Flip DB PENDING->VALIDATED : INTERDIT.

## 8. Hand-off requis (action utilisateur authentifiee)

Pour declencher la validation legitimement, l une des voies suivantes (par Ludovic) :
1. UI Client : se connecter en tant que tenant impacte (ou super_admin) -> Settings > Channels > Amazon -> "Renvoyer la validation" pour chaque pays PENDING (ecomlg-mot FR ; bon-kb-mos FR ; bon-kb-mos ES). Une adresse a la fois.
2. OU fournir au CE un token super_admin scope (canal securise, hors secrets repo) pour une phase de re-trigger authentifiee dediee.

Apres declenchement, une phase de verification (read-only) confirmera : SMTP out mail-core, relay=webhook in, processValidationEmail, et product DB validationStatus PENDING->VALIDATED + lastInboundAt renseigne, sans flip DB.

## 9. Non-regression mail / Amazon

| Check | Avant | Apres (cette phase) | Verdict |
|---|---|---|---|
| mail-core queue | 1118 (drainage) | inchange (aucune action) | OK |
| 454/421 storm | 0 | 0 | OK |
| inbound.keybuzz.io webhook | present | present | PRESERVE |
| MX mail-mx-01/02 | inchanges | non touches | INTACT |
| Amazon PENDING/VALIDATED | 3 / 8 | 3 / 8 (inchange) | OK |
| outbound_deliveries | non touche | non touche | OK |

## 10. Amazon feature parity / anti-regression

| Feature | Etat attendu | Change | Verdict |
|---|---|---|---|
| Amazon outbound From = amazon.<tenant>.<country>.<token>@inbound.keybuzz.io | contrat | NON | PRESERVE |
| Guard outbound validationStatus=VALIDATED | bloque si PENDING | NON | PRESERVE |
| Amazon inbound threading / connector statuses | inchange | NON | PRESERVE |
| AMAZON_SPAPI_MESSAGING_ENABLED=false | off | NON | PRESERVE |
| PH-20.11C / PH-20.12B code API | inchange | NON | PRESERVE |
| PH-20.13B Client | suspendu | NON | SUSPENDU |

## 11. No fake metrics / events

| Signal | Source reelle | Fake interdit | Verdict |
|---|---|---|---|
| validationStatus | backend webhook reel | flip DB / fake | aucun fait |
| inbound/webhook | maillog reel | fake webhook | aucun |
| trigger | endpoint authentifie reel | fake trigger | non execute |

## 12. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| UPDATE inbound_addresses / flip VALIDATED | OUI | 0 (SELECT only) |
| retry outbound_deliveries | OUI | 0 |
| message marketplace / fake webhook / fake event | OUI | 0 |
| bypass guard / forge JWT / dev-bridge bypass | OUI | refuse, non fait |
| Postfix/MX/DNS mutation / postqueue -f / postsuper | OUI | 0 |
| build/push/deploy/kubectl mutation | OUI | 0 |
| secret/PII brut / lecture /opt/keybuzz/secrets | OUI | 0 (tenant/email masques) |
| Push Client PH-20.13B | OUI | suspendu |
| Bastion install-v3 + IP internes | OUI | verifie E0 |

## 13. Gaps

- Le re-trigger ne peut pas etre fait par le CE sans authentification legitime.
- Question ouverte (a verifier en phase de verification) : la validation backend (Prisma keybuzz_backend) doit propager validationStatus=VALIDATED vers la product DB keybuzz lue par le worker outbound ; les 8 VALIDATED historiques prouvent que la propagation a fonctionne par le passe, mais le mecanisme de sync devra etre re-verifie apres un nouveau trigger.

## 14. Rollback

N/A - aucune mutation executee. Seul artefact : ce rapport docs.

## 15. Prochaine phrase GO

Au choix de Ludovic :
- Apres declenchement UI par Ludovic : GO READONLY VERIFY AMAZON INBOUND VALIDATION PROD PH-SAAS-T8.12AS.20.14B-VERIFY (verifier SMTP/webhook/DB PENDING->VALIDATED + propagation product DB, read-only).
- OU si un token super_admin scope est fourni : GO RETRIGGER AMAZON INBOUND VALIDATION AUTHENTICATED PROD PH-SAAS-T8.12AS.20.14B.

Ensuite seulement, et uniquement si au moins une adresse pertinente est VALIDATED + mail stable + guard preserve : GO RETRY AMAZON OUTBOUND DELIVERIES PROD PH-SAAS-T8.12AS.20.14C (cible, non global).

STOP.
