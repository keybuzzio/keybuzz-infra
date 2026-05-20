# PH-SAAS-T8.12AS.19.6-REGISTER-CGU-STATE-AND-COPY-SOURCE-PATCH-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.6-REGISTER-CGU-STATE-AND-COPY-SOURCE-PATCH
> Environnement : SOURCE PATCH LOCAL / commit local OK / NO push / NO build / NO deploy

## VERDICT

GO SOURCE PATCH REGISTER CGU STATE + COPY F.9 CUSTOM READY PH-SAAS-T8.12AS.19.6

- Commit local Client : `bae77de` ahead 1 sur origin/ph148/onboarding-activation-replay (fc4a43e)
- 7/7 modifications source appliquees (CGU persist + restore + encart + 4 wordings copy F.9 custom)
- ESLint OK 0 warning 0 error
- tsc OK hors 2 erreurs preexistantes cache obsolete `.next/types/app/api/debug-env`
- Non-regression PH-19.3 (lead-first) + PH-19.4 (selection plan + invalid marketing owner) preserves
- plan_selected emit unique, data-clarity-mask 13 PII, Clarity 0/0, no fake events
- NO BUILD, NO DOCKER PUSH, NO kubectl, NO push commit local

Prochaine phrase GO attendue : `GO PUSH REGISTER CGU STATE + COPY F.9 SOURCE PH-SAAS-T8.12AS.19.6`

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| Client branche | ph148/onboarding-activation-replay | OK |
| Client HEAD local pre | fc4a43e | OK |
| Client HEAD origin pre | fc4a43e | OK |
| Client dirty pre | tsconfig.tsbuildinfo (preexistant) | OK hors scope |
| Lucide-react imports | Check, CreditCard, Phone, MapPin, CheckCircle (deja importes, Lock non requis) | OK |
| .git/hooks/ | aucun hook custom installe | OK |

## MODIFICATIONS SOURCE (7 patches dans `app/register/page.tsx`)

| # | Type | Ligne | Description |
|---|---|---|---|
| 1 | Add | ~102-112 | `initialAcceptCgu` lecture sessionStorage `kb_signup_cgu_accepted` |
| 2 | Modify | 165 | `useState(false)` -> `useState(initialAcceptCgu)` |
| 3 | Add | 170-180 | `useEffect([acceptCgu])` qui ecrit `sessionStorage.kb_signup_cgu_accepted = 'true'` quand acceptCgu = true |
| 4 | Modify | 617 | ReassurancePanel lateral : nouvelle phrase F.9 custom |
| 5 | Modify | 684-691 | Bloc autopilot-trial-note : nouveau bloc 0 EUR F.9 custom (border-green-500/40, bg-green-500/10, icon Check vert) |
| 6 | Add | 757-779 | Encart CGU sur step plan : note "CGU acceptees" + lien Voir CGU si acceptCgu=true, OR checkbox cliquable orange si acceptCgu=false |
| 7 | Modify | 780 + 791 | Bouton "Confirmer ce plan" : `disabled={isLoading \|\| !acceptCgu}` + microcopy F.9 custom |

### Diff stats

| Fichier | +lignes | -lignes |
|---|---|---|
| `app/register/page.tsx` | 51 | 8 |

## COPY F.9 CUSTOM APPLIQUE (wording exact Ludovic)

| Element | Wording final live source |
|---|---|
| Titre bloc (l.687) | `0 EUR pendant 14 jours` |
| Phrase principale (l.690) | `Carte demandee a l'activation. Aucun debit avant la fin de l'essai. Pendant 14 jours, vous testez KeyBuzz avec les capacites Autopilot.` |
| Microcopy CTA (l.791) | `A la fin de l'essai, le plan selectionne devient actif si vous continuez. Vous pouvez changer de plan ou annuler avant cette date.` |
| Variante laterale (l.617) | `0 EUR pendant 14 jours. Essai active avec Autopilot, puis votre plan prend le relais` |

Style visuel bloc 0 EUR : `border-2 border-green-500/40 bg-green-500/10 px-5 py-4` (detonne visuellement du reste, vert rassurant, icon Check). Conserve `data-testid="register-autopilot-trial-note"` pour continuite QA tracking.

## CORRECTIF CGU APPLIQUE (4 sous-points)

