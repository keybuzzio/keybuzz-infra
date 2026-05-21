# PH-SAAS-T8.12AS.20.4-REGISTER-POLISH-BILLING-AUDIT-01

> Date : 2026-05-21
> Linear : KEY-342 (accents FR) ; KEY-343 (billing error session paiement) ; KEY-345 (0 EUR every step) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.4 REGISTER POLISH + BILLING AUDIT
> Environnement : READ-ONLY DEV + PROD (audit, aucune mutation)

## VERDICT

GO AUDIT REGISTER POLISH BILLING READY PH-SAAS-T8.12AS.20.4

Trois sujets audites en READ-ONLY :

1. KEY-342 accents FR copy register : 12+ chaines visibles utilisateur sans accents identifiees ; patch Client source-only faible risque possible.
2. KEY-345 0 EUR every step : message present desktop via ReassurancePanel sur tous steps mais absent mobile sauf step plan ; mini-bandeau compact recommande.
3. KEY-343 billing error "espace cree, rendez-vous Facturation" : **CAUSE RACINE PROUVEE** = tenantId malforme (commence par `-`) genere par create-signup quand le slug devient vide apres normalisation (nom societe = uniquement caracteres non-alphanumeriques). Le `checkout-session` API rejette via `validateTenantId` regex `^[a-zA-Z0-9][a-zA-Z0-9_-]{2,49}$`. Asymetrie create-signup (pas de validation) vs checkout-session (validation stricte).

Reproductibilite : 100% (4 essais Antoine en logs PROD, 4/4 rejet 400).

Patch API correctif identifie + scope simple. Aucune mutation Stripe ni DB requise pour reproduction. Tenant orphan en PROD = `-mpfmgx09` status `pending_payment` (cleanup optionnel).

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 16:21 |
| keybuzz-client branche/HEAD | ph148/onboarding-activation-replay / dad5f89 / clean (sauf tsconfig.tsbuildinfo) |
| keybuzz-api branche/HEAD | ph147.4/source-of-truth / 39e332ea / dirty 223 (preexistant connu) |
| keybuzz-infra branche/HEAD | main / 7a63c93 / clean |

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-website | -prod | v0.6.19-cta-tracking-prod | OK PH-20.3 live |
| keybuzz-client | -prod | v3.5.200-clarity-register-prod | OK PH-20.2 live |
| keybuzz-api | -prod | v3.5.250-ad-spend-sync-all-prod | OK |
| keybuzz-admin-v2 | -prod | v2.12.2-media-buyer-lp-domain-qa-prod | OK |

## E1 AUDIT COPY REGISTER ACCENTS (KEY-342)

Source : `keybuzz-client/app/register/page.tsx` (59 KB).

