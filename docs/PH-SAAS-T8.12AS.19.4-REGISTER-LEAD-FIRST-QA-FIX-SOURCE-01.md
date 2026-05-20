# PH-SAAS-T8.12AS.19.4-REGISTER-LEAD-FIRST-QA-FIX-SOURCE-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.4-REGISTER-LEAD-FIRST-QA-FIX-SOURCE
> Environnement : SOURCE ONLY / DEV-first / aucun build / aucun deploy

## VERDICT

GO SOURCE PATCH REGISTER QA FIX READY PH-SAAS-T8.12AS.19.4

- Commit local Client : `d363c38` ahead 1 sur `origin/ph148/onboarding-activation-replay` (`397687a`)
- 3 bugs QA Ludovic corriges en source (selection plan, badge populaire, marketing_owner_tenant_id)
- ESLint OK 0 warning 0 error sur `app/register/page.tsx`
- tsc OK hors 2 erreurs preexistantes cache obsolete `.next/types/app/api/debug-env/route.ts`
- Clarity absent / no fake events / plan_selected preserve unique
- Runtime DEV/PROD inchange (6/6)
- AUCUN build, AUCUN docker push, AUCUN kubectl, AUCUN deploy

Prochaine phrase GO attendue : GO PUSH REGISTER QA FIX SOURCE PH-SAAS-T8.12AS.19.4

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-client branche | ph148/onboarding-activation-replay | OK |
| Client HEAD local pre | 397687a | OK |
| Client HEAD origin pre | 397687a | OK match |
| Client dirty pre | tsconfig.tsbuildinfo (preexistant cache) | OK hors scope |
| keybuzz-api branche | ph147.4/source-of-truth (READ-ONLY) | OK |
| API HEAD = origin | 39e332ea | OK |
| API dirty | dist/*.js supprimes (preexistant cache build) | OK hors scope |
| keybuzz-infra branche | main (READ-ONLY sauf rapport untracked) | OK |
| Infra HEAD = origin | 8bb6bb6 | OK |
| Infra dirty | docs/PH-SAAS-T8.12AS.19.3-...-APPLY-CLIENT-DEV-01.md (untracked, attendu) | OK |

## CAUSE RACINE PAR BUG

### Bug 1 : Selection plan reste sur Pro

`app/register/page.tsx` rendu de card plan (avant l.666) :

```tsx
className={`... ${plan.highlighted ? 'bg-blue-600/20 border-blue-500 ring-2 ring-blue-500/50' : 'bg-gray-800/50 ...'}`}
```

`plan.highlighted` provient du mapping :

```tsx
const PLANS = PRICING_CONFIG.plans
  .filter(p => p.price !== null && p.id !== 'enterprise')
  .map(p => ({ ..., highlighted: p.recommended || false }))
```

`recommended: true` etait pose sur Pro dans `src/features/pricing/config.ts`. Resultat : `plan.highlighted` est STATIQUE et toujours `true` pour Pro. Le `selectedPlan` etait bien mis a jour via `setSelectedPlan(plan.id)` au clic mais l'UI ne le reflechissait pas car le className ne dependait pas de `selectedPlan`.

Le checkout fonctionnait avec le bon `selectedPlan` (state React) mais visuellement l'utilisateur n'avait aucun feedback : la card Pro restait active en permanence.

### Bug 2 : Badge "Le plus populaire" sur Pro

`src/features/pricing/config.ts` plan Pro contenait :

```ts
badge: 'Le plus populaire',
recommended: true,
```

Decision produit : `Autopilot` doit etre le plan le plus populaire (et avoir aussi l'effet visuel secondaire de mise en avant via recommended).

### Bug 3 : invalid_marketing_owner_tenant_id bloque le checkout

`keybuzz-api/src/modules/auth/tenant-context-routes.ts` ligne 622-635 :

```ts
if (marketingOwnerTenantId) {
  const ownerCheck = await client.query("SELECT id, status FROM tenants WHERE id = $1", [marketingOwnerTenantId]);
  if (ownerCheck.rows.length === 0 || ownerCheck.rows[0].status === 'deleted') {
    await client.query('ROLLBACK');
    return reply.status(400).send({ error: 'invalid_marketing_owner_tenant_id', ... });
  }
}
```

L'API rejette dur si le tenant cite n'existe pas (ou est deleted). L'URL `?marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk` provient d'un trafic legitime mais ne correspond pas a un tenant connu en DB.

Cote Client : `app/register/page.tsx` envoyait `marketing_owner_tenant_id: currentAttribution?.marketing_owner_tenant_id || undefined` sans fallback. Tout signup avec un owner ID invalide etait casse.

Decision : corriger cote Client (pas d'API patch necessaire) avec un retry safe une seule fois, sans le champ, sur cette erreur API specifique.

## FICHIERS MODIFIES

| Fichier | Type | Lignes | Risque |
|---|---|---|---|
| `app/register/page.tsx` | Client React lead-first | +36 / -18 | className conditionnel + retry safe payload create-signup |
| `src/features/pricing/config.ts` | Pricing config canonique | +2 / -2 | Badge `Le plus populaire` et `recommended:true` deplaces Pro -> Autopilot |

## PATCH DETAIL

### config.ts - Plan Pro

Avant :
```ts
cta: 'Passer en Pro',
ctaVariant: 'primary',
badge: 'Le plus populaire',
recommended: true,
```

Apres :
```ts
cta: 'Passer en Pro',
ctaVariant: 'primary',
```

### config.ts - Plan Autopilot

Avant :
```ts
cta: 'Activer Autopilot',
ctaVariant: 'secondary',
```

Apres :
```ts
cta: 'Activer Autopilot',
ctaVariant: 'secondary',
badge: 'Le plus populaire',
recommended: true,
```

### page.tsx - className conditional sur selectedPlan

```tsx
data-selected={selectedPlan === plan.id ? 'true' : 'false'}
aria-pressed={selectedPlan === plan.id}
className={`relative p-6 rounded-2xl border text-left transition-all hover:scale-[1.02] hover:shadow-lg hover:shadow-blue-500/10 ${
  selectedPlan === plan.id
    ? 'bg-blue-600/20 border-blue-500 ring-2 ring-blue-500/50'
    : plan.highlighted
      ? 'bg-gray-800/60 border-blue-500/40 hover:border-blue-500/70'
      : 'bg-gray-800/50 border-gray-700 hover:border-blue-500/40'
}`}
```

Effet UX :
- card SELECTED : ring 2 + bg-blue-600/20 + border-blue-500 (anneau bleu fort)
- card HIGHLIGHTED (Autopilot) non selected : border-blue-500/40 + bg-gray-800/60 (mise en avant discrete + badge top "Le plus populaire")
- card normale non selected : bg-gray-800/50 + border-gray-700 (neutre)

Le `selectedPlan` controle desormais l'UI active. Aucun feedback statique stale ne reste sur Pro.

### page.tsx - Retry safe sans marketing_owner_tenant_id

```tsx
const basePayload = { name: companyName, firstName, lastName, country, supportEmail: supportEmail || email, phone: phone || undefined, plan: selectedPlan, siret: siret || undefined, street: street || undefined, zipCode: zipCode || undefined, city: city || undefined, companyPhone: companyPhone || undefined, cguAccepted: true, attribution: currentAttribution || undefined };
const ownerCandidate = currentAttribution?.marketing_owner_tenant_id || undefined;
let res = await fetch('/api/auth/create-signup', { method: 'POST', headers: {...}, body: JSON.stringify({ ...basePayload, marketing_owner_tenant_id: ownerCandidate }) });
let data = await res.json();
if (!res.ok && data?.error === 'invalid_marketing_owner_tenant_id' && ownerCandidate) {
  res = await fetch('/api/auth/create-signup', { method: 'POST', headers: {...}, body: JSON.stringify(basePayload) });
  data = await res.json();
}
if (!res.ok) { setError(data.error || 'Erreur lors de la creation'); setIsLoading(false); return; }
```

Proprietes :
- 1er essai avec `marketing_owner_tenant_id` complet -> attribution fidele si valide.
- Retry uniquement sur `data?.error === 'invalid_marketing_owner_tenant_id'` ET `ownerCandidate` non vide -> aucune autre erreur n'est masquee.
- Retry une seule fois (pas de boucle).
- `attribution` complete (UTM/click IDs/_gl/promo) reste TOUJOURS dans le payload, dans les deux essais.
- `attribution` reste preservee meme sans marketing owner.

API non modifiee. La validation stricte reste en place pour les cas legitimes ; le Client gere simplement l'erreur sans bloquer.

## TESTS

| Test | Commande | Resultat | Verdict |
|---|---|---|---|
| ESLint | `npx next lint --file app/register/page.tsx` | "No ESLint warnings or errors" | OK |
| tsc strict | `npx tsc --noEmit --pretty false` | 2 erreurs preexistantes `.next/types/app/api/debug-env/route.ts` (cache obsolete, debug-env supprime PH-19.0 f61763a) | OK hors scope |
| grep config.ts badge | `grep -nE "badge:|recommended:" src/features/pricing/config.ts` | l.70 badge + l.71 recommended (sur Autopilot) | OK |
| grep page.tsx selection UI | `grep -nE "data-selected\|aria-pressed\|selectedPlan === plan.id" app/register/page.tsx` | l.679 + l.680 + l.682 (3 occurrences) | OK |
| grep page.tsx plan_selected | `grep -nE "plan_selected" app/register/page.tsx` | l.334 commentaire + l.338 emit (1 emit unique) | OK |
| grep page.tsx marketing owner retry | `grep -nE "invalid_marketing_owner_tenant_id\|ownerCandidate\|basePayload" app/register/page.tsx` | l.420 basePayload + l.433 ownerCandidate + l.438-439 spread + l.443 condition retry + l.448 retry body | OK |
| grep Clarity absent | `grep -rnE "clarity\.ms\|NEXT_PUBLIC_CLARITY\|wrff07upjx" app src` | aucun match | OK |
| diff no fake events | `git diff` ajouts | aucun `Lead`/`Purchase`/`StartTrial`/`CompletePayment`/`SubmitForm`/`InitiateCheckout`/`AW-` ajoute | OK |

## NO FAKE METRICS / NO FAKE EVENTS

| Critere | Constat |
|---|---|
| plan_selected emis au chargement avec `?plan=pro&cycle=monthly` | NON (emit uniquement dans handleSelectPlan sur clic) |
| plan_selected unique en source | OUI (1 emit canonique l.338) |
| Nouveau event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout | NON ajoute |
| Tag AW direct | NON ajoute |
| data-testid / data-plan / data-cycle / data-promo-state | preserves + data-selected + aria-pressed ajoutes |
| Clarity activation | NON activee (NEXT_PUBLIC_CLARITY=0 baseline) |
| Fake reviews / fake logos / fake chiffres | NON |

## RUNTIME PRESERVE READ-ONLY

| Service | Image runtime | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-dev | v3.5.201-register-lead-first-dev | 1/1 | INCHANGE |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | 1/1 | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |

Aucun build, aucun docker push, aucun apply, aucun rollout. Source patch + commit local Client uniquement.

## COMMIT LOCAL CLIENT

| Element | Valeur |
|---|---|
| files staged (2) | `app/register/page.tsx`, `src/features/pricing/config.ts` |
| commit hash | d363c38 |
| commit title | fix(register): corrige selection plan et marketing owner invalide |
| commit body | PH-SAAS-T8.12AS.19.4-REGISTER-LEAD-FIRST-QA-FIX |
| insertions/deletions | +40 / -20 |
| HEAD local apres | d363c38 |
| origin/ph148 apres | 397687a (INCHANGE, ahead 1) |
| status dirty | tsconfig.tsbuildinfo (preexistant, exclus du commit) |
| push | NON execute |

## CONFIRMATIONS NO BUILD / NO DEPLOY

- AUCUN docker build
- AUCUN docker push
- AUCUN kubectl apply / set / patch / edit
- AUCUN deploy DEV/PROD
- AUCUN manifest infra modifie
- AUCUN git push (commit local Client uniquement)
- AUCUN changement source API (READ-ONLY ; diagnostic ligne 622-635 uniquement)
- AUCUN changement Admin / Backend / Studio / Website / Stripe / Vault / ESO
- AUCUN secret expose
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE creation tenant reelle
- AUCUN checkout Stripe reel
- AUCUNE activation Clarity client.keybuzz.io
- Bastion install-v3 (46.62.171.61) uniquement

## LINEAR BROUILLONS (NON postes, token hors-chat)

> **KEY-335 (primary)** : Source patch local pret. Commit Client `d363c38` ahead 1. 3 bugs QA Ludovic corriges : (1) selection plan UI maintenant conditionnelle sur `selectedPlan === plan.id` (anneau bleu visible au clic, data-selected + aria-pressed ajoutes pour QA et a11y), (2) badge "Le plus populaire" + `recommended: true` deplaces de Pro vers Autopilot dans `src/features/pricing/config.ts`, (3) retry safe une seule fois sans `marketing_owner_tenant_id` cote Client si l API retourne `invalid_marketing_owner_tenant_id` (UTM/click IDs/_gl/promo preserves). ESLint OK. plan_selected preserve unique. Clarity non activee. No fake events. STOP avant push/build/deploy.

> **KEY-334** : QA blockers register lead-first corriges en source. Apres push + build + apply DEV, le tunnel email -> code -> company -> user -> plan -> checkout/Stripe sera 100% fonctionnel cote UX visible.

> **KEY-329** : Bug visuel selection plan etait du a un className statique base sur `plan.highlighted`. Correction passe par `selectedPlan === plan.id` + role secondaire `plan.highlighted` (Autopilot reste discretement mis en avant via border-blue-500/40 et badge top). Decision produit : Autopilot est desormais le plan le plus populaire.

> **KEY-331** : `plan_selected` reste emis uniquement dans `handleSelectPlan` (1 emit canonique). Aucun emit au chargement, aucun emit par bouton non-plan, aucun nouvel event ads ajoute.

> **KEY-330** : No fake events ajoutes. Aucun `Lead` / `Purchase` / `StartTrial` / `CompletePayment` / `SubmitForm` / `InitiateCheckout` / `AW-XXXXXXXXXX` ajoute par PH-19.4.

> **KEY-325** : Clarity client toujours non activee (`NEXT_PUBLIC_CLARITY=0`). data-clarity-mask PII preserves.

## GAPS

1. tsc rapporte 2 erreurs preexistantes sur `.next/types/app/api/debug-env/route.ts` (cache obsolete apres suppression du fichier en `f61763a`). N'a jamais bloque les builds PH-19.1 / PH-19.2 / PH-19.3 ; sera resolu naturellement au prochain build car `.next` est regenere.
2. QA navigateur Ludovic non realisable a ce stade : runtime DEV reste `v3.5.201-register-lead-first-dev` (sans le fix). Visuel correct uniquement apres build + push + apply DEV (phases QA-FIX-PUSH + BUILD-CLIENT-DEV + PUSH-IMAGE-CLIENT-DEV + APPLY-CLIENT-DEV).
3. Format `marketing_owner_tenant_id` non documente cote Client (tenant id canonique vs slug). La validation reste API-side ; le Client se contente d un fallback safe.
4. Aucun helper `sanitizeMarketingOwnerTenantId` introduit : approche minimaliste retenue (retry sur erreur API specifique uniquement). Si Ludovic prefere la validation cote Client en amont, une PH-19.4-bis pourra introduire le helper.
5. Tunnel email -> code -> company -> user -> plan -> checkout : pas touche, fonctionne tel quel.
6. API tenant-context-routes.ts ligne 622-635 inchange (validation stricte preservee).

## ROLLBACK

Si necessaire, rollback local strict :
- `git -C /opt/keybuzz/keybuzz-client reset --soft HEAD~1` (revient sur le commit precedent `397687a` tout en gardant le patch en index)
- ou `git -C /opt/keybuzz/keybuzz-client revert d363c38` (commit inverse propre)
- INTERDIT : `git reset --hard`, `git clean`, `git push --force`

Aucun runtime touche, donc aucun rollback runtime necessaire.

## VERDICT FINAL

GO SOURCE PATCH REGISTER QA FIX READY PH-SAAS-T8.12AS.19.4

| Indicateur | Valeur |
|---|---|
| Commit local Client | d363c38 |
| Origin/ph148 | 397687a (INCHANGE, ahead 1) |
| Files modifies | 2 (app/register/page.tsx + src/features/pricing/config.ts) |
| Lignes | +40 / -20 |
| ESLint | OK 0 warning 0 error |
| tsc | OK (2 erreurs preexistantes hors scope) |
| plan_selected | preserve unique |
| Clarity | non activee |
| No fake events | OK |
| Runtime | 6/6 INCHANGE |
| Rapport local | /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.19.4-REGISTER-LEAD-FIRST-QA-FIX-SOURCE-01.md (untracked) |

Prochaine phrase GO attendue :

GO PUSH REGISTER QA FIX SOURCE PH-SAAS-T8.12AS.19.4

STOP.