| Sous-point | Implementation |
|---|---|
| Persister acceptCgu en sessionStorage | useEffect ecrit `kb_signup_cgu_accepted = 'true'` quand acceptCgu = true |
| Restaurer acceptCgu au mount | `initialAcceptCgu` lit sessionStorage avant useState ; useState init avec cette valeur |
| Encart "CGU acceptees" + lien "Voir les CGU" | data-testid `register-cgu-accepted-note` ; affiche si acceptCgu=true ; lien `setLegalModal('cgu')` |
| Checkbox CGU accessible step plan si pas acceptees | data-testid `register-cgu-plan-checkbox` ; encart orange ; affiche si acceptCgu=false ; bouton Confirmer disabled tant que pas coche |
| Ne pas declencher erreur invisible | Bouton `disabled={isLoading \|\| !acceptCgu}` cote step plan ; la validation l.412 reste mais ne se declenche jamais sans UI (CTA non clickable si !acceptCgu) |

Cas reproduisant le bug avant patch :
- F5 refresh sur step plan -> acceptCgu false initial sans checkbox visible
- URL externe directe `?step=plan` -> idem
- Browser Back depuis Stripe externe -> idem

Cas apres patch :
- F5 refresh sur step plan -> initialAcceptCgu lit sessionStorage, acceptCgu restaure si deja accepte AVANT le refresh. Si jamais accepte (cas anormal), checkbox orange visible sur step plan permet acceptation directe.
- URL externe directe `?step=plan` sans flow prealable -> acceptCgu=false, checkbox orange visible -> user peut accepter -> bouton Confirmer activable.
- Browser Back depuis Stripe -> sessionStorage persiste, acceptCgu=true au restore -> note acceptee visible -> bouton Confirmer activable.

## SCOPE PRESERVE / NON-REGRESSION

| Pattern | Source compte | Verdict |
|---|---|---|
| selectedPlan === plan.id (PH-19.4 fix selection plan) | 3 occurrences | OK |
| data-selected (PH-19.4) | 1 | OK |
| aria-pressed (PH-19.4) | 1 | OK |
| invalid_marketing_owner_tenant_id (PH-19.4 retry fallback) | 1 | OK |
| emitFunnelStep plan_selected (KEY-331 unique) | 1 | OK |
| data-clarity-mask (KEY-325 PII) | 13 | OK |
| register-autopilot-trial-note (data-testid preserve) | preserve avec nouveau contenu | OK |
| register-lead-shell (PH-19.3) | preserve | OK |
| register-reassurance-panel (PH-19.3) | preserve | OK |
| register-confirm-plan (PH-19.3) | preserve | OK |
| Confirmer ce plan et activer l'essai 14 jours (CTA texte) | inchange | OK |

## VIEUX COPY SUPPRIME

| Vieux wording | Count post-patch |
|---|---|
| "Pendant l essai, tout le monde teste Autopilot" | 0 (supprime) |
| "Quel que soit le plan choisi, vous profitez de l experience la plus complete" | 0 (supprime) |
| "CB requise a cette etape uniquement. L essai se fait sur Autopilot" | 0 (supprime) |
| "Essai 14 jours sur Autopilot, puis bascule sur le plan choisi" (panneau lateral) | 0 (remplace par F.9 custom) |

NB : "14 jours d'essai gratuit sur Autopilot - puis bascule sur le plan choisi." (l.683 sous-titre h2) conserve : il s'agit du sous-titre du step plan, coherent avec F.9 custom. Non touche dans ce patch.

NB : Bloc 3 etapes l.644 "Votre choix fixe le plan apres l'essai. Pendant 14 jours, vous testez Autopilot pour voir toute la valeur." NON modifie -- ton acceptable, hors scope wording Ludovic (gap optionnel pour PH-19.7 si Ludovic veut une coherence totale).

## NO FAKE METRICS / NO FAKE EVENTS

- plan_selected reste emis uniquement dans handleSelectPlan (1 occurrence source, KEY-331).
- Aucun nouvel event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout ajoute.
- Aucun tag AW-XXXXXXXXXX direct.
- Aucun event par bouton ajoute. data-cta-id register_confirm_plan_and_checkout preserve.
- data-cta-id register_continue_to_plan preserve (step user CTA).
- Clarity client toujours non activee (clarity.ms 0, NEXT_PUBLIC_CLARITY 0, wrff07upjx 0).
- Aucune fake review / fake metric / fake chiffre / fake logo.

## PROMESSES SENSIBLES (verifier billing/Stripe/API avant ship)

