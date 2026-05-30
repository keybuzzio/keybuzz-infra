# PH-SAAS-T8.12AS.21.14 - Backfill CAPI platform tokens PROD

## Verdict

GO BACKFILL CAPI PLATFORM TOKENS PROD DONE PH-SAAS-T8.12AS.21.14

Le backfill PROD de `outbound_conversion_destinations.platform_token_ref` a ete execute avec succes.

Point critique rollback: apres ce commit DB, ne pas rollback vers une API pre-v3.5.261 sans plan explicite de restauration/compatibilite, car les anciens runtimes ne savent pas lire les tokens `aes256gcm`.

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.14_CODEX_EXECUTOR_MISSION.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.13_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.12_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.11_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.09_CE_RETURN.md` | lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | lu |
| `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` | lu |

## Preflight

| Controle | Resultat |
| --- | --- |
| Bastion | `install-v3` |
| IPv4 | `46.62.171.61` |
| IP interdite `51.159.99.247` | non observee |
| API branch | `ph147.4/source-of-truth` |
| API HEAD / origin | `9797bedf` / `9797bedf` |
| API dirty hors `dist` | 0 |
| Infra branch | `main` |
| Infra HEAD / origin avant rapport | `5269a07` / `5269a07` |
| Infra dirty avant rapport | 0 |

## Runtime

| Environnement | Image | Digest | Ready | Restarts |
| --- | --- | --- | --- | ---: |
| PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod` | `sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5` | `1/1` | 0 |
| DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev` | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` | `1/1` | 0 |

PROD runtime spec image = last-applied image = pod image digest cible.

## Helper runtime

| Controle | Resultat |
| --- | --- |
| Module | `/app/dist/modules/outbound-conversions/platform-token-crypto.js` |
| Exports | `OUTBOUND_PLATFORM_TOKEN_MASK`, `decryptOutboundPlatformTokenForProvider`, `encryptOutboundPlatformTokenForStorage`, `isMaskedOutboundPlatformToken`, `maskOutboundPlatformToken`, `prepareOutboundPlatformTokenUpdate` |
| `ADS_ENCRYPTION_KEY` | present |
| DB | `keybuzz_prod` |
| Schema | `public` |

Aucune valeur de token, cle ou connection string n'a ete affichee.

## Snapshot before

| destination_type | active | inactive | token_non_null | encrypted | plaintext_legacy |
| --- | ---: | ---: | ---: | ---: | ---: |
| `linkedin_capi` | 1 | 0 | 1 | 0 | 1 |
| `meta_capi` | 1 | 6 | 7 | 0 | 7 |
| `tiktok_events` | 1 | 2 | 3 | 0 | 3 |
| `webhook` | 0 | 3 | 0 | 0 | 0 |

Global before: total 14, token non null 11, encrypted 0, plaintext legacy 11, masked 0.

Distribution cible: 1 LinkedIn, 7 Meta, 3 TikTok.

## Backfill transactionnel

| Controle | Resultat |
| --- | --- |
| Mode | Node in-pod API PROD |
| Transaction | `BEGIN` -> controles -> `COMMIT` |
| Target rows | 11 |
| Updated rows | 11 |
| Decrypt avant commit | 11/11 |
| Decrypt in-transaction apres update | 11/11 |
| Format ecrit | `aes256gcm:` |
| `max(updated_at)` avant | `2026-05-01 11:13:53.745734+00` |
| `max(updated_at)` apres | `2026-05-01 11:13:53.745734+00` |

IDs traites, sans token brut:

