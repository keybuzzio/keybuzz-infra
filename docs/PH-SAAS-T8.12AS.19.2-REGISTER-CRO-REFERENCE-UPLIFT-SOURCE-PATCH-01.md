# PH-SAAS-T8.12AS.19.2-REGISTER-CRO-REFERENCE-UPLIFT-SOURCE-PATCH-01

> Date : 2026-05-20
> Linear : KEY-329 (primary), KEY-333 (benchmark), KEY-324, KEY-325, KEY-330, KEY-331
> Phase : PH-SAAS-T8.12AS.19.2-REGISTER-CRO-REFERENCE-UPLIFT-SOURCE-PATCH
> Environnement : SOURCE ONLY / DEV-first / aucun build / aucun deploy

## VERDICT

GO SOURCE PATCH REGISTER CRO REFERENCE UPLIFT READY PH-SAAS-T8.12AS.19.2

- commit local keybuzz-client : `20737fd feat(register): renforce le tunnel CRO benchmark` (1 ahead origin/ph148/onboarding-activation-replay)
- NOT PUSHED, NO BUILD, NO DEPLOY
- Runtime inchange (Client DEV deja sur v3.5.199-register-cro-dev de PH-19.1, PROD inchange)
- Image DEV v3.5.199-register-cro-dev devient obsolete : rebuild Client DEV necessaire avant nouvel apply
- Rapport local : keybuzz-infra/docs/PH-SAAS-T8.12AS.19.2-REGISTER-CRO-REFERENCE-UPLIFT-SOURCE-PATCH-01.md (untracked)