| Promesse copy F.9 custom | Verification requise | Statut |
|---|---|---|
| "0 EUR pendant 14 jours" | Stripe checkout-session trial_period_days = 14 + aucune capture pre-trial | A confirmer Stripe Test mode pendant QA |
| "Aucun debit avant la fin de l essai" | Idem ci-dessus | A confirmer |
| "le plan selectionne devient actif si vous continuez" | API tenant.trial_entitlement_plan -> tenant.plan switch a J+14 (Stripe webhook + API logic preexistante) | A confirmer end-to-end |
| "Vous pouvez changer de plan ou annuler avant cette date" | UI Facturation client avec endpoint update + cancel subscription pendant trial | A confirmer Settings/Billing accessible et fonctionnel |
| "Carte demandee a l activation" | Stripe checkout-session avec card collection requise | Match implementation actuelle |

**Doctrine** : ces promesses doivent etre verifiees en QA fonctionnel avant promotion PROD. Patch source patch ne change PAS la logic billing/API/Stripe -- seulement le copy frontend Client.

## TESTS SOURCE

| Test | Resultat |
|---|---|
| ESLint app/register/page.tsx | OK no warnings/errors |
| tsc strict --noEmit | OK (2 erreurs preexistantes hors scope cache obsolete `.next/types/app/api/debug-env/route.ts` -- regenere a chaque build) |
| Grep nouveaux patterns | initialAcceptCgu present (3 occurrences), useEffect persist CGU present, register-cgu-accepted-note + register-cgu-plan-checkbox presents, copy F.9 custom 4 lignes presentes |
| Grep vieux patterns supprimes | "tout le monde teste Autopilot" = 0, "CB requise a cette etape uniquement" = 0 |
| Grep non-regression PH-19.3/PH-19.4 | tous preserves (selectedPlan, data-selected, aria-pressed, invalid_marketing_owner_tenant_id, plan_selected, data-clarity-mask) |
| Grep Clarity | clarity.ms = 0, NEXT_PUBLIC_CLARITY = 0 (partout dans app/ + src/) |
| Diff git fake events ajoutes | 0 |

## COMMIT LOCAL CLIENT

| Element | Valeur |
|---|---|
| files staged (1) | `app/register/page.tsx` |
| commit hash | bae77de |
| commit title | fix(register): persiste CGU et clarifie copy 0 EUR pendant 14 jours |
| commit body | PH-SAAS-T8.12AS.19.6-REGISTER-QA-CGU-STATE-AND-COPY ; bug CGU + copy F.9 custom |
| insertions/deletions | +51 / -8 |
| HEAD local apres | bae77de |
| origin/ph148 apres | fc4a43e (INCHANGE, ahead 1) |
| status dirty | tsconfig.tsbuildinfo (preexistant, exclus du commit) |
| push | NON execute (NO push regle absolue de la phase) |

## CONFIRMATIONS NO BUILD / NO PUSH / NO DEPLOY

- AUCUN docker build
- AUCUN docker push
- AUCUN kubectl apply / set / patch / edit
- AUCUN deploy DEV / PROD
- AUCUN manifest infra modifie
- AUCUN git push (commit local Client uniquement)
- AUCUN changement source API / Backend / Admin / Studio / Website / Stripe / Vault / ESO
- AUCUN secret expose
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE creation tenant reelle
- AUCUN checkout Stripe reel
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN Linear ticket close
- Bastion install-v3 (46.62.171.61) uniquement

## LINEAR BROUILLONS (NON postes, token hors-chat ; reauth Codex 401)

> **KEY-335 (primary)** : PH-19.6 source patch local pret. Commit Client `bae77de` ahead 1. (1) Bug CGU corrige : persist sessionStorage `kb_signup_cgu_accepted` + restore au mount + encart CGU step plan (note acceptee avec lien OR checkbox accessible si pas acceptee) + bouton Confirmer disabled si !acceptCgu (plus d erreur invisible). (2) Copy F.9 custom Ludovic applique : bloc 0 EUR pendant 14 jours (vert, detonne), phrase "Carte demandee a l'activation. Aucun debit avant la fin de l'essai. Pendant 14 jours, vous testez KeyBuzz avec les capacites Autopilot.", microcopy CTA "A la fin de l'essai, le plan selectionne devient actif si vous continuez. Vous pouvez changer de plan ou annuler avant cette date.", variante laterale "0 EUR pendant 14 jours. Essai active avec Autopilot, puis votre plan prend le relais." ESLint OK, tsc OK, non-regression PH-19.3+19.4 preservee. plan_selected unique. Clarity non activee. No fake events. STOP avant push/build/deploy.

