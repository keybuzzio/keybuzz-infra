# Contexte Admin v2 KeyBuzz

> Derniere mise a jour : 2026-04-21
> Role : point d'entree pour `admin` / `admin-dev`.

## Surface

Chemin local :

- `C:\DEV\KeyBuzz\keybuzz-admin-v2`

Stack observee :

- Next.js 14.2.x
- React 18
- NextAuth
- PostgreSQL via `pg`
- UI admin type Metronic

Hosts :

- DEV : `admin-dev.keybuzz.io`
- PROD : `admin.keybuzz.io`

Manifests :

- DEV : `C:\DEV\KeyBuzz\V3\keybuzz-infra\k8s\keybuzz-admin-v2-dev`
- PROD : `C:\DEV\KeyBuzz\V3\keybuzz-infra\k8s\keybuzz-admin-v2-prod`

## Sections admin detectees

Routes dans `src/app/(admin)` :

- `ai-evaluations`
- `ai-metrics`
- `approvals`
- `audit`
- `billing`
- `cases`
- `connectors`
- `feature-flags`
- `finance`
- `followups`
- `incidents`
- `notifications`
- `ops`
- `queues`
- `queues-inspector`
- `settings`
- `system-health`
- `tenants`
- `users`

Routes API internes :

- `src/app/api/admin`
- `src/app/api/auth`

## Point critique connu

Source : `PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md`

En PROD, l'admin doit appeler le service Kubernetes API sans `:3001` :

- correct PROD : `keybuzz-api.keybuzz-api-prod.svc.cluster.local`
- correct DEV possible : `keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001`

Risque : une mauvaise URL interne casse metrics/trial/paid en PROD tout en pouvant rester invisible en DEV.

## Role produit

Admin v2 sert a piloter :

- tenants;
- users/admin users;
- billing usage/costs;
- queues/incidents/audit;
- feature flags;
- AI control center;
- system health;
- metrics internes;
- approvals et operations.

## Regle pratique

Avant modification admin :

1. Verifier si la donnee vient de DB directe ou API interne.
2. Verifier l'URL interne DEV/PROD.
3. Ne pas melanger couts internes et affichage client.
4. Tester DEV avec tenant connu.
5. Ne pas promouvoir PROD sans rapport et validation.

## Style de prompt CE Admin

Source : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-UNIFIED.md`.

Les prompts Admin V2 sont differents des prompts CE SaaS :

- repo cible : `keybuzz-admin-v2`;
- branche source de verite : `main`;
- focus : UI, RBAC, navigation, proxy Next.js, tenant selector, validation navigateur;
- ne pas modifier `keybuzz-api` / backend SaaS sauf phase explicitement coordonnee;
- verifier les contrats API depuis les rapports SaaS avant implementation;
- valider les headers proxy : `x-user-email`, `x-tenant-id`, `x-admin-role`;
- valider les roles : `super_admin`, `ops_admin`, `account_manager`, `media_buyer`, `agent`;
- valider les etats UI : loading, error, empty, refresh, no NaN, no mock;
- rapport final avec chemin complet, image, digest, rollback, pages testees et non-regression.

Les prompts restent stricts sur build-from-git, repo clean, commit + push avant build, GitOps strict et interdiction de `kubectl set image`.

Pour le marketing server-side Admin, lire aussi :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\AI_MEMORY\SERVER_SIDE_TRACKING_CONTEXT.md`

## Conversation longue Admin V2

Source :

- `C:\DEV\KeyBuzz\keybuzz-admin-v2\Reconstruction_Admin_V2.txt`

Cette conversation documente la reconstruction Admin V2 depuis l'ancien admin compromis/isole vers un cockpit operations/account management.

Principes a retenir pour prompts CE Admin :

- real data only : supprimer placeholders, mocks, seeds visibles, KPI fake, listes statiques et hardcodages;
- si une donnee n'existe pas, afficher un empty state honnete;
- prouver DB -> API -> UI quand le sujet touche des donnees Admin;
- validation navigateur visible obligatoire pour les phases UI;
- source-of-truth avant feature si doute : verifier runtime, Git, infra manifests, dirty files, commits non pushes, reproductibilite build;
- meme discipline DEV/PROD : image versionnee, digest, manifest GitOps, rollback;
- ne jamais declarer termine si l'image runtime ne correspond pas au code Git.

## Etat recent : Meta CAPI Destinations UI