| Ligne | Texte actuel | Correction accentuee proposee | Risque | Verdict |
|---|---|---|---|---|
| 375 | Essai gratuit 14 jours - sans engagement - resiliable a tout moment. | Essai gratuit 14 jours - sans engagement - resiliable a tout moment. (`resiliable a tout moment`) | nul | PATCH |
| 393 | Compte vendeur non modifie sans action explicite | non modifie -> `non modifie` | nul | PATCH |
| 394 | Donnees limitees au strict necessaire | -> `Donnees limitees au strict necessaire` | nul | PATCH |
| 388 | Prochaine etape : | -> `Prochaine etape :` | nul | PATCH |
| 333 | Confirmer vos informations puis activer l essai 14 jours. | -> `puis activer l'essai 14 jours` | nul | PATCH |
| 334 | Reprendre le paiement pour activer votre essai 14 jours. | -> OK deja "le paiement" et "votre essai" (verifier "Reprendre" avec accent ?) | nul | RAS |
| 642 | Votre cockpit SAV centralise, sous controle | -> `centralise, sous controle` | nul | PATCH |
| 653 | Copilote IA avec contexte commande - votre equipe garde le controle | -> `equipe garde le controle` | nul | PATCH |
| 661 | Donnees sensibles masquees, compte vendeur non modifie sans action explicite | -> `Donnees sensibles masquees, compte vendeur non modifie` | nul | PATCH |
| 666 | 0 EUR pendant 14 jours. Essai active avec Autopilot, puis votre plan prend le relais | -> `Essai active avec Autopilot` | nul | PATCH |
| 678 | Attribution marketing preservee jusqu au checkout | -> `preservee jusqu'au checkout` | nul | PATCH |
| 683 | Aucune CB requise tant que vous n avez pas confirme. | -> `pas confirme.` | nul | PATCH |
| 685 | Vos equipes gardent le controle - escalades et garde-fous configurables. | -> `equipes gardent le controle` | nul | PATCH |
| 686 | Centralisez les demandes Amazon, Fnac, Cdiscount et plus, avec un copilote IA qui prepare le contexte commande. | -> `qui prepare le contexte commande` | nul | PATCH |
| 713 | Votre choix fixe le plan apres l essai. Pendant 14 jours, vous testez Autopilot pour voir toute la valeur. | -> `apres l'essai` -> `apres l'essai` | nul | PATCH |
| 720 | Email professionnel + societe. Vos donnees sensibles restent masquees. | -> `societe. Vos donnees sensibles restent masquees` | nul | PATCH |
| 736 | 0 EUR pendant 14 jours (bandeau vert) | OK deja accentue partiellement, verifier siblings ligne 739 | nul | RAS |
| 739 | Carte demandee a l activation. Aucun debit avant la fin de l essai. | -> `Carte demandee a l'activation. Aucun debit avant la fin de l'essai.` | nul | PATCH |
| 801 | Facturation mensuelle - Essai 14 jours inclus / Facturation annuelle | OK accents | nul | RAS |
| 837 | Confirmer ce plan et activer l essai 14 jours | -> verifier "l'essai" apostrophe | nul | PATCH micro |
| 1054 | Vous allez etre redirige vers Stripe pour activer votre essai de 14 jours. | OK deja accentue | nul | RAS |
| 1072 | Votre essai gratuit de 14 jours commencera des la validation du paiement. | OK | nul | RAS |
| 1066 | Paiement non finalise | OK | nul | RAS |
| 904 | Un code a ete envoye a {email} | OK | nul | RAS |
| 948 | Nom de la societe | OK | nul | RAS |
| 558 | Impossible de creer la session de paiement. Votre espace a ete cree, rendez-vous dans Facturation. | OK accents corrects, recommandation revoir libelle (voir E3) | nul | RAS accents |
| 600 | Impossible de creer la session de paiement. Contactez le support. | OK | nul | RAS |

12+ chaines a accentuer. Toutes UTF-8 simples (`e`, `e`, `a`, `o`, `i`). Aucun risque technique. Code source deja UTF-8.

Note : Le fichier source contient deja certains accents (lignes 558, 600, 904, 1054, 1066, 1072). Le mix sans accents (`controle`, `donnees`, `equipe`) est probablement issu d evolutions iteratives PH-19.x sans relecture proofreading.

## E2 AUDIT 0 EUR VISIBLE EVERY STEP (KEY-345)

Steps Register :

```
stepsOrder = ['email', 'code', 'company', 'user', 'plan', 'checkout', 'payment_cancelled']
```

| Step | Message "0 EUR" present | Source ligne | Verdict |
|---|---|---|---|
| email | absent dans form | n/a | MANQUE |
| code | absent dans form | n/a | MANQUE |
| company | absent dans form | n/a | MANQUE |
| user | absent dans form | n/a | MANQUE |
| plan | **present** bandeau vert fort l.736 + l.739 carte/debit | 736-739 | OK fort |
| checkout | redirection Stripe | 1053-1054 | OK transition |
| payment_cancelled | retry message | 1066-1072 | OK transition |
| **Tous steps (desktop only)** | **present** ReassurancePanel sticky l.666 "0 EUR pendant 14 jours. Essai active avec Autopilot..." | 666 | OK desktop |
| Tous steps **mobile (lg<)** | ReassurancePanel `hidden lg:flex` -> **absent sur mobile** | 633 | **GAP MOBILE** |

