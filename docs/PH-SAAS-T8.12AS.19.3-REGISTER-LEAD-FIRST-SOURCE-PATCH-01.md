# PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-SOURCE-PATCH-01

> Date : 2026-05-20
> Linear : KEY-334 (primary), KEY-329, KEY-333, KEY-325, KEY-330, KEY-331
> Phase : PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-SOURCE-PATCH
> Environnement : SOURCE ONLY / aucun build / aucun deploy

## VERDICT

GO SOURCE PATCH REGISTER LEAD FIRST READY PH-SAAS-T8.12AS.19.3

- commit local keybuzz-client : `397687a feat(register): passe le tunnel en lead-first` (1 ahead origin/ph148/onboarding-activation-replay)
- NOT PUSHED, NO BUILD, NO DEPLOY
- Runtime DEV/PROD inchanges (Client DEV reste sur v3.5.200-register-cro-uplift-dev, obsolete apres push PH-19.3)
- Rapport local : keybuzz-infra/docs/PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-SOURCE-PATCH-01.md (untracked)

Prochaine phrase GO attendue : GO PUSH REGISTER LEAD FIRST SOURCE PH-SAAS-T8.12AS.19.3

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-client branche | ph148/onboarding-activation-replay | OK |
| keybuzz-client HEAD pre | 20737fd = origin | OK |
| keybuzz-client dirty pre | tsconfig.tsbuildinfo (cache tsc) | hors scope |
| keybuzz-infra HEAD | 7d62687 = origin | OK (1 rapport PH-19.2-APPLY-DEV-01 untracked preexistant) |

## BENCHMARK SYNTHESE SIGNUP (sans copie d assets/textes/chiffres)

| Reference | Pattern repris | Adaptation KeyBuzz |
|---|---|---|
| Gojiberry registration | split layout form + reassurance, formulaire compte direct, CTA Start Trial, reassurance trial/cancel | layout split desktop grid lg:grid-cols-[1fr_380px], CTA "Continuer vers le plan" sur user step, reassurance factuelle KeyBuzz |
| BabyLoveGrowth sign-up | inscription d abord, social proof a droite | inscription/contact d abord en lead-first, ReassurancePanel a droite avec proof produit factuelle. AUCUN chiffre invente, aucun "4000+ entreprises" |
| Taap signup | compte en quelques minutes, email/password + conditions, visuel produit a droite, pas de plan initial | step plan repousse apres collecte prospect, panneau lateral avec "Ce que KeyBuzz va gerer". Pas de visuel/asset copie |
| Blabla login/signup | panneau gauche social proof, form a droite, CTA "Commencer gratuitement" | panneau ReassurancePanel a droite (inverse), CTA principal "Confirmer ce plan et activer l essai 14 jours" sur step plan. Pas de logo/review fictif |

## DECISION PRODUIT LEAD-FIRST

Ordre cible implemente :

1. Contact prospect : email -> code OTP (ou OAuth Google)
2. Entreprise : nom societe + adresse + telephone + email support
3. Vous : prenom + nom + telephone + CGU
4. Plan : grille plans (avec preselection si URL plan), CTA "Confirmer ce plan et activer l essai 14 jours"
5. Activation : redirection Stripe (cree tenant + checkout au moment de la confirmation)

Aucune CB demandee avant la step 4. Aucune creation de tenant avant le clic "Confirmer ce plan".

## FICHIERS MODIFIES

| Repo | Fichier | Insertions | Deletions | Statut |
|---|---|---|---|---|
| keybuzz-client | app/register/page.tsx | 99 | 22 | committed local 397687a |

Aucun autre fichier touche : API, Website, Infra (sauf rapport docs PH untracked), BFFs, Stripe, Vault, ESO.

## STEP ORDER AVANT / APRES

| Phase | stepsOrder | Initial default | First screen visuel |
|---|---|---|---|
| Avant PH-19.3 | plan / email / code / company / user / checkout / payment_cancelled | plan (sauf urlPlan present + OAuth) | grille 3 plans (Starter/Pro/Autopilot) |
| Apres PH-19.3 | email / code / company / user / plan / checkout / payment_cancelled | email (sauf OAuth -> company) | formulaire email + ReassurancePanel a droite |

