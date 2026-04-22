# PH-ADMIN-T8.8A.3 — METRICS TENANT SCOPE UI FIX

**Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8A.3-METRICS-TENANT-SCOPE-UI-FIX-01.md`

**Date** : 2026-04-23
**Environnement** : DEV uniquement
**Type** : fix UI/proxy — metrics tenant-scoped
**Priorité** : P0

---

## 1. PRÉFLIGHT

| Élément | Valeur |
|---|---|
| Branche Admin | `main` |
| HEAD avant fix | `aef2be2` |
| HEAD après fix | `286c80c` |
| Repo clean | OUI |
| Image Admin DEV avant | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.2-meta-capi-ui-hardening-dev` |
| Image Admin PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.2-meta-capi-ui-hardening-prod` |
| Image API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.103-ad-spend-global-import-lock-dev` |
| Image API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.103-ad-spend-global-import-lock-prod` |
| PROD inchangée | OUI |

---

## 2. AUDIT CAUSE RACINE

### Problème observé
En DEV et PROD Admin, la page `/metrics` affichait les mêmes métriques globales (spend, MRR, CAC, ROAS) quel que soit le tenant sélectionné.

### Cause racine identifiée

Deux bugs dans la chaîne Admin → API :

| Point | Résultat |
|---|---|
| Page `/metrics` connaît `tenantId` via `useCurrentTenant()` | OUI (ligne 139) |
| Page envoie le tenant au proxy | OUI mais en `tenantId` (camelCase) |
| Proxy forwarde `tenant_id` vers API SaaS | **NON** — le proxy ignorait complètement le paramètre |
| API SaaS attend `tenant_id` (snake_case) | OUI confirmé |

**Bug 1** : Le proxy `src/app/api/admin/metrics/overview/route.ts` ne lisait que `from` et `to`. Le paramètre `tenantId`/`tenant_id` envoyé par la page était silencieusement ignoré.

**Bug 2** : La page `src/app/(admin)/metrics/page.tsx` envoyait `tenantId` (camelCase) alors que l'API SaaS attend `tenant_id` (snake_case).

---

## 3. FICHIERS MODIFIÉS

### `src/app/api/admin/metrics/overview/route.ts` (proxy)

Ajout de la lecture et du forwarding de `tenant_id` :

```diff
   const from = searchParams.get('from');
   const to = searchParams.get('to');
+  const tenantId = searchParams.get('tenant_id') || searchParams.get('tenantId');

   const params = new URLSearchParams();
   if (from) params.set('from', from);
   if (to) params.set('to', to);
+  if (tenantId) params.set('tenant_id', tenantId);
```

Le proxy accepte `tenant_id` ET `tenantId` par compatibilité, mais forwarde toujours sous la forme `tenant_id` vers l'API SaaS.

### `src/app/(admin)/metrics/page.tsx` (page UI)

Correction du nom du paramètre :

```diff
-      if (tenantId) params.set('tenantId', tenantId);
+      if (tenantId) params.set('tenant_id', tenantId);
```

---

## 4. VALIDATION API VIA PROXY

Tests directs sur l'API SaaS DEV externe :

| Appel | `spend.scope` | `spend.source` | `spend.total_eur` | OK |
|---|---|---|---|---|
| `tenant_id=ecomlg-001` | `tenant` | `no_data` | 0 | ✓ |
| `tenant_id=keybuzz-consulting-mo9y479d` (range courte) | `tenant` | `no_data` | 0 | ✓ |
| `tenant_id=keybuzz-consulting-mo9y479d` (range complète) | `tenant` | `ad_spend_tenant` | 512.29 | ✓ |
| sans `tenant_id` | `global` | `no_data` | 0 (MRR 497 EUR) | ✓ |

La séparation tenant/global fonctionne correctement au niveau API.

---

## 5. VALIDATION NAVIGATEUR RÉELLE

Sur `https://admin-dev.keybuzz.io/metrics` avec session `ludovic@keybuzz.pro` :

