# PH-WEBSITE-T8.12AS.17.1Q-1B-3B-0-KEY-323-PROVIDER-MANUAL-DECISIONS-DRYRUN-01

> Date : 2026-05-17
> Linear : KEY-323
> Phase : AS.17.1Q-1B-3B-0 provider/manual decisions DRY-RUN read-only
> Environnement : DEV + PROD read-only (synthese Q-1B-3A)
> Bastion : install-v3 (46.62.171.61)

## 1. Verdict

GO Q-1B-3B-0 DECISIONS READY.

Decision matrix complete pour les 18 decisions Q-1B-3A transformees en options A/B/C avec recommendation + risk + owner + future phase. 5 orphelins classifies (3 cleanup candidates + 2 retain/investigate). 5 LLM doublons identifies avec source-of-truth recommendee. inbound-webhook-key PROD : 4 options + recommendation migration ESO Option B. GHCR : 3 phases harmonisation (avant/pendant/apres rotation). Provider low-risk batch : 6 candidats classifies low/medium/high/blocker. OAuth + marketplace split confirme (Q-1B-3C separe de Q-1B-3B). 2 blockers documentes strategiques (keybuzz-ads-encryption + Shopify ENCRYPTION_KEY) avec options skip/dual-read/empty/migration. 8 non-secret items candidats migration ConfigMap. AI feature parity matrix 12 features avec validation future par batch. 0 secret/value affiche, 0 provider call, 0 mutation. Ordre recommande next prompts : Q-1B-3B-1 orphans cleanup (low-risk) -> Q-1B-3D GHCR design -> Q-1B-5A LLM dedup -> Q-1B-3B provider low-risk -> Q-1B-3C OAuth -> Q-1B-6 marketplace -> Q-1B-4 infra direct -> Q-1B-5 LLM rotation -> Q-1B-7 ads-encryption strategique -> Q-1F-3 validation cumulee.

Phrase finale :
STOP AS.17.1Q-1B-3B-0 - GO Q-1B-3B-0 DECISIONS READY. Rapport docs-only pret, en attente GO Ludovic commit/push. Q-1B-3B EXEC, Q-1B-4, Q-1B-5, Q-1B-6 et PROD promotion restent NO GO.

## 2. Scope / hors scope

### Scope inclus read-only

- Decision matrix 18 items Q-1B-3A.
- Orphans dry-run (5 secrets).
- LLM duplicates dry-run (5 items).
- inbound-webhook-key PROD divergence design (4 options).
- GHCR naming harmonisation design (3 phases).
- Provider low-risk batch design (6 candidats).
- OAuth + marketplace split design.
- 2 Blockers design (encryption durable).
- Non-secret ConfigMap migration candidates.
- AI feature parity matrix.
- No fake metrics verification.
- Recommandation ordre next prompts CE.
- Brouillon Linear KEY-323.

### Hors scope strict

- aucune suppression Secret.
- aucune rotation.
- aucune creation valeur.
- aucun appel provider externe.
- aucun login provider.
- aucun vault kv get/put/patch/delete/destroy/rollback.
- aucun vault token create/revoke / policy write/delete.
- aucun Shamir/root token.
- aucun kubectl apply/create/delete/annotate/rollout restart/scale.
- aucun build/deploy/docker push/GitOps deploy.
- aucun changement source/manifest.
- aucun test paiement/webhook/fake event.
- aucun secret value/base64 affiche.

## 3. Sources relues

### Standards KeyBuzz

- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md

### Rapports KEY-323 chain (9 rapports presents)

| Report | Commit | Key facts used | Verdict |
|---|---|---|---|
| Q-1A-bis-exec | 346b17a | vault-admin-token non-root active, rotator pattern Mode B SAFE etabli | source |
| Q-1B-0 | 7846785 | 35 unique KV paths + categories A/B/C/D/E initiales | baseline |
| Q-1B-1B | fcc1170 | DEV internal exec OK, pattern runner SCP atomique valide | reference |
| Q-1F-1 | 556772c | DEV validation OK, indicateurs stabilite | reference |
| Q-1B-2A | 4950f96 | PROD dry-run scope verrouille | reference |
| Q-1B-2A-bis | b00c9b8 | debug-env fix DEV+PROD, classification P3 disclosure | reference |
| Q-1B-2B | 41b80a0 | PROD internal exec Mode B SAFE atomique cross-env OK | reference |
| Q-1F-2 | 9d82413 | PROD stability OK 49min, JWT_SESSION_ERROR decroissant -72% | reference |
| **Q-1B-3A** | **42dd9a6** | 125 K8s Secrets + 5 orphelins + classification A-J + 18 decisions + 2 blockers | SOURCE PRINCIPALE |

Linear : connecteur indisponible cote CE - brouillon Linear inclus section 20 pour Codex.

## 4. Preflight

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| Date | 2026-05-17 | 2026-05-17 18:08 UTC | OK |
| Git infra HEAD | descendant 42dd9a6 | 42dd9a6e... clean | OK |
| Git client HEAD | descendant f61763a | f61763a4... clean | OK |
| Repos applicatifs | dirty 223 api + 1 backend connus | OK (prior sessions) | OK |
| 6 fichiers temp KEY-323 | tous absents | 6/6 absent + Q-1B-3A jsonls cleaned | OK |
| 9 rapports KEY-323 docs | presents tailles attendues | 9/9 OK (17-45 KB chacun) | OK |
| Q-1B-3A 18 decisions section 14 | 18 items | 18 confirmes | OK |
| Q-1B-3A 5 orphelins section 7 | 5 items | 5 confirmes | OK |
| Q-1B-3A categories A-J section 9 | 10 categories | 10 confirmees | OK |

## 5. Q-1B-3A findings digest

Synthese non-redondante (details complets dans rapport Q-1B-3A commit 42dd9a6).

### Inventaire

- 30 ExternalSecrets sur 11 namespaces vers 35 paths Vault KV uniques.
- 125 K8s Secrets : 28 ESO + 12 imagePull GHCR + 61 manual + 14 TLS + 10 helm.
- 47 manual secrets significatifs DEV+PROD apres exclusion infra obs/SA-tokens/TLS/helm.

### Categories A-J (rappel)

- A : internal generated KV-only (deja rotate Q-1B-1B + Q-1B-2B).
- B : provider externe high-risk (Stripe, SES, Meta Ads, Google Ads, Slack).
- C : OAuth login (Google/Azure secrets DEV+PROD).
- D : marketplace OAuth (Amazon SP-API, Shopify, Octopia ESO, 17track).
- E : infra direct (Redis, Postgres app roles, MinIO, SMTP).
- F : LLM/AI (OpenAI, Anthropic, Gemini, LiteLLM master key, 5 doublons).
- G : manual internal candidat migration ESO (internal-proxy, inbound-webhook-key PROD, admin-v2-auth, admin-v2-stripe, studio-api).
- H : imagePull GHCR (ghcr-cred 9 ns + ghcr-secret 3 ns).
- I : encryption durable (keybuzz-ads-encryption) BLOCKER.
- J : non-secret IDs/config (Stripe price IDs, URLs publiques, OAuth client IDs publics, LLM config).

