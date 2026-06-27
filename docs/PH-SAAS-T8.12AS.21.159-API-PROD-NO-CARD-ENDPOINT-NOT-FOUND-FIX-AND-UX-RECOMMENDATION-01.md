# PH-SAAS-T8.12AS.21.159 - API PROD NO-CARD ENDPOINT NOT FOUND FIX AND UX RECOMMENDATION

Date UTC: 2026-06-27

## RESUME LUDOVIC

Verdict: READY_FIXED_WITH_PRODUCT_RECOMMENDATION PH-SAAS-T8.12AS.21.159.

Symptome:

- Sur `https://client.keybuzz.io/register`, le dernier bouton affichait `Not Found`.
- Sur `https://client-dev.keybuzz.io/register`, le parcours etait OK.

Cause:

- Client PROD avait ete promu sur `v3.5.262-no-card-trial-onboarding-prod`.
- API PROD etait encore sur `v3.5.265-meta-capi-error-observability-prod`.
- Le Client PROD appelait donc le BFF no-card trial, mais l'API PROD ne possedait pas encore `POST /tenant-context/no-card-trial`.
- Resultat attendu dans cet etat intermediaire: `404 Not Found`.

Correction effectuee:

- Build API PROD depuis source Git propre `3ded430d1925a41eee4d35a84d64533bd97b40e4`.
- Image poussee: `ghcr.io/keybuzzio/keybuzz-api:v3.5.268-no-card-trial-runtime-endpoint-prod`.
- Digest GHCR: `sha256:8b5a70ae779c564e48aa6d93aedce75c07e5ad14747430aca347840189c22fef`.
- Config/Image ID: `sha256:6f04e5246aaaf131d9de1742d8300b8b9ddcecc1e094408bcb8119107a9b7810`.
- GitOps PROD applique via `k8s/keybuzz-api-prod/deployment.yaml`.
- Manifest commit: `f4572ae`.

Runtime final:

- API PROD image: `ghcr.io/keybuzzio/keybuzz-api:v3.5.268-no-card-trial-runtime-endpoint-prod`.
- Runtime equality: manifest = last-applied = deployment spec = pod spec.
- Pod imageID digest: `sha256:8b5a70ae779c564e48aa6d93aedce75c07e5ad14747430aca347840189c22fef`.
- Ready: `1/1`.
- Restarts: `0`.
- Generation: `428/428`.
- Health: OK.

Verification endpoint:

- `POST /tenant-context/no-card-trial` sans authentification retourne maintenant `401 {"error":"Not authenticated"}`.
- Ce resultat prouve que la route existe en PROD et ne retourne plus `404`.
- Aucun tenant n'a ete cree ou modifie pendant cette verification.

## SOURCE ET BUILD

| Controle | Resultat |
|---|---|
| Repo | `/opt/keybuzz/keybuzz-api` |
| Branche | `ph147.4/source-of-truth` |
| Source commit | `3ded430d1925a41eee4d35a84d64533bd97b40e4` |
| Build worktree | `/opt/keybuzz/build-worktrees/ph21156-20260627T093608Z/keybuzz-api` |
| Build base | clean detached worktree |
| Canonical dirty API | dette `dist/` preexistante conservee |

## TESTS ET AUDIT IMAGE

| Controle | Resultat |
|---|---|
| `tsc --noEmit` | PASS |
| PH-21.125 pricing/no-card tests | PASS, 31/31 |
| PH-21.132A runtime endpoint tests | PASS, 75/75 |
| `no-card-trial` marker image | present |
| `requiresCardAtStart` marker image | present |
| `stripeRequiredAtStart` marker image | present |
| `trialing` marker image | present |
| `trial_ends_at` marker image | present |
| `getPlanIncludedKBActions` marker image | present |
| `PROVIDER_CREDIT_EXHAUSTED` marker image | present |
| Meta CAPI observability markers | present |
| Tests in runtime image | absent |

## NON-REGRESSION

| Service | Etat |
|---|---|
| Client PROD | `v3.5.262-no-card-trial-onboarding-prod`, Ready `1/1`, restarts `0` |
| API PROD | `v3.5.268-no-card-trial-runtime-endpoint-prod`, Ready `1/1`, restarts `0` |
| Website PROD | non modifie |
| Client DEV | non modifie |
| API DEV | non modifie |
| Admin/Backend | non modifies |

## NO FAKE METRICS / NO FAKE EVENTS

| Surface | Resultat |
|---|---|
| Formulaire register | `0` |
| Tenant cree/modifie volontairement | `0` |
| Checkout Stripe | `0` |
| POST `/funnel/event` | `0` |
| StartTrial/Purchase/CompletePayment | `0` |
| CAPI/GA4/TikTok/LinkedIn fake event | `0` |
| DB mutation volontaire | `0` |

Note: la seule verification endpoint a ete un POST invalide sans authentification, attendu en refus `401`, sans activation de trial.

## RECOMMANDATION PRODUIT

Le parcours cible recommande est de supprimer le choix de plan pendant l'inscription.

Parcours cible:

1. L'utilisateur arrive sur `/register`.
2. Il saisit seulement les coordonnees minimales necessaires: email, nom, societe, mot de passe ou SSO.
3. KeyBuzz cree le tenant et active automatiquement un essai full-access de 14 jours.
4. L'utilisateur arrive directement dans le SaaS.
5. Le choix STARTER / PRO / AUTOPILOT est reporte dans le SaaS, pendant ou a la fin du trial.
6. La carte bancaire est demandee uniquement au moment de continuer apres le trial.

Pourquoi:

- Moins de friction acquisition.
- Moins de charge cognitive au moment de l'inscription.
- Meilleure coherence avec la promesse `14 jours sans carte`.
- Conversion plus naturelle apres experience produit reelle.

Decision technique a prendre:

- Le no-card trial actuel active deja un plan demande par le Client.
- Il faut donc patcher ensuite le Client pour ne plus demander le plan sur `/register`.
- Cote API, soit conserver un plan par defaut trial interne, soit forcer `AUTOPILOT_ASSISTED` pendant 14 jours puis demander le plan final dans le SaaS.

Option recommandee:

- Trial interne par defaut: `AUTOPILOT_ASSISTED` / full access encadre.
- Plan commercial final: non choisi au register.
- Conversion: ecran SaaS dedie avant expiration + billing page + emails lifecycle.

## VERDICT

`GO READONLY CLOSE API PROD NO-CARD ENDPOINT NOT FOUND FIX READY_FIXED_WITH_PRODUCT_RECOMMENDATION PH-SAAS-T8.12AS.21.159`

STOP.
