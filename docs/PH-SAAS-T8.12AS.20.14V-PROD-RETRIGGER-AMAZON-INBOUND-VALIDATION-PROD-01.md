# PH-SAAS-T8.12AS.20.14V-PROD-RETRIGGER-AMAZON-INBOUND-VALIDATION-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14U-PROD-APPLY / PH-20.14T / PH-20.14S-BIS
> Phase : PH-SAAS-T8.12AS.20.14V-PROD (RETRIGGER VALIDATION PROD, cible unique, gate auth)
> Environnement : PROD

## 1. Verdict

GO RETRIGGER AMAZON INBOUND VALIDATION PROD BLOCKED PH-SAAS-T8.12AS.20.14V-PROD

Pipeline PROD verifie SAIN et PRET (API + jobs-worker v1.0.53-prod digest 18f54575, scope OUTBOUND_EMAIL_SEND, SMTP mail-core-01, routage webhook mail-core -> backend PROD confirme). MAIS le trigger n a PAS ete execute : gate auth NON franchi. En PROD KEYBUZZ_DEV_MODE=false -> le header X-User-Email DEV-mode est inactif ET interdit ; la route send-validation exige un authenticate reel (Bearer JWT / session seller). Le CE ne dispose d aucun moyen d auth PROD legitime (pas de session utilisateur, pas de token super_admin scoped fourni, pas d action UI), et forger un JWT / header dev-mode / appel direct au service interne sont interdits. Verdict BLOCKED/HANDOFF : aucun trigger, aucun email, aucune DB mutation, aucun retry. Handoff UI fourni a Ludovic ci-dessous.

Prochaine phrase GO : GO READONLY VERIFY AMAZON INBOUND VALIDATION PROD PH-SAAS-T8.12AS.20.14V-PROD-VERIFY (apres clic UI Ludovic sur UNE adresse) -> verifier PENDING -> VALIDATED sous observabilite.

## 2. Sources relues

PH-20.14U-PROD-APPLY (pipeline PROD deploye), PH-20.14T (decision PROD), PH-20.14S-BIS (DEV prouve), PH-20.14U-PROD-PUSH (image PROD). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight PROD (E0)

| Service | image | digest | ready | restarts | env non-secret | verdict |
|---|---|---|---|---|---|---|
| API keybuzz-backend | v1.0.53-prod | sha256:18f54575...886368 | true | 0 | KEYBUZZ_DEV_MODE=false | OK |
| jobs-worker | v1.0.53-prod | sha256:18f54575...886368 | true | 0 | JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP_HOST=49.13.35.167, SMTP_PORT=25, SMTP_SECURE=false | OK |

startup jobs-worker : "Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw=\"OUTBOUND_EMAIL_SEND\" pollMs=2000".

## 4. Mail-core -> webhook PROD (E1)

| Signal | resultat | verdict |
|---|---|---|
| relay_domains mail-core-01 | inbound.keybuzz.io | OK |
| transport_maps | inbound.keybuzz.io -> webhook: (pipe) | OK |
| webhook pipe | /usr/local/bin/postfix_webhook.sh ${recipient} | OK |
| WEBHOOK_URL_PROD | https://backend.keybuzz.io/api/v1/webhooks/inbound-email | OK (route vers backend PROD) |
| dual-post DEV+PROD | messageId suffixe -dev/-prod (anti-dedup) | OK (PROD recoit son webhook) |
| API PROD inbound-webhook-key | present (cle INBOUND_WEBHOOK_KEY, valeur non affichee) | OK |
| storm 454/421 | absent (verifie en PH-20.14S-BIS, mail-core stable) | OK |

Routage CONFIRME : une validation d adresse PROD @inbound.keybuzz.io sera postee au backend PROD qui validera l adresse dans son keybuzz_backend.

## 5. DB BEFORE (E2)

