# PH-SAAS-T8.12AS.20.14V-PROD-VERIFY-AMAZON-INBOUND-VALIDATION-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14U-PROD-APPLY / PH-20.14V-PROD / PH-20.14S-BIS
> Phase : PH-SAAS-T8.12AS.20.14V-PROD-VERIFY (READONLY VERIFY PROD apres action UI Ludovic)
> Environnement : PROD (read-only strict ; aucune mutation)

## 1. Verdict

GO READONLY VERIFY AMAZON INBOUND VALIDATION PROD ACTION_REQUIRED_UI PH-SAAS-T8.12AS.20.14V-PROD-VERIFY

Ludovic a reconnecte le connecteur Amazon FR pour ecomlg-001 (OAuth complete a ~11:40 UTC : credentials Vault stockes, connexion OAuth cmn7ewkgl0..., inbound address FR "ensured"). MAIS le self-test de validation n a PAS ete declenche : aucun OutboundEmail, aucun Job OUTBOUND_EMAIL_SEND, aucun relay mail-core pour ecomlg-001, l adresse FR reste PENDING. La reconnexion OAuth ne declenche pas l email de validation -- c est l action UI separee "Renvoyer la validation" qui le fait, et elle n a pas encore ete effectuee. Pipeline PROD sain (API + jobs-worker v1.0.53-prod digest 18f54575, scope OUTBOUND_EMAIL_SEND, SMTP mail-core-01). Aucune mutation, aucun trigger CE, aucun retry, no unintended processing.

Action requise (Ludovic) : sur Client PROD, connecte ludo.gonthier@gmail.com / tenant ecomlg-001, cliquer explicitement "Renvoyer la validation" sur le canal Amazon FR. Puis re-lancer ce VERIFY.

## 2. Runtime PROD (E0)

| Service | image | digest | ready | restarts | verdict |
|---|---|---|---|---|---|
| API keybuzz-backend | v1.0.53-amazon-validation-pipeline-prod | sha256:18f54575...886368 | true | 0 | OK |
| jobs-worker | v1.0.53-amazon-validation-pipeline-prod | sha256:18f54575...886368 | true | 0 | OK |

jobs-worker JOB_TYPES=OUTBOUND_EMAIL_SEND ; SMTP_HOST=49.13.35.167 SMTP_PORT=25 SMTP_SECURE=false.

## 3. Connecteur (E1)

| Tenant | user owner | marketplace | country | inbound connection id | OAuth connection (log) | updatedAt | verdict |
|---|---|---|---|---|---|---|---|
| ecomlg-001 (product : eComLG) | ludo.gonthier@gmail.com (owner) | amazon | FR | cmmsdn4fs0001at01z2dbzg68 | cmn7ewkgl00007501wyfjzm9c (OAuth FR, 11:40) | 2026-05-26T11:40:25Z | reconnecte (OAuth OK) |

Logs backend PROD ~11:40 : POST /api/v1/inbound-email/connections ; [Amazon Vault] Credentials stored for tenant ecomlg-001 ; [Amazon OAuth] OAuth flow completed ... connection cmn7ewkgl0... ; [InboundEmail] Ensuring connection ecomlg-001/amazon ; [Amazon OAuth] Inbound address created for ecomlg-001 countries: ['FR'] (idempotent) ; redirect amazon_connected=true&expected_channel=amazon-fr. ProxyAuth context : ludo.gonthier@gmail.com / ecomlg-001.

## 4. Adresse inbound active (E2)

| Address id | inbound connection | country | token | validationStatus | marketplaceStatus | lastInboundAt | active ? | verdict |
|---|---|---|---|---|---|---|---|---|
| cmmsdn4if0003at01cwu3p6if | cmmsdn4fs0001at01z2dbzg68 | FR | 4x*** | PENDING | PENDING | null | OUI (cible) | a valider |
| cmnvwpyk500036i01rm59ill8 | cmmsdn4fs... | BE | ub*** | PENDING | PENDING | null | oui | autre pays |
| cmnvwpykn00056i01c3biprug | cmmsdn4fs... | ES | zu*** | PENDING | PENDING | null | oui | autre pays |
| cmnvwpyl000076i01ceti7ggf | cmmsdn4fs... | IT | hz*** | PENDING | PENDING | null | oui | autre pays |
| cmnvwsiz2000b6i01k1cwyqqe | cmmsdn4fs... | PL | 36*** | PENDING | PENDING | null | oui | autre pays |