### 5 orphelins detectes (0 workload reference)

- vault-emergency-token (api-dev, break-glass token probable).
- keybuzz-api-postgres-static (api-dev, backup statique probable).
- keybuzz-api-auth (api-dev, obsolete doublon ESO keybuzz-api-jwt).
- keybuzz-octopia (api-dev, obsolete doublon ESO octopia-credentials).
- litellm-runtime-key (keybuzz-ai, usage non clair).

### 2 Blockers strategiques

- keybuzz-ads-encryption : chiffre data ads (refresh tokens Google Ads dans DB) - rotation directe impossible sans dual-read OR vidage dataset.
- Shopify SHOPIFY_ENCRYPTION_KEY : chiffre shop tokens DB - meme nature blocker.

## 6. Decision matrix 18 items Q-1B-3A

| ID | Decision | Options | Recommended | Risk | Owner | Future phase |
|---|---|---|---|---|---|---|
| D01 | Scope Q-1B-3B providers low-risk | A=tout (Stripe+SES+Ads+Slack) ; B=Stripe TEST seul ; C=SES+Slack seul (low-impact) | C puis sequence individuelle per provider | impact billing/email Ads si tout en bloc | Ludovic | Q-1B-3B |
| D02 | Stripe scope rotation | A=PROD secret_key+webhook_secret ; B=TEST keys only ; C=skip (pas de client reel) | B TEST keys only (cycle complet pratique, zero impact reel) | rotation webhook_secret = re-config Dashboard | Ludovic console Stripe | Q-1B-3B |
| D03 | SES IAM rotation strategy | A=2-phase create+revoke (no downtime) ; B=immediate single (downtime transitoire) ; C=skip | A 2-phase obligatoire (outbound email critique) | impact OTP/notifications transit | Ludovic AWS IAM | Q-1B-3B |
| D04 | Google/Azure OAuth rotation | A=DEV+PROD ensemble ; B=DEV first ; C=skip (Q-1B-3C separe) | B DEV first, PROD avec UX validation Ludovic | invalide sessions PROD users | Ludovic GCP/Azure consoles | Q-1B-3C |
| D05 | GHCR PAT rotation | A=rotation atomique 12 ns ; B=harmonisation naming d'abord ; C=skip | B harmoniser ghcr-cred/ghcr-secret avant rotation pour zero ambiguite | impact pull image future deploy | Ludovic GitHub PAT | Q-1B-3D |
| D06 | Ads tokens (Google/Meta) | A=rotation OAuth refresh tokens ; B=DEV first ; C=skip | B DEV first puis PROD per provider | impact reporting Ads dashboards + GA4/CAPI | Ludovic Google Ads + Meta Marketing | Q-1B-3B sub-batch |
| D07 | Shopify ENCRYPTION_KEY | A=rotate avec dual-read design ; B=scope reduit CLIENT_SECRET only ; C=skip indefinite | B scope reduit (CLIENT_SECRET regenerable sans dual-read, ENCRYPTION_KEY BLOCKER strategique) | encryption shop tokens DB | Ludovic + dev backend | Q-1B-6 + Q-1B-7 strategique |
| D08 | Amazon SP-API rotation | A=re-consent par tenant ; B=skip (zero client reel actuel) ; C=design only | C design only maintenant (validate pattern), B operational si zero client | impact orders marketplace tenant | Ludovic Seller Central + AWS IAM | Q-1B-6 |
| D09 | Octopia rotation | A=rotation portal ; B=DEV first ; C=skip | B DEV first via ESO octopia-credentials sync | impact marketplace Octopia | Ludovic portal Octopia | Q-1B-6 |
| D10 | 17track rotation | A=rotation portal API_KEY ; B=skip | A rotation simple (1 key, portal regenerate, low-risk) | impact tracking colis | Ludovic portal 17track | Q-1B-6 sub-batch |
| D11 | LLM cleanup doublons | A=cleanup avant Q-1B-5 ; B=apres Q-1B-5 ; C=skip | A cleanup d'abord (Q-1B-5A) puis rotation Q-1B-5B | confusion source-of-truth | Ludovic + dev keybuzz-ai | Q-1B-5A puis Q-1B-5B |
| D12 | keybuzz-ads-encryption strategy | A=dual-read + re-encrypt batch ; B=vidage dataset + re-collect ; C=skip indefinite | C skip indefinite si data ads non-critique OU A si data ads business-critique | perte data ads chiffree si vidage | Ludovic strategique + dev | Q-1B-7 strategique |
| D13 | 5 orphelins cleanup | A=cleanup tous ; B=per-secret evaluation ; C=skip tous | B per-secret (cf section 7 orphans dry-run) | si retain pour resilience, garder annotation/labels | Ludovic per secret | Q-1B-3B-1 orphans cleanup |
| D14 | inbound-webhook-key PROD | A=garder manual ; B=migrer ESO backend-secrets ; C=Secret separe ESO ; D=Secret manuel mais documente | B migrer dans keybuzz-backend-secrets ESO (harmoniser DEV/PROD, source-of-truth Vault unique) | impact ext webhook senders ; backend restart | Ludovic + dev backend | Q-1B-3E migration ESO |
| D15 | Non-secrets ConfigMap | A=migrer ConfigMap tous ; B=garder dans Secret (less risky) ; C=case-by-case | C case-by-case : Stripe price IDs OK ConfigMap ; URLs publiques OK ConfigMap ; OAuth client IDs publics OK ConfigMap ; LLM config OK ConfigMap | priorite faible, decorrelation rotation | Ludovic + dev | Q-1B-3F low-priority cleanup |
| D16 | Studio API scope KEY-323 | A=inclure Q-1B-3E migration ESO ; B=phase dediee Q-1B-3E-studio ; C=skip indefinite | B phase dediee Studio API : 3 secrets manuels (auth/db/llm) + LLM config a separer (J), distinct admin-v2 | impact Studio API LLM + bootstrap | Ludovic + dev studio-api | Q-1B-3E-studio |
| D17 | Window operation + Mode B SAFE reuse | A=Mode B SAFE pour tous lots ; B=Mode A Ludovic direct pour low-risk ; C=mix | A Mode B SAFE pattern Q-1B-2B confirme (rotator dedie + STOP gates + cleanup) | overhead operationnel mais safety maximum | Ludovic + CE | tous lots futurs |
| D18 | Q-1F-3 validation scope | A=apres Q-1B-3B-1 orphans cleanup ; B=apres chaque batch ; C=apres cycle complet | B apres chaque batch (validation immediate evite drift) | overhead validation mais traceability max | CE per batch | Q-1F-3-X per batch |

