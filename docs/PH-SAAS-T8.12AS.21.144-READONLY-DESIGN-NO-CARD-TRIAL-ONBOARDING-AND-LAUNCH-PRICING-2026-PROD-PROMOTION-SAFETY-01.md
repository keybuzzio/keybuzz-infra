# PH-SAAS-T8.12AS.21.144 - READONLY DESIGN NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 PROD PROMOTION SAFETY

Date UTC: 2026-06-26

## RESUME LUDOVIC

Verdict: NO_GO_PROD_PROMOTION_WEBSITE_DEV_PRICING_GAP PH-SAAS-T8.12AS.21.144.

Reponse a la question Ludovic:

Oui, c'est normal au sens technique actuel que `preview.keybuzz.pro/pricing` affiche encore les anciens tarifs, car la chaine PH-21.125 -> PH-21.143 a aligne API DEV + Client DEV/onboarding, mais Website DEV/PROD etaient explicitement inchanges.

Ce n'est pas normal pour l'etat cible produit. Avant toute promotion PROD, il faut patcher Website DEV.

Preuve read-only:

- Website DEV runtime: `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev`.
- Website PROD runtime: `ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod`.
- Source Website `main`, HEAD `bd32fc8bc9d9554770cc611f0712998b111473ff`, dirty `0`.
- `src/app/pricing/page.tsx` contient encore:
  - Starter `monthlyPrice: 97`
  - Pro `monthlyPrice: 297`
  - Autopilot `monthlyPrice: 497`
- `src/app/pricing/layout.tsx` contient encore `Dès 97€/mois`.
- `src/app/page.tsx` contient encore `Dès 97€/mois`.
- Runtime HTML `/pricing` DEV confirme `97`, `297`, `497`; `197` absent.

Etat favorable deja clos:

- API DEV no-card trial runtime endpoint OK.
- Client DEV no-card trial onboarding OK.
- Client DEV pricing cible 47/97/197 OK.
- `/register` DEV ne force plus le checkout Stripe et ne declenche pas de faux StartTrial/Purchase.

Decision:

Ne pas lancer de promotion PROD maintenant. Le prochain GO doit etre Website DEV source patch, puis build/push/apply/verify/close DEV. Ensuite seulement reprendre la promotion PROD globale.

Prochain GO recommande:

`GO SOURCE PATCH WEBSITE DEV NO-CARD TRIAL AND LAUNCH PRICING 2026 PARITY PH-SAAS-T8.12AS.21.145`

STOP.

## PREFLIGHT

| Controle | Resultat |
|---|---|
| Bastion | `install-v3` |
| IP | `46.62.171.61` |
| Infra HEAD | `2bd0450ef54f2c312123033cca8a4f09dceff65b` |
| Infra ahead/behind | `0/0` |
| Website branch | `main` |
| Website HEAD | `bd32fc8bc9d9554770cc611f0712998b111473ff` |
| Website dirty | `0` |

## ETAT RUNTIME

| Service | Image |
|---|---|
| Website DEV | `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev` |
| Website PROD | `ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod` |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.261-no-card-trial-onboarding-dev` |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.267-no-card-trial-runtime-endpoint-dev` |

## PREUVE WEBSITE PRICING GAP

| Surface | Attendu cible | Observe | Verdict |
|---|---|---|---|
| Website pricing Starter | 47 EUR/mois | 97 EUR/mois | GAP |
| Website pricing Pro | 97 EUR/mois | 297 EUR/mois | GAP |
| Website pricing Autopilot | 197 EUR/mois | 497 EUR/mois | GAP |
| Website home reassurance | Dès 47 EUR/mois | Dès 97 EUR/mois | GAP |
| Website pricing metadata | Dès 47 EUR/mois | Dès 97 EUR/mois | GAP |
| Website no-card copy | essai sans carte bancaire | absent runtime | GAP |

## PREUVE RUNTIME DEV

| Controle | Resultat |
|---|---|
| Runtime `/pricing` HTML bytes | `71746` |
| Runtime HTML `97` | `1` |
| Runtime HTML `297` | `1` |
| Runtime HTML `497` | `1` |
| Runtime HTML `47` | `1` |
| Runtime HTML `197` | `0` |

Note: le `47` runtime isole n'est pas suffisant pour conclure a un prix Starter 47; `197` absent et `297/497` presents prouvent le gap.

## DESIGN PROD PROMOTION SAFETY

La promotion PROD no-card trial + launch pricing 2026 doit respecter l'ordre suivant:

1. Website DEV source patch:
   - `src/app/pricing/page.tsx`: 47/97/197.
   - `src/app/pricing/layout.tsx`: `Dès 47€/mois`.
   - `src/app/page.tsx`: reassurance finale `Dès 47€/mois`.
   - Ajouter/aligner copy "14 jours d'essai sans carte bancaire" sans casser les CTA tracking.

2. Website DEV build:
   - branche `main`;
   - commit + push avant build;
   - build-from-git propre;
   - build args DEV explicites;
   - audit bundle: API/Client DEV presents, PROD absent si applicable;
   - ancien pricing 297/497 absent du scope Website pricing.

3. Website DEV GitOps:
   - manifest image only;
   - commit + push avant apply;
   - `kubectl apply -f`;
   - runtime = manifest = last-applied = pod imageID.

4. Website DEV verify/close:
   - `preview.keybuzz.pro/pricing` ou pod-local `/pricing` montre 47/97/197;
   - home reassurance alignee;
   - CTA vers Client conserve;
   - tracking Website non pollue;
   - no fake event.

5. Reprendre ensuite PROD promotion:
   - API PROD deja possede no-card trial endpoint? A verifier contre DEV close.
   - Client PROD a promouvoir depuis source Client validée.
   - Website PROD a promouvoir depuis source Website validée.
   - Admin/billing surfaces a auditer pour affichage prix.
   - Stripe Price IDs 47/97/197 a verifier/creer avant conversion post-trial.

## AUTRES GAPS A TRAITER AVANT PROD COMPLETE

| Gap | Severite | Commentaire |
|---|---|---|
| Website DEV ancien pricing | P0 | Bloque promotion PROD marketing |
| Website PROD ancien pricing | P0 | Ne pas promouvoir tant que DEV non aligne |
| Stripe Price IDs 47/97/197 | P0 billing | Necessaire pour abonnement apres trial |
| Admin billing/pricing surfaces | P1 | Audit requis; un sample `amount: 297` observe dans marketing integration guide |
| Client `register/success` fallback `97` | P2 | Non bloquant si config presente, a nettoyer |
| E2E no-card mutationnel | P0 avant annonce publique | Vrai formulaire sous GO separe ou validation Ludovic |

## NO FAKE METRICS / NO FAKE EVENTS

| Point | Resultat |
|---|---|
| POST `/funnel/event` | `0` |
| Formulaire | `0` |
| Checkout Stripe | `0` |
| StartTrial/Purchase/CompletePayment fake | `0` |
| DB mutation volontaire | `0` |
| Build/deploy/apply | `0` |

## VERDICT

`GO READONLY DESIGN NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 PROD PROMOTION SAFETY NO_GO_PROD_PROMOTION_WEBSITE_DEV_PRICING_GAP PH-SAAS-T8.12AS.21.144`

STOP.
