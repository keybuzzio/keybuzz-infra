# PH-SAAS-T8.12AS.19.7-REGISTER-STATE-PERSISTENCE-SOURCE-01

> Date : 2026-05-20
> Linear : KEY-335 follow-up ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.7-REGISTER-STATE-PERSISTENCE-SOURCE
> Environnement : SOURCE PATCH LOCAL / commit local OK / NO push / NO build / NO deploy

## VERDICT

GO SOURCE PATCH REGISTER STATE PERSISTENCE READY PH-SAAS-T8.12AS.19.7

- Commit local Client : `8553bad` ahead 1 sur `origin/ph148/onboarding-activation-replay` (`bae77de`)
- 16/16 modifications appliquees : SignupDraft type + initialDraft read + 14 useState init fallback + useEffect persist
- ESLint OK 0 warning 0 error
- tsc OK hors 2 erreurs preexistantes cache obsolete `.next/types/app/api/debug-env`
- Non-regression PH-19.3 + PH-19.4 + PH-19.5 + PH-19.6 preservee
- plan_selected unique, data-clarity-mask 13 PII, Clarity 0/0, no fake events
- Audit lead draft server-side : recommandation pour PH-19.8 separe
- NO BUILD, NO DOCKER PUSH, NO kubectl, NO push commit local

Prochaine phrase GO attendue : `GO PUSH REGISTER STATE PERSISTENCE SOURCE PH-SAAS-T8.12AS.19.7`

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| Client branche | ph148/onboarding-activation-replay | OK |
| Client HEAD local pre | bae77de | OK |
| Client HEAD origin pre | bae77de | OK |
| Client dirty pre | tsconfig.tsbuildinfo (preexistant) | OK hors scope |
| Infra HEAD = origin | b1e98d1 | OK |
| Infra dirty | docs/PH-19.6 APPLY untracked (attendu) | OK |

## BUG REPRODUIT (constat Ludovic)

| Step | Action | Resultat avant patch | Diagnostic |
|---|---|---|---|
| 1 | User remplit email -> code -> company -> user -> coche CGU | OK | flow standard |
| 2 | User arrive step plan, choisit plan, click "Confirmer ce plan" | tenant cree + Stripe checkout-session ouvert | OK |
| 3 | User redirige vers Stripe Checkout externe | Stripe ouvert dans onglet ou nouveau tab | OK |
| 4 | User fait Back browser depuis Stripe ou cancelUrl Stripe | retour `/register?...&cancelled=1` (ou bfcache HMR) | OK navigation |
| 5 | User est sur step plan, change selectedPlan, click "Confirmer ce plan" | **handleConfirmPlanAndCheckout** -> API `/api/auth/create-signup` -> 400 "Le nom de societe est requis" (companyName state vide) | BUG : remount React reset state useState('') |

Cause racine : aucun state register persiste cote Client. Quand le composant `RegisterPage` est re-mount (refresh, Back browser, navigation Next.js), tous les `useState('')` repartent vide. Le pattern PH-19.6 fix UNIQUEMENT `acceptCgu` ; les autres champs (`companyName`, `firstName`, `selectedPlan`, etc.) restent perdus.

## MODIFICATIONS SOURCE (16 patches dans `app/register/page.tsx`)

| # | Type | Element | Description |
|---|---|---|---|
| 1 | Add | SignupDraft type + initialDraft read | Type TypeScript inline + lecture sessionStorage `kb_signup_form_draft_v1` au pre-mount |
| 2 | Modify | useState selectedPlan | `initialDraft.selectedPlan ?? effectivePlan` fallback URL/sessionStorage |
| 3 | Modify | useState billingCycle | `initialDraft.billingCycle \|\| (effectiveCycle === 'yearly' ? 'yearly' : 'monthly')` |
| 4 | Modify | useState email | `isOAuthUser ? oauthEmail : (initialDraft.email \|\| urlEmail \|\| '')` |
| 5 | Modify | useState companyName | `initialDraft.companyName \|\| ''` |
| 6 | Modify | useState siret | `initialDraft.siret \|\| ''` |
| 7 | Modify | useState street | `initialDraft.street \|\| ''` |
| 8 | Modify | useState zipCode | `initialDraft.zipCode \|\| ''` |
| 9 | Modify | useState city | `initialDraft.city \|\| ''` |
| 10 | Modify | useState country | `initialDraft.country \|\| 'FR'` |
| 11 | Modify | useState companyPhone | `initialDraft.companyPhone \|\| ''` |
| 12 | Modify | useState supportEmail | `initialDraft.supportEmail \|\| ''` |
| 13 | Modify | useState firstName | `initialDraft.firstName \|\| ''` |
| 14 | Modify | useState lastName | `initialDraft.lastName \|\| ''` |
| 15 | Modify | useState phone | `initialDraft.phone \|\| ''` |
| 16 | Add | useEffect persist draft | useEffect dependant des 14 champs, ecrit `kb_signup_form_draft_v1` JSON.stringify dans sessionStorage a chaque changement |

