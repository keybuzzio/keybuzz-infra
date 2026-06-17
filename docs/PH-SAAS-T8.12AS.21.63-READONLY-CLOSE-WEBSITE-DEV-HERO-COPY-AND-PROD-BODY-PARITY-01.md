# PH-SAAS-T8.12AS.21.63 - Read-only close Website DEV hero copy and PROD body parity

Date UTC: 2026-06-17
Mode: READONLY CLOSE WEBSITE DEV
Verdict: READY_WITH_DEBTS

## 1. Resume executif

Cette phase cloture la chaine Website DEV PH-21.58 -> PH-21.62.

Conclusion:

- le patch source Website DEV PH-21.58 est pousse sur `redesign/light-business`;
- l'image DEV `v0.7.1-hero-copy-prod-body-parity-dev` a ete construite et publiee;
- le deploy GitOps DEV PH-21.61 est applique;
- la verification PH-21.62 est `READY`;
- le runtime Website DEV execute toujours l'image cible avec le digest attendu;
- hero PH-21.58, corps restaure depuis PROD, routes, CTA, forwarding, contact DEV,
  legal/cookie et tracking safety restent conformes;
- Website PROD et les autres services restent hors scope et intacts;
- les dettes restantes sont non bloquantes pour la cloture DEV et doivent rester dans
  des phases separees.

Cette phase n'est pas une promotion PROD.

## 2. Sources relues

Sources locales:

- `AI_MEMORY/CURRENT_STATE.md`
- `AI_MEMORY/RULES_AND_RISKS.md`
- `AI_MEMORY/DOCUMENT_MAP.md`
- `AI_MEMORY/CE_PROMPTING_STANDARD.md`
- modele `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01`
- retours locaux PH-21.58, PH-21.58_PUSH, PH-21.59, PH-21.60, PH-21.61, PH-21.62

Rapports remote:

- `PH-SAAS-T8.12AS.21.57-READONLY-DESIGN-COPY-TRACKING-PARITY-AUDIT-PROD-01.md`
- `PH-SAAS-T8.12AS.21.58-SOURCE-PATCH-WEBSITE-DEV-HERO-COPY-AND-PROD-BODY-PARITY-01.md`
- `PH-SAAS-T8.12AS.21.59-BUILD-WEBSITE-DEV-HERO-COPY-AND-PROD-BODY-PARITY-01.md`
- `PH-SAAS-T8.12AS.21.60-PUSH-IMAGE-WEBSITE-DEV-HERO-COPY-AND-PROD-BODY-PARITY-01.md`
- `PH-SAAS-T8.12AS.21.61-APPLY-WEBSITE-DEV-HERO-COPY-AND-PROD-BODY-PARITY-GITOPS-01.md`
- `PH-SAAS-T8.12AS.21.62-READONLY-VERIFY-WEBSITE-DEV-HERO-COPY-AND-PROD-BODY-PARITY-01.md`
- `PH-SAAS-T8.12AS.21.55-READONLY-RCA-SERVER-SIDE-TRACKING-STARTTRIAL-DEV-PROD-01.md`
- `PH-SAAS-T8.12AS.21.56-READONLY-VERIFY-WEBSITE-TO-STRIPE-PRECHECKOUT-TRACKING-PROD-01.md`
- `WEBSITE-AGENT-CONTEXT.md`
- `keybuzz-website/docs/BUILD-ARGS.md`

Note: `WEBSITE-AGENT-CONTEXT.md` contient des exemples historiques imperatifs
`kubectl set image`. Ils sont obsoletes face aux regles GitOps actuelles et n'ont pas
ete utilises.

## 3. Preflight bastion et repos

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Bastion | `install-v3` | `install-v3` | OK |
| IP obligatoire | `46.62.171.61` | presente dans `hostname -I` | OK |
| IP interdite | non utilisee | `51.159.99.247` non utilisee | OK |
| Date UTC | actuelle | `2026-06-17T11:12:04Z` | OK |
| Kube context | read-only | `kubernetes-admin@kubernetes` | OK |
| Infra repo | `/opt/keybuzz/keybuzz-infra` | present | OK |
| Infra branch | `main` | `main` | OK |
| Infra HEAD avant rapport | origin/main | `625388c = origin/main` | OK |
| Infra dirty avant rapport | 0 | clean | OK |
| Website repo | `/opt/keybuzz/keybuzz-website` | present | OK |
| Website branch | `redesign/light-business` | `redesign/light-business` | OK |
| Website HEAD | `dfb299b6facbbe17cf36d9085aeed2ee8908e151` | same | OK |
| Website ahead/behind | 0/0 | 0/0 | OK |
| Website dirty | 0 | clean | OK |

## 4. Chaine PH-21.58 -> PH-21.62 consolidee

