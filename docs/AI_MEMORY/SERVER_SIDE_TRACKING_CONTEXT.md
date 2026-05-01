# Server-Side Tracking / Agents SaaS + Admin

> Derniere mise a jour : 2026-04-24
> Source principale : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-UNIFIED.md`

## Contexte actif

Ludovic travaille sur le pipeline marketing server-side KeyBuzz avec deux lignes d'execution distinctes :

- **CE SaaS API** : repo `keybuzz-api`, stack Fastify/Node/TypeScript, branche obligatoire `ph147.4/source-of-truth`.
- **CE Admin V2** : repo `keybuzz-admin-v2`, stack Next.js 14/Metronic/TypeScript, branche obligatoire `main`.

Les deux agents ne communiquent pas directement. Ludovic transmet les rapports, retours et contrats d'interface entre eux. Les rapports `keybuzz-infra/docs/` sont la source de verite inter-agents.

## Pipeline marketing server-side

Fonctions deja construites ou en cours :

- collecte conversions reelles depuis Stripe : `StartTrial`, `Purchase`;
- attribution marketing tenant-native via `signup_attribution`;
- metrics business : CAC, ROAS, MRR, trial/paid, spend Meta, EUR normalized;
- destinations outbound self-service : webhooks signes HMAC, retry, idempotence, logs;
- exclusion comptes test via `tenant_billing_exempt`;
- Admin V2 : `/metrics`, `/marketing/destinations`, `/marketing/delivery-logs`, `/marketing/integration-guide`;
- Admin multi-tenant : `TenantProvider`, `useCurrentTenant()`, selector topbar, `RequireTenant`;
- framework platform-native : `destination_type` prepare pour `webhook`, `meta_capi`, `tiktok_events`, `google_ads`, `linkedin_capi`.

## Etat courant lu

Selon le knowledge transfer du 2026-04-22 :

- API SaaS DEV : `v3.5.97-marketing-tenant-foundation-dev`.
- API SaaS PROD : `v3.5.95-outbound-destinations-api-prod`.
- Admin V2 DEV : `v2.11.0-tenant-foundation-dev`.
- Admin V2 PROD : `v2.11.0-tenant-foundation-prod`.

En DEV uniquement au moment du document :

- metrics tenant-scoped : `GET /metrics/overview?tenant_id=...`;
- framework platform-native pour destinations natives.

## Phase SaaS courante : Meta CAPI

### Etat au 2026-04-22 apres PH-T8.7B.2 PROD

La chaine Meta CAPI est maintenant promue en PROD :

- `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01` : fondation tenant marketing, commit API `db14cb03`, image DEV `v3.5.97-marketing-tenant-foundation-dev`.
- `PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01` : connecteur Meta CAPI natif par tenant, commit API `5661e215`, image DEV `v3.5.98-meta-capi-native-tenant-dev`.
- `PH-T8.7B.1-META-CAPI-REAL-VALIDATION-01` : validation reelle Meta avec pixel `1234164602194748`, token masque, `test_event_code=TEST66800`, `events_received: 1`, aucune fuite token, pas de build.
- `PH-T8.7B.2-META-CAPI-TEST-ENDPOINT-FIX-01` : fix endpoint de test Meta, commit API `9b461717`, image DEV `v3.5.99-meta-capi-test-endpoint-fix-dev`, digest `sha256:8ce4f07d275538de2dbd02cdd22b5a9fb7c986ecaa402aa48e8b2273ea344ad9`.
- `PH-T8.7B.2-META-CAPI-PROD-PROMOTION-01` : promotion PROD cumulative T8.7A + T8.7B + T8.7B.2, image PROD `v3.5.99-meta-capi-test-endpoint-fix-prod`, digest `sha256:bcd51da92d726a55494775398d68c36357e5c310d3be4ba2c2b3fb523306c912`, infra commit `a7ba43e`.

PROD API est maintenant `v3.5.99-meta-capi-test-endpoint-fix-prod`. L'ancienne image PROD de rollback est `v3.5.95-outbound-destinations-api-prod`. T8.7B.1 sert de preuve de validation reelle, pas de changement code.

Attention : les rapports DEV contiennent parfois des snippets de rollback avec `kubectl set image`; ne pas les reprendre. Les prochains prompts doivent imposer rollback et promotion par manifest GitOps uniquement.

### PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01

Rapports lus :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-AUDIT.md`

Etat :

- DEV termine.
- API commit : `5661e215`.
- Infra commit : `682b486`.
- Image API DEV : `v3.5.98-meta-capi-native-tenant-dev`.
- Digest : `sha256:fc5bead34331dea48712bf1fe7483a177e9972096e89906dbca350b2d3383370`.
- PROD inchangee : `v3.5.95-outbound-destinations-api-prod`.

Ce qui existe :

- adapter `src/modules/outbound-conversions/adapters/meta-capi.ts`;
- routing `webhook` vs `meta_capi` dans l'emitter;
- mapping `StartTrial -> StartTrial`, `Purchase -> Purchase`;
- endpoint Meta auto : `https://graph.facebook.com/v21.0/{pixel_id}/events`;
- CRUD destinations avec `destination_type='meta_capi'`;
- token masque en API (`platform_token_ref` jamais renvoye en clair);
- support `test_event_code`;
- coexistence webhook + Meta CAPI sur un meme tenant;
- delivery logs partages.

Point critique avant PROD :

- validation Meta reelle NON encore faite : le test DEV prouve le wiring avec une reponse Meta `Malformed access token`, mais aucun event visible Events Manager n'a encore ete valide;
- token stocke en DB non chiffre at-rest, documente comme dette future AES-256-GCM;
- PROD doit rester bloquee tant qu'une phase de validation reelle n'a pas confirme un vrai pixel, un vrai access token et un event visible Meta.

### PH-T8.7B.1-META-CAPI-REAL-VALIDATION-01

Prompt SaaS donne par Ludovic a CE SaaS apres PH-T8.7B.

Objectif :

- vrai pixel Meta;
- vrai access token;
- `test_event_code`;
- event visible dans Meta Events Manager;
- verification payload canonical -> Meta;
- hardening minimal token : pas de log, pas de retour API clair, usage serveur uniquement, masking OK;
- validation tenant A / tenant B sans fuite.

Note importante : le prompt donne est volontairement court. Au retour CE, verifier que les regles KeyBuzz attendues sont bien couvertes dans le rapport : branche `ph147.4/source-of-truth`, repo clean, build-from-git si build, GitOps si deploy DEV, PROD inchangee, chemin complet du rapport.

### PH-T8.7B.2-META-CAPI-TEST-ENDPOINT-FIX-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.2-META-CAPI-TEST-ENDPOINT-FIX-01.md`

Etat :

- DEV termine.
- API commit : `9b461717`.
- Infra commit : `5d59c88`.
- Image API DEV : `v3.5.99-meta-capi-test-endpoint-fix-dev`.
- Digest : `sha256:8ce4f07d275538de2dbd02cdd22b5a9fb7c986ecaa402aa48e8b2273ea344ad9`.
- PROD inchangee : `v3.5.95-outbound-destinations-api-prod`.

Ce qui est corrige :

- `POST /outbound-conversions/destinations/:id/test` garde `ConnectionTest` pour `webhook`.
- Pour `meta_capi`, le test envoie maintenant un `PageView` Meta standard avec dummy email hash SHA256.
- Meta repond HTTP 200 avec `events_received: 1`.
- Delivery logs distinguent `PageView` pour Meta et `ConnectionTest` pour webhook.
- Token absent des reponses API, logs pod et delivery logs.

### PH-T8.7B.2-META-CAPI-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.2-META-CAPI-PROD-PROMOTION-01.md`

Etat :

- PROD termine.
- API source : branche `ph147.4/source-of-truth`, commit `9b461717`.
- Image API PROD : `v3.5.99-meta-capi-test-endpoint-fix-prod`.
- Digest PROD : `sha256:bcd51da92d726a55494775398d68c36357e5c310d3be4ba2c2b3fb523306c912`.
- Infra commit : `a7ba43e`.
- Rollback documente : `v3.5.95-outbound-destinations-api-prod`.
- GitOps strict respecte : aucun `kubectl set image`.

Validations PROD :

- `/metrics/overview` global et `?tenant_id=ecomlg-001` OK.
- Colonnes et framework platform-native OK.
- Creation destination `meta_capi` OK, endpoint Meta auto genere.
- Test endpoint Meta envoie `PageView`; delivery logs confirment `event_name=PageView`.
- Token masque en reponse, absent des logs et delivery logs.
- Isolation tenant confirmee.
- Admin V2, client SaaS et backend non touches.

Nuance validation PROD :

- Le test endpoint PROD a atteint Meta mais le token utilise etait un token de test/invalide, donc Meta a renvoye `Malformed access token`. CE considere cela attendu et a valide le pipeline, le masquage et le logging. Une configuration avec vrai token tenant devra etre testee via l'Admin une fois l'UI disponible.

Prochaine phase probable :

- Passer a **CE Admin V2** pour exposer/configurer Meta CAPI dans `/marketing/destinations`, en s'appuyant sur les rapports SaaS comme contrat API.
- Le prompt Admin doit auditer d'abord l'UI existante, les routes proxy, RBAC, tenant selector, et seulement ensuite patcher DEV.

### PH-ADMIN-T8.7C-META-CAPI-DESTINATIONS-UI-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-META-CAPI-DESTINATIONS-UI-01.md`

Etat :

- DEV termine.
- Admin source : branche `main`, commit `9226f1f`.
- Image Admin DEV : `v2.11.1-meta-capi-destinations-ui-dev`.
- Digest DEV : `sha256:69fa8c088ac6984e1260925bd78c4270b15827045afff443cff611fd20aa0f67`.
- Infra commits : `5f4a8dc` (manifest DEV) + `257b0b5` (rapport).
- PROD Admin inchangee : `v2.11.0-tenant-foundation-prod`.

Ce qui est fait :

- `/marketing/destinations` supporte `webhook` et `meta_capi`.
- Formulaire `meta_capi` avec `platform_pixel_id`, `platform_token_ref` password, `platform_account_id` optionnel, `mapping_strategy=direct`.
- Token Meta jamais reaffiche complet; liste affiche le token masque par l'API.
- Le proxy test propage `test_event_code` vers l'API SaaS.
- Les webhooks gardent `ConnectionTest`, secret HMAC et regenerate-secret.
- `/marketing/delivery-logs` ajoute le filtre `PageView` et les icones Meta/Webhook.
- RBAC inchange : `super_admin`, `account_manager`, `media_buyer` marketing; `ops_admin` et `agent` non autorises.

Reserve avant promotion PROD :

- Le rapport valide surtout le code compile/pod et les surfaces techniques. Il ne documente pas clairement une validation navigateur/session reelle avec creation/test Meta depuis `admin-dev.keybuzz.io`, ni les etats loading/empty/error en UI. Avant PROD, faire soit une validation manuelle Ludovic, soit une phase courte CE Admin de readiness navigateur sans patch.