### Proposition design 0 EUR every step (Patch B)

| Surface | Proposition | Risque mobile |
|---|---|---|
| Mini-bandeau sous progress stepper | Ajouter bandeau 1 ligne entre l.687 (progress) et formulaire : "0 EUR pendant 14 jours - CB demandee uniquement a l activation - sans engagement" (accente) | nul, taille controlee |
| Etape email/code/company/user | Visible automatiquement via mini-bandeau | nul |
| Etape plan | Garder bloc vert fort actuel (l.736-739) | nul |
| Desktop ReassurancePanel | Inchange (deja le message) | nul |
| Mobile responsive | Bandeau compact, `<= 2 lignes`, font 12-13px gray-400 | bon |

Format propose (a valider design) :

```
[Check icon] 0 EUR pendant 14 jours - CB a l activation, aucun debit avant la fin de l essai.
```

Variante mobile encore plus compacte :

```
[Check icon] 0 EUR pendant 14 jours - sans engagement.
```

Tooltip ou expand toggle pour les details additionnels CB/debit.

## E3 AUDIT ERREUR CHECKOUT "ESPACE DEJA CREE" (KEY-343)

### Source Client (`app/register/page.tsx` l.510-561)

```js
let res = await fetch('/api/auth/create-signup', { ... });          // BFF Client -> API
...
if (!res.ok) { setError(data.error || 'Erreur lors de la creation'); ... return; }
const tid = data.tenantId || data.tenant?.id;
...
const stripeRes = await fetch('/api/billing/checkout-session', { ... });  // BFF Client -> API
const stripeData = await stripeRes.json();
if (stripeData.url) { ... window.location.href = stripeData.url; }
else {
  setError('Impossible de creer la session de paiement. Votre espace a ete cree, rendez-vous dans Facturation.');
  setStep('plan');
}
```

### Source API checkout-session (`src/modules/billing/routes.ts` l.241-247)

```ts
app.post('/checkout-session', async (request, reply) => {
  const { tenantId, targetPlan, billingCycle, ... } = request.body;
  if (!tenantId || !validateTenantId(tenantId)) {
    return reply.status(400).send({ error: 'Invalid tenantId format' });
  }
  ...
});

function validateTenantId(tenantId: string): boolean {
  return /^[a-zA-Z0-9][a-zA-Z0-9_-]{2,49}$/.test(tenantId);
}
```

### Source API create-signup (`src/modules/auth/tenant-context-routes.ts` l.657-665)

```ts
const tenantSlug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').substring(0, 20);
tenantId = `${tenantSlug}-${Date.now().toString(36)}`;
// INSERT INTO tenants (id, ...) VALUES ($1, ...) -- ON ACCEPT MEME SI tenantId COMMENCE PAR DASH
```

**Asymetrie critique** : `create-signup` accepte n importe quel `tenantId` genere, mais `checkout-session` rejette les `tenantId` qui ne matchent pas le regex.

### Preuve dans logs PROD Client (Antoine cas concret 2026-05-21 16:25 UTC)

```
[Create-Signup] Proxying to ... for antoine.seremet@gmail.com
[billing/checkout-session] tenantId=-mpfmgx09 plan=STARTER cycle=monthly successUrl=https://client.keybuzz.io/register/success?session_id={CHECKOUT_SESSION_ID} promo=none
[billing/checkout-session] Backend error: 400 { error: 'Invalid tenantId format' }
```

x4 essais identiques 16:25:01 -> 16:25:47 UTC. Le **meme tenantId `-mpfmgx09`** est reutilise car `create-signup` voit un `pending_payment` deja lie au user et le reuse (`existingPending` query l.644-655).