email FR : amazon.ecomlg-001.fr.4x***@inbound.keybuzz.io. Pas de nouvelle adresse creee par la reconnexion (5 adresses inchangees, FR createdAt/updatedAt 2026-03-15) ; l OAuth a "ensured" (idempotent) l adresse FR existante. Pas d ancienne adresse archivee distincte. Le tenant obsolete ludo-gonthier-ga4mpf-mo5ldw59 (keybuzz_backend only, hors product) reste hors scope.

## 5. OutboundEmail / Job (E3)

| Object | etat | verdict |
|---|---|---|
| OutboundEmail (global PROD) | VIDE | aucun email genere |
| OutboundEmail recents 6h | 0 | aucun |
| Job OUTBOUND_EMAIL_SEND (global PROD) | VIDE | aucun job |
| Job OUTBOUND_EMAIL_SEND recents 6h | 0 | aucun |
| jobs-worker logs claim/start/result/done | 0 | rien a traiter |

Aucun send-validation n a ete declenche -> pas d OutboundEmail, pas de Job.

## 6. Mail-core / webhook (E4)

| Maillon | evidence | result | verdict |
|---|---|---|---|
| mail-core relay ecomlg-001 (40 min) | aucune entree | pas d email de validation envoye | OK (coherent) |
| webhook backend PROD /inbound-email | aucun POST inbound-email pour validation ecomlg-001 | (seulement POST /inbound-email/connections = OAuth reconnect) | OK (coherent) |
| processValidationEmail | non execute (rien recu) | - | N/A |

NB : le seul trafic backend ecomlg-001 a 11:40 = le flow OAuth reconnect (connections), PAS un webhook inbound-email de validation.

## 7. Validation finale (E5)

| Address | validationStatus | lastInboundAt | updatedAt | verdict |
|---|---|---|---|---|
| cmmsdn4if (FR, cible) | PENDING | null | 2026-03-15T23:19:48Z | PAS encore validee |
| BE/ES/IT/PL ecomlg-001 | PENDING | null | inchange | non touchees |

Aucune transition. Aucune adresse VALIDATED.

## 8. No unintended processing (E6)

| Signal | etat | verdict |
|---|---|---|
| retry outbound | 0 | OK |
| MarketplaceOutboundMessage cree | 0 (table vide) | OK |
| message marketplace | 0 | OK |
| job autre que OUTBOUND_EMAIL_SEND traite par jobs-worker | 0 | OK |
| fake / mutation DB manuelle | 0 | OK |
| jobs-worker / API restarts | 0 / 0 | OK |

## 9. Decision (E7)

ACTION_REQUIRED_UI. Le connecteur Amazon FR ecomlg-001 est reconnecte (OAuth OK, creds Vault), mais aucun email de validation n a ete declenche : l adresse FR cmmsdn4if reste PENDING, 0 OutboundEmail / 0 Job. La reconnexion OAuth ne lance pas le self-test. Il faut l action UI explicite "Renvoyer la validation".

## 10. Prochaine phase

Action Ludovic : Client PROD (client.keybuzz.io), connecte ludo.gonthier@gmail.com -> tenant ecomlg-001 -> canal Amazon FR -> cliquer "Renvoyer la validation" (declenche POST /api/v1/marketplaces/amazon/inbound-address/send-validation, country=FR, authentifie par session). UNE adresse, pas de batch. Puis : GO READONLY VERIFY AMAZON INBOUND VALIDATION PROD PH-SAAS-T8.12AS.20.14V-PROD-VERIFY (re-run) pour confirmer la chaine OutboundEmail SENT -> Job DONE -> SMTP mail-core relay webhook -> processValidationEmail -> cmmsdn4if PENDING -> VALIDATED. Hygiene separee : upgrade amazon-orders/items-worker hors v1.0.40. Ne pas retry outbound.

Phrase cible : GO READONLY VERIFY AMAZON INBOUND VALIDATION PROD ACTION_REQUIRED_UI PH-SAAS-T8.12AS.20.14V-PROD-VERIFY

STOP.
