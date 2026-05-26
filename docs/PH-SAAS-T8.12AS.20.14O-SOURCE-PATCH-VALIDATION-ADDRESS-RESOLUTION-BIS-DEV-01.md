# PH-SAAS-T8.12AS.20.14O-SOURCE-PATCH-VALIDATION-ADDRESS-RESOLUTION-BIS-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14I / PH-20.14M
> Phase : PH-SAAS-T8.12AS.20.14O (SOURCE PATCH ONLY : resolution adresse validation, casse marketplace)
> Environnement : DEV (source patch ; aucune migration, aucun build, aucun deploy, aucune mutation DB, aucun trigger)

## 1. Verdict

GO SOURCE PATCH VALIDATION ADDRESS RESOLUTION BIS DEV READY PH-SAAS-T8.12AS.20.14O

La cause racine PH-20.14M (incoherence de casse du champ marketplace : "amazon" vs "AMAZON" pour un meme tenant) est corrigee en source. processValidationEmail resout desormais l adresse inbound par emailAddress exact (case-insensitive) SANS pre-filtre marketplace/country casse-dependant. La garde defensive ajoutee a updateMarketplaceStatusIfAmazon empeche un self-test de validation de declencher la mise a jour blanket marketplaceStatus. decideValidationAddress (PH-20.14I) reste inchangee : signature et comportement preserves (11/11). Patch scope strict (2 fichiers source + 1 test). TSC_OK. Tests : ph2014o 9/9 (nouveau, multi-casse), ph2014i 11/11, ph2014cbis 16/16, ph2014c 15/15. Commit backend LOCAL 8f7122b, NON pousse (STOP au gate push). Aucune migration, aucun ALTER, aucune mutation DB, aucun data fix (pas de normalisation de la colonne marketplace), aucun build, aucun deploy, aucun trigger.

Prochaine phrase GO : GO PUSH SOURCE PATCH VALIDATION ADDRESS RESOLUTION BIS DEV PH-SAAS-T8.12AS.20.14O (push backend 8f7122b + rapport infra + commentaires Linear), puis GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14P (tag v1.0.52-amazon-validation-pipeline-dev).

## 2. Sources relues

PH-20.14M (cause racine casse marketplace, PARTIAL), PH-20.14I (resolution par emailAddress via decideValidationAddress), PH-20.14C-TER (schema map toAddress). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| keybuzz-backend branche | main | OK |
| keybuzz-backend HEAD avant patch | cbbc99e = origin/main | OK (clean) |
| Repo backend dirty | non (hors src/modules/marketplaces/amazon/amazon.routes.ts.bak untracked anterieur) | OK |
| API DEV image | v1.0.51, Running | OK (non touche) |
| jobs-worker DEV image | v1.0.51, Running, restarts=0, pod started 2026-05-25T22:25:27Z | OK (non touche) |

## 4. Cause racine (rappel PH-20.14M) et signaux audites

Le webhook inbound appelle d abord processValidationEmail (routes L74) ; si validated=true il retourne tot (L83-89) ; sinon seulement il appelle updateMarketplaceStatusIfAmazon (L94). En PH-20.14M, processValidationEmail a renvoye "Address not found" (validated=false) car sa query candidates filtrait par marketplace = parsed.marketplace.toUpperCase() = "AMAZON" ; l adresse cible cmk5caxx7 a marketplace stocke en minuscule "amazon" -> exclue des candidates -> aucun match emailAddress -> echec. L echec a fait tomber le self-test dans updateMarketplaceStatusIfAmazon, dont l updateMany (tenant + marketplace=AMAZON + country=FR) a touche (updatedAt) l autre adresse cmj9z9r1k (deja VALIDATED, aucune transition nette).

| Signal source | Constat |
|---|---|
| processValidationEmail candidate query | findMany pre-filtre par marketplace.toUpperCase()/country casse-dependant -> exclut "amazon" minuscule |
| decideValidationAddress (PH-20.14I) | correct : filtre emailAddress exact + token, ne regarde jamais marketplace |
| webhook routes | processValidationEmail puis (si non validated) updateMarketplaceStatusIfAmazon |
| updateMarketplaceStatusIfAmazon | updateMany blanket par marketplace.toUpperCase() ; touchee par un self-test non resolu en 14M |

