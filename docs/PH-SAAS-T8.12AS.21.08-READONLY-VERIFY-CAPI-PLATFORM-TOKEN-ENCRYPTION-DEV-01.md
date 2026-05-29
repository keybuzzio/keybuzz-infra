# PH-SAAS-T8.12AS.21.08 - Read-only verify CAPI platform token encryption DEV

Date UTC: 2026-05-29
Executor: Codex Executor
Scope: verification runtime / DB read-only / plan backfill non execute. Aucun backfill, aucune DB mutation, aucun event tracking.

## Verdict

GO READONLY VERIFY CAPI PLATFORM TOKEN ENCRYPTION DEV READY PH-SAAS-T8.12AS.21.08

## Objectif

Verifier en lecture seule que l'API DEV deployee en PH-21.07 contient le patch PH-21.02 / PH-21.04:

- chiffrement futur de `outbound_conversion_destinations.platform_token_ref` present en runtime;
- lecture provider compatible `aes256gcm` et plaintext legacy presente;
- API response masking present dans le code runtime compile;
- `/app/dist/tests` absent;
- fake tokens de test absents;
- `ADS_ENCRYPTION_KEY` reference presente sans afficher sa valeur;
- aucun backfill, aucune DB mutation, aucun event tracking.

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.08_CODEX_EXECUTOR_MISSION.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.07_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.06_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.05_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.02_CE_RETURN.md` | lu |
| `docs/PH-SAAS-T8.12AS.21.02-SOURCE-PATCH-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` | lu |
| `docs/PH-SAAS-T8.12AS.21.07-APPLY-API-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` | lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | lu |
| `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` | lu |
| `AI_MEMORY/CURRENT_STATE.md` | lu |

## Preflight

| Point | Resultat | Verdict |
| --- | --- | --- |
| Bastion | `install-v3` | OK |
| IPv4 obligatoire | `46.62.171.61` | OK |
| IP interdite `51.159.99.247` | non utilisee | OK |
| Date UTC bastion | `2026-05-29T13:35:22Z` | OK |
| Infra branch | `main` | OK |
| Infra HEAD/origin | `15f9479` / `15f9479` | OK |
| Infra ahead/behind | `0 0` | OK |
| Infra dirty avant rapport | `0` | OK |
| API branch | `ph147.4/source-of-truth` | OK |
| API HEAD/origin | `9797bedf` / `9797bedf` | OK |
| API ahead/behind | `0 0` | OK |
| API dirty hors `dist/` | `0` | OK |

## Runtime

| Env | Service | Image | ImageID digest | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| DEV | `keybuzz-api` | `v3.5.261-capi-platform-token-encryption-dev` | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` | `1/1` | `0` | OK |
| PROD | `keybuzz-api` | `v3.5.260-amazon-inbound-address-sync-prod` | `sha256:778f7556c5aa187be21b8a72a5246594c83e561c68abfaa053600fa7cbda43b8` | `1/1` | `0` | OK, inchangee |

DEV spec image = DEV last-applied image = DEV pod image = image cible PH-21.07.

## Runtime markers DEV

| Marker/check | Attendu | Resultat |
| --- | --- | --- |
| `/app/dist/server.js` | present | present |
| `/app/dist/tests` | absent | absent |
| `meta_test_token` / `tiktok_test_token` / `linkedin_test_token` / fake key PH-21.02 | absent | `fake_token_files=0` |
| `platform-token-crypto` | present | PRESENT |
| `encryptOutboundPlatformTokenForStorage` | present | PRESENT |
| `decryptOutboundPlatformTokenForProvider` | present | PRESENT |
| `prepareOutboundPlatformTokenUpdate` | present | PRESENT |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | present | PRESENT |
| `aes256gcm` | present | PRESENT |
| `ADS_ENCRYPTION_KEY` reference | present sans valeur | PRESENT |
| `platform_token_ref` | present | PRESENT |
| `redactSecrets` | present | PRESENT |

## DB read-only token inventory DEV

Execution: Node in-pod avec transaction `BEGIN READ ONLY`, requetes `SELECT` uniquement, puis `ROLLBACK`. Aucune valeur token affichee.

| Controle global | Resultat |
| --- | ---: |
| `outbound_conversion_destinations` total | 9 |
| `platform_token_ref IS NOT NULL` | 5 |
| `platform_token_ref LIKE 'aes256gcm:%'` | 0 |
| Plaintext legacy | 5 |
| `is_active = true` | 1 |
| `is_active != true` | 8 |
| `deleted_at IS NOT NULL` | 8 |

| destination_type | active | inactive | token_non_null | encrypted | plaintext_legacy | deleted | verdict |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `linkedin_capi` | 1 | 0 | 1 | 0 | 1 | 0 | backfill DEV requis plus tard |
| `meta_capi` | 0 | 3 | 3 | 0 | 3 | 3 | backfill DEV requis plus tard |
| `tiktok_events` | 0 | 1 | 1 | 0 | 1 | 1 | backfill DEV requis plus tard |
| `webhook` | 0 | 4 | 0 | 0 | 0 | 4 | token-neutral |

Backfill candidates DEV: `5`.

## API response masking read-only

Route cible: `/outbound-conversions/destinations`.

Verification effectuee sans appeler la route HTTP:

| Check runtime compile | Resultat |
| --- | --- |
| `sanitizeDestinationRow` present | PRESENT |
| `platform_token_ref` passe par `maskOutboundPlatformToken` | PRESENT |
| La route list renvoie `result.rows.map(sanitizeDestinationRow)` | PRESENT |
| Constante mask | `(encrypted)` |
| Legacy plaintext sample masque avec asterisques | true |
| `null` reste `null` | true |