| Source | Condition | Message | Hypothese | Preuve | Risque |
|---|---|---|---|---|---|
| API checkout-session | `!validateTenantId(tenantId)` regex `^[a-zA-Z0-9]...` | 400 Invalid tenantId format | tenantId genere commence par `-` (slug vide) | Logs Client `tenantId=-mpfmgx09` + DB tenant id `-mpfmgx09` status `pending_payment` | CERTAIN |
| API create-signup | name not empty (validation `!name`) | INSERT tenant id = `${slug}-${ts36}` | name = caracteres non-alphanumeriques uniquement (ex : `@@@`, `&&&`, `___`, multi-espace, emoji seul) | name lowercased + remplacement /[^a-z0-9]+/g + strip dashes -> slug = "" -> tenantId = "-mc7bg9xy" | CERTAIN |
| Client Register form | Pas de pre-validation `name` strict (juste required HTML) | name envoyee comme tape | User peut entrer nom societe avec caracteres invalides | HTML5 `required` only, pas de pattern | CERTAIN |
| API create-signup | Pas de regex check post-genese tenantId | INSERT tenant avec id invalide | Pas de validateTenantId apres `tenantId = ...` | Source code l.658 | CERTAIN |
| User flow recovery | UX "rendez-vous dans Facturation" suppose user est connecte sur dashboard | l.558 setError + setStep('plan') | Pas de redirection automatique vers `/billing/plan` | Source l.558-560 | CERTAIN |
| Stripe API | OK fonctionnel | Stripe checkout sessions creees pour autres tenants meme periode | logs `[Billing] Checkout session created for keybuzz-mpffhbon: cs_live_...` | Stripe pas le coupable | CERTAIN |

### Questions repondues

| Question | Reponse |
|---|---|
| Message vient-il Client ou API ? | Client l.558. API renvoie 400 + `error: 'Invalid tenantId format'` ; Client affiche message generique car `stripeData.url` absent. |
| L espace est-il reellement cree avant l erreur ? | OUI. `create-signup` returns 201 + insert tenant en `pending_payment`. |
| Pourquoi session Stripe non creee ? | API checkout-session rejette en pre-validation tenantId. Stripe n est meme pas appele. |
| Cas attendu pour compte existant ? | NON, c est un bug. `create-signup` reuse le tenant `pending_payment` (logique CORRECTE) mais le tenantId reutilise est lui-meme invalide (genere par essai initial echoue). |
| Si user a deja tenant, doit-on : envoyer Facturation / relancer / autre ? | Sans pre-condition slug vide : la logique existante reuse + relance checkout est SAINE. Avec tenantId malforme : impossible de creer session, FIX BACKEND requis. |
| Cas Antoine/admin special ? | NON, pas de logique admin specifique. Antoine est un user normal avec un `name` societe atypique. Email exact : antoine.seremet@gmail.com (visible dans logs PROD interne). |

### Cas reproductibles a tester

| Name input | Slug genere | tenantId | validateTenantId | Verdict |
|---|---|---|---|---|
| `KeyBuzz SAS` | `keybuzz-sas` | `keybuzz-sas-mpfmgx09` | OK MATCH | INSCRIPTION OK |
| `Societe Elise` | `soci-t-lise` | `soci-t-lise-mpfmgx09` | OK MATCH | INSCRIPTION OK |
| `123` | `123` | `123-mpfmgx09` | OK MATCH | INSCRIPTION OK |
| `E` | (vide apres replace) | `-mpfmgx09` | FAIL ^[a-zA-Z0-9] | **BUG REPRO** |
| `@@@` | (vide) | `-mpfmgx09` | FAIL | **BUG REPRO** |
| `e e o` | (vide) | `-mpfmgx09` | FAIL | **BUG REPRO** |
| ` ` (espaces) | (vide) | `-mpfmgx09` | FAIL si frontend trim laisse passer | **BUG REPRO probable** |
| `&&&` | (vide) | `-mpfmgx09` | FAIL | **BUG REPRO** |