| Address id | tenant masque | country | token | status | priority |
|---|---|---|---|---|---|
| cmo6ay5wy00054z01fa27g0dv | ludo-gon*** | FR | ui*** | PENDING | RECOMMANDE (tenant owner, blast radius minimal) |
| cmmsdn4if0003at01cwu3p6if | ecomlg-0*** (001) | FR | 4x*** | PENDING | alt (plus ancienne) |
| cmnvwpyk500036i01rm59ill8 | ecomlg-0*** (001) | BE | ub*** | PENDING | - |
| cmnvwpykn00056i01c3biprug | ecomlg-0*** (001) | ES | zu*** | PENDING | - |
| cmnvwpyl000076i01ceti7ggf | ecomlg-0*** (001) | IT | hz*** | PENDING | - |
| cmnvwsiz2000b6i01k1cwyqqe | ecomlg-0*** (001) | PL | 36*** | PENDING | - |
| cmnvwva6l000f6i0144v9fgy2 | compta-e*** | FR | 3e*** | PENDING | - |
| cmo7g2sdw000a4z01acgv6sr1 | ecomlg-m*** (mo4h93e7) | FR | ie*** | PENDING | - |
| cmot0g28900037o3ez1ftlg7a | bon-kb-m*** | FR | fq*** | PENDING | - |
| cmotxn8bs00067r01ioikv1wj | ecomlg-m*** (motxke32) | FR | as*** | PENDING | - |
| cmou8lsnw000c7r01j4ntnps8 | bon-kb-m*** | ES | 11*** | PENDING | - |

Compteurs : Job OUTBOUND_EMAIL_SEND vide, OutboundEmail vide, MarketplaceOutboundMessage vide. Aucun outbound bloque enregistre -> pas de tenant prioritaire par delivery echouee. Toutes lastInboundAt=null.

## 6. Gate auth (E3) = BLOCKED

| Moyen auth | disponible ? | verdict |
|---|---|---|
| Session seller reelle fournie par Ludovic | non | indisponible |
| Token super_admin scoped fourni (canal securise) | non | indisponible |
| Action UI faite par Ludovic | non (pas encore) | indisponible |
| Header X-User-Email DEV-mode | INTERDIT + inactif (KEYBUZZ_DEV_MODE=false) | exclu |
| JWT forge / secret signing / appel direct service | INTERDIT | exclu |

Aucun moyen d auth PROD legitime -> STOP, pas de trigger.

## 7. Trigger (E4) / Job/OutboundEmail (E5) / SMTP-webhook (E6) / DB AFTER (E7)

NON EXECUTES (gate auth non franchi). Aucun OutboundEmail cree, aucun Job, aucun SMTP, aucun webhook, aucune transition DB. 11 adresses restent PENDING.

## 8. No unintended processing (E8)

| Signal | etat | verdict |
|---|---|---|
| Job OUTBOUND_EMAIL_SEND | vide (inchange) | OK |
| OutboundEmail | vide (inchange) | OK |
| MarketplaceOutboundMessage | vide (inchange) | OK |
| trigger / email / retry / fake | 0 | OK |
| API + jobs-worker restarts | 0 | OK |

## 9. Handoff UI pour Ludovic (action requise)

Pour valider UNE adresse PROD via le flow authentifie reel :
1. Se connecter au Client PROD (https://client.keybuzz.io) avec le compte du tenant cible.
2. Tenant RECOMMANDE pour le premier test : ludo-gonthier-ga4mpf-mo5ldw59, marketplace Amazon, country FR (adresse id cmo6ay5wy00054z01fa27g0dv) -- blast radius minimal (compte owner).
3. Ecran : connexion canal Amazon / adresse de validation inbound.
4. Cliquer le bouton "Renvoyer la validation" (declenche POST /api/v1/marketplaces/amazon/inbound-address/send-validation, country=FR, authentifie par la session).
5. UNE seule adresse, pas de batch.

Alternative : fournir au CE un token super_admin scoped (canal securise hors chat) pour declencher 1 adresse.

Apres le clic : lancer GO READONLY VERIFY ... PH-20.14V-PROD-VERIFY pour confirmer le flux (OutboundEmail SENT -> Job DONE -> SMTP mail-core relay webhook -> processValidationEmail -> adresse PENDING -> VALIDATED) sous observabilite, read-only.

## 10. Decision (E9)

BLOCKED/HANDOFF. Pipeline PROD pret et routage confirme ; seul l auth manque. Aucune mutation. Attendre le clic UI Ludovic (ou token scoped) puis VERIFY.

## 11. Prochaine phase

GO READONLY VERIFY AMAZON INBOUND VALIDATION PROD PH-SAAS-T8.12AS.20.14V-PROD-VERIFY (read-only, apres action UI Ludovic sur 1 adresse) : verifier la chaine complete + PENDING -> VALIDATED sur l adresse cible, no unintended processing. Ne pas retry outbound. Hygiene separee : upgrade amazon-orders/items-worker hors v1.0.40.

Phrase cible : GO RETRIGGER AMAZON INBOUND VALIDATION PROD BLOCKED PH-SAAS-T8.12AS.20.14V-PROD

STOP.
