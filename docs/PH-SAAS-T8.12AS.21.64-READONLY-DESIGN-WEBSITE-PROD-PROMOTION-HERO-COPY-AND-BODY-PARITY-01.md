# PH-SAAS-T8.12AS.21.64 - READONLY DESIGN WEBSITE PROD PROMOTION

Role: Cursor Executor (CE)  
Projet: KeyBuzz SaaS / Website / acquisition tracking  
Phase: PH-SAAS-T8.12AS.21.64  
Mode: READONLY DESIGN WEBSITE PROD PROMOTION HERO COPY AND BODY PARITY  
Date UTC audit: 2026-06-17T11:33:57Z  
Verdict: READY_SOURCE_PATCH_REQUIRED

## 1. Resume executif

PH-21.64 prepare la promotion PROD du Website valide en DEV, sans promotion runtime.

La chaine DEV PH-21.58 a PH-21.63 est consolidee et validee:

- source DEV: `keybuzz-website` branche `redesign/light-business`, commit `dfb299b6facbbe17cf36d9085aeed2ee8908e151`;
- image DEV: `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev`;
- digest DEV runtime: `sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b`;
- verification DEV: routes publiques, CTA, forwarding, bundle, tracking safety et PROD intactes confirmes en PH-21.62/PH-21.63.

Website PROD est intacte pendant PH-21.64:

- image runtime: `ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod`;
- digest runtime: `sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac`;
- Ready: `2/2`, restarts `0`.

Decision source:

`READY_SOURCE_PATCH_REQUIRED`.

`origin/main` est la source de verite PROD et ne contient pas le hero PH-21.58. `origin/redesign/light-business` contient le patch DEV valide, mais le diff `origin/main..origin/redesign/light-business` inclut aussi `src/app/layout.tsx`, `src/components/kb2/*` et `src/styles/kb2.css`. Il ne faut donc pas builder PROD directement depuis `redesign/light-business`. La prochaine phase doit appliquer/cherry-pick proprement le patch utile sur `keybuzz-website/main`, puis seulement lancer build/push/apply/verify dans des GO separes.

## 2. Sources relues

| Source | Statut | Note |
| --- | --- | --- |
| AI_MEMORY/CURRENT_STATE.md | Lu | Regles runtime/GitOps courantes |
| AI_MEMORY/RULES_AND_RISKS.md | Lu | Interdits build/deploy/secrets/fake events |
| AI_MEMORY/DOCUMENT_MAP.md | Lu | Carte docs |
| AI_MEMORY/CE_PROMPTING_STANDARD.md | Lu | Standard CE long |
| PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01 | Lu | Modele process |
| PH-21.58_CE_RETURN.md | Lu | Source patch DEV |
| PH-21.58_PUSH_CE_RETURN.md | Lu | Push source DEV |
| PH-21.59_CE_RETURN.md | Lu | Build DEV |
| PH-21.60_CE_RETURN.md | Lu | Push image DEV |
| PH-21.61_CE_RETURN.md | Lu | Apply GitOps DEV |
| PH-21.62_CE_RETURN.md | Lu | Verify DEV |
| PH-21.63_CE_RETURN.md | Lu | Close DEV |
| PH-21.57 remote report | Lu | Design copy/tracking source of truth |
| PH-21.58 a PH-21.63 remote reports | Lus | Chaine DEV complete |
| WEBSITE-AGENT-CONTEXT.md | Lu | Contexte historique; exemples `kubectl set image` obsoletes par regles GitOps actuelles |
| keybuzz-website/docs/BUILD-ARGS.md | Lu | Build args PROD publics |
| PH-21.01 report | Lu cible | Tracking/Clarity PROD baseline |
| PH-21.55 report | Lu cible | StartTrial CAPI traffic required |
| PH-21.56 report | Lu cible | Expected absent StartTrial precheckout |
| PH-WEBSITE-T8.11AK | Lu cible | Pricing attribution forwarding |
| PH-WEBSITE-T8.12AQ.4 | Lu cible | Media buyer LP attribution contract |

