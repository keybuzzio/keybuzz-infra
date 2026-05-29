# PH-SAAS-T8.12AS.21.02-SOURCE-PATCH-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01

> Date : 2026-05-29
> Projet : KeyBuzz SaaS / API / Tracking server-side / Securite
> Phase : PH-SAAS-T8.12AS.21.02
> Type : source patch API DEV uniquement, commits locaux, aucun push/build/deploy/DB

## 1. Verdict

GO SOURCE PATCH CAPI PLATFORM TOKEN ENCRYPTION DEV READY PH-SAAS-T8.12AS.21.02

Patch source API applique et committe localement dans `keybuzz-api`.
Le stockage des nouvelles valeurs `outbound_conversion_destinations.platform_token_ref`
passe par le helper AES-256-GCM existant `src/lib/ads-crypto.ts`.

Runtime DEV/PROD inchanges. Aucun push, build, deploy, kubectl apply, mutation DB,
backfill, rotation token, test endpoint CAPI ou fake event.

## 2. Resume

PH-21.01 avait prouve un CRITICAL_FINDING : les tokens CAPI Meta, TikTok et LinkedIn
etaient masques en transit mais stockes en clair au repos dans
`outbound_conversion_destinations.platform_token_ref`, contrairement a
`ad_platform_accounts.token_ref` deja chiffre en `aes256gcm:...`.

PH-21.02 corrige la source pour les futures ecritures :

- create destination native : token non vide chiffre avant INSERT ;
- update destination native : nouveau token chiffre avant UPDATE ;
- update sans token ou avec placeholder masque : token existant preserve ;
- lecture provider : `aes256gcm:...` decrypte en memoire uniquement, legacy plaintext
  accepte jusqu'au backfill ;
- API response : token brut jamais retourne ;
- erreurs/logs : redaction existante preservee.

## 3. Sources relues