| id | tenant_id | destination_type | active | token_sha256_12 |
| --- | --- | --- | --- | --- |
| `b530ffdc-9415-4072-8bae-5f34087076c2` | `keybuzz-consulting-mo9zndlk` | `linkedin_capi` | true | `6749ae93779d` |
| `28cbc2be-489a-4f22-a5a8-228d0c0d6551` | `ecomlg-001` | `meta_capi` | false | `e3bc4f665463` |
| `291a5797-fdcd-4449-8a10-ffa52270c7a8` | `ecomlg-001` | `meta_capi` | false | `e3bc4f665463` |
| `4b7ae65e-292d-4c02-b41a-3b8dd31264f1` | `ecomlg-001` | `meta_capi` | false | `8c1f0f420a36` |
| `7464753d-ce0f-4b47-9b4a-ac8baa619db5` | `ecomlg-001` | `meta_capi` | false | `4ead4d0e5b69` |
| `87f8dc49-5f62-460d-971e-2243c77e1192` | `keybuzz-consulting-mo9zndlk` | `meta_capi` | true | `f84be814391e` |
| `ba40f5ce-5209-441f-bde4-39719711ed81` | `ecomlg-001` | `meta_capi` | false | `13dab8cfdc07` |
| `f768d05f-5d0c-46ab-ac82-0587e622923f` | `keybuzz-consulting-mo9zndlk` | `meta_capi` | false | `ab3e377829f0` |
| `07b03162-7e5b-4751-8425-e9528faa3562` | `keybuzz-consulting-mo9zndlk` | `tiktok_events` | false | `e6131ea7a112` |
| `75a3c56a-2508-4fa9-ab12-6b1514951877` | `keybuzz-consulting-mo9zndlk` | `tiktok_events` | true | `431f118c63a9` |
| `d5832725-060e-4e10-8969-3043fa3f4745` | `keybuzz-consulting-mo9zndlk` | `tiktok_events` | false | `db0a3b8a3379` |

## Snapshot after

| destination_type | active | inactive | token_non_null | encrypted | plaintext_legacy |
| --- | ---: | ---: | ---: | ---: | ---: |
| `linkedin_capi` | 1 | 0 | 1 | 1 | 0 |
| `meta_capi` | 1 | 6 | 7 | 7 | 0 |
| `tiktok_events` | 1 | 2 | 3 | 3 | 0 |
| `webhook` | 0 | 3 | 0 | 0 | 0 |

Global after: total 14, token non null 11, encrypted 11, plaintext legacy 0, masked 0.

Verification read-only apres commit:

- encrypted rows: 11
- decrypt in-memory OK: 11/11
- rollback read-only: OK
- provider endpoint appele: non
- token affiche: non

## No side effect

| Compteur PROD | Before PH-21.14 | After PH-21.14 | Delta |
| --- | ---: | ---: | ---: |
| `outbound_conversion_delivery_logs` | 19 | 19 | 0 |
| `conversion_events` | 3 | 3 | 0 |
| `ai_actions_ledger` | 277 | 277 | 0 |
| `ai_suggestion_events` | 3642 | 3642 | 0 |
| `outbound_deliveries` | 314 | 314 | 0 |

`PH2112_LOG_CRITICAL_PATTERN_COUNT=0`.

## Interdits respectes

| Interdit | Resultat |
| --- | --- |
| build Docker | non |
| push image | non |
| deploy / GitOps apply | non |
| `kubectl set image/env`, `patch`, `edit` | non |
| provider event / test endpoint CAPI | non |
| event tracking artificiel | non |
| token rotation | non |
| Linear mutation | non |
| source/API modification | non |
| Git source push | non |
| `/opt/keybuzz/credentials` ou `/opt/keybuzz/secrets` | non touches |
| token brut / cle / connection string dans logs | non |

## Rollback lock

Apres `COMMIT`, `platform_token_ref` contient 11 valeurs `aes256gcm`.

Rollback autorise uniquement vers un runtime API compatible avec PH-21.02 / v3.5.261 ou hotfix descendant capable de lire `aes256gcm`.

Rollback interdit sans plan explicite: API pre-v3.5.261, pre-PH-21.02, ou tout runtime qui ne sait pas dechiffrer `aes256gcm`.

Aucun downgrade automatique DB vers plaintext n'est prevu ni execute.

## Conclusion

PH-21.14 est terminee: PROD est maintenant chiffre, decrypt-safe, et sans legacy plaintext residuel dans `outbound_conversion_destinations.platform_token_ref`.

STOP.
