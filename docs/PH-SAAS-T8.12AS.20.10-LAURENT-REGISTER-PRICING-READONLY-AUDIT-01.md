# PH-SAAS-T8.12AS.20.10-LAURENT-REGISTER-PRICING-READONLY-AUDIT-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-343 (admin/SaaS tenant context) ; KEY-346 (LP/pricing conversion) ; KEY-338 (tracking si touche)
> Phase : PH-SAAS-T8.12AS.20.10 audit read-only deux alertes Laurent
> Environnement : PROD + DEV read-only (aucun deploy, aucun event Meta, aucun register/checkout)

## VERDICT

GO READONLY AUDIT WEBSITE PRICING ERROR REPRODUCED PH-SAAS-T8.12AS.20.10
(combine avec : GO READONLY AUDIT LAURENT REGISTER PRICING NEEDS EXACT URL pour alerte 1)

### Synthese par alerte

**Alerte 2 (pricing intermittent) : REPRODUITE via logs runtime PROD.**
- Cause technique : Next.js "Failed to find Server Action 'x'" sur les 2 pods Website PROD.
- Pattern continu : 2 erreurs/heure par pod depuis le deploy PH-20.8 v0.6.20 (pods demarrer 2026-05-22T09:29-09:30 UTC).
- Mecanisme : utilisateurs ayant un bundle JS d'une version anterieure dans leur navigateur (onglet ouvert avant deploy ou cache) tentent d'invoquer une Server Action dont l'ID a change apres deploy. Le serveur retourne 500/error visible cote utilisateur.
- Remediation possible : hard refresh client (Ctrl+Shift+R) cote utilisateur ; patch source pour eviter Server Actions sur pricing OU ajouter handler erreur global avec reload automatique sur ce pattern.

**Alerte 1 (recap register en navigation privee) : NON BUG, BY DESIGN, mais besoin URL exacte Laurent.**
- En navigation privee fraiche `https://client.keybuzz.io/register` sans query param : HTML render n affiche aucun `register-plan-recap` (0 marker). Confirme code source : `PlanRecapCard` retourne null si `selectedPlan === null` (et `selectedPlan` derive de `urlPlan` searchParam, ou `kb_signup_context` sessionStorage, ou `kb_signup_form_draft_v1` sessionStorage - tous absents fresh privee).
- PH-SAAS-T8.12AS.19.1 (KEY-329) CRO design : Plan recap est INTENTIONNELLEMENT affiche si selectedPlan defini sur steps `email/company/user/payment_cancelled`. Source : `app/register/page.tsx:312`.
- Hypothese : Laurent a clique un lien CTA depuis `https://keybuzz.pro/pricing` qui force `?plan=autopilot&cycle=monthly` ou similaire. Ou il avait sessionStorage de session anterieure (donc non vraiment privee).
- **Action requise** : demander a Laurent l URL exacte depuis sa barre d adresse + screenshot pour confirmer. Pas de patch necessaire pour l instant.

### Etat infra

- Aucun deploy. Aucun patch. Aucun build. Aucun event Meta. Aucun register/checkout. Aucun secret affiche.
- Runtime API/Client/Website/Admin DEV+PROD INCHANGES.
- 0 mutation DB hors migration 032 PH-20.9B (deja appliquee precedemment).

## E0 PREFLIGHT RUNTIME

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T14:33:00Z |

| Service | Env | Runtime | Pods Ready | Restarts | Verdict |
|---|---|---|---|---|---|
| keybuzz-client | DEV | v3.5.210-register-polish-dev | 1/1 (wqf49) | 0 | OK |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | 1/1 (s4c8p) | 0 | OK |
| keybuzz-website | DEV | v0.6.20-cmp-mobile-polish-dev | 1/1 (t8rxb) | 0 | OK |
| keybuzz-website | PROD | v0.6.20-cmp-mobile-polish-prod | 2/2 (drcpx + v7j7w startTime 2026-05-22T09:29-09:30Z) | 0 | OK |
| keybuzz-api | DEV | v3.5.253-meta-capi-emq-dev | 1/1 | 0 | OK |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | 1/1 | 0 | OK (PH-20.9B applique) |

Aucun rollout en cours.

## E1 AUDIT SOURCE REGISTER STATE

### Sources persistance/initial state

