# PH-SOURCE-OF-TRUTH-RECOVERY-01 — Rapport

> **Date** : 24 mars 2026
> **Mode** : LECTURE SEULE — aucune modification runtime
> **Scope** : DEV + PROD + GitOps + Bastion + Pipeline
> **Verdict** : **SOURCE OF TRUTH BROKEN — RECOVERY REQUIRED BEFORE ANY NEW BUILD**

---

## 1. INVENTAIRE RUNTIME EXACT

| Env | Service | Image | Pods | Restarts | Status |
|-----|---------|-------|------|----------|--------|
| DEV | Client | `v3.5.77-ph119-role-access-guard-dev` | 1/1 Running | 0 | Healthy |
| DEV | API | `v3.5.49-amz-orders-list-sync-fix-dev` | 1/1 Running | 0 | Healthy |
| DEV | Backend | `v1.0.40-amz-tracking-visibility-backfill-dev` | 1/1 Running | 0 | Healthy |
| PROD | Client | `v3.5.77-ph119-role-access-guard-prod` | 1/1 Running | 0 | Healthy |
| PROD | API | `v3.5.49-amz-orders-list-sync-fix-prod` | 1/1 Running | 0 | Healthy |
| PROD | Backend | `v1.0.40-amz-tracking-visibility-backfill-prod` | 1/1 Running | 0 | Healthy |

**Runtime = SAIN et FONCTIONNEL.**

---

## 2. VERIFICATION FONCTIONNELLE RUNTIME

| Env | Page | HTTP | Conforme |
|-----|------|------|----------|
| DEV | /login | 200 | oui |
| DEV | /dashboard | 200 | oui |
| DEV | /inbox | 200 | oui |
| DEV | /orders | 200 | oui |
| DEV | /billing | 200 | oui |
| DEV | /ai-dashboard | 200 | oui |
| DEV | /settings | 200 | oui |
| DEV | Amazon status | connected=true, CONNECTED | oui |
| DEV | API health | ok | oui |
| PROD | Toutes pages | 200 | oui (confirme par rollback PH119 stable) |

**Runtime = VERIFIE FONCTIONNEL.**

---

## 3. COMPARAISON RUNTIME ↔ GITOPS

### 3.1 — Images

| Source | DEV Client | PROD Client |
|--------|-----------|-------------|
| Cluster (kubectl) | `v3.5.77-ph119-role-access-guard-dev` | `v3.5.77-ph119-role-access-guard-prod` |
| Manifest commite (Git HEAD) | `v3.5.77-ph119-role-access-guard-dev` | `v3.5.77-ph119-role-access-guard-prod` |
| Manifest working dir | idem | idem |

**Image tags : COHERENT.**

### 3.2 — Manifests

| Element | Commite dans Git | Present dans cluster | Drift |
|---------|-----------------|---------------------|-------|
| Image tag v3.5.77 | oui | oui | non |
| readinessProbe tcpSocket:3000 | **NON** | **OUI** | **OUI** |
| livenessProbe tcpSocket:3000 | **NON** | **OUI** | **OUI** |
| maxUnavailable: 0 | **NON** | **OUI** | **OUI** |
| maxSurge: 1 | **NON** | **OUI** | **OUI** |
| minReadySeconds: 5 | **NON** | **OUI** | **OUI** |

**Drift manifests : Les readiness/liveness probes et la strategie zero-downtime sont dans le cluster (appliquees via kubectl) mais PAS commitees dans Git.**

ArgoCD detecte ce drift et affiche `OutOfSync` pour DEV et PROD.

---

## 4. AUDIT REPO CLIENT SOURCE (bastion)

### Etat Git

| Element | Valeur |
|---------|--------|
| Branche | `fix/signup-redirect-v2` |
| HEAD local | `7cf7264` (PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02) |
| HEAD remote | `61a3116` |
| Commits locaux non pushes | **5** |
| Fichiers modifies non commites | **23** |
| Fichiers non-suivis | **1** (`src/lib/routeAccessGuard.ts`) |
| Stash | 3 entrees |

### Commits locaux non pushes (5)

```
7cf7264 PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02: add CSV export button + BFF route
5b32aeb PH118: onboarding hardening
d6583e9 PH117-DESIGN-ALIGNMENT-02: Metronic light/dark alignment
ac0f8c1 PH117-REBUILD-CLEAN-01: AI Dashboard page + BFF
cf3c242 PH-ONBOARDING-PLAN-STATE-CONTINUITY-01: fix plan/cycle state loss
```

### Fichiers modifies non commites (23)

