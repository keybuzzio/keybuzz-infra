# Etat courant KeyBuzz

> Date : 2026-04-21
> Contexte : reprise fiable apres analyse des docs locales KeyBuzz.

## Projet

KeyBuzz est un SaaS B2B de support client et automatisation SAV pour vendeurs e-commerce. Le produit combine :

- inbox multi-canal;
- cockpit commandes;
- IA SAV controlee;
- autopilot avec garde-fous;
- multi-tenant strict;
- billing Stripe/KBActions;
- integrations Amazon, Octopia, Shopify et tracking marketing.

## Architecture connue

Composants principaux :

- `keybuzz-api` : Fastify/Node.js/TypeScript, coeur API SaaS.
- `keybuzz-client` : Next.js, application client SaaS.
- `keybuzz-admin-v2` : Next.js/Metronic, cockpit admin.
- `keybuzz-backend` / `seller-api` : backend complementaire et integrations.
- `keybuzz-infra` : manifests K8s, GitOps, docs, rapports.
- `keybuzz-studio` et `keybuzz-studio-api` : module Studio/Growth.

Infra :

- Kubernetes kubeadm HA, pas K3s.
- Postgres HA via Patroni, acces via HAProxy `10.0.0.10:5432`.
- Redis, RabbitMQ, Vault/External Secrets selon historique.
- GitOps strict via manifests dans `keybuzz-infra`.

## Regles absolues a conserver

- Toujours lire les rapports recents avant de conclure.
- DEV avant PROD.
- PROD uniquement apres validation explicite de Ludovic.
- Patch minimal, pas de rework massif.
- Ne jamais utiliser `:latest`.
- Ne pas hardcoder tenant IDs, URLs ou secrets.
- Respecter le multi-tenant strict.
- Cote client, `useTenant().currentTenantId` est la source fiable.
- Attention aux deux DB Amazon : product DB `keybuzz` et backend Prisma `keybuzz_backend`.
- Pour les services K8s internes, utiliser le port service, pas le port container.
- Documentation et prompts en francais.

## Point de reprise reel au 2026-04-21

### Mise a jour apres `PH-AUTOPILOT-BACKEND-CALLBACK-01.md`

Le point le plus recent n'est plus le plan gate.

Etat confirme :

1. `PH-AUTOPILOT-REAL-TENANT-BEHAVIOR-AUDIT-01.md`
   - SWITAA et compta.ecomlg sont AUTOPILOT en DEV et PROD.
   - Aide IA fonctionne.
   - Auto-open fonctionne en DEV.
   - Auto-open PROD est bloque car le chemin inbound reel passe par `keybuzz-backend`, qui ne declenchait pas `keybuzz-api`.

2. `PH-AUTOPILOT-BACKEND-CALLBACK-01.md`
   - Callback backend -> API restaure en DEV dans `keybuzz-backend`.
   - Source backend : branche `main`.
   - Image DEV : `v1.0.45-autopilot-backend-callback-dev`.
   - Digest : `sha256:9ff366d1d86cd7ecd3c1c72f95746eb3e8c5830d5b75770f4eb13bdae21d5b51`.
   - Fix connector-agnostic : place dans `createInboxConversation()`, donc applicable aux connecteurs qui utilisent ce service.
   - Validation DEV sur `amazon`, `octopia`, `email` via creation directe de conversation.
   - PROD non touchee.

3. `PH-AUTOPILOT-BACKEND-DEV-INBOUND-RECEPTION-RECOVERY-01.md`
   - Reception inbound DEV restauree.
   - Cause racine : `ExternalMessage` migree vers product DB par PH-TD-05, mais le webhook backend utilisait encore Prisma sur `keybuzz_backend`, provoquant `P2021`.
   - Fix DEV : `inboundEmailWebhook.routes.ts` utilise maintenant `productDb.query()` pour `ExternalMessage`.
   - Image DEV : `v1.0.46-ph-recovery-01-dev`.
   - Callback Autopilot de PH-CALLBACK-01 conserve et fonctionnel.
   - Ludovic a ensuite valide un vrai email recu dans KeyBuzz DEV via `amazon.switaa-sasu-mnc1x4eq.fr.ulnllr@inbound.keybuzz.io`.

4. `PH-AUTOPILOT-BACKEND-REAL-EMAIL-READINESS-01.md`
   - Verdict : GO PROD PROMOTION.
   - Vrai email SWITAA DEV valide de bout en bout.
   - `autopilot_reply` 7 secondes apres inbound, draft applique, outbound envoye.
   - Reponse coherent avec commande `171-544451-556985`, colis `1Z121122512368`, contexte reparation.
   - PROD readiness : build cible `v1.0.46-ph-recovery-01-prod`, meme commit backend `f0f0d18`, correction `API_INTERNAL_URL` PROD vers `:80`, rollback `v1.0.44-ph150-thread-fix-prod`.

5. `PH-AUTOPILOT-BACKEND-CALLBACK-PROD-PROMOTION-01.md`
   - Backend callback promu en PROD.
   - Image backend PROD : `v1.0.46-ph-recovery-01-prod`.
   - `API_INTERNAL_URL` PROD corrige vers le port service `:80`.
   - Pipeline inbound PROD valide jusqu'au draft Autopilot : webhook, ExternalMessage, conversation, callback API, `ai_action_log`, `DRAFT_GENERATED`.
   - Observation terrain apres promotion : le volet auto-open fonctionne et la suggestion est coherente, mais quand le draft promet une escalade et que Ludovic valide/envoie, l'escalade ne se materialise pas.

6. `PH-AUTOPILOT-CONSUME-PROMISE-ESCALATION-TRUTH-01.md`
   - Cause racine identifiee cote API Autopilot.
   - Cas PROD `cmmo8sz5rd8f173c865e32cb4` : draft avec promesses humaines, classe `DRAFT_GENERATED`, consume/envoi effectue, `escalation_status=none`.
   - Les detecteurs de promesses sont trop etroits (`je vais + infinitif`) et ratent `je transmets`, `je verifierai`, `notre equipe va verifier`, etc.
   - Le consume ne redetecte pas les promesses pour un `DRAFT_GENERATED`; il fait confiance a la classification initiale.

7. `PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-FIX-01.md`
   - Fix DEV effectue.
   - Image API DEV : `v3.5.92-autopilot-promise-detection-guardrail-dev`.
   - Helper partage `src/lib/promise-detection.ts` cree pour engine, consume, reply et AI assist.
   - Guardrail consume : `DRAFT_GENERATED` contenant une promesse humaine est re-detecte au consume et escalade.
   - Bug SQL critique corrige : un commentaire JS dans une requete SQL cassait l'escalade `ESCALATION_DRAFT` depuis `7265d29a`.
   - PROD intouchee : API PROD reste `v3.5.91-autopilot-escalation-handoff-fix-prod`.

8. `PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-PROD-PROMOTION-01.md`
   - Fix promise detection + guardrail promu en PROD.
   - Image API PROD : `v3.5.92-autopilot-promise-detection-guardrail-prod`.
   - Digest : `sha256:d4a26f468e11c13a7c0db9ba1afcdb1c24709a4e9ae426d433f17d36e3fa92ad`.
   - Source : `ph147.4/source-of-truth`, commit `fcf8d67c`.
   - Validation PROD :
     - `DRAFT_GENERATED` avec promesse -> escalade OK, `status=pending`.
     - `ESCALATION_DRAFT` -> escalade OK, bug SQL corrige.
     - Non-promesse -> pas d'escalade.
   - Ludovic a fait des tests terrain et tout semble OK.
   - Ecart process : CE a utilise `kubectl set image` malgre la regle GitOps strict; le manifest GitOps a ete mis a jour, mais cette derive doit rester interdite dans les prompts futurs.

9. `PH-AUTOPILOT-GITOPS-DRIFT-RECONCILIATION-01.md`
   - Dette process GitOps fermee.
   - Manifest GitOps API PROD et runtime etaient deja alignes sur `v3.5.92-autopilot-promise-detection-guardrail-prod`; zero drift fonctionnel.
   - Annotation `last-applied` etait obsolete, corrigee par `kubectl apply -f` depuis manifest, sans rollout, sans restart, meme digest.
   - Meme reconciliation effectuee en DEV.
   - `.cursor/rules/process-lock.mdc` durci : interdiction explicite des commandes imperatives `kubectl set image`, `kubectl set env`, `kubectl edit`, `kubectl patch` sauf reconciliation depuis manifest.