Prochaine phrase GO attendue : GO PUSH REGISTER CRO REFERENCE UPLIFT PH-SAAS-T8.12AS.19.2

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-client branche | ph148/onboarding-activation-replay | OK |
| keybuzz-client HEAD pre | 1b29903 = origin | OK |
| keybuzz-client dirty pre | tsconfig.tsbuildinfo (cache tsc preexistant) | OK hors scope |
| keybuzz-api HEAD | 39e332ea = origin (read-only) | OK |
| keybuzz-api dirty | dist/*.js deletes (preexistants) | OK hors scope |
| keybuzz-infra HEAD | ef75ebc (descendant direct documente apply-dev) | OK |
| keybuzz-infra dirty | docs/PH-...-APPLY-DEV-01.md untracked | OK hors scope cette phase |
| GHCR images PH-19.1 | API v3.5.251 + Client v3.5.199 deja pousses + apply DEV deja realise | OK runtime PH-19.1 actif |

## SOURCES RELUES

- AI_MEMORY : CURRENT_STATE.md, RULES_AND_RISKS.md, DOCUMENT_MAP.md, CE_PROMPTING_STANDARD.md
- Rapports PH-19.1 : SOURCE-PATCH-LOCAL-01, BUILD-DEV-01, PUSH-IMAGE-DEV-01, APPLY-DEV-01
- Linear : KEY-329, KEY-333, KEY-324, KEY-325, KEY-330, KEY-331, KEY-332

## BENCHMARK SYNTHESE (sans copie d assets ni de chiffres)

| Reference | Pattern repris | Adaptation KeyBuzz |
|---|---|---|
| BabyLoveGrowth | promesse simple + CTA clair + reassurance immediate + sections "comment ca marche" 3 etapes | promesse "Activez votre cockpit SAV marketplace" + subheadline beneficie + bloc 3 etapes Plan/Espace/Activation. Aucune promesse de trafic (KeyBuzz n est pas marketing growth) |
| Taap | copy explicite + tabs/pills + analytics lisibles + interface utilitaire | pricing/register garde plan/cycle/promo lisibles. Pills "Annuel -20%". Pas un event par bouton : data-cta-id avec params plan/cycle/placement |
| Blabla | headline forte + benefices directs + CTA + essai | headline KeyBuzz "Activez votre cockpit SAV marketplace" + benefices reels (centralise / IA contexte commande / controle equipe). Pas de chiffre invente |
| Gojiberry | onboarding 3 etapes + IA explique simplement + DA marquee | 3 etapes register (Plan / Compte / Activation) + reassurance Amazon OAuth + garde-fous IA. DA accentuee : gradient subtle + badge cycle + accent bleu |

## DECISION PRODUIT

PH-19.1 = socle technique propre.
PH-19.2 = uplift copy/CRO/DA avant nouvelle iteration build+deploy.

Application DEV PH-19.1 actuelle (v3.5.251 API + v3.5.199 Client) reste active. PH-19.2 source patch rendra v3.5.199 obsolete : un nouveau build Client DEV sera necessaire avant re-apply.

API v3.5.251-register-cro-dev (commit 39e332ea KEY-332 tenant_created fix) reste candidate valide - aucun changement API dans PH-19.2.

## FICHIERS MODIFIES

| Repo | Fichier | Insertions | Deletions | Statut |
|---|---|---|---|---|
| keybuzz-client | app/register/page.tsx | 68 | 32 | committed local 20737fd |

Aucun autre fichier touche : API, Website, Infra (sauf rapport docs PH untracked), BFFs, Stripe, Vault, ESO.

## COPY / DESIGN CHANGES DETAIL

### 1) Header global

Avant :
- Image logo + h1 "KeyBuzz"
- Progress bar simple bleu

Apres :
- Image logo + h1 "Activez votre cockpit SAV marketplace" (3xl/4xl bold tracking-tight)
- Subheadline (2 lignes max) : "Centralisez les demandes Amazon, Fnac, Cdiscount et plus, avec un copilote IA qui prepare le contexte commande. Vos equipes gardent le controle - escalades et garde-fous configurables."
- Progress bar avec gradient bleu et labels Plan/Compte/Entreprise/Activation actifs selon currentIdx
- data-testid="register-header" + data-testid="register-step-progress"

Promesses verifiees coherentes KeyBuzz (centralisation marketplace + IA contexte commande + controle humain + escalades + garde-fous). Aucun chiffre/preuve invente.

### 2) Bloc "Comment ca se passe" sur step plan

Inseree avant le grid plans :
- 3 cards en grid 1 col mobile / 3 col desktop
- Etape 1 : Choisissez votre plan (mensuel/annuel -20%, 14 jours essai gratuit, resiliable)
- Etape 2 : Creez votre espace (email pro + societe, donnees sensibles masquees)
- Etape 3 : Lancez l essai 14 jours (Amazon OAuth officiel, vous gardez la main)
- data-testid="register-how-it-works"

Texte explicite "Amazon OAuth officiel" coherent avec connecteurs reels KeyBuzz.

### 3) PlanRecapCard design plus marque

- Background gradient subtle from-blue-950/30 via-gray-800/50
- Border accent blue-500/30 + shadow shadow-blue-500/5
- Badge inline cycle (Mensuel/Annuel -20%) en pill rounded-full bg-blue-500/20 border-blue-500/30
- "Votre selection" en uppercase text-blue-400 tracking-widest
- data-testid="register-plan-recap" + data-plan + data-cycle + data-promo-state (valid/invalid/none)

Toute la logique promo/cycle/benefice est preservee strictement (lecture des memes champs promoPreview).

### 4) Step email : suppression doublon

L ancien micro-recap inline (PH33.11 strikethrough) qui restait au-dessus du form email est supprime. PlanRecapCard fait deja ce job avec le nouveau design + badge cycle.

### 5) data-testid + data-cta-id

| Element | Attribut |
|---|---|
| Header wrapper | data-testid="register-header" |
| Progress stepper | data-testid="register-step-progress" |
| Step plan wrapper | data-testid="register-step-plan" |
| Bloc 3 etapes | data-testid="register-how-it-works" |
| Grid plans | data-testid="register-plan-grid" |
| Chaque plan card | data-testid="register-plan-card" + data-cta-id=`register_plan_select_${plan.id}` + data-plan + data-cycle |
| Cycle toggle wrapper | data-testid="register-cycle-toggle" |
| Cycle toggle button | data-cta-id="register_cycle_toggle" + data-cycle |
| PlanRecapCard | data-testid="register-plan-recap" + data-plan + data-cycle + data-promo-state |

Total : 8 data-testid + 2 data-cta-id sources (data-cta-id register_plan_select_${plan.id} produit 3 occurrences runtime via .map des PLANS).

Aucune nouvelle taxonomie GA4. Aucun event GA4/Meta/TikTok ajoute. Les attributes data-* permettent futurs hooks analytics/tests sans pollution event.

## TRACKING / NO FAKE EVENTS

| Check | Resultat |
|---|---|
| plan_selected dans handleSelectPlan | preserve 1 emit |
| plan_selected dans "Utiliser un autre email" | absent (corrige PH-19.1) |
| Nouvel event fbq Lead/Purchase/StartTrial/CompletePayment dans diff | 0 |
| Nouvel event ttq SubmitForm/InitiateCheckout dans diff | 0 |
| AW-XXXXXXXXXX direct | 0 |
| Events existants src/lib/tracking.ts (trackSignupStart Meta Lead + TikTok SubmitForm, trackSignupComplete Meta CompleteRegistration, trackBeginCheckout Meta+TikTok InitiateCheckout) | preserves, NON modifies par PH-19.2 |
| Sens de plan_selected, register_started, checkout_started, tenant_created | inchange |
| pricing/register compatibilite plan/cycle/coupon/utm/_gl/marketing_owner_tenant_id | preserve |

Decision KEY-330/KEY-331 (retrait events ads browser-side ou migration server-side) reste a prendre - hors scope PH-19.2.

## CLARITY PRESERVATION

| Check | Resultat |
|---|---|
| data-clarity-mask attributs preserves | 13 (inchange PH-19.1) |
| Script clarity.ms charge | absent (0) |
| NEXT_PUBLIC_CLARITY_PROJECT_ID env var | absent (0) |
| wrff07upjx project id website dans client | absent (0) |
| SaaSAnalytics.tsx | inchange |

Clarity client.keybuzz.io reste NON activee. Activation reste decision KEY-325 post-QA register.

## AI FEATURE PARITY / ANTI-REGRESSION

Verifie : aucune promesse produit non supportee par KeyBuzz.

- Headline : "Activez votre cockpit SAV marketplace" - factuel.
- Subheadline : "centralisez les demandes ... copilote IA prepare le contexte commande ... equipes gardent le controle ... escalades et garde-fous configurables" - coherent avec features deployees.
- Bloc 3 etapes : "Choisissez votre plan", "Creez votre espace", "Lancez l essai 14 jours" - factuel.
- PlanRecapCard reassurance : "Connexion Amazon via OAuth officiel SP-API", "Compte vendeur non modifie sans action explicite", "Donnees limitees au strict necessaire" - coherent KeyBuzz.

Aucune promesse :
- "+X% conversions"
- "zero intervention humaine"
- "repond automatiquement partout"
- "augmentation de CA garantie"
- review/temoignage fictif
- logo client fictif
- nombre de clients fictif

## TESTS

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| npx next lint --file app/register/page.tsx | exit 0 | "No ESLint warnings or errors" | OK |
| npx tsc --noEmit (projet) | 0 erreur sur fichiers touches | OK app/register/page.tsx 0 erreur (2 erreurs preexistantes .next/types/app/api/debug-env hors scope, deja documentees PH-19.1) | OK |
| grep data-testid count | 8 sources | 8 | OK |
| grep data-cta-id count | 2 sources | 2 | OK |
| grep data-clarity-mask | 13 (inchange) | 13 | OK |
| grep plan_selected emit | 1 (inchange) | 1 | OK |
| grep clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx dans register | 0 / 0 / 0 | 0 / 0 / 0 | OK |
| grep promoPreview | preserve | 17 occurrences | OK |
| grep _gl dans attribution.ts | preserve | 4 occurrences | OK |
| grep marketing_owner_tenant_id | preserve | 1 (register) + 3 (attribution.ts) | OK |
| grep "Activez votre cockpit SAV" | 1 (new) | 1 | OK |
| grep ancien doublon PH33.11 supprime | 0 | 0 | OK |

## VISUAL / RESPONSIVE STATIC CHECK

Verifications code (pas de dev server demarre cette phase) :
- Mobile 360px : grid 3 etapes en `grid-cols-1` mobile / `sm:grid-cols-3` desktop. Cards stacked sur mobile.
- Header : h1 `text-3xl md:text-4xl` ; subheadline `max-w-xl mx-auto leading-relaxed` ; pas de debordement.
- Stepper progress : labels `text-[10px] uppercase tracking-wider` distribues `flex justify-between`.
- PlanRecapCard : badge inline-flex `text-[10px] tracking-wider px-2 py-0.5 rounded-full` ; pas de chevauchement.
- Plan cards : `hover:shadow-lg hover:shadow-blue-500/10` + transition transform, pas de motion lourde.
- Aucune nouvelle dependance (animation lib).
- Aucune card imbriquee.
- Aucune review/logo/proof sociale ajoutee.

QA browser Ludovic confirmera visuellement post-rebuild Client DEV.

## COMMIT LOCAL

| Repo | Commit local | HEAD origin | Ahead | Dirty hors scope |
|---|---|---|---|---|
| keybuzz-client | 20737fd feat(register): renforce le tunnel CRO benchmark | 1b29903 ph148/onboarding-activation-replay | 1 | tsconfig.tsbuildinfo (cache tsc local) |

Aucun push effectue.
Aucun build Docker effectue.
Aucun docker push effectue.
Aucun deploy effectue.

## LINEAR BROUILLONS (NON postes, token hors-chat)

> KEY-333 (benchmark BabyLoveGrowth/Taap/Blabla/Gojiberry) : Synthese benchmarks integree dans PH-19.2 source patch (commit 20737fd local). Patterns repris : promesse simple + 3 etapes onboarding + DA marquee + reassurance immediate. Aucune copie de design/textes/temoignages/chiffres. Promesses produit verifiees coherentes KeyBuzz. STOP avant push/build/deploy.

> KEY-329 (primary - Register CRO recap) : Register uplift local pret (commit 20737fd). Headline "Activez votre cockpit SAV marketplace" + subheadline benefice business + bloc 3 etapes (Plan/Espace/Activation) + PlanRecapCard design plus marque (gradient + badge cycle + data-promo-state) + 8 data-testid + suppression doublon step email. Tracking canonique preserve, pas d event par bouton. Prochaine etape : push source puis rebuild Client DEV. API v3.5.251 reste candidate.

> KEY-325 (Clarity client) : data-clarity-mask 13 attributs preserve. Clarity client.keybuzz.io toujours NON activee (clarity.ms = 0, NEXT_PUBLIC_CLARITY = 0, wrff07upjx = 0). Activation a traiter apres QA register uplift.

> KEY-330 (taxonomie GA4) / KEY-331 (plan_selected + events ads) : Pas d event par bouton. Boutons identifiables via data-cta-id (register_plan_select_<plan>, register_cycle_toggle) + data-plan + data-cycle + data-promo-state pour futurs hooks analytics sans pollution event. Pricing/register plan/cycle/coupon a verifier dans phase suivante. No fake events preserve. Decision retrait events ads browser-side existants (Meta Lead, TikTok SubmitForm, Meta CompleteRegistration, Meta+TikTok InitiateCheckout) reste a prendre.

## RUNTIME PRESERVE READ-ONLY

| Cluster | Image runtime | Verdict |
|---|---|---|
| keybuzz-client-dev | v3.5.199-register-cro-dev (PH-19.1 deja applique) | DEVIENDRA OBSOLETE apres rebuild PH-19.2 |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev (PH-19.1 deja applique) | INCHANGE (PH-19.2 ne modifie pas API) |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | INCHANGE |

| Artefact | Valeur |
|---|---|
| docker build | NON execute |
| docker push GHCR | NON execute |
| kubectl apply | NON execute |
| kubectl set / patch / edit | NON execute |
| git push (client) | NON execute (commit local 20737fd) |
| Modification manifest infra | aucune |
| Commit infra additionnel | aucun |

## GAPS A DOCUMENTER

1. Client DEV image v3.5.199-register-cro-dev devient obsolete : un rebuild Client DEV est requis apres push commit 20737fd pour avoir un runtime DEV correspondant au source PH-19.2.
2. API DEV image v3.5.251-register-cro-dev reste candidate valide (aucun changement API dans PH-19.2). Pas de rebuild API.
3. Pricing website buttons doivent etre differencies par params (plan, cycle, placement, cta_id, promo state) - applicable hors scope PH-19.2 (website read-only) mais alignement futur souhaitable cote keybuzz-website pricing CTAs.
4. Coupons/promos a auditer apres rebuild Client + apply DEV avant PROD.
5. Clarity client.keybuzz.io activation reste decision post-QA register uplift.
6. Events ads browser-side preexistants (trackSignupStart Meta Lead + TikTok SubmitForm, trackSignupComplete Meta CompleteRegistration, trackBeginCheckout Meta+TikTok InitiateCheckout) restent decision KEY-330/KEY-331.
7. tsconfig.tsbuildinfo cache local Client : artefact tsc, non scope, jamais commit.

## ROLLBACK

Phase source-only NON pushed :
- Rollback local autorise via `git revert 20737fd` (ne PAS git reset --hard, ne PAS git clean).
- Si decision Ludovic d abandonner : demander confirmation avant action destructive.

## CONFIRMATIONS NO BUILD / NO PUSH / NO DEPLOY

- AUCUN docker build
- AUCUN docker push GHCR
- AUCUN kubectl apply / set / patch / edit
- AUCUN git push (commit local 20737fd reste local)
- AUCUN commit infra additionnel (rapport docs PH-19.2 restera untracked)
- AUCUN changement API / Website / Admin / Backend / Studio / Stripe / Vault / ESO
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN secret expose
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- Bastion install-v3 (46.62.171.61) uniquement

## VERDICT FINAL

GO SOURCE PATCH REGISTER CRO REFERENCE UPLIFT READY PH-SAAS-T8.12AS.19.2

| Composant | Statut |
|---|---|
| keybuzz-client commit local | 20737fd (1 ahead origin) |
| Fichiers modifies | app/register/page.tsx (+68/-32) |
| Tests | lint clean + tsc 0 erreur fichiers patches |
| data-testid + data-cta-id | 8 + 2 sources |
| data-clarity-mask preserve | 13 |
| plan_selected emit | 1 (handleSelectPlan, KEY-331) |
| 0 nouvel event fake | OK |
| Clarity client | NON activee |
| Runtime DEV/PROD | inchanges |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.2-REGISTER-CRO-REFERENCE-UPLIFT-SOURCE-PATCH-01.md (untracked) |

Prochaine phrase GO attendue :

GO PUSH REGISTER CRO REFERENCE UPLIFT PH-SAAS-T8.12AS.19.2

STOP.
