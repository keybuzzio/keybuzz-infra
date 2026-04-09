# Rollback — Source de Verite

> **Derniere mise a jour** : 27 mars 2026
> **Auteur** : Agent Cursor (PH-ENV-ALIGNMENT-STRICT-01)
> **Methode** : croisement `kubectl get deployment`, `docker images` bastion, rapports de phase

---

## 1. Etat Live Actuel

| Service | Env | Image actuelle | Manifest GitOps |
|---|---|---|---|
| keybuzz-api | DEV | `v3.5.120-env-aligned-dev` | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| keybuzz-api | PROD | `v3.5.120-env-aligned-prod` | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` |
| keybuzz-client | DEV | `v3.5.121-ph-autopilot-ui-feedback-dev` | `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` |
| keybuzz-client | PROD | `v3.5.120-env-aligned-prod` | `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` |
| keybuzz-backend | DEV | `v1.0.40-amz-tracking-visibility-backfill-dev` | — |
| keybuzz-backend | PROD | `v1.0.40-amz-tracking-visibility-backfill-prod` | — |
| outbound-worker | DEV | `v3.6.00-td02-worker-resilience-dev` | — |
| outbound-worker | PROD | `v3.6.00-td02-worker-resilience-prod` | — |
| keybuzz-website | DEV | `v0.5.1-ph3317b-prod-links` | — |
| keybuzz-website | PROD | `v0.5.1-ph3317b-prod-links` | — |

**DEV et PROD sont strictement alignes (27 mars 2026).**
- API et Client partagent la meme version logique : **v3.5.120**
- Meme codebase, seules les variables d'environnement (API URLs, DB) different
- API DEV et PROD ont le meme digest Docker (`sha256:42d823adf732...`)
- Builds realises depuis un Git propre (zero fichiers dirty)

---

## 2. Rollback Immediat Sur (1 cran)

### keybuzz-api

| Env | Rollback safe | Phase source | Disponible bastion |
|---|---|---|---|
| DEV | `v3.5.48-ph-autopilot-engine-fix-dev` | Autopilot Engine SQL Fix | OUI |
| PROD | `v3.5.48-ph-autopilot-engine-fix-prod` | Autopilot Engine SQL Fix | OUI |

```bash
# DEV
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph-autopilot-engine-fix-dev -n keybuzz-api-dev
# PROD
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph-autopilot-engine-fix-prod -n keybuzz-api-prod
```

### keybuzz-client

| Env | Rollback safe | Phase source | Disponible bastion |
|---|---|---|---|
| DEV | `v3.5.119-ph-ai-assist-reliability-dev` | AI Assist Reliability | OUI |
| PROD | `v3.5.119-ph-ai-assist-reliability-prod` | AI Assist Reliability | OUI |

```bash
# DEV
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.119-ph-ai-assist-reliability-dev -n keybuzz-client-dev
# PROD
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.119-ph-ai-assist-reliability-prod -n keybuzz-client-prod
```

---

## 3. Chaine Complete de Deploiement (chronologique)

### keybuzz-api

| # | Tag | Phase | Date build | Sur bastion |
|---|---|---|---|---|
| 1 | `v3.5.107b-ph131-autopilot-engine` | PH131-C Autopilot Engine | 26 mars ~10h | NON |
| 2 | `v3.5.108-ph-amz-inbound-address` | AMZ Inbound TRUTH-01 | 26 mars ~10h30 | NON |
| 3 | `v3.5.109-ph-amz-inbound-truth02` | AMZ Inbound TRUTH-02 | 26 mars ~11h | NON |
| 4 | `v3.5.110-ph-amz-multi-country` | AMZ Multi-Country TRUTH-03 | 26 mars 12h14 | OUI |
| 5 | `v3.5.111-ph-billing-truth` | Billing Plan TRUTH-01 | 26 mars 13h04 | OUI |
| 6 | `v3.5.114-ph-amz-false-connected` | TRUTH-04 (INTERMEDIATE, enum bug) | 26 mars 16h20 | OUI (DEV only) |
| 7 | `v3.5.115-ph-amz-false-connected` | AMZ False Connected TRUTH-04 | 26 mars 16h24 | OUI |
| 8 | `v3.5.48-ph-autopilot-engine-fix` | Autopilot Engine SQL Fix | 27 mars 08h15 | OUI |
| 9 | **`v3.5.120-env-aligned`** | **PH-ENV-ALIGNMENT-STRICT-01 (CURRENT)** | **27 mars 09h50** | **OUI** |

### keybuzz-client

| # | Tag | Phase | Date build | Sur bastion |
|---|---|---|---|---|
| 1 | `v3.5.107-ph131-autopilot-engine` | PH131-C Autopilot Engine | 26 mars ~10h | NON |
| 2 | `v3.5.108-ph-amz-inbound-address` | AMZ Inbound TRUTH-01 | 26 mars ~10h30 | NON |
| 3 | `v3.5.109-ph-amz-inbound-truth02` | AMZ Inbound TRUTH-02 | 26 mars ~11h | OUI (PROD only) |
| 4 | `v3.5.112-ph-billing-truth-02` | Billing Plan TRUTH-02 | 26 mars 13h49 | OUI |
| 5 | `v3.5.113-ph-trial-plan-fix` | Trial Banner + Plan Change | 26 mars 14h52 | OUI |
| 6 | `v3.5.116-ph-ai-product-integration` | AI Product Integration | 26 mars 19h27 | OUI |
| 7 | `v3.5.117-ph-ai-inbox-native-ux` | AI Inbox Native UX | 26 mars 21h06 | OUI |
| 8 | `v3.5.118-ph-ai-inbox-unified-entry` | AI Inbox Unified Entry | 26 mars 22h43 | OUI |
| 9 | `v3.5.119-ph-ai-assist-reliability` | AI Assist Reliability | 26 mars 23h29 | OUI |
| 10 | `v3.5.120-env-aligned` | PH-ENV-ALIGNMENT-STRICT-01 | 27 mars 09h50 | OUI |
| 11 | **`v3.5.121-ph-autopilot-ui-feedback`** | **PH-AUTOPILOT-UI-FEEDBACK-01 (CURRENT DEV)** | **1 mars 2026** | **OUI** |

---

## 4. Images Pre-mars (anciennes)

Ces images datent d'AVANT la serie de phases du 26 mars 2026 :

| Service | Dernier tag pre-mars | Sur bastion | Commentaire |
|---|---|---|---|
| keybuzz-api | `v3.5.47-vault-tls-fix` | NON | Contexte file reference, pas sur bastion |
| keybuzz-api | `v3.5.104-ph131-autopilot-settings` | NON | Derniere PROD avant PH131-C engine |
| keybuzz-client | `v3.5.48-white-bg` | NON | Contexte file reference |
| keybuzz-client | `v3.5.106-ph131-starter-upsell` | NON | Derniere PROD avant PH131-C engine |

> **ATTENTION** : les images non presentes sur le bastion ne sont disponibles que dans GHCR. Un `docker pull` est necessaire avant tout rollback vers ces tags.

---

## 5. Notes de Vigilance

### v3.5.114 — NE JAMAIS UTILISER POUR ROLLBACK
Image intermediaire avec un bug d'enum (`type = 'amazon'` au lieu de `'AMAZON'`). Toute requete vers `marketplace_connections` echoue avec `invalid input value for enum "MarketplaceType"`.

### v3.5.47 — ROLLBACK DESTRUCTEUR
L'image `v3.5.47-vault-tls-fix` est l'ancienne image pre-phases. Un rollback vers ce tag perdrait :
- Autopilot engine (PH131-C)
- Tous les fix Amazon inbound (TRUTH-01/02/03/04)
- Billing plan truth (channels hardcodes)
- Toutes les corrections de mars 2026

### v3.5.120 — Version unifiee
Premiere version ou API et Client partagent le meme numero de version logique (v3.5.120). Les versions precedentes avaient des numerotations divergentes (API v3.5.48, Client v3.5.119).

### Images non presentes sur le bastion
Les tags `v3.5.107*`, `v3.5.108*`, `v3.5.109-dev` ne sont plus en cache Docker local sur le bastion. Ils sont toujours dans GHCR mais necesitent un `docker pull` prealable.

### Outbound Worker et Backend
Le outbound worker (`v3.6.00-td02-worker-resilience`) et le backend (`v1.0.40-amz-tracking-visibility-backfill`) n'ont pas ete modifies par les phases recentes. Leurs rollbacks ne sont pas couverts par ces rapports.

---

## 6. Procedure de Rollback

```bash
# 1. Identifier le service et l'environnement
# 2. Consulter ce document pour le tag rollback safe
# 3. Verifier la disponibilite sur le bastion :
docker images ghcr.io/keybuzzio/<service> --format '{{.Tag}}' | grep <tag>

# 4. Si absent, pull depuis GHCR :
docker pull ghcr.io/keybuzzio/<service>:<tag>

# 5. Rollback :
kubectl set image deploy/<service> <container>=ghcr.io/keybuzzio/<service>:<tag> -n <namespace>
kubectl rollout status deploy/<service> -n <namespace>

# 6. Mettre a jour le manifest GitOps correspondant
```

---

## 7. Git Commits de Reference (v3.5.120)

| Repo | Commit | Message |
|---|---|---|
| keybuzz-api | `c0ee35a` | PH-ENV-ALIGNMENT: commit deployed autopilot engine fix + compat routes |
| keybuzz-client | `2310176` | PH-ENV-ALIGNMENT: commit remaining deployed AI components |

Les builds v3.5.120 ont ete realises depuis un Git **propre** (zero fichiers dirty) apres commit de tous les changements deployes.