Points a ne pas oublier avant PROD :

- `API_INTERNAL_URL` PROD est documente incorrect : `:3001` alors que le service K8s API PROD expose `:80`.
- Le webhook HTTP complet DEV fonctionne apres `PH-AUTOPILOT-BACKEND-DEV-INBOUND-RECEPTION-RECOVERY-01`; il faut maintenant faire consigner par CE les preuves autour du vrai email SWITAA envoye par Ludovic.
- Ne pas refaire le callback backend : il fonctionne DEV/PROD.
- Etat courant : Autopilot backend callback + auto-open + promise detection + consume guardrail + escalation handoff sont valides DEV/PROD.
- Dette GitOps imperative fermee : runtime API DEV/PROD = manifest = annotation.
- Prochaine action : surveillance terrain. Ne pas relancer de fix sans nouveau symptome concret.

La conversation `KeyBuzz_2026_complet_2026-04-21.txt` se termine sur le prompt `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01`, mais les rapports locaux montrent que cette phase a ensuite ete executee.

Etat confirme par rapports :

1. `PH-AUTOPILOT-ESCALATION-CONSUME-DIAGNOSTIC-01.md`
   - Cause racine identifiee : `ESCALATION_DRAFT` pose `status = 'escalated'`, puis le reply flow remet `status = 'open'`.
   - L'escalade DB fonctionne (`escalation_status`, `escalation_reason`, etc.).
   - Handoff incomplet : pas d'assignation auto, pas de notification.

2. `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01.md`
   - Fix minimal DEV effectue.
   - `src/modules/autopilot/routes.ts` : `status = 'escalated'` remplace par `status = 'pending'`.
   - Image DEV : `v3.5.91-autopilot-escalation-handoff-fix-dev`.
   - Commit source : `7265d29a`.

3. `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-PROD-PROMOTION-01.md`
   - Fix promu en PROD.
   - Image PROD : `v3.5.91-autopilot-escalation-handoff-fix-prod`.
   - Commit infra : `13f56d5`.
   - Verdict : `ESCALATION HANDOFF FIXED IN PROD - WORKFLOW HUMAN READY`.

4. `PH-AUTOPILOT-E2E-TRUTH-AUDIT-01.md`
   - Audit lecture seule DEV + PROD.
   - Verdict : `NO GO - cause racine = plan gate`.
   - Autopilot fonctionne pour un tenant AUTOPILOT (`switaa-sasu-mnc1x4eq` en DEV).
   - Autopilot ne fonctionne pas pour `ecomlg-001` car le tenant est en plan PRO.
   - `ai-mode-engine.ts` force PRO a `maxMode='suggestion'`, donc `canUseAutopilot` bloque.
   - Client/BFF/API/consume sont en place; le blocage principal est business/plan.

## Prochaine decision importante

Le prochain vrai sujet n'est plus le handoff escalation ni le plan gate, mais la readiness PROD du callback backend -> API.

## Point de reprise tracking server-side au 2026-04-22

La ligne server-side tracking / Meta CAPI est maintenant promue en PROD :

1. `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01.md`
   - DEV uniquement.
   - Commit API : `db14cb03`.
   - Image DEV : `v3.5.97-marketing-tenant-foundation-dev`.
   - Ajoute la fondation tenant marketing : `tenant_id` canonical, `/metrics/overview?tenant_id=...`, colonnes platform-native sur `outbound_conversion_destinations`.

2. `PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01.md`
   - DEV uniquement.
   - Commit API : `5661e215`.
   - Image DEV : `v3.5.98-meta-capi-native-tenant-dev`.
   - Ajoute l'adapter Meta CAPI, le routing `webhook` vs `meta_capi`, le mapping `StartTrial`/`Purchase`, le token masking et les delivery logs.

3. `PH-T8.7B.1-META-CAPI-REAL-VALIDATION-01.md`
   - Validation reelle DEV sans build.
   - Meta accepte un event `StartTrial` avec `events_received: 1`.
   - Token masque, absent des logs et delivery logs, isolation tenant A/B confirmee.

4. `PH-T8.7B.2-META-CAPI-TEST-ENDPOINT-FIX-01.md`
   - DEV uniquement.
   - Commit API : `9b461717`.
   - Image DEV : `v3.5.99-meta-capi-test-endpoint-fix-dev`.
   - Digest : `sha256:8ce4f07d275538de2dbd02cdd22b5a9fb7c986ecaa402aa48e8b2273ea344ad9`.
   - Le bouton/test endpoint Meta envoie maintenant un `PageView` standard accepte par Meta; les webhooks gardent `ConnectionTest`.

5. `PH-T8.7B.2-META-CAPI-PROD-PROMOTION-01.md`
   - Promotion PROD cumulative terminee.
   - Commit API : `9b461717`.
   - Image PROD : `v3.5.99-meta-capi-test-endpoint-fix-prod`.
   - Digest PROD : `sha256:bcd51da92d726a55494775398d68c36357e5c310d3be4ba2c2b3fb523306c912`.
   - Infra commit : `a7ba43e`.
   - GitOps strict respecte, aucun `kubectl set image`.
   - Metrics global/tenant OK, destination `meta_capi` OK, token masque, test endpoint `PageView` confirme dans delivery logs, isolation tenant OK.

6. `PH-ADMIN-T8.7C-META-CAPI-DESTINATIONS-UI-01.md`
   - Admin DEV ajoute l'UI Meta CAPI dans `/marketing/destinations`.
   - Image Admin DEV : `v2.11.1-meta-capi-destinations-ui-dev`.
   - Commit Admin : `9226f1f`.
   - PROD Admin inchangee : `v2.11.0-tenant-foundation-prod`.

7. `PH-ADMIN-T8.7C-META-CAPI-UI-REAL-BROWSER-VALIDATION-01.md`
   - Validation navigateur DEV OK sur les flows webhook et Meta.
   - Bloqueurs avant PROD Admin : input token Meta en `type=text`, erreur Meta/delivery logs pouvaient exposer le token, destinations test non nettoyees, suppression non validee en headless.

8. `PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-01.md`
   - Fix securite API DEV.
   - Commit API : `f5d6793b`.
   - Image DEV : `v3.5.100-meta-capi-error-sanitization-dev`.
   - Digest DEV : `sha256:4f148176d26f65189d9550df0cf7bdd6bd6d811e4af6b5eb7bbf70ff3ae2987e`.
   - Helper `redact-secrets.ts` applique aux erreurs Meta, reponses API, delivery logs DB/API et logs pod.
   - PROD API encore `v3.5.99-meta-capi-test-endpoint-fix-prod`.

9. `PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01.md`
   - Fix securite API promu en PROD.
   - Commit API : `f5d6793b`.
   - Image PROD : `v3.5.100-meta-capi-error-sanitization-prod`.
   - Digest PROD : `sha256:c7f6da86dda0726c0b35653e9dd01ca2ac506acaa6cf8d021fb39594c30e6cfc`.
   - Infra commit GitOps : `7e67d58`; rapport : `329dc50`.
   - Reponse API, delivery logs DB/API et logs pod ne contiennent plus de token brut; `[REDACTED_TOKEN]` valide.
   - Admin V2 non modifie, mais debloque cote API.

10. `PH-ADMIN-T8.7C-META-CAPI-UI-HARDENING-01.md`
   - Admin DEV durci : `v2.11.2-meta-capi-ui-hardening-dev`.
   - Defense-in-depth UI/proxy/logs, ConfirmModal, nettoyage tests.
   - Bloqueur detecte : suppression UI impossible car API `DELETE /outbound-conversions/destinations/:id` absente.

