# PH-BILLING-ROLLBACK-01 — Rapport de Rollback

> Date : 2026-03-01
> Decisionnaire : Utilisateur (rejet PH-BILLING-DEV-E2E-VALIDATION-01)
> Executant : Agent Cursor
> Impact : DEV uniquement — PROD intacte

---

## 1. Raison du Rollback

La phase PH-BILLING-DEV-E2E-VALIDATION-01 est **REJETEE** pour les raisons suivantes :

1. Melange corrections billing et nettoyage massif hors scope
2. Suppression / exclusion d'un volume important de fichiers sans validation prealable
3. Reecriture de pages entieres au lieu de corrections progressives
4. Conclusion prematuree "ready for manual test" sans maitrise du perimetre reel
5. Transformation d'une phase de reparation ciblee en refonte implicite

---

## 2. Ce qui a ete Reverte

### 2.1 Git Applicatif (keybuzz-client)

| Commit reverte | Description |
|---|---|
| `8ca1d3d` | PH-BILLING-REPAIR-01: 10 corrections billing (label, guard, packs, plan change, popup, invoices, TenantProvider, 2 BFF routes) |
| `cf59fc8` | PH-BILLING-DEV-BUILD: suppression 27 fichiers .tsx racine + tsconfig |
| `5a05c0b` | PH-BILLING-DEV-BUILD-02: suppression 63 fichiers .ts racine + tsconfig |
| `75b36c2` | PH-BILLING-DEV-BUILD-03: creation .dockerignore + tsconfig |
| `39e7e71` | PH-BILLING-DEV-BUILD-04: fix .dockerignore scripts |
| `f43641c` | PH-BILLING-DEV-BUILD-05: .dockerignore complet + tsconfig |
| `d8ededb` | PH-BILLING-DEV-BUILD-06: suppression src/main.ts |
| `519f589` | PH-BILLING-DEV-BUILD-07: suppression src/modules/tenants/tenants.types.ts |
| `8bb2829` | PH-BILLING-DEV-BUILD-08: exclusion *.md du docker context |
| `ce4bf6e` | PH-BILLING-DEV-BUILD-09: exclusion *.ts racine du docker context |

**Commit de revert** : `672d261` — revert unique couvrant les 10 commits
**Push** : `ce4bf6e..672d261 main -> main`

### 2.2 Deploiement K8s DEV

| Element | Avant rollback | Apres rollback |
|---|---|---|
| Image | `v3.5.49-billing-repair-dev` | `v3.5.100-ph131-fix-kbactions-dev` |
| Pod | keybuzz-client-6c8446d8b5-xxxxx | keybuzz-client-5d646869f6-77tsb |
| Status | 1/1 Running | 1/1 Running |
| Restarts | 0 | 0 |

### 2.3 GitOps (keybuzz-infra)

| Element | Avant rollback | Apres rollback |
|---|---|---|
| Commit billing | `a09c425` (image v3.5.49-billing-repair-dev) | Reverte par `fe04efb` |
| Image dans deployment.yaml | `v3.5.49-billing-repair-dev` | `v3.5.100-ph131-fix-kbactions-dev` |

**Note** : Un drift pre-existant a ete corrige dans le meme commit. Le GitOps referentiait `v3.5.94-ph125-agent-queue-dev` mais le live avait `v3.5.100-ph131-fix-kbactions-dev`. Le rollback a aligne le GitOps sur la verite live.

---

## 3. PROD — Aucun Impact

| Verification | Resultat |
|---|---|
| Image PROD | `v3.5.100-ph131-fix-kbactions-prod` (inchangee) |
| Pod PROD | 1/1 Running, 0 restarts, age 4h31m |
| GitOps PROD | Non touche |

---

## 4. Verifications Post-Rollback

| Check | Resultat |
|---|---|
| Pod DEV healthy | 1/1 Running, 0 restarts |
| Image DEV correcte | `v3.5.100-ph131-fix-kbactions-dev` |
| Next.js running | Ready in 398ms |
| `/login` accessible | HTTP 200 |
| `/billing` accessible | HTTP 200 (redirect auth, attendu) |
| Ingress DEV | `client-dev.keybuzz.io` OK |
| Drift Git/Live | **AUCUN** (aligne) |
| PROD intacte | Confirmee |

---

## 5. Fichiers Restaures par le Revert