### Diff stats

| Fichier | +lignes | -lignes |
|---|---|---|
| `app/register/page.tsx` | 63 | 14 |

## CHAMPS PERSISTES vs NON-PERSISTES

### Champs persistes dans `kb_signup_form_draft_v1`

| Champ | Type | Source useState |
|---|---|---|
| email | string | l.166 |
| selectedPlan | Plan \| null | l.160 |
| billingCycle | Cycle | l.161 |
| companyName | string | l.177 |
| siret | string | l.178 |
| street | string | l.179 |
| zipCode | string | l.180 |
| city | string | l.181 |
| country | string (default FR) | l.182 |
| companyPhone | string | l.183 |
| supportEmail | string | l.184 |
| firstName | string | l.187 |
| lastName | string | l.188 |
| phone | string | l.189 |

### Champs NON persistes (decision explicite)

| Champ | Raison |
|---|---|
| `code` (OTP) | secret one-time-use, ne JAMAIS persister |
| `devCode` | dev-only debug, jamais ecrit en runtime user |
| `step` | gere par URL (`?step=`) + restoration via `urlStep` ; pas de cas user-bug demande |
| `acceptCgu` | deja persiste separement via `kb_signup_cgu_accepted` (PH-19.6) |
| `attribution` (UTM/click IDs) | deja gere par `kb_signup_context` (PH-OAuth flow restore) + storage attribution interne (`@/src/lib/attribution`) |
| `promo` | derive de `urlPromo \|\| attribution?.promo` (URL + attribution lib) |

## CLEANUP DRAFT (decision)

| Point | Decision |
|---|---|
| Avant redirect Stripe | NON cleanup. L user doit pouvoir revenir depuis Stripe (Back browser / cancelUrl) sans perdre ses champs. |
| Apres success Stripe (`/register/success?session_id=...`) | NON applique dans ce patch. A traiter en PH-19.x ulterieure si un point fiable est ajoute (par exemple route `/register/success`). |
| Apres signup tenant cree (post-COMMIT API) | NON applique dans ce patch (laissera le draft dans sessionStorage jusqu a la fermeture du tab). Risque faible : sessionStorage est scope par tab. |

Documentation gap : voir section "GAPS" pour le cleanup post-success.

## TESTS SOURCE

| Test | Resultat |
|---|---|
| ESLint app/register/page.tsx | OK 0 warnings 0 errors |
| tsc strict --noEmit | OK (2 erreurs preexistantes hors scope `.next/types/app/api/debug-env/route.ts`) |
| Grep `kb_signup_form_draft_v1` | 2 occurrences (read mount + write useEffect) |
| Grep `initialDraft` | 14 occurrences (1 type + 1 init + 14 fallback inits = 14 references field-name) |
| Grep `SignupDraft` type | 4 occurrences (type def + 3 utilisations) |
| `companyName` dans draft persist+restore | 1 init `initialDraft.companyName` + 1 dans persist obj + 1 dans deps array |
| Grep `emitFunnelStep plan_selected` | 1 occurrence (unique, KEY-331 preserve) |
| Grep `data-clarity-mask` | 13 occurrences (KEY-325 PII preserve) |
| Grep Clarity (clarity.ms / NEXT_PUBLIC_CLARITY) | 0 / 0 partout app+src |
| Grep fake events ajoutes dans diff | 0 (aucun Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW-/fbq/ttq ajoute) |
| Grep OTP code dans draft useEffect persist obj | 0 (code n est pas dans le draft, devCode non plus) |

## NO PII TRACKING / NO FAKE EVENTS

