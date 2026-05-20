# PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-SOURCE-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-SOURCE
> Environnement : SOURCE ONLY / aucun build / aucun deploy

## VERDICT

GO SOURCE PATCH REGISTER AUTOPILOT TRIAL COPY READY PH-SAAS-T8.12AS.19.5

## OBJECTIF

Clarifier dans le step plan du tunnel register que les 14 jours d essai se font sur
Autopilot, quel que soit le plan choisi, afin de montrer la meilleure experience KeyBuzz
et de creer l effet wow attendu.

La page explique aussi que le plan selectionne prend le relais apres les 14 jours si le
client continue.

## CONTEXTE

Runtime DEV avant patch :

- Client DEV : v3.5.202-register-qa-fix-dev
- API DEV : v3.5.251-register-cro-dev
- Website DEV : v0.6.18-ga4-cleanup-dev

Runtime PROD avant patch :

- Client PROD : v3.5.198-debug-env-disabled-prod
- API PROD : v3.5.250-ad-spend-sync-all-prod
- Website PROD : v0.6.18-ga4-cleanup-prod

## SOURCE PATCH

Repo : keybuzz-client
Branche : ph148/onboarding-activation-replay
Commit local : fc4a43e copy(register): clarifie lessai Autopilot
Origin avant push : d363c38

Fichier modifie :

- app/register/page.tsx

Diff :

- 10 insertions
- 4 deletions

## COPY AJOUTE

Panneau lateral :

- "Essai 14 jours sur Autopilot, puis bascule sur le plan choisi"

Bloc 3 etapes :

- "Votre choix fixe le plan apres l essai. Pendant 14 jours, vous testez Autopilot pour voir toute la valeur."

Titre step plan :

- "14 jours d essai gratuit sur Autopilot - puis bascule sur le plan choisi."

Encart principal :

- "Pendant l essai, tout le monde teste Autopilot."
- "Quel que soit le plan choisi, vous profitez de l experience la plus complete. A la fin des 14 jours, si vous continuez, KeyBuzz bascule simplement sur le plan selectionne ici. Vous pouvez changer ou resilier pendant l essai."

CTA footer :

- "CB requise a cette etape uniquement. L essai se fait sur Autopilot ; le plan choisi prend le relais apres 14 jours si vous continuez."

## TESTS SOURCE

- next lint app/register/page.tsx : OK, no ESLint warnings or errors
- npx tsc --noEmit : 2 erreurs preexistantes hors scope sur .next/types/app/api/debug-env
- register-autopilot-trial-note : 1
- Essai 14 jours sur Autopilot : 1
- plan_selected emit : 1
- data-clarity-mask : 13
- invalid_marketing_owner_tenant_id : preserve
- clarity.ms : 0
- NEXT_PUBLIC_CLARITY : 0
- fake events in diff : 0

## NO FAKE METRICS / NO FAKE EVENTS

Le patch ne modifie aucun event GA4, Meta, TikTok ou Ads.

Le patch ne modifie pas :

- plan_selected
- tracking funnel
- attribution
- Stripe
- API
- Clarity

## RUNTIME

Aucun build.
Aucun docker push.
Aucun kubectl.
Aucun deploy DEV.
Aucun deploy PROD.

Runtime DEV/PROD inchange.

## GAPS

1. Ce patch clarifie le copy source. Il faudra verifier en QA que le comportement produit
   donne bien l experience Autopilot pendant l essai.
2. Client DEV v3.5.202 reste actif jusqu au build/apply PH-19.5.
3. Le rapport apply PH-19.4 reste a committer si toujours untracked cote infra.

## NEXT

Prochaine phrase GO attendue :

GO PUSH REGISTER AUTOPILOT TRIAL COPY SOURCE PH-SAAS-T8.12AS.19.5

STOP.