## 7. Orphans dry-run

| Secret | Current evidence | Hypothesis | Recommended decision | Future action | Risk |
|---|---|---|---|---|---|
| vault-emergency-token (api-dev) | 0 workload ref, contient DESCRIPTION + VAULT_TOKEN | break-glass token Ludovic pour intervention urgence si vault-token-renew CronJob casse | RETAIN BREAK-GLASS + add label `keybuzz.io/purpose=break-glass` + ajouter au runbook AI_MEMORY/RULES_AND_RISKS | documenter usage Q-1B-3B-1 + verify Ludovic confirmation usage | low : conserver mais documenter pour evite cleanup accidentel futur |
| keybuzz-api-postgres-static (api-dev) | 0 workload ref, 5 keys Postgres | backup statique DEV pour resilience si ESO down + keybuzz-api-postgres ESO indisponible | RETAIN BACKUP OR MIGRATE to ConfigMap-with-secretRef + add label `keybuzz.io/purpose=eso-fallback-backup` | documenter + Ludovic confirme resilience pattern needed (else delete candidate) | low : si retain documenter + ne pas rotate (consistency loss vs ESO source) |
| keybuzz-api-auth (api-dev) | 0 workload ref, 2 keys COOKIE_SECRET + JWT_SECRET | obsolete doublon ESO keybuzz-api-jwt (deja rotate Q-1B-1B) | DELETE CANDIDATE (cleanup safe, 0 workload ref + doublon ESO actif) | Q-1B-3B-1 orphans cleanup execute delete avec GO Ludovic | minimal : 0 consommateur, ESO source-of-truth |
| keybuzz-octopia (api-dev) | 0 workload ref, 1 key OCTOPIA_CLIENT_SECRET | obsolete doublon ESO octopia-credentials | DELETE CANDIDATE | Q-1B-3B-1 orphans cleanup execute delete avec GO Ludovic | minimal : 0 consommateur, ESO source-of-truth |
| litellm-runtime-key (keybuzz-ai) | 0 workload ref, 1 key LITELLM_RUNTIME_KEY | usage non clair, possible historique helm chart litellm | INVESTIGATE OWNER + decision Ludovic | check helm chart litellm si reference + verify Ludovic | medium : si supprime sans verify, casse possible litellm runtime |

Verdict orphans : 3 DELETE CANDIDATES (keybuzz-api-auth, keybuzz-octopia, litellm-runtime-key conditionnel) + 2 RETAIN avec labels documentation (vault-emergency-token, keybuzz-api-postgres-static).

Future phase : Q-1B-3B-1 ORPHANS CLEANUP DRY-RUN/EXEC avec STOP gate par secret + GO Ludovic individuel.

## 8. LLM duplicates dry-run

| Secret | Managed by | Consumers | Duplicate? | Recommended next phase | Risk |
|---|---|---|---|---|---|
| litellm-secret (keybuzz-ai) | ESO via ExternalSecret litellm-secrets -> Vault paths secret/keybuzz/litellm/{master_key,database_url,use_prisma_migrate} + secret/keybuzz/ai/{openai_api_key,anthropic_api_key} | litellm Deployment envFrom keybuzz-ai (2 pods) | NON SOURCE-OF-TRUTH | Q-1B-5B rotation cible (apres Q-1B-5A dedup) | risk si rotation casse litellm pods runtime |
| litellm-db-secret (keybuzz-ai) | manual, 3 keys (DATABASE_URL, LITELLM_DATABASE_URL, USE_PRISMA_MIGRATE) | litellm Deployment envFrom (idem) | DOUBLON ESO litellm-secret (3 keys identiques nommees) | Q-1B-5A : verify helm chart litellm utilise quel secret (litellm-secret ou litellm-db-secret), cleanup doublon | medium : si helm chart utilise les 2, conflit env-var order = behavior imprevisible |
| litellm-runtime-key (keybuzz-ai) | manual, 1 key LITELLM_RUNTIME_KEY | 0 workload reference (orphan) | ORPHAN | Q-1B-5A : verify helm chart si reference LITELLM_RUNTIME_KEY (env-var rare), sinon delete | low si orphan confirme : cleanup safe |
| keybuzz-litellm (api-dev + api-prod) | manual, 1 key LITELLM_MASTER_KEY | api Deployment envSecret api-dev + api-prod | DOUBLON ESO keybuzz-litellm-secrets (api-dev only) ET FONCTIONNELLEMENT keybuzz-ai litellm-secret | Q-1B-5A : determiner source-of-truth (probable ESO keybuzz-litellm-secrets api-dev mais api-prod n'a PAS d'ESO !) | high : api-prod consomme keybuzz-litellm manual SANS ESO equivalent, donc ce N'EST PAS un doublon mais le seul secret PROD pour LITELLM_MASTER_KEY. Migration ESO requise pour cleanup |
| keybuzz-studio-api-llm (studio-api dev + prod) | manual, 9 keys (ANTHROPIC_API_KEY + GEMINI_API_KEY + LLM_API_KEY + 6 config) | keybuzz-studio-api envFrom dev + prod | NON-DOUBLON (Studio LLM distinct keybuzz-ai LiteLLM) | Q-1B-3E-studio migration ESO + separer 6 config (J non-secret) des 3 secrets | medium : Studio API distinct, GEMINI provider nouveau scope |

Verdict LLM doublons :
- ESO source-of-truth confirme : litellm-secret (keybuzz-ai) pour LiteLLM gateway.
- ASYMMETRIE CRITIQUE : keybuzz-litellm api-prod manual = SEUL secret PROD pour LITELLM_MASTER_KEY (api-dev a ESO + manual, api-prod a manual seul). Migration ESO PROD requise AVANT rotation Q-1B-5.
- litellm-db-secret + litellm-runtime-key : cleanup post-helm-chart verify.
- Studio API LLM : phase dediee Q-1B-3E-studio.

Future phase : **Q-1B-5A LLM SECRETS DEDUP DRY-RUN** prerequisite pour Q-1B-5B rotation reelle.

## 9. inbound-webhook-key design

### Contexte

- DEV : INBOUND_WEBHOOK_KEY est property dans ESO keybuzz-backend-dev/keybuzz-backend-secrets (Vault keybuzz/dev/inbound-webhook), deja rotate Q-1B-1B.
- PROD : Secret manuel separe keybuzz-backend-prod/inbound-webhook-key (1 key INBOUND_WEBHOOK_KEY), NON gere par ESO.
- backend-prod Deployment consomme inbound-webhook-key via envFrom.
- Divergence architecture DEV/PROD = anti-pattern.