11. `PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-01.md`
   - API DEV ajoute la route DELETE destination.
   - Commit API : `df4a2c5e`.
   - Image DEV : `v3.5.101-outbound-destinations-delete-route-dev`.
   - Digest DEV : `sha256:12f9d1fd7fb236282b15ef3e51e7aa334f9c359fac6f5a14897434e57f7afc5a`.
   - Soft delete avec `deleted_at`, `deleted_by`, filtres `deleted_at IS NULL`, logs preserves.
   - PROD API encore `v3.5.100-meta-capi-error-sanitization-prod`.

12. `PH-ADMIN-T8.7C-CONFIRMMODAL-DELETE-E2E-VALIDATION-01.md`
   - Validation navigateur DEV de la suppression via ConfirmModal terminee.
   - Admin DEV `v2.11.2` + API DEV `v3.5.101`.
   - Webhook et Meta CAPI supprimes via UI, absents apres refresh.
   - Soft delete DB confirme : `deleted_at`, `deleted_by=ludovic@keybuzz.pro`, `is_active=false`.
   - Aucun code/build/deploy dans cette validation.

13. `PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-PROD-PROMOTION-01.md`
   - API DELETE promue en PROD.
   - Commit API : `df4a2c5e`.
   - Image PROD : `v3.5.101-outbound-destinations-delete-route-prod`.
   - Digest PROD : `sha256:bfac9f57ff79a9eaf83e53f9e88bdb3816c3a31456cdf97438465c984dc8c4f3`.
   - Infra commit GitOps : `776e910`; rapport : `d32a635`.
   - DELETE webhook et Meta CAPI OK, cross-tenant 403, logs preserves, non-regression OK.
   - Admin PROD encore `v2.11.0-tenant-foundation-prod`.

