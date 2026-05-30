# PH-SAAS-T8.12AS.21.15 - Readonly close CAPI platform token encryption PROD

## Verdict

GO READONLY CLOSE CAPI PLATFORM TOKEN ENCRYPTION PROD READY_WITH_DEBTS PH-SAAS-T8.12AS.21.15

Le P0 securite identifie en PH-21.01 est clos sur la preuve disponible:

- les API DEV et PROD tournent sur `v3.5.261` compatible `aes256gcm`;
- les nouveaux writes `platform_token_ref` sont chiffres par le runtime PH-21.02;
- le backfill DEV a transforme 5/5 tokens legacy en `aes256gcm`;
- le backfill PROD a transforme 11/11 tokens legacy en `aes256gcm`;
- les snapshots apres backfill prouvent `0 plaintext_legacy` DEV et PROD;
- decrypt readiness apres commit est OK DEV 5/5 et PROD 11/11;
- aucun provider event, fake event ou test endpoint CAPI n'a ete execute pour clore cette phase.

Important: PH-21.15 n'a execute aucune requete DB live. Le scope utilisateur courant imposait `aucune DB`. Les preuves DB ci-dessous proviennent des rapports/retours PH-21.09 et PH-21.14, executes avec controle transactionnel et verification read-only post-commit.

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.15_CODEX_EXECUTOR_MISSION.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.14_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.13_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.12_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.09_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.01_CE_RETURN.md` | lu |
| rapports PH-21.02 a PH-21.14 locaux | lecture ciblee |
| rapport remote PH-21.01 | lecture ciblee |
| `AI_MEMORY/CURRENT_STATE.md` | lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | lu |
| `AI_MEMORY/DOCUMENT_MAP.md` | lu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | lu |
| `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` | lu |
| `AI_MEMORY/EXECUTION_BOARD.md` | lu |

## Preflight

| Point | Resultat | Verdict |
| --- | --- | --- |
| Bastion | `install-v3` | OK |
| IPv4 | `46.62.171.61` | OK |
| IP interdite `51.159.99.247` | non observee | OK |
| API branch | `ph147.4/source-of-truth` | OK |
| API HEAD / origin | `9797bedf` / `9797bedf` | OK |
| API dirty hors `dist` | 0 | OK |
| Infra branch | `main` | OK |
| Infra HEAD / origin avant rapport | `1bc11d1` / `1bc11d1` | OK |
| Infra dirty avant rapport | 0 | OK |
| DB live query PH-21.15 | non executee | conforme scope Ludovic |
| Event provider / test endpoint | non execute | OK |
| Linear mutation | non executee | OK |

## Runtime

| Env | Service | Image | ImageID digest | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| DEV | `keybuzz-api` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev` | `sha256:ec4f7a5d84bfeef07dd9349df7179033419e442450c97b8490df1d3166341aeb` | `1/1` | 0 | OK |
| PROD | `keybuzz-api` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod` | `sha256:947c1902ba15622f1e757cee6b3b4e796eb91e503b56c724e7d7fa9e5b6545c5` | `1/1` | 0 | OK |

Manifest/spec/last-applied/runtime restent alignes en DEV et PROD.

## Final token inventory

Source des preuves:

- DEV: `PH-21.09_CE_RETURN.md` et rapport `PH-SAAS-T8.12AS.21.09-BACKFILL-CAPI-PLATFORM-TOKENS-DEV-01.md`.
- PROD: `PH-21.14_CE_RETURN.md` et rapport `PH-SAAS-T8.12AS.21.14-BACKFILL-CAPI-PLATFORM-TOKENS-PROD-01.md`.

| Env | Total | token_non_null | encrypted | plaintext_legacy | decrypt_ok | Verdict |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| DEV | 9 | 5 | 5 | 0 | 5/5 | OK |
| PROD | 14 | 11 | 11 | 0 | 11/11 | OK |

| Env | destination_type | active | inactive | token_non_null | encrypted | plaintext_legacy |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| DEV | `linkedin_capi` | 1 | 0 | 1 | 1 | 0 |
| DEV | `meta_capi` | 0 | 3 | 3 | 3 | 0 |
| DEV | `tiktok_events` | 0 | 1 | 1 | 1 | 0 |
| DEV | `webhook` | 0 | 4 | 0 | 0 | 0 |
| PROD | `linkedin_capi` | 1 | 0 | 1 | 1 | 0 |
| PROD | `meta_capi` | 1 | 6 | 7 | 7 | 0 |
| PROD | `tiktok_events` | 1 | 2 | 3 | 3 | 0 |
| PROD | `webhook` | 0 | 3 | 0 | 0 | 0 |

No raw token, encryption key, connection string, cookie or Authorization header was printed.

## Runtime markers

Active runtime checks were executed against DEV and PROD pods without DB access.

| Env | Marker/check | Expected | Result |
| --- | --- | --- | --- |
| DEV | `/app/dist/server.js` | present | present |
| DEV | `/app/dist/tests` | absent | absent |
| DEV | fake PH-21.02 test tokens | absent | absent |
| DEV | `platform-token-crypto` | present | present |
| DEV | `encryptOutboundPlatformTokenForStorage` | present | present |
| DEV | `decryptOutboundPlatformTokenForProvider` | present | present |
| DEV | `prepareOutboundPlatformTokenUpdate` | present | present |
| DEV | `OUTBOUND_PLATFORM_TOKEN_MASK` | present | present |
| DEV | `aes256gcm` | present | present |
| DEV | `ADS_ENCRYPTION_KEY` reference only | present | present |
| DEV | `redactSecrets` | present | present |
| PROD | `/app/dist/server.js` | present | present |
| PROD | `/app/dist/tests` | absent | absent |
| PROD | fake PH-21.02 test tokens | absent | absent |
| PROD | `platform-token-crypto` | present | present |
| PROD | `encryptOutboundPlatformTokenForStorage` | present | present |
| PROD | `decryptOutboundPlatformTokenForProvider` | present | present |
| PROD | `prepareOutboundPlatformTokenUpdate` | present | present |
| PROD | `OUTBOUND_PLATFORM_TOKEN_MASK` | present | present |
| PROD | `aes256gcm` | present | present |
| PROD | `ADS_ENCRYPTION_KEY` reference only | present | present |
| PROD | `redactSecrets` | present | present |

## No side effect / counters

No live DB counter query was run during PH-21.15. The values below are the final values recorded by the backfill phases.

| Env | Compteur | Valeur finale | Delta phase backfill | Verdict |
| --- | --- | ---: | ---: | --- |
| DEV | `outbound_conversion_delivery_logs` | 7 | 0 | OK |
| DEV | `conversion_events` | 0 | 0 | OK |
| DEV | `ai_actions_ledger` | 550 | 0 | OK |
| DEV | `ai_suggestion_events` | 2728 | 0 | OK |
| DEV | `outbound_deliveries` | 310 | 0 | OK |
| PROD | `outbound_conversion_delivery_logs` | 19 | 0 | OK |
| PROD | `conversion_events` | 3 | 0 | OK |
| PROD | `ai_actions_ledger` | 277 | 0 | OK |
| PROD | `ai_suggestion_events` | 3642 | 0 | OK |
| PROD | `outbound_deliveries` | 314 | 0 | OK |

Active runtime side-effect checks:

| Env | Check | Result | Verdict |
| --- | --- | --- | --- |
| DEV | pod restarts | 0 | OK |
| DEV | critical log pattern count | 0 | OK |
| PROD | pod restarts | 0 | OK |
| PROD | critical log pattern count | 0 | OK |

Backfill scheduler debt remains observed read-only:

| Namespace | Pod | Status | Restarts | Age |
| --- | --- | --- | ---: | --- |
| `keybuzz-backend-dev` | `backfill-scheduler-8654c9f646-26bgs` | `ImagePullBackOff` | 0 | 15d |
| `keybuzz-backend-prod` | `backfill-scheduler-65dd74c776-tssb5` | `ImagePullBackOff` | 0 | 15d |

## Rollback constraint

After PH-21.09 and PH-21.14, DB DEV and PROD contain `aes256gcm` values in `outbound_conversion_destinations.platform_token_ref`.

Mandatory constraint:

- do not rollback API DEV or PROD to pre-v3.5.261 / pre-PH-21.02 without an explicit token restoration or compatibility plan;
- safe runtime rollback means v3.5.261 or hotfix descendant that can read `aes256gcm`;
- rollback to v3.5.260 is forbidden without a written plan to restore or safely read encrypted tokens;
- no automatic plaintext DB downgrade is planned or authorized.

## Remaining debts

| Dette | Severite | Statut PH-21.15 | Prochaine phase |
| --- | --- | --- | --- |
| Server-side CAPI delivery logs 0/7j / traffic required | P1 | still needs real traffic proof; no fake event allowed | controlled real traffic or wait real traffic |
| Client funnel pixels D-2 from PH-21.01 | closed/obsolete | current memory says client funnel stack was later restored by PH-T8.12U / GA4 activation line | no PH-21 action unless new symptom |
| Alerting credit LLM + provider fallback | P1 | open | dedicated alerting/fallback phase |
| Token rotation Meta/TikTok/LinkedIn after historical plaintext at-rest | P1 security decision | open decision; encryption at-rest is done, rotation is separate risk management | security/product GO for rotation plan |
| backfill-scheduler ErrImagePull | P2 infra hygiene | still observed DEV and PROD | dedicated backend/infra hygiene phase |
| Amazon failed deliveries historical backlog | P2 | not revalidated live because PH-21.15 had no DB scope; remains historical debt from PH-21.01 | optional human review phase |
| TikTok Business API spend credentials | external/P2 | still business-blocked per memory | provide credentials, then resume TikTok spend phase |
| LinkedIn Ads Reporting spend approval | external/P3 | still outside P0 closure | wait approval / separate spend phase |

## Linear prepared text

No Linear mutation was executed. Prepared text only:

```text
PH-21 security closure: P0 token plaintext at-rest is corrected in DEV and PROD.

