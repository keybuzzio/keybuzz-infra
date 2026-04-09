# PH-ROLLBACK-METADATA-TRUTH-01 — Rapport

**Date** : 26 mars 2026
**Phase** : PH-ROLLBACK-METADATA-TRUTH-01
**Type** : correction documentaire et operationnelle — aucun deploiement
**Verdict** : **ROLLBACK METADATA FIXED AND TRUSTWORTHY**

---

## 1. Perimetre

Audit de la verite de rollback dans les 9 rapports de phase existants. Aucun deploiement, aucun rollback, aucune modification de code applicatif.

---

## 2. Methode

Croisement de 3 sources :

| Source | Commande / Outil |
|---|---|
| **Images live K8s** | `kubectl get deployment -o jsonpath` sur DEV + PROD |
| **Cache Docker bastion** | `docker images ghcr.io/keybuzzio/*` avec timestamps |
| **Manifests GitOps** | `keybuzz-infra/k8s/*/deployment.yaml` |

---

## 3. Rapports audites (9)

| # | Rapport | Rollback indique | Rollback correct | Verdict |
|---|---|---|---|---|
| 1 | PH131-C-AUTOPILOT-ENGINE-SAFE-01 | (DEV only, pas de rollback PROD) | N/A | **OK** |
| 2 | PH131-C-PROD-PROMOTION-01 | API `v3.5.104`, Client `v3.5.106` | API `v3.5.104`, Client `v3.5.106` | **OK** |
| 3 | PH-AMZ-INBOUND-ADDRESS-TRUTH-01 | API `v3.5.107b`, Client `v3.5.107` | API `v3.5.107b`, Client `v3.5.107` | **OK** |
| 4 | PH-AMZ-INBOUND-ADDRESS-TRUTH-02 | API `v3.5.108`, Client `v3.5.108` | API `v3.5.108`, Client `v3.5.108` | **OK** |
| 5 | PH-AMZ-MULTI-COUNTRY-TRUTH-03 | API `v3.5.109` (PROD only) | API `v3.5.109` | **OK** (DEV manquant) |
| 6 | **PH-BILLING-PLAN-TRUTH-RECOVERY-01** | API `v3.5.108-ph-amz-inbound-address` | API **`v3.5.110-ph-amz-multi-country`** | **FAUX — CORRIGE** |
| 7 | PH-BILLING-PLAN-TRUTH-RECOVERY-02 | Client `v3.5.109` | Client `v3.5.109` | **OK** |
| 8 | PH-BILLING-TRIAL-BANNER-AND-PLAN-CHANGE-01 | Client `v3.5.112` | Client `v3.5.112` | **OK** |
| 9 | **PH-AMZ-CONNECTOR-FALSE-CONNECTED-TRUTH-04** | API `v3.5.47-vault-tls-fix` | API **`v3.5.111-ph-billing-truth`** | **FAUX — CORRIGE** |

---

## 4. Rapport faux #1 — TRUTH-04 (CRITIQUE)

**Probleme** : la section rollback du rapport PH-AMZ-CONNECTOR-FALSE-CONNECTED-TRUTH-04 pointait vers `v3.5.47-vault-tls-fix-dev/prod`.

**Pourquoi c'est faux** :
- `v3.5.47` est l'image originale d'AVANT toutes les phases du 26 mars 2026
- Cette image n'est PAS presente sur le bastion
- Un rollback vers `v3.5.47` perdrait TOUTES les corrections :
  - Autopilot engine (PH131-C)
  - Amazon inbound (TRUTH-01/02/03)
  - Billing plan truth (channels hardcodes)
  - Billing client PlanProvider fix
  - Trial banner
  - Amazon false connected fix

**Image correcte** : `v3.5.111-ph-billing-truth-dev/prod` — derniere image deployee juste avant TRUTH-04, presente sur le bastion.

**Cause probable** : le tag `v3.5.47` provient du fichier de contexte projet (`keybuzz-v3-context.mdc` section "Versions deployees") qui listait les versions d'avant les phases recentes. L'agent a utilise cette reference au lieu de la chronologie reelle des deploiements.

**Correction** : addendum dans le rapport TRUTH-04 avec le tag correct + note explicative.

---

## 5. Rapport faux #2 — BILLING-PLAN-TRUTH-01 (MAJEUR)

**Probleme** : la section rollback du rapport PH-BILLING-PLAN-TRUTH-RECOVERY-01 pointait vers `v3.5.108-ph-amz-inbound-address-dev/prod`.