## 5. Patch (fichier / changement / risque)

| Fichier | Changement | Risque |
|---|---|---|
| keybuzz-backend/src/modules/inbound/inbound.service.ts (processValidationEmail) | query candidates : remplace where { tenantId, marketplace: toUpperCase(), country: toUpperCase() } par where { emailAddress: { equals: to.trim(), mode: 'insensitive' } } | Faible. emailAddress est l adresse inbound complete (marketplace.tenant.country.token) donc deja coherente ; le token reste verifie par decideValidationAddress. Plus de dependance a la casse marketplace. |
| keybuzz-backend/src/modules/inbound/inbound.service.ts (updateMarketplaceStatusIfAmazon) | ajoute param subject? ; garde : if (subject && isValidationEmail(subject).isValidation) return false | Faible. Un self-test de validation ne declenche plus la maj blanket marketplaceStatus. Les vrais forwards Amazon (sujet != "KeyBuzz Validation ...") ne sont pas affectes. |
| keybuzz-backend/src/modules/webhooks/inboundEmailWebhook.routes.ts | passe subject: payload.subject || "" a updateMarketplaceStatusIfAmazon | Nul (ajout d un champ deja disponible dans le payload). |
| keybuzz-backend/tests/ph2014o-validation-address-casing.test.ts | nouveau test multi-casse (amazon vs AMAZON) sur la resolution | N/A (test). |

git diff : 2 files source changed (17 insertions, 4 deletions) + 1 nouveau test (99 lignes). decideValidationAddress non modifiee.

## 6. Conception (ETAPE 3)

1. Query primaire dans processValidationEmail : chercher inboundAddress par emailAddress exact case-insensitive (Prisma mode: 'insensitive'), sans pre-filtre marketplace casse-dependant.
2. marketplace/country/tenant restent verifies en amont au niveau du FORMAT (parseInboundAddress + parsed.isCanonical), et la coherence finale est assuree par decideValidationAddress via le token : non bloquant sur la casse marketplace.
3. decideValidationAddress conservee telle quelle (filtre emailAddress exact lowercased + token + garde ambiguite/empty) : aucun changement de signature -> 11/11 preserves.
4. updateMarketplaceStatusIfAmazon : audit -> elle pouvait retoucher une autre adresse lors d un self-test non resolu. Correctif : ignorer explicitement les self-tests de validation (skip si isValidationEmail(subject)). Avec le fix #1, un self-test reussit et retourne tot dans le webhook, donc n atteint plus cette fonction ; la garde est une defense en profondeur pour le cas d un self-test non resolu.

## 7. Tests / typecheck

| Etape | Commande | Resultat |
|---|---|---|
| Typecheck | npx tsc --noEmit -p tsconfig.json | TSC_OK |
| Tests PH-20.14O (nouveau, multi-casse) | tests/ph2014o-validation-address-casing.test.ts | 9 passed, 0 failed |
| Tests PH-20.14I (resolution) | tests/ph2014i-validation-address.test.ts | 11 passed, 0 failed |
| Tests PH-20.14C-BIS (jobscope) | tests/ph2014cbis-jobscope.test.ts | 16 passed, 0 failed |
| Tests PH-20.14C (outboundEmail) | tests/ph2014c-outboundEmail.test.ts | 15 passed, 0 failed |

Le test ph2014o prouve : l ancien pre-filtre (marketplace == "AMAZON", egalite DB casse-sensible) exclut la cible minuscule et echoue ("Address not found") ; la nouvelle approche (candidates par emailAddress, sans pre-filtre marketplace) resout la cible minuscule cmk5caxx7, ne touche pas l autre adresse VALIDATED cmj9z9r1k, resout aussi l adresse majuscule (idempotent), gere un destinataire en casse mixte, et rejette toujours un token mismatch.

## 8. No side-effect runtime

| Check | Etat | Verdict |
|---|---|---|
| jobs-worker DEV redeploye | non (v1.0.51, restarts=0, pod started 22:25:27Z, inchange depuis 14M) | OK |
| API DEV redeployee | non (v1.0.51) | OK |
| Mutation DB | aucune (pas de migrate/db push/ALTER/INSERT/UPDATE/normalisation marketplace) | OK |
| OutboundEmail cree / email envoye | aucun | OK |
| Trigger send-validation | aucun | OK |
| Build / docker push / kubectl apply | aucun | OK |

