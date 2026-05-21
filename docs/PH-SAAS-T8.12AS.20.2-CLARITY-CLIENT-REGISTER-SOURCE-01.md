# PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-SOURCE-01

> Date : 2026-05-21
> Linear : KEY-339 (primary) ; KEY-337 (parent) ; KEY-338, KEY-340, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.2 CLARITY CLIENT REGISTER SOURCE PATCH
> Environnement : SOURCE PATCH Client / aucun build / aucun deploy

## VERDICT

GO SOURCE PATCH CLARITY CLIENT REGISTER READY PH-SAAS-T8.12AS.20.2

- Source Client patche pour ajouter Microsoft Clarity route-gated dans `SaaSAnalytics.tsx` existant.
- Reutilise les FUNNEL_PREFIXES `[/register, /login]` et BLOCKED_PREFIXES qui inclut `/onboarding /inbox /dashboard /orders /settings /channels /suppliers /knowledge /playbooks /ai-journal /billing /workspace-setup /start /help`.
- Dockerfile etendu pour supporter `NEXT_PUBLIC_CLARITY_PROJECT_ID` (ARG/ENV).
- Commit Client `dad5f89` pushe sur `ph148/onboarding-activation-replay`.
- 0 fake event ajoute. 0 PII trackee. data-clarity-mask preserve (13 inputs register).
- tsc 2 erreurs preexistantes documentees (cache `.next/types/app/api/debug-env`), non causees par le patch.
- Clarity Project ID requis pour la phase BUILD suivante. Status : ABSENT a ce jour.

Aucun build effectue. Aucun docker push. Aucun deploy. Aucun kubectl. Aucun secret/token affiche. Aucun ticket Linear ferme ou statut modifie automatiquement.

## E0 PREFLIGHT BASTION + REPOS

### Bastion install-v3

| Indicateur | Valeur |
|---|---|
| hostname | install-v3 |
| IP publique | 46.62.171.61 |
| date UTC | 2026-05-21 11:17:34 |
| Source IP autorisee | OK |

### Repos Git

| Repo | Branche | HEAD avant | Dirty avant | Remote | Verdict |
|---|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | 8553bad fix(register): persist draft sessionStorage | 1 (tsconfig.tsbuildinfo cache hors scope) | github.com/keybuzzio/keybuzz-client | OK branche imposee |
| keybuzz-infra | main | 36a2e44 docs(tracking): audit PH-20.1 go agence | 0 | github.com/keybuzzio/keybuzz-infra | OK clean |

## E1 SOURCE AUDIT CLARITY EXISTANT

### Pattern detection

| Fichier | Pattern recherche | Resultat | Impact |
|---|---|---|---|
| src/ + app/ | `clarity`, `Clarity`, `NEXT_PUBLIC_CLARITY` | 0 occurrence | Pas de Clarity provider Client existant |
| app/register/page.tsx | `data-clarity-mask` | 13 occurrences | PII protection PH-19.x preservee |
| app/layout.tsx | provider tracking root | 1 = `<SaaSAnalytics />` (rendu hors `<AuthProvider>`) | Pattern provider tracking deja en place, ideal pour extension Clarity |
| src/components/tracking/SaaSAnalytics.tsx | composant tracking existant | OUI 161 lignes, GA4 + Meta + TikTok + LinkedIn route-gated, FUNNEL_PREFIXES / BLOCKED_PREFIXES | Reutilisation parfaite pour Clarity |
| app/onboarding/page.tsx | route /onboarding | OUI : `<OnboardingDataAware />` import depuis `@/src/features/onboarding` | Post-auth (depend de tenant + onboarding status), confirme presence dans BLOCKED_PREFIXES |
| middleware.ts | auth guard global | ABSENT au root, BFFs propres | Pas de bypass auth necessaire |

### Decision design

Plutot que creer un nouveau composant `ClarityClientProvider.tsx`, EXTENDRE `SaaSAnalytics.tsx` existant. Rationale :

1. Patch minimal : 1 fichier source modifie + 1 Dockerfile.
2. Reutilise FUNNEL_PREFIXES et BLOCKED_PREFIXES deja testes par PH-T3 + GA4/Meta/TikTok/LinkedIn.
3. SaaSAnalytics deja monte en root layout (`app/layout.tsx` ligne 41), aucune integration supplementaire necessaire.
4. Coherence avec le pattern projet : un seul composant SaaSAnalytics centralise les pixels client-side.