- Aucun envoi PII (firstName/lastName/phone/email) vers GA4/Meta/TikTok/Ads. trackSignupStep est appele avec uniquement `selectedPlan` (Plan) et `billingCycle` (Cycle).
- PH-19.7 ne modifie aucune logique tracking, juste l etat React.
- Aucun nouvel event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout ajoute.
- Aucun tag AW-XXXXXXXXXX direct.
- data-clarity-mask preserve sur 13 PII inputs.
- Clarity client NON activee.
- Aucune fake review / fake metric / fake chiffre.

## SCOPE PRESERVE / NON-REGRESSION

| Pattern | Source compte | Verdict |
|---|---|---|
| selectedPlan === plan.id (PH-19.4 fix selection plan) | 3 | preserve |
| data-selected / aria-pressed (PH-19.4) | 1 / 1 | preserve |
| invalid_marketing_owner_tenant_id (PH-19.4 retry fallback) | 1 | preserve |
| emitFunnelStep plan_selected (KEY-331 unique) | 1 | preserve |
| data-clarity-mask (KEY-325 PII) | 13 | preserve |
| register-lead-shell / register-reassurance-panel / register-confirm-plan (PH-19.3) | tous | preserve |
| register-autopilot-trial-note (data-testid PH-19.3, contenu PH-19.6 0 EUR) | preserve | OK |
| register-cgu-accepted-note + register-cgu-plan-checkbox (PH-19.6) | preserve | OK |
| Bloc 0 EUR pendant 14 jours (copy F.9 custom PH-19.6) | preserve | OK |
| Microcopy CTA F.9 + variante laterale F.9 | preserve | OK |
| Vieux patterns (tout le monde teste Autopilot / CB requise) | 0 | preserve nettoyage PH-19.6 |

## COMMIT LOCAL CLIENT

| Element | Valeur |
|---|---|
| files staged (1) | `app/register/page.tsx` |
| commit hash | 8553bad |
| commit title | fix(register): persist draft sessionStorage pour retour Stripe et back browser |
| commit body | PH-SAAS-T8.12AS.19.7 KEY-335 follow-up ; bug Ludovic companyName perdu apres retour Stripe -> persist draft 14 champs |
| insertions/deletions | +63 / -14 |
| HEAD local apres | 8553bad |
| origin/ph148 apres | bae77de (INCHANGE, ahead 1) |
| status dirty | tsconfig.tsbuildinfo (preexistant, exclus du commit) |
| push | NON execute (NO push regle absolue de la phase) |

## AUDIT LEAD DRAFT SERVER-SIDE (read-only, recommandation PH-19.8)

### Etat actuel cote API (audit read-only)

| Element | Constat |
|---|---|
| Table `signup_attribution` (existante) | INSERT dans `tenant-context-routes.ts` l.720 apres tenant cree. Stocke attribution_id, utm, click IDs, marketing_owner_tenant_id, ttclid, li_fat_id. Mais : insert UNIQUEMENT a la creation tenant (post-acceptCgu + payment-first). |
| Table `leads` / `lead_drafts` | AUCUNE table dediee aux drafts pre-tenant existante (grep confirmed). |
| Endpoint `POST /api/auth/signup-draft` | AUCUN endpoint dedie aux drafts existant. |
| Endpoint `POST /api/funnel/event` (existant via `funnel/routes.ts` import) | utilise pour emit funnel events (register_started, otp_verified, etc.). Stocke des events mais pas un draft complet (form data). |
| Tenant `pending_payment` status | Existe : tenant cree avec `status='pending_payment'` cote API jusqu a Stripe webhook. Mais cela ne couvre PAS le draft pre-tenant (avant clic "Confirmer ce plan"). |

### Donnees minimales recommandees pour lead draft server-side (PH-19.8)

| Champ | Justification metier | RGPD |
|---|---|---|
| funnel_id | corrolation avec funnel events existants | OK (technical) |
| email | identifier la personne (retargeting / nurturing) | PII - consentement requis |
| selectedPlan + billingCycle | interet produit | OK (non-PII) |
| companyName | identifier l entreprise | semi-PII (B2B contact) |
| siret | identifier legal entity | semi-PII |
| firstName + lastName | identifier la personne | PII - consentement requis |
| phone | retargeting telephonique | PII - consentement requis |
| country | scope geo | OK |
| utm + click IDs + _gl + promo | attribution canal | OK (deja en signup_attribution) |
| status_draft | enum 'started' / 'company_done' / 'user_done' / 'plan_selected' / 'abandoned' / 'completed' | OK |
| created_at / updated_at | tracking duree | OK |
| last_step | dernier step atteint | OK |
| ip_hash / user_agent_hash | analytics anti-fraude | semi-PII |

