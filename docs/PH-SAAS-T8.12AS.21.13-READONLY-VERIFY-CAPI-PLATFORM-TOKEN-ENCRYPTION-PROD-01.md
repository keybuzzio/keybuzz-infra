# PH-SAAS-T8.12AS.21.13 - READONLY VERIFY CAPI PLATFORM TOKEN ENCRYPTION PROD

Date UTC : 2026-05-29
Projet : KeyBuzz SaaS
Service : keybuzz-api
Environnement : PROD runtime read-only
Type : verification runtime / DB read-only / plan backfill PROD non execute
Verdict : GO READONLY VERIFY CAPI PLATFORM TOKEN ENCRYPTION PROD ACTION_REQUIRED_AUTH PH-SAAS-T8.12AS.21.13

## Resume

Verification read-only PROD terminee apres deploiement PH-21.12.

Runtime PROD attendu confirme :

`ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod`

Runtime digest confirme :

`sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5`

Inventaire tokens PROD :

- destinations total : 14
- `platform_token_ref IS NOT NULL` : 11
- encrypted `aes256gcm:%` : 0
- plaintext legacy : 11

Aucune valeur token, cle, connection string, cookie ou authorization header n'a ete affichee. L'inventaire exact des lignes legacy utilise seulement `id`, `tenant_id`, `destination_type`, `is_active` et un hash court SHA-256 non reversible.

Limite : la verification HTTP authentifiee de la liste destinations n'a pas ete executee sans session/cookie reel. Le code runtime de masking est present, et l'appel non authentifie retourne `400`; la verification HTTP complete est donc classee `AUTH_REQUIRED`.

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.13_CODEX_EXECUTOR_MISSION.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.12_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.11_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.09_CE_RETURN.md` | lu |
| rapports PH-21.09 / 21.11 / 21.12 | lus via retours/docs |
| `AI_MEMORY/RULES_AND_RISKS.md` | lu |
| `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` | lu |

## Preflight

| Controle | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Bastion | `install-v3` | `install-v3` | OK |
| IPv4 | `46.62.171.61` | `46.62.171.61` | OK |
| IP interdite | `51.159.99.247` absente | absente | OK |
| API branch | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | OK |
| API HEAD/origin | `9797bedf` | `9797bedf` / `9797bedf` | OK |
| API dirty hors `dist` | 0 | 0 | OK |
| Infra branch | `main` | `main` | OK |
| Infra HEAD/origin | `75092d9` | `75092d9` / `75092d9` | OK |
| Infra dirty | 0 | 0 | OK |

## Runtime

| Env | Service | Image | ImageID | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| PROD | `keybuzz-api` | `v3.5.261-capi-platform-token-encryption-prod` | `sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5` | `1/1` | `0` | OK |
| DEV | `keybuzz-api` | `v3.5.261-capi-platform-token-encryption-dev` | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` | `1/1` | `0` | OK, inchange |

PROD pod verifie :

`keybuzz-api-5b444cbc99-lkcnv`

Critical log pattern count :

`0`

## Runtime markers PROD

| Marker/check | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| `/app/dist/server.js` | present | present | OK |
| `/app/dist/tests` | absent | absent | OK |
| fake tokens PH-21.02 | absent | absent | OK |
| `platform-token-crypto` | present | present | OK |
| `encryptOutboundPlatformTokenForStorage` | present | present | OK |
| `decryptOutboundPlatformTokenForProvider` | present | present | OK |
| `prepareOutboundPlatformTokenUpdate` | present | present | OK |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | present | present | OK |
| `aes256gcm` | present | present | OK |
| `ADS_ENCRYPTION_KEY` | nom present, valeur non affichee | present | OK |
| `redactSecrets` | present | present | OK |

## DB read-only PROD token inventory

Execution : Node in-pod API PROD avec `BEGIN TRANSACTION READ ONLY`, puis `ROLLBACK`.

Aucune valeur `platform_token_ref` n'a ete affichee.

### Global

| Total destinations | Active | Inactive | Token non null | Encrypted | Plaintext legacy |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 14 | 3 | 11 | 11 | 0 | 11 |

### Par destination_type

| destination_type | active | inactive | token_non_null | encrypted | plaintext_legacy | verdict |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `linkedin_capi` | 1 | 0 | 1 | 0 | 1 | legacy a backfiller |
| `meta_capi` | 1 | 6 | 7 | 0 | 7 | legacy a backfiller |
| `tiktok_events` | 1 | 2 | 3 | 0 | 3 | legacy a backfiller |
| `webhook` | 0 | 3 | 0 | 0 | 0 | token-neutral |

### Lignes legacy exactes

Hash : prefixe 12 caracteres SHA-256 du token, calcule en memoire, non reversible, token jamais affiche.

| id | tenant_id | destination_type | is_active | token_sha256_12 |
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

Observation : deux lignes `meta_capi` inactives `ecomlg-001` partagent le meme hash court `e3bc4f665463`, ce qui indique probablement le meme token legacy, sans exposer la valeur.