14. `PH-T8.8-BUSINESS-EVENTS-INBOUND-SOURCES-ARCHITECTURE-01.md`
   - Audit architecture inbound business events DEV+PROD termine.
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8-BUSINESS-EVENTS-INBOUND-SOURCES-ARCHITECTURE-01.md`.
   - Commit infra rapport : `20d4f77`.
   - Aucune modification code/DB/build/deploy.
   - Outbound sain : aucune destination active involontaire en DEV ou PROD; DEV a 0 destination active; KeyBuzz Consulting PROD a seulement des destinations soft-deleted.
   - Dette mineure : 3 destinations PROD `ecomlg-001` sont `is_active=false` mais `deleted_at IS NULL`; inoffensives, a nettoyer via soft delete/Admin V2.
   - Dette critique : `ad_spend` est global, sans `tenant_id`, avec credentials Meta KeyBuzz Consulting en env vars DEV+PROD.
   - `/metrics/overview?tenant_id=X` filtre customers/revenue mais pas spend/CAC/ROAS; risque de fuite/pollution de metrics multi-tenant.
   - Aucun pipeline inbound marketing n'existe encore : pas de pixel tenant, pas de collector business events, pas d'Addingwell code.
   - Architecture cible definie : `business_event_sources`, `business_events_inbound`, `ad_platform_accounts`, `ad_spend_tenant`.
   - Regle anti-doublon cible : un seul source owner par `event_name` et `event_id` canonical partage entre Pixel/CAPI; Addingwell optionnel, jamais owner des conversions si KeyBuzz CAPI les envoie.

15. `PH-T8.8A-AD-SPEND-TENANT-SAFETY-HYGIENE-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8A-AD-SPEND-TENANT-SAFETY-HYGIENE-01.md`.
   - DEV termine, PROD inchangee.
   - Commit API : `f4c3d910`.
   - Image API DEV : `v3.5.102-ad-spend-tenant-safety-dev`.
   - Digest DEV : `sha256:5178f39c5df537a7d0cb1b5c726bc3a9a289c76ff63d799eeaa0ce1e32c42601`.
   - Commit infra DEV : `912045e`.
   - Tables DEV creees : `ad_platform_accounts`, `ad_spend_tenant`.
   - Backfill DEV : 16 rows `ad_spend` global, total `445.20 GBP`, migrees vers `ad_spend_tenant` pour `keybuzz-consulting-mo9y479d`; total EUR vu metrics `512.29`.
   - `/metrics/overview?tenant_id=X` lit exclusivement `ad_spend_tenant` en mode tenant; `ecomlg-001` ne voit plus le spend global; tenant inexistant = 0/null sans NaN.
   - `/metrics/import/meta` avec `tenant_id` ecrit dans `ad_spend_tenant`; tenant sans compte Meta = `400 TENANT_SCOPED_AD_ACCOUNT_REQUIRED`.
   - Attention avant PROD : `/metrics/import/meta` sans `tenant_id` ecrit encore dans `ad_spend` global; a verrouiller/auditer avant promotion pour eviter une dette globale.
   - DEV hygiene : 0 destination active; 6 soft-deleted.
   - PROD lecture seule : 3 destinations `ecomlg-001` inactives sans `deleted_at` a soft-delete pendant promotion dediee.

16. `PH-T8.8A.1-AD-SPEND-GLOBAL-IMPORT-LOCK-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8A.1-AD-SPEND-GLOBAL-IMPORT-LOCK-01.md`.
   - DEV termine, PROD inchangee.
   - Commit API : `954eea74`.
   - Image API DEV : `v3.5.103-ad-spend-global-import-lock-dev`.
   - Digest DEV : `sha256:25355f81839edf11066679f073099b60e71452e13204f1a482e0ac25553b2c1f`.
   - Commit infra DEV : `b4d004c`.
   - `/metrics/import/meta` sans `tenant_id` retourne maintenant `400 TENANT_ID_REQUIRED_FOR_AD_SPEND_IMPORT`; plus aucun `INSERT INTO ad_spend` global dans `src/modules/metrics/routes.ts`.
   - `/metrics/import/meta` avec `tenant_id` ecrit uniquement dans `ad_spend_tenant`.
   - Validation DEV 10/10 : KBC OK, ecomlg-001 sans fuite, tokens absents, pas de NaN.
   - PROD a encore l'ancien code `v3.5.101`; promotion cumulative T8.8A+T8.8A.1 requise.

17. `PH-T8.8A.2-AD-SPEND-TENANT-SAFETY-PROD-PROMOTION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8A.2-AD-SPEND-TENANT-SAFETY-PROD-PROMOTION-01.md`.
   - PROD termine.
   - API commit : `954eea74`.
   - Image API PROD : `v3.5.103-ad-spend-global-import-lock-prod`.
   - Digest PROD : `sha256:9acd6b518535d49c858e0375852ae04a5ca4d11edf44f086230e108f42f7ed84`.
   - Infra commit PROD : `73be006`.
   - Tables PROD creees : `ad_platform_accounts` (1 row) et `ad_spend_tenant` (16 rows).
   - Backfill PROD KeyBuzz Consulting : tenant `keybuzz-consulting-mo9zndlk`, compte Meta `1485150039295668`, 16 rows `445.20 GBP`.
   - `/metrics/overview?tenant_id=ecomlg-001` ne voit plus le spend global; KBC voit son spend tenant; tenant inexistant propre.
   - `/metrics/import/meta` sans tenant_id retourne 400; import KBC ecrit/upsert uniquement `ad_spend_tenant`; `ad_spend` global reste a 16 rows.
   - 3 destinations PROD ecomlg-001 orphelines soft-deleted; orphans restants = 0.
   - Admin V2 et client SaaS non modifies.

18. `PH-ADMIN-T8.8A.3-METRICS-TENANT-SCOPE-UI-FIX-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8A.3-METRICS-TENANT-SCOPE-UI-FIX-01.md`.
   - Admin DEV termine, PROD inchangee.
   - Commit Admin : `286c80c`.
   - Image Admin DEV : `v2.11.3-metrics-tenant-scope-fix-dev`.
   - Digest DEV : `sha256:0bb88cc0f98ae8ad3214efb0db657373ef44659c986bce45e7eab1e21e6002e2`.
   - Cause racine : proxy Admin `/api/admin/metrics/overview` ignorait `tenant_id`/`tenantId` et forwardait seulement `from/to`; UI envoyait `tenantId`.
   - Fix : proxy accepte `tenant_id` ou `tenantId`, forwarde `tenant_id`; UI envoie `tenant_id`.
   - Validation navigateur DEV : KeyBuzz Consulting voit `512 EUR`; eComLG voit aucun spend et CAC/ROAS `—`; changement de tenant recharge correctement.
   - Prochaine action : promotion Admin PROD vers `v2.11.3-metrics-tenant-scope-fix-prod`.

19. `PH-ADMIN-T8.8A.4-METRICS-TENANT-SCOPE-PROD-PROMOTION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8A.4-METRICS-TENANT-SCOPE-PROD-PROMOTION-01.md`.
   - Admin PROD termine.
   - Admin commit : `286c80c`.
   - Image Admin PROD : `v2.11.3-metrics-tenant-scope-fix-prod`.
   - Digest PROD : `sha256:0c2bc611daa451ab5f7706b7c74d73e4f0b8d4cb148a31813b002b6821a36dad`.
   - Infra commit PROD : `b167abe`.
   - API PROD inchangee : `v3.5.103-ad-spend-global-import-lock-prod`.
   - Validation navigateur PROD : KeyBuzz Consulting voit `512 EUR`; eComLG voit aucun spend/banniere no-data; retour KBC OK sans residu.
   - `/marketing/integration-guide` accessible mais pas encore mis a jour pour les nouvelles sources/spend tenant; a traiter dans une phase doc/Admin dediee apres T8.8B/T8.8C.

20. `PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01.md`.
   - DEV termine, PROD inchangee.
   - API commit : `a5797352`.
   - Image API DEV : `v3.5.104-meta-ads-tenant-sync-foundation-dev`.
   - Digest DEV : `sha256:97394c1cce6ed03081d9b7bfb48ec29be87a628db983f443a5e2102159c0faf7`.
   - Infra commit DEV : `32d83f3`.
   - Routes SaaS ajoutees : `GET/POST/PATCH/DELETE /ad-accounts` et `POST /ad-accounts/:id/sync`.
   - Adapter Meta Ads tenant ajoute : `src/modules/metrics/ad-platforms/meta-ads.ts`.
   - Sync manuelle ecrit uniquement dans `ad_spend_tenant`; aucun write vers `ad_spend`.
   - KeyBuzz Consulting DEV pilote : `keybuzz-consulting-mo9y479d`, compte Meta `1485150039295668`.
   - Cross-tenant OK : eComLG ne voit pas le compte KBC et ne peut pas le synchroniser.
   - Blocage P0 : `token_ref` n'est pas exploitable car aucun secret store tenant n'existe encore; fallback env global limite a KBC DEV uniquement.
   - Ne PAS promouvoir en PROD avant une phase `PH-T8.8C` de Tenant Secret Store / credentials ads tenant.

21. `PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01.md`.
   - DEV termine, PROD inchangee.
   - API commit : `e6733567`.
   - Image API DEV : `v3.5.105-tenant-secret-store-ads-dev`.
   - Digest DEV : `sha256:906e232f830efd67b220cf3a6af34411ff2c65e235c54f7508410081b61db032`.
   - Infra commit DEV : `44f0ebc`.
   - K8s secret DEV : `keybuzz-ads-encryption`, env var `ADS_ENCRYPTION_KEY`.
   - `src/lib/ads-crypto.ts` cree : AES-256-GCM pour tokens Ads.
   - `token_ref` devient resolvable : POST/PATCH `/ad-accounts` acceptent `access_token`, chiffrent et stockent dans `token_ref`.
   - Fallback legacy `META_ACCESS_TOKEN` supprime dans l'adapter Meta Ads.
   - KBC DEV sync via token chiffre OK, token brut absent responses/logs/DB erreurs, cross-tenant bloque.
   - PROD reste `v3.5.103-ad-spend-global-import-lock-prod`.

22. `PH-ADMIN-T8.8D-AD-ACCOUNTS-META-ADS-UI-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8D-AD-ACCOUNTS-META-ADS-UI-01.md`.
   - Admin DEV termine, PROD inchangee.
   - Admin commit remote : `0d3582e`.
   - Image Admin DEV : `v2.11.4-ad-accounts-meta-ads-ui-dev`.
   - Digest DEV : `sha256:4941eb7c204c19ab0eb83092221de874536fab959803f3241c6163fe23fbfbcf`.
   - Ajoute `/marketing/ad-accounts`, proxies `/api/admin/marketing/ad-accounts`, navigation Marketing `Ads Accounts`.
   - Validation KBC DEV et cross-tenant eComLG OK.
   - Dette detectee : rollback documente en `kubectl set image`, validation navigateur partielle, fallback UI token pouvait afficher une valeur brute si API regressait.

23. `PH-ADMIN-T8.8D.1-AD-ACCOUNTS-UI-HARDENING-VALIDATION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8D.1-AD-ACCOUNTS-UI-HARDENING-VALIDATION-01.md`.
   - Admin DEV durci et valide navigateur, PROD inchangee.
   - Admin commit remote : `1986a8e`.
   - Image Admin DEV : `v2.11.5-ad-accounts-ui-hardening-dev`.
   - Digest DEV : `sha256:6c0815664ed8dab2d14b956dcd11ce19d27f5a52320322e77579de369a76e0a9`.
   - Infra commits : `016a2d8` deploy DEV + `c77c6d4` rapport.
   - Corrections : `redactTokens` sur erreurs/last_error, TokenBadge fallback `Masked`, icons sidebar completees, rollback GitOps strict.
   - Validation navigateur DEV : KBC CRUD test create/delete OK, eComLG isolation OK, token brut absent DOM/proxies/erreurs/logs, no NaN/undefined/mock.

24. `PH-T8.8C-PROD-PROMOTION-AD-ACCOUNTS-SECRET-STORE-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8C-PROD-PROMOTION-AD-ACCOUNTS-SECRET-STORE-01.md`.
   - API PROD termine, Admin PROD inchangee.
   - API commit : `e6733567`.
   - Image API PROD : `v3.5.105-tenant-secret-store-ads-prod`.
   - Digest PROD : `sha256:27d32ac3c05d5f2e2858a32052295ed4574cf271b2c2dc104f7332c52b8f97b1`.
   - Infra commit : `60f63b9`.
   - Secret PROD : `keybuzz-ads-encryption` dans `keybuzz-api-prod`, env `ADS_ENCRYPTION_KEY`, cle PROD differente de DEV.
   - Token KBC PROD chiffre dans `ad_platform_accounts.token_ref` (`aes256gcm:...`).
   - `GET /ad-accounts` KBC PROD OK, eComLG 0 compte, sync KBC OK, aucun write dans `ad_spend`, metrics sans fuite.
   - Token brut absent responses/logs/last_error/rapport; fallback `META_ACCESS_TOKEN` supprime.

25. `PH-ADMIN-T8.8D.2-AD-ACCOUNTS-UI-PROD-PROMOTION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8D.2-AD-ACCOUNTS-UI-PROD-PROMOTION-01.md`.
   - Admin PROD termine.
   - Admin commit : `1986a8e`.
   - Image Admin PROD : `v2.11.5-ad-accounts-ui-hardening-prod`.
   - Digest PROD : `sha256:40bbfd671b6470dcd373fe7f09345851c94eade6dc912bbf11de0d8a1490c3af`.
   - Infra commit manifest : `d8f5001`; rapport : `dd3febd`.
   - Page `/marketing/ad-accounts` live en PROD.
   - KBC PROD sync Meta Ads OK : 8 rows upsert, total `760.76 GBP` sur 30 jours, total rows `24`.
   - eComLG voit `No ad accounts`.
   - Token brut absent DOM/proxy/console/erreurs/rapport.

26. `PH-T8.8E-METRICS-TENANT-CURRENCY-AND-CAC-EXCLUSION-CONTROLS-API-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8E-METRICS-TENANT-CURRENCY-AND-CAC-EXCLUSION-CONTROLS-API-01.md`.
   - API DEV termine, PROD inchangee.
   - API commit : `808f2dae`.
   - Image API DEV : `v3.5.106-metrics-settings-currency-exclusion-dev`.
   - Digest DEV : `sha256:62ac263126847c9e7dbbbc95f51657be5fd4ea07ea4e0c15abeda9f78ec2165a`.
   - Cree `metrics_tenant_settings` : `metrics_display_currency`, `exclude_from_cac`, `exclude_reason`, audit minimal.
   - Ajoute endpoints `/metrics/settings/tenants`, lecture roles marketing, PATCH super_admin uniquement.
   - `/metrics/overview` supporte `display_currency` et preference tenant (`EUR`, `GBP`, `USD`), ajoute bloc `currency`, conserve champs existants.
   - `data_quality.internal_only=true` prepare le masquage Admin du bandeau "Donnees reelles - X compte test exclu".
   - Validation DEV : KBC EUR/GBP OK, eComLG sans fuite, devise invalide 400, PATCH super_admin OK, media_buyer 403, zero write dans `ad_spend` global.
   - Attention : le rapport contient un exemple rollback `kubectl set image`, a corriger/ignorer. Regle durable : rollback GitOps strict par manifest uniquement.

27. `PH-ADMIN-T8.8E-METRICS-CURRENCY-CAC-CONTROLS-UI-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8E-METRICS-CURRENCY-CAC-CONTROLS-UI-01.md`.
   - Admin DEV termine, PROD inchangee.
   - Admin commits : `17306bc` + `461e08a`.
   - Image Admin DEV : `v2.11.6-metrics-currency-cac-controls-dev`.
   - Digest DEV : `sha256:6aad8de557cff3508aa89993246ebd5dc50a75156ea7f290e890579f2765e514`.
   - Infra commits : `d7336de` deploy DEV + `532f246` rapport.
   - Ajoute proxies settings metrics, forward `display_currency`, `x-user-email`, `x-admin-role`, selecteur EUR/GBP/USD, bandeau internal-only Super Admin, controle exclusion CAC, menu Marketing reordonne.
   - Validation DEV : KBC GBP/EUR/USD OK, eComLG sans fuite, Ad Accounts KBC token encrypted, aucun token console.
   - Limites : pas de session non-super_admin testee en navigateur, destination outbound Meta CAPI KBC non configuree/testee, delivery logs et integration guide non testes, captures non deposees dans dossier durable.
   - Avant Admin PROD, promouvoir d'abord API PH-T8.8E en PROD car Admin `v2.11.6` depend de `/metrics/settings/tenants` et `display_currency` absents de l'API PROD actuelle.

28. `PH-ADMIN-T8.8E.1-METRICS-OUTBOUND-READINESS-COMPLETION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8E.1-METRICS-OUTBOUND-READINESS-COMPLETION-01.md`.
   - Validation DEV terminee sans patch, Admin DEV reste `v2.11.6-metrics-currency-cac-controls-dev`, commit `461e08a`.
   - `/metrics` KBC : GBP `445`, EUR `512`, USD valide, FX ECB coherent.
   - Bandeau Super Admin et controles CAC visibles/fonctionnels.
   - eComLG sans fuite spend KBC.
   - `/marketing/ad-accounts` KBC : compte Meta Ads `1485150039295668`, token `Encrypted`, aucune fuite.
   - `/marketing/destinations`, `/marketing/delivery-logs`, `/marketing/integration-guide` stables.
   - Screenshots durables dans `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\screenshots\PH-ADMIN-T8.8E.1\`.
   - Limite : pas de destination Meta CAPI KBC en DEV, donc pas de test PageView reel outbound; configuration outbound KBC reste phase dediee.
   - Limite : pas de session non-super_admin navigateur, RBAC confirme par code review.

29. `PH-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-API-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-API-01.md`.
   - API PROD termine.
   - API commit : `808f2dae`, branche `ph147.4/source-of-truth`.
   - Image API PROD : `v3.5.106-metrics-settings-currency-exclusion-prod`.
   - Digest PROD : `sha256:c415cf0272f53a86593f0ee68cdc8800151d71d92f7f89ac6f3fc2f5efcb7177`.
   - Infra commit : `aef2ca3`.
   - Table `metrics_tenant_settings` creee en PROD.
   - Settings GET/PATCH super_admin OK, media_buyer PATCH 403.
   - KBC PROD : 760.76 GBP natif, 875.41 EUR converti, USD OK, preference tenant GBP.
   - Exclusion CAC testee puis restauree (`exclude_from_cac=false`, `exclude_reason=null`).
   - `ad_spend` global intact 16 rows, `ad_spend_tenant` 24 rows.
   - `/ad-accounts` KBC OK, token `(encrypted)`.
   - Admin PROD inchange.

30. `PH-ADMIN-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-UI-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-UI-01.md`.
   - Admin PROD termine.
   - Admin commit : `461e08a`, branche `main`.
   - Image Admin PROD : `v2.11.6-metrics-currency-cac-controls-prod`.
   - Digest PROD : `sha256:532bc30177982eb6fda2febc885dc1605952c2b0562c1b7f1da480ea074f0d57`.
   - Infra commit : `8c9b824`.
   - API PROD consommee : `v3.5.106-metrics-settings-currency-exclusion-prod`.
   - KBC PROD : GBP `761`, EUR `875`, USD `1027`, labels coherents.
   - Selecteur devise, bouton devise defaut, controle CAC Super Admin OK.
   - eComLG ne voit aucune donnee KBC.
   - Pages marketing OK : ad-accounts, destinations, delivery logs, integration guide.
   - Token safety OK, GitOps strict, rollback `v2.11.5-ad-accounts-ui-hardening-prod`.
   - Limites : pas de session non-super_admin PROD, pas de destination Meta CAPI creee.

31. `PH-T8.8F-AD-SPEND-TENANT-DUPLICATE-TRUTH-AUDIT-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8F-AD-SPEND-TENANT-DUPLICATE-TRUTH-AUDIT-01.md`.
   - Audit lecture seule DEV+PROD, commit rapport infra `38bb4a7`.
   - Cause racine : 8 doublons logiques en PROD dans `ad_spend_tenant` sur 2026-03-24 a 2026-03-31.
   - Aucun global leak : API tenant lit uniquement `ad_spend_tenant`.
   - Doublon cause par deux chemins :
     - `/metrics/import/meta` legacy : `campaign_id=NULL`.
     - `/ad-accounts/:id/sync` : `campaign_id='120241837833890344'`.
   - PROD faux : 24 rows / `760.76 GBP`; attendu : 16 rows / `445.20 GBP`; surplus `315.56 GBP`.

32. `PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP-01.md`.
   - API commit : `3207caf4`, branche `ph147.4/source-of-truth`.
   - Image API DEV : `v3.5.107-ad-spend-idempotence-fix-dev`, digest `sha256:2e5d5666dd92f4cb52bc61746f0941a30bb9cfb80de233eca2e7454865f21b5f`.
   - Image API PROD : `v3.5.107-ad-spend-idempotence-fix-prod`, digest `sha256:4f49a7486a8fef2d34b01cb2b39535104647823b7e1f38f95692a8282acdc096`.
   - Infra commit : `a14a5eb`.
   - `/metrics/import/meta` tenant deprecie : avec `tenant_id` retourne `410 DEPRECATED_META_IMPORT_USE_AD_ACCOUNT_SYNC`; sans tenant reste `400 TENANT_ID_REQUIRED`.
   - Chemin canonique Meta Ads spend : `/ad-accounts/:id/sync`.
   - Cleanup PROD : backup des 24 rows, safety check 8 rows / `315.56 GBP`, DELETE par IDs exacts des legacy NULL.
   - KBC PROD restaure : 16 rows / `445.20 GBP`, 0 doublon.
   - KBC DEV : 16 rows / `445.20 GBP`, 0 doublon.
   - `ad_spend` global inchange : 16 rows / `445.20`.

33. `PH-ADMIN-T8.8H-KBC-META-CAPI-OUTBOUND-REAL-CONFIG-VALIDATION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8H-KBC-META-CAPI-OUTBOUND-REAL-CONFIG-VALIDATION-01.md`.
   - PROD termine sans code, build ni deploy.
   - Admin PROD : `v2.11.6-metrics-currency-cac-controls-prod`.
   - API PROD : `v3.5.107-ad-spend-idempotence-fix-prod`.
   - Tenant KBC : `keybuzz-consulting-mo9zndlk`.
   - Destination Meta CAPI creee via Admin UI : `KeyBuzz Consulting — Meta CAPI`.
   - Pixel ID : `1234164602194748`; Account ID : `1485150039295668`; endpoint `https://graph.facebook.com/v21.0/1234164602194748/events`.
   - Test `PageView` avec `TEST66800` : HTTP 200, `events_received: 1`.
   - Delivery logs : 1x `PageView` / KBC Meta CAPI / Livre / HTTP 200.
   - Aucun business event reel envoye : `StartTrial=0`, `Purchase=0`, `SubscriptionRenewed=0`, `SubscriptionCancelled=0`.
   - Metrics KBC inchangees : `445 GBP`.
   - Token safety OK : console, network, DOM et rapport sans token brut.
   - Point de vigilance local : le rapport apparait non suivi dans le checkout infra; demander a CE Admin de verifier commit/push avant toute phase documentation.

