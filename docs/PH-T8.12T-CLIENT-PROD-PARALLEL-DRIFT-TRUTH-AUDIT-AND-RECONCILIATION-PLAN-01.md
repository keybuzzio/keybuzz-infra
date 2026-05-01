# PH-T8.12T — Client PROD Parallel Drift Truth Audit and Reconciliation Plan

**Phase** : PH-T8.12T-CLIENT-PROD-PARALLEL-DRIFT-TRUTH-AUDIT-AND-RECONCILIATION-PLAN-01
**Date** : 2026-05-01
**Environnement** : PROD (audit uniquement, aucun build/deploy)
**Type** : audit verite + plan de reconciliation
**Priorite** : P0

---

## Objectif

Diagnostiquer le drift cause par deux flux paralleles sur `keybuzz-client-prod` et produire un plan de reconciliation sur.

Deux lignees Client PROD se sont croisees :

1. **Lignee Tracking** (`ph-t812p/tiktok-browser-pixel` + `ph-t812s/meta-pixel-dedup-safe`)
   - `v3.5.144-tiktok-browser-pixel-prod`
   - `v3.5.145-client-ga4-sgtm-parity-prod`
   - `v3.5.146-client-meta-pixel-dedup-safe-prod`

2. **Lignee SaaS Sample Demo** (`ph148/onboarding-activation-replay`)
   - `v3.5.146-sample-demo-platform-aware-prod`

Le runtime actuel (`v3.5.146-sample-demo-platform-aware-prod`) a ecrase l'image tracking complete.

## Sources relues

- `AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `AI_MEMORY/RULES_AND_RISKS.md`
- `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md`
- `PH-T8.12R-CLIENT-GA4-SGTM-PARITY-AND-TRACKING-DOC-RECONCILIATION-01.md`
- `PH-T8.12S-META-CLIENT-PIXEL-DEDUP-READINESS-AND-SAFE-ACTIVATION-01.md`
- `PH-SAAS-T8.12R.1-SAMPLE-DEMO-PLATFORM-AWARE-PROD-PROMOTION-01.md`
- `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml`

---

## Freeze Client PROD

| Element | Valeur |
|---|---|
| Runtime actuel | `ghcr.io/keybuzzio/keybuzz-client:v3.5.146-sample-demo-platform-aware-prod` |
| Dernier commit manifest | `7be510f` |
| Rollout | successfully rolled out, 1/1 Running, 0 restarts |
| Freeze confirme | OUI |

---

## Cartographie des images

### Images et sources

| Image | Phase | Source commit | Branche source | Digest |
|---|---|---|---|---|
| `v3.5.144-tiktok-browser-pixel-prod` | PH-T8.12P | `3325f03` | `ph-t812p/tiktok-browser-pixel` | non disponible localement |
| `v3.5.145-client-ga4-sgtm-parity-prod` | PH-T8.12R | `3325f03` | `ph-t812p/tiktok-browser-pixel` | `sha256:9239525e6ee33210fd4e360a786b9190301e9122c53cc886e77f39cf1a6df9f4` |
| `v3.5.146-client-meta-pixel-dedup-safe-prod` | PH-T8.12S | `5840a18` (base `3325f03`) | `ph-t812s/meta-pixel-dedup-safe` | `sha256:ba90a78457c1c2fed92d392be840958f60871890670bc2830ba3af126034c3fa` |
| `v3.5.146-sample-demo-platform-aware-prod` | PH-SAAS-T8.12R.1 | `3d858a8` | `ph148/onboarding-activation-replay` | `sha256:c08e95ecfbdb6a63457a13e63c625f3684b18bf85b1e4787efdbb3ed0c455989` |

### Build args par image

| Image | GA4 | sGTM | TikTok | LinkedIn | Meta |
|---|---|---|---|---|---|
| `v3.5.145-client-ga4-sgtm-parity-prod` | `G-R3QQDYEBFG` | `https://t.keybuzz.pro` | `D7PT12JC77U44OJIPC10` | `9969977` | NON PASSE |
| `v3.5.146-client-meta-pixel-dedup-safe-prod` | `G-R3QQDYEBFG` | `https://t.keybuzz.pro` | `D7PT12JC77U44OJIPC10` | `9969977` | `1234164602194748` |
| `v3.5.146-sample-demo-platform-aware-prod` | **VIDE** | **VIDE** | **VIDE** | `9969977` (Dockerfile default) | **VIDE** |

### Fonctions par image

| Image | SaaS Demo platform-aware | GA4 | sGTM | TikTok | LinkedIn | Meta | CompletePayment removed | Purchase removed |
|---|---|---|---|---|---|---|---|---|
| `v3.5.145-client-ga4-sgtm-parity-prod` | Pre platform-aware | OK | OK | OK | OK | - | OK | Non |
| `v3.5.146-client-meta-pixel-dedup-safe-prod` | Pre platform-aware | OK | OK | OK | OK | OK | OK | OK |
| `v3.5.146-sample-demo-platform-aware-prod` | **OK** | **ABSENT** | **ABSENT** | **ABSENT** | OK | **ABSENT** | **Non** | **Non** |