### Options

| Option | Description | Pros | Cons | Runtime impact | Recommendation |
|---|---|---|---|---|---|
| A | Garder manual PROD comme-il-est | aucun changement infra | divergence DEV/PROD perdure ; cleanup futur necessaire | aucun maintenant | NON (garde dette technique) |
| B | Migrer PROD vers ESO via keybuzz-backend-secrets ESO + Vault path keybuzz/prod/inbound-webhook | source-of-truth Vault unique DEV+PROD ; ESO sync automatique ; aligne pattern internal Q-1B-2B | requires : (1) creer KV path keybuzz/prod/inbound-webhook (vault kv put nouvelle valeur) ; (2) ajouter property INBOUND_WEBHOOK_KEY dans ExternalSecret keybuzz-backend-prod/keybuzz-backend-secrets ; (3) supprimer Secret manuel ; (4) restart backend-prod | backend-prod restart 1x (etape 3) + ext webhook senders avec ancien key fail jusqu'a re-config | RECOMMANDEE |
| C | Secret separe ESO `keybuzz-backend-inbound-webhook` distinct (sans melange backend-secrets) | isolation logique ; rotation independante future | + 1 ExternalSecret + 1 K8s Secret a maintenir ; complexite namespace | restart backend-prod ; ext webhook senders idem | non-prefere |
| D | Manual mais documente avec label keybuzz.io/managed-by=manual-justified-prod | aucun changement infra ; documentation explicite | divergence perdure mais documentee | aucun | si Ludovic prefere isolation manuelle PROD |

**Recommandation : Option B** - migrer PROD vers ESO keybuzz-backend-secrets pour harmoniser source-of-truth Vault.

Sequence migration Q-1B-3E-inbound-webhook :
1. Ludovic determine valeur actuelle PROD (lire Secret manuel valeur) ou generer nouvelle valeur.
2. CE Mode B SAFE : `vault kv put secret/keybuzz/prod/inbound-webhook INBOUND_WEBHOOK_KEY=<value>` (rotator dedie scope path strict).
3. Modifier manifest GitOps ExternalSecret keybuzz-backend-prod/keybuzz-backend-secrets : ajouter `- secretKey: INBOUND_WEBHOOK_KEY ; remoteRef.key=keybuzz/prod/inbound-webhook ; property=INBOUND_WEBHOOK_KEY`.
4. Commit + push infra + kubectl apply.
5. Si nouvelle valeur, coordonner ext webhook senders avant cutover.
6. Supprimer Secret manuel `kubectl delete secret inbound-webhook-key -n keybuzz-backend-prod` apres confirmation ESO synced.
7. backend-prod restart (manuel ou reloader si configure).

GO requis a chaque etape. STOP avant suppression Secret manuel.

## 10. GHCR naming / imagePullSecrets design

### Contexte Q-1B-3A

- ghcr-cred : 9 namespaces (keybuzz-api-dev/prod, keybuzz-backend-dev/prod, keybuzz-client-dev/prod, keybuzz-seller-dev, keybuzz-studio-api-dev/prod)
- ghcr-secret : 3 namespaces (keybuzz-admin-v2-dev/prod, keybuzz-client-dev)
- Total 12 imagePullSecrets, 2 conventions naming.

### Phases harmonisation proposees (Q-1B-3D)

| Phase | Description | Risk | Sequence |
|---|---|---|---|
| **Phase 1 BEFORE rotation : harmonisation naming** | Renommer ghcr-secret -> ghcr-cred dans 3 namespaces concernes (admin-v2-dev/prod + client-dev) + modifier manifests Deployment imagePullSecrets | impact GitOps manifest pour 3 ns ; risque double-active si transition | execution dual : ajouter ghcr-cred avec meme content + retirer ghcr-secret manifests + supprimer Secret ghcr-secret apres confirmation pull tests |
| **Phase 2 ROTATION PAT** | Rotation GitHub PAT atomique sur les 12 namespaces ghcr-cred | impact pull image future deploy si nouveau PAT non deploy partout | rotation simultanee via runner (kubectl create/apply nouvelle ghcr-cred dans 12 ns) + revoke ancien PAT GitHub apres pull canary tests |
| **Phase 3 AFTER : canary validation** | Pull test image arbitraire dans chaque namespace via Job pour valider PAT effective | aucun impact pods existants Running | runner canary Job par ns |

### Recommandation Q-1B-3D dedicated phase

- **Q-1B-3D Phase 1** : harmonisation naming (DRY-RUN + EXEC avec GO Ludovic), separer de Phase 2 rotation.
- **Q-1B-3D Phase 2** : rotation PAT atomique 12 ns avec Mode B SAFE pattern.
- **Q-1B-3D Phase 3** : canary validation Job-per-ns + cleanup ancien PAT GitHub.

Table imagePullSecrets observed :

| Secret name | Namespaces | Risk | Harmonization option | Future validation |
|---|---|---|---|---|
| ghcr-cred | keybuzz-api-{dev,prod}, keybuzz-backend-{dev,prod}, keybuzz-client-{dev,prod}, keybuzz-seller-dev, keybuzz-studio-api-{dev,prod} | bloque future deploy si PAT casse | conserver convention dominante | canary pull job |
| ghcr-secret | keybuzz-admin-v2-{dev,prod}, keybuzz-client-dev | duplicate dans client-dev (a la fois ghcr-cred ET ghcr-secret!) | RENAME -> ghcr-cred | canary pull job |

Note critique : keybuzz-client-dev possede les 2 secrets (ghcr-cred + ghcr-secret) - confusion architecturale a resoudre.

## 11. Provider low-risk batch design (Q-1B-3B candidates)

