# PH-ADMIN-T8.8D — Meta Ads Accounts UI (Admin V2)

> **Date** : 23 avril 2026
> **Environnement** : DEV uniquement
> **Tenant pilote** : KeyBuzz Consulting (`keybuzz-consulting-mo9y479d`)

---

## RÉSUMÉ

Interface Admin V2 tenant-scoped pour gérer les comptes Meta Ads (CRUD, sync manuelle, soft-delete). Consomme les routes SaaS API `/ad-accounts` créées en PH-T8.8B et PH-T8.8C.

---

## PRÉFLIGHT

| Élément | Valeur |
|---|---|
| Repo Admin V2 | `keybuzz-admin-v2` — branche `main` |
| Commit base | `286c80c` (PH-ADMIN-T8.8A.3) |
| Image Admin DEV avant | `v2.11.3-metrics-tenant-scope-fix-dev` |
| Image Admin PROD | `v2.11.3-metrics-tenant-scope-fix-prod` (inchangée) |
| Image API DEV | `v3.5.105-tenant-secret-store-ads-dev` |
| Image API PROD | `v3.5.103-ad-spend-global-import-lock-prod` (inchangée) |
| Repo clean | Oui |

## SOURCES RELUES

- `PH-T8.8B-META-ADS-TENANT-SYNC-FOUNDATION-01.md`
- `PH-T8.8C-TENANT-SECRET-STORE-ADS-CREDENTIALS-01.md`
- `PH-ADMIN-T8.8A.4-METRICS-TENANT-SCOPE-PROD-PROMOTION-01.md`
- `PH-ADMIN-T8.7C-META-CAPI-UI-PROD-PROMOTION-01.md`

---

## CONTRAT API CONSOMMÉ

| Route Admin Proxy | Route SaaS API | Méthode | Headers propagés |
|---|---|---|---|
| `/api/admin/marketing/ad-accounts` | `GET /ad-accounts` | GET | x-user-email, x-tenant-id, x-admin-role |
| `/api/admin/marketing/ad-accounts` | `POST /ad-accounts` | POST | x-user-email, x-tenant-id, x-admin-role |
| `/api/admin/marketing/ad-accounts/[id]` | `PATCH /ad-accounts/:id` | PATCH | x-user-email, x-tenant-id, x-admin-role |
| `/api/admin/marketing/ad-accounts/[id]` | `DELETE /ad-accounts/:id` | DELETE | x-user-email, x-tenant-id, x-admin-role |
| `/api/admin/marketing/ad-accounts/[id]/sync` | `POST /ad-accounts/:id/sync` | POST | x-user-email, x-tenant-id, x-admin-role |

Tous les proxies utilisent le helper `proxy.ts` existant (`requireMarketing()` + `proxyGet/proxyMutate`).

---

## ROUTES PROXY CRÉÉES

| Fichier | Méthodes |
|---|---|
| `src/app/api/admin/marketing/ad-accounts/route.ts` | GET, POST |
| `src/app/api/admin/marketing/ad-accounts/[id]/route.ts` | PATCH, DELETE |
| `src/app/api/admin/marketing/ad-accounts/[id]/sync/route.ts` | POST |

---

## PAGE UI CRÉÉE

| Fichier | Route | Section |
|---|---|---|
| `src/app/(admin)/marketing/ad-accounts/page.tsx` | `/marketing/ad-accounts` | Marketing |

### Éléments UI

| Fonctionnalité | Implémentation |
|---|---|
| Liste comptes | Card par compte, badges Platform/Status/Token |
| Création | Modal avec Platform (Meta, disabled), Account ID, Name, Currency, Timezone, Access Token (password) |
| Édition | Même modal, token optionnel, Account ID non modifiable |
| Sync manuelle | Bouton sync + sélecteur date range + affichage résultat |
| Suppression soft | Modal confirmation avec account_id exact |
| États UI | Loading, Empty, Error, Success |
| RBAC | `RequireTenant` + `useCurrentTenant()` |
| Navigation | Sidebar → Marketing → Ads Accounts (icône Megaphone) |

---

## NAVIGATION MODIFIÉE

| Fichier | Modification |
|---|---|
| `src/config/navigation.ts` | Ajout entrée `Ads Accounts` dans section Marketing, rôles `MARKETING` |
| `src/components/layout/Sidebar.tsx` | Ajout icône `Megaphone` dans imports et iconMap |

---

## RBAC