### PH-ADMIN-T8.7C-META-CAPI-UI-REAL-BROWSER-VALIDATION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-META-CAPI-UI-REAL-BROWSER-VALIDATION-01.md`

Etat :

- Validation navigateur DEV effectuee sur `https://admin-dev.keybuzz.io`.
- Tenant teste : Keybuzz (`keybuzz-mnqnjna8`), super_admin `ludovic@keybuzz.pro`.
- Image Admin DEV : `v2.11.1-meta-capi-destinations-ui-dev`.
- API DEV appelee : `v3.5.99-meta-capi-test-endpoint-fix-dev`.
- PROD Admin inchangee : `v2.11.0-tenant-foundation-prod`.

Valide :

- Login, sidebar, topbar, tenant selector, RequireTenant.
- Webhook : creation, badge, `ConnectionTest`, regenerate secret, pas de regression.
- Meta CAPI : creation, token masque apres creation, endpoint auto, badge, PageView test, delivery logs.
- Etats UI : loading, empty, error, success, pas de NaN/undefined/mock.

Bloquant avant PROD Admin malgre verdict GO du rapport :

- Champ Access Token Meta observe en `type="text"` au lieu de `type="password"`.
- Erreur Meta invalide affiche/stocke le token (`Malformed access token ...`) dans l'UI et les delivery logs. Cela doit etre corrige a la source cote SaaS API par redaction/sanitization avant stockage/retour, puis defense-in-depth cote Admin.
- Les 3 destinations de test creees sont restees actives et doivent etre supprimees ou desactivees.
- Suppression via `window.confirm()` non validee en headless; a verifier ou remplacer par modal UI controlee dans une phase Admin.

Prochaine action recommandee :

1. Repasser temporairement a CE SaaS pour une phase securite DEV : redaction des tokens dans erreurs Meta CAPI, reponses test endpoint et delivery logs.
2. Puis CE Admin : hardening UI `type=password`, redaction defense-in-depth, nettoyage destinations test, suppression testee.
3. Puis seulement promotion PROD Admin.

### PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-01.md`

Etat :

- DEV termine.
- API source : branche `ph147.4/source-of-truth`, commit `f5d6793b`.
- Image API DEV : `v3.5.100-meta-capi-error-sanitization-dev`.
- Digest DEV : `sha256:4f148176d26f65189d9550df0cf7bdd6bd6d811e4af6b5eb7bbf70ff3ae2987e`.
- Infra commit dans rapport : `bd6a9de`; le resume utilisateur a mentionne `cba494c`, a verifier avant promotion.
- PROD API inchangee : `v3.5.99-meta-capi-test-endpoint-fix-prod`.

Ce qui est corrige :

- Nouveau helper `src/modules/outbound-conversions/redact-secrets.ts`.
- Redaction des tokens Meta `EA...`, `access_token=...`, `Bearer ...`, et du token exact connu.
- Applique sur adapter Meta CAPI, emitter, test endpoint routes, INSERT delivery_logs, lecture delivery logs et logs pod.
- Validation DEV : reponse API, DB delivery logs, API lecture logs, logs pod et CRUD masking sans token brut.

Prochaine action :

- Promouvoir PH-T8.7B.3 en PROD avant toute promotion Admin. C'est un fix securite API qui protege aussi l'Admin PROD futur.
- Ensuite seulement : CE Admin pour `type=password`, defense-in-depth UI, nettoyage destinations test et suppression controlee.

### PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01.md`

Etat :

- PROD termine.
- API source : branche `ph147.4/source-of-truth`, commit `f5d6793b`.
- Image API PROD : `v3.5.100-meta-capi-error-sanitization-prod`.
- Digest PROD : `sha256:c7f6da86dda0726c0b35653e9dd01ca2ac506acaa6cf8d021fb39594c30e6cfc`.
- Infra commit GitOps : `7e67d58`.
- Infra commit rapport : `329dc50`.
- Rollback : `v3.5.99-meta-capi-test-endpoint-fix-prod`.
- GitOps strict respecte : aucun `kubectl set image`.

Validations PROD :

- Reponse API `/test` : `Malformed access token [REDACTED_TOKEN]`.
- Delivery logs DB : token absent, message redige.
- API lecture logs : double sanitisation.
- Logs pod K8s : 0 occurrence token brut.
- CRUD `platform_token_ref` : masque `EA****...`.
- PageView et destinations CRUD non regresses.
- Admin V2 non modifie.

Clarification infra DEV :

- `bd6a9de` = GitOps DEV deployment.
- `cba494c` = rapport DEV.

### PH-ADMIN-T8.7C-META-CAPI-UI-HARDENING-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-META-CAPI-UI-HARDENING-01.md`

Etat :

- DEV termine cote Admin.
- Image Admin DEV : `v2.11.2-meta-capi-ui-hardening-dev`.
- Digest DEV : `sha256:0aac0068eca6221a8e964b4ac4fc80b31d7f5e95a9e5ebd9b6e2e6bcbb3fde1a`.
- PROD Admin inchangee : `v2.11.0-tenant-foundation-prod`.
- API PROD : `v3.5.100-meta-capi-error-sanitization-prod`.

Ce qui est ferme :

- Redaction defense-in-depth cote Admin : `src/lib/sanitize-tokens.ts`.
- ConfirmModal reusable : `src/components/ui/ConfirmModal.tsx`.
- Redaction UI/proxy/delivery logs sur les erreurs.
- Nettoyage des destinations test par SQL direct.
- Token input confirme en `type=password`.

Bloquant avant promotion Admin PROD :

- `DELETE /outbound-conversions/destinations/:id` retourne 404 cote API SaaS; la suppression UI n'est donc pas fonctionnelle malgre ConfirmModal.
- La suppression a ete faite en SQL direct, ce qui ne valide pas le workflow produit.
- Il faut corriger l'API SaaS en DEV puis PROD, ensuite revalider Admin DEV via ConfirmModal, puis seulement promouvoir Admin PROD.

### PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-01.md`

Etat :

- DEV termine cote API.
- API source : branche `ph147.4/source-of-truth`, commit `df4a2c5e`.
- Image API DEV : `v3.5.101-outbound-destinations-delete-route-dev`.
- Digest DEV : `sha256:12f9d1fd7fb236282b15ef3e51e7aa334f9c359fac6f5a14897434e57f7afc5a`.
- Infra commits : `dd23202` deploy DEV, `a272a86` rapport.
- PROD API inchangee : `v3.5.100-meta-capi-error-sanitization-prod`.

Ce qui est fait :

- Route `DELETE /outbound-conversions/destinations/:id` ajoutee.
- Strategie soft delete : colonnes additives `deleted_at`, `deleted_by`.
- `GET`, `PATCH`, `POST test`, emitter filtrent `deleted_at IS NULL`.
- Logs historiques preserves et accessibles.
- Validation DEV API : webhook delete OK, meta_capi delete OK, re-delete 404, cross-tenant 403, headers manquants 400, token sanitization OK.

Prochaine action recommandee :

- Valider immediatement dans Admin DEV que ConfirmModal appelle bien la route DELETE et que la destination disparait de la liste.
- Si OK : promouvoir PH-T8.7B.4 en PROD API.
- Puis promotion Admin PROD.

### PH-ADMIN-T8.7C-CONFIRMMODAL-DELETE-E2E-VALIDATION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-CONFIRMMODAL-DELETE-E2E-VALIDATION-01.md`

Etat :

- Validation navigateur DEV terminee.
- Admin DEV : `v2.11.2-meta-capi-ui-hardening-dev`.
- API DEV : `v3.5.101-outbound-destinations-delete-route-dev`.
- Admin PROD inchangee : `v2.11.0-tenant-foundation-prod`.
- API PROD inchangee : `v3.5.100-meta-capi-error-sanitization-prod`.
- Tenant teste : KeyBuzz Consulting (`keybuzz-consulting-mo9y479d`).

Valide :

- ConfirmModal ouvre et affiche le nom exact.
- Annuler ferme sans supprimer.
- Confirmer supprime une destination webhook via DELETE API.
- Confirmer supprime une destination Meta CAPI via DELETE API.
- Destination absente apres refresh.
- Soft delete confirme en DB : `deleted_at`, `deleted_by=ludovic@keybuzz.pro`, `is_active=false`.
- Aucun token brut expose.
- Non-regression UI OK.
- Aucun code/build/deploy pendant validation.

Prochaine action :

- Promouvoir l'API PH-T8.7B.4 en PROD.
- Ensuite promouvoir Admin PROD `v2.11.2` avec validation post-deploy sur `admin.keybuzz.io`.

### PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-PROD-PROMOTION-01.md`

Etat :

- PROD termine.
- API source : branche `ph147.4/source-of-truth`, commit `df4a2c5e`.
- Image API PROD : `v3.5.101-outbound-destinations-delete-route-prod`.
- Digest PROD : `sha256:bfac9f57ff79a9eaf83e53f9e88bdb3816c3a31456cdf97438465c984dc8c4f3`.
- Infra commit GitOps : `776e910`.
- Infra commit rapport : `d32a635`.
- Rollback : `v3.5.100-meta-capi-error-sanitization-prod`.
- Admin PROD inchangee : `v2.11.0-tenant-foundation-prod`.

Validations PROD :

- DELETE webhook : 200, disparu de la liste, re-delete 404.
- DELETE Meta CAPI : 200, 0 token leak, disparu de la liste.
- Cross-tenant : 403.
- Logs historiques preserves, pas de hard delete.
- Non-regression : CRUD, test, metrics, isolation, sanitization.

Prochaine action :

- Passer a CE Admin V2 pour promotion PROD de `v2.11.2-meta-capi-ui-hardening-dev`, avec validation post-deploy sur `admin.keybuzz.io`.

## Difference prompt CE SaaS vs CE Admin

### PH-T8.8-BUSINESS-EVENTS-INBOUND-SOURCES-ARCHITECTURE-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8-BUSINESS-EVENTS-INBOUND-SOURCES-ARCHITECTURE-01.md`

Etat :

- Audit lecture seule DEV+PROD termine.
- API DEV/PROD : `v3.5.101-outbound-destinations-delete-route-*`.
- Admin DEV/PROD : `v2.11.2-meta-capi-ui-hardening-*`.
- Aucun build/deploy/modification DB.

Constats :

- Outbound destinations tenant-native OK.
- Aucune destination active involontaire en DEV/PROD.
- DEV : 0 destination active, 6 soft-deleted.
- PROD : 3 destinations ecomlg-001 `is_active=false` sans `deleted_at` a nettoyer par soft delete, mais aucun flux actif.
- KeyBuzz Consulting doit etre traite comme tenant lambda.
- `ad_spend` global est une dette critique : pas de `tenant_id`, credentials Meta KeyBuzz Consulting en env vars DEV+PROD.
- `/metrics/overview?tenant_id=X` expose encore le spend global dans CAC/ROAS.
- Aucun inbound marketing collector/pixel/Addingwell n'est code.

Architecture cible :

