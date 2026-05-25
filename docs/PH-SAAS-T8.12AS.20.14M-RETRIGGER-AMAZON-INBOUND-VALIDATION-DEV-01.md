# PH-SAAS-T8.12AS.20.14M-RETRIGGER-AMAZON-INBOUND-VALIDATION-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14G-TER / PH-20.14I / PH-20.14L
> Phase : PH-SAAS-T8.12AS.20.14M (validation fonctionnelle controlee DEV)
> Environnement : DEV uniquement

## 1. Verdict

GO RETRIGGER AMAZON INBOUND VALIDATION DEV PARTIAL PH-SAAS-T8.12AS.20.14M

Le pipeline mecanique fonctionne de bout en bout (send-validation 200, OutboundEmail cree+SENT, job OUTBOUND_EMAIL_SEND consomme, SMTP self-test, mail-core relay=webhook status=sent, webhook recu). MAIS l adresse PENDING ciblee cmk5caxx7 n est PAS passee VALIDATED. Le webhook a renvoye "[Validation] Unresolved recipient (Address not found)". NOUVELLE cause racine : incoherence de casse du champ marketplace en DB pour ce tenant -- cmk5caxx7 a marketplace="amazon" (minuscule) alors que cmj9z9r1k a "AMAZON" (majuscule). decideValidationAddress (PH-20.14I) pre-filtre les candidates via findMany({ marketplace: parsed.marketplace.toUpperCase()="AMAZON" }), ce qui EXCLUT cmk5caxx7, puis le match emailAddress exact echoue -> "Address not found".

Point positif : le fix PH-20.14I empeche desormais la validation de la MAUVAISE adresse (contrairement a PH-20.14G-TER). Point negatif : il ne trouve pas la bonne a cause de la casse legacy. Aucun flip DB. cmk5caxx7 reste PENDING. validationStatus global inchange (39 PENDING / 4 VALIDATED).

NE PAS promouvoir en PROD : la condition "cmk5caxx7 reellement VALIDATED" n est pas remplie. Correctif = sous-phase source DEV : decideValidationAddress doit resoudre par emailAddress exact SANS pre-filtre marketplace dependant de la casse (et/ou normaliser la donnee + revoir updateMarketplaceStatusIfAmazon).

## 2. Sources relues

PH-20.14L (deploy v1.0.51), PH-20.14I (source patch resolution), PH-20.14G-TER (root cause initial). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, OPERATIONAL_SOURCE_OF_TRUTH.

## 3. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| infra HEAD | e1830f7 main | OK |
| API DEV image | v1.0.51, Running, restarts=0 | OK |
| jobs-worker DEV image | v1.0.51, Running, restarts=0, scope OUTBOUND_EMAIL_SEND | OK |
| KEYBUZZ_DEV_MODE | true | OK |

## 4. Snapshot before

| Source | Before | Verdict |
|---|---|---|
| cmk5caxx7 (cible) | validationStatus PENDING, pipelineStatus PENDING, lastInboundAt null | OK (PENDING) |
| cmj9z9r1k (autre FR) | VALIDATED, updatedAt 2026-05-25T21:32 | OK |
| Amazon inbound counts | PENDING 39 / VALIDATED 4 | OK |
| OutboundEmail | SENT 11 / FAILED 14 | OK |
| Job OUTBOUND_EMAIL_SEND | DONE 10 / FAILED 16 ; PENDING/RUNNING 0 | OK |

## 5. Auth / flow DEV

| Element | Valeur | Verdict |
|---|---|---|
| Endpoint | POST /api/v1/marketplaces/amazon/inbound-address/send-validation | OK |
| Methode | curl interne pod -> keybuzz-backend:4000 (node http) | OK |
| Auth | devAuthenticateOrJwt DEV-mode : X-User-Email dev@keybuzz.io + KEYBUZZ_DEV_MODE=true | legitime |
| Payload | {"country":"FR"} | OK (la route envoie vers l adresse FR token 812g37 = cmk5caxx7) |

Aucun JWT forge, aucun secret, aucun SQL, aucun fake.

## 6. Trigger

| Ref | Trigger time UTC | HTTP status | Response | Verdict |
|---|---|---|---|---|
| cmk5caxx7 (FR) | 2026-05-25T22:33:58Z | 200 | {"ok":true,"message":"Validation email sent"} | OK (pas de 500 toAddress) |

Une seule requete.

## 7. OutboundEmail / Job

| Objet | Avant | Apres | Delta | Verdict |
|---|---|---|---|---|
| OutboundEmail SENT | 11 | 12 | +1 | OK (cree + envoye) |
| Job OUTBOUND_EMAIL_SEND DONE | 10 | 11 | +1 | OK |
| sendOutboundEmailById (worker, nouveau pod) | n/a | "[OutboundEmail] cmpls9oxq sent (provider=smtp)" | present | OK |
| AMAZON_POLL claim par worker-1 (exact) | 0 | 0 | 0 | OK |

Logs worker (nouveau pod v1.0.51) : Claimed cmpls9p6g (OUTBOUND_EMAIL_SEND) by worker-1 -> Processing tenant tenant_test_dev -> sent provider=smtp -> done SENT. Aucun AMAZON_POLL.

## 8. SMTP / webhook