| Tenant | Spend attendu | Spend observé | OK |
|---|---|---|---|
| **KeyBuzz Consulting** | 512 EUR (tenant spend Meta) | **512 EUR** | ✓ |
| **eComLG** | — / 0 (aucun spend tenant) | **— (aucune donnée)** + bannière jaune | ✓ |
| **Retour KeyBuzz Consulting** | 512 EUR | **512 EUR** (pas de résidu du tenant précédent) | ✓ |

Vérifications complémentaires :
- Bannière "Aucune donnée réelle de dépenses publicitaires disponible" pour eComLG : ✓
- CAC/ROAS : `—` quand pas de spend tenant : ✓
- Aucun NaN : ✓
- Aucun undefined : ✓
- Dates from/to fonctionnelles : ✓
- Bouton Rafraîchir fonctionnel : ✓
- Changement de tenant recharge les métriques automatiquement : ✓

---

## 6. NON-RÉGRESSION

| Page | État | OK |
|---|---|---|
| `/metrics` | Fonctionnelle, tenant-scoped | ✓ |
| `/marketing/destinations` | Charge normalement | ✓ |
| `/marketing/delivery-logs` | Charge normalement | ✓ |
| `/marketing/integration-guide` | Complète, code samples visibles | ✓ |
| Sidebar / Topbar | Intactes | ✓ |
| Tenant selector | Fonctionnel, liste complète | ✓ |
| Login / Session | OK | ✓ |
| Aucun NaN / undefined / mock | ✓ | ✓ |
| Admin PROD inchangé | `v2.11.2-meta-capi-ui-hardening-prod` | ✓ |
| API non modifiée | ✓ | ✓ |
| DB non modifiée | ✓ | ✓ |
| Client SaaS non modifié | ✓ | ✓ |

---

## 7. IMAGE DEV

| Élément | Valeur |
|---|---|
| Tag | `v2.11.3-metrics-tenant-scope-fix-dev` |
| Registry | `ghcr.io/keybuzzio/keybuzz-admin` |
| Digest | `sha256:0bb88cc0f98ae8ad3214efb0db657373ef44659c986bce45e7eab1e21e6002e2` |
| Build | `--no-cache`, build-from-git |
| Commit source | `286c80c` |
| Manifest | `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml` |
| GitOps strict | OUI (commit + push manifest + kubectl apply) |

---

## 8. ROLLBACK DEV

Image précédente : `v2.11.2-meta-capi-ui-hardening-dev`

Procédure :
1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml`
2. Remplacer l'image par `ghcr.io/keybuzzio/keybuzz-admin:v2.11.2-meta-capi-ui-hardening-dev`
3. Commit + push
4. `kubectl apply -f keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml`

**Aucun `kubectl set image`.**

---

## 9. PROD INCHANGÉE

| Élément | Valeur |
|---|---|
| Image Admin PROD | `v2.11.2-meta-capi-ui-hardening-prod` (inchangée) |
| Image API PROD | `v3.5.103-ad-spend-global-import-lock-prod` (inchangée) |
| Manifest PROD | Non modifié |

---

## 10. RECOMMANDATION PROMOTION PROD

**GO** pour promotion PROD.

Le fix est chirurgical (4 lignes, 2 fichiers), la cause racine est claire, et la validation navigateur prouve le comportement correct :
- KeyBuzz Consulting voit son spend tenant (512 EUR)
- eComLG ne voit aucun spend global
- Le changement de tenant recharge les métriques automatiquement
- Aucune régression sur les autres pages

Image PROD cible : `v2.11.3-metrics-tenant-scope-fix-prod`

---

## VERDICT

**ADMIN METRICS TENANT SCOPE FIXED IN DEV — NO GLOBAL SPEND DISPLAYED FOR TENANT METRICS — READY FOR PROD PROMOTION**
