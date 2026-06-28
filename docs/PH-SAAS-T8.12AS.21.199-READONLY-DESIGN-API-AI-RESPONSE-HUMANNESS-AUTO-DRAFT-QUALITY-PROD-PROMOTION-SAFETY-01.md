# PH-SAAS-T8.12AS.21.199 - READONLY DESIGN API AI RESPONSE HUMANNESS AND AUTO DRAFT QUALITY PROD PROMOTION SAFETY

Date: 2026-06-28
Mode: READONLY DESIGN PROD PROMOTION SAFETY
Verdict: READY_FOR_BUILD_PROD

## Objectif

Verifier que la promotion PROD du patch API "AI response humanness and auto draft quality" est sure.

Hors scope de cette phase:

- aucun build Docker;
- aucun docker push;
- aucun manifest modifie;
- aucun kubectl apply;
- aucun appel LLM live;
- aucun event fake;
- aucune mutation DB;
- aucune modification Client/Admin/Website/Stripe/tracking/billing.

## Sources relues

- keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md
- keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
- keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
- keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
- keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md
- PH-SAAS-T8.12AS.21.192-READONLY-DESIGN-AI-RESPONSE-HUMANNESS-AUTO-DRAFT-QUALITY-DEV-PROD-01.md
- PH-SAAS-T8.12AS.21.193-SOURCE-PATCH-AI-RESPONSE-HUMANNESS-AUTO-DRAFT-QUALITY-DEV-01.md
- PH-SAAS-T8.12AS.21.194-BUILD-API-AI-RESPONSE-HUMANNESS-AUTO-DRAFT-QUALITY-DEV-01.md
- PH-SAAS-T8.12AS.21.195-PUSH-IMAGE-API-AI-RESPONSE-HUMANNESS-AUTO-DRAFT-QUALITY-DEV-01.md
- PH-SAAS-T8.12AS.21.196-APPLY-API-AI-RESPONSE-HUMANNESS-AUTO-DRAFT-QUALITY-DEV-GITOPS-01.md
- PH-SAAS-T8.12AS.21.197-READONLY-VERIFY-API-AI-RESPONSE-HUMANNESS-AUTO-DRAFT-QUALITY-DEV-01.md
- PH-SAAS-T8.12AS.21.198-READONLY-CLOSE-API-AI-RESPONSE-HUMANNESS-AUTO-DRAFT-QUALITY-DEV-01.md

## Source API

Repo: keybuzz-api
Branche: ph147.4/source-of-truth
HEAD: f030088d9132d85d955558d1850b2ec8085f7da0
Commit: feat(ai): improve human reply quality prompts
Origin: aligned 0/0
Dirty: 0

Patch source:

- src/modules/ai/shared-ai-context.ts
- src/modules/autopilot/engine.ts
- src/tests/ph21193-ai-response-humanness-tests.ts

No migration DB.
No schema change.
No Client/Admin/Website change required.

## Tests source read-only

| Test | Resultat |
|---|---|
| npx ts-node src/tests/ph21193-ai-response-humanness-tests.ts | PASS |
| npx ts-node src/tests/ph21182-playbooks-read-repair-tests.ts | PASS |
| npx ts-node src/tests/ph21177-activate-amazon-idempotent-tests.ts | PASS |
| npx tsc --noEmit | PASS |

## DEV valide

API DEV runtime:

ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-dev

Digest:

sha256:815c80d07d9473ff04c6c8252f7672559eb17ae3ec2d304dff9081e67d2c5cbb

Etat:

- ready 1/1;
- generation 520/520;
- restarts 0;
- health 200;
- critical logs 10m = 0;
- runtime marker "QUALITE HUMAINE KEYBUZZ" = OK.

## PROD baseline

API PROD runtime actuel:

ghcr.io/keybuzzio/keybuzz-api:v3.5.278-playbook-trial-metadata-repair-prod

Digest:

sha256:83b9d2388b2e350c4c41bd647bb1104eaf12bac95e06755cad97b671c56b700f

Source baseline:

5656987a09b3b38e8dc5025d1d2d4de255e46406

Etat:

- manifest = ghcr.io/keybuzzio/keybuzz-api:v3.5.278-playbook-trial-metadata-repair-prod;
- deployment spec = ghcr.io/keybuzzio/keybuzz-api:v3.5.278-playbook-trial-metadata-repair-prod;
- pod image = ghcr.io/keybuzzio/keybuzz-api:v3.5.278-playbook-trial-metadata-repair-prod;
- last-applied = ghcr.io/keybuzzio/keybuzz-api:v3.5.278-playbook-trial-metadata-repair-prod;
- ready 1/1;
- generation 438/438;
- restarts 0;
- health 200;
- critical logs 10m = 0;
- marker "QUALITE HUMAINE KEYBUZZ" absent, attendu avant promotion.

## Registry readiness

Tag DEV valide:

ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-dev

Tag PROD cible propose:

ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-prod

Registry:

- DEV tag existe: oui.
- PROD target tag existe: non, status 1, donc disponible.
- latest existe mais ne doit pas etre modifie.

## Image PROD a builder

Build PROD recommande:

ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-prod

Source exacte:

f030088d9132d85d955558d1850b2ec8085f7da0

Build rules:

- build-from-git uniquement;
- worktree/clone propre;
- commit deja pousse;
- tag immuable;
- OCI revision = f030088d9132d85d955558d1850b2ec8085f7da0;
- latest interdit;
- audit image obligatoire:
  - QUALITE HUMAINE KEYBUZZ present;
  - "pas comme un chatbot" present;
  - Autopilot branche sur getWritingRules;
  - dist/tests absent;
  - StartTrial/Purchase/CompletePayment non touches.

## GitOps PROD propose

Manifest a modifier uniquement apres build/push:

k8s/keybuzz-api-prod/deployment.yaml

Changement attendu:

- de: ghcr.io/keybuzzio/keybuzz-api:v3.5.278-playbook-trial-metadata-repair-prod
- vers: ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-prod

Rollback:

ghcr.io/keybuzzio/keybuzz-api:v3.5.278-playbook-trial-metadata-repair-prod

Rollback GitOps uniquement:

- modifier manifest;
- commit;
- push;
- kubectl apply -f;
- rollout status;
- verifier manifest = last-applied = spec = pod image.

Interdit:

- kubectl set image;
- kubectl patch;
- kubectl edit;
- kubectl set env.

## Services non touches

Constats read-only:

| Service | Runtime observe |
|---|---|
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.269-eslint-toolchain-post-oauth-trial-readiness-prod |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.268-post-oauth-trial-readiness-dev |
| Website PROD | ghcr.io/keybuzzio/keybuzz-website:v0.7.3-no-card-launch-pricing-prod |
| Admin PROD | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod |

Ces services ne sont pas dans le scope de promotion PH-21.199/200.

## AI feature parity / anti-regression

La promotion PROD doit preserver:

- AI Assist manuel;
- brouillons Autopilot;
- contrat JSON Autopilot;
- KBActions;
- playbooks;
- Agent KeyBuzz;
- human approval queue;
- no-reply classifier;
- false promise detection;
- refund protection;
- marketplace/Amazon guard;
- signatures tenant;
- budget/credits;
- logs/audit.

Verification runtime post-apply obligatoire:

- API health 200;
- ready 1/1;
- restarts 0;
- marker "QUALITE HUMAINE KEYBUZZ" present;
- Autopilot getWritingRules present;
- critical logs 0;
- no LLM live test;
- no fake conversation.

## No fake metrics / no fake events

Interdits pour la suite:

- aucun appel LLM live pendant build/apply/verify;
- aucun POST /funnel/event;
- aucun CAPI;
- aucun checkout;
- aucun fake StartTrial/Purchase/CompletePayment;
- aucun trigger Autopilot reel;
- aucune mutation DB volontaire.

## Risques

| Risque | Mitigation |
|---|---|
| Reponse plus humaine mais moins safe | Guardrails, marketplace policy, false promise detection et refund protection restent presents. |
| Regression Autopilot JSON | Tests PH-21.193 et audit runtime getWritingRules. |
| Divergence DEV/PROD | Build PROD depuis meme source f030088d et meme audit image. |
| Tag reuse | Target tag PROD absent avant build/push. |
| GitOps drift | Apply strict via manifest, puis equality manifest/last-applied/spec/pod. |

## Verdict

READY_FOR_BUILD_PROD.

La promotion PROD est prete pour la phase build, avec source f030088d, tag cible disponible, runtime PROD stable, rollback documente, et sans dette bloquante.

Prochain GO exact:

GO BUILD API AI RESPONSE HUMANNESS AND AUTO DRAFT QUALITY PROD PH-SAAS-T8.12AS.21.200

STOP.