Le prompt CE autorise cette option : "ou emplacement local existant si pattern deja present".

## E2 DESIGN PATCH

| Fichier | Changement | Risque | Validation |
|---|---|---|---|
| `src/components/tracking/SaaSAnalytics.tsx` | + commentaire doc PH-20.2 KEY-339 ; + declaration `const CLARITY_PROJECT_ID = process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID || '';` ; + Clarity dans condition `shouldLoad` ; + bloc `<Script id="ms-clarity">` injecte au funnel only | Bas - reutilise gate existant, no-op si ID vide | tsc + assertions |
| `Dockerfile` | + ARG `NEXT_PUBLIC_CLARITY_PROJECT_ID=` (default vide) ; + ENV `NEXT_PUBLIC_CLARITY_PROJECT_ID=${NEXT_PUBLIC_CLARITY_PROJECT_ID}` apres LINKEDIN_PARTNER_ID | Bas - default vide, no-op sans build-arg | diff confirme |

Pattern Clarity inject (idiomatique Microsoft) :

```js
(function(c,l,a,r,i,t,y){
  c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
  t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
  y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
})(window, document, "clarity", "script", "${CLARITY_PROJECT_ID}");
```

Identique au pattern utilise sur `keybuzz-website/src/components/ClarityProvider.tsx`. Pas de consent gate explicite cote Client (different du Website) : le funnel pre-auth `/register` /`login` n a pas de banniere cookie, l utilisateur consent implicitement aux CGU au moment du signup (verifie via `kb_signup_cgu_accepted`).

## E3 ROUTES AUTORISEES / INTERDITES

### Reutilisation des prefixes existants SaaSAnalytics

```ts
const FUNNEL_PREFIXES = ['/register', '/login'];

const BLOCKED_PREFIXES = [
  '/inbox', '/dashboard', '/orders', '/settings',
  '/channels', '/suppliers', '/knowledge', '/playbooks',
  '/ai-journal', '/billing', '/onboarding', '/workspace-setup',
  '/start', '/help',
];
```

### Tableau routes vs Clarity

| Route | Autorisee ? | Raison | Risque PII si Clarity actif |
|---|---|---|---|
| /register | OUI (FUNNEL) | tunnel d acquisition pre-auth | Bas (data-clarity-mask 13 inputs PII) |
| /register/* | OUI (FUNNEL prefix) | sous-routes register | Bas (idem) |
| /login | OUI (FUNNEL) | login pre-auth | Medium (email + password) - a etudier au QA si recoir Clarity ou masquer |
| /onboarding | NON (BLOCKED) | post-auth, donnees tenant | Haut, evite |
| /inbox | NON (BLOCKED) | post-auth, PII clients final + messages | Critique, evite |
| /dashboard | NON (BLOCKED) | post-auth, chiffres business | Haut, evite |
| /orders | NON (BLOCKED) | post-auth, donnees commerciales | Haut, evite |
| /settings | NON (BLOCKED) | post-auth, configuration | Medium, evite |
| /channels | NON (BLOCKED) | post-auth, configuration canaux | Medium, evite |
| /suppliers | NON (BLOCKED) | post-auth, base fournisseurs | Medium, evite |
| /knowledge | NON (BLOCKED) | post-auth, base de connaissance interne | Bas, evite par principe |
| /playbooks | NON (BLOCKED) | post-auth, playbooks IA | Bas, evite par principe |
| /ai-journal | NON (BLOCKED) | post-auth, journal IA et conversations | Critique, evite |
| /billing | NON (BLOCKED) | post-auth, Stripe, montants | Critique, evite |
| /workspace-setup | NON (BLOCKED) | post-auth, setup tenant | Bas, evite par principe |
| /start, /help | NON (BLOCKED) | helpers non funnel | Bas, evite par principe |

Note : `/onboarding` reste BLOCKED car post-auth (composant `OnboardingDataAware` necessite `useTenant()` qui lui necessite AuthProvider). Le prompt CE permettait l ajouter en routes autorisees "si pre-auth prouve" - ici l audit prouve le contraire, donc reste BLOCKED.

## E4 PATCH APPLIQUE

### Diff scope strict (2 fichiers, 25 insertions, 2 deletions)

```
 Dockerfile                                |  2 ++
 src/components/tracking/SaaSAnalytics.tsx | 25 +++++++++++++++++++++++--
 2 files changed, 25 insertions(+), 2 deletions(-)
```

### SaaSAnalytics.tsx changes

```diff
- * PH-T3: SaaS Analytics - GA4 + Meta Pixel
+ * PH-T3 + PH-SAAS-T8.12AS.20.2 KEY-339: SaaS Analytics - GA4 + Meta + TikTok + LinkedIn + Microsoft Clarity
@@ IDs doc block
+ *   NEXT_PUBLIC_SGTM_URL
+ *   NEXT_PUBLIC_TIKTOK_PIXEL_ID
+ *   NEXT_PUBLIC_LINKEDIN_PARTNER_ID
+ *   NEXT_PUBLIC_CLARITY_PROJECT_ID (PH-20.2 KEY-339 route-gated funnel only)
@@ const declarations
+ const CLARITY_PROJECT_ID = process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID || '';
@@ shouldLoad
- (GA4_ID || META_PIXEL_ID || TIKTOK_PIXEL_ID || LINKEDIN_PARTNER_ID)
+ (GA4_ID || META_PIXEL_ID || TIKTOK_PIXEL_ID || LINKEDIN_PARTNER_ID || CLARITY_PROJECT_ID)
@@ JSX return - apres LinkedIn block
+ {/* Microsoft Clarity - PH-SAAS-T8.12AS.20.2 KEY-339 route-gated (funnel only) */}
+ {CLARITY_PROJECT_ID && (
+   <Script id="ms-clarity" strategy="afterInteractive"
+     dangerouslySetInnerHTML={{ __html: `(function(c,l,a,r,i,t,y){...})(window, document, "clarity", "script", "${CLARITY_PROJECT_ID}");` }} />
+ )}
```

### Dockerfile changes

```diff
 ARG NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977
