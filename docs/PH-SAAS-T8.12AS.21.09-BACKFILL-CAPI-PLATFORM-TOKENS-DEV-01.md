# PH-SAAS-T8.12AS.21.09 - Backfill CAPI platform tokens DEV

Date UTC: 2026-05-29
Executor: Codex Executor
Scope: mutation DB DEV controlee uniquement. Aucun provider event, aucun deploy, aucune PROD.

## Verdict

GO BACKFILL CAPI PLATFORM TOKENS DEV READY PH-SAAS-T8.12AS.21.09

## Objectif

Chiffrer en DEV les 5 tokens legacy en clair identifies en PH-21.08 dans:

`outbound_conversion_destinations.platform_token_ref`

Contraintes respectees:

- helper runtime PH-21.02 utilise;
- format cible `aes256gcm:...`;
- transaction controlee;
- verification decrypt avant commit;
- aucune valeur token affichee;
- aucun provider event;
- PROD inchangee.

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.09_CODEX_EXECUTOR_MISSION.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.08_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.07_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.02_CE_RETURN.md` | lu |
| `docs/PH-SAAS-T8.12AS.21.02-SOURCE-PATCH-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` | lu |
| `docs/PH-SAAS-T8.12AS.21.07-APPLY-API-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` | lu |
| `docs/PH-SAAS-T8.12AS.21.08-READONLY-VERIFY-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` | lu via retour et rapport |
| `AI_MEMORY/RULES_AND_RISKS.md` | lu |
| `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` | lu |

## Preflight

| Point | Resultat | Verdict |
| --- | --- | --- |
| Bastion | `install-v3` | OK |
| IPv4 obligatoire | `46.62.171.61` | OK |
| IP interdite `51.159.99.247` | non utilisee | OK |
| Date UTC bastion | `2026-05-29T14:23:09Z` | OK |
| Infra branch | `main` | OK |
| Infra HEAD/origin avant rapport | `63df636` / `63df636` | OK |
| Infra ahead/behind | `0 0` | OK |
| Infra dirty avant rapport | `0` | OK |
| API branch | `ph147.4/source-of-truth` | OK |
| API HEAD/origin | `9797bedf` / `9797bedf` | OK |
| API ahead/behind | `0 0` | OK |
| API dirty hors `dist/` | `0` | OK |

## Runtime

| Env | Service | Image | ImageID | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| DEV | `keybuzz-api` | `v3.5.261-capi-platform-token-encryption-dev` | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` | `1/1` | `0` | OK |
| PROD | `keybuzz-api` | `v3.5.260-amazon-inbound-address-sync-prod` | `sha256:778f7556c5aa187be21b8a72a5246594c83e561c68abfaa053600fa7cbda43b8` | `1/1` | `0` | OK, inchangee |

Runtime DEV spec image = last-applied image = pod image cible.

## Runtime helpers

| Check | Resultat |
| --- | --- |
| `/app/dist/server.js` | present |
| `/app/dist/tests` | absent |
| Fake tokens PH-21.02 | `0` |
| `platform-token-crypto` | PRESENT |
| `encryptOutboundPlatformTokenForStorage` | PRESENT |
| `decryptOutboundPlatformTokenForProvider` | PRESENT |
| `prepareOutboundPlatformTokenUpdate` | PRESENT |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | PRESENT |
| `aes256gcm` | PRESENT |
| `ADS_ENCRYPTION_KEY` reference | PRESENT, valeur non affichee |
| `redactSecrets` | PRESENT |

## Snapshot before read-only

Transaction `BEGIN READ ONLY`, puis `ROLLBACK`. Aucune valeur token affichee.

| Controle global | Before |
| --- | ---: |
| total destinations | 9 |
| token non null | 5 |
| encrypted | 0 |
| plaintext legacy cible | 5 |
| active | 1 |
| inactive | 8 |
| deleted | 8 |
| max `updated_at` | `2026-04-27 15:38:25.603612+00` |