## API response masking read-only

| Check | Resultat | Verdict |
| --- | --- | --- |
| `sanitizeDestinationRow` runtime | present | OK |
| `maskOutboundPlatformToken` runtime | present | OK |
| mapping `platform_token_ref` -> mask runtime | present | OK |
| HTTP unauth list destinations | status `400` | pas de token retourne |
| HTTP list authentifiee | non executee, aucune session/cookie reel fourni | `AUTH_REQUIRED` |

Decision : le masking est prouve par le code compile runtime, mais la verification HTTP authentifiee complete reste a faire avec une vraie session admin/client. Aucun cookie ou header d'autorisation n'a ete invente.

## No unintended processing

| Compteur PROD | Before | After | Delta |
| --- | ---: | ---: | ---: |
| `outbound_conversion_delivery_logs` | 19 | 19 | 0 |
| `conversion_events` | 3 | 3 | 0 |
| `ai_actions_ledger` | 276 | 276 | 0 |
| `ai_suggestion_events` | 3642 | 3642 | 0 |
| `outbound_deliveries` | 314 | 314 | 0 |

Aucun event, delivery log, backfill ou processing inattendu observe.

## Plan PH-21.14 non execute

Plan propose pour backfill PROD dedie, sous GO explicite separe uniquement :

1. Preflight strict :
   - verifier bastion `install-v3` / `46.62.171.61`;
   - verifier runtime PROD toujours `v3.5.261-capi-platform-token-encryption-prod`;
   - verifier `ADS_ENCRYPTION_KEY` reference presente, sans afficher sa valeur;
   - snapshot compteurs no-side-effect.

2. Snapshot token-safe before :
   - compter total destinations;
   - compter tokens non nuls;
   - compter encrypted;
   - compter plaintext legacy;
   - inventorier les IDs cibles avec `destination_type`, `tenant_id`, `is_active`, hash court non reversible;
   - ne jamais sauvegarder ou afficher le token brut.

3. Selection cible :
   - lignes `platform_token_ref IS NOT NULL` et non prefixees `aes256gcm:`;
   - expected current target count : 11 lignes;
   - STOP si le count change sans explication.

4. Execution applicative :
   - utiliser le helper runtime de chiffrement deja deployee;
   - executer dans le pod API PROD ou un contexte applicatif equivalent;
   - transaction explicite;
   - `SELECT ... FOR UPDATE` sur les IDs cibles;
   - chiffrer en memoire avec `ADS_ENCRYPTION_KEY` runtime;
   - ne jamais logger plaintext, cle ou connection string;
   - verifier decrypt en memoire avant commit.

5. Validation avant commit :
   - target rows lues = expected;
   - updated rows = expected;
   - decrypt OK pour chaque valeur chiffree;
   - aucun provider endpoint appele;
   - aucun event tracking.

6. Commit ou rollback transactionnel :
   - `COMMIT` seulement si toutes les validations passent;
   - `ROLLBACK` au moindre ecart;
   - pas de backup plaintext persistant.

7. Validation apres commit :
   - plaintext legacy = 0;
   - encrypted = expected;
   - decrypt read-only possible via helper runtime;
   - API response masking toujours OK;
   - compteurs no-side-effect inchanges;
   - logs critiques = 0.

8. Rollback strategy :
   - rollback transactionnel avant commit;
   - apres commit, restauration uniquement sous GO explicite avec une strategie token-safe predefinie;
   - eviter tout export plaintext;
   - documenter si une rotation provider est preferable.

9. Decision rotation post-backfill :
   - apres chiffrement at-rest, evaluer rotation des tokens actifs par plateforme;
   - priorite probable : tokens actifs `linkedin_capi`, `meta_capi`, `tiktok_events`;
   - rotation uniquement en phase separee avec coordination provider.

Aucune commande SQL mutation prete a coller n'est fournie dans ce rapport.

## No side effect / interdits

| Interdit / controle | Resultat |
| --- | --- |
| SQL UPDATE/INSERT/DELETE/ALTER | non execute |
| Backfill | non execute |
| Deploy | non execute |
| Kubectl mutation | non execute |
| Docker build/push | non execute |
| Event tracking | non execute |
| Test endpoint CAPI | non execute |
| Secret/token/env value dans logs/rapport | non |
| Linear mutation | non execute |
| `/opt/keybuzz/credentials` | non touche |
| `/opt/keybuzz/secrets` | non touche |

## Artefacts

| Artefact | Chemin |
| --- | --- |
| Helper read-only | `/tmp/ph2113_tools.sh` |
| Rapport remote | `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.13-READONLY-VERIFY-CAPI-PLATFORM-TOKEN-ENCRYPTION-PROD-01.md` |

## Verdict

GO READONLY VERIFY CAPI PLATFORM TOKEN ENCRYPTION PROD ACTION_REQUIRED_AUTH PH-SAAS-T8.12AS.21.13

STOP.