- `business_event_sources`.
- `business_events_inbound`.
- `ad_platform_accounts`.
- `ad_spend_tenant`.
- Anti-doublon : `event_id` canonical + source owner unique par `event_name`.
- Addingwell devient source inbound optionnelle/relay browser; KeyBuzz CAPI doit etre owner exclusif des conversions serveur `StartTrial`/`Purchase`.

Priorite recommandee :

1. Nettoyer les 3 destinations PROD inactives sans `deleted_at`.
2. Corriger la dette critique ad spend global -> tenant-scoped avant lancement ads fiable.
3. Construire le registry inbound sources, collector, pixel/snippet et UI Admin.

Ne pas activer de vrai flux publicitaire tant que les metrics spend tenant-scoped et la strategie anti-doublon ne sont pas implementees.

### PH-T8.8A-AD-SPEND-TENANT-SAFETY-HYGIENE-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8A-AD-SPEND-TENANT-SAFETY-HYGIENE-01.md`

Etat :

- DEV termine, PROD inchangee.
- API commit : `f4c3d910`.
- Image DEV : `v3.5.102-ad-spend-tenant-safety-dev`.
- Digest DEV : `sha256:5178f39c5df537a7d0cb1b5c726bc3a9a289c76ff63d799eeaa0ce1e32c42601`.
- Infra commit DEV : `912045e`.

Validations :

- Tables DEV : `ad_platform_accounts`, `ad_spend_tenant`.
- Backfill DEV : 16 rows `ad_spend` global migrees vers `ad_spend_tenant` pour `keybuzz-consulting-mo9y479d`.
- `/metrics/overview?tenant_id=X` ne lit plus `ad_spend` global en tenant mode.
- `ecomlg-001` : spend tenant 0, CAC/ROAS null, pas de fuite globale.
- KeyBuzz Consulting : spend tenant OK.
- Tenant inexistant : 0/null, pas de NaN.
- `/metrics/import/meta` avec `tenant_id` ecrit dans `ad_spend_tenant`.
- Tenant sans compte Meta : `400 TENANT_SCOPED_AD_ACCOUNT_REQUIRED`.

Point de vigilance :

- `/metrics/import/meta` sans `tenant_id` continue d'ecrire dans `ad_spend` global. Avant promotion PROD, exiger audit et verrouillage : soit endpoint global strictement interne/super_admin documente, soit blocage/deprecation explicite. Ne pas promouvoir une surface globale accessible aux tenants.

Prochaine phase recommandee :

- `PH-T8.8A.1-AD-SPEND-GLOBAL-IMPORT-LOCK-AND-PROD-PROMOTION-01`
- Objectifs : verrouiller l'import global, promouvoir `v3.5.102` en PROD, creer/backfiller `ad_spend_tenant` PROD pour KeyBuzz Consulting, soft-delete les 3 residues PROD inactifs.

### PH-T8.8A.1-AD-SPEND-GLOBAL-IMPORT-LOCK-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8A.1-AD-SPEND-GLOBAL-IMPORT-LOCK-01.md`

Etat :

- DEV termine, PROD inchangee.
- API commit : `954eea74`.
- Image DEV : `v3.5.103-ad-spend-global-import-lock-dev`.
- Digest DEV : `sha256:25355f81839edf11066679f073099b60e71452e13204f1a482e0ac25553b2c1f`.
- Infra commit DEV : `b4d004c`.

Correction :

- 44 lignes de write global vers `ad_spend` supprimees.
- `/metrics/import/meta` sans `tenant_id` retourne `400 TENANT_ID_REQUIRED_FOR_AD_SPEND_IMPORT`.
- Plus aucun `INSERT INTO ad_spend` global dans `src/modules/metrics/routes.ts`.
- Import Meta avec `tenant_id` ecrit uniquement dans `ad_spend_tenant`.

Validation :

- 10/10 PASS en DEV.
- KeyBuzz Consulting import OK dans `ad_spend_tenant`.
- `ecomlg-001` ne voit aucun spend global.
- Token brut absent, pas de NaN.

Prochaine phase :

- Promotion PROD cumulative : creer tables PROD, backfill `ad_spend` -> `ad_spend_tenant` pour KeyBuzz Consulting PROD (`keybuzz-consulting-mo9zndlk`), deploy `v3.5.103-ad-spend-global-import-lock-prod`, soft-delete les 3 destinations ecomlg-001 inactives sans `deleted_at`.

### PH-T8.8A.2-AD-SPEND-TENANT-SAFETY-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8A.2-AD-SPEND-TENANT-SAFETY-PROD-PROMOTION-01.md`

Etat :

- PROD termine.
- API commit : `954eea74`.
- Image PROD : `v3.5.103-ad-spend-global-import-lock-prod`.
- Digest PROD : `sha256:9acd6b518535d49c858e0375852ae04a5ca4d11edf44f086230e108f42f7ed84`.
- Infra commit PROD : `73be006`.

Validations PROD :

- Tables `ad_platform_accounts` et `ad_spend_tenant` creees avec indexes.
- Backfill KBC PROD : `keybuzz-consulting-mo9zndlk`, Meta account `1485150039295668`, 16 rows, `445.20 GBP`.
- `/metrics/overview?tenant_id=ecomlg-001` : `source=no_data`, pas de global leak.
- `/metrics/overview?tenant_id=keybuzz-consulting-mo9zndlk` : `source=ad_spend_tenant`, total EUR `512.29`.
- `POST /metrics/import/meta` sans tenant_id : 400 `TENANT_ID_REQUIRED_FOR_AD_SPEND_IMPORT`.
- Import KBC : target `ad_spend_tenant`, `ad_spend` global reste a 16 rows.
- 3 destinations ecomlg-001 orphelines soft-deleted; orphans restants = 0.
- Non-regression health/billing/destinations/token sanitization OK.

Etat business :

- Le risque de fuite spend globale est ferme en PROD.
- KBC est pret pour pilot tenant-scoped, mais la prochaine etape doit auditer/commenter la dependance restante aux env vars Meta globales et transformer la sync Meta Ads en source tenant-native propre.

### PH-ADMIN-T8.8A.3-METRICS-TENANT-SCOPE-UI-FIX-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8A.3-METRICS-TENANT-SCOPE-UI-FIX-01.md`

Etat :

- Admin DEV termine, PROD inchangee.
- Admin commit : `286c80c`.
- Image Admin DEV : `v2.11.3-metrics-tenant-scope-fix-dev`.
- Digest DEV : `sha256:0bb88cc0f98ae8ad3214efb0db657373ef44659c986bce45e7eab1e21e6002e2`.
- API DEV/PROD : `v3.5.103-ad-spend-global-import-lock-*`.

Cause :

- La page `/metrics` connaissait le tenant via `useCurrentTenant()`, mais envoyait `tenantId`.
- Le proxy Admin `/api/admin/metrics/overview` ignorait totalement `tenantId`/`tenant_id` et ne forwardait que `from/to`.
- L'Admin affichait donc la vue globale quel que soit le tenant.

Fix :

- Proxy accepte `tenant_id` et `tenantId`, forwarde vers SaaS sous `tenant_id`.
- UI envoie `tenant_id`.

Validation navigateur DEV :

- KeyBuzz Consulting : spend tenant `512 EUR`.
- eComLG : aucun spend, banniere no-data, CAC/ROAS `—`.
- Retour KBC : `512 EUR`, pas de residu visuel.
- Dates/refresh/tenant selector OK, pas de NaN/undefined/mock.

Prochaine phase :

- Promotion Admin PROD vers `v2.11.3-metrics-tenant-scope-fix-prod`.

### PH-ADMIN-T8.8A.4-METRICS-TENANT-SCOPE-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8A.4-METRICS-TENANT-SCOPE-PROD-PROMOTION-01.md`

Etat :

- Admin PROD termine.
- Admin commit : `286c80c`.
- Image Admin PROD : `v2.11.3-metrics-tenant-scope-fix-prod`.
- Digest PROD : `sha256:0c2bc611daa451ab5f7706b7c74d73e4f0b8d4cb148a31813b002b6821a36dad`.
- Infra commit PROD : `b167abe`.
- API PROD inchangee : `v3.5.103-ad-spend-global-import-lock-prod`.

Validation PROD :

- Proxy accepte `tenant_id` et `tenantId`, forwarde `tenant_id`.
- API proxy PROD : eComLG `source=no_data`, KBC `source=ad_spend_tenant`, global reste global uniquement sans tenant.
- Navigateur PROD : KBC `512 EUR`, eComLG `—` + banniere no-data, retour KBC OK sans residu.
- Non-regression `/metrics`, `/marketing/destinations`, `/marketing/delivery-logs`, `/marketing/integration-guide`, tenant selector, session.

Dette doc :

- `/marketing/integration-guide` est accessible mais n'a pas ete mis a jour pour expliquer sources inbound, spend tenant-scoped, Addingwell optional/anti-doublon. A inclure apres fondation T8.8B/T8.8C, probablement via CE Admin.

### PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01.md`

Etat :

- DEV termine, PROD inchangee.
- API source : branche `ph147.4/source-of-truth`, commit `a5797352`.
- Image API DEV : `v3.5.104-meta-ads-tenant-sync-foundation-dev`.
- Digest DEV : `sha256:97394c1cce6ed03081d9b7bfb48ec29be87a628db983f443a5e2102159c0faf7`.
- Infra commit DEV : `32d83f3`.
- PROD API reste `v3.5.103-ad-spend-global-import-lock-prod`.

Ce qui est fait :

- Nouveau module SaaS `src/modules/ad-accounts/routes.ts`.
- Routes `GET/POST/PATCH/DELETE /ad-accounts` et `POST /ad-accounts/:id/sync`.
- Adapter Meta Ads tenant `src/modules/metrics/ad-platforms/meta-ads.ts`.
- Sync manuelle Meta Ads vers `ad_spend_tenant` uniquement.
- Cross-tenant strict : eComLG ne voit pas et ne peut pas sync le compte KBC.
- `ad_spend` global reste inchange et aucun write global n'existe.
- Token safety valide : responses, pod logs, last_error et rapport sans token brut.

Blocage P0 :

- `ad_platform_accounts.token_ref` existe mais n'est pas encore un vrai secret store exploitable.
- Le fallback legacy vers `META_ACCESS_TOKEN` est limite a KBC DEV (`tenant_id=keybuzz-consulting-mo9y479d`, account `1485150039295668`).
- Ne PAS promouvoir T8.8B en PROD tant que le secret store tenant n'est pas resolu.

Prochaine action recommandee :

- CE SaaS d'abord : `PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01`.
- Objectif : stocker/resoudre les tokens par tenant sans env var globale, migrer KBC DEV vers ce mecanisme, supprimer ou neutraliser le fallback legacy avant toute promotion PROD.
- CE Admin viendra apres pour UI de gestion comptes ads et integration guide, pas avant.

### PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01.md`

Etat :