| Step | Role | Donnees collectees | Action suivante |
|---|---|---|---|
| email | saisie email pro | email | handleSendCode -> code |
| code | verification OTP 6 chiffres | code | handleVerifyCode -> company |
| company | infos societe | companyName, siret, street, zipCode, city, country, companyPhone, supportEmail | handleCompanySubmit -> user |
| user | prenom/nom/telephone/CGU | firstName, lastName, phone, acceptCgu | handleUserSubmit -> plan (PH-19.3 : ne lance plus Stripe ici) |
| plan | grille plans + CTA confirmer | selectedPlan (cliquable), billingCycle (toggle), promoPreview | handleConfirmPlanAndCheckout -> checkout (cree tenant + Stripe) |
| checkout | spinner redirection | n/a | window.location.href = stripe URL |
| payment_cancelled | retry | n/a | handleRetryCheckout -> Stripe |

## PATCH DETAIL

### P1 - Initial state default = 'email'

Avant :
```
useState<Step>(urlStep || (isOAuthUser && effectivePlan ? 'company' : effectivePlan ? (isOAuthUser ? 'company' : 'email') : 'plan'))
```

Apres :
```
useState<Step>(urlStep || (isOAuthUser ? 'company' : 'email'))
```

Lead-first : plus de fallback 'plan' au premier ecran. Si URL contient plan/cycle, ces valeurs restent en state (selectedPlan/billingCycle) mais step demarre sur email.

### P2 - stepsOrder reorder

Avant : `['plan', 'email', 'code', 'company', 'user', 'checkout', 'payment_cancelled']`

Apres : `['email', 'code', 'company', 'user', 'plan', 'checkout', 'payment_cancelled']`

Plan deplace apres user, devient etape de confirmation finale avant checkout.

### P3 - Progress labels reorder

Avant 4 labels : Plan (>=0), Compte (>=1), Entreprise (>=3), Activation (>=5).

Apres 5 labels :
- Compte (>=0)
- Entreprise (>=2)
- Vous (>=3)
- Plan (>=4)
- Activation (>=5)

### P4 - handleSelectPlan : retire setStep + trackSignupStep

Avant : clic plan card -> setSelectedPlan + emit plan_selected + setStep('email'|'company').

Apres : clic plan card sur step plan = setSelectedPlan + emit plan_selected (unique via dedupe) + trackSignupStart. **Reste sur step plan**. L avancee vers checkout est faite via le nouveau CTA "Confirmer ce plan et activer l essai 14 jours".

### P5 - handleUserSubmit split + nouveau handleConfirmPlanAndCheckout

Avant : handleUserSubmit (async) -> validate CGU + fetch create-signup + fetch checkout-session + window.location.href = stripe URL.

Apres :
- handleUserSubmit (sync) : valide CGU + emit user_completed + setStep('plan') + trackSignupStep('plan').
- handleConfirmPlanAndCheckout (async, NOUVEAU) : contient l ancien logic (fetch create-signup + fetch checkout-session + redirect Stripe). Appele depuis CTA "Confirmer ce plan" sur step plan.

Avantage : aucun tenant n est cree avant la confirmation explicite du plan + activation essai.

### P6 - Step user CTA renomme

Avant : `<button type="submit" disabled={... || isLoading}>... CreditCard icon ... Creer et passer au paiement`.

Apres : `<button type="submit" disabled={... pas isLoading}> ArrowRight icon ... Continuer vers le plan` + data-cta-id="register_continue_to_plan".

### P7 - Step plan : CTA confirmation finale ajoute

Apres la phrase footer "Facturation ... Essai 14 jours inclus", ajout d un bloc visible si selectedPlan defini :

- CTA principal "Confirmer ce plan et activer l essai 14 jours" -> handleConfirmPlanAndCheckout
- data-cta-id="register_confirm_plan_and_checkout" + data-plan + data-cycle + data-promo-state
- Sous-texte : "CB requise a cette etape uniquement. Resiliable a tout moment pendant l essai."

### P8 - Layout wrapper split + ReassurancePanel

