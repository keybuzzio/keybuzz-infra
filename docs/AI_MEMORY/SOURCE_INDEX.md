# Index des sources KeyBuzz

> Derniere mise a jour : 2026-04-21

## Sources principales

| Source | Role | Notes |
|---|---|---|
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\PROJECT_OVERVIEW.md` | Vision consolidee | Synthese globale produit/tech a lire apres `CURRENT_STATE.md`. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\RULES_AND_RISKS.md` | Regles/pieges | Stop conditions, risques multi-tenant, Git/runtime drift. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\DOCUMENT_MAP.md` | Carte documentaire | Inventaire 2 119 documents et familles de sources. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\OPERATIONAL_SURFACES.md` | Carte des surfaces | Client/client-dev, admin/admin-dev, Studio/studio-dev, seller/seller-dev, API et infra. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\PHASES_FEATURES_AND_CURSOR_CONTEXT.md` | Memoire PH/Cursor | Role des 956 phases, familles features, agents Cursor comme executants, regle de prompt. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CLIENT_CONTEXT.md` | Contexte client | Pages, BFF Next.js, pieges Inbox/client. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\API_AUTOPILOT_CONTEXT.md` | Contexte API/Autopilot | API SaaS, IA, billing, Autopilot, blocage plan gate courant. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\ADMIN_CONTEXT.md` | Contexte admin v2 | Routes admin, role ops, URL interne API critique. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\SERVER_SIDE_TRACKING_CONTEXT.md` | Contexte tracking server-side | Pipeline marketing SaaS/Admin, differences prompts CE SaaS vs CE Admin, etat T8.7. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\STUDIO_CONTEXT.md` | Contexte Studio | Explique comment Asphalte/Smoozii alimente Studio, Knowledge, Learning, Templates, Strategy et generation. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\SELLER_CONTEXT.md` | Contexte seller | Seller API/client, seller-dev, nomenclature `seller` et verification runtime. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\INFRA_CONTEXT.md` | Contexte infra | K8s, DB, GitOps, source-of-truth, manifests. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\INFRA_SERVERS_INSTALL_CONTEXT.md` | Serveurs/install | Inventaire 49 serveurs v3, endpoints internes, sommaire modules 2-9. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\FEATURES_DEPLOYED_CONTEXT.md` | Features deployees | Resume Feature Truth Matrix V2 : 31 green, 2 orange, 7 red. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\MARKETING_CORPUS_INDEX.md` | Index corpus Studio | Classification marketing/Asphalte/Smoozii pour ingestion Studio. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\CONTEXT_STRATEGY.md` | Strategie memoire | Decoupe conseillee pour eviter un fichier de contexte trop gros et fragile. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\KeyBuzz_2026_complet_2026-04-21.txt` | Conversation complete actuelle | 69 460 lignes, 2,6 Mo. La fin contient un prompt devenu depasse par les rapports suivants. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\RECAPITULATIF PHASES.md` | Historique chronologique des phases | Source utile pour comprendre PH0 -> PH154 et les decisions produit/tech. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PROMPT-NOUVEL-AGENT.md` | Ancien prompt de reprise | Important mais date du 2026-03-27, donc incomplet pour les phases du 2026-04-21. |
| `C:\DEV\KeyBuzz\V3\.cursor\rules\process-lock.mdc` | Regle Cursor | Cursor doit respecter source de verite, repo clean, un build/deploy max, rapport, stop conditions. |
| `C:\DEV\KeyBuzz\KeyBuzz 2026.txt` | Conversation ou synthese racine | 605 Ko, plus ancienne que le fichier complet du 2026-04-21. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\KeyBuzz_2026.txt` | Conversation/synthese intermediaire | 1,2 Mo, antecedente au fichier complet. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\KeyBuzz SaaS.txt` | Contexte SaaS | 885 Ko. |
| `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-UNIFIED.md` | Knowledge transfer tracking | Source active 2026-04-22 pour server-side tracking, coordination Agent SaaS API et Agent Admin V2. |
| `C:\DEV\KeyBuzz\keybuzz-admin-v2\Reconstruction_Admin_V2.txt` | Conversation Admin V2 | Source longue de style Agent Admin, reconstruction Admin V2, prompts PH-ADMIN, real data enforcement et source-of-truth. |

## Sources recentes critiques

| Source | Verdict / apport |
|---|---|
| `PH-AUTOPILOT-ESCALATION-CONSUME-DIAGNOSTIC-01.md` | Cause racine escalation consume : status invalide/ecrase, handoff incomplet. |
| `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01.md` | Fix minimal DEV : `status='pending'`, image `v3.5.91-autopilot-escalation-handoff-fix-dev`. |
| `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-PROD-PROMOTION-01.md` | Promotion PROD du fix handoff, image `v3.5.91-autopilot-escalation-handoff-fix-prod`. |
| `PH-AUTOPILOT-E2E-TRUTH-AUDIT-01.md` | Etat le plus important : Autopilot bloque pour `ecomlg-001` par plan gate PRO. |
| `PH-AUTOPILOT-ORDER-ID-CONTEXT-AUDIT-01.md` | Audit contexte order_id pour Autopilot. |
| `PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-01.md` | Fix DEV prompt order_id. |
| `PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-PROD-PROMOTION-01.md` | Promotion PROD fix order_id. |
| `PH-AUTOPILOT-INBOUND-TRIGGER-RECOVERY-01.md` | Recovery trigger inbound Autopilot. |
| `PH-AUTOPILOT-INBOUND-TRIGGER-PROD-PROMOTION-01.md` | Promotion PROD trigger inbound. |
| `PH-AUTOPILOT-REAL-TENANT-BEHAVIOR-AUDIT-01.md` | Verite tenants reels : SWITAA/compta AUTOPILOT, Aide IA OK, auto-open PROD bloque car backend ne declenche pas API Autopilot. |
| `PH-INBOUND-PIPELINE-TRUTH-04-REPORT.md` | Ancien fix backend -> API Autopilot apres webhook inbound; a relire avant tout nouveau patch backend. |
| `PH-AUTOPILOT-BACKEND-CALLBACK-01.md` | Callback backend -> API restaure en DEV, connector-agnostic, image `v1.0.45-autopilot-backend-callback-dev`; PROD non touchee; attention `ExternalMessage P2021` et port PROD `API_INTERNAL_URL`. |
| `PH-AUTOPILOT-BACKEND-DEV-INBOUND-RECEPTION-RECOVERY-01.md` | Reception inbound DEV restauree : `ExternalMessage` migre de Prisma/keybuzz_backend vers productDb/keybuzz, image `v1.0.46-ph-recovery-01-dev`; vrai email SWITAA recu par Ludovic apres rapport. |
| `PH-AUTOPILOT-BACKEND-REAL-EMAIL-READINESS-01.md` | Vrai email SWITAA DEV valide de bout en bout, Autopilot reply/draft/outbound OK, verdict GO PROD promotion avec tag `v1.0.46-ph-recovery-01-prod` et `API_INTERNAL_URL` PROD sur `:80`. |
| `PH-AUTOPILOT-BACKEND-CALLBACK-PROD-PROMOTION-01.md` | Backend callback promu PROD, auto-open restaure; observation utilisateur restante : validation d'un draft avec promesse d'escalade ne cree pas le handoff, a auditer cote API consume/classification. |
| `PH-AUTOPILOT-CONSUME-PROMISE-ESCALATION-TRUTH-01.md` | Cause racine promise escalation : regex trop etroites (`je vais + infinitif`) + consume ne redetecte pas les promesses pour `DRAFT_GENERATED`; fix DEV recommande promise detection + guardrail consume. |
| `PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-FIX-01.md` | Fix DEV API : helper partage 37 patterns, guardrail consume, correction bug SQL `//` dans requete escalation; image `v3.5.92-autopilot-promise-detection-guardrail-dev`, commit `fcf8d67c`. |
| `PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-PROD-PROMOTION-01.md` | Fix API promu PROD : `DRAFT_GENERATED` avec promesse escalade, `ESCALATION_DRAFT` OK, non-promesse OK; image `v3.5.92-autopilot-promise-detection-guardrail-prod`, digest `sha256:d4a26f...`. |
| `PH-AUTOPILOT-GITOPS-DRIFT-RECONCILIATION-01.md` | Dette process fermee : manifest/runtime/annotation API DEV+PROD alignes, zero drift fonctionnel, process-lock durci contre `kubectl set image/env/edit/patch`. |
| `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01.md` | Fondation marketing tenant-native DEV : `tenant_id` canonical, metrics `?tenant_id`, colonnes platform-native destinations, image `v3.5.97`; PROD encore `v3.5.95`. |
| `PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01.md` | Meta CAPI native per-tenant DEV : adapter, routing `meta_capi`, CRUD, token masque, image `v3.5.98`; PROD bloquee avant vraie validation Meta. |
| `PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-AUDIT.md` | Audit technique Meta CAPI : credentials, routing, token non chiffre at-rest, tenant safety, non-regression. |
| `PH-T8.7B.1-META-CAPI-REAL-VALIDATION-01.md` | Validation reelle Meta DEV : pixel/test event code, `StartTrial` accepte par Meta avec `events_received: 1`, token masque, pas de fuite, isolation tenant A/B; pas de build. |
| `PH-T8.7B.2-META-CAPI-TEST-ENDPOINT-FIX-01.md` | Fix DEV endpoint test Meta : `PageView` standard au lieu de `ConnectionTest` pour `meta_capi`, webhooks inchanges, image `v3.5.99`, commit API `9b461717`; pret promotion PROD cumulative. |
| `PH-T8.7B.2-META-CAPI-PROD-PROMOTION-01.md` | Promotion PROD cumulative T8.7A+T8.7B+T8.7B.2 : API PROD `v3.5.99-meta-capi-test-endpoint-fix-prod`, digest `sha256:bcd51da...`, GitOps strict, Meta CAPI live, prochaine phase probable CE Admin UI. |
| `PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-01.md` | Fix securite DEV API : redaction centralisee des tokens Meta dans erreurs, responses, delivery logs et pod logs; image `v3.5.100`, commit `f5d6793b`, PROD encore `v3.5.99`; a promouvoir avant Admin PROD. |
| `PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01.md` | Fix securite Meta CAPI promu PROD : API `v3.5.100`, digest `sha256:c7f6da...`, aucun token dans responses/delivery logs/pod logs, Admin PROD debloque cote API. |
| `PH-ADMIN-T8.7C-META-CAPI-DESTINATIONS-UI-01.md` | Admin DEV `v2.11.1` : UI `/marketing/destinations` supporte `webhook` + `meta_capi`, test `PageView`, token safe, delivery logs PageView; avant PROD, demander validation navigateur reelle. |
| `PH-ADMIN-T8.7C-META-CAPI-UI-REAL-BROWSER-VALIDATION-01.md` | Validation navigateur Admin DEV : flows webhook/meta OK mais bloqueurs pre-PROD detectes : token input text, token dans erreur Meta/delivery log, destinations test non nettoyees, suppression confirm non validee. |
| `PH-ADMIN-T8.7C-META-CAPI-UI-HARDENING-01.md` | Admin DEV `v2.11.2` : redaction UI/proxy/logs, ConfirmModal, nettoyage tests; bloqueur restant : API DELETE destination absente, suppression UI 404. |
| `PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-01.md` | API DEV `v3.5.101` : route DELETE destinations en soft delete, tenant-scoped, logs preserves; prochaine validation Admin ConfirmModal DEV avant promotion API PROD. |
| `PH-ADMIN-T8.7C-CONFIRMMODAL-DELETE-E2E-VALIDATION-01.md` | Validation Admin DEV : ConfirmModal supprime Webhook et Meta CAPI via API DELETE, soft delete DB confirme; GO promotion API PROD. |
| `PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-PROD-PROMOTION-01.md` | API PROD `v3.5.101` : route DELETE live, soft delete tenant-scoped, logs preserves, Admin PROD debloque pour promotion `v2.11.2`. |
| `PH-T8.8-BUSINESS-EVENTS-INBOUND-SOURCES-ARCHITECTURE-01.md` | Audit inbound business events : outbound sain, 0 destination active involontaire, mais `ad_spend` global et `/metrics/overview` CAC/ROAS non tenant-scoped sont critiques; architecture cible `business_event_sources`, `business_events_inbound`, `ad_platform_accounts`, `ad_spend_tenant`; Addingwell optionnel avec source owner/event_id anti-doublon. |
| `PH-T8.8A-AD-SPEND-TENANT-SAFETY-HYGIENE-01.md` | DEV `v3.5.102` : `ad_platform_accounts` + `ad_spend_tenant`, backfill KeyBuzz Consulting DEV, `/metrics/overview?tenant_id` lit uniquement le spend tenant; attention avant PROD : `/metrics/import/meta` global sans tenant_id ecrit encore dans `ad_spend` et doit etre verrouille/audite. |
| `PH-T8.8A.1-AD-SPEND-GLOBAL-IMPORT-LOCK-01.md` | DEV `v3.5.103` : verrou import Meta global, `/metrics/import/meta` sans `tenant_id` retourne `400 TENANT_ID_REQUIRED_FOR_AD_SPEND_IMPORT`, plus aucun `INSERT INTO ad_spend`; pret promotion PROD cumulative avec backfill KBC et cleanup 3 residues. |
| `PH-T8.8A.2-AD-SPEND-TENANT-SAFETY-PROD-PROMOTION-01.md` | PROD `v3.5.103` : `ad_spend_tenant` live, backfill KBC PROD `keybuzz-consulting-mo9zndlk`, import global bloque, tenant metrics sans fuite globale, 3 residues ecomlg soft-deleted. |
| `PH-ADMIN-T8.8A.3-METRICS-TENANT-SCOPE-UI-FIX-01.md` | Admin DEV `v2.11.3` : proxy `/api/admin/metrics/overview` forwarde `tenant_id`, UI envoie snake_case; KBC voit 512 EUR, eComLG ne voit plus le spend global; pret promotion PROD Admin. |
| `PH-ADMIN-T8.8A.4-METRICS-TENANT-SCOPE-PROD-PROMOTION-01.md` | Admin PROD `v2.11.3` : metrics tenant scope live, KBC voit 512 EUR, eComLG no-data; integration guide accessible mais doc tenant sources/spend reste a mettre a jour apres T8.8B/T8.8C. |
| `PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01.md` | API DEV `v3.5.104` : routes `/ad-accounts`, adapter Meta Ads tenant et sync manuelle vers `ad_spend_tenant`; aucun write global; blocage P0 `token_ref` non exploitable, secret store tenant requis avant PROD. |
| `PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01.md` | API DEV `v3.5.105` : `token_ref` Ads resolvable via AES-256-GCM, fallback `META_ACCESS_TOKEN` supprime, KBC DEV sync via token chiffre; PROD inchangee, CE Admin UI comptes Ads peut demarrer. |
| `PH-ADMIN-T8.8D-AD-ACCOUNTS-META-ADS-UI-01.md` | Admin DEV `v2.11.4` : UI `/marketing/ad-accounts`, proxies ad-accounts, navigation Marketing; validation KBC/eComLG OK mais dette rollback imperatif + hardening token fallback a corriger. |
| `PH-ADMIN-T8.8D.1-AD-ACCOUNTS-UI-HARDENING-VALIDATION-01.md` | Admin DEV `v2.11.5` : UI Ads Accounts durcie, `redactTokens`, fallback token `Masked`, icons sidebar, validation navigateur complete; pret Admin PROD apres promotion API PROD T8.8B+C. |
| `PH-T8.8C-PROD-PROMOTION-AD-ACCOUNTS-SECRET-STORE-01.md` | API PROD `v3.5.105` : `/ad-accounts` + secret store Ads live, KBC PROD sync tenant-scoped OK, `token_ref` chiffre, aucun token global; Admin PROD debloque. |
| `PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md` | Admin metrics fix : PROD doit appeler le service K8s API sans `:3001`. |
| `PH152-GIT-SOURCE-OF-TRUTH-LOCK-01.md` | Source-of-truth Git : pas de build depuis fichiers non committe, pre-build check obligatoire. |
| `PH147.RULES-CURSOR-PROCESS-LOCK-01.md` | Regles Cursor anti-drift : source, build, repo clean, deploiement, rapports, stop conditions. |
| `PH154.1.3-INBOX-VISUAL-PARITY-FIX-STRICT-01.md` | Derniere reconstruction Inbox DEV lue : image `v3.5.84-ph154.1.3-inbox-fix-dev`, validation humaine attendue. |