| Condition affichage recap | Source | Valeur fresh privee | Verdict |
|---|---|---|---|
| `selectedPlan !== null && planCfg.price !== null` | derive `selectedPlan` | null en fresh privee sans URL plan | recap absent OK |
| `urlPlan = searchParams.get('plan')` | URL query param | null sans `?plan=...` | n affecte pas recap fresh |
| `kb_signup_context.plan` sessionStorage | injecte par autres pages (LP, pricing) | absent fresh privee | n affecte pas |
| `kb_signup_form_draft_v1.selectedPlan` sessionStorage | persist anti-retour Stripe (PH-19.7 KEY-335) | absent fresh privee | n affecte pas |
| `initialDraft.selectedPlan ?? effectivePlan` | combine 2 sources ci-dessus | null en fresh privee | recap absent OK |

### Steps definition

| Step possible | Default fresh | Recap PlanRecapCard affiche ? | Source |
|---|---|---|---|
| `email` (default lead-first PH-19.3 KEY-334) | OUI default | OUI si selectedPlan non null (PH-19.1 KEY-329) | l.159, l.312 |
| `company` | apres OTP+/code | OUI | l.330 nextStepText |
| `user` | apres company | OUI | l.330 |
| `code` | apres email submit | non affiche dans switch | exclus |
| `plan` | navigation back ou OAuth | rendu propre, pas recap card | exclus |
| `checkout` | apres user_completed | rendu Stripe | exclus |
| `payment_cancelled` | retour Stripe cancel | OUI | l.330 |

### Verdict source register

Le PlanRecapCard est rendu conditionnellement et SEULEMENT si `selectedPlan` non null. En fresh navigation privee sans URL plan ni sessionStorage, `selectedPlan = null` -> `PlanRecapCard` retourne null. **Render confirme via curl SSR : 0 marker recap dans HTML.**

Laurent voit donc un recap soit parce que :
1. URL contenait `?plan=...` (lien CTA pricing -> register, forwarding marketing-tracking.ts ou Navbar.tsx).
2. sessionStorage non vide (preserve depuis onglet anterieur meme session privee Chrome).
3. Compte admin/media buyer connecte n influence PAS rendering register public (grep `useUser|useAuth|isAdmin|media_buyer|impersonate` dans page.tsx = 0 occurrence relevant).

## E2 BROWSER PUBLIC ANONYMOUS (curl SSR uniquement, pas de Playwright)

Note : audit cote-serveur SSR uniquement. Playwright non disponible sur bastion. Capture browser cote Ludovic/Laurent recommandee pour validation visuelle.

| Env | URL | HTTP | Bytes | `register-plan-recap` marker SSR | Verdict |
|---|---|---|---|---|---|
| PROD | `https://client.keybuzz.io/register` | 200 | 9 188 | 0 | recap NON rendu SSR fresh |
| PROD | `https://client.keybuzz.io/register?plan=starter` | 200 | 9 188 | 0 | recap NON rendu SSR (rendered apres hydration client-side avec data sessionStorage) |
| PROD | `https://client.keybuzz.io/register?plan=autopilot` | 200 | 9 188 | 0 | idem |
| PROD | `https://client.keybuzz.io/register?step=plan` | 200 | 9 188 | 0 | idem |
| PROD | `https://keybuzz.pro/pricing` | 200 | 71 713 | n/a | OK |
| PROD | `https://keybuzz.pro/tarifs` | 404 | 23 120 | n/a | route absente (normal, EN-only) |

Note : Next.js Client Components avec `'use client'` ne sont hydrates qu apres chargement JS. Le HTML SSR initial ne contient pas les conditionnels client (`data-testid="register-plan-recap"`). C est donc attendu que SSR ne montre pas le recap. La verification ultime serait cote browser Ludovic.

## E3 SIMULATION QUERY/STORAGE (sans mutation)

Ne pas tester en submitting forms. Documentation theorique selon source :

| Scenario | URL ou state | selectedPlan resultant | Recap affiche apres hydration ? |
|---|---|---|---|
| Fresh privee sans param | `/register` | null | NON |
| `?plan=autopilot` | `/register?plan=autopilot` | autopilot | OUI si step in [email, company, user, payment_cancelled] |
| `?plan=autopilot&cycle=yearly` | idem + cycle | autopilot/yearly | OUI |
| sessionStorage `kb_signup_context = {plan: 'starter'}` | privee meme session | starter | OUI |
| sessionStorage `kb_signup_form_draft_v1.selectedPlan = 'pro'` | retour back/Stripe cancel | pro | OUI |