## 9. Build / GitOps

N/A pour cette phase. SOURCE PATCH uniquement. Build = phase suivante PH-20.14P (tag v1.0.52-amazon-validation-pipeline-dev) depuis commit 8f7122b apres push.

## 10. Validation runtime

N/A. Aucun deploy. La validation reelle (cmk5caxx7 PENDING -> VALIDATED via le flow) se fera apres rebuild v1.0.52 + redeploy API DEV + jobs-worker DEV puis re-trigger (PH-20.14M-bis).

## 11. No fake metrics / events

Aucun flip DB, aucun fake OutboundEmail, aucun fake webhook, aucune metrique forgee, aucune normalisation de donnee marketplace. Le fix est prouve par tests unitaires (decideValidationAddress + simulation des ensembles de candidates ancien/nouveau), pas par ecriture DB. validationStatus reel inchange (cmk5caxx7 reste PENDING tant que non rejoue).

## 12. AI feature parity / anti-regression

Hors scope IA generative. Le patch ne touche que la resolution d adresse de validation inbound et la garde self-test. Aucun impact Inbox, messages IA, autopilot, dashboard, metriques derivees. Contrats outbound Amazon (From = adresse inbound tenant) et guard validationStatus=VALIDATED inchanges. PH-20.11C / PH-20.12B / PH-20.13B preserves / suspendus.

## 13. Non-regression PROD

| Check | Avant | Apres | Verdict |
|---|---|---|---|
| PROD touche | non | non | OK |
| origin/main backend | cbbc99e | cbbc99e (non avance) | OK |
| jobs-worker DEV | v1.0.51 Running r=0 | v1.0.51 Running r=0 | OK |
| Schema DB (DEV/PROD) | inchange | inchange (aucune migration) | OK |
| Donnee marketplace en DB | inchangee | inchangee (pas de data fix) | OK |

## 14. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| Migration SQL / prisma migrate deploy / db push / ALTER | OUI | aucune commande prisma migrate/db push |
| Mutation DB / data fix marketplace | OUI | 0 INSERT/UPDATE/DELETE ; pas de normalisation |
| Build / docker push / deploy / kubectl apply | OUI | 0 |
| Trigger validation / retry outbound | OUI | 0 |
| Mail-core / MX / DNS | OUI | non touche |
| PROD | OUI | non touche |
| git push (sans GO) | OUI | origin/main = cbbc99e |
| Hardcode tenant/user/email | OUI | aucun (ids de test dans le fichier de test uniquement, non runtime) |
| decideValidationAddress signature modifiee | NON modifiee | 11/11 preserves |

## 15. Gaps restants

1. Push backend 8f7122b : en attente de GO explicite.
2. Rebuild image backend v1.0.52-amazon-validation-pipeline-dev (PH-20.14P) puis redeploy API DEV (resolution) ET jobs-worker DEV.
3. Re-trigger PH-20.14M-bis apres redeploy pour prouver cmk5caxx7 PENDING -> VALIDATED via le flow reel.
4. Donnee marketplace incoherente en DB ("amazon" vs "AMAZON") toujours presente : le code est desormais robuste a la casse, mais une sous-phase data dediee (hors scope) pourrait normaliser pour la coherence d ensemble (impacte aussi l updateMany blanket de updateMarketplaceStatusIfAmazon sur les vrais forwards vers une adresse minuscule).
5. jobsWorker PROD toujours absent (apres validation DEV complete).
6. Fichier untracked src/modules/marketplaces/amazon/amazon.routes.ts.bak (anterieur, hors chaine) a nettoyer hors phase ; NON commite.

## 16. Rollback

Le commit 8f7122b touche 2 fichiers source (1 query + 1 garde + 1 param) et ajoute 1 test. Revert = reset local HEAD a cbbc99e avant push (non pousse). Aucun effet DB a annuler (aucune migration, aucun data fix). jobs-worker / API DEV inchanges.

Phrase cible : GO SOURCE PATCH VALIDATION ADDRESS RESOLUTION BIS DEV READY PH-SAAS-T8.12AS.20.14O

STOP.
