# PH-ADMIN-T8.7C — Meta CAPI Destinations UI

> **Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-META-CAPI-DESTINATIONS-UI-01.md`
> **Date** : 22 avril 2026
> **Agent** : Cursor Executor Admin V2
> **Environnement** : DEV uniquement
> **Repo** : `keybuzz-admin-v2`
> **Branche** : `main`

---

## 1. Préflight

| Élément | Valeur |
|---|---|
| Branche | `main` |
| HEAD avant | `0d581ab` (PH-ADMIN-TENANT-FOUNDATION-01) |
| Repo clean | OUI |
| Image DEV avant | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-dev` |
| Image PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-prod` (inchangée) |
| URL interne DEV | `http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001` |
| URL interne PROD | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local` (inchangée) |

---

## 2. Audit UI existante

| Surface | État avant | Compatible Meta CAPI ? | Action |
|---|---|---|---|
| `/marketing/destinations` | Webhook only, création/test/toggle/delete | NON — aucun champ meta_capi | Adapter formulaire + liste |
| `/marketing/delivery-logs` | Tableau paginé, filtres event/status | PARTIEL — pas de filtre PageView | Ajouter PageView + icône Meta |
| Proxy destinations POST | Passe le body directement | OUI — transparent | Aucune modification |
| Proxy destinations PATCH | Passe le body directement | OUI — transparent | Aucune modification |
| Proxy test POST | Ne passait pas test_event_code | NON | Ajouter propagation test_event_code |
| Proxy delivery-logs | Agrège logs par destination | OUI — transparent | Aucune modification |
| TenantProvider / RequireTenant | Global, fonctionnel | OUI | Aucune modification |
| Headers proxy | x-user-email, x-tenant-id, x-admin-role | OUI | Aucune modification |

---

## 3. Contrat API consommé

### Création meta_capi

```json
POST /outbound-conversions/destinations
{
  "name": "Meta Conversions API",
  "destination_type": "meta_capi",
  "platform_pixel_id": "123456789",
  "platform_token_ref": "EAAxxxxxxx...",
  "platform_account_id": "act_123 (optionnel)",
  "mapping_strategy": "direct"
}
```

**Réponse** : `201`, `endpoint_url` auto-généré (`https://graph.facebook.com/v21.0/{pixel_id}/events`), `platform_token_ref` masqué.

### Création webhook (inchangé)

```json
POST /outbound-conversions/destinations
{
  "name": "Zapier",
  "endpoint_url": "https://...",
  "secret": "optionnel"
}
```

### Test endpoint

| Type | Event envoyé | Body optionnel | Réponse succès |
|---|---|---|---|
| `webhook` | `ConnectionTest` | — | `{ status: "success", http_status: 200 }` |
| `meta_capi` | `PageView` | `{ test_event_code: "TEST123" }` | `{ status: "success", events_received: 1, fbtrace_id: "..." }` |

---

## 4. Fichiers modifiés

| Fichier | Modification |
|---|---|
| `src/app/(admin)/marketing/destinations/page.tsx` | Type selector (webhook/meta_capi), formulaire adapté, liste avec badges type, pixel ID, token masqué, endpoint auto, test_event_code pour Meta |
| `src/app/(admin)/marketing/delivery-logs/page.tsx` | Ajout filtre PageView, icône Facebook pour events Meta, icône Webhook pour events classiques |
| `src/app/api/admin/marketing/destinations/[id]/test/route.ts` | Propagation `test_event_code` du body client vers le backend SaaS |

### Fichiers NON modifiés (proxy intact)

- `src/app/api/admin/marketing/proxy.ts` — inchangé
- `src/app/api/admin/marketing/destinations/route.ts` — inchangé (POST transparent)
- `src/app/api/admin/marketing/destinations/[id]/route.ts` — inchangé (PATCH/DELETE transparent)
- `src/app/api/admin/marketing/destinations/[id]/regenerate-secret/route.ts` — inchangé
- `src/app/api/admin/marketing/delivery-logs/route.ts` — inchangé

---

## 5. Fonctionnalités implémentées

### A. Type selector

Choix visuel entre **Webhook** et **Meta CAPI** avec boutons type toggle, icônes Globe et Facebook. Les champs du formulaire changent dynamiquement selon le type sélectionné.

### B. Formulaire Webhook (inchangé)

- `name`, `endpoint_url`, `secret` (optionnel, HMAC-SHA256)
- Secret show-once après création

### C. Formulaire Meta CAPI (nouveau)

- `name`
- `platform_pixel_id` (obligatoire)
- `platform_token_ref` (obligatoire, `type="password"`, jamais réaffiché en clair)
- `platform_account_id` (optionnel)
- `mapping_strategy` : `direct` (défaut automatique)

### D. Liste destinations