34. `PH-ADMIN-T8.8I-INTEGRATION-GUIDE-SERVER-SIDE-TRACKING-PROD-PROMOTION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8I-INTEGRATION-GUIDE-SERVER-SIDE-TRACKING-PROD-PROMOTION-01.md`.
   - Admin PROD promu depuis `main`.
   - Image Admin PROD : `v2.11.7-integration-guide-server-side-tracking-prod`.
   - Digest PROD : `sha256:f1d7f984`.
   - Infra commit GitOps : `482296a`.
   - Rapport commit : `ef379a7`.
   - Validation navigateur PROD : 10 sections OK, menu Marketing complet, boutons Copier OK.
   - Non-regression validee : Metrics KBC stables a `445 GBP`, destination Meta CAPI KBC toujours active avec badge `Test: success`, token masque.
   - DEV et API PROD inchanges.

35. `PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-01.md`.
   - DEV termine.
   - Admin source : branche `main`, HEAD preflight `ef379a7`.
   - Image Admin DEV : `v2.11.8-agency-tracking-playbook-dev`.
   - Digest DEV : `sha256:cadaf8fc`.
   - Commit Admin : `4bad311`.
   - Infra commit GitOps DEV : `6926a4b`.
   - Rapport commit : `891d299`.
   - `/marketing/integration-guide` enrichi sans nouvelle page/menu.
   - 9 nouvelles sections ajoutees, page passee de 404 a 860 lignes.
   - Contradictions documentees :
     - `MEDIA-BUYER-TRACKING-GUIDE.md` obsolete.
     - `PH-T8.5-AGENCY-INTEGRATION-DOC-01.md` obsolete sur le modele mono-destination.
   - Verite documentee :
     - Meta = le plus natif/mature.
     - les autres plateformes restent presentes honnetement comme webhook-first / non full-native si non livres.
     - seule `/pricing` est garantie pour le forwarding UTM selon la doc actuelle.
   - Validation DEV : 19 sections OK, 0 NaN, 0 token brut, 6 boutons Copier, menu Marketing inchange.