---

## Cause racine du drift

Le build `v3.5.146-sample-demo-platform-aware-prod` (script `build_client_prod_t812r1.sh`) n'a passe que 3 build args :

```
--build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io
--build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io
--build-arg NEXT_PUBLIC_APP_ENV=production
```

Les build args tracking (GA4, sGTM, TikTok, Meta) etaient **absents**. Le Dockerfile definit ces variables avec des valeurs **vides par defaut** (sauf LinkedIn `9969977`). Resultat : le tracking est effectivement mort dans le runtime actuel (sauf LinkedIn).

De plus, la branche source `ph148/onboarding-activation-replay` diverge de `ph-t812p/tiktok-browser-pixel` depuis le merge-base `f6ae911`. Les patchs de suppression `CompletePayment` (TikTok) et `Purchase` (Meta) browser ne sont pas dans `ph148`.

---

## Comparaison des sources

### Arbre de divergence

```
f6ae911 (merge-base: seller-first alignment)
├── ph-t812p/tiktok-browser-pixel → 3325f03 (+1 commit: tracking.ts CompletePayment removal)
└── ph148/onboarding-activation-replay → 3d858a8 (+3 commits: demo platform-aware)
```

### Fichiers modifies par branche (depuis merge-base)

| Fichier | Tracking (`ph-t812p`) | SaaS (`ph148`) | Conflit | Decision |
|---|---|---|---|---|
| `src/lib/tracking.ts` | CompletePayment supprime | Inchange | **Aucun** | Merge auto |
| `src/features/demo/DemoBanner.tsx` | - | `onConnect` + texte generalise | **Aucun** | Aucune action |
| `src/features/demo/DemoDashboardPreview.tsx` | - | `onConnect` + texte | **Aucun** | Aucune action |
| `src/features/demo/DemoInboxExperience.tsx` | - | `onConnect` + texte | **Aucun** | Aucune action |
| `src/features/demo/sampleData.ts` | - | Multi-canal | **Aucun** | Aucune action |
| `keybuzz-client/src/features/demo/*` (7) | - | Fichiers parasites monorepo | **Aucun** | Nettoyer |
| `src/components/tracking/SaaSAnalytics.tsx` | Identique | Identique | **Aucun** | Aucune action |
| `Dockerfile` | Identique | Identique | **Aucun** | Aucune action |

### Test merge

```
git merge --no-commit --no-ff origin/ph-t812p/tiktok-browser-pixel
Automatic merge went well; stopped before committing as requested
```

**0 conflit.**

### Patch supplementaire requis

La branche `ph-t812s/meta-pixel-dedup-safe` n'existe pas sur le remote du bastion. Le commit `5840a18` est introuvable. Le patch de suppression Meta `Purchase` browser doit etre reapplique manuellement :

```diff
- trackMeta('Purchase', {
-   content_name: `KeyBuzz ${params.plan}`,
-   currency: 'EUR',
-   value: params.value,
-   content_type: 'product',
- });
+ // PH-T8.12S: Meta Purchase removed from browser — server-side only via CAPI
+ // event_id mismatch prevents deduplication — double counting risk eliminated
```

---

## Audit bundle runtime actuel

| Signal | Present runtime | Attendu cible | Verdict |
|---|---|---|---|
| GA4 `G-R3QQDYEBFG` | **ABSENT** | Present | PERDU — build arg non passe |
| sGTM `https://t.keybuzz.pro` | **ABSENT effectif** | Present | PERDU — build arg non passe |
| TikTok `D7PT12JC77U44OJIPC10` | **ABSENT** | Present | PERDU — build arg non passe |
| Meta `1234164602194748` | **ABSENT** | Present | PERDU — build arg non passe |
| LinkedIn `9969977` | **PRESENT** | Present | OK — default Dockerfile |
| `connect.facebook.net` | **ABSENT** | Present | PERDU |
| `analytics.tiktok.com` | **ABSENT** | Present | PERDU |
| `snap.licdn.com` | **PRESENT** | Present | OK |
| `CompletePayment` browser | **PRESENT** (code mort) | **ABSENT** | Regression code (inoffensif car ID vide) |
| Meta `Purchase` browser | **PRESENT** (code mort) | **ABSENT** | Regression code (inoffensif car ID vide) |
| Pages protegees sans tracking | OK | OK | OK |

**ATTENTION** : `CompletePayment` et `Purchase` sont du code mort actuellement (IDs vides), mais deviendraient **actifs et dangereux** si on rebuild avec les build args sans merger les patchs.

---

## Audit Sample Demo

| Fonction SaaS | Presente | Risque reconciliation |
|---|---|---|
| 5 demo conversations | OUI (3 amazon, 1 email, 1 octopia) | Aucun |
| `onConnect` (pas `onConnectAmazon`) | OUI | Aucun |
| "Connecter un canal" generalise | OUI | Aucun |
| `kb_demo_dismissed` tenant-scope | OUI | Aucun |
| 0 DB demo rows | OUI | Aucun |
| 0 billing drift | OUI | Aucun |
| API/Backend/Website inchanges | OUI | Aucun |

