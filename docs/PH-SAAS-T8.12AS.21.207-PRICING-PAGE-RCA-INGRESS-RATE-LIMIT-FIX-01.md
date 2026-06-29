# PH-SAAS-T8.12AS.21.207 - Pricing page RCA / ingress rate-limit fix

Date UTC: 2026-06-29

## Verdict

READY_FIXED.

La page pricing PROD n'est pas cassee cote code Website ni par divergence de pods.
La root cause observee est un rate-limit NGINX live trop bas et hors GitOps sur les
Ingress Website DEV/PROD.

## Symptome

Ludovic signale des erreurs regulieres sur `https://keybuzz.pro/pricing`, page critique
pour choisir un forfait et entrer dans le SaaS.

## Preflight

- Bastion: `install-v3`
- IP attendue: `46.62.171.61`
- Website repo: `/opt/keybuzz/keybuzz-website`
- Website branch: `main`
- Website HEAD observe: `0dc16900a1fd46317e6d4f5f72b8e9914a4c82ea`
- Infra repo: `/opt/keybuzz/keybuzz-infra`
- Infra branch: `main`
- Infra HEAD avant patch: `0b8780c1277259823fb1e2ed74b1c37a3596a056`

## Runtime Website PROD

- Deployment: `keybuzz-website`
- Namespace: `keybuzz-website-prod`
- Image: `ghcr.io/keybuzzio/keybuzz-website:v0.7.3-no-card-launch-pricing-prod`
- Digest runtime: `sha256:81adb5e2325953692c86fed3d15eae84882b5b4c78fd4fda0e666d3b1a856c35`
- Pods: 2/2 Ready, restarts 0
- Pod images: identiques
- Manifest/deployment/pods: coherents

Conclusion: pas de pod divergent ni de rollback partiel.

## Root cause

Les Ingress Website live contenaient des annotations rate-limit qui n'etaient pas dans
les manifests GitOps:

- `nginx.ingress.kubernetes.io/limit-rps: "10"`
- `nginx.ingress.kubernetes.io/limit-burst-multiplier: "2"`
- `nginx.ingress.kubernetes.io/limit-connections: "20"`

Les logs ingress PROD montrent un vrai parcours Meta/Instagram iOS avec rafales de
requêtes Next App Router / RSC sur:

- `/pricing?_rsc=...`
- `/?_rsc=...`
- `/cookies?_rsc=...`
- `/privacy?_rsc=...`

NGINX a ensuite retourne des `503`:

- `limiting requests, excess: 20.540 by zone ... request: "GET /pricing?_rsc=..."`
- `GET /pricing?_rsc=... HTTP/2.0" 503`
- `GET /?_rsc=... HTTP/2.0" 503`

Cela correspond au comportement intermittent: un refresh HTTP simple passe en 200,
mais un vrai navigateur Meta/Instagram peut declencher assez de prefetch RSC paralleles
pour depasser la limite.

## Observations complementaires

- `curl` public repete sur `/pricing`: HTTP 200.
- Fetch direct dans chaque pod sur `/pricing`: HTTP 200, contenu OK.
- Aucun `Application error`, `Internal Server Error` ou HTML d'erreur dans les reponses
  directes.
- Logs Website: presence historique de `Failed to find Server Action "x"`, mais le code
  source Website actuel ne contient pas de Server Action applicative (`use server` absent).
  Ce signal est classe secondaire/stale-client, pas root cause principale de la panne
  observee ici.

## Patch source Infra

Fichiers modifies:

- `k8s/website-dev/ingress.yaml`
- `k8s/website-prod/ingress.yaml`

Changement:

- GitOps reprend la maitrise des annotations rate-limit Website.
- Seuils ajustes:
  - `limit-connections: "200"`
  - `limit-rps: "100"`
  - `limit-burst-multiplier: "5"`

Raison:

- garder une protection raisonnable;
- ne plus bloquer les rafales normales des navigateurs in-app Meta/Instagram et des
  prefetch RSC Next App Router.

## Validations avant commit

- `git diff --check`: PASS
- `kubectl apply --dry-run=client -f k8s/website-dev/ingress.yaml`: PASS
- `kubectl apply --dry-run=client -f k8s/website-prod/ingress.yaml`: PASS
- `kubectl apply --dry-run=server -f k8s/website-dev/ingress.yaml`: PASS
- `kubectl apply --dry-run=server -f k8s/website-prod/ingress.yaml`: PASS

## No fake metrics / no fake events

- Aucun formulaire soumis.
- Aucun clic checkout.
- Aucun event tracking declenche volontairement.
- Aucun fake event CAPI/GA4/TikTok/LinkedIn.
- Aucune mutation DB.
- Aucun build Website.
- Aucun docker push.

## Apply GitOps

Commit infra pousse avant apply:

- `af3768df3d70240274df5fddb9ec079a491706eb`

Apply effectue:

- `kubectl apply -f k8s/website-dev/ingress.yaml`
- `kubectl apply -f k8s/website-prod/ingress.yaml`

Verification live:

- DEV last-applied contient `limit-rps=100`, `limit-burst-multiplier=5`,
  `limit-connections=200`.
- PROD last-applied contient `limit-rps=100`, `limit-burst-multiplier=5`,
  `limit-connections=200`.

## Validation post-apply

Rafale RSC simulee:

- 120 GET concurrents sur `/pricing?_rsc=...`, `/?_rsc=...`, `/cookies?_rsc=...`,
  `/privacy?_rsc=...`
- Resultat: `{'200': 120}`
- `slow_or_errors=[]`

Smoke public:

- `https://www.keybuzz.pro/pricing`: HTTP 200, error markers 0, copy pricing OK.
- `https://keybuzz.pro/pricing`: HTTP 200, error markers 0, copy pricing OK.
- `https://www.keybuzz.pro/`: HTTP 200, error markers 0.

Runtime Website PROD post-fix:

- Image inchangee: `ghcr.io/keybuzzio/keybuzz-website:v0.7.3-no-card-launch-pricing-prod`
- Digest inchange: `sha256:81adb5e2325953692c86fed3d15eae84882b5b4c78fd4fda0e666d3b1a856c35`
- Pods: 2/2 Ready, restarts 0.

Logs ingress post-fix:

- Les requetes `/pricing?_rsc=ph21207...` observees apres apply sont en HTTP 200.
- Aucun nouveau `limiting requests`/503 observe dans la fenetre post-apply.

Repo infra final:

- HEAD = origin/main = `af3768df3d70240274df5fddb9ec079a491706eb`
- ahead/behind = `0/0`
- dirty = `0`

## Rollback

- revenir les annotations rate-limit dans les manifests GitOps au commit precedent;
- commit + push;
- `kubectl apply -f` DEV puis PROD.

## Verdict final

GO APPLY WEBSITE PRICING INGRESS RATE LIMIT FIX READY_FIXED PH-SAAS-T8.12AS.21.207.