```
app/ai-dashboard/page.tsx
app/ai-journal/page.tsx
app/api/amazon/status/route.ts
app/orders/[orderId]/page.tsx
app/orders/page.tsx
app/playbooks/[playbookId]/page.tsx
app/playbooks/[playbookId]/tester/page.tsx
app/playbooks/new/page.tsx
app/playbooks/page.tsx
app/settings/components/ProfileTab.tsx
app/settings/constants.ts
app/settings/page.tsx
app/settings/types.ts
app/settings/utils.ts
middleware.ts
src/components/auth/AuthGuard.tsx
src/components/auth/AuthProvider.tsx
src/components/layout/ClientLayout.tsx
src/features/ai-journal/storage.ts
src/features/ai-ui/AIModeSwitch.tsx
src/features/tenant/useTenantId.ts
src/services/playbooks.service.ts
tsconfig.tsbuildinfo
```

**TOTAL : 5135 insertions, 4716 deletions dans les fichiers dirty.**

### Fichier non-suivi (1)

```
src/lib/routeAccessGuard.ts     ← cree par PH119, JAMAIS commite
```

### Impact

L'image saine `v3.5.77` a ete construite depuis cet etat dirty. Un `build-from-git.sh` (clone depuis GitHub) produirait une image **RADICALEMENT DIFFERENTE** — sans PH117 a PH119, sans Amazon fixes, sans onboarding hardening.

---

## 5. AUDIT REPO INFRA SOURCE (bastion)

| Element | Valeur |
|---------|--------|
| Branche | `main` |
| HEAD local | `acbaab5` (PH119-ROLE-ACCESS-GUARD-01) |
| HEAD remote | `acbaab5` |
| Sync | **COHERENT** (0 behind, 0 ahead) |
| Fichiers modifies | **2** (deployment.yaml DEV + PROD) |

Les 2 fichiers modifies contiennent les readiness probes + strategie zero-downtime ajoutees dans PH-HARD-REFRESH-FIRST-HIT-STABILITY-01.

---

## 6. AUDIT REPO API SOURCE (bastion)

| Element | Valeur |
|---------|--------|
| Branche | `main` |
| HEAD local | `8fac4ec` |
| HEAD remote | `8fac4ec` |
| Sync | **COHERENT** (0 behind, 0 ahead) |
| Fichiers modifies | **3** |
| Fichiers non-suivis | **4** (.bak) |

Fichiers modifies (contiennent les fixes Amazon tracking + compat) :
```
src/modules/ai/ai-policy-debug-routes.ts
src/modules/compat/routes.ts         ← fix Amazon status (PH-AMZ-TRACKING-PROD-TRUTH-FIX-03)
src/modules/orders/routes.ts         ← fix tracking v2026-01-01 (PH-AMZ-TRACKING-PROD-TRUTH-FIX-03)
```

Fichiers .bak (pollution) :
```
src/modules/ai/ai-policy-debug-routes.ts.bak.pre-ph116-fix
src/modules/compat/routes.ts.bak-ph03
src/modules/compat/routes.ts.bak-ph04
src/modules/orders/routes.ts.bak-ph03
```

---

## 7. AUDIT BASTION CONTAMINATION

### Le bastion peut-il contaminer un build ?

**OUI — par le mecanisme suivant :**

```
Dockerfile: COPY app ./app     ← copie les 23 fichiers dirty de app/
Dockerfile: COPY src ./src     ← copie les 23 fichiers dirty de src/
```

Meme avec le Dockerfile PH-TD-08 (explicit COPY au lieu de COPY . .), les COPY ciblent des repertoires entiers (`app/`, `src/`) qui contiennent les fichiers dirty.

Le SEUL moyen d'eviter la contamination est `build-from-git.sh` qui clone dans `/tmp/` depuis GitHub.

### Est-ce que `build-from-git.sh` est reellement utilise ?

**NON.** Tous les builds observes (PH117 a PH120) ont ete faits via `docker build` direct sur le bastion, depuis le working directory dirty.

Preuve : l'image v3.5.77 contient du code qui n'existe PAS sur GitHub (PH119 routeAccessGuard, Amazon fixes, etc.), donc elle n'a pas ete construite depuis un clone GitHub.

---

## 8. AUDIT PIPELINE SAFE REEL

| Element | Existe ? | Utilise ? | Bloquant ? |
|---------|----------|-----------|------------|
| `build-from-git.sh` | OUI | **NON** | N/A |
| `verify-image-clean.sh` | OUI | **NON** | N/A |
| `frontend-release-gate.sh` | OUI | **NON** | N/A (gate inverse) |
| Dirty check dans Dockerfile | NON | N/A | N/A |
| ArgoCD auto-sync | Desactive | N/A | N/A |