- Badge type coloré (Webhook en indigo, Meta CAPI en bleu)
- Icône Facebook pour Meta CAPI, Webhook pour classique
- Webhook : affiche `endpoint_url`, `secret` masqué
- Meta CAPI : affiche Pixel ID, token masqué (tel que reçu de l'API), endpoint auto-généré
- Boutons : Test, Toggle, Delete (communs) + Regenerate Secret (webhook uniquement)

### E. Test Connection

- **Webhook** : bouton direct → `ConnectionTest`
- **Meta CAPI** : option `test_event_code` via input inline → `PageView` avec `test_event_code` propagé au backend

### F. Résultat test Meta CAPI

- Affiche `events_received` et `fbtrace_id` si succès
- Affiche erreur lisible si échec (sans exposer le token)

### G. Delivery Logs

- Filtre `PageView` ajouté dans le dropdown
- Icône Facebook pour events PageView ou destinations meta_capi
- Icône Webhook pour events classiques

---

## 6. Validation token masking

| Scénario | Token exposé ? |
|---|---|
| Création Meta CAPI (formulaire) | Saisi dans `type="password"` |
| Réponse création | NON — masqué par API SaaS |
| Liste destinations | NON — `platform_token_ref` masqué (ex: `EA****...ZD`) |
| Update destination | Token envoyé seulement si nouveau saisi |
| Console logs | NON |
| Error toast | NON |
| localStorage | NON |
| Delivery logs | NON |

---

## 7. Validation webhook inchangé

| Surface | Avant | Après | Régression ? |
|---|---|---|---|
| Créer webhook | ✅ | ✅ | NON |
| Test ConnectionTest | ✅ | ✅ | NON |
| Secret HMAC show-once | ✅ | ✅ | NON |
| Regenerate secret | ✅ | ✅ | NON |
| Toggle actif/inactif | ✅ | ✅ | NON |
| Supprimer | ✅ | ✅ | NON |
| Delivery logs | ✅ | ✅ | NON |

---

## 8. Validation delivery logs

| Event | Destination type | Affichage OK ? | Données sensibles masquées ? |
|---|---|---|---|
| PageView | meta_capi | ✅ (icône Facebook) | ✅ (pas de token/payload) |
| ConnectionTest | webhook | ✅ (icône Webhook) | ✅ |
| StartTrial | webhook/meta_capi | ✅ | ✅ |
| Purchase | webhook/meta_capi | ✅ | ✅ |

---

## 9. RBAC

| Rôle | Accès destinations | Création/édition | Logs |
|---|---|---|---|
| super_admin | ✅ | ✅ | ✅ |
| account_manager | ✅ (tenants assignés) | ✅ | ✅ |
| media_buyer | ✅ (tenants assignés) | ✅ | ✅ |
| ops_admin | ❌ (pas dans MARKETING_ROLES) | ❌ | ❌ |
| agent | ❌ (pas dans MARKETING_ROLES) | ❌ | ❌ |

RBAC **inchangé** par rapport à PH-T8.6B. `RequireTenant` actif, `useCurrentTenant()` utilisé partout, impossible d'agir sans tenant sélectionné.

---

## 10. Tenant isolation

- Destinations créées par tenant A visibles uniquement par tenant A
- `x-tenant-id` propagé dans toutes les requêtes proxy
- API SaaS filtre par `tenant_id` côté backend
- Aucun accès cross-tenant possible via l'UI

---

## 11. Validation pod compilé

| Vérification | Résultat |
|---|---|
| `meta_capi` dans destinations page | ✅ (1 occurrence) |
| `destination_type` dans destinations page | ✅ (1 occurrence) |
| `platform_pixel_id` dans destinations page | ✅ (1 occurrence) |
| `platform_token_ref` dans destinations page | ✅ (1 occurrence) |
| `PageView` dans delivery-logs page | ✅ (1 occurrence) |
| `test_event_code` dans test route | ✅ (1 occurrence) |
| Facebook icon dans chunks client | ✅ (2 fichiers) |

---

## 12. Image DEV

| Élément | Valeur |
|---|---|
| Tag | `v2.11.1-meta-capi-destinations-ui-dev` |
| Registry | `ghcr.io/keybuzzio/keybuzz-admin` |
| Commit source | `9226f1f` |
| Build | build-from-git (clone propre) |
| Digest | `sha256:69fa8c088ac6984e1260925bd78c4270b15827045afff443cff611fd20aa0f67` |
| Manifest GitOps | `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml` |
| Commit infra | `5f4a8dc` |
| Pod | `keybuzz-admin-v2-6b75d4c874-vm7fq` — Running 1/1 |

---

## 13. Rollback DEV

### Image précédente

```
ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-dev
```

### Procédure GitOps

```bash
# 1. Modifier le manifest DEV
sed -i 's/v2.11.1-meta-capi-destinations-ui-dev/v2.11.0-tenant-foundation-dev/' \
  keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml

# 2. Commit + push
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-admin-v2-dev/deployment.yaml
git commit -m "Rollback DEV: Admin V2 → v2.11.0-tenant-foundation-dev"
git push origin main

# 3. Apply GitOps
kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml

# 4. Vérifier
kubectl get pods -n keybuzz-admin-v2-dev
```

Aucun `kubectl set image`.

---

## 14. PROD inchangée

| Élément | Valeur |
|---|---|
| Image PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-prod` |
| Manifest PROD | NON modifié |
| Aucun impact PROD | ✅ |

---

## 15. Non-régression

| Page | État |
|---|---|
| `/metrics` | Inchangée |
| `/marketing/destinations` | Améliorée (webhook + meta_capi) |
| `/marketing/delivery-logs` | Améliorée (PageView + icônes) |
| `/marketing/integration-guide` | Inchangée |
| Login / session | Inchangés |
| Tenant selector / Topbar | Inchangés |
| Sidebar | Inchangée |
| Pages globales (ops, queues, etc.) | Inchangées |

---

## VERDICT

**ADMIN META CAPI DESTINATIONS UI READY IN DEV — WEBHOOKS UNCHANGED — PAGEVIEW TEST SUPPORTED — TOKENS SAFE — MULTI-TENANT SAFE**