| Provider | Env | Consumer | Future provider action | Runtime action | Risk | Recommended phase |
|---|---|---|---|---|---|---|
| Stripe TEST keys (keybuzz-stripe-secrets ESO api-dev) | DEV | api Deployment | Ludovic Stripe Dashboard regenerate TEST secret_key + webhook_secret | api-dev restart auto reloader | low (zero client reel) | Q-1B-3B sub-1 |
| Stripe TEST admin (keybuzz-admin-v2-stripe DEV) | DEV | admin-v2-dev Deployment | Ludovic regenerate idem | admin-v2-dev restart manuel reloader absent | low | Q-1B-3B sub-1 |
| Stripe PROD keys | PROD | api-prod (manual keybuzz-stripe) | Ludovic regenerate PROD secret_key + webhook_secret + re-config webhook endpoint Stripe | api-prod restart + Stripe webhook re-config | medium-high (live billing future) | Q-1B-3B sub-2 ; defer pre-launch ou skip si test mode actif |
| SES (keybuzz-ses-secrets ESO + keybuzz-ses manual PROD) | DEV+PROD | api-outbound-worker envFrom dev+prod | Ludovic AWS IAM : create new access key, deploy via Vault patch, revoke ancien (2-phase) | outbound-worker restart per env | medium (impact OTP/notifications) | Q-1B-3B sub-3 ; harmoniser PROD vers ESO d'abord |
| Slack/monitoring webhook (alerting-slack-dev ESO + monitoring-webhook manual vault-management) | DEV+vault-management | alertmanager StatefulSet + monitoring-alerts CronJob | Ludovic Slack app regenerate webhook URL | alertmanager pod restart (StatefulSet) + monitoring-alerts CronJob inherit | low | Q-1B-3B sub-4 |
| Google Ads (keybuzz-google-ads manual DEV+PROD) | DEV+PROD | api Deployment envSecret | Ludovic Google Ads API console regenerate refresh token (OAuth flow) | api restart per env | medium (impact reporting Ads dashboard) | Q-1B-3B sub-5 ; DEV first |
| Meta Ads (keybuzz-meta-ads manual PROD only) | PROD | api Deployment envSecret | Ludovic Meta Marketing API regenerate access token | api-prod restart | medium (impact reporting Meta dashboard) | Q-1B-3B sub-6 ; defer ou test isole |

Recommandation Q-1B-3B :
- **sub-1+sub-4** (Stripe TEST + Slack) : low-risk, DEV first, executable rapidement.
- **sub-3 SES** : medium, 2-phase strategy obligatoire.
- **sub-5+sub-6 Ads** : medium, DEV first puis PROD.
- **sub-2 Stripe PROD** : defer post-launch reel.

## 12. OAuth login / marketplace split

| Domain | Why separate | Impact | Validation | Future prompt |
|---|---|---|---|---|
| **OAuth login** Google/Azure secret/keybuzz/auth (DEV) + secret/keybuzz/prod/auth (PROD) | impact UX users login (sessions invalidees, re-auth NextAuth, redirect URI verification) | testeurs/users PROD doivent re-login OAuth Google ou Azure ; admin-v2 separate NEXTAUTH_SECRET | manual Ludovic validation post-rotation comme Q-1F-1/Q-1F-2 pattern | **Q-1B-3C OAUTH LOGIN DRY-RUN/EXEC** distincte de provider batch |
| **Marketplace OAuth** Amazon SP-API + Shopify + Octopia + 17track | impact connecteurs commandes/tracking, requires re-consent par tenant (Amazon SP-API), shop tokens encryption Shopify | tests marketplace API dry-run + per-tenant runbook | dry-run d'abord, execution per-tenant si client reel | **Q-1B-6 MARKETPLACE OAUTH DRY-RUN** dedicated phase per marketplace |

Justification split :
- OAuth login (utilisateurs SaaS authentification) vs marketplace OAuth (apps integrators tenant) sont 2 surfaces distinctes avec impact users different.
- Provider low-risk Q-1B-3B = backend services impact (Stripe billing, SES email, Ads reporting, Slack alerting) sans impact directement UX login utilisateur.
- Melange dans un meme batch = risk regression cumulee impossible a tracer.

## 13. Blockers design

### keybuzz-ads-encryption (Category I)

| Aspect | Detail |
|---|---|
| Data encrypted | Google Ads refresh tokens stockes en DB chiffres par ADS_ENCRYPTION_KEY (probable +Meta Ads tokens si pattern similaire) |
| Files runtime | api src/lib/ads-crypto.ts utilise crypto AES probable |
| Rotation directe impossible | si rotate, anciennes data chiffrees ne se dechiffrent plus -> perte refresh tokens Ads -> users tenants doivent re-OAuth Google/Meta Ads |
| Options strategiques |  |
| A skip indefinite | retain encryption key forever, rotation NEVER. Risque securite si key compromise (incident KEY-323 -> probable scope) | NON recommande si compromise |
| B dual-read + re-encrypt batch | nouvelle key ENCRYPTION_KEY_NEW deploye en parallele, code modifie pour read both, batch re-encrypt data, remove old key | RECOMMANDE techniquement mais effort dev important |
| C empty dataset + re-collect | wipe ads data dataset DB, rotate key, users tenants re-OAuth Google/Meta Ads pour re-collecter refresh tokens | acceptable si data ads non business-critique OU si pre-launch reel |
| D migration scheme with backfill | versioned encryption (envelope encryption), nouveaux records chiffres new key, anciens records re-encrypted en background | RECOMMANDE long-terme mais hors scope KEY-323 immediate |

**Recommandation** : Q-1B-7 STRATEGIC DECISION phase dediee + Option C (empty dataset) acceptable maintenant si zero client reel actuel confirme par Ludovic, sinon Option B (dual-read).

Required design avant execution :
- code review src/lib/ads-crypto.ts pour determiner algorithm + cipher mode.
- DB schema audit pour identifier columns chiffrees.
- backfill script design.
- versioned encryption library evaluation.

### Shopify SHOPIFY_ENCRYPTION_KEY (Category I subset)

| Aspect | Detail |
|---|---|
| Data encrypted | shop tokens (access tokens Shopify API) chiffres dans DB |
| Files runtime | api src/modules/marketplaces/shopify/shopifyAuth.service.ts + shopify.routes.ts + shopifyWebhook.routes.ts |
| Rotation directe impossible | si rotate sans dual-read, anciens shop tokens illisibles -> tenants Shopify connectes perdent acces |
| Options |  |
| A skip ENCRYPTION_KEY, rotate uniquement CLIENT_SECRET (Shopify Partners app secret) | OAuth client secret regenerable sans impact tokens chiffres | RECOMMANDE court-terme |
| B dual-read + re-encrypt batch shops tokens | meme pattern keybuzz-ads-encryption | effort dev |
| C empty dataset shops + tenants re-OAuth | tenants Shopify perdent connexion, doivent re-OAuth | acceptable si zero client reel |
| D migration versioned encryption | long-terme | hors scope |

**Recommandation** : Q-1B-6 Shopify sub-batch : Option A scope reduit (rotate CLIENT_SECRET only, skip ENCRYPTION_KEY) ; Q-1B-7 strategic decision ENCRYPTION_KEY couplee avec keybuzz-ads-encryption.

### Tableau blockers consolide

| Secret | Data encrypted | Options | Recommended | Required design |
|---|---|---|---|---|
| keybuzz-ads-encryption | Google/Meta Ads refresh tokens DB | A skip / B dual-read / C empty / D versioned | C empty si zero client reel + Q-1B-7 strategic | DB schema audit + ads-crypto.ts review + backfill script |
| Shopify SHOPIFY_ENCRYPTION_KEY | Shopify shop tokens DB | A skip ENCRYPTION rotate CLIENT_SECRET only / B dual-read / C empty + re-OAuth / D versioned | A scope reduit court-terme + Q-1B-7 strategic | shopifyAuth.service review + dual-read design si business-critique |