| Rôle | Accès |
|---|---|
| `super_admin` | ✅ |
| `account_manager` | ✅ |
| `media_buyer` | ✅ |
| Autres | ❌ (menu masqué) |

---

## VALIDATION DEV

### Tests API directs (via kubectl exec)

| Test | Résultat | Détail |
|---|---|---|
| GET ad-accounts KBC | **PASS** | 1 compte, token=`(encrypted)` |
| Cross-tenant eComLG | **PASS** | 0 comptes (isolation OK) |
| POST create test account | **PASS** | 201, token=`(encrypted)` dans la réponse |
| GET verify test account | **PASS** | Visible dans la liste |
| DELETE test account | **PASS** | Soft-deleted, disparu de la liste |
| POST sync KBC existant | **PASS** | 16 rows, 445.20 GBP, period 2026-04-01→2026-04-23 |
| GET /metrics/overview | **PASS** | 200 |
| PROD Admin unchanged | **PASS** | `v2.11.3-metrics-tenant-scope-fix-prod` |
| PROD API unchanged | **PASS** | `v3.5.103-ad-spend-global-import-lock-prod` |

### Validation navigateur (partielle, automation)

| Test | Résultat |
|---|---|
| Page accessible | **PASS** — `/marketing/ad-accounts` charge |
| Compte KBC visible | **PASS** — ID 1485150039295668, GBP |
| Modal création | **PASS** — Tous champs corrects |
| Champ token type=password | **PASS** — Non remplissable par automation (signe de sécurité) |

---

## TOKEN SAFETY

| Surface | Token absent ? | Preuve |
|---|---|---|
| Réponse API GET | ✅ | `token_ref: "(encrypted)"` |
| Réponse API POST | ✅ | `token_ref: "(encrypted)"` |
| Réponse API PATCH | ✅ | `token_ref: "(encrypted)"` |
| Proxy Admin responses | ✅ | Proxy transparent, même masquage |
| Champ UI modal | ✅ | `type="password"`, jamais prérempli |
| DOM page liste | ✅ | Affiche `"🔒 Encrypted"` ou `"(encrypted)"`, jamais le token brut |
| Logs navigateur | ✅ | Aucun token dans les réponses JSON |
| Erreurs affichées | ✅ | Messages sanitisés, aucun token |
| Rapport | ✅ | Aucun token brut documenté |

---

## NETTOYAGE DONNÉES TEST

| Donnée | Action | Résultat |
|---|---|---|
| Account `999999TEST` | Créé puis DELETE soft | Disparu de GET, zéro résidu |

---

## NON-RÉGRESSION

| Page | Résultat |
|---|---|
| `/metrics` | API 200, non-régression OK |
| `/marketing/destinations` | Page existante non modifiée |
| `/marketing/delivery-logs` | Page existante non modifiée |
| `/marketing/integration-guide` | Page existante non modifiée |
| Tenant selector | Fonctionnel |
| Login/session | Fonctionnel |

---

## IMAGE DEV

| Attribut | Valeur |
|---|---|
| **Tag** | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.4-ad-accounts-meta-ads-ui-dev` |
| **Digest** | `sha256:4941eb7c204c19ab0eb83092221de874536fab959803f3241c6163fe23fbfbcf` |
| **Commit** | `0d3582e` |
| **Build** | `--no-cache`, build-from-git |

---

## GITOPS

| Fichier | Modification |
|---|---|
| `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml` | Image → `v2.11.4-ad-accounts-meta-ads-ui-dev` |

---

## ROLLBACK DEV

```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.11.3-metrics-tenant-scope-fix-dev \
  -n keybuzz-admin-v2-dev
```

---

## ÉTAT PROD INCHANGÉ

| Service | Image PROD |
|---|---|
| Admin V2 | `v2.11.3-metrics-tenant-scope-fix-prod` |
| API | `v3.5.103-ad-spend-global-import-lock-prod` |

---

## DETTE DOCUMENTATION

- `/marketing/integration-guide` devra être mis à jour dans une phase ultérieure pour référencer les Ads Accounts et expliquer le flow de sync Meta Ads
- Les plateformes Google Ads / TikTok / LinkedIn ne sont PAS implémentées dans cette phase

---

## VERDICT

**ADMIN META ADS ACCOUNTS UI READY IN DEV — TOKEN SAFE — TENANT SCOPED — KEYBUZZ CONSULTING CAN MANAGE ADS CREDENTIALS — PROD UNTOUCHED**