> **KEY-334** : Tunnel lead-first preserve dans le patch PH-19.6. Patterns register-lead-shell + register-reassurance-panel + register-confirm-plan inchanges. handleConfirmPlanAndCheckout signature inchangee (sauf disabled=!acceptCgu sur le bouton).

> **KEY-329** : Copy CRO post-PH-19.6 plus pro/B2B (style Stripe/Atlassian factuel). Bloc 0 EUR signal financier fort, sans fake review ni superlatif risque.

> **KEY-331** : plan_selected preserve unique (1 emit source canonique dans handleSelectPlan).

> **KEY-330** : No fake events ajoutes par PH-19.6. AW- direct = 0.

> **KEY-325** : Clarity client toujours non activee dans le patch. data-clarity-mask 13 PII inputs preserves.

## GAPS

1. Bloc 3 etapes l.644 "Votre choix fixe le plan apres l'essai. Pendant 14 jours, vous testez Autopilot pour voir toute la valeur." NON modifie dans ce patch (hors scope wording Ludovic). Ton acceptable mais pourrait etre rendu plus pro en PH-19.7 (ex: "Pendant 14 jours, vous accedez aux capacites Autopilot.").
2. Sous-titre h2 "Choisissez votre plan" l.682-683 : "14 jours d'essai gratuit sur Autopilot - puis bascule sur le plan choisi." -- conserve, coherent avec F.9 custom. Pourrait etre simplifie en "14 jours sur Autopilot. Aucun debit avant J+14." si Ludovic veut une coherence totale du nouveau ton.
3. Verifications Stripe/API a faire en QA fonctionnel pre-promotion PROD : trial_period_days=14, absence capture pre-trial, UI Facturation accessible pour change plan / annuler pendant trial.
4. tsc 2 erreurs preexistantes sur `.next/types/app/api/debug-env/route.ts` (cache obsolete depuis PH-19.0 f61763a) ; non bloquant (regenere a chaque build).
5. Cleanup sessionStorage `kb_signup_cgu_accepted` apres success Stripe : NON ajoute dans ce patch (low risk, sessionStorage est efface a la fermeture de tab). Si Ludovic veut cleanup explicite, l ajouter en PH-19.7.
6. Tests fonctionnels QA Ludovic requis pour valider visuellement : (a) bloc 0 EUR vert visible et detonne, (b) microcopy CTA F.9 affiche, (c) variante laterale ReassurancePanel modifiee, (d) checkbox CGU apparait sur step plan si pas acceptee (cas reproduisible : refresh F5 sur step plan), (e) note "CGU acceptees" + lien Voir CGU apparait sur step plan si deja acceptee, (f) bouton Confirmer disabled tant que CGU pas cochee.

## ROLLBACK LOCAL

Si necessaire, rollback local strict (NO push, NO destruct) :
- `git -C /opt/keybuzz/keybuzz-client reset --soft HEAD~1` (revient sur fc4a43e tout en gardant le patch en index)
- ou `git -C /opt/keybuzz/keybuzz-client revert bae77de` (commit inverse propre)
- INTERDIT : `git reset --hard`, `git clean`, `git push --force`

Aucun runtime touche, aucun rollback runtime necessaire.

## VERDICT FINAL

GO SOURCE PATCH REGISTER CGU STATE + COPY F.9 CUSTOM READY PH-SAAS-T8.12AS.19.6

| Indicateur | Valeur |
|---|---|
| Commit local Client | bae77de |
| Origin/ph148 | fc4a43e (INCHANGE, ahead 1) |
| Files modifies | 1 (app/register/page.tsx) |
| Lignes | +51 / -8 |
| ESLint | OK 0 warning 0 error |
| tsc | OK (2 erreurs preexistantes hors scope) |
| Patches 7/7 appliques | OK (CGU persist + restore + useEffect + encart + 4 wordings F.9 custom) |
| Non-regression PH-19.3+19.4 | preservee |
| plan_selected | unique source |
| data-clarity-mask | 13 PII preserves |
| Clarity activation | 0/0 |
| No fake events | OK |
| No fake reviews/logos/chiffres | OK |
| Runtime DEV/PROD | inchange (no apply) |
| NO BUILD | OK |
| NO DOCKER PUSH | OK |
| NO kubectl | OK |
| NO git push | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.6-REGISTER-CGU-STATE-AND-COPY-SOURCE-PATCH-01.md (untracked attendu) |

Prochaine phrase GO attendue :

GO PUSH REGISTER CGU STATE + COPY F.9 SOURCE PH-SAAS-T8.12AS.19.6

STOP.