Wrapper transforme :
- Avant : `<div className="min-h-screen ... flex flex-col items-center justify-center p-4"><div className="w-full max-w-2xl">`
- Apres : `<div className="min-h-screen ... lg:grid lg:grid-cols-[1fr_380px]" data-testid="register-lead-shell"><div className="flex flex-col items-center justify-center p-4 lg:p-8"><div className="w-full max-w-2xl" data-testid="register-lead-form">`

Fin du wrapper : ajout `<ReassurancePanel />` avant la fermeture du shell.

ReassurancePanel component (composant local React) :
- Aside hidden lg:flex - visible uniquement sur desktop, hidden mobile
- Sticky top, panneau bord gauche en lg
- Titre : "Ce que KeyBuzz va gerer"
- Sous-titre : "Votre cockpit SAV centralise, sous controle"
- 4 bullet points proof KeyBuzz factuels (Amazon OAuth officiel, copilote IA contexte commande, escalades/garde-fous, donnees masquees)
- 3 bullet points reassurance compacts (plan/coupon avant Stripe, essai 14j resiliable, attribution preservee)
- AUCUNE review, AUCUN logo client, AUCUN chiffre invente

## TRACKING / NO FAKE EVENTS

| Check | Resultat |
|---|---|
| plan_selected emit unique dans handleSelectPlan | 1 (preserve) |
| Nouvel event fbq Lead/Purchase/StartTrial/CompletePayment dans diff | 0 |
| Nouvel event ttq SubmitForm/InitiateCheckout dans diff | 0 |
| AW-XXXXXXXXXX direct dans diff | 0 |
| Events existants tracking.ts (trackSignupStart Meta Lead + TikTok SubmitForm, trackSignupComplete Meta CompleteRegistration, trackBeginCheckout Meta+TikTok InitiateCheckout) | preserves, NON modifies par PH-19.3 |
| plan_selected sur preselection URL (sans clic utilisateur) | n est PAS emis (dedupe + handler appele uniquement sur clic) |
| Sens de register_started, plan_selected, user_completed, tenant_created, checkout_started | inchange |

Decision KEY-330/KEY-331 (retrait events ads browser-side ou migration server-side) reste a prendre - hors scope PH-19.3.

## CLARITY PRESERVATION

| Check | Resultat |
|---|---|
| data-clarity-mask sur inputs PII | 13 (inchange) |
| Script clarity.ms | absent (0) |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | absent (0) |
| wrff07upjx (project id website) dans client | absent (0) |
| SaaSAnalytics.tsx | inchange |

## AI FEATURE PARITY / ANTI-REGRESSION

Promesses produit verifiees coherentes KeyBuzz :

| Texte | Verite produit |
|---|---|
| "Activez votre cockpit SAV marketplace" (header) | OK factuel |
| "Centralisez les demandes Amazon, Fnac, Cdiscount" (subheadline) | OK connecteurs reels |
| "copilote IA qui prepare le contexte commande" | OK (AI feature deja deployee) |
| "Vos equipes gardent le controle - escalades et garde-fous configurables" | OK (escalades + garde-fous existent) |
| "Connexion Amazon, Fnac, Cdiscount via OAuth officiel SP-API" | OK (connecteur Amazon SP-API actif) |
| "Plan et coupon confirmes avant Stripe" | OK (vrai apres PH-19.3 lead-first) |
| "CB requise a cette etape uniquement" | OK (handleConfirmPlanAndCheckout est le seul point d entree Stripe) |
| "Essai 14 jours, resiliable a tout moment" | OK (deja en place) |
| "Attribution marketing preservee jusqu au checkout" | OK (UTM/_gl/marketing_owner_tenant_id/promo preserves) |

AUCUNE promesse :
- "+X% conversions"
- "zero intervention humaine"
- "repond automatiquement partout"
- "augmentation CA garantie"
- "automatisation totale sans controle"
- review/temoignage fictif
- logo client fictif
- nombre de clients fictif

## TESTS