La route HTTP n'a pas ete appelee volontairement. Raison: le hook runtime `ensureDestinationTables()` est present sur `onRequest` et peut executer des DDL idempotents (`CREATE TABLE IF NOT EXISTS`, `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`) si l'etat in-memory est froid. Comme PH-21.08 interdit toute DB mutation et tout `ALTER`, la preuve a ete limitee au code compile runtime et au helper execute localement dans le pod.

Conclusion masking: le code runtime actif masque `platform_token_ref` dans la reponse list. Aucune valeur token brute n'a ete lue ou affichee.

## No unintended processing

| Compteur DEV | Before | After | Delta |
| --- | ---: | ---: | ---: |
| `outbound_conversion_delivery_logs` | 7 | 7 | 0 |
| `conversion_events` | 0 | 0 | 0 |
| `ai_actions_ledger` | 550 | 550 | 0 |
| `ai_suggestion_events` | 2728 | 2728 | 0 |
| `outbound_deliveries` | 310 | 310 | 0 |

Logs runtime:

| Controle | Resultat |
| --- | --- |
| Pod lu | `keybuzz-api-5b6cc7fff9-hdg58` |
| `kubectl logs` status | `0` |
| Occurrence brute du mot `error` | 1 |
| Ligne sanitisee | `[OCTOPIA-SYNC] Completed: tenants=0 imported=0 skipped=0 errors=0` |
| Erreur critique reelle | 0 |

## Backfill DEV plan PH-21.09 - non execute

Plan uniquement. Aucune commande de mutation prete a coller n'est fournie ici.

1. Preflight PH-21.09
   - verifier bastion `install-v3` / `46.62.171.61`;
   - verifier runtime DEV toujours `v3.5.261-capi-platform-token-encryption-dev`;
   - verifier `ADS_ENCRYPTION_KEY` presente par reference uniquement, sans valeur;
   - verifier DB reachable depuis le pod API DEV.

2. Snapshot before
   - compter total `outbound_conversion_destinations`;
   - compter tokens non null;
   - compter tokens deja `aes256gcm:%`;
   - compter candidats plaintext legacy avec le critere `platform_token_ref IS NOT NULL AND NOT LIKE 'aes256gcm:%'`;
   - compter par `destination_type`, `is_active`, `deleted_at`;
   - sauvegarder les identifiants techniques et checksums token-safe, sans afficher de token.

3. Backup / garde-fous
   - creer un snapshot export token-safe ou backup DB selon protocole infra approuve;
   - ne pas afficher les valeurs `platform_token_ref`;
   - produire un fichier de controle avec counts et hashes non reversibles si necessaire;
   - STOP si count candidat differe fortement de PH-21.08 sans explication.

4. Execution applicative
   - executer via helper applicatif/runtime, pas par transformation SQL ad hoc;
   - utiliser le meme helper que le runtime: `encryptOutboundPlatformTokenForStorage`;
   - executer dans une transaction controlee;
   - chiffrer uniquement les lignes candidates plaintext legacy;
   - ne jamais declencher provider, test endpoint CAPI, outbound delivery ou event tracking;
   - logger uniquement counts, ids techniques si necessaires et statuts, jamais les tokens.

5. Verification after
   - verifier count plaintext legacy -> `0`;
   - verifier count encrypted augmente de `5` si aucun changement intercurrent;
   - verifier total rows stable;
   - verifier decrypt possible via helper applicatif sur echantillon controle, sans appeler Meta/TikTok/LinkedIn et sans afficher plaintext;
   - verifier list response masking par code/runtime ou route si garantie sans DDL mutation;
   - verifier counters outbound/conversion inchanges.

6. Rollback strategy
   - pas de downgrade automatique;
   - restauration uniquement sous GO explicite de Ludovic si echec;
   - utiliser le backup/snapshot approuve;
   - ne jamais restaurer depuis logs, rapport ou sortie terminal;
   - documenter count avant/apres et raison exacte du rollback.

7. Rapport PH-21.09
   - rapport ASCII/no BOM;
   - counts before/after;
   - preuve no event/no provider;
   - preuve no secret;
   - decision restante sur rotation token DEV.

## Hors scope respecte

| Interdit | Resultat |
| --- | --- |
| SQL UPDATE/INSERT/DELETE/ALTER | non execute |
| Backfill | non execute |
| Deploy | non execute |
| Kubectl mutation | non execute |
| Docker build/push | non execute |
| Event tracking | non execute |
| Test endpoint CAPI | non execute |
| Secret/token/env value dans logs | non affiche |
| Linear mutation | non execute |
| PROD mutation | non execute |

## Livrables

| Livrable | Chemin |
| --- | --- |
| Rapport infra | `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.08-READONLY-VERIFY-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` |
| Retour CE | `C:\DEV\KeyBuzz\tmp\PH-21.08_CE_RETURN.md` |

## Conclusion

Le runtime API DEV contient bien le patch CAPI platform token encryption, les tests runtime ne sont pas embarques, les fake tokens sont absents, les helpers de chiffrement/dechiffrement/masking sont presents et actifs dans le code compile. L'inventaire DB DEV montre `5` tokens legacy plaintext a backfiller dans une phase dediee PH-21.09, non executee ici. Les compteurs read-only sont inchanges, aucun event ou delivery n'a ete cree, et PROD est inchangee.

Phrase finale:

GO READONLY VERIFY CAPI PLATFORM TOKEN ENCRYPTION DEV READY PH-SAAS-T8.12AS.21.08

STOP.
