# PH-SAAS-T8.12AS.21.65 - SOURCE PATCH WEBSITE PROD HERO COPY AND BODY PARITY

Role: Cursor Executor (CE)  
Projet: KeyBuzz SaaS / Website / acquisition tracking  
Phase: PH-SAAS-T8.12AS.21.65  
Mode: SOURCE PATCH WEBSITE PROD branch only  
Date UTC: 2026-06-17T12:09:11Z  
Verdict: READY_WITH_DEBTS

## 1. Resume executif

PH-21.65 a porte sur `keybuzz-website/main` le hero copy valide par la chaine DEV PH-21.58 -> PH-21.63, sans copier la branche `redesign/light-business` et sans toucher aux fichiers hors scope `layout/kb2/styles`.

Le patch final est minimal:

- repo: `/opt/keybuzz/keybuzz-website`;
- branche: `main`;
- commit local non pousse: `4a12cfc801eda3d095bc43a984abc87522d6e41b`;
- fichier modifie: `src/app/page.tsx` uniquement;
- diff: `4 insertions(+), 4 deletions(-)`;
- aucun build, docker push, deploy, `kubectl apply`, manifest, fake event, formulaire, checkout Stripe, mutation DB, Webflow ou Linear.

Verdict `READY_WITH_DEBTS` car les tests cibles passent, mais `npm run lint` global reste en `FAIL_PREEXISTING` avec 275 problemes hors patch, dette deja documentee en PH-21.58/PH-21.59.

## 2. Sources relues