**Pourquoi c'est faux** :
- `v3.5.108` est TRUTH-01 (Amazon inbound)
- Deux versions intermediaires ont ete deployees APRES v3.5.108 et AVANT v3.5.111 :
  - `v3.5.109-ph-amz-inbound-truth02` (TRUTH-02)
  - `v3.5.110-ph-amz-multi-country` (TRUTH-03)
- Un rollback vers `v3.5.108` sauterait les corrections TRUTH-02 et TRUTH-03, reintroduisant :
  - Bug ON CONFLICT sur mauvaise contrainte
  - Hardcode FR dans le client
  - Provisioning passif (depend du callback OAuth)
  - Return premature du status endpoint (multi-country casse)

**Image correcte** : `v3.5.110-ph-amz-multi-country-dev/prod` — derniere image deployee juste avant BILLING-01, presente sur le bastion.

**Correction** : addendum dans le rapport BILLING-01 avec le tag correct + note explicative.

---

## 6. Verification des manifests GitOps

| Manifest | Image dans le fichier | Image live K8s | Coherent |
|---|---|---|---|
| `keybuzz-api-dev/deployment.yaml` | `v3.5.115-ph-amz-false-connected-dev` | `v3.5.115-ph-amz-false-connected-dev` | **OK** |
| `keybuzz-api-prod/deployment.yaml` | `v3.5.115-ph-amz-false-connected-prod` | `v3.5.115-ph-amz-false-connected-prod` | **OK** |
| `keybuzz-client-dev/deployment.yaml` | `v3.5.113-ph-trial-plan-fix-dev` | `v3.5.113-ph-trial-plan-fix-dev` | **OK** |
| `keybuzz-client-prod/deployment.yaml` | `v3.5.113-ph-trial-plan-fix-prod` | `v3.5.113-ph-trial-plan-fix-prod` | **OK** |

Les 4 manifests sont alignes avec les images live.

---

## 7. Disponibilite des images rollback sur le bastion

| Tag | Bastion | GHCR | Commentaire |
|---|---|---|---|
| `v3.5.115-ph-amz-false-connected-*` | OUI | OUI | Image actuelle API |
| `v3.5.114-ph-amz-false-connected-dev` | OUI | OUI | **NE JAMAIS UTILISER** — bug enum |
| `v3.5.113-ph-trial-plan-fix-*` | OUI | OUI | Image actuelle client |
| `v3.5.112-ph-billing-truth-02-*` | OUI | OUI | Rollback client safe |
| `v3.5.111-ph-billing-truth-*` | OUI | OUI | Rollback API safe |
| `v3.5.110-ph-amz-multi-country-*` | OUI | OUI | Rollback API n-2 |
| `v3.5.109-ph-amz-inbound-truth02-prod` | OUI (PROD) | OUI | DEV absent bastion |
| `v3.5.108-ph-amz-inbound-address-*` | NON | OUI | Necessite `docker pull` |
| `v3.5.107*` | NON | OUI | Necessite `docker pull` |
| `v3.5.47-vault-tls-fix-*` | NON | ? | Pre-mars, a eviter |

---

## 8. Livrable cree

`keybuzz-infra/docs/ROLLBACK-SOURCE-OF-TRUTH-01.md` — document de reference contenant :
- Tableau global des services et images actuelles
- Rollback immediat sur (1 cran) pour API et client
- Chaine complete de deploiement chronologique
- Notes de vigilance (images dangereuses, images absentes)
- Procedure de rollback standardisee

---

## 9. Corrections apportees

| Fichier | Modification |
|---|---|
| `PH-AMZ-CONNECTOR-FALSE-CONNECTED-TRUTH-04-REPORT.md` | Section 10 : rollback `v3.5.47` → `v3.5.111` + addendum |
| `PH-BILLING-PLAN-TRUTH-RECOVERY-01-REPORT.md` | Section 9 : rollback `v3.5.108` → `v3.5.110` + addendum |
| `ROLLBACK-SOURCE-OF-TRUTH-01.md` | NOUVEAU — source de verite rollback |

---

## Verdict Final

## ROLLBACK METADATA FIXED AND TRUSTWORTHY

Deux rapports contenaient des rollbacks faux (TRUTH-04 : critique, BILLING-01 : majeur). Les deux ont ete corriges avec addendum. Un document de reference `ROLLBACK-SOURCE-OF-TRUTH-01.md` a ete cree comme source de verite unique. Les 4 manifests GitOps sont alignes avec les images live.