- DEV termine, PROD inchangee.
- API source : branche `ph147.4/source-of-truth`, commit `e6733567`.
- Image API DEV : `v3.5.105-tenant-secret-store-ads-dev`.
- Digest DEV : `sha256:906e232f830efd67b220cf3a6af34411ff2c65e235c54f7508410081b61db032`.
- Infra commit DEV : `44f0ebc`.
- K8s secret DEV : `keybuzz-ads-encryption` dans `keybuzz-api-dev`.
- Env var DEV : `ADS_ENCRYPTION_KEY` 256 bits.
- API PROD reste `v3.5.103-ad-spend-global-import-lock-prod`.

Ce qui est fait :

- `src/lib/ads-crypto.ts` cree : `encryptToken()`, `decryptToken()`, `isEncryptedToken()`.
- Chiffrement AES-256-GCM avec IV aleatoire et tag d'authentification.
- `src/modules/metrics/ad-platforms/meta-ads.ts` decrypte `token_ref` et ne depend plus de `META_ACCESS_TOKEN`.
- Fallback legacy supprime.
- `src/modules/ad-accounts/routes.ts` accepte `access_token` en POST/PATCH, chiffre et stocke dans `token_ref`.
- `GET /ad-accounts` retourne `(encrypted)`, jamais le token brut.
- KBC DEV sync via token chiffre OK; cross-tenant bloque; `ad_spend` global inchange.

Decision de suite :

- Le verrou SaaS DEV est leve : CE Admin peut maintenant construire l'UI de gestion des comptes Ads en DEV.
- Ne pas promouvoir API PROD avant validation UI Admin DEV, sauf decision explicite de Ludovic.
- Pour promotion PROD future, prevoir secret `keybuzz-ads-encryption` en `keybuzz-api-prod`, env `ADS_ENCRYPTION_KEY`, token KBC PROD chiffre, puis deploy API `v3.5.105-*prod`.
- `/marketing/integration-guide` reste a mettre a jour apres UI Admin et validation navigateur.

### PH-ADMIN-T8.8D-AD-ACCOUNTS-META-ADS-UI-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8D-AD-ACCOUNTS-META-ADS-UI-01.md`

Etat :

- DEV termine, PROD inchangee.
- Admin source remote : branche `main`, commit `0d3582e`.
- Image Admin DEV : `v2.11.4-ad-accounts-meta-ads-ui-dev`.
- Digest DEV : `sha256:4941eb7c204c19ab0eb83092221de874536fab959803f3241c6163fe23fbfbcf`.
- Infra commit : `e2b486d`.
- Page ajoutee : `/marketing/ad-accounts`.
- Proxies ajoutes : `/api/admin/marketing/ad-accounts`, `/[id]`, `/[id]/sync`.
- Navigation Marketing : `Ads Accounts`.
- Validation KBC DEV : liste, create/delete, sync, cross-tenant eComLG, token safety.

Dette detectee puis traitee :

- Rapport initial contenait un rollback `kubectl set image`, interdit.
- Validation navigateur etait partielle.
- `TokenBadge` pouvait afficher une valeur fallback brute si l'API regressait.
- Une phase Admin hardening a ete demandee avant toute promotion.

### PH-ADMIN-T8.8D.1-AD-ACCOUNTS-UI-HARDENING-VALIDATION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8D.1-AD-ACCOUNTS-UI-HARDENING-VALIDATION-01.md`

Etat :

- DEV termine, PROD inchangee.
- Admin source remote : branche `main`, commit `1986a8e`.
- Image Admin DEV : `v2.11.5-ad-accounts-ui-hardening-dev`.
- Digest DEV : `sha256:6c0815664ed8dab2d14b956dcd11ce19d27f5a52320322e77579de369a76e0a9`.
- Infra commits : `016a2d8` deploy DEV, `c77c6d4` rapport.

Corrections :

- `redactTokens` applique sur `/marketing/ad-accounts` pour erreurs API et `last_error`.
- `TokenBadge` fallback ne peut plus afficher de valeur brute : fallback `Masked`.
- `Sidebar` iconMap complete : `Webhook`, `ScrollText`, `BookOpen`, `Megaphone`.
- Rollback documente en GitOps strict, sans `kubectl set image`.

Validation navigateur DEV :

- KeyBuzz Consulting : compte KBC visible, token badge "Encrypted", create/delete test OK, aucun residu.
- eComLG : aucun compte KBC visible, empty state propre.
- Retour KBC : OK, pas de residu visuel.
- Etats loading/empty/success OK, aucun NaN/undefined/mock.
- Token brut absent DOM, proxies, erreurs UI, logs navigateur et rapport.

Suite obligatoire :

- Ne pas promouvoir Admin PROD avant API PROD cumulative.
- Prochaine phase CE SaaS : promotion PROD cumulative T8.8B + T8.8C, avec secret `keybuzz-ads-encryption` PROD, env `ADS_ENCRYPTION_KEY`, migration/chiffrement token KBC PROD et validation `/ad-accounts`.
- Ensuite seulement : CE Admin promotion PROD `v2.11.5-ad-accounts-ui-hardening-prod`.

### PH-T8.8C-PROD-PROMOTION-AD-ACCOUNTS-SECRET-STORE-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8C-PROD-PROMOTION-AD-ACCOUNTS-SECRET-STORE-01.md`

Etat :

- PROD termine.
- API source : branche `ph147.4/source-of-truth`, commit `e6733567`.
- Image API PROD : `v3.5.105-tenant-secret-store-ads-prod`.
- Digest PROD : `sha256:27d32ac3c05d5f2e2858a32052295ed4574cf271b2c2dc104f7332c52b8f97b1`.
- Infra commit : `60f63b9`.
- Secret PROD : `keybuzz-ads-encryption` dans `keybuzz-api-prod`, env `ADS_ENCRYPTION_KEY`, cle PROD distincte de DEV.
- Token KBC PROD chiffre dans `ad_platform_accounts.token_ref` au format `aes256gcm:...`.

Validations PROD :

- `GET /ad-accounts` KBC retourne 1 compte avec `token_ref=(encrypted)`.
- eComLG retourne 0 compte.
- Sync KBC OK : 16 rows, 445.20 GBP, aucun write dans `ad_spend`.
- Metrics KBC OK; eComLG sans fuite.
- `/metrics/import/meta` sans tenant reste 400.
- Token brut absent responses/logs/last_error/rapport.
- Fallback global `META_ACCESS_TOKEN` supprime du code.
- Admin PROD reste `v2.11.3-metrics-tenant-scope-fix-prod`.

Suite :

- CE Admin peut maintenant promouvoir `v2.11.5-ad-accounts-ui-hardening-dev` vers PROD.
- Apres promotion Admin PROD, mettre a jour `/marketing/integration-guide` pour documenter Ads Accounts, sync spend tenant et anti-doublon.

### PH-ADMIN-T8.8D.2-AD-ACCOUNTS-UI-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8D.2-AD-ACCOUNTS-UI-PROD-PROMOTION-01.md`

Etat :

- Admin PROD termine.
- Admin source : branche `main`, commit `1986a8e`.
- Image Admin PROD : `v2.11.5-ad-accounts-ui-hardening-prod`.
- Digest PROD : `sha256:40bbfd671b6470dcd373fe7f09345851c94eade6dc912bbf11de0d8a1490c3af`.
- Infra commit manifest : `d8f5001`; rapport : `dd3febd`.
- API PROD inchangee : `v3.5.105-tenant-secret-store-ads-prod`.

Validations :

- Page `/marketing/ad-accounts` live en PROD.
- KeyBuzz Consulting voit son compte Meta Ads chiffre, sync manuelle OK.
- Sync KBC PROD : 8 lignes upsert, total `760.76 GBP` sur 30 jours, total rows `24`.
- eComLG voit `No ad accounts`.
- Token brut absent DOM, proxy, console, erreurs et rapport.
- Non-regression `/metrics`, `/marketing/destinations`, `/marketing/delivery-logs`.

### PH-T8.8E-METRICS-TENANT-CURRENCY-AND-CAC-EXCLUSION-CONTROLS-API-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8E-METRICS-TENANT-CURRENCY-AND-CAC-EXCLUSION-CONTROLS-API-01.md`

Etat :

- DEV termine, PROD inchangee.
- API source : branche `ph147.4/source-of-truth`, commit `808f2dae`.
- Image API DEV : `v3.5.106-metrics-settings-currency-exclusion-dev`.
- Digest DEV : `sha256:62ac263126847c9e7dbbbc95f51657be5fd4ea07ea4e0c15abeda9f78ec2165a`.
- API PROD reste `v3.5.105-tenant-secret-store-ads-prod`.

Ce qui est fait :

- Table `metrics_tenant_settings` creee : `tenant_id`, `metrics_display_currency`, `exclude_from_cac`, `exclude_reason`, `updated_by`, `updated_at`.
- Endpoints API : `GET /metrics/settings/tenants`, `GET /metrics/settings/tenants/:tenant_id`, `PATCH /metrics/settings/tenants/:tenant_id`.
- PATCH strictement `super_admin`; lecture ouverte aux roles marketing autorises.
- `/metrics/overview` supporte `display_currency` et preference tenant, avec fallback `EUR`.
- Devises supportees : `EUR`, `GBP`, `USD`.
- Nouveau bloc `currency` dans la reponse : display/source/fx/rate/date/provider/source de resolution.
- `data_quality.internal_only=true` ajoute pour permettre a l'Admin de masquer le bandeau "donnees reelles / compte test exclu" aux non super_admin.
- `exclude_from_cac` integre aux requetes SQL de signups/conversion/revenue.
- Champs historiques conserves pour compatibilite Admin actuelle.

Validation DEV :

- KBC display EUR et GBP OK.
- eComLG sans spend : aucune fuite KBC.
- Devise invalide : 400 `invalid_display_currency`.
- PATCH exclusion super_admin OK, media_buyer rejete 403.
- Overview sans `display_currency` utilise la preference tenant.
- `ad_spend_tenant` intact, aucun write dans `ad_spend` global.

Point de vigilance :

- Le rapport PH-T8.8E documente un rollback DEV via `kubectl set image`; ne pas reprendre cette commande. Les prochaines phases doivent exiger rollback GitOps strict par manifest uniquement.

Suite :

- CE Admin doit connecter cette fondation : masquer le bandeau interne aux non-super_admin, ajouter selecteur devise, controles Super Admin d'exclusion CAC, forwarder `x-user-email` et `x-admin-role` vers l'API, reordonner le menu Marketing, puis valider navigateur DEV.
- La documentation `/marketing/integration-guide` reste a mettre a jour apres stabilisation UI et validation outbound.

### PH-ADMIN-T8.8E-METRICS-CURRENCY-CAC-CONTROLS-UI-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8E-METRICS-CURRENCY-CAC-CONTROLS-UI-01.md`

Etat :

