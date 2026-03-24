# ROLLBACK-PH122-ESCALATION-FOUNDATION-01 — Rapport

**Date** : 24 mars 2026
**Phase** : ROLLBACK-PH122-ESCALATION-FOUNDATION-01
**Type** : rollback immediat client
**Verdict** : PH122 ROLLBACK COMPLETED — BASELINE RESTORED

---

## 1. Cause du rollback

Le product owner constate en usage reel apres PH122 :
- Messages non affiches correctement dans l'inbox
- Features fournisseurs perdues
- Regression fonctionnelle visible

Le rapport PH122 ne peut pas etre considere comme valide fonctionnellement.

## 2. Images avant rollback

| Env | Image |
|---|---|
| DEV | `v3.5.88-ph122-escalation-dev` |
| PROD | `v3.5.88-ph122-escalation-prod` |

## 3. Images apres rollback

| Env | Image |
|---|---|
| DEV | `v3.5.87-ph121-role-agent-dev` |
| PROD | `v3.5.87-ph121-role-agent-prod` |

## 4. Validation DEV

| Page | HTTP | Statut |
|---|---|---|
| / | 200 | OK |
| /login | 200 | OK |
| /dashboard | 200 | OK |
| /inbox | 200 | OK |
| /orders | 200 | OK |
| /ai-dashboard | 200 | OK |

**ROLLBACK PH122 DEV = OK**

## 5. Validation PROD

| Page | HTTP | Statut |
|---|---|---|
| / | 200 | OK |
| /login | 200 | OK |
| /dashboard | 200 | OK |
| /inbox | 200 | OK |
| /orders | 200 | OK |
| /ai-dashboard | 200 | OK |

**ROLLBACK PH122 PROD = OK**

## 6. Verification menage bastion

| Element | Statut |
|---|---|
| Images PH121 DEV/PROD sur bastion | Presentes |
| Images PH121 sur GHCR | Pullables (OK) |
| Scripts pipeline safe (build-from-git.sh, verify-image-clean.sh) | Intacts |
| Repo client Git | OK (commits PH121+PH122 presents) |
| Repo infra Git | OK (commit rollback pousse) |

**Cleanup bastion sans impact** : seuls les repertoires temporaires `/tmp/keybuzz-client-build-*` et des images Docker intermediaires anciennes ont ete supprimes. Aucun script, aucune image de reference, aucun artifact critique n'a ete touche.

## 7. API / Backend

Aucune modification API ou backend pendant PH122 — pas de rollback necessaire.

## 8. Verdict

### PH122 ROLLBACK COMPLETED — BASELINE RESTORED

DEV et PROD sont revenus a PH121 (`v3.5.87`).
Les images sont intactes sur le bastion et sur GHCR.
Le menage bastion n'a eu aucun impact sur les artifacts critiques.