### Consentement RGPD

- L'utilisateur n'a PAS encore accepte les CGU sur step plan dans le flow PH-19.6 lead-first. La checkbox CGU peut etre absent sur certains steps.
- Stocker un lead draft server-side AVANT acceptation CGU = collecte PII sans consentement explicite = risque RGPD.
- Recommandation : ne persister cote serveur QUE :
  - apres acceptation CGU si checkbox cochee (proxy = `acceptCgu` true cote Client = ajouter flag dans payload draft).
  - OU avec un consentement specifique distinct ("Je souhaite etre recontacte si je n'ai pas termine mon inscription").

### Recommandation PH-19.8 (separe, NON applique ici)

**Phase PH-19.8 a designer** :
- Table `signup_drafts` (nouvelle) : id UUID, funnel_id, email_hash (au lieu d email brut pour consentement non donne), selectedPlan, billingCycle, country, last_step, status_draft, created_at, updated_at, expires_at (TTL 30 jours).
- Endpoint `POST /api/auth/signup-draft` (nouveau) : upsert idempotent par funnel_id, body partiel autorise.
- Endpoint `GET /api/auth/signup-draft?funnel_id=X` (nouveau) : restore draft cote Client si funnel_id retrouve via attribution storage.
- Quand l user accepte CGU explicite => ajouter email/firstName/lastName clair dans le draft (avec consentement explicite + cookie consent banner si non present).
- Job CronJob nightly : flag `abandoned` les drafts > 24h sans update, purge > 30 jours.
- Retargeting nurturing : email J+1 si email present + acceptCgu+1, email J+7 si toujours abandoned. Necessite consent specifique ("recevoir des rappels").
- Linear ticket recommande : KEY-XXX-NEW "Lead draft server-side + retargeting RGPD" (Ludovic doit creer le ticket).

PH-19.7 fait UNIQUEMENT du client-side sessionStorage (zero RGPD risk, scope tab). PH-19.8 ajouterait le server-side avec consentement explicite. Sequence proposee :
1. PH-19.7 (ce patch) : draft sessionStorage Client uniquement. Resout le bug retour Stripe immediatement.
2. PH-19.8 (a designer) : draft server-side avec consentement RGPD + endpoint API + table + jobs.

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

> **KEY-335 (follow-up PH-19.7)** : Source patch local pret. Commit Client `8553bad` ahead 1. Bug Ludovic corrige : retour depuis Stripe ou Back browser sur step plan ne perd plus les champs entreprise/utilisateur/plan/cycle. Persist sessionStorage `kb_signup_form_draft_v1` au write changements + restore au mount via `initialDraft`. 14 champs persistes (email, selectedPlan, billingCycle, companyName, siret, street, zipCode, city, country, companyPhone, supportEmail, firstName, lastName, phone). Non persistes : OTP code, devCode, secrets. acceptCgu deja persiste separement PH-19.6. Cleanup draft NON applique pour permettre retour Stripe. ESLint OK, tsc OK, plan_selected unique, data-clarity-mask 13, Clarity 0/0, no fake events. STOP avant push/build/deploy.

> **KEY-334** : Tunnel lead-first preserve dans le patch PH-19.7. handleConfirmPlanAndCheckout retrouve maintenant tous les champs entreprise/user via state restaure.

> **KEY-329** : Copy CRO post-PH-19.6 preserve. PH-19.7 ne touche aucun copy.

> **KEY-331** : plan_selected preserve unique (1 emit source canonique). Persist draft n a aucune mecanique tracking.

> **KEY-330** : No fake events ajoutes par PH-19.7. AW- direct = 0.

> **KEY-325** : Clarity client toujours non activee. data-clarity-mask 13 PII inputs preserves. sessionStorage `kb_signup_form_draft_v1` reste cote client, scope tab, non envoye a Clarity/GA4/Meta/TikTok.