- DEV termine, PROD inchangee.
- Admin source : branche `main`, commits `17306bc` puis `461e08a`.
- Image Admin DEV : `v2.11.6-metrics-currency-cac-controls-dev`.
- Digest DEV : `sha256:6aad8de557cff3508aa89993246ebd5dc50a75156ea7f290e890579f2765e514`.
- Infra commits : `d7336de` deploy DEV, `532f246` rapport.
- Admin PROD reste `v2.11.5-ad-accounts-ui-hardening-prod`.
- API DEV requise : `v3.5.106-metrics-settings-currency-exclusion-dev`.
- API PROD reste `v3.5.105-tenant-secret-store-ads-prod`.

Ce qui est fait :

- Proxies Admin crees : `/api/admin/metrics/settings/tenants` et `/api/admin/metrics/settings/tenants/[tenant_id]`.
- Proxy `/api/admin/metrics/overview` forward `display_currency`, `x-user-email`, `x-admin-role` et applique `redactTokens`.
- Page `/metrics` ajoute selecteur EUR/GBP/USD, formatage dynamique et bouton Super Admin pour enregistrer la devise par defaut tenant.
- Bandeau "Donnees reelles - X compte test exclu" visible uniquement si `isSuperAdmin` et `data_quality.test_data_excluded`.
- Controle Super Admin d'exclusion/inclusion CAC avec raison via PATCH API.
- Menu Marketing reordonne : Metrics, Ads Accounts, Destinations, Delivery Logs, Integration Guide.

Validation DEV :

- KBC : GBP `445`, EUR `512`, USD `601`, FX BCE coherent.
- eComLG : aucun spend KBC visible.
- Ad Accounts KBC : compte visible, token `Encrypted`, pas de fuite.
- Console : aucun token brut.

Limites / avant PROD :

- Sessions non-super_admin non testees en navigateur, seulement condition code `isSuperAdmin`.
- Destination Meta CAPI outbound KBC non configuree en DEV; aucun test PageView reel effectue dans `/marketing/destinations`.
- `/marketing/delivery-logs` et `/marketing/integration-guide` non testes pendant la non-regression.
- Captures indiquees comme stockees en temp local, pas dans `keybuzz-infra/docs/screenshots/PH-ADMIN-T8.8E/`.
- Avant promotion Admin PROD, il faut d'abord promouvoir l'API PH-T8.8E en PROD, sinon Admin PROD `v2.11.6` appellera des endpoints/settings absents de l'API PROD `v3.5.105`.

Decision recommandee :

- Ne pas promouvoir PROD immediatement.
- Faire une courte phase Admin DEV de completion/readiness pour valider KBC outbound Meta CAPI, delivery logs, integration guide, captures durables et si possible un vrai role non-super_admin.
- Ensuite promotion SaaS API PH-T8.8E PROD.
- Ensuite promotion Admin PH-T8.8E PROD.

### PH-ADMIN-T8.8E.1-METRICS-OUTBOUND-READINESS-COMPLETION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8E.1-METRICS-OUTBOUND-READINESS-COMPLETION-01.md`

Etat :

- Validation DEV terminee sans patch.
- Admin DEV reste `v2.11.6-metrics-currency-cac-controls-dev`, commit `461e08a`.
- Aucune promotion PROD.

Validations :

- `/metrics` KBC : GBP `445`, EUR `512`, USD valide, FX ECB coherent.
- Bandeau Super Admin "Donnees reelles - 1 compte test exclu" + "Internal only" visible.
- Controle CAC tenant visible/fonctionnel pour Super Admin.
- eComLG : pas de fuite spend KBC, etat no-data correct.
- `/marketing/ad-accounts` KBC : compte Meta Ads `1485150039295668`, token `Encrypted`, aucune fuite.
- `/marketing/destinations` KBC : page stable, etat vide attendu.
- `/marketing/delivery-logs` : page stable, etat vide attendu.
- `/marketing/integration-guide` : page stable avec Quick Start, evenements, HMAC Node/Python, bonnes pratiques.
- Menu Marketing ordre correct.
- Screenshots durables presents dans `keybuzz-infra/docs/screenshots/PH-ADMIN-T8.8E.1/`.

Limites :

- Pas de session non-super_admin navigateur; RBAC confirme par code review.
- Pas de destination Meta CAPI KBC en DEV, donc pas de test PageView reel outbound. La configuration outbound Meta CAPI KBC reste une phase dediee.
- Delivery logs vides car aucune destination configuree.

Decision :

- E.1 valide la readiness UI Admin DEV.
- Prochaine etape obligatoire : CE SaaS promotion API PH-T8.8E en PROD (`v3.5.106-*prod`) avant toute promotion Admin `v2.11.6`, car Admin depend des nouveaux endpoints `/metrics/settings/tenants` et de `display_currency`.
- Ensuite CE Admin promotion PROD de `v2.11.6`.
- Ensuite phase dediee de configuration reelle KBC outbound Meta CAPI et documentation enrichie.

### PH-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-API-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-API-01.md`

Etat :

- PROD termine.
- API source : branche `ph147.4/source-of-truth`, commit `808f2dae`.
- Image API PROD : `v3.5.106-metrics-settings-currency-exclusion-prod`.
- Digest PROD : `sha256:c415cf0272f53a86593f0ee68cdc8800151d71d92f7f89ac6f3fc2f5efcb7177`.
- Image rollback : `v3.5.105-tenant-secret-store-ads-prod`.
- Infra commit : `aef2ca3`.
- Admin PROD inchange.

Validations PROD :

- Table additive `metrics_tenant_settings` creee.
- Settings GET/PATCH super_admin OK.
- PATCH media_buyer rejete 403.
- KBC PROD : `display_currency=EUR` -> `875.41 EUR` depuis `760.76 GBP`; `display_currency=GBP` natif; USD OK; sans param -> preference tenant `GBP`.
- Devise invalide : 400 `invalid_display_currency`.
- Exclusion CAC testee puis restauree : `exclude_from_cac=false`, `exclude_reason=null`.
- `/metrics/import/meta` sans tenant reste 400.
- `ad_spend` global intact : 16 rows; KBC spend dans `ad_spend_tenant` : 24 rows.
- `/ad-accounts` KBC OK, token `(encrypted)`.
- `data_quality.internal_only=true`.
- DEV inchange.

Decision :

- API PROD est maintenant prete pour Admin `v2.11.6`.
- Prochaine action : CE Admin promotion PROD de `v2.11.6-metrics-currency-cac-controls-prod`.

### PH-ADMIN-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-UI-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-UI-01.md`

Etat :

- PROD termine.
- Admin source : branche `main`, commit `461e08a`.
- Image Admin PROD : `v2.11.6-metrics-currency-cac-controls-prod`.
- Digest PROD : `sha256:532bc30177982eb6fda2febc885dc1605952c2b0562c1b7f1da480ea074f0d57`.
- Image rollback : `v2.11.5-ad-accounts-ui-hardening-prod`.
- Infra commit : `8c9b824`.
- API PROD consommee : `v3.5.106-metrics-settings-currency-exclusion-prod`.

Validations PROD :

- KBC : GBP `761`, EUR `875`, USD `1027`, labels coherents.
- Selecteur devise, bouton "Enregistrer comme devise par defaut", controle CAC Super Admin OK.
- eComLG : aucune donnee KBC visible.
- Pages marketing OK : `/marketing/ad-accounts`, `/marketing/destinations`, `/marketing/delivery-logs`, `/marketing/integration-guide`.
- Token safety OK : DOM, proxies, console, rapport.
- GitOps strict documente, aucun `kubectl set image` / `kubectl patch` / `kubectl edit`.

Limites :

- Pas de session non-super_admin en PROD; RBAC confirme par code review.
- CAC toggle non modifie en PROD.
- Aucune destination Meta CAPI creee; phase dediee a venir.

Decision :

- Admin Metrics currency/CAC controls est live en PROD.
- Prochaine phase logique : configuration reelle outbound Meta CAPI KBC + enrichissement Integration Guide.

### PH-T8.8F-AD-SPEND-TENANT-DUPLICATE-TRUTH-AUDIT-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8F-AD-SPEND-TENANT-DUPLICATE-TRUTH-AUDIT-01.md`

Etat :

- Audit lecture seule DEV+PROD termine.
- Infra commit rapport : `38bb4a7`.

Constat :

- Le chiffre PROD `760.76 GBP` etait faux.
- Aucun global leak : `/metrics/overview?tenant_id=KBC` lit uniquement `ad_spend_tenant`.
- Doublons logiques dans `ad_spend_tenant` PROD : 8 rows du 24 au 31 mars 2026.
- Cause : deux chemins d'import avec granularite differente.
  - `/metrics/import/meta` legacy : `campaign_id=NULL`, 16 rows backfill.
  - `/ad-accounts/:id/sync` canonique : `campaign_id='120241837833890344'`, 8 rows riches.
- L'index `idx_ast_dedup` sur `COALESCE(campaign_id,'__none__')` ne detecte pas ces doublons logiques.
- Impact : `760.76 GBP` au lieu de `445.20 GBP`, surplus `315.56 GBP`.

Decision :

- Corriger l'idempotence en deprecant l'ecriture tenant de `/metrics/import/meta`.
- Nettoyer PROD chirurgicalement les 8 rows legacy NULL sur les dates 2026-03-24 a 2026-03-31.

### PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8G-AD-SPEND-IDEMPOTENCE-FIX-AND-PROD-CLEANUP-01.md`

Etat :

- DEV + PROD termine.
- API commit : `3207caf4`, branche `ph147.4/source-of-truth`.
- Image API DEV : `v3.5.107-ad-spend-idempotence-fix-dev`, digest `sha256:2e5d5666dd92f4cb52bc61746f0941a30bb9cfb80de233eca2e7454865f21b5f`.
- Image API PROD : `v3.5.107-ad-spend-idempotence-fix-prod`, digest `sha256:4f49a7486a8fef2d34b01cb2b39535104647823b7e1f38f95692a8282acdc096`.
- Infra commit : `a14a5eb`.
- Rollback API : `v3.5.106-metrics-settings-currency-exclusion-{dev,prod}`.

Correction :

- Option A retenue : `/metrics/import/meta` avec `tenant_id` retourne maintenant `410 DEPRECATED_META_IMPORT_USE_AD_ACCOUNT_SYNC`.
- `/metrics/import/meta` sans `tenant_id` reste `400 TENANT_ID_REQUIRED`.
- Chemin canonique unique de sync Meta Ads tenant : `/ad-accounts/:id/sync`.
- Patch minimal dans `src/modules/metrics/routes.ts` : 4 insertions, 68 suppressions.

Cleanup PROD :

- Backup des 24 lignes KBC documente.
- Safety check : SELECT retourne exactement 8 rows legacy, total `315.56 GBP`, `campaign_id IS NULL`, dates 2026-03-24 a 2026-03-31.
- DELETE execute par IDs exacts.
- KBC PROD : 24 rows / `760.76 GBP` -> 16 rows / `445.20 GBP`.
- Doublons logiques : 0.

Validation :