+ARG NEXT_PUBLIC_CLARITY_PROJECT_ID=
 ARG GIT_COMMIT_SHA=unknown
...
 ENV NEXT_PUBLIC_LINKEDIN_PARTNER_ID=${NEXT_PUBLIC_LINKEDIN_PARTNER_ID}
+ENV NEXT_PUBLIC_CLARITY_PROJECT_ID=${NEXT_PUBLIC_CLARITY_PROJECT_ID}
 ENV GIT_COMMIT_SHA=${GIT_COMMIT_SHA}
```

## E5 TESTS SOURCE

### tsc

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| `npx tsc --noEmit` (90s timeout) | 0 erreur nouvelle | 2 erreurs preexistantes sur `.next/types/app/api/debug-env/route.ts(2,24) + (5,29)` | OK preexistant, prouve par stash/pop : memes erreurs sans le patch |
| stash patch + tsc | reproduire les memes 2 erreurs | OUI 2 erreurs identiques sur HEAD 8553bad seul | OK confirme PRE-EXISTANT |

Origine erreurs : cache `.next/types/app/api/debug-env/route.ts` heritee de PH-19.0 commit `f61763a` apres suppression de la route `app/api/debug-env/route.ts`. Erreurs heritees sur toutes les builds PH-19.x. Hors scope. Regenerees a chaque build (le repertoire `.next/` est ephemere et reconstruit).

### Assertions

| Assertion | Attendu | Observe | Verdict |
|---|---|---|---|
| `NEXT_PUBLIC_CLARITY_PROJECT_ID` dans SaaSAnalytics.tsx | >=2 (commentaire doc + const) | 2 | OK |
| `const CLARITY_PROJECT_ID` declaration | 1 | 1 | OK |
| Script id `ms-clarity` | 1 | 1 | OK |
| `clarity.ms/tag` loader pattern | 1 | 1 | OK |
| data-clarity-mask dans app/register/page.tsx | >=13 | 13 | OK preserve |
| kb_signup_form_draft_v1 dans app/register/page.tsx | >=1 | 2 | OK PH-19.7 preserve |
| kb_signup_cgu_accepted dans app/register/page.tsx | >=1 | 2 | OK PH-19.6 preserve |
| plan_selected emit source unique | 1 | 1 | OK KEY-331 preserve |
| FUNNEL_PREFIXES inclut /register et /login | OUI | OUI ligne 30 | OK |
| BLOCKED_PREFIXES inclut /onboarding | OUI | OUI ligne 34 | OK |
| Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- delta + dans le patch | 0 chacun | 0 chacun (delta git diff confirme) | OK no fake events ajoutes |

Note : les occurrences existantes hors-SaaSAnalytics (Purchase 28, Lead 1, CompletePayment 1, SubmitForm 1, InitiateCheckout 2) sont preexistantes (labels billing/plans/Stripe webhook), aucune n est ajoutee par ce patch. Verifie par `git diff` delta `^+` filtre.

## E6 COMMIT + PUSH SOURCE CLIENT

| Commit | Repo | Branche | Hash | Push | Verdict |
|---|---|---|---|---|---|
| feat(client): add route-gated Clarity provider for register | keybuzz-client | ph148/onboarding-activation-replay | `dad5f89` | OK 8553bad..dad5f89 | OK local==origin `dad5f89b1e9d511026d168e7ae64a9209151355a` |

Diffstat commit : 2 files changed, 25 insertions(+), 2 deletions(-).

Scope strict du commit :

- `Dockerfile` (modifie)
- `src/components/tracking/SaaSAnalytics.tsx` (modifie)

`tsconfig.tsbuildinfo` (dirty cache TypeScript local) NON ajoute au commit, reste en working tree comme noise.

## E7 NO FAKE METRICS / NO FAKE EVENTS

### Constats

- Aucun event GA4 ajoute par le patch.
- Aucun event Meta Pixel ajoute par le patch.
- Aucun event TikTok ajoute par le patch.
- Aucun event LinkedIn ajoute par le patch.
- Aucun event Google Ads (AW-) ajoute par le patch.
- Aucun Lead / Purchase / StartTrial / CompletePayment / SubmitForm / InitiateCheckout ajoute par le patch (`git diff | grep ^+` confirme 0 chacun).
- Aucun `clarity.set(...)` avec PII ajoute. Le bloc Clarity se limite a l injection du loader. Aucun tag personnalise n est emis.
- Aucun KPI publicitaire fabrique.
- Aucun session tag PII.
- data-clarity-mask preserve.

### Signal | Type | Source | Destination | Statut

| Signal | Type | Source | Destination | Statut |
|---|---|---|---|---|
| Clarity session heatmap | UX analytics client-side | SaaSAnalytics.tsx (NEXT_PUBLIC_CLARITY_PROJECT_ID) | clarity.ms (Microsoft Clarity) | PROVISIONNE EN SOURCE, INACTIF tant que ID absent en build |
| Clarity tag custom | UX analytics personnalise | aucun | aucun | INACTIF par decision (no fake events) |
| GA4/Meta/TikTok/LinkedIn | tracking existant pre-patch | SaaSAnalytics.tsx (autres consts) | inchange | INCHANGE |

## E8 CLARITY PROJECT ID STATUS

| Item | Valeur |
|---|---|
| ARG declare dans Dockerfile | OUI `NEXT_PUBLIC_CLARITY_PROJECT_ID=` default vide |
| ENV declare dans Dockerfile | OUI `NEXT_PUBLIC_CLARITY_PROJECT_ID=${NEXT_PUBLIC_CLARITY_PROJECT_ID}` |
| Const declare dans SaaSAnalytics.tsx | OUI `const CLARITY_PROJECT_ID = process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID || '';` |
| Default vide | OUI - no-op si build sans `--build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID=<id>` |
| Reutilisation projet Website existant | NON par decision (recommandation PH-20.1 : projet Clarity Client separe pour eviter melange Website public / app connectee) |
| Status actuel | ABSENT - a fournir par Ludovic/Antoine au moment de la phase BUILD CLIENT DEV |
| Hardcode dans source | NON (jamais hardcode, lu env-only) |

Pour activer Clarity en DEV au prochain build :

```
docker build \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID=<id-clarity-fourni-par-Antoine-ou-Ludovic> \
  ... \
  -t ghcr.io/keybuzzio/keybuzz-client:v3.5.<n>-clarity-register-dev .