| destination_type | active | inactive | token_non_null | encrypted | plaintext_legacy |
| --- | ---: | ---: | ---: | ---: | ---: |
| `linkedin_capi` | 1 | 0 | 1 | 0 | 1 |
| `meta_capi` | 0 | 3 | 3 | 0 | 3 |
| `tiktok_events` | 0 | 1 | 1 | 0 | 1 |
| `webhook` | 0 | 4 | 0 | 0 | 0 |

Candidate hashes, token-safe:

| id_hash | destination_type | active | deleted |
| --- | --- | --- | --- |
| `e7a7d3898d47` | `linkedin_capi` | true | false |
| `3554b50ddbf5` | `meta_capi` | false | true |
| `85d743fd936e` | `meta_capi` | false | true |
| `f0b494762702` | `meta_capi` | false | true |
| `448d456a8b5c` | `tiktok_events` | false | true |

Target count = 5, conforme PH-21.08 et mission PH-21.09.

## Script backfill

Execution dans le pod API DEV, avec env DB runtime sans affichage.

Le script:

- importe `/app/dist/modules/outbound-conversions/platform-token-crypto.js`;
- verifie `encryptOutboundPlatformTokenForStorage`, `decryptOutboundPlatformTokenForProvider`, `isMaskedOutboundPlatformToken`;
- ouvre une transaction SQL;
- selectionne uniquement les lignes candidates avec:
  - `platform_token_ref IS NOT NULL`;
  - `btrim(platform_token_ref) <> ''`;
  - `platform_token_ref NOT LIKE 'aes256gcm:%'`;
  - exclusion `(encrypted)`, `[REDACTED_TOKEN]`, `****`, valeurs contenant `*`;
- garde le plaintext en memoire uniquement;
- chiffre chaque valeur via helper runtime;
- verifie prefix `aes256gcm:`;
- verifie que le ciphertext ne contient pas le plaintext;
- verifie `decrypt(encrypted) == plaintext` en memoire;
- update uniquement `platform_token_ref`;
- requery dans la meme transaction;
- commit seulement si plaintext legacy = 0, encrypted = 5, decrypt OK.

Aucun token brut, aucune cle, aucune connection string n'a ete affiche.

## Execution backfill DEV

| Controle | Resultat |
| --- | --- |
| Scope | `DEV_ONLY` |
| Helper runtime | OK |
| Transaction | `BEGIN` |
| Before in transaction | total 9, token non null 5, encrypted 0, plaintext legacy 5 |
| Target rows | 5 |
| Updated rows | 5 |
| After in transaction | total 9, token non null 5, encrypted 5, plaintext legacy 0 |
| Decrypt verified before commit | 5 |
| Transaction finale | `COMMIT` |

Rows updatees, token-safe:

| id_hash | destination_type | active | deleted |
| --- | --- | --- | --- |
| `e7a7d3898d47` | `linkedin_capi` | true | false |
| `3554b50ddbf5` | `meta_capi` | false | true |
| `85d743fd936e` | `meta_capi` | false | true |
| `f0b494762702` | `meta_capi` | false | true |
| `448d456a8b5c` | `tiktok_events` | false | true |

## Snapshot after read-only

Transaction `BEGIN READ ONLY`, puis `ROLLBACK`. Aucune valeur token affichee.

| Controle global | Before | After | Verdict |
| --- | ---: | ---: | --- |
| total destinations | 9 | 9 | OK |
| token non null | 5 | 5 | OK |
| encrypted | 0 | 5 | OK |
| plaintext legacy cible | 5 | 0 | OK |
| active | 1 | 1 | OK |
| inactive | 8 | 8 | OK |
| deleted | 8 | 8 | OK |
| max `updated_at` | `2026-04-27 15:38:25.603612+00` | `2026-04-27 15:38:25.603612+00` | OK, non modifie |

