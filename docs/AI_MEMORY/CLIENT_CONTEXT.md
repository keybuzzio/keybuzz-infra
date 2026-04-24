# Contexte Client SaaS KeyBuzz

> Derniere mise a jour : 2026-04-21
> Role : point d'entree pour les taches `client` / `client-dev`.

## Surface

Chemin local principal : `C:\DEV\KeyBuzz\V3`

Stack observee :

- Next.js 14.2.x
- React 18
- TypeScript
- NextAuth
- Tailwind

Hosts :

- DEV : `client-dev.keybuzz.io`
- PROD : `client.keybuzz.io`

Manifests :

- DEV : `C:\DEV\KeyBuzz\V3\keybuzz-infra\k8s\keybuzz-client-dev`
- PROD : `C:\DEV\KeyBuzz\V3\keybuzz-infra\k8s\keybuzz-client-prod`

## Pages principales

Routes detectees dans `app` :

- `/inbox`
- `/orders`
- `/channels`
- `/playbooks`
- `/settings`
- `/billing`
- `/ai-dashboard`
- `/ai-journal`
- `/knowledge`
- `/suppliers`
- `/onboarding`
- `/start`
- `/register`
- `/select-tenant`

## BFF Next.js

Routes detectees dans `app/api` :

- `agents`
- `ai`
- `amazon`
- `attachments`
- `auth`
- `autopilot`
- `billing`
- `channel-rules`
- `channels`
- `conversations`
- `dashboard`
- `invite`
- `octopia`
- `orders`
- `playbooks`
- `returns`
- `roles`
- `shopify`
- `space-invites`
- `stats`
- `supplier-cases`
- `suppliers`
- `teams`
- `tenant-context`
- `tenant-lifecycle`
- `tenant-settings`
- `v1`

## Points sensibles

- Beaucoup de bugs historiques viennent du BFF : mauvais forwarding, `X-Tenant-Id` absent, headers auth incomplets, endpoint API incorrect.
- `NEXT_PUBLIC_*` est build-time : ne pas re-tag une image DEV pour PROD si l'URL API doit changer.
- Inbox est fragile : plusieurs reconstructions PH154 ont corrige visuel/API mais demandent validation humaine.
- Les changements client doivent etre recoupes avec PH152/PH153/PH154 si la zone touche Inbox, source-of-truth ou rebuild.

## Rapports a lire selon tache

- Inbox/client : `PH154-INBOX-CONTEXT-CLEAN-REBUILD-01.md`, `PH154.1.2-INBOX-PIXEL-TARGET-REBUILD-01.md`, `PH154.1.3-INBOX-VISUAL-PARITY-FIX-STRICT-01.md`
- Source Git/runtime : `PH152-GIT-SOURCE-OF-TRUTH-LOCK-01.md`, `PH152.1-DEV-TRUTH-RECONSTRUCTION-FROM-PROD-AND-REPORTS-01.md`
- Autopilot client/BFF : `PH-AUTOPILOT-E2E-TRUTH-AUDIT-01.md`
- Plans/features : `FEATURE_TRUTH_MATRIX_V2.md`

## Regle pratique

Avant de patcher le client :

1. Identifier si la route est page front ou BFF.
2. Lire le dernier rapport du domaine.
3. Verifier les envs build-time.
4. Patch minimal.
5. DEV avant PROD.
6. Documenter image, validation et rollback.