Le revert `672d261` a restaure l'etat exact pre-billing :
- **90+ fichiers temporaires racine** (.ts, .tsx) : restaures dans Git (etaient supprimes par le chantier billing)
- **`.dockerignore`** : supprime (n'existait pas avant le chantier)
- **`tsconfig.json`** : restaure a l'etat pre-billing (sans les exclusions massives)
- **`src/main.ts`** : restaure (fichier backend mal place, mais present avant)
- **`src/modules/tenants/tenants.types.ts`** : restaure (idem)
- **`app/api/billing/change-plan/route.ts`** : supprime (n'existait pas avant)
- **`app/api/billing/invoices/route.ts`** : supprime (n'existait pas avant)
- **Pages billing** (plan, history, ai, manage, ai-actions-checkout) : restaurees a leur etat pre-chantier
- **`src/features/billing/useCurrentPlan.tsx`** : restaure

---

## 6. Drift Residuel Connu

| Element | Etat | Risque |
|---|---|---|
| Rapport billing dans keybuzz-infra (`docs/PH-BILLING-DEV-E2E-VALIDATION-01-REPORT.md`) | Present mais inoffensif (doc) | Aucun |
| Commit `2fd35ff` (rapport billing dans infra) | Existe dans l'historique | Aucun impact fonctionnel |
| Scripts billing locaux (`scripts/ph-billing-*.sh`) | Non trackes dans Git | Aucun impact, a nettoyer |

---

## 7. Verdict

### **DEV ROLLED BACK SUCCESSFULLY**

L'environnement DEV est revenu a l'etat exact pre-chantier billing :
- Git applicatif : aligné sur `3b0d99b` (via revert `672d261`)
- Deploiement K8s : image `v3.5.100-ph131-fix-kbactions-dev`
- GitOps : aligne, drift corrige
- PROD : intacte, confirmee

---

## 8. Plan de Reprise Incremental (a valider AVANT execution)

### Principes

1. **1 bug = 1 mini-phase** — correction unique, ciblee, testee
2. **Aucun nettoyage hors scope** — pas de suppression de fichiers temporaires, pas de refonte tsconfig, pas de creation .dockerignore
3. **Aucune reecriture globale** — on corrige le minimum vital dans les fichiers existants
4. **Chaque correction testee individuellement** — build local OU validation visuelle, pas de deploiement groupe
5. **Aucun deploiement tant que le bug precedent n'est pas valide**
6. **Approbation explicite avant chaque deploiement**

### Bugs billing identifies (a traiter un par un)

| # | Bug | Fichier(s) | Correction estimee |
|---|---|---|---|
| B1 | Compteur canaux affiche `0/3` au lieu de `1/3` | `useCurrentPlan.tsx` | Fix `tenantId` canonical vs display (~5 lignes) |
| B2 | Bouton "Acheter des KBActions" desactive sur `/billing/ai/manage` | `app/billing/ai/manage/page.tsx` | Remplacer bouton disabled par lien actif (~3 lignes) |
| B3 | Label KBActions incorrect sur `/billing/ai` | `app/billing/ai/page.tsx` | Corriger le libelle du bouton (~1 ligne) |
| B4 | Guard 403 bloquant sur `ai-actions-checkout` | `app/api/billing/ai-actions-checkout/route.ts` | Retirer la condition bloquante (~5 lignes) |
| B5 | Historique factures avec donnees mock | `app/billing/history/page.tsx` | Connexion a l'API reelle (necessite route backend existante) |
| B6 | Plan change dialog absent | `app/billing/plan/page.tsx` | Ajout modal changement plan (necessite route BFF) |
| B7 | Popup dissuasive annulation absente | `app/billing/plan/page.tsx` | Ajout popup (apres B6) |

### Ordre de traitement recommande

1. **B1** (compteur canaux) — impact visuel immediat, correction la plus simple et la plus isolee
2. **B3** (label KBActions) — 1 ligne, zero risque
3. **B4** (guard 403) — correction API, pas d'impact UI
4. **B2** (bouton KBActions manage) — correction UI simple
5. **B5** (historique factures) — necessite verification de l'endpoint backend
6. **B6** (plan change) — necessite route BFF, plus complexe
7. **B7** (popup annulation) — depend de B6

### Methode par mini-phase

Pour chaque bug Bx :
1. Lire le fichier concerne
2. Identifier la correction minimale
3. Appliquer UNIQUEMENT cette correction
4. Commiter avec message `PH-BILLING-FIX-Bx: <description>`
5. Presenter le diff au user pour validation
6. Si valide : deployer en DEV
7. Tester en DEV
8. Passer a Bx+1

### Ce qui NE sera PAS fait dans cette reprise

- Aucune suppression de fichiers temporaires racine
- Aucune creation de `.dockerignore`
- Aucune modification de `tsconfig.json`
- Aucune creation de nouvelles routes BFF (sauf si strictement necessaire pour un bug)
- Aucun nettoyage de dette technique hors scope billing
- Aucune refonte de page