**Pipeline safe PH-TD-08 : DOCUMENTE mais JAMAIS APPLIQUE.**

---

## 9. VERDICT DE REPRODUCTIBILITE

**NON REPRODUCTIBLE.**

Un rebuild depuis GitHub (via `build-from-git.sh` ou tout autre clone) produirait une image **catastrophiquement differente** de l'image saine actuelle. Il manquerait :

- PH-ONBOARDING-PLAN-STATE-CONTINUITY-01
- PH117-REBUILD-CLEAN-01 + PH117-DESIGN-ALIGNMENT-02
- PH118 onboarding hardening
- PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02
- PH119 role access guard (fichier `routeAccessGuard.ts` non-suivi)
- Tous les fixes Amazon (orders, compat, tracking)
- Tous les changements PH120 (useTenantId, AIModeSwitch, etc.)
- Corrections settings types/constants/utils
- Corrections playbooks service

---

## 10. BASELINE SAINE A GELER

| Env | Service | Image | Statut |
|-----|---------|-------|--------|
| DEV | Client | `v3.5.77-ph119-role-access-guard-dev` | REFERENCE |
| PROD | Client | `v3.5.77-ph119-role-access-guard-prod` | REFERENCE |
| DEV | API | `v3.5.49-amz-orders-list-sync-fix-dev` | REFERENCE |
| PROD | API | `v3.5.49-amz-orders-list-sync-fix-prod` | REFERENCE |
| DEV | Backend | `v1.0.40-amz-tracking-visibility-backfill-dev` | REFERENCE |
| PROD | Backend | `v1.0.40-amz-tracking-visibility-backfill-prod` | REFERENCE |

Ces images sont IMMUABLES dans GHCR. Le runtime est sain TANT QU'on ne rebuild pas.

---

## 11. PLAN MINIMAL DE REPARATION

### OBLIGATOIRE (avant tout nouveau build)

| # | Action | Cible | Pourquoi |
|---|--------|-------|----------|
| FIX-1 | **Push les 5 commits locaux** client | `fix/signup-redirect-v2` → GitHub | 5 commits de phases entieres absents de GitHub |
| FIX-2 | **Commit + push les 23 fichiers modifies** client | Git | Le code de l'image saine n'est nulle part dans Git |
| FIX-3 | **Commit + push le fichier non-suivi** `routeAccessGuard.ts` | Git | PH119 est incomplete sans ce fichier |
| FIX-4 | **Commit + push les 2 manifests infra** (probes) | Git infra | ArgoCD OutOfSync |
| FIX-5 | **Commit + push les 3 fichiers API** modifies | Git API | Amazon fixes absents de Git |
| FIX-6 | **Nettoyer les .bak** API | bastion | Pollution |
| FIX-7 | **Verifier** qu'un `build-from-git.sh` compile OK | bastion | Prouver la reproductibilite |
| FIX-8 | **Interdire** `docker build` direct | process | Seul `build-from-git.sh` autorise |

### Ordre d'execution

```
1. Push commits client (FIX-1)
2. Commit + push dirty files client (FIX-2 + FIX-3)
3. Commit + push dirty files infra (FIX-4)
4. Commit + push dirty files API (FIX-5)
5. Nettoyer .bak (FIX-6)
6. Test build-from-git.sh (FIX-7)
7. Documenter interdiction (FIX-8)
```

---

## 12. DECISION

### Source de verite actuelle

| Composant | Etat |
|-----------|------|
| Runtime | SAIN |
| Git client | **BROKEN** (code sain absent) |
| Git infra | **PARTIEL** (manifests drift) |
| Git API | **PARTIEL** (fixes absent) |
| Bastion | **DIRTY** (contamination active) |
| Pipeline | **NON APPLIQUE** |

---

## VERDICT FINAL

# SOURCE OF TRUTH BROKEN — RECOVERY REQUIRED BEFORE ANY NEW BUILD

Le runtime est sain et fonctionnel. Mais la chaine de verite (Git → build → deploy) est cassee :
- Le code source sur GitHub ne correspond PAS a l'image deployee
- Un rebuild depuis GitHub produirait une image radicalement differente
- Le pipeline safe existe mais n'est jamais utilise
- Le bastion est toujours un vecteur de contamination actif

**Aucun nouveau build ne doit etre lance avant :**
1. Synchronisation complete Git ← bastion (commits + push)
2. Verification de reproductibilite via `build-from-git.sh`
3. Application effective du pipeline safe

---

> **STOP POINT** — Aucune modification runtime. Ce rapport constitue la verite technique absolue sur l'etat de la chaine de deploiement.
