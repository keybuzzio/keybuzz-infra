# PH-SAAS-T8.12AS.21.62 - Read-only verify Website DEV hero copy and PROD body parity

Date UTC: 2026-06-17
Mode: READONLY VERIFY WEBSITE DEV
Verdict: READY

## Objectif

Verifier en lecture seule que le Website DEV deploye en PH-21.61 est conforme apres le
patch PH-21.58:

- runtime DEV, manifest, last-applied, deployment spec, pod spec et digest alignes;
- routes publiques critiques OK;
- homepage hero PH-21.58 et corps restaure depuis PROD visibles dans le runtime;
- CTA, pricing forwarding, contact, legal/cookie preserves;
- bundle DEV sans endpoint contact PROD ni events business interdits;
- PROD et autres services non modifies.

Ludovic a confirme avant cette phase que le rendu visuel de la preview DEV est OK. CE a
complete par des preuves techniques internes read-only.

## Preflight

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Bastion | install-v3 | install-v3 | OK |
| IP bastion | 46.62.171.61 | 46.62.171.61 presente dans hostname -I | OK |
| Date UTC | 2026-06-17 | 2026-06-17T09:46:44Z / 09:52:23Z | OK |
| Infra branch | main | main | OK |
| Infra HEAD avant rapport | origin/main | f79c76c, ahead/behind 0/0 | OK |
| Infra dirty avant rapport | 0 | clean | OK |

## Runtime equality

Runtime DEV attendu:
`ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev`

Digest attendu:
`sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b`