## 14. Non-secret ConfigMap candidates

| Item | Current location | Secret? | Proposed future location | Priority |
|---|---|---|---|---|
| STRIPE_PRICE_STARTER_MONTHLY/ANNUAL | keybuzz-stripe-secrets ESO + secret/keybuzz/stripe Vault | NON public Stripe IDs | ConfigMap keybuzz-stripe-config | low |
| STRIPE_PRICE_PRO_MONTHLY/ANNUAL | idem | NON | ConfigMap | low |
| STRIPE_PRICE_AUTOPILOT_MONTHLY/ANNUAL | idem | NON | ConfigMap | low |
| STRIPE_PRICE_ADDON_CHANNEL_MONTHLY/ANNUAL | idem | NON | ConfigMap | low |
| STRIPE_PRODUCT_ADDON_CHANNEL + STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ | keybuzz-stripe manual api-prod | NON | ConfigMap | low |
| API_BASE_URL + APP_BASE_URL | keybuzz-stripe ESO + manual | NON URLs publiques | ConfigMap ou inline env Deployment | low |
| NEXTAUTH_URL | secret/keybuzz/auth Vault + ESO keybuzz-auth-secrets | NON URL publique callback | ConfigMap | low |
| GOOGLE_CLIENT_ID (DEV + PROD) | secret/keybuzz/auth + secret/keybuzz/prod/auth | semi-public (OAuth norm) | rester Secret (lie a GOOGLE_CLIENT_SECRET) ou ConfigMap si separation acceptee | low |
| AZURE_AD_CLIENT_ID + AZURE_AD_TENANT_ID | idem | semi-public | rester Secret ou ConfigMap | low |
| META_AD_ACCOUNT_ID | keybuzz-meta-ads manual PROD | semi-public ID | ConfigMap | low |
| LLM_MAX_TOKENS + LLM_MODEL + LLM_PROVIDER + LLM_TEMPERATURE + LLM_TIMEOUT_MS + PIPELINE_MODE | keybuzz-studio-api-llm manual | NON config | ConfigMap keybuzz-studio-api-config | low |

Recommandation : Q-1B-3F low-priority cleanup phase apres cycle Q-1B-3 complet. Migration ConfigMap requires GitOps manifest changes + Deployment env reference update + restart. Pas un blocker pour rotation actuelle.

## 15. AI feature parity / anti-regression

| Feature | Secrets involved | Proposed future batch | Regression risk | Future validation |
|---|---|---|---|---|
| Inbox AI assist / Autopilot draft | LITELLM_MASTER_KEY + OPENAI_API_KEY + ANTHROPIC_API_KEY via keybuzz-ai litellm-secret ESO + keybuzz-litellm manual | Q-1B-5B post Q-1B-5A dedup | high : rotation LITELLM_MASTER_KEY cassere IA SAV transitoire | dry-run dans DEV + sync atomique 3 ns + 0 appel provider durant phase |
| LiteLLM gateway | litellm-secret ESO + litellm-db-secret manual (DOUBLON) + litellm-runtime-key orphan | Q-1B-5A dedup OBLIGATOIRE avant Q-1B-5B | medium : dedup mauvaise -> conflit env-var order | helm chart inspection + Ludovic validation source-of-truth |
| Studio API LLM | keybuzz-studio-api-llm (ANTHROPIC + GEMINI + LLM config) | Q-1B-3E-studio migration ESO + separation config J | medium : Studio API distinct keybuzz-ai LiteLLM, GEMINI nouveau provider | dry-run DEV + manual Ludovic Studio test |
| Amazon orders / fees | amazon-spapi-creds (4 keys) + KEYBUZZ_INTERNAL_TOKEN cross-service (deja rotate Q-1B-2B) | Q-1B-6 Amazon sub-batch | high : re-consent par tenant requis | per-tenant runbook + Ludovic validation tenant si client reel |
| Octopia connector | octopia-credentials ESO (DEV+PROD) | Q-1B-6 Octopia sub-batch | medium : portal regenerate + ESO sync | dry-run + Octopia test endpoint |
| Shopify connector | keybuzz-shopify manual (3 keys dont ENCRYPTION_KEY blocker) | Q-1B-6 Shopify sub-batch scope reduit CLIENT_SECRET only | medium si scope reduit, high si ENCRYPTION_KEY | scope CLIENT_SECRET only + Q-1B-7 strategic ENCRYPTION_KEY |
| Tracking 17track | tracking-17track manual (1 key) | Q-1B-6 17track sub-batch | low : portal regenerate simple | dry-run + portal verification |
| Billing Stripe | keybuzz-stripe-secrets ESO (DEV) + keybuzz-stripe manual (PROD) + keybuzz-admin-v2-stripe (DEV) | Q-1B-3B sub-1 + sub-2 | low si TEST keys, high si PROD live | TEST DEV first + webhook reconfig |
| Outbound email SES | keybuzz-ses-secrets ESO + keybuzz-ses manual PROD | Q-1B-3B sub-3 | medium : OTP/notifications impact | 2-phase rotation + monitoring email rejects |
| Ads dashboards | keybuzz-google-ads + keybuzz-meta-ads manual | Q-1B-3B sub-5/sub-6 | medium : reporting impact | DEV first |
| Admin v2 auth | keybuzz-admin-v2-auth + keybuzz-admin-v2-bootstrap ESO + keybuzz-admin-v2-postgres ESO | Q-1B-3C OAuth (admin separate de Client) | medium : admin login + bootstrap | manual Ludovic admin login validation |
| Backend Amazon Fees module (cross-service) | KEYBUZZ_INTERNAL_TOKEN (deja rotate Q-1B-2B atomique) | aucun re-traitement | low : deja stable Q-1F-2 49min | aucun, valide |

## 16. No fake metrics / no fake events

Verifications conformite Q-1B-3B-0 :

| Interdit | Action verifiee | Verdict |
|---|---|---|
| 0 Stripe API call | aucune commande stripe CLI/API executee | OK |
| 0 purchase / checkout | aucun paiement test | OK |
| 0 SES email | aucun envoi email | OK |
| 0 Slack webhook | aucun curl POST endpoint Slack | OK |
| 0 Ads provider call (Google Ads/Meta) | aucune commande Google/Meta API | OK |
| 0 GA4/CAPI event | aucun fake event tracking | OK |
| 0 marketplace provider call (Amazon SP-API/Shopify/Octopia) | aucune commande | OK |
| 0 17track API call | aucune commande tracking | OK |
| 0 OpenAI/Anthropic/Gemini/LiteLLM provider call | aucune commande API | OK |
| 0 fake business event/metric | aucun event mutationnel | OK |

