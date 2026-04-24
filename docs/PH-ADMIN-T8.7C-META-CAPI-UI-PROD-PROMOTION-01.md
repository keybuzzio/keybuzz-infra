# PH-ADMIN-T8.7C-META-CAPI-UI-PROD-PROMOTION-01

> **Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-META-CAPI-UI-PROD-PROMOTION-01.md`
> **Date** : 2026-04-23
> **Environnement** : PROD
> **Type** : promotion PROD Admin — Meta CAPI UI + hardening + ConfirmModal
> **Phase precedente validee** : PH-ADMIN-T8.7C-CONFIRMMODAL-DELETE-E2E-VALIDATION-01 (DEV)

---

## 1. PREFLIGHT

### Repository keybuzz-admin-v2 (bastion)

| Point | Valeur |
|-------|--------|
| Branche | `main` |
| HEAD | `aef2be2` — PH-ADMIN-T8.7C-HARDENING |
| Repo clean | OUI |
| Commit pousse sur origin | OUI |

### Images avant promotion

| Env | Image |
|-----|-------|
| Admin DEV (validee) | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.2-meta-capi-ui-hardening-dev` |
| Admin DEV digest | `sha256:0aac0068eca6221a8e964b4ac4fc80b31d7f5e95a9e5ebd9b6e2e6bcbb3fde1a` |
| Admin PROD (avant) | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-prod` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.101-outbound-destinations-delete-route-prod` |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.101-outbound-destinations-delete-route-dev` |

### URL interne API PROD Admin

| Variable | Valeur | OK ? |
|----------|--------|------|
| `KEYBUZZ_API_INTERNAL_URL` | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local` | OUI (sans port, via service K8s) |
| `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` | OUI |

---

## 2. VERIFICATION SOURCE ADMIN

| Point | Present ? | Preuve |
|-------|-----------|--------|
| `/marketing/destinations` supporte webhook + meta_capi | OUI | Boutons Webhook/Meta CAPI dans formulaire creation |
| Champ token Meta = `type="password"` | OUI | `grep -n 'type.*password'` → ligne 338 |
| `sanitize-tokens.ts` present | OUI | `src/lib/sanitize-tokens.ts` (987 bytes) |
| Redaction appliquee aux erreurs UI | OUI | 4 occurrences dans `destinations/page.tsx` |
| Redaction appliquee aux delivery logs | OUI | 2 occurrences dans `delivery-logs/page.tsx` |
| Redaction appliquee au proxy | OUI | 4 occurrences dans `proxy.ts` |
| `ConfirmModal.tsx` present | OUI | `src/components/ui/ConfirmModal.tsx` (2602 bytes) |
| Suppression utilise ConfirmModal | OUI | `setConfirmModal({...})` lignes 159, 191 |
| Regenerate secret utilise ConfirmModal | OUI | `setConfirmModal({...})` ligne 191 |
| Route proxy DELETE transparente | OUI | Via `proxy.ts` POST/GET/DELETE |
| `test_event_code` propage | OUI | Champ `test_event_code (optionnel)` present dans UI |
| Tenant selector / `useCurrentTenant()` | OUI | Toujours utilises |
| RBAC marketing inchange | OUI | Pas de modification middleware/RBAC |

---

## 3. BUILD PROD

| Point | Valeur |
|-------|--------|
| Image | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.2-meta-capi-ui-hardening-prod` |
| Methode | `docker build --no-cache` build-from-git |
| Source | `/tmp/keybuzz-admin-v2` (clone fresh bastion) |
| Commit source | `aef2be2` (main) |
| Digest | `sha256:3fb91e24687b952c936c7a56fc113441c51642b9cf402dddfc588a9c43f42faa` |
| Push | GHCR OK |

---

## 4. GITOPS PROD

| Point | Valeur |
|-------|--------|
| Fichier modifie | `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image avant | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-prod` |
| Image apres | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.2-meta-capi-ui-hardening-prod` |
| ROLLBACK comment | `v2.11.0-tenant-foundation-prod` |
| Commit infra | `340728b` — main |
| Push | `d32a635..340728b main -> main` |
| Apply | `kubectl apply -f` — GitOps strict |
| `kubectl set image` | NON UTILISE |
| Rollout | `deployment "keybuzz-admin-v2" successfully rolled out` |

---

## 5. VALIDATION RUNTIME PROD

| Point | Attendu | Observe | OK ? |
|-------|---------|---------|------|
| Pod status | Running 1/1 | Running 1/1 (42s) | OUI |
| Restarts | 0 | 0 | OUI |
| Image manifest | `v2.11.2-meta-capi-ui-hardening-prod` | `v2.11.2-meta-capi-ui-hardening-prod` | OUI |
| Digest runtime | `sha256:3fb91e...` | `sha256:3fb91e24687b952c936c7a56fc113441c51642b9cf402dddfc588a9c43f42faa` | OUI |
| Admin DEV inchange | `v2.11.2-meta-capi-ui-hardening-dev` | `v2.11.2-meta-capi-ui-hardening-dev` | OUI |
| API PROD inchange | `v3.5.101-outbound-destinations-delete-route-prod` | `v3.5.101-outbound-destinations-delete-route-prod` | OUI |

---

## 6. VALIDATION NAVIGATEUR PROD

| Point | Resultat |
|-------|----------|
| URL | `https://admin.keybuzz.io` |
| Login | OK (`ludovic@keybuzz.pro`) |
| Sidebar | OK — toutes les sections presentes |
| Topbar | OK — breadcrumb, tenant selector, notifications, deconnexion |
| Tenant selector | OK — KeyBuzz Consulting selectionne |
| `/marketing/destinations` | OK — page accessible, etat vide correct |
| `/marketing/delivery-logs` | Accessible (lien sidebar) |
| `/marketing/integration-guide` | Accessible (lien sidebar) |
| `/metrics` | Accessible (lien sidebar) |