| Source | Statut |
| --- | --- |
| Mission `PH-21.65_CE_MISSION.md` | Lue |
| AI_MEMORY `CURRENT_STATE`, `RULES_AND_RISKS`, `DOCUMENT_MAP`, `CE_PROMPTING_STANDARD` | Lus |
| Modele `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | Lu |
| Retours locaux PH-21.58, PH-21.58_PUSH, PH-21.59, PH-21.60, PH-21.61, PH-21.62, PH-21.63, PH-21.64 | Lus |
| Rapports remote PH-21.57 a PH-21.64 | Lus / consolides |
| `WEBSITE-AGENT-CONTEXT.md` | Lu, exemples imperatifs obsoletes non repris |
| `keybuzz-website/docs/BUILD-ARGS.md` | Lu |
| PH-21.01, PH-21.55, PH-21.56, PH-WEBSITE-T8.11AK, PH-WEBSITE-T8.12AQ.4 | Lus cible |

## 3. Preflight bastion / repos

| Controle | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Bastion | install-v3 | install-v3 | OK |
| IP obligatoire | 46.62.171.61 | presente | OK |
| IP interdite | 51.159.99.247 absente | absente | OK |
| Website repo | /opt/keybuzz/keybuzz-website | present | OK |
| Website branch avant | noter | redesign/light-business puis main | OK |
| Website target branch | main | main | OK |
| Website HEAD main avant | origin/main | eba00d8181dc1e9a0cbcbd66af8b3531a4b8c1ec | OK |
| Website dirty avant | 0 | 0 | OK |
| Infra repo | /opt/keybuzz/keybuzz-infra | present | OK |
| Infra branch | main | main | OK |
| Infra dirty avant | 0 | 0 | OK |

## 4. Decision PH-21.64 reprise

PH-21.64 avait conclu `READY_SOURCE_PATCH_REQUIRED`:

- `main` ne contenait pas le hero PH-21.58;
- `redesign/light-business` contenait le hero/body valide;
- le diff `main..redesign` incluait aussi `src/app/layout.tsx`, `src/components/kb2/*` et `src/styles/kb2.css`;
- il ne fallait donc pas builder PROD directement depuis `redesign/light-business`.

PH-21.65 respecte cette decision: aucun merge, aucun cherry-pick global, aucun fichier `kb2`, aucun layout, aucun style global.

## 5. Audit source avant patch

| Reference | Hash | Role | Verdict |
| --- | --- | --- | --- |
| origin/main | eba00d8181dc1e9a0cbcbd66af8b3531a4b8c1ec | source PROD cible | Patch necessaire |
| origin/redesign/light-business | dfb299b6facbbe17cf36d9085aeed2ee8908e151 | source DEV reference | Reference hero/body |

Diff global observe avant patch:

```text
M src/app/layout.tsx
M src/app/page.tsx
A src/components/kb2/Icon.tsx
A src/components/kb2/WaveCanvas.tsx
A src/components/kb2/primitives.tsx
A src/styles/kb2.css
```

Audit critique: le `page.tsx` complet de `redesign/light-business` depend de `@/components/kb2/Icon`, `WaveCanvas`, `Sparkline` et classes `kb2`. Il n'a donc pas ete copie tel quel. Le patch porte uniquement le contenu hero compatible avec la source `main` existante.

## 6. Patch applique

Fichier modifie:

`src/app/page.tsx`

Changements:

| Zone | Avant | Apres |
| --- | --- | --- |
| Badge hero | `Support Client Marketplace` | `OS IA pour le SAV marketplace` |
| H1 ligne 1 | `Automatisez votre SAV marketplace` | `Reprenez le controle de votre SAV marketplace` |
| H1 ligne 2 | `sans perdre le controle` | `avec une IA qui protege vos marges` |
| Subtitle | IA trie/priorise/prepares reponses, main gardee | centralise messages, contexte commande, reponses controlees, validation humaine, automatisation prudente |

Scope:

| Fichier | Statut |
| --- | --- |
| `src/app/page.tsx` | modifie |
| `src/app/layout.tsx` | non touche |
| `src/components/kb2/*` | non touche |
| `src/styles/kb2.css` | non touche |
| Tracking/adapters/API/Client/Admin/Backend | non touche |
| Manifests Kubernetes | non touche |

## 7. No fake metrics / no fake events

Verification source:

| Signal | Attendu | Observe source | Verdict |
| --- | --- | ---: | --- |
| StartTrial | pas ajoute | 0 | OK |
| Purchase | pas ajoute | 0 | OK |
| CompletePayment | pas ajoute | 0 | OK |
| InitiateCheckout | pas ajoute | 0 | OK |
| Lead | pas ajoute | 0 | OK |
| Stripe direct | absent | 0 | OK |
| URL DEV hardcodee homepage | absente | 0 `client-dev` / 0 `api-dev` | OK |
| Forwarding attribution | preserve | fichiers pricing/CTA non modifies | OK |
| Contact endpoint | build-arg compatible PROD | fichiers contact/build args non modifies | OK |

Rappel conserve: `StartTrial` reste un event business reel apres checkout/trial Stripe finalise, jamais un clic pricing ni une arrivee sur Stripe.

## 8. Tests source

| Test | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| `git apply --check` | PASS | PASS | OK |
| `git diff --name-only` avant commit | `src/app/page.tsx` only | `src/app/page.tsx` | OK |
| `git diff --check` | PASS | PASS | OK |
| Forbidden deps kb2/layout/styles | 0 | 0 | OK |
| `npx eslint src/app/page.tsx` | PASS | PASS | OK |
| `npm run lint` global | PASS ou FAIL_PREEXISTING | FAIL_PREEXISTING: 275 problems, hors patch | Dette |
| Typecheck rapide | si script non-build existe | aucun script typecheck dans package | NOT_RUN |
| Docker build | interdit | non lance | OK |

Marqueurs apres patch:

| Marker | Count |
| --- | ---: |
| `Reprenez le contr` | 1 |
| `marges` | 1 |
| `Vous validez` | 1 |
| `automatisez seulement` | 1 |
| `Ce que KeyBuzz change` | 1 |
| `Si vous vendez sur marketplace` | 1 |
| `Questions` | 1 |
| `49 EUR` | 0 |
| `199 EUR` | 0 |
| `-84` | 0 |

## 9. Non-regression tracking / contact / CTA

| Surface | Controle | Resultat | Verdict |
| --- | --- | --- | --- |
| CTA hero primaire | ID/href existants | non modifies | OK |
| CTA hero secondaire | `#comment`, ID existant | non modifies | OK |
| Pricing forwarding | UTM/click IDs/owner/promo | fichiers non modifies | OK |
| Clarity/GA4/Meta/TikTok/LinkedIn/sGTM | build args/docs | non modifies | OK |
| Contact API | source contact/build args | non modifies | OK |
| Server-side tracking | API/Client untouched | non modifie | OK |

## 10. Commits locaux

| Repo | Branch | HEAD | Origin | Ahead/behind | Dirty | Push | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-website | main | 4a12cfc801ed | eba00d8181dc | 1/0 | 0 | non | OK |
| keybuzz-infra | main | voir section rapport | 4dba4cc250a6 avant rapport | attendu 1/0 apres rapport | attendu 0 | non | OK |

Commit Website:

`4a12cfc801eda3d095bc43a984abc87522d6e41b feat(website): PH-21.65 prod hero body parity source`

## 11. Runtime / PROD intact check read-only

| Surface | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Website PROD image | v0.6.22-clarity-restore-prod | `ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod` | OK |
| Website PROD digest | sha256:974350... | `sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac` | OK |
| Website PROD ready | 2/2 | 2/2 | OK |
| Website DEV image | v0.7.1 dev reference | `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev` | OK |
| Website DEV ready | 1/1 | 1/1 | OK |
| Manifests | aucun changement | infra dirty 0 avant rapport | OK |

## 12. Dettes et risques

| Dette | Priorite | Bloque push source ? | Action |
| --- | --- | --- | --- |
| `npm run lint` global FAIL_PREEXISTING | P2 | Non | Dette globale Website hors patch |
| Build PROD non fait | P0 avant deploy | Non pour source patch | PH-21.66 apres push source |
| Webflow `try.keybuzz.io` owner forwarding | P0 si LP active | Non pour Website Git | Phase Webflow separee |
| Attribution Meta reelle | P1 | Non | Trafic reel uniquement, pas fake event |
| Client GA4 runtime parity | P1 | Non | Phase Client separee |
| Npm audit dependencies | P2 | Non | Audit dedie |
| Certificat preview self-signed | P2 | Non | Limite connue |
| Dette SRE backfill-scheduler | P2 | Non | Phase SRE separee |

## 13. LINEAR_PREPARED_TEXT

Non envoye:

```text
PH-21.65 source patch complete locally. Website main has local commit 4a12cfc801ed touching only src/app/page.tsx. No redesign merge, no layout/kb2/styles. Targeted tests pass; global lint remains preexisting Website debt. No push/build/deploy/apply/runtime mutation/fake event/form/checkout/Linear.
```

## 14. Prochain GO

`GO PUSH SOURCE PATCH WEBSITE PROD HERO COPY AND BODY PARITY PH-SAAS-T8.12AS.21.65`

Ne pas proposer de build tant que le source patch local n'est pas pousse.

## 15. Verdict

`GO SOURCE PATCH WEBSITE PROD HERO COPY AND BODY PARITY READY_WITH_DEBTS PH-SAAS-T8.12AS.21.65`

STOP