| destination_type | active | inactive | token_non_null | encrypted | plaintext_legacy |
| --- | ---: | ---: | ---: | ---: | ---: |
| `linkedin_capi` | 1 | 0 | 1 | 1 | 0 |
| `meta_capi` | 0 | 3 | 3 | 3 | 0 |
| `tiktok_events` | 0 | 1 | 1 | 1 | 0 |
| `webhook` | 0 | 4 | 0 | 0 | 0 |

## Decrypt readiness after commit

Verification read-only apres commit:

| Controle | Resultat |
| --- | --- |
| Transaction | `BEGIN READ ONLY` puis `ROLLBACK` |
| Encrypted rows lues | 5 |
| Decrypt in-memory OK | 5 |
| Provider endpoint appele | non |
| Token affiche | non |

Rows verifiees, token-safe:

| id_hash | destination_type | active | deleted |
| --- | --- | --- | --- |
| `e7a7d3898d47` | `linkedin_capi` | true | false |
| `3554b50ddbf5` | `meta_capi` | false | true |
| `85d743fd936e` | `meta_capi` | false | true |
| `f0b494762702` | `meta_capi` | false | true |
| `448d456a8b5c` | `tiktok_events` | false | true |

## API masking readiness

Route HTTP non appelee pour eviter tout hook DDL `ensureDestinationTables`. Verification runtime compilee:

| Check | Resultat |
| --- | --- |
| `sanitizeDestinationRow` runtime | PRESENT |
| `platform_token_ref` mappe vers `maskOutboundPlatformToken` | PRESENT |
| List route renvoie `result.rows.map(sanitizeDestinationRow)` | PRESENT |
| Constante mask | `(encrypted)` |
| Helper legacy sample masque avec `*` | true |
| `null` reste `null` | true |

## No side effect

| Compteur DEV | Before | After | Delta |
| --- | ---: | ---: | ---: |
| `outbound_conversion_delivery_logs` | 7 | 7 | 0 |
| `conversion_events` | 0 | 0 | 0 |
| `ai_actions_ledger` | 550 | 550 | 0 |
| `ai_suggestion_events` | 2728 | 2728 | 0 |
| `outbound_deliveries` | 310 | 310 | 0 |

| Interdit | Resultat |
| --- | --- |
| PROD mutation | non |
| Build Docker | non |
| Docker push | non |
| Deploy | non |
| `kubectl apply/set/patch/edit/env` | non |
| Test endpoint CAPI | non |
| Event Meta/TikTok/LinkedIn/Google | non |
| Rotation token | non |
| Token brut affiche | non |
| Plaintext sauvegarde dans fichier persistant | non |
| Linear mutation | non |
| Credentials/secrets paths | non touches |
| Source modifiee | non |
| Push Git source | non |

## Rollback / restoration

Le rollback automatique n'est pas applique apres commit et n'a pas ete necessaire.

Avant le commit, toute verification pouvait provoquer `ROLLBACK` transactionnel. Apres commit, une restauration ne doit etre envisagee que sous GO explicite de Ludovic et via procedure dediee, sans extraire les tokens depuis logs ou rapports. Aucun plaintext persistant n'a ete cree pendant PH-21.09.

## Livrables

| Livrable | Chemin |
| --- | --- |
| Rapport infra | `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.09-BACKFILL-CAPI-PLATFORM-TOKENS-DEV-01.md` |
| Retour CE | `C:\DEV\KeyBuzz\tmp\PH-21.09_CE_RETURN.md` |

## Conclusion

Le backfill DEV a chiffre les 5 tokens legacy en clair de `outbound_conversion_destinations.platform_token_ref` avec le helper runtime PH-21.02. Apres commit, il reste 0 plaintext legacy et 5 valeurs `aes256gcm:%`. Le decrypt in-memory des 5 valeurs chiffrees est OK, aucun provider event n'a ete declenche, les compteurs tracking/delivery sont inchanges, et PROD est restee strictement inchangee.

Phrase finale:

GO BACKFILL CAPI PLATFORM TOKENS DEV READY PH-SAAS-T8.12AS.21.09

STOP.