## 3. Preflight bastion / repos

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Bastion | install-v3 | install-v3 | OK |
| IP obligatoire | 46.62.171.61 | 46.62.171.61 presente | OK |
| IP interdite | 51.159.99.247 absente | absente | OK |
| Date UTC | actuelle | 2026-06-17T11:33:57Z | OK |
| Kube context | read-only | kubernetes-admin@kubernetes | OK |
| Infra repo | /opt/keybuzz/keybuzz-infra | present | OK |
| Infra branch | main | main | OK |
| Infra HEAD/origin | identiques | 00a0e06a0cbd / 00a0e06a0cbd | OK |
| Infra ahead/behind | 0/0 | 0/0 | OK |
| Infra dirty avant rapport | 0 | 0 | OK |
| Website repo | /opt/keybuzz/keybuzz-website | present | OK |
| Website current branch | noter seulement | redesign/light-business | OK |
| Website dirty | 0 | 0 | OK |
| Website origin/main | hash | eba00d8181dc1e9a0cbcbd66af8b3531a4b8c1ec | OK |
| Website origin/redesign/light-business | hash | dfb299b6facbbe17cf36d9085aeed2ee8908e151 | OK |

## 4. Etat DEV valide

| Phase | Objet | Commit/tag/digest | Verdict | Statut promotion |
| --- | --- | --- | --- | --- |
| PH-21.58 | Source patch DEV | dfb299b6facbbe17cf36d9085aeed2ee8908e151 | DONE | Reference fonctionnelle |
| PH-21.59 | Build DEV | Image ID sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc | DONE | Reference build DEV |
| PH-21.60 | Push image DEV | digest sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b | DONE | Reference registry |
| PH-21.61 | Apply DEV | GitOps 00f5e69 | DONE | Runtime DEV reference |
| PH-21.62 | Verify DEV | report 625388c | READY | Reference verification |
| PH-21.63 | Close DEV | report 00a0e06 | READY_WITH_DEBTS | Reference closure |

Conclusion DEV:

- DEV est valide comme source fonctionnelle.
- PROD n'a pas ete modifiee par cette chaine.
- Aucune promotion PROD ne peut demarrer sans source PROD propre sur `main` et build PROD dedie.

## 5. Etat PROD actuel

| Service | Namespace | Image | Digest runtime | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| Website PROD | keybuzz-website-prod | ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod | sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac | 2/2 | 0 | Intact |
| Website DEV reference | keybuzz-website-dev | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev | sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b | 1/1 | 0 | Reference |

## 6. Audit source main vs redesign

| Reference | Hash | Role | Verdict |
| --- | --- | --- | --- |
| origin/main | eba00d8181dc1e9a0cbcbd66af8b3531a4b8c1ec | Source PROD candidate | Ne contient pas le hero PH-21.58 |
| origin/redesign/light-business | dfb299b6facbbe17cf36d9085aeed2ee8908e151 | Source DEV validee | Contient le hero PH-21.58 et body restore |

Diff `origin/main..origin/redesign/light-business`:

```text
M src/app/layout.tsx
M src/app/page.tsx
A src/components/kb2/Icon.tsx
A src/components/kb2/WaveCanvas.tsx
A src/components/kb2/primitives.tsx
A src/styles/kb2.css
6 files changed, 893 insertions(+), 73 deletions(-)
```

| Fichier | Diff main..redesign | Risque PROD | Action recommandee |
| --- | --- | --- | --- |
| src/app/page.tsx | modifie | Patch utile, mais doit etre porte sur main proprement | SOURCE PATCH ciblant main |
| src/app/layout.tsx | modifie | Peut embarquer du design DEV non souhaite | Ne pas prendre sans revue |
| src/components/kb2/Icon.tsx | ajoute | Composant design DEV non prouve necessaire PROD | Exclure sauf besoin prouve |
| src/components/kb2/WaveCanvas.tsx | ajoute | Animation/design DEV, risque perf/UX | Exclure sauf besoin prouve |
| src/components/kb2/primitives.tsx | ajoute | Design system DEV | Exclure sauf besoin prouve |
| src/styles/kb2.css | ajoute | Styles globaux DEV | Exclure sauf besoin prouve |
| Tracking/build files | 0 diff ciblee | Pas de drift observe | Preserver inchanges |

