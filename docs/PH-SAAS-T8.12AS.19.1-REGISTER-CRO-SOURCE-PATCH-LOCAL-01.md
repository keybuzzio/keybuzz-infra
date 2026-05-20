# PH-SAAS-T8.12AS.19.1-REGISTER-CRO-SOURCE-PATCH-LOCAL-01

> Date : 2026-05-20
> Linear : KEY-329 (primary), KEY-324, KEY-325, KEY-330, KEY-331, KEY-332
> Phase : PH-SAAS-T8.12AS.19.1
> Environnement : SOURCE ONLY / DEV-first / aucun build / aucun deploy

## VERDICT

GO SOURCE PATCH LOCAL READY PH-SAAS-T8.12AS.19.1

- 2 commits locaux : keybuzz-api 39e332ea + keybuzz-client 1b29903.
- NOT PUSHED. NO BUILD. NO DEPLOY.
- Runtime DEV/PROD inchanges (Client v3.5.198-debug-env-disabled-*, API v3.5.198-* baseline preserve).
- Prochaine phrase GO attendue : GO PUSH REGISTER CRO SOURCE PH-SAAS-T8.12AS.19.1.

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-client branch | ph148/onboarding-activation-replay | OK |
| keybuzz-client HEAD pre-patch | f61763a (fix(security): disable debug env endpoint) | OK |
| keybuzz-api branch | ph147.4/source-of-truth | OK |
| keybuzz-api HEAD pre-patch | 01b163e4 (feat(ad-accounts): add internal /sync-all endpoint) | OK (dist/*.js deletes preexistants hors scope) |
| keybuzz-website branch | main | OK |
| keybuzz-website HEAD | 3baecc2 (fix(website): renomme le flag GA4 _gl_present) | OK (read-only this phase) |
| keybuzz-infra branch | main | OK |
| keybuzz-infra HEAD | a06adff (ops(website-prod): bump image v0.6.18-ga4-cleanup-prod) | OK (read-only this phase) |

## SOURCES RELUES

- C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CURRENT_STATE.md
- C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\RULES_AND_RISKS.md
- C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\DOCUMENT_MAP.md
- C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CE_PROMPTING_STANDARD.md
- Rapports PH recents (PH-WEBSITE-T8.12AS.18.x) verifies cote runtime preserve.

## CONTEXTE RUNTIME (read-only)

| Surface | Image runtime PROD | Image runtime DEV | Changement cette phase |
|---|---|---|---|
| keybuzz-website | v0.6.18-ga4-cleanup-prod | v0.6.18-ga4-cleanup-dev | aucun |
| keybuzz-client | v3.5.198-debug-env-disabled-prod | v3.5.198-debug-env-disabled-dev | aucun (patch SOURCE only) |
| keybuzz-api | v3.5.198-* (baseline) | v3.5.198-* (baseline) | aucun (patch SOURCE only) |

## FICHIERS MODIFIES

| Repo | Fichier | Insertions | Deletions | Statut |
|---|---|---|---|---|
| keybuzz-api | src/modules/auth/tenant-context-routes.ts | 13 | 3 | committed local 39e332ea |
| keybuzz-client | app/register/page.tsx | 100 | 36 | committed local 1b29903 |

## DECISIONS PRODUIT

1. KEY-331 plan_selected interne : emis dans handleSelectPlan(plan) au vrai clic plan, retire du bouton "Utiliser un autre email" (step code).
2. KEY-332 tenant_created API : deplace du catch (attrErr) vers le chemin succes apres COMMIT, non-bloquant.
3. KEY-329 PlanRecapCard CRO : composant local React unique, affiche dans email, company, user, payment_cancelled. Pas de logos, pas de reviews, pas de chiffres inventes.
4. KEY-325 Clarity client : data-clarity-mask=true ajoute sur 13 inputs PII. Clarity client.keybuzz.io NON activee. Aucun script clarity.ms, aucun NEXT_PUBLIC_CLARITY_PROJECT_ID, aucune modification SaaSAnalytics.
5. KEY-330 events ads browser-side : trackSignupStart emet toujours Meta Lead + TikTok SubmitForm cote browser. Documentation + decision Ludovic requise avant retrait. Aucun patch dans cette phase.
6. Coupons et Stripe : non touches. promo preview, promo forwarding et Stripe checkout-session inchanges.
7. Attribution : completement preservee (UTM, gclid, fbclid, ttclid, li_fat_id, _gl, marketing_owner_tenant_id, promo).

## DETAILS PATCH API (KEY-332)

Fichier : keybuzz-api/src/modules/auth/tenant-context-routes.ts.

Avant patch (zone l.752-757) :
- emitFunnelEvent('tenant_created', ...) etait place a l interieur du catch (attrErr: any) de la persistance signup_attribution.
- Consequence : l event n etait emis QUE si l INSERT signup_attribution echouait. Sur chemin succes attendu, aucun tenant_created emis.

Apres patch (zone catch nettoyee + bloc apres COMMIT) :
- Le catch contient uniquement le ROLLBACK TO SAVEPOINT et le console.warn.
- L emission tenant_created est deplacee apres await client.query('COMMIT').
- L emission reste non-bloquante (emitFunnelEvent gere try/catch silencieux en interne).
- tenantId, attributionId, plan et cycle preserves dans le payload.
- Si attribution.id absent du body : pas d emission (pas d invention de funnel_id).
- Si l INSERT signup_attribution echoue : la creation business CONTINUE et tenant_created est quand meme emis apres COMMIT, conformement a la regle no rollback business sur event funnel.

Test source : npx tsc --noEmit exit 0, aucune erreur reportee.
Verification : sed -n "752,756p" tenant_created count = 0 ; sed -n "763,775p" tenant_created count = 1.

## DETAILS PATCH CLIENT (KEY-329, KEY-324, KEY-325, KEY-331)

Fichier : keybuzz-client/app/register/page.tsx.

### Patch 1 - plan_selected (KEY-331)

Avant : plan_selected etait emis dans le bouton "Utiliser un autre email" du step code. handleSelectPlan(plan) ne l emettait pas du tout. Le funnel interne mesurait donc la conversion du retour utilisateur au step email, pas le vrai choix de plan.

Apres :
- handleSelectPlan(plan) appelle getFunnelId() puis emitFunnelStep('plan_selected', { funnelId, plan, cycle: billingCycle }) au tout debut, avant trackSignupStart, avant setStep.
- Le bouton "Utiliser un autre email" devient un handler simple setStep('email') + reset code + reset devCode, sans emitFunnelStep.
- emitFunnelStep dedupe in-memory inchangee (1 funnelId + 1 event_name = 1 emission par session).

Verification grep : 1 occurrence emitFunnelStep('plan_selected') dans le fichier (la nouvelle, au bon endroit). 0 occurrence dans le bouton "Utiliser un autre email".

### Patch 2 - PlanRecapCard CRO (KEY-329, KEY-324)

Composant React local defini dans RegisterContent, juste avant handleSelectPlan. Acces aux state vars existantes (selectedPlan, billingCycle, isAnnual, promoPreview, step) et aux helpers (PLANS, PRICING_CONFIG, getAnnualPrice, formatEur, ANNUAL_DISCOUNT).

Contenu rendu :
- Bloc "Votre selection" : KeyBuzz <plan name> - <Mensuel ou Annuel (-20%)>.
- Prix :
  - si promoPreview valide : prix de base barre + montant apres discount (formatEur) + duree si fournie ;
  - si annuel sans promo : prix mensuel base barre + prix annualise EUR/mois ;
  - si mensuel sans promo : prix base EUR/mois.
- "Essai gratuit 14 jours - sans engagement - resiliable a tout moment."
- 3 a 4 benefices tires de PRICING_CONFIG.plans.find().features.slice(0, 4). Aucun benefice invente.
- "Prochaine etape :" texte dynamique selon le step en cours :
  - email : Verifier votre email avec un code a 6 chiffres.
  - company : Renseigner les informations de votre societe.
  - user : Confirmer vos informations puis activer l essai 14 jours.
  - payment_cancelled : Reprendre le paiement pour activer votre essai 14 jours.
- 3 lignes reassurance :
  - Connexion Amazon via OAuth officiel SP-API.
  - Compte vendeur non modifie sans action explicite.
  - Donnees limitees au strict necessaire.

Integration :
- step email : PromoPreviewBanner -> PlanRecapCard -> form principal (1 insertion).
- step company : PromoPreviewBanner -> PlanRecapCard -> card principal (1 insertion).
- step user : PromoPreviewBanner -> PlanRecapCard -> card principal (1 insertion + suppression de l ancien recap inline PH33.11).
- step payment_cancelled : PromoPreviewBanner -> PlanRecapCard -> card principal (1 insertion).

Verification grep : <PlanRecapCard /> count = 4. const PlanRecapCard = ()> defini. 0 occurrence du commentaire "PH33.11: Recap plan" supprime.

Hors scope respect :
- step plan (selection initiale) : non modifie (le recap apparait apres clic).
- step code (verification OTP) : non modifie (focus sur saisie code).

### Patch 3 - data-clarity-mask sur 13 inputs PII (KEY-325)

Attribut HTML data-clarity-mask="true" ajoute sur :
- email (step email saisie),
- code (OTP),
- companyName, siret, street, zipCode, city, companyPhone, supportEmail,
- firstName, lastName, phone,
- email readonly (step user recap).

Si Microsoft Clarity etait active un jour sur client.keybuzz.io, ces champs seraient automatiquement masques dans les recordings et heatmaps. Tant que Clarity n est pas branchee, attribut DOM no-op sans effet runtime.

Verification grep :
- data-clarity-mask count = 13.
- NEXT_PUBLIC_CLARITY count = 0 (page register + SaaSAnalytics).
- clarity.ms count = 0 (page register + SaaSAnalytics).
- Inventory NEXT_PUBLIC_* du repo Client : NEXT_PUBLIC_CLARITY_PROJECT_ID ABSENT.

Hors scope respect :
- SaaSAnalytics : aucun changement, GA4/Meta/TikTok/LinkedIn inchanges.
- Pas d injection Clarity script.

### Hors scope (audite, non modifie)

- trackSignupStart : emet GA4 signup_start + Meta Lead + TikTok SubmitForm browser-side. Doublon potentiel avec event server-side CAPI futur. Decision produit attendue (KEY-330 + KEY-331).
- trackSignupComplete : Meta CompleteRegistration browser-side. Idem decision produit.
- trackBeginCheckout : Meta InitiateCheckout + TikTok InitiateCheckout browser-side. Idem.
- trackPurchase : Meta Purchase et TikTok CompletePayment deja retires browser-side (server-side only via CAPI/Events API).

## COUPON PRESERVATION

Coupon flow preserve a l identique :
- URL /register?promo=XYZ capture par urlPromo (useSearchParams).
- attribution.promo persiste dans sessionStorage/localStorage via initAttribution (src/lib/attribution.ts ; aucun changement de cette logique).
- BFF /api/billing/promo-preview proxy GET vers API /billing/promo-preview ; affichage par PromoPreviewBanner (inchange).
- handleUserSubmit construit resolvedPromo = urlPromo || checkoutAttribution?.promo et le passe a /api/billing/checkout-session avec attribution complete.
- handleRetryCheckout reconstruit retryPromo identiquement et le passe a la session Stripe.
- API /billing/checkout-session : verification Stripe promo + stop si invalide preserve.

PlanRecapCard utilise les champs promoPreview.valid, promoPreview.amountDueAfterDiscount et promoPreview.durationMonths uniquement en LECTURE, sans modifier la logique de preview existante.

## ATTRIBUTION PRESERVATION

| Cle attribution | Source | Preserve |
|---|---|---|
| utm_source, utm_medium, utm_campaign, utm_term, utm_content | URL pricing -> attribution.ts | OK |
| gclid, fbclid, ttclid, li_fat_id | URL pricing -> attribution.ts | OK |
| _gl (cross-domain GA4 linker) | URL pricing -> attribution.ts (key _gl) -> ATTRIBUTION_FLAG_NAMES website renomme uniquement flag GA4 ; URL key intacte | OK |
| marketing_owner_tenant_id | URL pricing -> attribution.ts | OK |
| promo | URL pricing -> attribution.ts -> handleUserSubmit -> Stripe | OK |
| plan, cycle | URL pricing -> register state -> embedInSignupContext (OAuth) | OK |

Aucune cle d attribution supprimee. Aucune modification du contrat de stockage sessionStorage/localStorage.

## CLARITY PREPARATION SANS ACTIVATION

- 13 attributs data-clarity-mask="true" ajoutes sur les inputs PII du formulaire register.
- AUCUN script clarity.ms injecte.
- AUCUN NEXT_PUBLIC_CLARITY_PROJECT_ID ajoute aux env vars ou au .env.
- AUCUNE modification de src/components/tracking/SaaSAnalytics.tsx.
- Hors scope explicite : pages /inbox, /dashboard, /orders, /settings et autres pages protegees (BLOCKED_PREFIXES de SaaSAnalytics) - Clarity n y serait pas charge meme apres activation eventuelle.
- Decision activation Clarity sur client.keybuzz.io : portee par KEY-325, prochaine phase apres refonte register validee.

## NO FAKE METRICS / NO FAKE EVENTS

| Indicateur | Resultat |
|---|---|
| Nouvel event Meta fbq('track', 'Lead'|'InitiateCheckout'|'Purchase'|'StartTrial'|'CompletePayment') ajoute par le patch | 0 |
| Nouvel event TikTok ttq.track('SubmitForm'|'InitiateCheckout'|'Purchase'|'CompletePayment') ajoute par le patch | 0 |
| Nouveau tag Google Ads AW-XXXXXXXXXX direct | 0 |
| Nouveau KPI fake | 0 |
| Conversion Stripe redirection en Purchase | non |
| Conversion clic plan en Lead ads | non (ajout reste sur funnel interne plan_selected + ce qui existait deja via trackSignupStart) |
| Conversion micro-etape register en event ads | non |

## TESTS

| Test | Repo | Attendu | Resultat |
|---|---|---|---|
| npx next lint --file app/register/page.tsx | Client | 0 warning 0 error | OK : "No ESLint warnings or errors" |
| npx tsc --noEmit projet | Client | 0 erreur sur fichiers patches | OK : app/register/page.tsx 0 erreur ; src/lib/{attribution,funnel,tracking}.ts 0 erreur ; 2 erreurs preexistantes dans .next/types/app/api/debug-env/ liees a la suppression de l endpoint debug-env (cache obsolete) NON IMPUTABLES au patch |
| npx tsc --noEmit projet | API | 0 erreur | OK : exit 0 |
| grep emit plan_selected dans handleSelectPlan | Client | 1 occurrence | OK : 1 |
| grep plan_selected dans bouton "Utiliser un autre email" | Client | 0 | OK : 0 |
| grep data-clarity-mask | Client | 13 | OK : 13 |
| grep NEXT_PUBLIC_CLARITY | Client | 0 | OK : 0 |
| grep clarity.ms | Client | 0 | OK : 0 |
| grep emit tenant_created dans catch (l.752-756) | API | 0 | OK : 0 |
| grep emit tenant_created apres COMMIT (l.763-775) | API | 1 | OK : 1 |
| grep promo: resolvedPromo (handleUserSubmit) | Client | 1 | OK : 1 |
| grep marketing_owner_tenant_id (attribution + register) | Client | 4 | OK : 3 + 1 |
| grep _gl (attribution.ts) | Client | 4 | OK : 4 |
| grep PlanRecapCard | Client | 5 (1 def + 4 usages) | OK : 5 |

## COMMITS LOCAUX

| Repo | Commit local | HEAD origin | Ahead | Dirty |
|---|---|---|---|---|
| keybuzz-api | 39e332ea fix(funnel): emet tenant_created sur le chemin succes | 01b163e4 ph147.4/source-of-truth | 1 | dist/*.js deletes preexistants hors scope (build artefacts trackes mais regenerables, AUCUN fichier src/ touche dirty) |
| keybuzz-client | 1b29903 feat(register): renforce le recap CRO et le tracking funnel | f61763a ph148/onboarding-activation-replay | 1 | tsconfig.tsbuildinfo modifie par tsc --noEmit cache (artefact local non scope, jamais commit) |

NOT PUSHED. NO BUILD. NO DEPLOY.

## LINEAR UPDATES (brouillon, NON poste, attente GO Ludovic)

### KEY-329 (primary - Register CRO recap)

Patch local PH-SAAS-T8.12AS.19.1 pret. Composant PlanRecapCard ajoute dans les steps email, company, user et payment_cancelled. Recap plan + cycle + prix (avec ou sans promo preview), 3-4 benefices tires de PRICING_CONFIG, prochaine etape, 3 lignes reassurance Amazon/RGPD. Pas de logo, pas de review, pas de chiffre invente. Ancien micro-recap inline supprime du step user. Commit keybuzz-client 1b29903 (NOT pushed). Aucun build, aucun deploy.

### KEY-324 (CRO acquisition website / register / lead capture)

Cote register : PlanRecapCard livre la promesse CRO sans casser le flow plan/email/code/company/user/checkout. Attribution complete preservee (UTM/click IDs/_gl/marketing_owner_tenant_id/promo). Flow Stripe checkout-session inchange. Pas de nouvelle activation ads (decision KEY-330 + KEY-331 + KEY-325 a confirmer avant). Commit keybuzz-client 1b29903.

### KEY-325 (Clarity client.keybuzz.io apres refonte register)

Preparation Clarity (no-op runtime): data-clarity-mask=true ajoute sur 13 inputs PII du register (email, code, companyName, siret, street, zipCode, city, companyPhone, supportEmail, firstName, lastName, phone, email readonly). Clarity NON activee : aucun script clarity.ms, aucun NEXT_PUBLIC_CLARITY_PROJECT_ID, aucune modification SaaSAnalytics. Quand Ludovic decidera d activer Clarity sur client.keybuzz.io, les champs PII seront automatiquement masques dans les recordings. Commit keybuzz-client 1b29903.

### KEY-330 (GA4 taxonomy reporting) + KEY-331 (Register funnel tracking)

KEY-331 plan_selected interne corrige : emis dans handleSelectPlan au vrai clic plan, supprime du bouton "Utiliser un autre email" (step code). Dedupe inchangee. KEY-330 events ads browser-side documentes mais non modifies sans decision Ludovic :
- trackSignupStart emet GA4 signup_start + Meta Lead + TikTok SubmitForm.
- trackSignupComplete emet Meta CompleteRegistration.
- trackBeginCheckout emet Meta InitiateCheckout + TikTok InitiateCheckout.
- Tous browser-side ; dedupe avec server-side conversions est a clarifier.
Decision recommandee : passer ces evenements en server-side only via Meta CAPI + TikTok Events API (alignement avec ce qui a deja ete fait pour trackPurchase), ou conserver le browser-side et accepter le double comptage. Commit keybuzz-client 1b29903 (KEY-331 corrigee, KEY-330 audit only).

### KEY-332 (API funnel tenant_created dans catch attribution)

Bug confirme et corrige. Avant : emitFunnelEvent('tenant_created') etait dans le catch (attrErr) du INSERT signup_attribution, donc emis seulement en cas d echec attribution. Apres : emission apres COMMIT sur le chemin succes business, non-bloquante. tenantId, attributionId, plan et cycle preserves. Commit keybuzz-api 39e332ea (NOT pushed). Aucun build, aucun deploy. Test source npx tsc --noEmit exit 0.

## GAPS RESTANTS

1. trackSignupStart / trackSignupComplete / trackBeginCheckout : decision produit KEY-330 a prendre avant de retirer les events Meta/TikTok browser-side ou de les rebrancher proprement server-side.
2. Activation Clarity client.keybuzz.io : KEY-325, prochaine phase apres validation refonte register.
3. CRO copy refinement : eventuelle iteration ulterieure sur la copy de PlanRecapCard (titres, longueur des benefices, ton) selon retours QA.
4. Tests visuels register navigateur (preview DEV) : a faire apres GO BUILD + DEPLOY DEV. Cette phase est SOURCE only.
5. .next/types/app/api/debug-env/ : artefacts cache obsoletes (route debug-env supprimee dans f61763a). Non bloquant. Sera nettoye au prochain next build.

## ROLLBACK

Source uniquement. Rollback par revert commit futur :

- keybuzz-api : git revert 39e332ea (apres push) ou git reset --soft HEAD~1 (avant push) suivi d un git checkout -- src/modules/auth/tenant-context-routes.ts.
- keybuzz-client : git revert 1b29903 (apres push) ou git reset --soft HEAD~1 (avant push) suivi d un git checkout -- app/register/page.tsx.

INTERDIT : git reset --hard, git clean.

Cette phase n a touche aucun runtime, aucun manifest, aucune image. Rollback non requis tant que NOT PUSHED.

## CONFIRMATION NO BUILD / NO PUSH / NO DEPLOY

- AUCUN docker build.
- AUCUN docker push.
- AUCUN kubectl apply.
- AUCUN kubectl set image / set env / patch / edit.
- AUCUN git push (keybuzz-api ahead 1, keybuzz-client ahead 1, keybuzz-website inchange, keybuzz-infra inchange).
- AUCUN commit sur keybuzz-website ou keybuzz-infra.
- AUCUN secret expose dans le rapport.
- AUCUN changement Admin / Backend / Studio / Stripe / Vault / ESO.
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/.
- AUCUNE activation Clarity client.keybuzz.io.
- AUCUN changement onboarding/register flow (steps inchanges).
- Bastion : install-v3 (46.62.171.61), aucune autre IP touchee.

## VERDICT FINAL

GO SOURCE PATCH LOCAL READY PH-SAAS-T8.12AS.19.1

- Commits locaux : keybuzz-api 39e332ea + keybuzz-client 1b29903.
- NOT PUSHED.
- NO BUILD.
- NO DEPLOY.
- Runtime DEV/PROD inchanges.
- Linear brouillons prepares (KEY-329, KEY-324, KEY-325, KEY-330, KEY-331, KEY-332) - non postes, attente GO Ludovic.

Prochaine phrase GO attendue : GO PUSH REGISTER CRO SOURCE PH-SAAS-T8.12AS.19.1

STOP.