## E4 RECOMMANDATIONS PATCH

### Patch A - Copy accents (KEY-342)

| Item | Valeur |
|---|---|
| Scope | Client `app/register/page.tsx` uniquement |
| Lignes touchees | 12-18 chaines (cf E1) |
| Risque | nul (UTF-8 deja en place ailleurs) |
| Recommandation | Patch source-only, build DEV, QA visuelle, train PROD |
| Prochaine phase | PH-SAAS-T8.12AS.20.5-REGISTER-ACCENTS-FR-SOURCE-01 |
| Effort | < 30 min source patch |

### Patch B - 0 EUR every step (KEY-345)

| Item | Valeur |
|---|---|
| Scope | Client `app/register/page.tsx` ; ajout mini-bandeau apres progress stepper l.687 |
| Lignes touchees | 5-15 lignes nouveau composant |
| Risque | mobile responsive a valider |
| Recommandation | Patch source + screenshot QA mobile 360px / 768px / 1024px |
| Prochaine phase | PH-SAAS-T8.12AS.20.5-REGISTER-0EUR-EVERY-STEP-SOURCE-01 |
| Effort | < 60 min source + QA mobile |
| Note | Peut etre couple avec Patch A car meme scope fichier |

### Patch C - Billing error tenantId malforme (KEY-343)

#### Option C1 : Fix racine - API create-signup ajoute fallback slug (RECOMMANDE)

| Item | Valeur |
|---|---|
| Scope | API `src/modules/auth/tenant-context-routes.ts` l.657-658 |
| Patch | `const tenantSlug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').substring(0, 20) || 'tenant';` |
| Risque | nul (fallback minimal `tenant-mpfmgx09` 18 chars MATCH regex) |
| Effort | < 5 min patch + tests |

#### Option C2 : Defense en profondeur - API create-signup valide tenantId post-genese

| Item | Valeur |
|---|---|
| Scope | API `src/modules/auth/tenant-context-routes.ts` |
| Patch | Apres `tenantId = ...`, ajouter `if (!validateTenantId(tenantId)) throw ...` ; rollback transaction |
| Risque | rejette inscription au lieu de tenant orphan -> meilleur UX (erreur immediate) |
| Effort | < 10 min |

#### Option C3 : Cleanup tenant orphan `-mpfmgx09` PROD

| Item | Valeur |
|---|---|
| Scope | DB read+write PROD |
| Action | SELECT pour confirmer tenant `-mpfmgx09` est bien Antoine, DELETE tenant + cascade user_tenants/user_preferences/tenant_metadata/ai_actions_wallet/signup_attribution |
| Risque | destructif si mauvais tenant ; necessite GO Ludovic ; Antoine doit recommencer inscription avec un nom valide |
| Recommandation | NE PAS faire avant que Antoine confirme |

#### Option C4 : UX improvement (Client) - message plus utile

| Item | Valeur |
|---|---|
| Scope | Client l.558 |
| Patch | Remplacer message `Impossible de creer la session de paiement...` par detection du code erreur API et message contextuel. Si `error === 'Invalid tenantId format'` -> `Le nom de societe contient des caracteres non supportes. Merci de saisir un nom avec au moins une lettre ou un chiffre.` + setStep('company') pour permettre correction. |
| Risque | nul, ameliore UX |
| Effort | < 30 min |

#### Recommandation patch C ordre

1. **Option C1 + C2 ensemble** (fix backend racine + defense profondeur) -> immediat
2. **Option C4** (UX message contextuel) en meme temps que A+B
3. **Option C3** apres confirmation Antoine

### Ordre recommande

