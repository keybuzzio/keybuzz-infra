# Fix Octopia Aggregator Client ID — Report

## Probleme
La modale "Connecter Octopia" affichait `YOUR_KEYBUZZ_CLIENT_ID` comme placeholder
au lieu du vrai nom d'aggregateur enregistre aupres d'Octopia.

## Cause racine
`octopia.routes.ts` ligne 29 :
```typescript
const KEYBUZZ_AGGREGATOR_CLIENT_ID = process.env.OCTOPIA_CLIENT_ID || 'YOUR_KEYBUZZ_CLIENT_ID';
```
`OCTOPIA_CLIENT_ID` est le **secret API OAuth** (UUID), pas le nom visible par le vendeur.

## Fix
```typescript
// Aggregator display name as registered with Octopia (visible to sellers in Seller Portal).
// NOT the API client_id used for OAuth — that one is in OCTOPIA_CLIENT_ID env var.
const KEYBUZZ_AGGREGATOR_CLIENT_ID = 'KeyBuzz';
```

## Fichier modifie
`keybuzz-api/src/modules/marketplaces/octopia/octopia.routes.ts` (ligne 28-30)

## Verification placeholder residuel
```
grep YOUR_KEYBUZZ_CLIENT_ID keybuzz-api/ → 0 resultats
grep YOUR_KEYBUZZ_CLIENT_ID keybuzz-client/ → 0 resultats
```

## Validation

| Env | keybuzzClientId | step3 | Statut |
|-----|-----------------|-------|--------|
| DEV | `KeyBuzz` | "collez: KeyBuzz" | PASS |
| PROD | `KeyBuzz` | "collez: KeyBuzz" | PASS |

## Tags

| Composant | DEV | PROD |
|-----------|-----|------|
| API | `v3.4.1-fix-octopia-clientid-dev` | `v3.4.1-fix-octopia-clientid-prod-1` |
| Digest | `sha256:82b23fdc...` | `sha256:82b23fdc...` (meme image) |

## Rollback PROD
`ghcr.io/keybuzzio/keybuzz-api:v3.4.1-ph343-sender-policy-prod-1`

## Git
Commit `8a79327` — `[PROD-APPROVED] Fix Octopia aggregator clientId`

Date: 2026-02-18
