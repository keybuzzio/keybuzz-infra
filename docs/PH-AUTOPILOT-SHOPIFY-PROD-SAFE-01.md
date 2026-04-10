# PH-AUTOPILOT-SHOPIFY-PROD-SAFE-01 — Promotion PROD Autopilot Shopify (SAFE MODE)

> Date : 10 avril 2026
> Environnement : PROD
> Mode : SAFE — draft uniquement, aucun envoi automatique

---

## Objectif

Promouvoir l'Autopilot Shopify en PROD en mode sécurisé :
- Draft uniquement (safe_mode=true)
- Aucune réponse envoyée automatiquement
- Validation humaine obligatoire

---

## Precheck

| Vérification | Résultat |
|---|---|
| Image DEV validée | `v3.5.239-ph-autopilot-shopify-dev` |
| PROD avant promotion | `v3.5.238-ph-shopify-04-ai-prod` |
| Pods PROD healthy | 1/1 Running |
| Health check PROD | `{"status":"ok"}` |
| Shopify connexions PROD | 0 (aucune connexion active) |
| Shopify conversations PROD | 0 (aucune conversation existante) |
| Autopilot safe_mode PROD | **true** pour tous les tenants (4/4) |

---

## Image déployée

| Env | Image | Rollback |
|---|---|---|
| **PROD** | `ghcr.io/keybuzzio/keybuzz-api:v3.5.239-ph-autopilot-shopify-prod` | `v3.5.238-ph-shopify-04-ai-prod` |
| DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.239-ph-autopilot-shopify-dev` | `v3.5.238-ph-shopify-04-ai-dev` |

---

## Safe Mode — État de tous les tenants PROD

| Tenant | is_enabled | mode | safe_mode | allow_auto_reply |
|---|---|---|---|---|
| ecomlg-001 | true | supervised | **true** | false |
| romruais-gmail-com-mn7mc6xl | false | off | **true** | false |
| switaa-sasu-mn9c3eza | true | supervised | **true** | true |
| switaa-sasu-mnc1ouqu | true | autonomous | **true** | true |

**Tous les tenants ont `safe_mode: true` — aucun envoi automatique possible.**

---

## Données de test PROD

| Type | ID | Détails |
|---|---|---|
| Order | `ord-shopify-test-prod-001` | Shopify, Enceinte Bluetooth, 79.99 EUR |
| Conversation | `conv-shopify-test-prod-001` | Canal shopify, Marie Martin, status pending |
| Message | `msg-shopify-test-prod-001` | Inbound, demande suivi expédition |

---

## Validation Shopify PROD

**`POST /autopilot/evaluate` sur `conv-shopify-test-prod-001`**

| Critère | Résultat |
|---|---|
| Draft généré | Oui — 745 chars, cohérent, personnalisé ("Bonjour Marie") |
| executed | **false** (safe_mode respecté) |
| Confidence | 0.75 |
| KBActions débités | 6.72 |
| Outbound delivery créé | **Non** (aucun message envoyé) |
| AI Action Log | `autopilot_escalate` status=skipped |
| False promise detection | Fonctionnelle ("je reviens vers vous", "je vais vérifier") |

---

## Non-régression Amazon PROD

**`POST /autopilot/evaluate` sur `cmmnp0b76t5236d53bd31bebf`** (conversation Amazon réelle)

| Critère | Résultat |
|---|---|
| Draft généré | Oui — contextualisé (HP OfficeJet, n° commande, tracking) |
| executed | **false** (safe_mode respecté) |
| Confidence | 0.80 |
| KBActions débités | 6.82 |
| Context utilisé | orderNumber, trackingNumber, trackingStatus, carrierName, deliveryDelay |

---

## Non-régression endpoints PROD

| Endpoint | Statut |
|---|---|
| `GET /health` | OK |
| `GET /messages/conversations` | OK |
| `GET /api/v1/orders` | OK (3 orders retournés) |

---

## Post-validation

- Plan `ecomlg-001` restauré à `PRO` (plan original)
- Autopilot settings `ecomlg-001` restaurés : `mode=supervised, safe_mode=true, allow_auto_reply=false`
- GitOps manifeste PROD mis à jour et poussé sur GitHub

---

## Rollback d'urgence

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.238-ph-shopify-04-ai-prod -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

---

## Verdict

**PROD : VALIDÉ** — Autopilot Shopify déployé en mode safe (draft only), zéro message envoyé automatiquement, non-régression Amazon confirmée, tous les tenants en safe_mode.