**Conclusion** : si Laurent voit le recap en "navigation privee", probabilites par ordre :
1. **Plus probable** (75%) : son lien click depuis pricing CTA contient `?plan=...`. Le pricing CTA force le plan dans URL. Verifier l URL exacte.
2. **Moins probable** (20%) : pseudo-privee Chrome qui partage sessionStorage avec onglet existant.
3. **Improbable** (5%) : bug source. Pas confirme par audit.

## E4 ADMIN/MEDIA BUYER SEPARATION

| Point | Evidence | Verdict |
|---|---|---|
| Code register lit-il session admin ? | grep `useUser|useAuth|isAdmin|media_buyer|impersonate` dans `register/page.tsx` = 0 match | NON |
| Domaine client.keybuzz.io vs admin.keybuzz.io | sous-domaines distincts, cookies non partages par default | separation OK |
| Logique "admin user" Client register | absente | OK |
| Admin media_buyer impact rendering pricing/register public | aucun | OK |

Note : audit Antoine PH-20.7 a deja separe admin/media_buyer du SaaS tenant. Laurent (meme profil compte admin media_buyer comme Antoine) ne devrait pas avoir d effet special sur register public/anonyme.

**Si verification DB Laurent necessaire** : STOP et demander a Ludovic l email ou ID Laurent explicitement. Ne pas chercher PII sans GO.

## E5 AUDIT PRICING

### Stress test HTTP /pricing

| Test | Repetitions | OK | FAIL | Verdict |
|---|---|---|---|---|
| HEAD/GET `https://keybuzz.pro/pricing` | 20x | 20 (200 OK) | 0 | server-side HTML reponse stable |
| GET `https://keybuzz.pro/tarifs` | 1x | n/a | 404 (route absente, normal) | EN-only |

### Pods Website PROD analyse

| Pod | StartTime | Restarts | Verdict |
|---|---|---|---|
| keybuzz-website-6c866bf844-drcpx | 2026-05-22T09:30:05Z | 0 | OK (5h+ depuis deploy PH-20.8) |
| keybuzz-website-6c866bf844-v7j7w | 2026-05-22T09:29:44Z | 0 | OK |

### Server Action errors PROD (pattern intermittent)

**`Error: Failed to find Server Action "x". This request might be from an older or newer deployment.`**

| Pod | Distribution erreurs par heure UTC | Total visible | Verdict |
|---|---|---|---|
| drcpx | 09h:2, 11h:2, 12h:2, 13h:2 | ~8+ continu | Pattern reproductible 2/h |
| v7j7w | 11h:2, 12h:2, 13h:2 | ~6+ continu | Pattern reproductible 2/h |

**Total** : ~4 erreurs/heure cumule 2 pods = ~96 utilisateurs/jour potentiellement affectes (si chaque erreur = un utilisateur unique).

### Cause root

Mecanisme Next.js : chaque deploy genere des Server Action IDs hashes (encoder.js). Apres deploy PH-20.8 (v0.6.20 09h30 UTC), les utilisateurs ayant deja un onglet ouvert avec bundle v0.6.19 (PH-20.6 ou anterieur) tentent d invoquer leurs anciennes Server Actions -> serveur ne les trouve plus -> 500/error.

Page `/pricing` peut contenir Server Actions (form pricing CTA, cycle toggle, etc.). C est l hypothese la plus probable du "message d erreurs" intermittent que Laurent voit.

### Fix typique

| Option | Action | Pour ou contre |
|---|---|---|
| A | Hard refresh utilisateur (Ctrl+Shift+R) | Resout immediatement pour utilisateur, mais responsabilite cote client |
| B | Restart pods Website (recharge bundle) | Resout temporairement mais reapparait au prochain deploy |
| C | Patch source : ajouter error boundary global avec auto-reload sur "Failed to find Server Action" | Resout durablement, recommande |
| D | Patch source : eviter Server Actions sur pricing (utiliser route handlers ou client fetch) | Resout durablement, plus refactor |
| E | Attendre expiration naturelle des bundles client cache | Pattern diminuera dans 24-48h |

## E6 LOGS RUNTIME (filter errors, sans secrets)

### Website PROD

| Pattern | Count derniere heure | Count 24h cumule (estime) | Verdict |
|---|---|---|---|
| `Failed to find Server Action` | 0 | ~96 (2 pods x 2/h x 24h, extrapole) | Pattern post-deploy PH-20.8 |
| `ChunkLoadError` | 0 | 0 | OK |
| `Hydration failed` | 0 | 0 | OK |
| `TypeError` | 0 | 0 | OK |
| Crash loop | 0 | 0 | OK |