| source | statut |
|---|---|
| `AI_MEMORY/CURRENT_STATE.md` | relu |
| `AI_MEMORY/RULES_AND_RISKS.md` | relu |
| `AI_MEMORY/DOCUMENT_MAP.md` | relu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | relu |
| `AI_MEMORY/CE_FILE_HANDOFF_PROTOCOL.md` | relu |
| `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` | relu |
| `AI_MEMORY/EXECUTION_BOARD.md` | relu |
| `C:/DEV/KeyBuzz/tmp/PH-21.01_CE_RETURN.md` | relu |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.01-READONLY-VERIFY-TRACKING-CLARITY-FEATURE-PARITY-PROD-01.md` | relu |
| `PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01.md` | localise/relu par recherche |
| `PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01.md` | localise/relu par recherche |
| `PH-T8.8C-PROD-PROMOTION-AD-ACCOUNTS-SECRET-STORE-01.md` | localise/relu par recherche |
| `PH-T8.7B*` et `PH-ADMIN-T8.7C*` | localises/reconcilies |

## 4. Preflight repos/runtime

Bastion lu en preflight :

| point | resultat | verdict |
|---|---|---|
| host | `install-v3` | OK |
| IPv4 publique | `46.62.171.61` | OK |
| date UTC | `2026-05-29T09:55:45Z` | OK |
| IP interdite `51.159.99.247` | absente | OK |

Repos avant patch :

| repo | branche | HEAD | origin | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 798db37c | 798db37c | 223 suppressions `dist/` preexistantes | OK hors scope |
| keybuzz-infra | main | 92def68 | 92def68 | 0 | OK |

Runtime API lu en read-only :

| env | service | image | ADS_ENCRYPTION_KEY reference presente | restarts | verdict |
|---|---|---|---|---|---|
| DEV | keybuzz-api | ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-dev | oui, nom env present | 0 | OK |
| PROD | keybuzz-api | ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod | oui, nom env present | 0 | OK |

## 5. Audit source actuel

| fichier | role | lecture/ecriture token | risque |
|---|---|---|---|
| `src/lib/ads-crypto.ts` | helper AES-256-GCM existant | `encryptToken`, `decryptToken`, `isEncryptedToken` | source de verite crypto |
| `src/modules/ad-accounts/routes.ts` | reference deja conforme | chiffre `ad_platform_accounts.token_ref` | ne pas casser |
| `src/modules/metrics/ad-platforms/meta-ads.ts` | lecture token Ads | refuse plaintext, exige `aes256gcm` | pattern de reference |
| `src/modules/outbound-conversions/routes.ts` | CRUD destinations + test endpoint | ecrivait token en clair avant patch | P0 corrige |
| `src/modules/outbound-conversions/emitter.ts` | delivery server-side | lisait token DB directement | P0 corrige |
| `src/modules/outbound-conversions/adapters/meta-capi.ts` | appel Meta | attend token utilisable | pas modifie |
| `src/modules/outbound-conversions/adapters/tiktok-events.ts` | appel TikTok | attend token utilisable | pas modifie |
| `src/modules/outbound-conversions/adapters/linkedin-capi.ts` | appel LinkedIn | attend token utilisable | pas modifie |
| `src/modules/outbound-conversions/redact-secrets.ts` | redaction logs/erreurs | token connu + patterns | preserve |

Schema source : `platform_token_ref TEXT`, donc pas de contrainte de largeur detectee.
`ADS_ENCRYPTION_KEY` est deja reference en DEV et PROD. Aucun nouveau format crypto cree.

## 6. Design retenu

Nouveau helper central :

- `encryptOutboundPlatformTokenForStorage(value)` :
  - retourne `null` si valeur vide ou placeholder masque ;
  - preserve une valeur deja `aes256gcm:...` ;
  - chiffre toute valeur plaintext via `encryptToken()`.
- `prepareOutboundPlatformTokenUpdate(value, existing)` :
  - ignore `undefined`, vide, `(encrypted)`, `[REDACTED_TOKEN]`, `****`, `EA****xx` ;
  - preserve l'existant dans ces cas ;
  - chiffre un nouveau token brut.
- `decryptOutboundPlatformTokenForProvider(value)` :
  - decrypte `aes256gcm:...` en memoire ;
  - accepte legacy plaintext pour backward compatibility.
- `maskOutboundPlatformToken(value)` :
  - retourne `(encrypted)` pour une valeur chiffree ;
  - masque les valeurs legacy plaintext ;
  - ne retourne jamais le token brut.

Les adapters provider restent inchanges : ils recoivent un token utilisable en memoire
et conservent leur redaction existante.

## 7. Patch exact

| fichier | changement | raison | risque |
|---|---|---|---|
| `src/modules/outbound-conversions/platform-token-crypto.ts` | nouveau helper stockage/lecture/masking | centraliser la politique token outbound | faible |
| `src/modules/outbound-conversions/routes.ts` | create/update chiffrent ; responses masquent ; test endpoint decrypte en memoire | fermer le stockage plaintext futur | moyen, couvert par tests/tsc |
| `src/modules/outbound-conversions/emitter.ts` | Meta/TikTok/LinkedIn decryptent avant provider ; logs restent rediges | compat encrypted + legacy | moyen, couvert par tests/tsc |
| `src/tests/ph21_02-outbound-platform-token-crypto-tests.ts` | tests purs standalone | non-regression securite | faible |

Aucun adapter provider modifie. Aucun webhook/HMAC modifie.

## 8. Tests

| test | attendu | resultat |
|---|---|---|
| `encryptToken` | produit `aes256gcm:` sans plaintext | PASS |
| `isEncryptedToken` | detecte seulement `aes256gcm:` | PASS |
| `decryptToken` | rend le plaintext attendu | PASS |
| provider legacy plaintext | accepte legacy en memoire | PASS |
| provider encrypted | decrypte en memoire | PASS |
| create destination helper | chiffre `platform_token_ref` | PASS |
| update nouveau token | chiffre avant stockage | PASS |
| update sans token | preserve existant | PASS |
| update placeholder masque | n'ecrase pas existant | PASS |
| API mask | ne retourne jamais token brut | PASS |
| redaction erreur | preserve `[REDACTED_TOKEN]` | PASS |
| webhook destinations | token-neutral | PASS |
| Meta/TikTok/LinkedIn paths | helper provider-agnostic couvert | PASS |
| `./node_modules/.bin/tsc --noEmit` | compilation API sans emission | PASS |

Commandes executees :

```text
./node_modules/.bin/tsc --target ES2022 --module commonjs --esModuleInterop --skipLibCheck --types node --rootDir src --outDir /tmp/ph2102-build src/tests/ph21_02-outbound-platform-token-crypto-tests.ts
node /tmp/ph2102-build/tests/ph21_02-outbound-platform-token-crypto-tests.js
./node_modules/.bin/tsc --noEmit
```

## 9. No secret / no side-effect

| controle | resultat | verdict |
|---|---|---|
| secrets affiches | aucune valeur token/env affichee | OK |
| `git diff --check` | PASS | OK |
| diff source cible | 4 fichiers sources/tests | OK |
| `platform_token_ref` brut en response | remplace par `maskOutboundPlatformToken` | OK |
| logs provider | redaction avec token en memoire uniquement | OK |
| `ad_platform_accounts` | non modifie | OK |
| manifests K8s | non modifies | OK |
| `package-lock.json` | non modifie | OK |
| DB/backfill/rotation | non execute | OK |
| fake event/test endpoint | non execute | OK |
| push/build/deploy | non execute | OK |

Le `git diff --stat` global du repo API reste pollue par les suppressions `dist/`
preexistantes. Le commit API a ete fait avec `git add` cible uniquement sur les 4 fichiers
du patch PH-21.02.

## 10. Commits locaux

| repo | commit local | ahead | dirty residuel | push |
|---|---|---|---|---|
| keybuzz-api | `0d86d294 fix(tracking): encrypt outbound conversion platform tokens at rest (PH-21.02)` | 1 | 223 suppressions `dist/` preexistantes | non |
| keybuzz-infra | commit docs-only local contenant ce rapport | 1 attendu | 0 attendu apres commit | non |

## 11. Backfill/rotation plan non execute

PLAN NON EXECUTE.

DEV :

1. Promouvoir l'API DEV avec ce patch via process GitOps separe et GO explicite.
2. Verifier runtime API DEV = manifest = last-applied, avec `ADS_ENCRYPTION_KEY` present.
3. Executer une phase backfill dediee, avec backup/snapshot et script applicatif utilisant
   le helper crypto, pour les lignes `platform_token_ref` non nulles et non `aes256gcm`.
4. Faire la verification count plaintext -> 0 sans afficher les valeurs.
5. Valider que Meta/TikTok/LinkedIn continuent a lire les tokens sans fake event provider.
6. Decider separement d'une rotation token DEV si Ludovic juge le risque important.

PROD :

1. Attendre validation DEV complete.
2. Promouvoir l'API PROD via phase separee, GO explicite, build-from-git, GitOps strict.
3. Snapshot/backup PROD avant backfill.
4. Backfill PROD dedie via helper applicatif, transaction controlee, logs token-safe.
5. Verifier count plaintext -> 0 sans afficher les valeurs.
6. Evaluer rotation Meta/LinkedIn/TikTok selon risque business et exposition historique.
7. Valider no secret en API responses, delivery logs, pod logs et Admin.

Aucune commande SQL de mutation definitive n'est incluse ici.

## 12. Linear prepared text

Titre propose :

```text
Encrypt outbound conversion platform tokens at rest
```

Contenu propose :

```text
PH-21.01 a identifie un CRITICAL_FINDING : les tokens CAPI Meta, TikTok et LinkedIn
dans outbound_conversion_destinations.platform_token_ref etaient stockes en clair au repos,
alors que ad_platform_accounts.token_ref utilise deja aes256gcm.