Marqueurs:

| Marker | origin/main | origin/redesign/light-business | Interpretation |
| --- | ---: | ---: | --- |
| `Reprenez le contr` | 0 | 1 | Hero PH-21.58 absent de main, present en redesign |
| `Ce que KeyBuzz change` | 1 | 1 | Corps PROD present des deux cotes |
| `Si vous vendez sur marketplace` | 1 | 1 | Corps PROD present des deux cotes |
| `homepage_hero_primary_pricing` | 1 | 1 | CTA hero preserves |
| `homepage_hero_secondary_learn_more` | 1 | 1 | CTA hero preserves |
| `49 EUR` | 0 | 0 | Ancien prix absent |
| `199 EUR` | 0 | 0 | Ancien prix absent |
| `-84` | 0 | 0 | KPI obsolete absent |
| `api-dev.keybuzz.io` | 0 | 0 | Pas de DEV URL dans page source |

Decision:

`SOURCE_PATCH_REQUIRED`.

Un build PROD direct depuis `redesign/light-business` n'est pas acceptable car `main` est la source de verite PROD et le diff DEV contient des fichiers hors hero/body. La promotion doit commencer par un patch source PROD ciblant `main`, avec revue explicite des fichiers inclus.

## 7. Build args PROD attendus

| Build arg / marker | PROD attendu | Source de verite | Risque | Gate build |
| --- | --- | --- | --- | --- |
| NEXT_PUBLIC_SITE_MODE | production | docs/BUILD-ARGS.md | Guard skip si absent | Build fail si production args manquants |
| NEXT_PUBLIC_CLIENT_APP_URL | https://client.keybuzz.io | docs/BUILD-ARGS.md | CTA vers DEV si mauvais | Bundle grep PROD only |
| NEXT_PUBLIC_CONTACT_API_URL | https://api.keybuzz.io/api/public/contact | docs/BUILD-ARGS.md | Form contact vers DEV si mauvais | Bundle grep PROD only |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro | docs/BUILD-ARGS.md / PH-21.01 | Perte sGTM | Bundle grep `t.keybuzz.pro` |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wrff07upjx | docs/BUILD-ARGS.md / PH-20.15 / KEY-322 | Perte Clarity | Guard + bundle grep |
| NEXT_PUBLIC_GA_ID | G-R3QQDYEBFG | docs/BUILD-ARGS.md / PH-21.01 | Perte GA4 Website | Guard + bundle grep |
| NEXT_PUBLIC_META_PIXEL_ID | 1234164602194748 | docs/BUILD-ARGS.md / PH-21.01 | Perte Meta pixel | Guard + bundle grep |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 | docs/BUILD-ARGS.md / PH-21.01 | Perte TikTok pixel | Guard + bundle grep |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 | docs/BUILD-ARGS.md / PH-21.01 | Perte LinkedIn Insight | Bundle grep |

Gates obligatoires build PROD:

- build-from-git depuis `origin/main` pousse;
- tag immuable propose: `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod`;
- aucune URL DEV dans bundle PROD: `api-dev.keybuzz.io`, `client-dev.keybuzz.io`;
- Contact PROD present: `https://api.keybuzz.io/api/public/contact`;
- Client PROD present: `https://client.keybuzz.io`;
- tracking public PROD present: Clarity, GA4, Meta, TikTok, LinkedIn, sGTM;
- aucun event browser business fake: `StartTrial`, `Purchase`, `CompletePayment`, `InitiateCheckout`, `Lead` ne doivent pas etre emis artificiellement par le Website.

## 8. Tracking / Clarity / server-side safety