36. `PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-PROD-PROMOTION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-PROD-PROMOTION-01.md`.
   - PROD termine.
   - Admin source : branche `main`, HEAD preflight `891d299`.
   - Image Admin PROD : `v2.11.8-agency-tracking-playbook-prod`.
   - Digest PROD : `sha256:cadaf8fc`.
   - Infra commit GitOps PROD : `526dab2`.
   - Rapport commit : `4ca0734`.
   - Validation PROD : 19 sections visibles, contenu critique verifie, captures token-safe documentees dans le rapport.
   - Non-regression : Metrics KBC stables a `445 GBP`, Meta CAPI actif, token masque, DEV/API inchanges.
   - Rollback documente : `v2.11.7-integration-guide-server-side-tracking-prod`.

37. `PH-T8.9A-ONBOARDING-FUNNEL-CRO-TRUTH-AUDIT-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9A-ONBOARDING-FUNNEL-CRO-TRUTH-AUDIT-01.md`.
   - Audit lecture seule DEV+PROD termine.
   - 15 etapes funnel identifiees.
   - Trou noir critique pre-tenant confirme : 6 etapes non observables (`plan_selected`, `email_submitted`, `otp_sent/verified`, `company_completed`, `user_completed`).
   - Attribution `UTM/click IDs -> signup_attribution -> Stripe -> outbound` intacte.
   - `StartTrial` et `Purchase` fiables, distincts des micro-steps funnel.
   - Recommandation : nouvelle table `funnel_events` + pipeline d'instrumentation client/API en 6 phases.

38. `PH-T8.9B-PRE-TENANT-FUNNEL-VISIBILITY-FOUNDATION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9B-PRE-TENANT-FUNNEL-VISIBILITY-FOUNDATION-01.md`.
   - DEV termine.
   - API source : branche `ph147.4/source-of-truth`, commit `006c4bbb`.
   - Client source : branche `ph148/onboarding-activation-replay`, commit `9d8b9a0`.
   - Images DEV :
     - API `v3.5.108-funnel-pretenant-foundation-dev`
     - Client `v3.5.108-funnel-pretenant-foundation-dev`
   - Table `funnel_events` creee avec `UNIQUE(funnel_id, event_name)` et 4 index.
   - Routes API : `POST /funnel/event`, `GET /funnel/events`, `GET /funnel/metrics`.
   - 9 events allowlist stricts.
   - Micro-steps funnel stockes sans polluer `conversion_events` ni les destinations outbound.
   - Validation DEV : 16/16 PASS, PROD strictement inchangee.

39. `PH-ADMIN-T8.9C-FUNNEL-CRO-UI-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.9C-FUNNEL-CRO-UI-01.md`.
   - DEV termine.
   - Admin commit : `bc6394f` (apres commit initial `4d876c3`).
   - Image Admin DEV : `v2.11.9-funnel-cro-ui-dev`.
   - Digest DEV : `sha256:6d81302ba622be74dbc1e603cb8d45db150a2fc180b0effa3a1325ce7e5ac159`.
   - Infra commit : `45fc4c5`.
   - Nouvelle page `/marketing/funnel` + proxies `/api/admin/marketing/funnel/metrics` et `/api/admin/marketing/funnel/events`.
   - Menu Marketing : `Funnel` ajoute en position 2.
   - Limitation critique documentee : `GET /funnel/metrics` ignore `tenant_id`, donc l'agregation actuelle reste globale cote API.
   - La UI DEV ne doit pas etre promue en PROD tant que cette limitation n'est pas corrigee si l'on veut une vraie verite tenant-scoped.

40. `PH-ADMIN-T8.9C.1-FUNNEL-MENU-ICON-FIX-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.9C.1-FUNNEL-MENU-ICON-FIX-01.md`.
   - DEV termine.
   - Cause racine : `Filter` absent des imports `lucide-react` et du `iconMap` de `Sidebar.tsx`.
   - Commit Admin : `2c3db25`.
   - Image Admin DEV : `v2.11.10-funnel-menu-icon-fix-dev`.
   - Digest DEV : `sha256:c8211134be5cb35a440cc292839805364ae573b1bc8932002d31574b741546d1`.
   - Rollback DEV : `v2.11.9-funnel-cro-ui-dev`.
   - PROD inchangée.

41. `PH-T8.9B.1-FUNNEL-METRICS-TENANT-SCOPE-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9B.1-FUNNEL-METRICS-TENANT-SCOPE-01.md`.
   - DEV termine.
   - API source : branche `ph147.4/source-of-truth`, commit `2a61895e`.
   - Image API DEV : `v3.5.109-funnel-metrics-tenant-scope-dev`.
   - Digest DEV : `sha256:07264afc922d433a9e5f687af017f7ac875738b6f4efadd9e4920537477b3237`.
   - Fix applique :
     - `GET /funnel/metrics` supporte maintenant `tenant_id`
     - `GET /funnel/events` aligne avec le meme tenant cohort stitching
   - Logique retenue :
     - resolution all-time des `funnel_id` du tenant
     - aggregation/lecture de toutes les rows de ces funnels, y compris celles avec `tenant_id = NULL`
   - Validation DEV : 8/8 PASS, isolation tenant OK, pre-tenant steps inclus, `conversion_events` toujours sans micro-steps.
   - Client/Admin/PROD inchanges.