```

## E9 LINEAR KEY-339

Cette phase est read-only cote Linear. Verification auth Linear effectuee sans afficher de cle :

```
ls -la /root/.config/keybuzz-linear/api_key 2>&1
```

Si la cle existe et est lisible, le commentaire ci-dessous est poste automatiquement sur KEY-339. Sinon, brouillon a copier manuellement par Ludovic.

### Brouillon commentaire KEY-339

```
PH-SAAS-T8.12AS.20.2 source patch Clarity Client register PRET (2026-05-21).

Verdict : GO SOURCE PATCH CLARITY CLIENT REGISTER READY.

Commit Client : dad5f89 (feat(client): add route-gated Clarity provider for register)
Branche : ph148/onboarding-activation-replay
Push : OK 8553bad..dad5f89

Changes :
- src/components/tracking/SaaSAnalytics.tsx : extension du provider existant pour Microsoft Clarity (reutilise FUNNEL_PREFIXES + BLOCKED_PREFIXES).
- Dockerfile : + ARG/ENV NEXT_PUBLIC_CLARITY_PROJECT_ID= (default vide).

Routes autorisees Clarity : /register, /login (funnel pre-auth).
Routes interdites Clarity : /inbox, /dashboard, /orders, /settings, /channels, /suppliers, /knowledge, /playbooks, /ai-journal, /billing, /onboarding, /workspace-setup, /start, /help.