## Sources structurantes produit

| Source | Role |
|---|---|
| `FEATURE_TRUTH_MATRIX.md` | Matrice de verite features. |
| `FEATURE_TRUTH_MATRIX_V2.md` | Version etendue matrice features. |
| `feature_registry.json` | Registry structure des features. |
| `DB-ARCHITECTURE-CONTRACT.md` | Contrat architecture DB. |
| `DB-ACCESS-MAP.md` | Cartographie acces DB. |
| `DB-TABLE-MATRIX.md` | Matrice tables. |
| `BUILD-AND-PROMOTION-PROCEDURE.md` | Procedure build/promotion. |
| `STUDIO-MASTER-REPORT.md` | Etat Studio. |
| `STUDIO-ARCHITECTURE.md` | Architecture Studio. |
| `STUDIO-RULES.md` | Regles Studio. |
| `C:\DEV\KeyBuzz\V3\marketing\RAPPORT-COMPLET-SMOOZII-ASPHALTE-POUR-CHATGPT.md` | Corpus Studio / marketing | Rapport compile de 62 DOCX : Smoozii, Asphalte, acquisition, conversion, automation, ton, learning. A utiliser pour Studio, pas pour trancher l'architecture runtime. |

## Pattern de lecture pour une nouvelle conversation

1. Lire `AI_MEMORY/CURRENT_STATE.md`.
2. Lire le rapport de phase le plus recent cite dans le point de reprise.
3. Lire `RECAPITULATIF PHASES.md` uniquement sur les sections pertinentes.
4. Lire le code local seulement apres avoir identifie la phase et le scope.
5. Si un fichier de conversation se termine sur un prompt, verifier toujours si un rapport plus recent existe deja.
6. Si la tache touche Studio, contenu, strategie, generation, templates ou learning, lire `AI_MEMORY/STUDIO_CONTEXT.md` et le rapport Smoozii/Asphalte avant de prompt un agent.