42. `PH-ADMIN-T8.9C.3-FUNNEL-METRICS-TENANT-PROXY-FIX-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.9C.3-FUNNEL-METRICS-TENANT-PROXY-FIX-01.md`.
   - DEV termine.
   - Cause racine : le proxy `src/app/api/admin/marketing/funnel/metrics/route.ts` lisait `tenantId` mais ne le forwardait pas en `tenant_id` vers l'API.
   - Patch minimal : 1 ligne ajoutee `if (tenantId) apiParams.set('tenant_id', tenantId);`
   - Commit Admin : `63f9ed3`.
   - Image Admin DEV : `v2.11.11-funnel-metrics-tenant-proxy-fix-dev`.
   - Digest DEV : `sha256:895bf615...`.
   - Validation navigateur :
     - KeyBuzz Consulting : `1 funnel / 1 derniere etape / 100.0% / 8 events`
     - Keybuzz : `1 funnel / 0 derniere etape / 0.0% / 4 events`
     - avant fix global : `2 / 2 / 50% / 12`
   - Isolation tenant parfaite, aucune fuite.
   - Limitation connue : filtre `to` cote API traite la date comme minuit exclusif; workaround = `to = lendemain`.
   - PROD inchangee.

43. `PH-T8.9D-FUNNEL-FOUNDATION-PROD-PROMOTION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9D-FUNNEL-FOUNDATION-PROD-PROMOTION-01.md`.
   - PROD termine.
   - API source finale : `2a61895e`.
   - Client source finale : `9d8b9a0`.
   - Table PROD `funnel_events` creee de facon additive avec contrainte `UNIQUE` et 5 index.
   - Images PROD :
     - API `v3.5.109-funnel-metrics-tenant-scope-prod`
     - Client `v3.5.108-funnel-pretenant-foundation-prod`
   - Infra commit GitOps : `6c03abb`.
   - Validation PROD : `POST /funnel/event`, `GET /funnel/events`, `GET /funnel/metrics` OK; test event cree puis nettoye.
   - Non-regression : `conversion_events` non polluee, `signup_attribution` intacte, Admin inchangee.
   - Limitation connue conservee : filtre `to` traite la date comme minuit exclusif.

44. `PH-ADMIN-T8.9E-FUNNEL-CRO-UI-PROD-PROMOTION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.9E-FUNNEL-CRO-UI-PROD-PROMOTION-01.md`.
   - PROD termine.
   - Image Admin PROD : `v2.11.11-funnel-metrics-tenant-proxy-fix-prod`.
   - Validation PROD :
     - page `/marketing/funnel` charge correctement
     - icone `Filter` visible et alignee
     - menu Marketing `Funnel` en position 2
     - KeyBuzz Consulting : etat vide reel OK
     - eComLG : etat vide reel OK
     - isolation tenant OK
     - 0 NaN / 0 mock / 0 token brut
     - non-regression Marketing OK
   - API PROD et Client PROD inchanges pendant cette phase.
   - Rollback documente : `v2.11.8-agency-tracking-playbook-prod`.

45. `PH-T8.9F-POST-CHECKOUT-ACTIVATION-FUNNEL-TRUTH-AUDIT-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9F-POST-CHECKOUT-ACTIVATION-FUNNEL-TRUTH-AUDIT-01.md`.
   - Audit lecture seule DEV + PROD, aucune modification.
   - Verdict : verite et observabilite du post-checkout maintenant etablies; plan d'implementation pret.
   - Constat majeur : l'activation post-checkout est un trou noir partiel entre `trial_started` et l'usage reel du produit.
   - 5 etapes mesurables et fiables :
     - subscription Stripe active
     - trial demarre
     - marketplace connectee (`inbound_connections` / `shopify_connections`)
     - premiere conversation (`conversations`)
     - premiere reponse agent (`messages`)
   - 6 etapes invisibles :
     - vue `/register/success`
     - premiere visite dashboard
     - vue `/start` / onboarding hub
     - premiere session utile
     - activation "produit pret"
     - correlation checkout -> tenant, car `billing_events.tenant_id = NULL`
   - Faits critiques :
     - le post-checkout redirige vers `/dashboard`, pas vers `/start`
     - `OnboardingWizard` est du code mort, jamais route
     - `OnboardingHub` est une checklist statique sans API ni progression reelle
     - les pixels s'eteignent apres `/register` par design
     - `billing_events.tenant_id = NULL` pour 244 rows, donc billing -> tenant n'est pas cousu
   - Modele cible recommande :
     - reutiliser `funnel_events`
     - 7 events d'activation proposes de `success_viewed` a `activation_completed`
     - plan en 5 phases G1 -> G5
   - Aucune autre action effectuee.

46. `PH-T8.9G-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9G-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-01.md`.
   - DEV termine.
   - Le funnel canonique passe de 9 a 15 events, avec 6 nouveaux events post-checkout :
     - `success_viewed`
     - `dashboard_first_viewed`
     - `onboarding_started`
     - `marketplace_connected`
     - `first_conversation_received`
     - `first_response_sent`
   - Design retenu :
     - cote API : `emitActivationEvent()` resout le `funnel_id` canonique du tenant depuis les events existants, fallback = `tenant_id`
     - cote client : `emitActivationStep()` avec dedup `activation:{tenantId}:{eventName}`
     - idempotence : `ON CONFLICT (funnel_id, event_name) DO NOTHING`
   - Aucune migration DB : table `funnel_events` inchangee.
   - Non-regression prouvee :
     - `conversion_events` contient toujours 0 activation events
     - `signup_attribution` intacte
     - Admin V2 inchangee
     - PROD inchangee
   - Images DEV :
     - API `v3.5.110-post-checkout-activation-foundation-dev`
     - Client `v3.5.110-post-checkout-activation-foundation-dev`
   - Decision : la prochaine phase logique est de verifier cote Admin DEV que `/marketing/funnel` affiche correctement ces nouveaux events et ordres post-checkout avec vraie data, avant toute promotion PROD de cette brique.

47. `PH-T8.9I-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-PROD-PROMOTION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9I-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-PROD-PROMOTION-01.md`.
   - PROD termine.
   - Images PROD :
     - API `v3.5.110-post-checkout-activation-foundation-prod`
     - Client `v3.5.110-post-checkout-activation-foundation-prod`
   - Admin PROD inchangee : `v2.11.11-funnel-metrics-tenant-proxy-fix-prod`.
   - Le funnel live couvre maintenant 15 steps (9 pre-tenant + 6 post-checkout).
   - Aucune migration DB requise en PROD.
   - `conversion_events` contient toujours 0 activation events : aucune pollution marketing/ads.
   - Destinations outbound inchangees.
   - Idempotence prouvee via `ON CONFLICT DO NOTHING`.
   - Rollback documente :
     - API `v3.5.109-funnel-metrics-tenant-scope-prod`
     - Client `v3.5.108-funnel-pretenant-foundation-prod`
   - Decision : la fondation post-checkout/activation est maintenant live en PROD. La suite logique devient soit une validation Admin PROD legere avec vraies donnees, soit une evolution produit sur les labels/UI, soit la modelisation de `activation_completed`.

48. `PH-T8.9J-ACTIVATION-COMPLETED-MODEL-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9J-ACTIVATION-COMPLETED-MODEL-01.md`.
   - DEV termine.
   - Modele retenu : A — `marketplace_connected AND first_conversation_received`.
   - Implementation :
     - event derive via `tryEmitActivationCompleted()` dans `emitActivationEvent()`
     - fichier modifie : `src/modules/funnel/routes.ts` uniquement
     - patch minimal : +32 lignes
   - Le funnel canonique passe maintenant a 16 steps :
     - 9 pre-tenant
     - 6 post-checkout
     - 1 derived = `activation_completed`
   - API DEV :
     - image `v3.5.111-activation-completed-model-dev`
     - digest `sha256:1d8648a623abb1d74f202cd2bb6071debc5e568e2916f9f0b85501783307621c`
     - commit API `c0b0f195`
   - Infra :
     - commit GitOps `538bc62`
     - commit rapport `5e5f07c`
   - Rollback DEV : `v3.5.110-post-checkout-activation-foundation-dev`
   - Validation : 6/6 PASS
   - Non-regression :
     - `conversion_events` contient toujours 0 activation events
     - Client inchange
     - Admin inchange
     - PROD inchangee
   - Decision : prochaine phase logique = validation Admin DEV avec le 16e step, puis promotion PROD si la lecture UI reste correcte.