| Surface | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Manifest DEV | target tag | present dans `k8s/website-dev/deployment.yaml` | OK |
| Last-applied | target tag | present | OK |
| Deployment spec | target tag | target tag | OK |
| Pod spec | target tag | target tag | OK |
| Pod imageID | sha256:209d...400b | `ghcr.io/keybuzzio/keybuzz-website@sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | OK |
| Ready/restarts | ready, 0 restarts | pod `keybuzz-website-78d4c86b87-xs8lz`, Ready true, restarts 0 | OK |
| Generation | observed = desired | 69 = 69 | OK |

## Source inventory

Source Website:

- branch: `redesign/light-business`
- HEAD: `dfb299b6facbbe17cf36d9085aeed2ee8908e151`
- origin: `dfb299b6facbbe17cf36d9085aeed2ee8908e151`
- ahead/behind: 0/0
- dirty: 0

Routes sources publiques detectees:

| Source file | Route | Verdict |
| --- | --- | --- |
| `src/app/page.tsx` | `/` | OK |
| `src/app/pricing/page.tsx` | `/pricing` | OK |
| `src/app/contact/page.tsx` | `/contact` | OK |
| `src/app/privacy/page.tsx` | `/privacy` | OK |
| `src/app/terms/page.tsx` | `/terms` | OK |
| `src/app/features/page.tsx` | `/features` | OK |
| `src/app/amazon/page.tsx` | `/amazon` | OK |
| `src/app/integrations/google-ads/page.tsx` | `/integrations/google-ads` | OK |
| `src/app/cookies/page.tsx` | `/cookies` | OK |
| `src/app/legal/page.tsx` | `/legal` | OK |
| `src/app/about/page.tsx` | `/about` | OK |
| `src/app/amazon/security/page.tsx` | `/amazon/security` | OK |
| `src/app/amazon/data-usage/page.tsx` | `/amazon/data-usage` | OK |

## Bundle runtime audit

Audit effectue in-pod sur le runtime DEV. Les marqueurs attendus sont presents et les
marqueurs interdits sont absents.

| Marker | Attendu | Count runtime | Verdict |
| --- | ---: | ---: | --- |
| `Reprenez le contr` | present | 3 | OK |
| `marges` | present | 3 | OK |
| `Vous validez` | present | 9 | OK |
| `automatisez seulement` | present | 3 | OK |
| `Si vous vendez sur marketplace` | present | 3 | OK |
| `Comment` | present | 25 | OK |
| `Ce que KeyBuzz change` | present | 3 | OK |
| `protection` | present | 16 | OK |
| `Marketplaces` | present | 32 | OK |
| `Questions` | present | 32 | OK |
| `client-dev.keybuzz.io` | present | 3 | OK |
| `api-dev.keybuzz.io/api/public/contact` | present | 2 | OK |
| `api.keybuzz.io/api/public/contact` | absent | 0 | OK |
| `49 EUR` | absent | 0 | OK |
| `199 EUR` | absent | 0 | OK |
| `49e/mois` | absent | 0 | OK |
| `199e/mois` | absent | 0 | OK |
| `-84` | absent | 0 | OK |
| `StartTrial` | absent | 0 | OK |
| `Purchase` | absent | 0 | OK |
| `CompletePayment` | absent | 0 | OK |
| `InitiateCheckout` | absent | 0 | OK |
| `AW-` | absent | 0 | OK |
| `G-R3QQDYEBFG` | absent | 0 | OK |
| `9969977` | absent | 0 | OK |
| `1234164602194748` | absent | 0 | OK |
| `D7PT12JC77U44OJIPC10` | absent | 0 | OK |
| `wrff07upjx` | absent | 0 | OK |
| `facebook.com/tr` | absent | 0 | OK |
| `analytics.tiktok.com` | absent | 0 | OK |
| `snap.licdn.com` | absent | 0 | OK |
| `clarity.ms` | absent | 0 | OK |
| `google-analytics.com` | absent | 0 | OK |
| `googletagmanager.com/gtag` | absent | 0 | OK |
| `stripe.com` | absent | 0 | OK |
| `signup_complete` | absent | 0 | OK |

## Route smoke HTTP interne

GET internes depuis le pod DEV, sans navigateur, sans soumission de formulaire et sans
navigation vers le funnel.

| Route | Expected | Status | Bytes | Error marker | Verdict |
| --- | --- | ---: | ---: | ---: | --- |
| `/` | public 200 | 200 | 84126 | 0 | OK |
| `/pricing` | public 200 | 200 | 71746 | 0 | OK |
| `/contact` | public 200 | 200 | 28363 | 0 | OK |
| `/privacy` | public 200 | 200 | 57151 | 0 | OK |
| `/terms` | public 200 | 200 | 60146 | 0 | OK |
| `/features` | public 200 | 200 | 64452 | 0 | OK |
| `/amazon` | public 200 | 200 | 47089 | 0 | OK |
| `/integrations/google-ads` | public 200 | 200 | 47867 | 0 | OK |
| `/cookies` | public 200 | 200 | 46104 | 0 | OK |
| `/legal` | public 200 | 200 | 38916 | 0 | OK |
| `/about` | public 200 | 200 | 45702 | 0 | OK |
| `/amazon/security` | public 200 | 200 | 48880 | 0 | OK |
| `/amazon/data-usage` | public 200 | 200 | 45952 | 0 | OK |

## Homepage content parity

HTML interne `/`:

| Section/claim | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Hero variant A | `Reprenez le` | count 1 | OK |
| Seller protection margin framing | `marges` | count 1 | OK |
| Human validation | `Vous validez` | count 1 | OK |
| Cautious automation | `automatisez seulement` | count 1 | OK |
| Marketplace target | `Si vous vendez sur marketplace` | count 1 | OK |
| How it works | `Comment` | count 2 | OK |
| Body restored | `Ce que KeyBuzz change` | count 1 | OK |
| Protection wording | `protection` | count 1 | OK |
| Marketplace section | `Marketplaces` | count 2 | OK |
| FAQ section | `Questions` | count 1 | OK |
| Obsolete pricing `49 EUR` | absent | 0 | OK |
| Obsolete pricing `199 EUR` | absent | 0 | OK |
| Obsolete pricing `49e/mois` | absent | 0 | OK |
| Obsolete pricing `199e/mois` | absent | 0 | OK |
| Old KPI `-84` | absent | 0 | OK |
| Contact PROD endpoint | absent | 0 | OK |

## Pricing / CTA / forwarding

HTML `/pricing` et source read-only:

| Element | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| `/pricing` route | HTTP 200 | 200, 71746 bytes | OK |
| Plans | Starter/Pro/Autopilot visibles | Starter 6, Pro 9, Autopilot 6 | OK |
| Trial copy | `14 jours` visible | count 10 | OK |
| Client DEV target | `client-dev.keybuzz.io` | HTML count 8 | OK |
| Direct Stripe link | absent | source count 0, HTML count 0 | OK |
| Homepage CTA pricing | href source present | count 5 | OK |
| Secondary CTA anchor | `#comment` source present | count 1 | OK |
| `utm_source` | forwarding preserved | source count 2 | OK |
| `utm_medium` | forwarding preserved | source count 2 | OK |
| `utm_campaign` | forwarding preserved | source count 2 | OK |
| `utm_content` | forwarding preserved | source count 2 | OK |
| `utm_term` | forwarding preserved | source count 2 | OK |
| `gclid` | forwarding preserved | source count 6 | OK |
| `fbclid` | forwarding preserved | source count 6 | OK |
| `ttclid` | forwarding preserved | source count 6 | OK |
| `li_fat_id` | forwarding preserved | source count 6 | OK |
| `_gl` | forwarding preserved | source count 8 | OK |
| `promo` | forwarding preserved | source count 4 | OK |
| `marketing_owner_tenant_id` | forwarding preserved | source count 6 | OK |
| Business events | no StartTrial/Purchase/CompletePayment/InitiateCheckout | HTML count 0 | OK |

Aucun CTA vers register/checkout n'a ete clique.

## Contact / legal / cookie parity