| Test | Attendu | Resultat |
|---|---|---|
| npx next lint --file app/register/page.tsx | exit 0, no warnings/errors | OK "No ESLint warnings or errors" |
| npx tsc --noEmit | 0 erreur sur fichier patche | OK (0 erreur lancee, .next/types anciennes nettoyees) |
| grep stepsOrder = email,code,company,user,plan,checkout,payment_cancelled | OK | OK |
| grep initial step useState default email | OK | OK |
| grep handleConfirmPlanAndCheckout | 4 occurrences (def + setStep refs + onClick) | 4 |
| grep register-lead-shell / register-lead-form / register-reassurance-panel / register-confirm-plan | 1/1/1/1 | OK |
| grep "Continuer vers le plan" | 1 | OK |
| grep "Confirmer ce plan et activer" | 2 (CTA + commentaire) | OK |
| grep "Creer et passer au paiement" (ancien) | 0 | OK supprime |
| grep data-clarity-mask | 13 preserve | OK |
| grep emitFunnelStep plan_selected | 1 unique | OK |
| grep clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx | 0 / 0 / 0 | OK |
| grep data-cta-id | 4 (2 anciens PH-19.2 + 2 nouveaux PH-19.3) | OK |
| Nouveau fake event dans diff (Lead/Purchase/SubmitForm/InitiateCheckout) | 0 | OK |
| AW direct dans diff | 0 | OK |

## VISUAL / RESPONSIVE STATIC CHECK

Verifications code (pas de dev server demarre cette phase) :

Desktop (lg:) :
- `lg:grid lg:grid-cols-[1fr_380px]` -> 2 colonnes : form (1fr) + ReassurancePanel (380px)
- ReassurancePanel `hidden lg:flex lg:flex-col lg:justify-center lg:p-8 lg:bg-gray-900/40 lg:border-l lg:border-gray-800 lg:min-h-screen lg:sticky lg:top-0` -> sticky visible desktop
- Form panel `flex flex-col items-center justify-center p-4 lg:p-8` -> centered
- `max-w-2xl` interne -> taille form preservee

Mobile (default) :
- Single column (grid default = block sur mobile)
- ReassurancePanel `hidden lg:flex` -> HIDDEN sur mobile (compact, pas de chevauchement)
- Form panel pleine largeur (p-4)
- CTA toujours visible

Anti-debordement :
- Header `text-3xl md:text-4xl` + `max-w-xl mx-auto` subheadline -> pas de debordement
- ReassurancePanel `max-w-sm` content interne -> ne pousse pas la colonne
- Plan cards `grid md:grid-cols-3 gap-4` -> sur mobile single column
- Pas de nested cards (PlanRecapCard reste compact)
- Pas d animation lourde, transitions Tailwind uniquement

Aucune nouvelle dependency. Aucun fake social proof.

## COMMIT LOCAL

| Repo | Commit local | HEAD origin | Ahead | Dirty hors scope |
|---|---|---|---|---|
| keybuzz-client | 397687a feat(register): passe le tunnel en lead-first | 20737fd ph148/onboarding-activation-replay | 1 | tsconfig.tsbuildinfo |

Aucun push effectue. Aucun build Docker. Aucun docker push. Aucun deploy.

## LINEAR BROUILLONS (NON postes, token hors-chat)

> **KEY-334 (primary)** : Source patch local pret (commit 397687a). Lead-first implemente : default step 'email', stepsOrder reorder (plan apres user), grille plans cachee first screen. Layout split desktop + ReassurancePanel a droite avec proof KeyBuzz factuelle (aucun fake review/logo/chiffre). CTA "Continuer vers le plan" sur user step + "Confirmer ce plan et activer l essai 14 jours" sur step plan. handleConfirmPlanAndCheckout extrait pour deplacer creation tenant + Stripe a la confirmation explicite du plan. STOP avant push/build/deploy.

> **KEY-329 (Register CRO)** : Register CRO passe en lead-first. Build Client DEV requis apres push. API v3.5.251 reste candidate.

> **KEY-333 (benchmark)** : Signup benchmark applique en structure (Gojiberry/BabyLoveGrowth/Taap/Blabla split layout + lead-first ordering), sans copie d assets/textes/temoignages/chiffres. Promesses produit verifiees coherentes KeyBuzz.

> **KEY-325 (Clarity)** : Clarity client.keybuzz.io toujours NON activee. data-clarity-mask 13 inputs PII preserve. Activation post-QA register lead-first.