Source :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-META-CAPI-DESTINATIONS-UI-01.md`

Etat DEV :

- Image Admin DEV : `v2.11.1-meta-capi-destinations-ui-dev`.
- Digest : `sha256:69fa8c088ac6984e1260925bd78c4270b15827045afff443cff611fd20aa0f67`.
- Source : `main`, commit `9226f1f`.
- Infra : `5f4a8dc` + rapport `257b0b5`.
- PROD Admin inchangee : `v2.11.0-tenant-foundation-prod`.

Fonctionnel :

- `/marketing/destinations` supporte maintenant `webhook` et `meta_capi`.
- `meta_capi` expose Pixel ID, token password a la creation, account id optionnel, mapping direct, endpoint auto genere par API.
- Test Meta supporte `test_event_code` et l'API SaaS envoie `PageView`.
- Webhooks inchanges : `ConnectionTest`, HMAC, regenerate-secret.
- `/marketing/delivery-logs` supporte le filtre `PageView`.
- RBAC marketing inchange : super_admin/account_manager/media_buyer.

Avant promotion PROD :

- Exiger une validation navigateur/session reelle sur `admin-dev.keybuzz.io`, car le rapport PH-ADMIN-T8.7C valide surtout le code compile et le pod.

Validation navigateur effectuee ensuite :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-META-CAPI-UI-REAL-BROWSER-VALIDATION-01.md`
- Tenant Keybuzz, session super_admin, UI validee.

Mais ne pas promouvoir PROD Admin avant correction des dettes suivantes :

- `platform_token_ref` input observe en `type="text"` au lieu de `password`.
- Erreur Meta / delivery logs pouvaient afficher le token invalide renvoye par Meta; correction source SaaS API promue en PROD par `PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01.md`. Il reste une defense-in-depth Admin a faire pour ne jamais afficher un secret meme si l'API regressait.
- Destinations de test creees par validation doivent etre supprimees ou desactivees.
- Suppression via `window.confirm()` non fiable en headless; a tester ou remplacer par modal controlee.

Etat API apres correction securite :

- API PROD : `v3.5.100-meta-capi-error-sanitization-prod`.
- Commit API : `f5d6793b`.
- Digest PROD : `sha256:c7f6da86dda0726c0b35653e9dd01ca2ac506acaa6cf8d021fb39594c30e6cfc`.
- Les erreurs Meta et delivery logs renvoient `[REDACTED_TOKEN]`.

Hardening Admin DEV effectue :

- Source : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-META-CAPI-UI-HARDENING-01.md`
- Image Admin DEV : `v2.11.2-meta-capi-ui-hardening-dev`.
- Digest : `sha256:0aac0068eca6221a8e964b4ac4fc80b31d7f5e95a9e5ebd9b6e2e6bcbb3fde1a`.
- Ajoute `src/lib/sanitize-tokens.ts`, `src/components/ui/ConfirmModal.tsx`, redaction UI/proxy/logs.
- Nettoyage destinations test effectue par SQL direct.

Blocage restant avant promotion Admin PROD :

- La route SaaS `DELETE /outbound-conversions/destinations/:id` est absente et retourne 404.
- Donc la suppression UI via ConfirmModal ne fonctionne pas encore de bout en bout.
- Corriger d'abord l'API SaaS, promouvoir API si necessaire, puis revalider la suppression Admin DEV.

Validation ConfirmModal apres fix API DEV :

- Source : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-CONFIRMMODAL-DELETE-E2E-VALIDATION-01.md`
- Admin DEV : `v2.11.2-meta-capi-ui-hardening-dev`.
- API DEV : `v3.5.101-outbound-destinations-delete-route-dev`.
- Tenant teste : KeyBuzz Consulting (`keybuzz-consulting-mo9y479d`).
- Webhook et Meta CAPI supprimes via UI ConfirmModal, appel DELETE API OK.
- Soft delete DB confirme : `deleted_at`, `deleted_by=ludovic@keybuzz.pro`, `is_active=false`.

Le blocage Admin est leve cote DEV. Prochaine etape : promotion API DELETE en PROD, puis promotion Admin PROD.

API DELETE promue en PROD :

- Source : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-PROD-PROMOTION-01.md`
- API PROD : `v3.5.101-outbound-destinations-delete-route-prod`.
- Commit API : `df4a2c5e`.
- Digest PROD : `sha256:bfac9f57ff79a9eaf83e53f9e88bdb3816c3a31456cdf97438465c984dc8c4f3`.
- DELETE Webhook/Meta CAPI, cross-tenant et logs preserves valides.

Admin PROD est maintenant debloque. Prochaine phase : promotion Admin PROD depuis `v2.11.2-meta-capi-ui-hardening-dev`.
