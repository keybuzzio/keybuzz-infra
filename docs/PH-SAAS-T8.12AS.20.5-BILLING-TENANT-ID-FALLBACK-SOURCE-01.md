# PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-SOURCE-01

> Date : 2026-05-21
> Linear : KEY-343 (primary) ; KEY-342, KEY-345 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.5 BILLING TENANT_ID FALLBACK SOURCE
> Environnement : SOURCE PATCH API (aucun build, aucun deploy)

## VERDICT

GO SOURCE PATCH BILLING TENANT_ID FALLBACK READY PH-SAAS-T8.12AS.20.5

- Cause racine PH-20.4 corrigee a la source dans `keybuzz-api/src/modules/auth/tenant-context-routes.ts`.
- Fallback slug `tenant` ajoute si normalisation produit slug vide.
- Defense en profondeur : tenantId genere valide contre regex billing avant INSERT ; sinon ROLLBACK + 500.
- 0 erreur TypeScript (`npx tsc --noEmit --skipLibCheck`).
- Logic tests 10/10 pass (KeyBuzz SAS / Societe Elise / @@@ / Elite / & & & / E seul / x / 123 / espaces / emoji-isole).
- Commit `6850427c` push origin `ph147.4/source-of-truth` OK.
- Aucun build. Aucun deploy. Aucun docker push. Aucune mutation DB. Aucun Stripe touche.
- Tenant orphan `-mpfmgx09` PROD non touche (hors scope PH-20.5).

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 16:52 |
| keybuzz-api branche | ph147.4/source-of-truth |
| keybuzz-api HEAD avant | 39e332ea fix(funnel): emet tenant_created sur le chemin succes |
| keybuzz-api local==origin avant | OK |
| keybuzz-api dirty cible (src/modules/auth/, src/modules/billing/) | 0 (preexistant `dist/` deletions hors scope) |
| keybuzz-infra HEAD avant | d140fe0 docs(register): audit polish billing PH-20.4 |
| keybuzz-infra dirty | 0 |

| Service | Namespace | Image runtime | Ready | Verdict |
|---|---|---|---|---|
| keybuzz-api | -dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE prevu |
| keybuzz-api | -prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE prevu |
| keybuzz-client | -dev | v3.5.206-clarity-register-dev | 1/1 | INCHANGE prevu |
| keybuzz-client | -prod | v3.5.200-clarity-register-prod | 1/1 | INCHANGE prevu |
| keybuzz-website | -dev | v0.6.19-cta-tracking-dev | 1/1 | INCHANGE |
| keybuzz-website | -prod | v0.6.19-cta-tracking-prod | 2/2 | INCHANGE |

## E1 AUDIT SOURCE EXACT

| Fichier | Ligne | Role | Finding | Verdict |
|---|---|---|---|---|
| `src/modules/auth/tenant-context-routes.ts` | 657-658 | UNIQUE generateur tenantId via slug + Date.now().toString(36) | slug peut etre vide -> tenantId = `-...` -> rejete par billing | CIBLE PATCH |
| `src/modules/billing/routes.ts` | 136 | `validateTenantId` regex `^[a-zA-Z0-9][a-zA-Z0-9_-]{2,49}$` | regex strict rejette tenantId commencant par `-` | INCHANGE (canonique) |
| `src/modules/billing/routes.ts` | 162, 247, 697, 755, 1130, 1197, 1306, 1346, 1563 | 10 endpoints billing utilisent `validateTenantId` | regex applique partout en billing | INCHANGE |
| `src/tests/ph111-tests.ts`, `ph113`, `ph117` | divers | tests source pre-existants mais ne couvrent pas genese tenantId | aucune regression de tests existants attendue | INCHANGE |
| Autres generateurs `tenantId =` | aucun | n/a | tenantId est lu de query/headers/params ailleurs, pas regenere | CONFIRMATION SCOPE |
| `package.json` scripts | uniquement `build` | n/a | pas de test/lint/typecheck scripts ; utilise `npx tsc` directement | OK manuel |

Conclusion E1 : un seul site de generation tenantId, regex canonique unique dans billing. Patch minimal au site de generation suffit.

## E2 DESIGN PATCH