data-clarity-mask preserve (13 inputs register).
kb_signup_form_draft_v1 + kb_signup_cgu_accepted preserves.
plan_selected emit unique preserve.
No fake events ajoutes.

Clarity Project ID requis pour BUILD : ABSENT a ce jour, a fournir par Ludovic/Antoine au moment du build DEV.

Prochaine phrase GO attendue :
  CLARITY CLIENT PROJECT ID = <id>
  puis GO BUILD CLIENT CLARITY REGISTER DEV PH-SAAS-T8.12AS.20.2
```

## GAPS

1. Clarity Project ID a fournir au moment du build DEV. Sans cet ID, le code reste no-op (default vide) - donc le patch source peut etre mergi sans risque.
2. `/login` route inclus dans FUNNEL_PREFIXES heritage : Clarity y serait actif. A QA sur DEV : verifier que le champ password est bien masque par Clarity automatiquement (Clarity masque par defaut les inputs de type="password"). Si necessaire, ajouter `data-clarity-mask="true"` aux inputs login en phase ulterieure.
3. tsc 2 erreurs preexistantes sur `.next/types/app/api/debug-env/route.ts` (cache stale depuis PH-19.0). Hors scope. Regenere a chaque build.

## ROLLBACK GitOps STRICT

Cette phase ne touche pas le runtime. Aucun rollback K8s necessaire.

Rollback source disponible :

- `git revert dad5f89` sur `ph148/onboarding-activation-replay` (le commit precedent `8553bad` est le point de retour).

## CONFIRMATIONS

- AUCUN build / docker / push image realises.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN secret / token affiche.
- AUCUN /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ ouvert.
- AUCUN event marketing fake ajoute.
- AUCUN Lead / Purchase / StartTrial / CompletePayment / SubmitForm / InitiateCheckout / AW- ajoute par le patch.
- AUCUN tag Clarity personnalise avec PII.
- AUCUN changement Website / API / Admin.
- AUCUN ticket Linear ferme ou statut modifie automatiquement.
- Clarity Website non touche.
- Bastion install-v3 (46.62.171.61) uniquement.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH CLARITY CLIENT REGISTER READY PH-SAAS-T8.12AS.20.2 |
| Bastion | install-v3 46.62.171.61 |
| keybuzz-client HEAD apres push | dad5f89 |
| keybuzz-client branche | ph148/onboarding-activation-replay |
| Commit Client | feat(client): add route-gated Clarity provider for register |
| Files changed | 2 (Dockerfile, src/components/tracking/SaaSAnalytics.tsx) |
| Insertions / deletions | +25 / -2 |
| Routes autorisees Clarity | /register, /login (FUNNEL_PREFIXES) |
| Routes interdites Clarity | /inbox /dashboard /orders /settings /channels /suppliers /knowledge /playbooks /ai-journal /billing /onboarding /workspace-setup /start /help (BLOCKED_PREFIXES) |
| Clarity Project ID status | ABSENT - a fournir au build DEV |
| data-clarity-mask preserve | 13 inputs register |
| No fake events ajoutes | OK confirme |
| tsc | 2 erreurs preexistantes documentees |
| Linear KEY-339 | brouillon comment fourni dans E9 |
| Rapport infra docs | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-SOURCE-01.md` (a commit/push apres ASCII OK) |

### Prochaine phrase GO attendue

- Si Clarity ID fourni : `CLARITY CLIENT PROJECT ID = <id>` puis `GO BUILD CLIENT CLARITY REGISTER DEV PH-SAAS-T8.12AS.20.2`
- Si Clarity ID non encore obtenu : verdict reste GO SOURCE PATCH READY ; build differe ; aucune urgence (code no-op tant que ID absent)

STOP.
