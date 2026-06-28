# PH-SAAS-T8.12AS.21.179 - AIJournal startup DDL guard DEV/PROD

## Verdict

READY_CLOSED.

La dette runtime observee sur API PROD (`[AIJournal] Could not ensure table` / `must be owner of table ai_journal_events`) est corrigee en DEV puis promue en PROD.

## Objectif

Supprimer le warning AIJournal au demarrage API sans mutation schema inutile, sans changer les droits DB, sans casser les correctifs Amazon channel activation, onboarding trial, billing, tracking ou provider credit watcher.

## RCA

Le code API executait au demarrage des DDL `CREATE TABLE IF NOT EXISTS` et `CREATE INDEX IF NOT EXISTS` sur `ai_journal_events`.

La table existait deja en PROD, les indexes existaient deja, et l'utilisateur runtime `keybuzz_api_prod` avait les droits DML requis:

- table: `ai_journal_events`
- owner: `postgres`
- runtime user: `keybuzz_api_prod`
- can_select/can_insert/can_update/can_delete: true
- indexes existants: `ai_journal_events_pkey`, `idx_ai_journal_entity`, `idx_ai_journal_event_type`, `idx_ai_journal_level`, `idx_ai_journal_tenant`, `idx_ai_journal_tenant_timestamp`
- row_count: 19

La cause etait donc une tentative de DDL redondante sur une table owned par `postgres`, pas une panne fonctionnelle AIJournal.

## Source patch

Repo: `/opt/keybuzz/keybuzz-api`

Branch: `ph147.4/source-of-truth`

Commit source:

`b1b06a87b8b43c004f873ba9cdad01fba686e2e6 fix(ai): avoid redundant journal startup ddl`

Fichiers:

| Fichier | Changement | Risque |
|---|---|---|
| `src/modules/ai/ai-journal-routes.ts` | Ajoute detection `to_regclass('public.ai_journal_events')`; cree la table uniquement si absente; cree les indexes uniquement s'ils sont absents | Faible, startup path cible uniquement |
| `src/tests/ph21179-ai-journal-startup-ddl-tests.ts` | Verifie le guard DDL et la non-regression | Faible |

## Tests source

| Test | Resultat |
|---|---|
| `git diff --check` | PASS |
| `npx tsx src/tests/ph21179-ai-journal-startup-ddl-tests.ts` | PASS |
| `npx tsx src/tests/ph21177-activate-amazon-idempotent-tests.ts` | PASS |
| `npx tsx src/tests/ph21172-start-onboarding-fast-tests.ts` | PASS |
| `npx tsc --noEmit` | PASS |

## DEV

Image DEV:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.275-ai-journal-startup-ddl-dev`

Digest DEV:

`sha256:6f80254e810c5b6494e18b09743216c075fb9e31c7b16fb3b456788e3df7d530`

Image ID DEV:

`sha256:1321fae06c61f44d6da1cc20bee9a2f8b5fa547df5691c8f9a9a949397c05e8b`

GitOps DEV:

`04fe6077995b59ff9cd1450eb47686e1c2015ddf deploy(api-dev): apply ai journal startup ddl guard`

Runtime DEV:

| Controle | Resultat |
|---|---|
| image runtime | OK |
| digest pod | OK |
| manifest = last-applied = spec = pod | OK |
| health | OK |
| `to_regclass('public.ai_journal_events')` present | OK |
| `SELECT indexname FROM pg_indexes` present | OK |
| `Activated/confirmed` Amazon marker present | OK |
| `must be owner|Could not ensure table` logs | ABSENT |

## PROD

Image PROD:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.275-ai-journal-startup-ddl-prod`

Digest PROD:

`sha256:ad5950ee3bf86b7980fde0005a778565956ff1f6c931b2b8d6877f94b39157f8`

Image ID PROD:

`sha256:ebe6fc429263bdc66e1153889ee9df550aa4ae2aa8c1046880aae872930663aa`

GitOps PROD:

`d3dd9744e244b99e5a5ba75d74745224c480d773 deploy(api-prod): apply ai journal startup ddl guard`

Runtime PROD:

| Controle | Resultat |
|---|---|
| image runtime | `ghcr.io/keybuzzio/keybuzz-api:v3.5.275-ai-journal-startup-ddl-prod` |
| generation | `436/436` |
| pod | `keybuzz-api-79d94fd5df-wz5jj` |
| ready/restarts | `true/0` |
| pod digest | OK |
| manifest = last-applied = spec = pod | OK |
| health | OK |
| `to_regclass('public.ai_journal_events')` present | OK |
| `SELECT indexname FROM pg_indexes` present | OK |
| `Activated/confirmed` Amazon marker present | OK |
| `must be owner|Could not ensure table` logs | ABSENT |

## Non-regression Amazon

Read-only DB tenant `switaa-sasu-mqwuvv8z`:

| Controle | Resultat |
|---|---|
| tenant | `SWITAA SASU` |
| marketplace | `amazon-fr` |
| tenant channel status | `active` |
| billing_status | `included` |
| active_count | `1` |
| inbound connection | `READY` |
| inbound address exists | true |

## Repos final

| Repo | Branch | HEAD | Origin | Dirty |
|---|---|---|---|---|
| `/opt/keybuzz/keybuzz-api` | `ph147.4/source-of-truth` | `b1b06a87b8b43c004f873ba9cdad01fba686e2e6` | same | 0 |
| `/opt/keybuzz/keybuzz-infra` | `main` | `d3dd9744e244b99e5a5ba75d74745224c480d773` | same | 0 avant rapport |

## No side-effect

- Aucun secret lu/affiche.
- Aucun token affiche.
- Aucun fake event.
- Aucun POST `/funnel/event`.
- Aucun retry/replay CAPI.
- Aucun formulaire ou checkout.
- Aucune mutation DB volontaire.
- Aucun `kubectl set image`, `kubectl set env`, `kubectl patch`, `kubectl edit`.
- GitOps strict respecte.

## Rollback

Rollback GitOps possible en restaurant l'image precedente:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.274-amazon-channel-activation-idempotent-prod`

Digest precedent:

`sha256:7bec821136ff8d77056a2a3ce7050f923bb26240ec1bd4cca880eee14a3cbf1a`

Rollback uniquement par commit manifest + push + `kubectl apply -f`.

## Backlog produit

Amelioration future demandee par Ludovic: rendre les reponses IA et les brouillons IA auto-generes plus humains, avec un equivalent de consigne type `/humain` pour les providers dont OpenAI/ChatGPT. Hors scope PH-21.179, a traiter apres cloture des problemes techniques en cours.

## Verdict final

GO AIJOURNAL STARTUP DDL GUARD DEV PROD READY_CLOSED PH-SAAS-T8.12AS.21.179.

STOP.