Toutes observations issues de :
- lecture rapports Q-1B-3A + KEY-323 chain
- git log + git status (read-only)
- aucune commande kubectl mutation
- aucune commande Vault mutation
- aucun curl provider

## 17. Recommended next prompt

Ordre prudent recommande pour la suite Q-1B-3/4/5/6, base sur risk croissant et preconditions :

| Rank | Future prompt | Why now | Why not execution yet | GO required |
|---|---|---|---|---|
| **1** | **Q-1B-3B-1 ORPHANS CLEANUP DRY-RUN/EXEC** | low-risk, 0 workload ref pour 3/5 orphelins (api-auth + octopia + runtime-key conditionnel), zero impact runtime, valide pattern cleanup safe | requires GO Ludovic per secret (5 decisions) + verify helm chart litellm pour litellm-runtime-key | Ludovic per secret |
| **2** | **Q-1B-3D-1 GHCR NAMING HARMONIZATION DRY-RUN** | architectural fix avant rotation PAT, separer naming de rotation | requires GitOps manifest changes (3 ns admin-v2-dev/prod + client-dev) + Ludovic confirme convention ghcr-cred dominante | Ludovic |
| **3** | **Q-1B-5A LLM SECRETS DEDUP DRY-RUN** | obligatoire avant Q-1B-5B rotation LLM, evite conflit env-var, identifie source-of-truth ESO PROD asymmetrie | requires helm chart inspection + Ludovic clarifier ownership litellm-db-secret + litellm-runtime-key + keybuzz-litellm PROD source-of-truth | Ludovic |
| **4** | **Q-1B-3E-inbound-webhook MIGRATION ESO DRY-RUN** | harmoniser PROD vers ESO avant rotation future, evite divergence DEV/PROD | requires GitOps manifest changes ExternalSecret + Vault path keybuzz/prod/inbound-webhook creation + coordination ext webhook senders | Ludovic |
| **5** | **Q-1B-3D-2 GHCR PAT ROTATION** | post-harmonisation phase 1, rotation atomique 12 ns | requires GitHub PAT regenerate + Ludovic Mode B SAFE pattern | Ludovic GitHub |
| **6** | **Q-1B-3B PROVIDER LOW-RISK DRY-RUN/EXEC** | Stripe TEST + Slack + SES + Ads (sub-batched) post-cleanup | requires Ludovic decisions per provider + console access portals | Ludovic per provider |
| **7** | **Q-1B-3C OAUTH LOGIN DRY-RUN/EXEC** | Google/Azure OAuth secrets DEV+PROD, impact UX users | requires Ludovic accept invalidation sessions PROD + window operation + console GCP/Azure | Ludovic |
| **8** | **Q-1B-6 MARKETPLACE OAUTH DRY-RUN** | Amazon SP-API (re-consent tenant), Octopia, 17track, Shopify CLIENT_SECRET only | requires per-tenant runbook + provider portals access | Ludovic per marketplace |
| **9** | **Q-1B-4 INFRA DIRECT DRY-RUN/EXEC** | Redis password, Postgres app roles, MinIO access keys, SMTP - runbook par service | requires runbook par service + window operation + dual-credentials transient strategy | Ludovic per service |
| **10** | **Q-1B-5B LLM ROTATION DRY-RUN/EXEC** | post-dedup Q-1B-5A, rotation OpenAI/Anthropic/Gemini + LITELLM_MASTER_KEY | requires provider portals OpenAI/Anthropic + sync atomique 3 ns + cost monitoring | Ludovic |
| **11** | **Q-1B-7 ADS-ENCRYPTION STRATEGIC DESIGN** | blocker strategique, design dual-read OR empty OR migration | requires DB schema audit + ads-crypto.ts review + decision strategique business | Ludovic strategique |
| **12** | **Q-1F-3 VALIDATION CUMULEE** | post-cycle Q-1B-3/4/5/6 complet, validation cumulative stabilite | requires Q-1B-3/4/5/6 EXEC complete + manual UX Ludovic | Ludovic |
| **13** | **AS.17.0/AS.17.0.1 PROD PROMOTION** | post-cycle complet KEY-323, decisions strategiques marketing | requires Q-1F-3 validation complete + decisions Ludovic | Ludovic strategique |

**Recommandation immediate** : commencer par **Q-1B-3B-1 ORPHANS CLEANUP** (low-risk, valide pattern cleanup + economise cognitive load avant gros lots).

## 18. Decisions Ludovic required (avant prochain prompt CE)

Pour debloquer **Q-1B-3B-1 ORPHANS CLEANUP** :
1. Confirmer ordre prochains lots (Rank section 17) ou ajustement preference Ludovic.
2. Per orphan decision :
   - vault-emergency-token : RETAIN BREAK-GLASS confirme ?
   - keybuzz-api-postgres-static : RETAIN BACKUP OR DELETE ?
   - keybuzz-api-auth : DELETE confirme ?
   - keybuzz-octopia : DELETE confirme ?
   - litellm-runtime-key : INVESTIGATE helm chart avant decide OR DELETE direct ?
3. Pattern Mode B SAFE pour cleanup orphans (rotator non-root scope strict `kubectl delete secret` capability) ou Mode A Ludovic direct ?

Pour debloquer **Q-1B-3D-1 GHCR HARMONIZATION** :
4. Convention dominante ghcr-cred confirmee ? (vs renommer tout en ghcr-secret ?)
5. Sequence : harmonisation DEV first puis PROD ou tout en parallele ?

Pour debloquer **Q-1B-5A LLM DEDUP** :
6. Verify ownership litellm-db-secret + litellm-runtime-key + keybuzz-litellm api-prod (helm chart litellm + dev keybuzz-ai) ?
7. Si Studio API distinct, scope Q-1B-3E-studio en parallele ou apres Q-1B-5A ?

Pour debloquer **Q-1B-3E-inbound-webhook MIGRATION ESO** :
8. Option B confirmee (migrer PROD vers ESO keybuzz-backend-secrets) ?
9. Ext webhook senders PROD a coordonner avant cutover ?

Pour debloquer **Q-1B-3B PROVIDER LOW-RISK** :
10. Stripe scope TEST keys only (recommended) ?
11. SES strategy 2-phase confirme ?
12. Slack webhook DEV only ?
13. Google Ads + Meta Ads scope DEV first ?

Pour debloquer **Q-1B-7 ADS-ENCRYPTION STRATEGIC** :
14. Zero client reel actuel confirme ? (acceptable empty dataset option C)
15. Effort dev dual-read pattern accepte (option B) ?

## 19. Compliance