| Patch | Fichier | Justification | Risque |
|---|---|---|---|
| Fallback slug `\|\| 'tenant'` | `src/modules/auth/tenant-context-routes.ts` l.657 | si slug vide apres normalisation, fallback garantit un tenantId valide (`tenant-mpfqdhoc` 15 chars match regex) | nul |
| Defense en profondeur : regex check avant INSERT | `src/modules/auth/tenant-context-routes.ts` apres l.658 | si regex echoue, ROLLBACK transaction + 500 ; protege contre evolution future de Date.now() ou de la regex billing | nul (jamais atteint en pratique grace au fallback) |
| Pas de changement branche `existingPending` | n/a | les tenantId existants malformes (cas Antoine `-mpfmgx09`) ne sont pas mutes ; cleanup orphan est PH-20.7 separe | nul |
| Pas de helper extrait, scope minimal | n/a | seul appelant `tenantSlug` = ce site ; pas de DRY-out necessaire | nul |

Approche retenue : patch in-place a la source de la genese. 2 modifications dans une seule branche `else` (creation nouveau tenant), pas de touche a la branche `existingPending`.

## E3 PATCH SOURCE API

### Diff

```
diff --git a/src/modules/auth/tenant-context-routes.ts b/src/modules/auth/tenant-context-routes.ts
@@ -654,9 +654,19 @@ export async function tenantContextRoutes(app: FastifyInstance) {
           [name, planUpper, marketingOwnerTenantId, planUpper, trialBoostPlan, tenantId]
         );
       } else {
-        const tenantSlug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').substring(0, 20);
+        // PH-SAAS-T8.12AS.20.5 (KEY-343): garantir slug non vide pour eviter tenantId commencant par '-'
+        // (sinon billing/checkout-session rejette via /^[a-zA-Z0-9][a-zA-Z0-9_-]{2,49}$/).
+        const tenantSlug = (name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').substring(0, 20)) || 'tenant';
         tenantId = `${tenantSlug}-${Date.now().toString(36)}`;

+        // PH-SAAS-T8.12AS.20.5 (KEY-343): defense en profondeur - le tenantId genere doit matcher la regex billing.
+        // Si la regex echoue, rollback et retourner 500 plutot que creer un tenant orphan.
+        if (!/^[a-zA-Z0-9][a-zA-Z0-9_-]{2,49}$/.test(tenantId)) {
+          await client.query('ROLLBACK');
+          console.error('[CreateSignup] Generated tenantId rejected by regex:', { length: tenantId.length, prefix: tenantId.charAt(0) });
+          return reply.status(500).send({ error: 'Erreur lors de la creation du compte' });
+        }
+
         const trialBoostPlanNew = (planUpper === 'AUTOPILOT' || planUpper === 'ENTERPRISE') ? null : 'AUTOPILOT_ASSISTED';
```

| Indicateur | Valeur |
|---|---|
| Fichier touche | `src/modules/auth/tenant-context-routes.ts` (1 fichier) |
| Stats | 1 file changed, 11 insertions(+), 1 deletion(-) |
| Delta bytes | +770 |
| Commentaires source | 2 blocs commentaires PH-SAAS-T8.12AS.20.5 (KEY-343) |
| PII dans logs ? | NON. Le `console.error` log uniquement length + prefix char (pas de name brut, pas d email) |
| Changement response shape ? | NON. 201 reste 201 sur succes. 500 reste 500 sur erreur. La branche 500 est nouvelle mais retourne le format `{ error: ... }` deja utilise ailleurs dans le handler |

## E4 TESTS

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| `npx tsc --noEmit --skipLibCheck -p tsconfig.json` | 0 erreurs TS | 0 erreurs | OK |
| Logic test `KeyBuzz SAS` | slug=keybuzz-sas, tenantId match regex | OK | OK |
| Logic test `Societe Elise` (accents) | slug=soci-t-lise, match | OK | OK |
| Logic test `@@@` | slug=tenant (fallback), match | OK | OK |
| Logic test `Elite` (accent isole en debut) | slug=lite, match | OK | OK |
| Logic test `& & &` | slug=tenant (fallback), match | OK | OK |
| Logic test `E` (caractere accentue seul) | slug=tenant (fallback), match | OK | OK |
| Logic test `x` | slug=x, match (10 chars) | OK | OK |
| Logic test `123` | slug=123, match | OK | OK |
| Logic test "  " (espaces) | slug=tenant (fallback), match | OK | OK |
| Logic test `emoji-<isole>` | slug=emoji, match | OK | OK |

Total : 10/10 logic tests pass + 0 erreur TypeScript.

Pas de framework de tests automatises (`package.json` scripts contient uniquement `build`). Verification manuelle via `node -e ...` inline assertion script.

## E5 COMMIT + PUSH API

| Commit | Repo | Branche | Hash | Push | Verdict |
|---|---|---|---|---|---|
| fix(auth): ensure generated tenant ids are checkout-safe | keybuzz-api | ph147.4/source-of-truth | 6850427c (6850427ce33f7537dffaf1facda761289271fc5e) | origin OK 39e332ea..6850427c | OK |