| Phase | Objet | Commit/tag/digest | Verdict | Preuve | Statut |
| --- | --- | --- | --- | --- | --- |
| PH-21.58 | source patch Website DEV | Website `dfb299b` | READY_WITH_DEBTS | rapport PH-21.58 | DONE |
| PH-21.58 PUSH | push source/docs | Website `dfb299b`, infra `344cbc8` | DONE | retour push, ahead/behind 0/0 | DONE |
| PH-21.59 | build Website DEV | Image ID `sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc` | READY_WITH_DEBTS | rapport PH-21.59 | DONE |
| PH-21.60 | push image GHCR | manifest digest `sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | DONE | pull-back verified | DONE |
| PH-21.61 | apply GitOps DEV | deploy `00f5e69`, docs `f79c76c` | READY_WITH_DEBTS | manifest=last-applied=spec=pod | DONE |
| PH-21.62 | verify runtime/features | report `625388c` | READY | 13 routes 200, bundle/tracking safety OK | DONE |

No source contradictoire observee.

## 5. Runtime DEV final

Runtime DEV attendu:

`ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev`

Digest attendu:

`sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b`

| Surface | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Manifest DEV | tag cible | `k8s/website-dev/deployment.yaml` contient le tag | OK |
| Last-applied | tag cible | present | OK |
| Deployment spec | tag cible | tag cible | OK |
| Pod spec | tag cible | tag cible | OK |
| Pod imageID | digest cible | `ghcr.io/keybuzzio/keybuzz-website@sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | OK |
| Ready | 1/1 | 1/1 | OK |
| Restarts | 0 | 0 | OK |
| Generation | observed = desired | 69 = 69 | OK |

Pod DEV observe:

`keybuzz-website-78d4c86b87-xs8lz`

## 6. Feature parity DEV final

PH-21.62 a fourni la verification complete. PH-21.63 a refait un check leger in-pod des
marqueurs critiques.

| Brique | Preuve PH-21.62 | Recheck PH-21.63 | Verdict |
| --- | --- | --- | --- |
| Hero PH-21.58 | present | `Reprenez le contr` count 3 | OK |
| Seller margin framing | present | `marges` count 3 | OK |
| Human validation | present | `Vous validez` count 9 | OK |
| Body PROD parity | present | `Ce que KeyBuzz change` count 3 | OK |
| FAQ/questions | present | `Questions` count 39 | OK |
| Pricing obsolete | absent | `49 EUR` 0, `199 EUR` 0 | OK |
| KPI non prouve | absent | `-84` 0 | OK |
| Contact DEV | present | `api-dev.keybuzz.io/api/public/contact` count 2 | OK |
| Contact PROD endpoint | absent | `api.keybuzz.io/api/public/contact` count 0 | OK |
| Routes publiques | 13/13 HTTP 200 | consolide PH-21.62 | OK |
| Legal/cookies | `/privacy`, `/terms`, `/cookies` 200 | consolide PH-21.62 | OK |
| Visual | Ludovic OK | VISUAL_USER_CONFIRMED | OK |

## 7. Tracking / no fake events

Cette phase n'a declenche aucun navigateur, aucun formulaire, aucun CTA register/checkout
et aucun checkout Stripe.

| Signal | Attendu PH-21.63 | Observe | Verdict |
| --- | --- | --- | --- |
| StartTrial | 0 fake | bundle count 0, action CE 0 | OK |
| Purchase | 0 fake | bundle count 0, action CE 0 | OK |
| CompletePayment | 0 fake | bundle count 0, action CE 0 | OK |
| InitiateCheckout | 0 fake | bundle count 0, action CE 0 | OK |
| Form submit | 0 | 0 | OK |
| Stripe checkout | 0 | 0 | OK |
| CAPI endpoint | 0 call | 0 | OK |
| Browser paid IDs DEV | absent selon baseline preview | GA4/Clarity PROD IDs count 0 | OK |
| Stripe direct marker | absent | `stripe.com` count 0 | OK |

Rappel PH-21.55/PH-21.56:

- `StartTrial` server-side n'est pas attendu sans vrai checkout/trial Stripe finalise;
- le parcours direct de Ludovic vers Stripe sans paiement finalise a correctement produit
  `EXPECTED_ABSENT_STARTTRIAL`;
- les micro-events funnel ne doivent pas etre transformes en faux `StartTrial`.

## 8. Tracking / Clarity / server-side parity status

| Surface | Etat | Impact PH-21.63 |
| --- | --- | --- |
| Website DEV tracking | baseline preview, no fake events, IDs PROD absents | preserve |
| Website PROD tracking | full stack PH-21.01 connue, runtime non modifie | untouched |
| Server-side CAPI | API/tracking chain hors scope | untouched |
| Webflow `try.keybuzz.io` | gap owner forwarding separe si LP active | open debt |
| Client GA4 parity | dette separee PH-21.55 | open debt |