| Interdit Q-1B-3B-0 | Evidence | Verdict |
|---|---|---|
| Aucune suppression Secret | seul lecture rapport Q-1B-3A | OK |
| Aucune rotation | aucune commande vault kv put/patch | OK |
| Aucun appel provider externe | aucune commande Stripe/SES/Slack/Google/Azure/Ads/Shopify/Octopia/Amazon/17track/OpenAI/Anthropic/Gemini | OK |
| Aucun login provider | aucun curl provider | OK |
| Aucun vault kv get/put/patch/delete/destroy/rollback | aucune commande Vault mutation | OK |
| Aucun vault token create/revoke / policy write/delete | aucun | OK |
| Aucun Shamir/root token | aucun | OK |
| Aucun kubectl apply/create/delete/annotate/rollout restart/scale | aucune commande kubectl mutation | OK |
| Aucun build/docker push/GitOps deploy | aucun | OK |
| Aucun changement source applicatif | aucun grep mutationnel | OK |
| Aucun changement manifest | aucun edit | OK |
| Aucun test paiement/webhook | aucun curl mutation provider | OK |
| Aucun secret/value/base64/JWT/cookie/token/OAuth secret/webhook secret/password affiche | aucun output sensible | OK |
| Bastion install-v3 only | confirme E0 | OK |
| /opt/keybuzz/credentials/ non touche | aucun acces | OK |
| /opt/keybuzz/secrets/ non touche | aucun acces | OK |
| Read-only strict | seul rapport docs-only ecrit local | OK |
| ASCII strict rapport | a verifier post-Write | a verifier |
| STOP avant commit/push | OK E15 STOP | OK |

## 20. Brouillon Linear KEY-323 (a poster par Codex apres commit)

```
AS.17.1Q-1B-3B-0 provider/manual decisions DRY-RUN read-only COMPLETE

Commit rapport Q-1B-3A : 42dd9a6 (provider/manual inventory)
Commit rapport Q-1B-3B-0 : <CE remplira apres push>
Verdict : GO Q-1B-3B-0 DECISIONS READY.

Resume technique :
- Decision matrix 18 items Q-1B-3A transformees en options A/B/C avec recommendation + risk + owner + future phase.
- 5 orphelins classifies :
  - DELETE candidates 3 (keybuzz-api-auth obsolete doublon ESO + keybuzz-octopia doublon ESO + litellm-runtime-key conditionnel helm chart verify).
  - RETAIN + label documentation 2 (vault-emergency-token break-glass + keybuzz-api-postgres-static backup ESO-fallback).
- 5 LLM doublons identifies + asymetrie critique : keybuzz-litellm api-prod manual = SEUL secret PROD pour LITELLM_MASTER_KEY (api-dev a ESO + manual, api-prod a manual seul). Migration ESO PROD requise AVANT rotation Q-1B-5.
- inbound-webhook-key PROD : 4 options + recommended Option B migration ESO via keybuzz-backend-secrets pour harmoniser source-of-truth Vault DEV/PROD.
- GHCR naming : 3 phases (harmonisation BEFORE rotation, rotation PAT atomique 12 ns, canary validation Job-per-ns). Note : keybuzz-client-dev possede les 2 secrets ghcr-cred ET ghcr-secret (confusion architecturale a resoudre).
- Provider low-risk batch : 7 candidats classifies + sub-batching Q-1B-3B sub-1 a sub-6.
- OAuth + marketplace split confirme : Q-1B-3C OAuth login distinct de Q-1B-3B (impact UX users), Q-1B-6 marketplace OAuth distinct (impact tenant + Shopify ENCRYPTION_KEY blocker).
- 2 Blockers strategiques documentes :
  - keybuzz-ads-encryption : Options C empty (zero client reel) OR B dual-read OR D versioned, decision strategique Q-1B-7.
  - Shopify SHOPIFY_ENCRYPTION_KEY : Option A scope reduit CLIENT_SECRET only court-terme + Q-1B-7 strategic ENCRYPTION_KEY long-terme.
- 11 non-secret items candidats migration ConfigMap (Stripe price IDs, URLs publiques, OAuth client IDs, LLM config) - Q-1B-3F low-priority cleanup.
- AI feature parity matrix 12 features impactees avec validation future par batch.
- Conformite : 0 secret/value affiche, 0 provider externe call, 0 mutation, 0 build/deploy/restart.

Ordre recommande next prompts (13 lots) :
1. Q-1B-3B-1 ORPHANS CLEANUP (low-risk, 3 deletes safe + 2 retains documented)
2. Q-1B-3D-1 GHCR NAMING HARMONIZATION (architectural fix avant rotation)
3. Q-1B-5A LLM SECRETS DEDUP (obligatoire avant Q-1B-5B rotation)
4. Q-1B-3E-inbound-webhook MIGRATION ESO (harmoniser PROD)
5. Q-1B-3D-2 GHCR PAT ROTATION (post-harmonisation)
6. Q-1B-3B PROVIDER LOW-RISK (Stripe TEST + SES + Slack + Ads)
7. Q-1B-3C OAUTH LOGIN (Google/Azure)
8. Q-1B-6 MARKETPLACE OAUTH (Amazon + Octopia + 17track + Shopify scope reduit)
9. Q-1B-4 INFRA DIRECT (Redis + Postgres + MinIO + SMTP)
10. Q-1B-5B LLM ROTATION (post-dedup)
11. Q-1B-7 ADS-ENCRYPTION STRATEGIC DESIGN (blocker)
12. Q-1F-3 VALIDATION CUMULEE
13. AS.17.0/AS.17.0.1 PROD PROMOTION (post-cycle complet)

15 decisions Ludovic requises avant Q-1B-3B-1 ORPHANS CLEANUP (cf section 18 rapport).

Gaps :
- keybuzz-ads-encryption + Shopify ENCRYPTION_KEY blockers strategiques (decision Ludovic).
- LLM api-prod asymetrie ESO (migration ESO PROD avant rotation Q-1B-5).
- inbound-webhook-key PROD divergence DEV (migration ESO Option B recommandee).
- GHCR client-dev double secret (ghcr-cred + ghcr-secret).
- 5 orphelins decisions per secret.
- backfill-scheduler ImagePullBackOff hors scope.

NO GO Q-1B-3B EXEC, Q-1B-3C, Q-1B-3D EXEC, Q-1B-3E EXEC, Q-1B-4, Q-1B-5, Q-1B-6, Q-1B-7 et PROD promotion AS.17.0/AS.17.0.1 maintenus.

Pas de changement status KEY-323 ou KEY-322 sans GO supplementaire.
```

STOP final : rapport pret, en attente GO Ludovic commit/push E15.

Aucun enchainement sur Q-1B-3B EXEC.
Aucun enchainement sur Q-1B-4/5/6/7.
Aucun enchainement sur PROD promotion AS.17.0/AS.17.0.1.