| Signal | Contrat attendu | Verification future sans fake event | Risque |
| --- | --- | --- | --- |
| PageView | Browser/sgtm selon contrat Website PROD | Bundle grep + GET public/passif; ne pas utiliser comme KPI business | Tracking absent si build args manquants |
| Lead | Jamais fake | Grep bundle/source, aucun formulaire soumis | Faux signal media buyer |
| StartTrial | Business event reel apres checkout/trial | DB/delivery apres vrai checkout seulement | Faux CAPI si simule |
| Purchase | Paiement reel | Stripe/API/delivery apres paiement reel | Faux revenue si simule |
| CTA pricing/register | Preserve UTM/click IDs/owner params | Inspection href/forwarding passive, aucun clic checkout | Attribution perdue |
| Clarity | Website PROD only `wrff07upjx` | Bundle/runtime passive | Replay absent |
| sGTM | Website PROD `t.keybuzz.pro` | Bundle/runtime passive | Perte routing analytics |

Rappels imposes par PH-21.55 / PH-21.56:

- StartTrial CAPI server-side n'est pas prouve casse; preuve historique PROD du 2026-05-05 livree Meta/TikTok/LinkedIn.
- L'absence de StartTrial lors d'un arret sur page Stripe est `EXPECTED_ABSENT_STARTTRIAL`.
- Aucun faux event ne doit etre emis pour rassurer un dashboard media buyer.
- `signup_complete` GA4/Google est un chemin separe du StartTrial CAPI.

## 9. Routes / UX / content gates PROD futures

| Route | Verification future | Markers attendus | Markers interdits | Risque |
| --- | --- | --- | --- | --- |
| / | HTTP 200 HTML non vide | Hero PH-21.58, body PROD, CTA pricing/comment | 49/199/-84, DEV URLs, faux event business | Regress home |
| /pricing | HTTP 200 | Plans et forwarding attribution | Stripe direct non controle, DEV URLs | Perte conversion/attribution |
| /contact | HTTP 200 | Form/contact API PROD | api-dev | Contact casse |
| /privacy | HTTP 200 | Legal privacy | DEV URLs | Non-compliance |
| /terms | HTTP 200 | Legal terms | DEV URLs | Non-compliance |
| /features | HTTP 200 | Product features | DEV URLs | Regress content |
| /amazon | HTTP 200 | Amazon marketplace context | DEV URLs | Regress SEO |
| /integrations/google-ads | HTTP 200 | Google Ads content | DEV URLs, fake KPI | Regress acquisition |
| /cookies | HTTP 200 | Cookie/legal content | DEV URLs | Consent/legal |
| /legal | HTTP 200 | Legal identity | DEV URLs | Compliance |
| /about | HTTP 200 | About/company | DEV URLs | Brand |
| /amazon/security | HTTP 200 | Security/SP-API | DEV URLs | Trust/compliance |
| /amazon/data-usage | HTTP 200 | Data usage/SP-API | DEV URLs | Trust/compliance |

## 10. Promotion PROD proposee

Sequence future si Ludovic donne GO:

1. PH-21.65 - SOURCE PATCH WEBSITE PROD HERO COPY AND BODY PARITY
   - travailler sur `keybuzz-website/main`;
   - appliquer/cherry-pick proprement le patch utile PH-21.58;
   - exclure les fichiers DEV non necessaires sauf justification explicite;
   - tests source/offline;
   - commit local puis push dans une phase push separee si demande;
   - aucun build.

2. PH-21.66 - BUILD WEBSITE PROD HERO COPY AND BODY PARITY
   - build-from-git depuis `main` pousse;
   - tag immuable propose: `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod`;
   - passer tous les `NEXT_PUBLIC_*` PROD explicites;
   - auditer bundle avant tout push.

3. PH-21.67 - PUSH IMAGE WEBSITE PROD HERO COPY AND BODY PARITY
   - docker push GHCR du tag cible seul;
   - pull-back apres rmi;
   - verifier RepoDigest/manifest digest/Image ID/labels OCI;
   - `latest` intact.