---

## Matrice de reconciliation

### Image cible

`ghcr.io/keybuzzio/keybuzz-client:v3.5.147-sample-demo-platform-aware-tracking-parity-prod`

Interdiction de reutiliser un tag `v3.5.146`.

### Construction

| Etape | Action | Source |
|---|---|---|
| 1 | Base : checkout `ph148/onboarding-activation-replay` @ `3d858a8` | Branche SaaS |
| 2 | Merge : `origin/ph-t812p/tiktok-browser-pixel` @ `3325f03` | Branche Tracking |
| 3 | Patch : supprimer Meta `Purchase` browser dans `tracking.ts` | Manuel (equiv. `5840a18`) |
| 4 | Nettoyer : supprimer dossier parasite `keybuzz-client/` | Hygiene monorepo |
| 5 | Build avec 8 build args complets | Docker `--no-cache` |

### Build args obligatoires

```bash
--build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io
--build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io
--build-arg NEXT_PUBLIC_APP_ENV=production
--build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG
--build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro
--build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10
--build-arg NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977
--build-arg NEXT_PUBLIC_META_PIXEL_ID=1234164602194748
```

### Exigences de la cible

| Exigence | Source | Action |
|---|---|---|
| Demo 5 conv multi-canal | ph148 | Aucune (base) |
| `onConnect` generalise | ph148 | Aucune (base) |
| 0 refund-first | ph148 | Aucune (base) |
| GA4 actif | Build arg | Passer `G-R3QQDYEBFG` |
| sGTM actif | Build arg | Passer `https://t.keybuzz.pro` |
| TikTok actif | Build arg | Passer `D7PT12JC77U44OJIPC10` |
| LinkedIn actif | Dockerfile default | Passer explicitement `9969977` |
| Meta Pixel actif | Build arg | Passer `1234164602194748` |
| TikTok CompletePayment browser ABSENT | Merge ph-t812p | Merger |
| Meta Purchase browser ABSENT | Patch manuel | Modifier tracking.ts |
| Pages protegees sans tracking | SaaSAnalytics.tsx | Aucune (identique) |

---

## Risques

| Risque | Probabilite | Impact | Mitigation |
|---|---|---|---|
| Conflit merge | Nul | - | Test valide |
| Patch Meta mal applique | Faible | Double Purchase | Verifier bundle post-build |
| Build args oublies (repete T8.12R.1) | Moyen | Tracking perdu encore | Script avec TOUS les args + checklist |
| Fichiers parasites monorepo | Faible | Aucun (Docker context) | Nettoyer avant commit |

---

## Interdits respectes

- Aucun build effectue
- Aucun deploy effectue
- Aucun GitOps apply
- Aucun rollback
- Aucune modification API/DB/billing
- Aucun faux event
- Aucun secret expose
- Bastion `install-v3` / `46.62.171.61` uniquement

---

## Plan build futur (prochaine phase)

1. SSH bastion `install-v3`
2. Clone temporaire propre de `ph148/onboarding-activation-replay`
3. Merge `origin/ph-t812p/tiktok-browser-pixel`
4. Appliquer patch Meta Purchase removal
5. Supprimer dossier parasite `keybuzz-client/`
6. Commit + push
7. Docker build `--no-cache` avec 8 build args
8. Docker push
9. Documenter digest
10. GitOps : modifier manifest PROD, commit, push, apply, rollout status
11. Validation bundle : verifier les 8 signaux tracking + demo
12. Validation tenant reel : pas de demo
13. Non-pollution : 0 DB demo, 0 billing, 0 CAPI
14. Rapport final

---

## Verdict

**GO RECONCILE BUILD NEXT**

**CLIENT PROD PARALLEL DRIFT ROOT CAUSE IDENTIFIED — SAMPLE DEMO IMAGE OVERWROTE TRACKING IMAGE — RECONCILIATION TARGET DEFINED — NO BUILD — NO DEPLOY — READY FOR SINGLE COMBINED BUILD**

### Root cause

Le build PH-SAAS-T8.12R.1 (`v3.5.146-sample-demo-platform-aware-prod`) a ete construit depuis la branche `ph148` sans les build args tracking. La branche `ph148` diverge de `ph-t812p` (tracking) et ne contient pas les patchs de securite CompletePayment/Purchase. Le resultat : une image qui preserve la fonction SaaS demo platform-aware mais perd tout le tracking sauf LinkedIn.

### Cible reconciliation

`v3.5.147-sample-demo-platform-aware-tracking-parity-prod` : merge `ph148` + `ph-t812p` + patch Meta Purchase + 8 build args complets.

---

**Chemin du rapport** : `keybuzz-infra/docs/PH-T8.12T-CLIENT-PROD-PARALLEL-DRIFT-TRUTH-AUDIT-AND-RECONCILIATION-PLAN-01.md`
