# PH-PLAYBOOKS-V2-PROD-PROMOTION-01

> Phase : Promotion PROD — Module Playbooks V2
> Date : 2026-04-08
> Périmètre : PROD (API + Client)
> Source : DEV validé (`v3.5.225-ph-playbooks-v2-dev`)

---

## Objectif

Promouvoir en PROD les corrections Playbooks V2 validées en DEV :
- Triggers corrigés (tracking / annulation / retour / défectueux)
- Simulateur fonctionnel (daysLate dynamique)
- Auto-seed multi-tenant
- Starters actifs par défaut (8 active / 7 disabled)

---

## Images

| Service | Avant (v3.5.224) | Après (v3.5.225) |
|---------|-----------------|-----------------|
| API PROD | `v3.5.224-ph143-agents-ia-prod` | `v3.5.225-ph-playbooks-v2-prod` |
| Client PROD | `v3.5.224-ph143-agents-ia-prod` | `v3.5.225-ph-playbooks-v2-prod` |
| API DEV | `v3.5.225-ph-playbooks-v2-dev` | inchangé |
| Client DEV | `v3.5.225-ph-playbooks-v2-dev` | inchangé |

### SHA Docker

| Image | Digest |
|-------|--------|
| API PROD | `sha256:7203dc9769e456bd66b71f035ae18a2e93ef200881d7df8d2cea0cc8a3809c15` |
| Client PROD | `sha256:2ce2c50fb7a2c389b31d2a847eb368da665f4eded96353ed6a62350850eaa4be` |

---

## Diff vs v3.5.224

### Fichiers modifiés (4)

| Fichier | Changement |
|---------|-----------|
| `playbook-engine.service.ts` | Suppression `'commande'` des keywords `tracking_request` |
| `playbook-seed.service.ts` | Starter-plan playbooks seedés en `active` par défaut |
| `modules/playbooks/routes.ts` | Auto-seed si tenant sans playbooks + import seedStarterPlaybooks |
| `app/api/playbooks/[id]/simulate/route.ts` | Fix `daysLate` : interface, destructuring, context, evaluateConditions |

### Aucun fichier hors scope
- 0 fichier Studio
- 0 merge main
- 0 changement IA/Agents/Billing

---

## Validation PROD — Smoke Tests

### Playbooks (15 total)

| Playbook | Trigger | Status |
|----------|---------|--------|
| Où est ma commande ? | tracking_request | **active** |
| Suivi indisponible | tracking_request | **active** |
| Retard de livraison | delivery_delay | **active** |
| Demande de retour | return_request | **active** |
| Paiement refusé | payment_declined | **active** |
| Produit défectueux | defective_product | **active** |
| Demande de facture | invoice_request | **active** |
| Annulation de commande | order_cancelled | **active** |
| Client agressif | negative_sentiment | disabled |
| Mauvaise description produit | wrong_description | disabled |
| Produit incompatible | incompatible_product | disabled |
| Message hors sujet | off_topic | disabled |
| Client VIP | vip_client | disabled |
| Message sans réponse | unanswered_timeout | disabled |
| Escalade vers support | escalation_needed | disabled |

### Triggers (PROD)

| Test | Triggers détectés | Verdict |
|------|------------------|---------|
| "Je veux annuler ma commande" | `order_cancelled` | **OK** — plus de tracking |
| "Retourner le produit, être remboursé" | `return_request` | **OK** |
| "Produit cassé, ne fonctionne pas" | `defective_product` | **OK** |
| "Où est ma commande, pas reçu colis" | `tracking_request` | **OK** |
| "5 jours de retard livraison" | `tracking_request` | **OK** |

**ALL TRIGGERS OK**

### Auto-seed multi-tenant (PROD)

| Test | Résultat |
|------|---------|
| Nouveau tenant `test-prod-seed-001` | 15 playbooks auto-seedés |
| Cleanup | 15 lignes supprimées |

### Non-régression endpoints (PROD)

| Endpoint | HTTP Status |
|----------|-------------|
| conversations | 200 |
| check-user | 200 |
| agents | 200 |
| billing | 200 |
| ai-wallet | 200 |
| ai-settings | 200 |
| dashboard | 200 |
| orders | 200 |
| entitlement | 200 |
| space-invites | 200 |
| playbooks | 200 |

**11/11 = 200**

---

## Anti-contamination

| Check | Résultat |
|-------|---------|
| 0 fichier Studio dans l'image | OK |
| Build depuis code source identique au DEV | OK |
| Pas de merge main | OK |
| Pas de code hors scope | OK |
| DEV inchangé | OK |

---

## Rollback

```bash
# API PROD
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.224-ph143-agents-ia-prod -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod

# Client PROD
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.224-ph143-agents-ia-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## GitOps

| Manifest | Image mise à jour |
|----------|------------------|
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.225-ph-playbooks-v2-prod` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.225-ph-playbooks-v2-prod` |
| `k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.225-ph-playbooks-v2-dev` (depuis PH-PLAYBOOKS-V2) |
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.225-ph-playbooks-v2-dev` (depuis PH-PLAYBOOKS-V2) |

---

## Verdict

**PLAYBOOKS V2 PROMOTED TO PROD**

- Triggers corrigés — tracking/annulation/retour/défectueux
- Simulateur fonctionnel — daysLate dynamique
- Auto-seed multi-tenant — 15 playbooks (8 active / 7 disabled)
- Non-régression — 11/11 endpoints PROD = 200
- Anti-contamination — zéro fichier hors scope
- Rollback documenté
- DEV/PROD alignés sur v3.5.225

**PLAYBOOKS V2 STABLE — TRIGGERS CORRECT — MULTI-TENANT OK — PROD CLEAN**