> **KEY-330 (no fake events) / KEY-331 (plan_selected)** : plan_selected emit unique dans handleSelectPlan preserve (clic plan = selection visuelle + emit unique via dedupe). Pas d event par bouton (data-cta-id : register_continue_to_plan, register_confirm_plan_and_checkout, register_plan_select_<plan>, register_cycle_toggle). 0 nouveau fake event Lead/Purchase/SubmitForm/InitiateCheckout dans diff. 0 AW direct. Events ads browser-side existants src/lib/tracking.ts inchanges.

## RUNTIME PRESERVE READ-ONLY

| Cluster | Image runtime | Verdict |
|---|---|---|
| keybuzz-client-dev | v3.5.200-register-cro-uplift-dev (PH-19.2) | INCHANGE - **deviendra obsolete** apres push PH-19.3 |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE (candidate valide PH-19.3 non touche API) |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | INCHANGE |

| Artefact | Valeur |
|---|---|
| docker build | NON execute |
| docker push GHCR | NON execute |
| kubectl apply | NON execute |
| Modification manifest infra | aucune |
| Commit infra additionnel | aucun |
| git push application | NON execute (commit 397687a reste local) |

## GAPS A DOCUMENTER

1. Client DEV image v3.5.200-register-cro-uplift-dev deviendra obsolete apres push commit 397687a : un rebuild Client DEV est requis.
2. API DEV image v3.5.251-register-cro-dev reste candidate valide (aucun changement API dans PH-19.3).
3. Lead enrichment fields (marketplaces utilisees, volume commandes, volume tickets SAV, urgence/objectif, role contact) : non ajoutes dans cette phase car non persistes par backend actuellement. Dette documentee pour future phase API PH-19.4-LEAD-ENRICHMENT.
4. Events ads browser-side preexistants (Meta Lead, TikTok SubmitForm, Meta CompleteRegistration, Meta+TikTok InitiateCheckout) restent decision KEY-330/KEY-331.
5. Clarity activation client.keybuzz.io reste decision post-QA register lead-first.
6. Email logo template magic-link `client.keybuzz.io/branding/...` preexistant hors scope - non lie a PH-19.3.
7. Marketing tracking IDs (GA4/Meta/TikTok/SGTM) toujours omis du build (iso baseline) - decision activation DEV ulterieure si Ludovic souhaite.
8. tsconfig.tsbuildinfo cache local Client : artefact tsc, jamais commit.

## ROLLBACK

Phase source-only NON pushed :
- Rollback local autorise via `git revert 397687a` (ne PAS git reset --hard, ne PAS git clean).
- Si decision Ludovic d abandonner : demander confirmation avant action destructive.

## CONFIRMATIONS NO BUILD / NO PUSH / NO DEPLOY

- AUCUN docker build
- AUCUN docker push GHCR
- AUCUN kubectl apply / set / patch / edit
- AUCUN git push (commit local 397687a reste local)
- AUCUN commit infra additionnel (rapport PH-19.3 sera untracked apres mv)
- AUCUN changement API / Website / Admin / Backend / Studio / Stripe / Vault / ESO
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN secret expose
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- Bastion install-v3 (46.62.171.61) uniquement

## VERDICT FINAL

GO SOURCE PATCH REGISTER LEAD FIRST READY PH-SAAS-T8.12AS.19.3

| Composant | Statut |
|---|---|
| keybuzz-client commit local | 397687a (1 ahead origin) |
| Fichiers modifies | app/register/page.tsx (+99/-22) |
| Tests | lint clean + tsc 0 erreur fichiers patches |
| Step order avant/apres | plan-first -> lead-first (plan deplace apres user) |
| Initial step default | 'email' (au lieu de 'plan') |
| Layout | split desktop + ReassurancePanel sticky |
| Nouveau handler | handleConfirmPlanAndCheckout (creation tenant + Stripe a la confirmation finale) |
| data-testid + data-cta-id | 12 + 4 sources |
| data-clarity-mask preserve | 13 |
| plan_selected emit unique | 1 |
| Clarity client | NON activee |
| 0 nouveau fake event | OK |
| Runtime DEV/PROD | inchanges |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-SOURCE-PATCH-01.md (untracked) |

Prochaine phrase GO attendue :

GO PUSH REGISTER LEAD FIRST SOURCE PH-SAAS-T8.12AS.19.3

STOP.