- DEV : 16 rows / `445.20 GBP`, 0 doublons.
- PROD : 16 rows / `445.20 GBP`, 0 doublons.
- `/metrics/overview` KBC GBP = `445.20`, source `ad_spend_tenant`.
- eComLG spend = 0, no_data.
- `ad_spend` global inchange : 16 rows / `445.20`.
- `/ad-accounts` KBC OK, token `(encrypted)`.
- health DEV/PROD OK.
- Admin V2 non touche.

Decision :

- Metrics spend KBC restaure et fiable.
- Ne plus utiliser `/metrics/import/meta` pour Meta Ads tenant; uniquement `/ad-accounts/:id/sync`.
- Prochaine phase logique : configuration reelle outbound Meta CAPI KBC + documentation enrichie.

### PH-ADMIN-T8.8H-KBC-META-CAPI-OUTBOUND-REAL-CONFIG-VALIDATION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8H-KBC-META-CAPI-OUTBOUND-REAL-CONFIG-VALIDATION-01.md`

Etat :

- PROD termine sans code/build/deploy.
- Admin PROD : `v2.11.6-metrics-currency-cac-controls-prod`.
- API PROD : `v3.5.107-ad-spend-idempotence-fix-prod`.
- Tenant KBC : `keybuzz-consulting-mo9zndlk`.
- Destination avant : 0; delivery logs avant : 0.

Configuration :

- Destination creee via Admin UI : `KeyBuzz Consulting — Meta CAPI`.
- Type : `meta_capi`.
- Pixel ID : `1234164602194748`.
- Account ID : `1485150039295668`.
- Token saisi via champ password et masque dans UI/rapport.
- Endpoint : `https://graph.facebook.com/v21.0/1234164602194748/events`.
- Etat final : actif, dernier test success.

Validation :

- Test `PageView` avec `TEST66800` : HTTP 200, `events_received: 1`.
- Delivery logs : 1x PageView / KBC Meta CAPI / Livre / HTTP 200.
- StartTrial : 0 log; Purchase : 0 log; SubscriptionRenewed/Cancelled : 0.
- Metrics KBC inchangees : `445 GBP`.
- Token safety OK : console, network, DOM, rapport.
- Aucun code modifie, aucun build/deploy, aucun Webflow/DNS.

Point de vigilance :

- Dans le checkout local infra, le rapport apparait non suivi (`??`) apres lecture; verifier au prochain retour CE s'il a bien ete commit/push cote infra.

Decision :

- KBC Meta CAPI outbound est configure et valide en PROD pour les tests PageView.
- Les vrais business events StartTrial/Purchase pourront maintenant router vers cette destination, a surveiller dans delivery logs.
- Prochaine phase : enrichir `/marketing/integration-guide` avec Ads Accounts, Meta Ads sync, destinations Meta CAPI, anti-doublon, Addingwell, webhooks media buyer, screenshots.

### PH-ADMIN-T8.8I-INTEGRATION-GUIDE-SERVER-SIDE-TRACKING-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8I-INTEGRATION-GUIDE-SERVER-SIDE-TRACKING-PROD-PROMOTION-01.md`

Etat :

- PROD termine.
- Admin source : branche `main`.
- Image Admin PROD : `v2.11.7-integration-guide-server-side-tracking-prod`.
- Digest PROD : `sha256:f1d7f984`.
- Infra commit GitOps : `482296a`.
- Rapport commit : `ef379a7`.
- API PROD inchangee : `v3.5.107-ad-spend-idempotence-fix-prod`.

Validation :

- Page `/marketing/integration-guide` live en PROD.
- 10 sections OK, 404 lignes documentees.
- Menu Marketing complet et ordre valide.
- Boutons Copier fonctionnels.
- Non-regression OK :
  - Metrics KBC stables a `445 GBP`.
  - Destination Meta CAPI KBC toujours active.
  - Badge `Test: success` conserve.
  - Token masque.
- DEV et API non modifies.

Decision :

- La documentation Admin server-side tracking est maintenant alignee avec le systeme reel en PROD.
- Ne plus ouvrir de phase doc sur ce sujet sauf si une nouvelle surface fonctionnelle est ajoutee.
- La suite logique n'est plus documentaire, mais fonctionnelle : soit attendre les premiers vrais `StartTrial` / `Purchase`, soit ouvrir une phase funnel/CRO par etapes si prioritaire.

### PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-01.md`

Etat :

- DEV termine.
- Admin source : branche `main`.
- Image Admin DEV : `v2.11.8-agency-tracking-playbook-dev`.
- Digest DEV : `sha256:cadaf8fc`.
- Commit Admin : `4bad311`.
- Infra commit GitOps DEV : `6926a4b`.
- Rapport commit : `891d299`.

Contenu :

- `/marketing/integration-guide` enrichi sans nouvelle page/menu.
- 9 nouvelles sections ajoutees, 404 -> 860 lignes.
- Verite documentee pour agences/media buyers :
  - Browser events != business events.
  - Meta = plateforme la plus native/mature aujourd'hui.
  - TikTok / Google / YouTube ne sont pas presentes comme full-native si non livrees.
  - webhook agence = voie valide d'autonomie.
  - Addingwell = complement possible, pas remplacement du proprietaire des conversions business.
  - Landing pages : seule `/pricing` est garantie pour le forwarding UTM selon la documentation actuelle.

Contradictions documentees :

- `MEDIA-BUYER-TRACKING-GUIDE.md` obsolete par rapport a l'etat reel.
- `PH-T8.5-AGENCY-INTEGRATION-DOC-01.md` obsolete sur le modele mono-destination.

Validation :

- 19 sections OK.
- 0 NaN / 0 token brut.
- 6 boutons Copier.
- Menu Marketing inchange.
- PROD inchangee.

Decision :

- Le systeme est maintenant mieux documente pour rendre les agences autonomes, mais le playbook n'est encore live qu'en DEV.
- Deux suites logiques possibles :
  1. promotion PROD du playbook agence si on veut rendre la doc accessible tout de suite aux equipes;
  2. phase SaaS/produit pour completer ce qui manque vraiment a l'autonomie : inbound multi-plateforme tenant-native ou funnel/CRO.

### PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-PROD-PROMOTION-01.md`

Etat :

- PROD termine.
- Admin source : branche `main`.
- Image Admin PROD : `v2.11.8-agency-tracking-playbook-prod`.
- Digest PROD : `sha256:cadaf8fc`.
- Infra commit GitOps PROD : `526dab2`.
- Rapport commit : `4ca0734`.
- API PROD inchangee : `v3.5.107-ad-spend-idempotence-fix-prod`.

Validation :

- 19 sections visibles en PROD.
- Contenu critique verifie :
  - browser vs server explicite;
  - Meta documente comme le plus natif aujourd'hui;
  - TikTok / Google / YouTube non survendus si non full-native;
  - webhook agence documente comme voie valide;
  - Addingwell documente comme complement, pas comme proprietaire concurrent des conversions business;
  - seule `/pricing` documentee comme garantie pour le forwarding UTM.
- Captures token-safe documentees dans le rapport.
- Non-regression : Metrics KBC `445 GBP`, Meta CAPI actif, token masque.

Decision :

- Le playbook agence/media buyer est maintenant live en PROD.
- La documentation marketing actuelle est alignee avec la verite systeme.
- La suite n'est plus documentaire : il faut maintenant soit valider les premiers vrais business events, soit ouvrir la brique funnel/CRO, soit construire l'inbound multi-plateforme tenant-native hors Meta.

### PH-T8.9A-ONBOARDING-FUNNEL-CRO-TRUTH-AUDIT-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9A-ONBOARDING-FUNNEL-CRO-TRUTH-AUDIT-01.md`

Etat :

- Audit lecture seule DEV+PROD termine.
- 15 etapes funnel identifiees.
- 6 etapes pre-tenant sont un trou noir total.
- `StartTrial` et `Purchase` restent les seuls business events ads/billing fiables.
- Recommandation d'architecture : table `funnel_events`, `funnel_id`, instrumentation B1->B6.

### PH-T8.9B-PRE-TENANT-FUNNEL-VISIBILITY-FOUNDATION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9B-PRE-TENANT-FUNNEL-VISIBILITY-FOUNDATION-01.md`

Etat :

- DEV termine.
- API `ph147.4/source-of-truth` commit `006c4bbb`.
- Client `ph148/onboarding-activation-replay` commit `9d8b9a0`.
- Table `funnel_events` live en DEV.
- API DEV expose :
  - `POST /funnel/event`
  - `GET /funnel/events`
  - `GET /funnel/metrics`
- 9 micro-steps allowlist stricts.
- Aucun envoi des micro-steps vers `conversion_events` / destinations outbound.
- PROD inchangee.

### PH-ADMIN-T8.9C-FUNNEL-CRO-UI-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.9C-FUNNEL-CRO-UI-01.md`

Etat :

- DEV termine.
- Page `/marketing/funnel` creee.
- Proxies Admin :
  - `/api/admin/marketing/funnel/metrics`
  - `/api/admin/marketing/funnel/events`
- Image Admin DEV : `v2.11.9-funnel-cro-ui-dev`.
- Digest DEV : `sha256:6d81302ba622be74dbc1e603cb8d45db150a2fc180b0effa3a1325ce7e5ac159`.

Point critique :

- Le rapport documente noir sur blanc que `GET /funnel/metrics` ignore `tenant_id`.
- Donc la page Funnel DEV n'est pas encore veritablement tenant-scoped, meme si le proxy forward le tenant.
- Conclusion : NE PAS promouvoir la page Funnel Admin en PROD avant correction API de ce point.

### PH-ADMIN-T8.9C.1-FUNNEL-MENU-ICON-FIX-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.9C.1-FUNNEL-MENU-ICON-FIX-01.md`

Etat :

- DEV termine.
- Cause racine : `Filter` absent de l'import Lucide et du `iconMap` de `Sidebar.tsx`.
- Image Admin DEV : `v2.11.10-funnel-menu-icon-fix-dev`.
- Digest DEV : `sha256:c8211134be5cb35a440cc292839805364ae573b1bc8932002d31574b741546d1`.
- Navigation DEV visuellement corrigee.
- PROD inchangee.

Decision :

- Le bug visuel menu est ferme.
- La priorite suivante etait bien SaaS/API : rendre `GET /funnel/metrics` vraiment tenant-scoped.

### PH-T8.9B.1-FUNNEL-METRICS-TENANT-SCOPE-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9B.1-FUNNEL-METRICS-TENANT-SCOPE-01.md`

Etat :

- DEV termine.
- API source : branche `ph147.4/source-of-truth`.
- Commit API : `2a61895e`.
- Image API DEV : `v3.5.109-funnel-metrics-tenant-scope-dev`.
- Digest DEV : `sha256:07264afc922d433a9e5f687af017f7ac875738b6f4efadd9e4920537477b3237`.

Fix :

- `GET /funnel/metrics` supporte maintenant `tenant_id`.
- `GET /funnel/events` aligne avec la meme logique.
- Tenant scope resolu par cohort stitching :
  1. `SELECT DISTINCT funnel_id FROM funnel_events WHERE tenant_id = :tenant_id`
  2. lecture/agregation de toutes les rows de ces funnels, y compris celles avec `tenant_id = NULL`