> **Recommandation PH-19.8** (nouveau ticket KEY-XXX a creer par Ludovic) : Lead draft server-side avec consentement RGPD, endpoint POST/GET signup-draft, table signup_drafts, CronJob nightly flagging abandoned/purge. Audit cote API confirme : signup_attribution existe deja (cree post-tenant), aucune table leads/lead_drafts existante, aucun endpoint /api/auth/signup-draft existant. Implementer apres validation produit + design RGPD (consentement explicite avant persist email/PII server-side).

## GAPS

1. Cleanup draft `kb_signup_form_draft_v1` apres success Stripe : NON applique dans ce patch. sessionStorage est scope par tab, donc expire a la fermeture du tab. Risque faible. A traiter en PH-19.x si Ludovic veut cleanup explicite (par exemple route `/register/success` qui clear sessionStorage).
2. Lead draft server-side : audit read-only realise (section ci-dessus), implementation a traiter en PH-19.8 separe avec design RGPD.
3. tsc 2 erreurs preexistantes sur `.next/types/app/api/debug-env/route.ts` (cache obsolete depuis PH-19.0 f61763a) ; non bloquant.
4. `kb_signup_context` (PH-OAuth flow) reste un mecanisme separe pour plan/cycle uniquement. Le nouveau `kb_signup_form_draft_v1` est plus complet et pourrait remplacer `kb_signup_context` a terme, mais hors scope PH-19.7 pour eviter regression OAuth.
5. Tests QA Ludovic visuels requis : (a) reproduire le bug avant patch sur v3.5.204, (b) confirmer fix apres deploy PH-19.7 (build + push + apply DEV) : remplir company, user, plan, Stripe -> retour Back browser -> step plan affiche -> companyName + firstName + lastName + email restaures + bouton "Confirmer" fonctionne sans erreur.
6. Cookie / sessionStorage consent banner : sessionStorage est techniquement un "essential storage" (necessaire au fonctionnement du flow signup), pas de consent banner requis (RGPD considere essential storage comme legitimate interest pour fournir le service demande par l user).

## ROLLBACK LOCAL

Si necessaire, rollback local strict (NO push, NO destruct) :
- `git -C /opt/keybuzz/keybuzz-client reset --soft HEAD~1` (revient sur bae77de tout en gardant le patch en index)
- ou `git -C /opt/keybuzz/keybuzz-client revert 8553bad` (commit inverse propre)
- INTERDIT : `git reset --hard`, `git clean`, `git push --force`

Aucun runtime touche, aucun rollback runtime necessaire.

## VERDICT FINAL

GO SOURCE PATCH REGISTER STATE PERSISTENCE READY PH-SAAS-T8.12AS.19.7

| Indicateur | Valeur |
|---|---|
| Commit local Client | 8553bad |
| Origin/ph148 | bae77de (INCHANGE, ahead 1) |
| Files modifies | 1 (app/register/page.tsx) |
| Lignes | +63 / -14 |
| Patches 16/16 appliques | OK (SignupDraft type + initialDraft read + 14 useState init + useEffect persist) |
| ESLint | OK 0 warning 0 error |
| tsc | OK (2 erreurs preexistantes hors scope) |
| Champ companyName dans draft restore+persist | OK |
| sessionStorage key | kb_signup_form_draft_v1 |
| Cleanup draft pre-Stripe | NON (permet retour) |
| OTP code dans persist | NON (jamais persiste) |
| acceptCgu | toujours persiste separement (kb_signup_cgu_accepted, PH-19.6) |
| Non-regression PH-19.3+19.4+19.5+19.6 | preservee |
| plan_selected | unique source |
| data-clarity-mask | 13 PII preserves |
| Clarity activation | 0/0 |
| No fake events | OK |
| No PII tracking | OK |
| Runtime DEV/PROD | inchange (no apply) |
| Audit lead draft server-side | read-only realise, recommandation PH-19.8 separe |
| NO BUILD | OK |
| NO DOCKER PUSH | OK |
| NO kubectl | OK |
| NO git push | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.7-REGISTER-STATE-PERSISTENCE-SOURCE-01.md (untracked attendu) |

Prochaine phrase GO attendue :

GO PUSH REGISTER STATE PERSISTENCE SOURCE PH-SAAS-T8.12AS.19.7

STOP.