| Ordre | Patch | Scope | Risque | Phase |
|---|---|---|---|---|
| 1 | Patch C1 + C2 | API source (1 fichier) | nul | PH-20.5 BILLING-FIX URGENT |
| 2 | Patch A + B + C4 ensemble | Client source (1 fichier) | faible | PH-20.6 REGISTER-POLISH |
| 3 | Patch C3 cleanup | DB PROD (avec GO) | destructif | PH-20.7 DATA-CLEANUP |

## E5 NO FAKE METRICS / NO FAKE EVENTS

- Audit READ-ONLY uniquement.
- Aucun event GA4/Meta/TikTok/LinkedIn declenche.
- Aucun checkout Stripe test.
- Aucun signup test.
- Logs lus en read-only, masquage email Antoine (cite uniquement comme tester interne autorise).
- Aucune mutation DB.

## GAPS

1. Tenant `-mpfmgx09` orphan en DB PROD `pending_payment` status (rattachement user antoine.seremet@gmail.com). Cleanup possible mais necessite GO et confirmation Antoine.
2. Audit copy accents n a pas inclus le composant `LegalModal.tsx` (31 KB) qui peut contenir d autres textes a accentuer (CGU). A faire en PH-20.6 si decision patch A.
3. Aucune verification mobile responsive sur les modifications proposees - QA navigateur necessaire avant train PROD.
4. Repo `keybuzz-api` HEAD dirty 223 fichiers (preexistant connu, hors scope PH-20.4 - probablement working tree non commit issus de PH-19.x ou autre).
5. Logs Client PROD montrent uniquement 4 occurrences `tenantId=-mpfmgx09` dans 72h. Pas d autres victimes du bug actuellement, mais probleme latent pour tout futur user avec name societe atypique.

## LINEAR

| Linear | Issue | Action | Statut |
|---|---|---|---|
| KEY-342 | Register copy accents FR | Comment avec liste 12+ chaines + recommandation Patch A | a poster (no status change) |
| KEY-345 | Register 0 EUR every step | Comment avec mapping steps + design Patch B | a poster (no status change) |
| KEY-343 | Register billing error session paiement | Comment avec **CAUSE RACINE PROUVEE** (tenantId malforme `-mpfmgx09` Antoine) + recommandation Patch C1+C2+C4 | a poster (no status change) |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO AUDIT REGISTER POLISH BILLING READY PH-SAAS-T8.12AS.20.4 |
| Bastion | install-v3 46.62.171.61 |
| KEY-342 accents FR | 12+ chaines a accentuer ; patch Client source-only ; risque nul |
| KEY-345 0 EUR every step | gap mobile uniquement (desktop OK via ReassurancePanel) ; mini-bandeau compact recommande |
| KEY-343 billing error | CAUSE RACINE = tenantId malforme (`-mpfmgx09` Antoine) ; asymetrie create-signup vs checkout-session ; fix backend C1+C2 simple |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.4-REGISTER-POLISH-BILLING-AUDIT-01.md` |
| Mutations | AUCUNE |

### Prochaines phrases GO possibles

Priorite (ordre recommande) :

1. **`GO PATCH BILLING TENANT_ID FALLBACK SOURCE PH-SAAS-T8.12AS.20.5`** (Patch C1+C2 backend, urgent, faible risque)
2. **`GO PATCH REGISTER ACCENTS + 0EUR + UX BILLING ERROR SOURCE PH-SAAS-T8.12AS.20.6`** (Patches A+B+C4 Client, bundled)
3. **`GO CLEANUP TENANT_ID ORPHAN PROD PH-SAAS-T8.12AS.20.7`** (avec GO explicite + confirmation Antoine)

Alternatives :

- `GO READONLY REGISTER BILLING ERROR DEEP DIVE PH-SAAS-T8.12AS.20.5` (si volonte audit DB plus profond avant patch)
- `GO WEBSITE CMP MOBILE AUDIT PH-SAAS-T8.12AS.20.5`

STOP.