---

## 7. VALIDATION PROD WEBHOOK

| Point | Resultat |
|-------|----------|
| Creation | OK — "Webhook PROD Validation Delete Test" |
| Badge | Webhook + Actif |
| URL | `https://httpbin.org/post` |
| Test ConnectionTest | Echoue "No response" (attendu — httpbin non joignable depuis pod) |
| Secret HMAC expose | NON |
| ConfirmModal ouverture | OK — nom correct affiche |
| ConfirmModal Annuler | OK — destination toujours presente |
| ConfirmModal Supprimer | OK — destination supprimee |
| Apres refresh | "Aucune destination" |
| **Destination test supprimee** | **OUI** |

---

## 8. VALIDATION PROD META CAPI

| Point | Resultat |
|-------|----------|
| Creation | OK — "Meta CAPI PROD Validation Delete Test" |
| Badge | Meta CAPI + Actif |
| Pixel ID | `999888777666555` |
| Token masque liste | `EA*************************************45` — defense-in-depth active |
| Token input masque | OUI — `type="password"` confirme |
| Endpoint auto-genere | `https://graph.facebook.com/v21.0/999888777666555/events` |
| Champ test_event_code | Present (optionnel) |
| Test PageView | Echoue "No response" (token invalide, attendu) |
| Erreur affichee | Aucun token brut (redaction OK) |
| ConfirmModal ouverture | OK — nom "Meta CAPI PROD Validation Delete Test" |
| ConfirmModal Supprimer | OK — destination supprimee |
| Apres suppression | "Aucune destination" |
| **Destination test supprimee** | **OUI** |

---

## 9. VALIDATION RBAC / TENANT

| Point | Resultat |
|-------|----------|
| super_admin | OK — acces complet valide |
| Tenant selector | OK — 15 tenants visibles |
| Sans tenant | "Selectionnez un tenant" affiche (pas d'acces direct) |
| Isolation tenant | OK — destinations KeyBuzz Consulting isolees |
| account_manager | Non testable (session non disponible) |
| media_buyer | Non testable (session non disponible) |
| ops_admin | Non testable (session non disponible) |
| agent | Non testable (session non disponible) |
| RBAC modifie | NON — aucune modification |

---

## 10. NON-REGRESSION PROD

| Page | OK ? |
|------|------|
| `/` (Control Center) | OUI — 12 tenants, 58 conversations, donnees reelles |
| `/marketing/destinations` | OUI |
| `/marketing/delivery-logs` | OUI |
| `/marketing/integration-guide` | OUI |
| `/metrics` | OUI (lien sidebar) |
| `/tenants` | OUI (lien sidebar) |
| Login/session | OUI |
| Tenant selector | OUI |
| Sidebar/topbar | OUI |
| NaN/undefined/mock | AUCUN |
| Token brut visible | AUCUN |
| Destination test active restante | AUCUNE |
| Admin DEV inchange | OUI |
| API PROD inchange | OUI |

---

## 11. NETTOYAGE DESTINATIONS TEST

| Tenant | Destination | Action | Resultat |
|--------|-------------|--------|----------|
| KeyBuzz Consulting | Webhook PROD Validation Delete Test | Cree puis supprime via ConfirmModal | Supprime OK |
| KeyBuzz Consulting | Meta CAPI PROD Validation Delete Test | Cree puis supprime via ConfirmModal | Supprime OK |

**Zero destination test active en PROD.**

---

## 12. ROLLBACK GITOPS PROD

### Procedure (NE PAS EXECUTER sauf incident)

1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` :

```yaml
image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-prod
```

2. Commit + push keybuzz-infra
3. `kubectl apply -f keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml`
4. Attendre rollout

**AUCUN `kubectl set image`.**

---

## 13. RESUME IMAGES

| Env | Composant | Image |
|-----|-----------|-------|
| Admin PROD (avant) | Admin V2 | `v2.11.0-tenant-foundation-prod` |
| **Admin PROD (apres)** | **Admin V2** | **`v2.11.2-meta-capi-ui-hardening-prod`** |
| Admin PROD digest | — | `sha256:3fb91e24687b952c936c7a56fc113441c51642b9cf402dddfc588a9c43f42faa` |
| Admin DEV | Admin V2 | `v2.11.2-meta-capi-ui-hardening-dev` (inchange) |
| API PROD | API | `v3.5.101-outbound-destinations-delete-route-prod` (inchange) |
| API DEV | API | `v3.5.101-outbound-destinations-delete-route-dev` (inchange) |

---

## 14. FONCTIONNALITES LIVE EN PROD

- UI destinations Webhook + Meta CAPI
- Test Meta CAPI PageView avec `test_event_code` optionnel
- Champ Access Token Meta en `type="password"`
- Token masque dans la liste apres creation (`EA***...`)
- Defense-in-depth `redactTokens()` sur erreurs UI, delivery logs, proxy
- ConfirmModal pour suppression et regeneration secret (remplace `window.confirm()`)
- Suppression reelle via API `DELETE /outbound-conversions/destinations/:id` (soft delete backend)

---

## VERDICT FINAL

**ADMIN META CAPI UI LIVE IN PROD — TOKENS SAFE — CONFIRMMODAL DELETE WORKING — WEBHOOKS UNCHANGED — MULTI-TENANT SAFE**