Validation :

- 8/8 PASS.
- Global inchange.
- Tenant A complet avec steps pre-tenant inclus.
- Tenant B isole, zero fuite.
- `conversion_events` toujours sans micro-steps.
- PROD / Client / Admin inchanges.

Decision :

- Le blocage data qui empechait une promo Funnel Admin propre est leve.
- La suite logique n'est plus un fix SaaS, mais :
  1. revalidation Admin DEV du Funnel avec vraie data tenant-scoped;
  2. puis promotion PROD sequencee :
     - API/client funnel foundation,
     - Admin funnel UI.

### PH-ADMIN-T8.9C.3-FUNNEL-METRICS-TENANT-PROXY-FIX-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.9C.3-FUNNEL-METRICS-TENANT-PROXY-FIX-01.md`

Etat :

- DEV termine.
- Cause racine : le proxy Admin `funnel/metrics` ne forwardait pas `tenant_id`.
- Patch : 1 ligne ajoutee dans `src/app/api/admin/marketing/funnel/metrics/route.ts`.
- Commit Admin : `63f9ed3`.
- Image Admin DEV : `v2.11.11-funnel-metrics-tenant-proxy-fix-dev`.

Validation :

- KeyBuzz Consulting : `1 funnel / 1 derniere etape / 100.0% / 8 events`.
- Keybuzz : `1 funnel / 0 derniere etape / 0.0% / 4 events`.
- Avant fix global : `2 / 2 / 50% / 12`.
- Isolation tenant parfaite.
- Aucune fuite cross-tenant.

Limitation restante :

- Le filtre `to` cote API reste exclusif a minuit.
- Workaround documente : `to = lendemain`.
- Ce point n'est pas bloquant pour la promo Funnel principale.

Decision :

- Le funnel DEV est maintenant coherent de bout en bout : API + client + Admin.
- La prochaine sequence logique est :
  1. CE SaaS : promotion PROD de la fondation funnel (API + client);
  2. CE Admin : promotion PROD de l'UI Funnel/CRO.

### PH-T8.9D-FUNNEL-FOUNDATION-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9D-FUNNEL-FOUNDATION-PROD-PROMOTION-01.md`

Etat :

- PROD termine.
- API source finale : `2a61895e`.
- Client source finale : `9d8b9a0`.
- Images PROD :
  - API `v3.5.109-funnel-metrics-tenant-scope-prod`
  - Client `v3.5.108-funnel-pretenant-foundation-prod`
- Infra commit GitOps : `6c03abb`.

Validation :

- Table `funnel_events` creee en PROD de facon additive.
- `POST /funnel/event`, `GET /funnel/events`, `GET /funnel/metrics` fonctionnels.
- Test event controle cree puis nettoye.
- `signup_attribution` intact.
- `conversion_events` non polluee.
- Admin PROD inchangee.

Decision :

- La fondation Funnel/CRO est maintenant live en PROD cote SaaS.
- La prochaine phase logique est CE Admin PROD pour promouvoir l'UI Funnel/CRO, maintenant que le backend PROD est pret.

### PH-ADMIN-T8.9E-FUNNEL-CRO-UI-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.9E-FUNNEL-CRO-UI-PROD-PROMOTION-01.md`

Etat :

- PROD termine.
- Image Admin PROD : `v2.11.11-funnel-metrics-tenant-proxy-fix-prod`.

Validation :

- `/marketing/funnel` charge correctement en PROD.
- Icône Funnel visible et alignée.
- Menu Marketing : Funnel en position 2.
- KeyBuzz Consulting : état vide réel OK.
- eComLG : état vide réel OK.
- Isolation tenant OK.
- 0 NaN / 0 mock / 0 token brut.
- Non-régression Marketing OK.
- API PROD et Client PROD inchangés pendant cette phase.

Decision :

- Le funnel/CRO est maintenant live en PROD de bout en bout :
  - capture côté client,
  - persistance et cohort stitching côté API,
  - visualisation côté Admin.
- Il n'y a plus de chantier technique bloquant sur cette brique.
- Les prochaines évolutions deviennent des choix produit :
  1. collecter de vrais funnels et les analyser;
  2. mesurer l'activation post-checkout;
  3. enrichir l'UI avec insights/export;
  4. étendre l'autonomie tracking hors Meta.

### Prompt CE SaaS

Style attendu :

- tres strict sur API, DB, event pipeline, idempotence, tenant scope;
- branche obligatoire `ph147.4/source-of-truth`;
- bastion obligatoire si SSH necessaire : `install-v3` / `46.62.171.61` uniquement; toute autre IP bastion detectee ou utilisee => STOP immediat;
- build-from-git, repo clean, commit + push avant build;
- GitOps strict, aucun `kubectl set image`;
- validation API/DB/logs, non-regression Stripe/billing/metrics/tracking;
- ne pas modifier Admin V2 sauf phase explicitement mixte;
- rapport avec preuves techniques, image/digest/rollback.

Exemples typiques :

- `PH-T8.6A-OUTBOUND-DESTINATIONS-API-01`
- `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01`
- `PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01`

### Prompt CE Admin

Style attendu :

- centre sur UI, RBAC, routes proxy Next.js, tenant selector, navigation et validation navigateur;
- branche obligatoire `main`;
- bastion obligatoire si SSH necessaire : `install-v3` / `46.62.171.61` uniquement; toute autre IP bastion detectee ou utilisee => STOP immediat;
- build-from-git, repo clean, commit + push avant build;
- GitOps strict, aucun `kubectl set image`;
- ne pas modifier backend SaaS/API sauf phase explicitement coordonnee;
- valider pages reelles, sidebar/topbar, states loading/error/empty, absence de NaN/mock;
- valider RBAC : `super_admin`, `ops_admin`, `account_manager`, `media_buyer`, `agent`;
- verifier propagation headers proxy : `x-user-email`, `x-tenant-id`, `x-admin-role`;
- verifier service K8s interne API, surtout PROD sans `:3001`;
- rapport avec validation navigateur, non-regression pages existantes, image/digest/rollback.

Exemples typiques :

- `PH-T8.3.1-METRICS-UI-BASIC-01`
- `PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01`
- `PH-ADMIN-TENANT-FOUNDATION-01`
- `PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION`

## Regles inter-agents

- Un prompt Admin doit citer les rapports SaaS qui definissent le contrat API.
- Un prompt SaaS doit citer les rapports Admin uniquement comme consommateurs/contraintes d'interface, sans modifier Admin.
- Pour une phase mixte, separer clairement les scopes Admin et SaaS ou produire deux prompts sequentiels.
- Ne jamais supposer que l'Admin peut recalculer les metriques : il affiche les donnees du backend.
- Ne jamais supposer que le SaaS connait les contraintes visuelles Admin : les rapports Admin font foi pour UI/RBAC/navigation.

## Points de vigilance

- `KEYBUZZ_API_INTERNAL_URL` Admin PROD doit pointer vers le service K8s API sur port service, pas le port container `:3001`.
- Les admins globaux peuvent ne pas exister dans `user_tenants` cote SaaS; les proxies Admin doivent propager `x-admin-role` et le backend doit garder le tenant scope.
- `media_buyer` voit uniquement ses tenants assignes et les surfaces marketing autorisees.
- Secrets/tokens marketing ne doivent jamais etre renvoyes en clair.
- Aucune fake data marketing : pas de mock, pas de fallback invente, pas de faux graphique.

## Source Admin Reconstruction

Fichier ajoute comme source de style Admin :

- `C:\DEV\KeyBuzz\keybuzz-admin-v2\Reconstruction_Admin_V2.txt`

Apports principaux :

- Admin V2 a ete reconstruit comme ops/account workbench greenfield apres isolation de l'ancien admin.
- Les prompts Admin historiques insistent beaucoup sur : real data, suppression placeholders/mocks/fake KPI, DB -> API -> UI, navigation navigateur, RBAC, versioning, rollback et reproductibilite Git.
- A partir de PH-ADMIN-87.9A, regle renforcee : toute UI Admin doit afficher un etat vide reel si la donnee n'existe pas, jamais une simulation.
- Phases structurantes lues dans la conversation : `PH-ADMIN-SOURCE-OF-TRUTH-01/02`, `PH-ADMIN-87.9A`, prompts tenants/cockpit/connectors/AI control.

## Addendum 2026-04-24 - Post-checkout activation

### PH-T8.9F-POST-CHECKOUT-ACTIVATION-FUNNEL-TRUTH-AUDIT-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9F-POST-CHECKOUT-ACTIVATION-FUNNEL-TRUTH-AUDIT-01.md`

Etat :

- Audit lecture seule DEV + PROD.
- Aucun patch, aucun build, aucun deploy.
- Verdict : verite du funnel d'activation post-checkout et observabilite maintenant etablies.

Constats majeurs :

- Le post-checkout redirige vers `/dashboard`, pas vers `/start` ni un onboarding guide.
- `OnboardingWizard` est du code mort, jamais route.
- `OnboardingHub` est une checklist statique sans API ni progression reelle.
- Les pixels sont bloques apres `/register` par design, donc aucun tracking browser fiable post-login.
- `billing_events.tenant_id = NULL` pour 244 rows : impossible aujourd'hui de coudre proprement checkout -> tenant a partir de cette table seule.

Etapes mesurables et fiables :

- subscription Stripe active;
- trial demarre;
- marketplace connectee (`inbound_connections`, `shopify_connections`);
- premiere conversation (`conversations`);
- premiere reponse agent (`messages`).

Etapes invisibles aujourd'hui :

- vue `/register/success`;
- premiere visite `/dashboard`;
- vue `/start` / onboarding hub;
- premiere session utile;
- activation "produit pret";
- correlation checkout -> tenant via `billing_events`.

Modele cible recommande :

- reutiliser `funnel_events` plutot que creer une nouvelle table;
- 7 events d'activation recommandes :
  - `success_viewed`
  - `dashboard_first_viewed`
  - `onboarding_started`
  - `marketplace_connected`
  - `first_conversation_received`
  - `first_response_sent`
  - `activation_completed`
- separation stricte a conserver :
  - micro-steps d'activation = interne seulement
  - `StartTrial` / `Purchase` = seuls business events marketing/billing

Decision :

- Le prochain prompt SaaS logique n'est pas un fix du funnel existant.
- La prochaine phase logique devient une fondation DEV d'instrumentation post-checkout / activation, en reutilisant `funnel_events` et en gardant l'Admin hors scope initial.

### PH-T8.9G-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9G-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-01.md`

Etat :

- DEV termine.
- Aucun impact PROD.
- Fondations d'activation post-checkout ajoutees dans `funnel_events` sans migration de schema.

Nouveaux events canoniques maintenant captures en DEV :

- `success_viewed`
- `dashboard_first_viewed`
- `onboarding_started`
- `marketplace_connected`
- `first_conversation_received`
- `first_response_sent`

