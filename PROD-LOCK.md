# PROD-LOCK.md

## REGLE ABSOLUE

Tout commit touchant k8s/*-prod/* DOIT contenir le tag [PROD-APPROVED] dans le message.

Exemples:
- OK: [PROD-APPROVED] Fix critical bug in prod
- KO: Fix critical bug in prod

## Images PROD validees

### Client PROD
ghcr.io/keybuzzio/keybuzz-client:ph29.7e-prod-debug-2026-02-05

### API PROD
ghcr.io/keybuzzio/keybuzz-api:api-prod-full-2026-02-05a

## Derniere mise a jour
2026-02-05 - PH29.7B Rollback