49. `PH-ADMIN-T8.9K-ACTIVATION-COMPLETED-UI-VALIDATION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.9K-ACTIVATION-COMPLETED-UI-VALIDATION-01.md`.
   - DEV termine.
   - Verdict : GO — UI suffisante telle quelle.
   - Preflight confirme :
     - Admin DEV `v2.11.11-funnel-metrics-tenant-proxy-fix-dev`
     - API DEV `v3.5.111-activation-completed-model-dev`
     - Client DEV `v3.5.110-post-checkout-activation-foundation-dev`
   - API reelle :
     - 16 steps retournes
     - `activation_completed` en position 16
   - Validation UI :
     - step 16 visible dans le funnel visuel
     - visible dans la section verite business
     - visible dans la table detail par etape
     - `count = 0` coherent sur dataset de test nettoye
   - Isolation tenant confirmee.
   - Distinction micro-steps / business events claire.
   - Aucune modification effectuee.
   - Decision : aucune phase Admin de patch n'est requise; la prochaine phase logique est la promotion PROD cote API pour `activation_completed`, suivie d'une validation PROD legere de lecture UI.

50. `PH-T8.9L-ACTIVATION-COMPLETED-PROD-PROMOTION-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9L-ACTIVATION-COMPLETED-PROD-PROMOTION-01.md`.
   - PROD termine.
   - Image API PROD : `v3.5.111-activation-completed-model-prod`.
   - Digest PROD : `sha256:22d238e34273a3bd0d18804fec0253291d8b733d6a550b75a351b3c699d8b3ac`.
   - Le funnel canonique live en PROD passe maintenant a 16 steps :
     - 9 pre-tenant
     - 6 post-checkout
     - 1 derived = `activation_completed`
   - Modele live : A — `marketplace_connected AND first_conversation_received`.
   - Aucune migration DB requise.
   - `conversion_events` contient toujours 0 activation events : aucune pollution.
   - Destinations outbound inchangees.
   - Idempotence prouvee via `ON CONFLICT DO NOTHING`.
   - Client PROD inchange : `v3.5.110-post-checkout-activation-foundation-prod`.
   - Admin PROD inchangee : `v2.11.11-funnel-metrics-tenant-proxy-fix-prod`.
   - Rollback documente : `v3.5.110-post-checkout-activation-foundation-prod`.
   - Decision : `activation_completed` est maintenant live en PROD sans changement Client/Admin. La suite logique devient une validation Admin PROD legere de lecture funnel, puis soit une phase cosmetique labels, soit l'exploitation produit des nouveaux signaux.

51. `PH-T8.9M-PROD-FUNNEL-DATA-TRUTH-AUDIT-01.md`
   - Rapport : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9M-PROD-FUNNEL-DATA-TRUTH-AUDIT-01.md`.
   - Audit lecture seule PROD termine.
   - Verdict : NORMAL.
   - Tenant PROD verifie :
     - `tenant_id = keybuzz-consulting-mo9zndlk`
     - statut `active`
     - cree le `2026-04-22`
   - Verite DB :
     - `funnel_events` PROD = `0 rows` globalement, pas seulement pour KBC mais pour tous les tenants.
   - Verite API :
     - API PROD fonctionne correctement
     - `200 OK`
     - 16 steps structures
     - counts tous a `0`, reflet exact de la table vide
   - Filtre `to` :
     - non pertinent dans ce cas
     - toutes les variantes de date retournent `0`
   - Admin PROD :
     - chaine integre
     - backend `0 events` -> proxy Admin -> UI vide coherent
   - Comparaison DEV vs PROD :
     - DEV contient des rows de validation creees par CE les `2026-04-23` et `2026-04-24`
     - PROD contient `0 row` car aucun tenant n'a traverse le flow `/register` instrumente depuis la mise en prod du funnel le `2026-04-24`
   - Decision :
     - rien d'anormal
     - le pipeline PROD est fonctionnel mais n'a pas encore ete exerce par un vrai funnel utilisateur
     - le premier vrai funnel sera capture automatiquement des qu'un vrai parcours `/register` arrivera en PROD

Etat tracking server-side courant :

- API PROD : `v3.5.111-activation-completed-model-prod`.
- API DEV : `v3.5.111-activation-completed-model-dev`.
- Client DEV : `v3.5.110-post-checkout-activation-foundation-dev`.
- Client PROD : `v3.5.110-post-checkout-activation-foundation-prod`.
- Admin DEV : `v2.11.11-funnel-metrics-tenant-proxy-fix-dev`.
- Admin PROD : `v2.11.11-funnel-metrics-tenant-proxy-fix-prod`.
- KBC Meta CAPI outbound PROD : configure, actif, test `PageView` OK, aucun business event reel encore envoye.
- `/marketing/integration-guide` est maintenant live en PROD avec la documentation server-side tracking.
- Playbook agence/media buyer maintenant live en PROD.
- Funnel/CRO DEV existe avec tenant cohort stitching maintenant correct cote API.
- Funnel/CRO DEV est maintenant valide de bout en bout avec vraie data tenant-scoped cote Admin.
- La fondation Funnel est maintenant live en PROD cote API + Client.
- Funnel/CRO UI est maintenant live en PROD cote Admin.
- La fondation post-checkout / activation est maintenant live en PROD.
- Le modele derive `activation_completed` est maintenant live en PROD.
- Le 16e step `activation_completed` a ete valide cote Admin DEV sans patch requis.
- L'audit PROD confirme que l'absence actuelle de data funnel en PROD est normale : `funnel_events` est vide globalement.
- Prochaine action recommandee : attendre ou provoquer un premier vrai funnel PROD via `/register`, puis relire `/marketing/funnel`; ensuite seulement decider d'une phase cosmetique labels ou d'exploitation produit.
- Ne pas reprendre les exemples de rollback avec `kubectl set image`; promotion et rollback doivent rester GitOps strict via manifests.
- Bastion obligatoire si SSH necessaire dans tous les futurs prompts : `install-v3` / `46.62.171.61` uniquement. Si une autre IP bastion apparait ou est tentee, STOP immediat.
- Ne plus utiliser `/metrics/import/meta` pour Meta Ads tenant; le chemin canonique est `/ad-accounts/:id/sync`.

Options documentees :

1. Surveiller les vrais retours PROD et ne pas modifier sans symptome nouveau.
2. Si nouveau sujet Autopilot : lire d'abord tous les rapports PH-AUTOPILOT du 2026-04-21, surtout les quatre derniers rapports de callback/promise.
3. Sujet separe : le plan gate `ecomlg-001` PRO reste vrai pour ce tenant, mais ce n'est pas la cause des tests reels SWITAA/compta.

Apres changement de plan, aligner eventuellement `autopilot_settings` PROD avec DEV pour `ecomlg-001` :

```sql
UPDATE autopilot_settings
SET allow_auto_reply = true, allow_auto_escalate = true
WHERE tenant_id = 'ecomlg-001';
```

## Prompt suivant probable

Generer une phase de type :

Pas de phase de fix immediate

Objectif prudent :

- Si nouveau prompt CE est necessaire, imposer chemin complet du rapport final.
- Rappeler GitOps strict : aucun `kubectl set image` / `kubectl set env`.
- Repartir des images actuelles : API PROD `v3.5.92-autopilot-promise-detection-guardrail-prod`, backend PROD `v1.0.46-ph-recovery-01-prod`.

## Risques connus

- Ne pas confondre "Autopilot ne marche pas" avec bug UI : l'audit dit que UI/BFF/API sont presents.
- Ne pas reouvrir `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01` comme si elle n'etait pas faite : elle est faite DEV + PROD.
- Ne pas activer Autopilot pour tous les PRO par accident.
- Ne pas tester uniquement sur conversations synthetiques : l'audit demande un test reel.
- Garder le contexte que `ecomlg-001` est billing exempt/internal_admin.