Initial finding PH-21.01: outbound_conversion_destinations.platform_token_ref stored Meta, LinkedIn and TikTok CAPI tokens as plaintext at rest.

Closure state:
- API DEV and PROD now run v3.5.261 CAPI platform token encryption runtime.
- Runtime helpers for aes256gcm write/read/masking are present.
- DEV backfill completed: 5 encrypted, 0 plaintext legacy, decrypt readiness 5/5.
- PROD backfill completed: 11 encrypted, 0 plaintext legacy, decrypt readiness 11/11.
- No provider event, no fake tracking event, no CAPI test endpoint was used for closure.
- Runtime rollback constraint: do not rollback to pre-v3.5.261/pre-PH-21.02 without an explicit aes256gcm compatibility or token restoration plan.

Remaining debts:
- server-side CAPI real delivery proof still needs real traffic or controlled GO;
- token rotation decision remains separate from encryption at rest;
- LLM credit alerting/fallback remains open;
- backfill-scheduler ImagePullBackOff remains infra hygiene;
- historical Amazon failed deliveries require optional human review.
```

## Interdits respectes

| Interdit | Resultat |
| --- | --- |
| SQL mutation | non |
| DB query live PH-21.15 | non |
| backfill | non |
| deploy / GitOps apply | non |
| kubectl mutation | non |
| docker build/push | non |
| provider event / test endpoint CAPI | non |
| fake event tracking | non |
| token rotation | non |
| Linear mutation | non |
| secret/token/env value display | non |
| `/opt/keybuzz/credentials` or `/opt/keybuzz/secrets` | non touches |

## Conclusion

The P0 at-rest plaintext exposure is closed for DEV and PROD. Remaining items are operational debts or risk decisions, not blockers for the encryption closure itself.

Final phrase:

GO READONLY CLOSE CAPI PLATFORM TOKEN ENCRYPTION PROD READY_WITH_DEBTS PH-SAAS-T8.12AS.21.15

STOP.