Design retenu :

- cote API : `emitActivationEvent()` resout le `funnel_id` canonique du tenant depuis les events existants, fallback = `tenant_id`;
- cote client : `emitActivationStep()` avec dedup `activation:{tenantId}:{eventName}`;
- idempotence : `ON CONFLICT (funnel_id, event_name) DO NOTHING`.

Non-regression :

- `conversion_events` contient 0 activation events;
- `signup_attribution` intacte;
- Admin V2 inchangee;
- PROD inchangee.

Images DEV :

- API `v3.5.110-post-checkout-activation-foundation-dev`
- Client `v3.5.110-post-checkout-activation-foundation-dev`

Decision :

- Avant toute promotion PROD de cette brique, la prochaine phase logique est CE Admin DEV :
  - verifier que `/marketing/funnel` affiche correctement les 15 events avec vraie data;
  - verifier l'ordre, les labels et la lisibilite du segment post-checkout;
  - identifier si l'UI actuelle suffit telle quelle ou si un patch Admin est necessaire.

### PH-T8.9I-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9I-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-PROD-PROMOTION-01.md`

Etat :

- PROD termine.
- Images PROD :
  - API `v3.5.110-post-checkout-activation-foundation-prod`
  - Client `v3.5.110-post-checkout-activation-foundation-prod`
- Admin PROD inchangee : `v2.11.11-funnel-metrics-tenant-proxy-fix-prod`.

Validation :

- funnel live couvre maintenant 15 steps :
  - 9 pre-tenant
  - 6 post-checkout
- aucune migration DB requise;
- `conversion_events` contient toujours 0 activation events;
- destinations outbound inchangees;
- idempotence prouvee via `ON CONFLICT DO NOTHING`.

Decision :

- la fondation post-checkout / activation est maintenant live en PROD;
- il n'y a pas besoin d'une promotion Admin pour cette sous-phase, l'Admin existant consomme deja ces events;
- la suite logique devient :
  1. validation Admin PROD legere avec vraies donnees quand elles arriveront;
  2. eventuelle phase cosmétique de labels funnel;
  3. ou modelisation de `activation_completed`.

### PH-T8.9J-ACTIVATION-COMPLETED-MODEL-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9J-ACTIVATION-COMPLETED-MODEL-01.md`

Etat :

- DEV termine.
- API uniquement, Client/Admin/PROD inchanges.

Modele retenu :

- Modele A :
  - `activation_completed = marketplace_connected AND first_conversation_received`

Implementation :

- event derive via `tryEmitActivationCompleted()` dans `emitActivationEvent()`
- fichier modifie uniquement :
  - `src/modules/funnel/routes.ts`
- patch minimal : +32 lignes

Effet fonctionnel :

- le funnel canonique passe a 16 steps :
  - 9 pre-tenant
  - 6 post-checkout
  - 1 derived = `activation_completed`

Artefacts DEV :

- API `v3.5.111-activation-completed-model-dev`
- digest `sha256:1d8648a623abb1d74f202cd2bb6071debc5e568e2916f9f0b85501783307621c`
- commit API `c0b0f195`
- commit infra GitOps `538bc62`
- commit rapport `5e5f07c`

Validation :

- 6/6 PASS
- `conversion_events` contient toujours 0 activation events
- aucune pollution outbound

Decision :

- la prochaine phase logique est CE Admin DEV pour verifier que le 16e step `activation_completed` est bien affiche et lisible dans `/marketing/funnel`;
- si UI OK, alors promotion PROD cote API seulement pourra suivre.

### PH-ADMIN-T8.9K-ACTIVATION-COMPLETED-UI-VALIDATION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.9K-ACTIVATION-COMPLETED-UI-VALIDATION-01.md`

Etat :

- DEV termine.
- Aucun patch, aucun build, aucun deploy.
- Verdict : GO — UI suffisante telle quelle.

Validation :

- API reelle retourne maintenant 16 steps;
- `activation_completed` est en position 16;
- step 16 visible dans le funnel visuel;
- visible dans la section verite business;
- visible dans la table detail par etape;
- `count = 0` coherent sur dataset de test nettoye;
- isolation tenant confirmee;
- distinction micro-steps / business events claire.

Decision :

- aucune phase Admin de patch n'est requise;
- la prochaine phase logique devient la promotion PROD cote API pour `activation_completed`, suivie d'une validation Admin PROD legere sans redeploiement Admin.

### PH-T8.9L-ACTIVATION-COMPLETED-PROD-PROMOTION-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9L-ACTIVATION-COMPLETED-PROD-PROMOTION-01.md`

Etat :

- PROD termine.
- API PROD :
  - `v3.5.111-activation-completed-model-prod`
  - digest `sha256:22d238e34273a3bd0d18804fec0253291d8b733d6a550b75a351b3c699d8b3ac`
- Client PROD inchange :
  - `v3.5.110-post-checkout-activation-foundation-prod`
- Admin PROD inchangee :
  - `v2.11.11-funnel-metrics-tenant-proxy-fix-prod`

Validation :

- le funnel live en PROD couvre maintenant 16 steps;
- `activation_completed` est le 16e step canonique;
- modele live :
  - `marketplace_connected AND first_conversation_received`
- aucune migration DB requise;
- `conversion_events` contient toujours 0 activation events;
- destinations outbound inchangees;
- idempotence prouvee via `ON CONFLICT DO NOTHING`.

Decision :

- `activation_completed` est maintenant live en PROD sans changement Client/Admin;
- la suite logique n'est plus une promotion technique obligatoire;
- prochaines options :
  1. validation Admin PROD legere de lecture funnel;
  2. phase cosmetique de labels funnel;
  3. exploitation produit/CRO du nouveau seuil `activation_completed`.

### PH-T8.9M-PROD-FUNNEL-DATA-TRUTH-AUDIT-01

Rapport lu :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.9M-PROD-FUNNEL-DATA-TRUTH-AUDIT-01.md`

Etat :

- Audit lecture seule PROD termine.
- Verdict : NORMAL.

Constats :

- tenant PROD verifie :
  - `keybuzz-consulting-mo9zndlk`
  - statut `active`
  - cree le `2026-04-22`
- `funnel_events` PROD contient `0 row` globalement, pour tous les tenants;
- l'API PROD fonctionne correctement :
  - `200 OK`
  - 16 steps
  - counts a `0`
- le filtre `to` n'explique rien ici;
- l'Admin PROD affiche correctement le vide car le backend renvoie reellement `0`.

Comparaison DEV vs PROD :

- DEV contient des rows de validation creees pendant les phases CE les `2026-04-23` et `2026-04-24`;
- PROD contient `0 row` car aucun tenant n'a encore traverse le flow `/register` instrumente depuis la mise en production du funnel le `2026-04-24`.

Decision :

- rien d'anormal;
- le pipeline funnel PROD est bien deploie et fonctionnel, simplement non encore exerce;
- la prochaine action logique n'est pas un fix, mais soit :
  1. attendre un premier vrai funnel PROD;
  2. ou lancer une validation controlee sur un vrai parcours `/register` en PROD si necessaire.

---

## PH-T8.12U — Etat tracking Client PROD combine (2026-05-01)

Image Client PROD : `v3.5.147-sample-demo-platform-aware-tracking-parity-prod`
Digest : `sha256:6a95073a92edbbcdf2fa55b9f36e25ea8e51ddaefc4d0e2aa59f1de5b1bb4ef5`

### Tracking actif sur funnel (/register, /login)

| Plateforme | Type | ID/URL | Statut |
|------------|------|--------|--------|
| GA4 | Browser | `G-R3QQDYEBFG` | Actif |
| sGTM | Routing | `https://t.keybuzz.pro` | Actif |
| TikTok Pixel | Browser | `D7PT12JC77U44OJIPC10` | Actif (PageView, SubmitForm, InitiateCheckout) |
| LinkedIn Insight Tag | Browser | `9969977` | Actif |
| Meta Pixel | Browser | `1234164602194748` | Actif (PageView, Lead, CompleteRegistration, InitiateCheckout) |

### Conversions business server-side only

| Event | Plateforme | Transport | event_id format |
|-------|-----------|-----------|-----------------|
| Purchase | Meta CAPI | `graph.facebook.com` | `conv_{tenant}_{Purchase}_{sub_id}` |
| Purchase | TikTok Events API | `business-api.tiktok.com` | `conv_{tenant}_{Purchase}_{sub_id}` |
| StartTrial | Meta CAPI + TikTok + LinkedIn CAPI | Respectifs | `conv_{tenant}_{StartTrial}_{sub_id}` |

### Events browser retires (dedup)

- **Meta Purchase** : retire du browser (PH-T8.12S) — CAPI server-side only, pas de event_id commun browser/server.
- **TikTok CompletePayment** : retire du browser (PH-T8.12P) — Events API server-side only, event_id mismatch.

### Pages protegees

`/dashboard`, `/inbox`, `/orders`, `/settings`, `/channels`, `/suppliers`, `/knowledge`, `/playbooks`, `/ai-journal`, `/billing`, `/onboarding`, `/workspace-setup`, `/start`, `/help` — aucun tracking publicitaire.

### Gaps restants

| Priorite | Gap |
|----------|-----|
| P2 | TikTok content_id manquant sur ViewContent |
| P2 | TikTok spend bloque (Business API credentials) |
| P3 | LinkedIn spend hors scope (Ads Reporting approval) |
| P3 | Google destination native non implementee (via sGTM/Addingwell) |

### Admin wording (PH-ADMIN-T8.12V)

Phase d'alignement documentaire pour refleter cet etat dans les surfaces Admin Marketing et la memoire projet.

---

## PH-ADMIN-T8.12W — Baseline acquisition et spend truth (2026-05-01)

### Baseline officielle

- Date : **2026-05-01 00:00 Europe/Paris**
- Toute donnee avant cette date = setup/test/cutover tracking
- Admin Metrics et Funnel demarrent par defaut au 2026-05-01
- Les donnees historiques ne sont PAS supprimees, seulement filtrees par defaut

### TikTok destination cutover verifie

- Nouvelle destination active : `75a3c56a-2508-4fa9-ab12-6b1514951877`
  - pixel `D7PT12JC77U44OJIPC10`, ad account `7634494806858252304`
- Ancienne destination inactive : `07b03162-7e5b-4751-8425-e9528faa3562`
  - pixel `D7HQO0JC77U2ODPGMDI0`, ad account `7629719710579130369`

### Ad Accounts PROD

| Platform | Account ID | Statut |
|----------|-----------|--------|
| Google | `5947963982` | active |
| Meta | `1485150039295668` | active |
| TikTok | absent | Business API credentials requis |
| LinkedIn | absent | Ads Reporting approval requis |

### Spend truth dans Admin

- Google spend : synced via Ad Account API
- Meta spend : synced via Ad Account API
- TikTok spend : non remonte (Business API bloque)
- LinkedIn spend : non remonte (hors scope)
- Admin `/marketing/ad-accounts` explique pourquoi TikTok/LinkedIn absents