4. PH-21.68 - APPLY WEBSITE PROD HERO COPY AND BODY PARITY GITOPS
   - modifier uniquement `k8s/website-prod/deployment.yaml`;
   - commit + push manifest avant apply;
   - `kubectl apply -f` uniquement;
   - rollout status;
   - verifier runtime = manifest = last-applied = digest.

5. PH-21.69 - READONLY VERIFY WEBSITE PROD HERO COPY AND BODY PARITY
   - routes publiques;
   - bundle markers;
   - tracking passive;
   - no fake event;
   - contact PROD;
   - DEV et autres services intacts.

6. PH-21.70 - READONLY CLOSE WEBSITE PROD HERO COPY AND BODY PARITY
   - consolidation finale.

## 11. Rollback GitOps PROD futur

Rollback seulement sous GO explicite:

- revenir au manifest PROD precedent `ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod`;
- utiliser un commit GitOps de rollback/revert manifest;
- push normal non-force;
- `kubectl apply -f k8s/website-prod/deployment.yaml`;
- rollout status;
- verifier digest precedent `sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac`;
- verifier runtime = manifest = last-applied.

Interdit: ne pas utiliser ni documenter `kubectl set image`, `kubectl set env`, `kubectl patch` ou `kubectl edit` comme chemin de deploy/rollback.

## 12. Dettes et risques

| Dette | Priorite | Bloque promotion PROD ? | Action |
| --- | --- | --- | --- |
| Source PROD a patcher sur `main` | P0 | Oui avant build | PH-21.65 source patch |
| Diff DEV contient fichiers kb2/layout/styles | P0 | Oui pour build direct redesign | Ne pas builder redesign; porter patch utile |
| Webflow `try.keybuzz.io` owner forwarding | P0 si LP active | Non pour Website Git, oui pour campagnes Webflow | Phase Webflow/Antoine separee |
| Attribution Meta reelle | P1 | Non | Parcours reel depuis URL campagne, sans fake event |
| Client GA4 runtime parity | P1 | Non pour Website | Phase Client separee |
| Lint Website global preexistant | P2 | Non si tests source gates OK | Traiter hors promotion |
| Npm audit/dependencies Website | P2 | Non bloquant immediate | Audit dedie |
| Certificat preview self-signed limite CE | P2 | Non | Limite connue |
| Dette SRE `backfill-scheduler` | P2 | Non | Phase SRE separee |
| SEO/perf PROD | P2 | Gate verify | Lighthouse/passive checks apres promotion |

## 13. No fake metrics / no fake events

PH-21.64 n'a emis aucun faux event et ne recommande aucun test artificiel. Les futures phases doivent rester passives sur tracking:

- pas de fake `Lead`;
- pas de fake `StartTrial`;
- pas de fake `Purchase`;
- pas de fake `CompletePayment`;
- pas de fake checkout Stripe;
- pas de faux formulaire;
- pas d'appel endpoint CAPI test.

La preuve business doit venir soit d'un vrai trafic, soit d'une lecture read-only des systems internes/externes autorises.

## 14. LINEAR_PREPARED_TEXT

Non envoye. Texte si une note Linear est demandee plus tard:

```text
PH-21.64 readonly design complete. DEV Website v0.7.1 hero/body parity is validated, PROD remains on v0.6.22 clarity restore. Source decision is READY_SOURCE_PATCH_REQUIRED: main does not contain PH-21.58 hero and redesign diff includes kb2/layout/style files, so PROD must start with a targeted source patch on keybuzz-website/main before build/push/apply/verify phases. No build, deploy, form, checkout, fake event, secret or Linear mutation was performed.
```

## 15. Verdict

Verdict final:

`GO READONLY DESIGN WEBSITE PROD PROMOTION HERO COPY AND BODY PARITY READY_SOURCE_PATCH_REQUIRED PH-SAAS-T8.12AS.21.64`

Prochain GO recommande:

`GO SOURCE PATCH WEBSITE PROD HERO COPY AND BODY PARITY PH-SAAS-T8.12AS.21.65`

STOP