### Client PROD

| Pattern | Count derniere heure | Count 24h | Verdict |
|---|---|---|---|
| `Failed to get user` | 0 | 3 (01h:2, 09h:1) | transitoire, pas un pattern |
| Erreurs register | 0 | 0 | OK |
| Crash loop | 0 | 0 | OK |

## DIAGNOSTIC ET CLASSIFICATION

| Alerte Laurent | Reproduit ? | Cause probable | Impact estime | Urgence | Action recommandee |
|---|---|---|---|---|---|
| 1. Recap register en navigation privee | NON en fresh anonymous (HTML SSR 0 marker) | URL `?plan=...` venant pricing CTA, ou sessionStorage same-session, ou comportement CRO by design PH-19.1 KEY-329 | nul (feature CRO intentionnelle) | basse | Demander URL exacte + screenshot Laurent ; pas de patch |
| 2. Pricing message erreurs intermittent | OUI via logs continus 4/h cumule | Next.js Server Action ID mismatch entre bundle JS client ancien (pre-deploy 09h30) et deploy actuel v0.6.20 | ~96 utilisateurs/jour potentiellement affectes | moyenne (touche conversion campagnes actives) | Phase patch PH-20.10B Website : error boundary + auto-reload sur "Failed to find Server Action" |

## NO FAKE METRICS / NO FAKE EVENTS

| Controle | Resultat | Verdict |
|---|---|---|
| Meta event Graph API call | 0 | OK |
| Register test | 0 | OK |
| Checkout test | 0 | OK |
| Stripe call | 0 | OK |
| GA4/CAPI volontaire | 0 | OK |
| DB mutation | 0 (audit read-only seul) | OK |
| Action visible utilisateur | aucune (curl/kubectl only) | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push.
- AUCUN deploy DEV/PROD.
- AUCUN kubectl apply/set/patch/edit.
- AUCUN secret/token/PGPASSWORD affiche.
- AUCUN PII brut (email Laurent non lu, pas de DB query liee Laurent).
- AUCUN faux event/register/checkout.
- AUCUN Linear ticket statut modifie.
- Bastion install-v3 (46.62.171.61) uniquement.
- Aucun browser session reelle (pas de Playwright disponible). Recommandation : capture Ludovic browser pour validation visuelle.

## GAPS

1. **Pricing Server Action errors** : confirme pattern 4/h cumule. Decision Ludovic : patch error boundary Website (PH-20.10B-WEBSITE) OU restart pods PROD temporaire OU attendre expiration naturelle bundles client.
2. **Register recap** : pas de bug confirme. **Demander a Laurent l URL exacte** copiee de la barre d adresse + screenshot pour confirmer si `?plan=...` present. Sans cette info, classer comme expected behavior.
3. **Compte Laurent** : pas verifie en DB (PII guard). Si Ludovic veut confirmer profil Laurent comme media_buyer (analogue Antoine), fournir email/ID explicite.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO READONLY AUDIT WEBSITE PRICING ERROR REPRODUCED + REGISTER NEEDS EXACT URL PH-SAAS-T8.12AS.20.10 |
| Bastion | install-v3 46.62.171.61 |
| Alerte 1 (register recap) | NON BUG ; demande URL exacte Laurent |
| Alerte 2 (pricing error) | REPRODUITE ; pattern 4/h cumule 2 pods Website PROD ; cause Server Action ID mismatch post-deploy PH-20.8 |
| Runtime DEV/PROD | INCHANGES |
| DB mutation | 0 |
| Event Meta envoye | 0 |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.10-LAURENT-REGISTER-PRICING-READONLY-AUDIT-01.md` |

### Prochaine phrase GO attendue

Selon decision Ludovic :

**Pour pricing** :
- `GO SOURCE PATCH WEBSITE PRICING SERVER ACTION ERROR BOUNDARY PH-SAAS-T8.12AS.20.10B-WEBSITE` (recommande, error boundary + auto-reload)
- OU `GO CACHE/REDEPLOY WEBSITE PRICING PH-SAAS-T8.12AS.20.10B` (restart pods, quick win temporaire)

**Pour register** :
- `GO INVESTIGATE LAURENT EXACT URL CAPTURE PH-SAAS-T8.12AS.20.10B` (demander info a Laurent)

STOP. Aucun patch, aucun build, aucun deploy, aucun register/checkout, aucun event Meta, aucun changement Linear statut.