PH-21.02 applique le patch source API : futures ecritures chiffrees via ads-crypto,
lecture provider backward-compatible aes256gcm/plaintext legacy, responses masquees,
placeholders masques ignores en update, redaction erreurs conservee.

Aucun token brut n'a ete affiche, aucun push/build/deploy/DB/backfill/event tracking
n'a ete execute.

Prochaine phase : build/deploy DEV puis backfill DEV dedie, avant promotion PROD et
backfill/rotation PROD sous GO separe.
```

Ce texte n'a pas ete poste. Aucun ticket/commentaire Linear cree.

## 13. Gaps / risques

| gap | impact | suite |
|---|---|---|
| lignes DB legacy encore plaintext | risque at-rest persiste jusqu'au backfill | phase backfill DEV puis PROD |
| runtime non deployee | patch uniquement local source | phase build/deploy DEV sous GO |
| repo API dirty `dist/` preexistant | hygiene Git locale | ne pas melanger, traiter separement |
| rotation token non faite | risque historique selon exposition | decision Ludovic apres backfill |

## 14. Prochaine phase recommandee

PH-21.03 ou PH-21.02B separee :

1. build/deploy API DEV depuis commit `0d86d294` ;
2. validation runtime DEV sans fake event ;
3. backfill DEV dedie des `platform_token_ref` legacy plaintext ;
4. rapport token-safe ;
5. seulement ensuite decision PROD.

STOP.