L'absence des IDs publics PROD dans le bundle Website DEV est attendue pour la preview
DEV et n'est pas une regression PROD.

## 9. PROD et autres services intacts

| Service | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Website PROD image | `v0.6.22-clarity-restore-prod` | same | OK |
| Website PROD digest | stable | `sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac` | OK |
| Website PROD ready | 2/2 | 2/2, both pods Running, restarts 0 | OK |
| API DEV | hors scope | `v3.5.263-llm-provider-credit-watcher-dev`, ready 1/1 | OK |
| API PROD | hors scope | `v3.5.262-llm-provider-credit-alerting-prod`, ready 1/1 | OK |
| Client DEV | hors scope | `v3.5.259-ai-assist-notification-scope-dev`, ready 1/1 | OK |
| Client PROD | hors scope | `v3.5.259-ai-assist-notification-scope-prod`, ready 1/1 | OK |
| Backend DEV/PROD | hors scope | current deployments observed, no action | OK |
| Admin V2 DEV | hors scope | `v2.12.2-media-buyer-lp-domain-qa-dev`, ready 1/1 | OK |
| Admin V2 PROD | hors scope | `v2.12.2-media-buyer-lp-domain-qa-prod`, ready 1/1 | OK |
| PROD manifests | no PH-21.63 diff | no diff observed | OK |

Known pre-existing backend debt observed again:

- `backfill-scheduler` DEV/PROD has `ready=/1`.

This is outside Website PH-21.63 and was not modified.

## 10. Dettes restantes

1. Promotion Website PROD non faite.
   - DEV est clos.
   - PROD reste sur `v0.6.22-clarity-restore-prod`.
   - Toute promotion exige un GO separe, recommande:
     `GO READONLY DESIGN WEBSITE PROD PROMOTION HERO COPY AND BODY PARITY PH-SAAS-T8.12AS.21.64`

2. `try.keybuzz.io` Webflow externe.
   - PH-21.57 signale un gap potentiel `marketing_owner_tenant_id` si cette LP reste
     utilisee pour les campagnes.
   - Hors scope PH-21.63.

3. Tracking campaign attribution / StartTrial.
   - Pas de fake event.
   - Preuve Meta/Ads exige un vrai parcours campagne avec click IDs et un vrai event
     business au bon niveau.
   - Hors scope PH-21.63.

4. Client GA4 runtime parity.
   - Dette separee PH-21.55.
   - Hors scope Website DEV.

5. Website lint global.
   - PH-21.58: `npx eslint src/app/page.tsx` PASS.
   - `npm run lint` reste FAIL_PREEXISTING hors patch.

6. Website dependency audit.
   - PH-21.59: `npm ci` a signale 9 vulnerabilities existantes.
   - Hors scope PH-21.63.

7. Preview public HEAD / certificat.
   - PH-21.62: HEAD public CE limite par certificat auto-signe, non contourne.
   - Ludovic a valide visuellement la preview DEV.
   - Dette non bloquante pour la cloture DEV.

8. Dette SRE backend preexistante.
   - `backfill-scheduler` non ready observe en DEV/PROD.
   - Hors scope Website.

## 11. No fake metrics / no fake events

| Interdit | Resultat |
| --- | --- |
| Patch source Website | 0 |
| Build Docker | 0 |
| Docker push | 0 |
| Deploy / rollout / restart volontaire | 0 |
| `kubectl apply` | 0 |
| `kubectl set image/env`, `kubectl patch/edit` | 0 |
| DB mutation | 0 |
| Fake event tracking | 0 |
| Form submit | 0 |
| CTA register/checkout click | 0 |
| Stripe checkout | 0 |
| Webflow | 0 |
| Linear | 0 |
| PROD mutation | 0 |
| Secret/token/cookie affiche | 0 |

## 12. Linear

Aucun commentaire Linear et aucun changement Linear effectue.

`LINEAR_PREPARED_TEXT`: non necessaire. La cloture DEV est documentee par ce rapport.

## 13. Post-rapport Git infra

Ce rapport est le seul changement infra attendu pour PH-21.63.

Commit attendu:

`docs(website): PH-21.63 close website dev body parity`

## 14. Verdict

La chaine DEV est close avec dettes non bloquantes et explicitement hors scope.

Phrase finale:

```text
GO READONLY CLOSE WEBSITE DEV HERO COPY AND PROD BODY PARITY READY_WITH_DEBTS PH-SAAS-T8.12AS.21.63
```

Prochain GO recommande:

```text
GO READONLY DESIGN WEBSITE PROD PROMOTION HERO COPY AND BODY PARITY PH-SAAS-T8.12AS.21.64
```

STOP.
