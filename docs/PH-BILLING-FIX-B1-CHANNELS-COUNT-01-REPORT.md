# PH-BILLING-FIX-B1 — Channels Count Fix

> Date : 2026-03-01
> Methode : incrementale (1 bug = 1 mini-phase)
> Scope : 1 fichier, 1 commit, +3/-13 lignes

---

## 1. Resume du Bug

La page `/billing` affichait `0 / 3` pour le compteur de canaux utilises, alors que le tenant `ecomlg-001` a reellement 1 canal actif.

---

## 2. Root Cause Prouvee

### Source de verite

```
GET /billing/current?tenantId=ecomlg-001  →  channelsUsed: 1  (correct)
GET /billing/current?tenantId=ecomlg      →  channelsUsed: 0  (display ID, mauvais)
GET /billing/current?tenantId=            →  rien              (vide, erreur)
```

### Cause

Le fichier `useCurrentPlan.tsx` utilisait une fonction locale `getTenantId()` qui lisait `localStorage.getItem('currentTenantId')`. Cette cle :
- N'est ecrite QUE dans `workspace-setup/page.tsx` (onboarding initial)
- N'est JAMAIS ecrite par le `TenantProvider` (source de verite RBAC)
- Retourne donc `null` ou le display ID (`ecomlg`) au lieu du canonical ID (`ecomlg-001`)

Consequence : l'appel API partait avec un tenantId vide ou incorrect, le backend retournait `channelsUsed: 0`, et l'UI affichait `0 / 3`.

### Piege connu (documente dans les regles projet)

> **PIEGE CRITIQUE** : `getCurrentTenantId()` retourne le display ID (`ecomlg`), mais la DB stocke le canonical ID (`ecomlg-001`). TOUJOURS utiliser `getLastTenant().canonicalId` pour les appels API.

---

## 3. Correction Appliquee

### Fichier modifie

`src/features/billing/useCurrentPlan.tsx` — seul fichier modifie

### Diff

```diff
+import { useTenant } from '@/src/features/tenant/TenantProvider';

-  const getTenantId = (): string | null => {
-    if (typeof window === 'undefined') return null;
-    const stored = localStorage.getItem('currentTenantId');
-    if (stored) return stored;
-    return '';
-  };
+  const { currentTenantId: tenantId } = useTenant();

   const fetchBillingData = useCallback(async () => {
-    const tenantId = getTenantId();
     if (!tenantId) {
       ...
     }
     ...
-  }, []);
+  }, [tenantId]);
```

### Pourquoi cette correction est minimale et suffisante

1. Le `PlanProvider` est enfant de `TenantProvider` dans l'arbre React (verifie dans `app/layout.tsx`)
2. `useTenant()` retourne `currentTenantId` = le canonical ID (`ecomlg-001`)
3. L'ajout de `tenantId` dans les deps du `useCallback` garantit le re-fetch quand le tenant change
4. Aucune nouvelle route, aucun changement API, aucune dependance ajoutee

---

## 4. Commit

```
852ef8f PH-BILLING-FIX-B1: fix billing channels used count - use TenantProvider canonical ID instead of empty localStorage
```

1 fichier, +3 insertions, -13 deletions.

---

## 5. Deploiement DEV

| Element | Valeur |
|---|---|
| Image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.101-billing-fix-b1-dev` |
| Commit | `852ef8f` |
| GitOps commit | `45955f0` |
| Build context | 2.1 MB (whitelist .dockerignore temporaire, non commite) |

---

## 6. Validations Post-Deploy

| Check | Resultat |
|---|---|
| Pod DEV healthy | 1/1 Running, 0 restarts |
| Next.js | Ready in 484ms |
| `/login` | HTTP 200 |
| `/billing` | HTTP 200 |
| Backend `channelsUsed` pour `ecomlg-001` | **1** (correct) |
| PROD intacte | `v3.5.100-ph131-fix-kbactions-prod` |
| Drift Git/Live | AUCUN |

---

## 7. Validation Utilisateur Requise

Pour confirmer visuellement le fix :
1. Se connecter a `https://client-dev.keybuzz.io/login` avec `ludo.gonthier@gmail.com`
2. Naviguer vers `/billing`
3. Verifier que le compteur canaux affiche **1 / 3** (et non plus 0 / 3)

---

## 8. Bugs Observes Mais Non Traites

| # | Bug | Statut |
|---|---|---|
| B2 | Bouton "Acheter KBActions" desactive sur `/billing/ai/manage` | Non traite |
| B3 | Label KBActions incorrect sur `/billing/ai` | Non traite |
| B4 | Guard 403 sur `ai-actions-checkout` | Non traite |
| B5 | Historique factures avec mock data | Non traite |
| B6 | Plan change dialog absent | Non traite |
| B7 | Popup dissuasive annulation absente | Non traite |

### Observation supplementaire (build)

Les fichiers temporaires racine (`ClientLayout-v13.tsx`, `ai-assist-routes.ts`, `src/main.ts`, etc.) empechent le build Docker sans `.dockerignore`. Un `.dockerignore` temporaire (whitelist) a ete utilise sur le bastion pendant le build, puis supprime. Ce probleme devra etre traite dans une mini-phase dediee.

---

## 9. Verdict

### **B1 FIXED AND VALIDATED IN DEV**
