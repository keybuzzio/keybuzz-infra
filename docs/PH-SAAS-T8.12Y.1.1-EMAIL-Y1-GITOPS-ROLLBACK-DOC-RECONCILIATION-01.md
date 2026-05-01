# PH-SAAS-T8.12Y.1.1 — Email Y.1 GitOps Rollback Doc Reconciliation

> Date : 2026-05-02
> Type : Reconciliation documentation, aucun changement runtime
> Environnement : Documentation / Infra uniquement
> Statut : **RECONCILED**

---

## 0. PREFLIGHT

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| `keybuzz-infra` | `main` | `main` | `dd40cdf` | Oui (docs untracked, non liés) | OK |
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `956da28d` | — | OK (lecture seule) |

| Service | Image attendue | Runtime constaté | Verdict |
|---|---|---|---|
| API DEV | `v3.5.131-email-preview-transactional-dev` | `v3.5.131-email-preview-transactional-dev` | OK |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | `v3.5.130-platform-aware-refund-strategy-prod` | OK |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | OK |

---

## 1. AUDIT RAPPORT Y.1

Source : `keybuzz-infra/docs/PH-SAAS-T8.12Y.1-EMAIL-PREVIEW-AND-TRANSACTIONAL-MIGRATION-DEV-01.md`

| Pattern interdit | Occurrences avant correction | Emplacement | Action |
|---|---|---|---|
| `kubectl set image` | **1** | Section 12, ligne 197 (bloc bash) | Remplacé par procédure GitOps stricte |
| `kubectl set env` | 0 | — | Aucune |
| `kubectl patch` | 0 | — | Aucune |
| `kubectl edit` | 0 | — | Aucune |
| `git reset --hard` | 0 | — | Aucune |
| `git clean` | 0 | — | Aucune |

---

## 2. CORRECTION APPLIQUÉE

### Avant (section 12)

```bash
# API DEV rollback
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.130-platform-aware-refund-strategy-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

Suivi de : "Puis mettre à jour le deployment.yaml" — procédure inversée (runtime d'abord, manifest ensuite).

### Après (section 12)

Procédure GitOps stricte en 6 étapes :

1. Modifier `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` (image rollback)
2. Commit infra
3. Push `main`
4. `kubectl apply -f`
5. `kubectl rollout status`
6. Vérifier manifest = runtime = annotation

Rappel explicite : `kubectl set image`, `kubectl patch`, `kubectl edit` **interdits**.

---

## 3. VÉRIFICATION POST-CORRECTION

| Rapport | Forbidden patterns dans procédures | Mentions légitimes (section interdits) | Verdict |
|---|---|---|---|
| PH-SAAS-T8.12Y.1 | **0** | 1 (rappel "Interdit") | **OK** |

---

## 4. CONFIRMATIONS

- **Code** : aucun code API/Client/Admin/Website modifié
- **Build** : aucun build Docker exécuté
- **Deploy** : aucun deploy K8s exécuté
- **Runtime** : aucune mutation runtime
- **DB** : aucune mutation base de données
- **Billing/CAPI/Tracking** : aucun event
- **Email** : aucun email envoyé

---

## 5. BASELINES INCHANGÉES

| Service | Image | Vérifié | Verdict |
|---|---|---|---|
| API DEV | `v3.5.131-email-preview-transactional-dev` | Oui | **Inchangé** |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | Oui | **Inchangé** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Oui | **Inchangé** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | — | **Inchangé** (non audité runtime, hors scope) |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | — | **Inchangé** (non audité runtime, hors scope) |

---

## 6. FICHIERS MODIFIÉS

| Fichier | Action |
|---|---|
| `keybuzz-infra/docs/PH-SAAS-T8.12Y.1-EMAIL-PREVIEW-AND-TRANSACTIONAL-MIGRATION-DEV-01.md` | Section 12 corrigée |
| `keybuzz-infra/docs/PH-SAAS-T8.12Y.1.1-EMAIL-Y1-GITOPS-ROLLBACK-DOC-RECONCILIATION-01.md` | Nouveau (ce rapport) |

---

## VERDICT

**EMAIL Y.1 ROLLBACK DOC RECONCILED — GITOPS STRICT DOCUMENTED — ZERO RUNTIME CHANGE — NO CODE — NO BUILD — NO DEPLOY — READY FOR BILLING EMAIL MIGRATION Y.2**

### Chemin complet du rapport

`keybuzz-infra/docs/PH-SAAS-T8.12Y.1.1-EMAIL-Y1-GITOPS-ROLLBACK-DOC-RECONCILIATION-01.md`