| Signal | Observe | Verdict |
|---|---|---|
| API log | [Validation] Queued email to amazon.tenant_test_dev.fr.812g37@inbound.keybuzz.io (job cmpls9p6g) | OK |
| mail-core | E0BAC3E615 to amazon.tenant_test_dev.fr.812g37@inbound.keybuzz.io relay=webhook status=sent | OK |
| Backend webhook | [Webhook] Received inbound email to: 812g37 | OK |
| processValidationEmail | [Validation] Unresolved recipient (Address not found) | NON RESOLU (cause sec. 11) |
| mail-core storm 421/454 | 0 nouveau | STABLE |

## 9. DB validation

| Ref | Status before | Status after | lastInboundAt before | lastInboundAt after | Verdict |
|---|---|---|---|---|---|
| cmk5caxx7 (cible) | PENDING | PENDING (inchange, updatedAt Jan-08) | null | null | NON VALIDE |
| cmj9z9r1k (autre FR) | VALIDATED (updatedAt 21:32) | VALIDATED, updatedAt 22:34 (touche par updateMarketplaceStatusIfAmazon) | - | - | deja VALIDATED, pas de transition |
| Amazon validationStatus counts | PENDING 39 / VALIDATED 4 | PENDING 39 / VALIDATED 4 | - | - | INCHANGE |

cmk5caxx7 PAS VALIDATED. Aucun flip DB manuel. cmj9z9r1k touche (updatedAt) par le 2e chemin webhook updateMarketplaceStatusIfAmazon (updateMany sur tenant+marketplace=AMAZON+country=FR) ; deja VALIDATED donc aucune transition incorrecte de validationStatus.

## 10. Non-regression

| Check | Before | After | Verdict |
|---|---|---|---|
| jobs-worker healthy | Running r=0 | Running r=0 | OK |
| AMAZON_POLL claim par worker-1 | 0 | 0 | OK |
| mail-core | stable | stable (1 self-test, 0 storm) | OK |
| outbound_deliveries retry | 0 | 0 | OK |
| PROD | non touche | non touche | OK |

## 11. Anti-regression / cause racine

| Feature | Contrat | Etat | Verdict |
|---|---|---|---|
| Amazon outbound From | tenant inbound address | inchange | OK |
| Guard validationStatus=VALIDATED | non bypasse ; pas de validation incorrecte | renforce vs 14G-TER | OK |
| Inbound webhook reel | utilise (relay=webhook reel) | OK | OK |
| Resolution exacte par emailAddress | active mais defaite par casse marketplace | a corriger | GAP |
| PH-20.11C / PH-20.12B / PH-20.13B | preserve / suspendu | non touche | OK |

Cause racine PH-20.14M : decideValidationAddress (inbound.service.ts) fait findMany({ tenantId, marketplace: parsed.marketplace.toUpperCase()="AMAZON", country }) comme ensemble de candidates. cmk5caxx7 a marketplace stocke en minuscule "amazon" -> exclu des candidates -> aucun match emailAddress exact -> "Address not found". cmj9z9r1k (marketplace "AMAZON") est dans les candidates mais son emailAddress (token different) ne matche pas 812g37 -> correctement rejete. La donnee marketplace est incoherente entre les 2 lignes du meme tenant.

## 12. No fake metrics / events

| Objet | Change | Verdict |
|---|---|---|
| validation / webhook / OutboundEmail / delivery / KBActions | reels, aucun fake, aucun flip DB | OK |

OutboundEmail + webhook reels. Aucun forcage de validationStatus. cmk5caxx7 reflete l etat reel (NON valide).

## 13. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| PROD | OUI | DEV namespace + DB DEV uniquement |
| retry outbound / message marketplace | OUI | 0 |
| fake webhook | OUI | webhook reel via mail-core |
| DB UPDATE manuel | OUI | aucun flip ; lectures read-only |
| build / push / deploy / GitOps | OUI | 0 |
| mail-core / MX / DNS | OUI | non touche |
| JWT forge / secret / bypass | OUI | DEV-mode legitime |

## 14. Gaps

1. **Casse marketplace incoherente (DATA)** : cmk5caxx7 marketplace="amazon" (minuscule) vs cmj9z9r1k "AMAZON". Le pipeline genere les emails et tokens correctement, mais decideValidationAddress filtre les candidates par marketplace.toUpperCase() et rate la ligne minuscule.
2. **decideValidationAddress (CODE)** : devrait resoudre l adresse par emailAddress exact SANS dependre de la casse marketplace (ex : findMany({ emailAddress: { equals: to, mode: insensitive } }) directement, sans pre-filtre marketplace), puis verifier coherence. Sous-phase source PH-20.14I-bis / 14O.
3. **updateMarketplaceStatusIfAmazon (CODE, secondaire)** : utilise aussi marketplace.toUpperCase() en updateMany ; a touche cmj9z9r1k (deja VALIDATED). A auditer pour la meme robustesse de casse + verifier pourquoi isAmazonForwardedEmail a matche un self-test.
4. Option complementaire : normaliser la donnee marketplace (DB) en majuscule de facon coherente (sous-phase data dediee, hors scope ici).

## 15. Prochaine phrase GO

NE PAS proposer GO PROMOTE AMAZON VALIDATION PIPELINE PROD PH-20.14N tant que cmk5caxx7 n est pas reellement VALIDATED via le flow.

Phrase recommandee : GO SOURCE PATCH VALIDATION ADDRESS RESOLUTION BIS DEV PH-SAAS-T8.12AS.20.14O -- decideValidationAddress resout par emailAddress exact insensitive sans pre-filtre marketplace casse-dependant (tests multi-casse), puis rebuild v1.0.52 -> push -> redeploy -> re-trigger PH-20.14M-bis. Auditer aussi updateMarketplaceStatusIfAmazon (casse + self-test) en parallele.

STOP.