| Feature | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| `/contact` | HTTP 200 | 200, 28363 bytes | OK |
| Contact form | present | HTML `<form` count 1 | OK |
| Contact endpoint DEV | present in runtime bundle | bundle count 2 | OK |
| Contact endpoint PROD | absent from DEV runtime | bundle 0, HTML 0 | OK |
| Source PROD endpoint references | uniquement commentaire/doc build PROD | `src/app/contact/page.tsx` comment + `docs/BUILD-ARGS.md` | OK |
| `/privacy` | HTTP 200 | 200, 57151 bytes | OK |
| `/terms` | HTTP 200 | 200, 60146 bytes | OK |
| `/cookies` | HTTP 200 | 200, 46104 bytes | OK |
| Cookie/consent surface | present in source/runtime markers | source cookie marker count 64 | OK |

Aucun formulaire n'a ete soumis.

## Visual sanity

| Viewport | Page | Controle | Resultat | Verdict |
| --- | --- | --- | --- | --- |
| utilisateur | preview DEV | Ludovic a controle visuellement et juge OK | VISUAL_USER_CONFIRMED | OK |
| CE interne | `/` + `/pricing` | HTML non vide, routes 200, marqueurs section presents | OK | OK |
| CE public HEAD | `https://preview.keybuzz.pro/` | HEAD standard sans auth | `curl exit 60`, certificat auto-signe, headers vides | LIMIT |

CE n'a pas contourne le certificat avec un mode insecure et n'a pas utilise de secret
preview. La limite externe ne bloque pas le verdict READY car Ludovic a explicitement
confirme la QA visuelle et les preuves internes runtime/HTML/bundle sont OK.

## Network / tracking safety

Pas de navigateur execute, donc aucun JS tracking browser n'a ete declenche par CE. Audit
bundle/runtime et HTML:

| Signal | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| `facebook.com/tr` | absent | 0 | OK |
| `analytics.tiktok.com` | absent | 0 | OK |
| `snap.licdn.com` | absent | 0 | OK |
| `clarity.ms` | absent | 0 | OK |
| `google-analytics.com` | absent | 0 | OK |
| `googletagmanager.com/gtag` | absent | 0 | OK |
| Stripe | absent | 0 | OK |
| Contact PROD endpoint | absent runtime DEV | 0 | OK |
| `Lead` fake event | not triggered | 0 action | OK |
| `StartTrial` | absent / not triggered | 0 marker, 0 action | OK |
| `Purchase` | absent / not triggered | 0 marker, 0 action | OK |
| `CompletePayment` | absent / not triggered | 0 marker, 0 action | OK |
| `InitiateCheckout` | absent / not triggered | 0 marker, 0 action | OK |
| `signup_complete` | absent | 0 | OK |

## PROD / autres services preserves

| Surface | Avant/attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Website PROD image | `v0.6.22-clarity-restore-prod` | unchanged | OK |
| Website PROD digest | stable PH-21.61 | `sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac` | OK |
| Website PROD ready | ready | 2/2, restarts 0 | OK |
| API DEV | hors scope | unchanged runtime listing | OK |
| API PROD | hors scope | unchanged runtime listing | OK |
| Client DEV/PROD | hors scope | unchanged runtime listing | OK |
| Backend/Admin | hors scope | unchanged runtime listing | OK |
| PROD manifest diff | none expected | no prod manifest diff observed | OK |

## No fake events / hors scope

| Interdit | Resultat |
| --- | --- |
| Build/deploy/kubectl apply | 0 |
| Manifest/source patch | 0 |
| DB mutation | 0 |
| Fake event/form/checkout | 0 |
| CTA click register/checkout | 0 |
| Stripe checkout | 0 |
| Webflow | 0 |
| Linear | 0 |
| PROD mutation | 0 |
| Secret/token/basic-auth printed | 0 |

## Limitations

- La preview publique `https://preview.keybuzz.pro/` n'a pas ete revalidee par CE en
  navigateur ou HEAD public complet: `curl` standard a echoue sur certificat auto-signe
  (`exit=60`, `http=000`). CE n'a pas contourne cette limite avec `-k` et n'a affiche
  aucun secret.
- La validation visuelle de Ludovic compense cette limite conformement au prompt, et les
  preuves internes runtime/HTML/bundle restent reproductibles.
- Aucun checkout/trial/StartTrial naturel n'a ete provoque ni attendu en PH-21.62.

## Dettes

- Si besoin d'une preuve browser CE autonome, prevoir une phase separee avec auth preview
  fournie hors logs et politique reseau explicite, sans clic funnel.
- Garder la vigilance sur les build args Website DEV/PROD: ne jamais copier les IDs PROD
  dans la preview DEV sans decision explicite.

## Prochain GO recommande

```text
GO READONLY CLOSE WEBSITE DEV HERO COPY AND PROD BODY PARITY PH-SAAS-T8.12AS.21.63
```

## Verdict final

```text
GO READONLY VERIFY WEBSITE DEV HERO COPY AND PROD BODY PARITY READY PH-SAAS-T8.12AS.21.62
```

STOP.