```
[ph147.4/source-of-truth 6850427c] fix(auth): ensure generated tenant ids are checkout-safe
 1 file changed, 11 insertions(+), 1 deletion(-)
To https://github.com/keybuzzio/keybuzz-api.git
   39e332ea..6850427c  ph147.4/source-of-truth -> ph147.4/source-of-truth
```

| Item | Valeur |
|---|---|
| Branche | ph147.4/source-of-truth |
| HEAD avant | 39e332ea |
| HEAD apres | 6850427c |
| local == origin apres push | OK |
| Files changed | src/modules/auth/tenant-context-routes.ts (1 fichier) |
| Diff stat | +11 -1 |
| Aucun fichier hors scope commit | OK (dist/* preexistant non touche, non commit) |

## NO FAKE METRICS / NO FAKE EVENTS

- Aucun event Lead/Purchase/StartTrial/CompletePayment ajoute.
- Aucun pixel Meta/TikTok/LinkedIn touche.
- Aucun checkout Stripe test reel.
- Aucune mutation DB.
- Aucun changement contract billing trial/plan/price.
- Aucun tracking GA4 modifie.
- Le `console.error` ajoute log uniquement metadonnees (length, prefix char) sans PII.

## RUNTIME PRESERVE

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-api DEV | v3.5.251-register-cro-dev | INCHANGE (aucun build) |
| keybuzz-api PROD | v3.5.250-ad-spend-sync-all-prod | INCHANGE (aucun build) |
| keybuzz-client DEV/PROD | v3.5.206 / v3.5.200 | INCHANGE |
| keybuzz-website DEV/PROD | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 DEV/PROD | v2.12.2-* | INCHANGE |

Patch source uniquement. Runtime impact = 0 jusqu au prochain build/deploy explicite (PH-20.5 BUILD DEV ou ulterieur).

## GAPS

1. Le tenant orphan PROD `-mpfmgx09` (lie a Antoine) reste en DB en status `pending_payment`. Cleanup necessite GO + confirmation Antoine en PH-20.7 separee. Avec le patch PH-20.5 live, Antoine pourra recommencer l inscription avec un nom societe identique (meme caracteres invalides) : un nouveau tenant `tenant-XXXX` valide sera cree, et le checkout passera.
2. La branche `existingPending` (UPDATE tenant existant) n est pas patchee : les tenantId malformes deja en DB restent malformes. Ce risque est attenue car (a) PH-20.4 logs ne montrent que 4 occurrences du meme tenantId Antoine en 72h, (b) le cleanup PH-20.7 traitera ces orphans existants.
3. Une regression hypothetique : si un user a deja un `pending_payment` tenant avec un id malforme et tente une nouvelle inscription, `existingPending` matche -> UPDATE -> tenantId reste malforme -> checkout-session 400. Mitigation possible en PH-20.7 cleanup. Court-circuit alternatif : ajouter une regex check sur le tenantId reuse aussi, mais hors scope PH-20.5 (le prompt limite a la branche else creation).
4. Pas de tests unitaires committed (pas de framework Jest/Vitest configure cote `keybuzz-api`). Les tests logiques ont ete executes manuellement en inline node script (10/10 pass). Future amelioration : ajouter `npm run test` script + framework dans une phase dediee.

## LINEAR

| Linear | Issue | Action | Statut |
|---|---|---|---|
| KEY-343 | Register billing error session paiement | Comment avec verdict + commit + tests + recommandation build DEV PH-20.5 | a poster (no status change) |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH BILLING TENANT_ID FALLBACK READY PH-SAAS-T8.12AS.20.5 |
| Bastion | install-v3 46.62.171.61 |
| keybuzz-api commit | 6850427c |
| keybuzz-api branche | ph147.4/source-of-truth (origin == local OK) |
| Fichier patche | src/modules/auth/tenant-context-routes.ts (+11 -1 = 10 lignes net) |
| TypeScript | 0 erreurs `npx tsc --noEmit --skipLibCheck` |
| Logic tests | 10/10 pass |
| Mutations | AUCUNE |
| Build | AUCUN |
| Deploy | AUCUN |
| DB | AUCUN |
| Runtime | INCHANGE (tous services) |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-SOURCE-01.md` |

### Prochaine phrase GO attendue

`GO BUILD API BILLING TENANT_ID FALLBACK DEV PH-SAAS-T8.12AS.20.5`

Ou bundle avec Client polish :

`GO PATCH REGISTER ACCENTS + 0EUR + UX BILLING ERROR SOURCE PH-SAAS-T8.12AS.20.6`

STOP.
