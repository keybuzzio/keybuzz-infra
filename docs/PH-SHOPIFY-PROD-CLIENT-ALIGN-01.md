# PH-SHOPIFY-PROD-CLIENT-ALIGN-01 — Alignement Client PROD Shopify

**Date** : 10 avril 2026
**Phase** : PH-SHOPIFY-PROD-CLIENT-ALIGN-01
**Environnement** : PROD
**Statut** : VALIDÉ

---

## 1. Problème

Le client PROD (`v3.5.225-ph-playbooks-v2-prod`) était en retard de 3 phases Shopify par rapport au DEV (`v3.5.228-ph-shopify-04-dev`).

| Élément | Client PROD (avant) | Client DEV (référence) |
|---|---|---|
| `shopify.svg` | **ABSENT** | Présent |
| Routes BFF Shopify (`/api/shopify/*`) | **ABSENTES** | Présentes (connect, disconnect, status) |
| `shopifyPaymentStatus` (OrderSidePanel) | **ABSENT** | Présent |
| Catalogue canaux Shopify | **ABSENT** | Présent |

**Cause** : L'API PROD avait été promue en `v3.5.237-ph-shopify-expiring-prod` (PH-SHOPIFY-PROD-PROMOTION-01) mais le client PROD n'avait jamais été aligné.

---

## 2. Solution

Build d'une image client PROD depuis le même code source que le client DEV validé, avec les `--build-arg` PROD :

```bash
docker build --no-cache \
  --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  -t ghcr.io/keybuzzio/keybuzz-client:v3.5.238-ph-shopify-client-prod .
```

---

## 3. Images

| Service | Avant | Après |
|---|---|---|
| Client PROD | `v3.5.225-ph-playbooks-v2-prod` | `v3.5.238-ph-shopify-client-prod` |
| API PROD | `v3.5.237-ph-shopify-expiring-prod` | Inchangée |
| Client DEV | `v3.5.228-ph-shopify-04-dev` | Inchangé |
| API DEV | `v3.5.238-ph-shopify-04-ai-dev` | Inchangée |

---

## 4. Contenu aligné

### Assets Shopify
- `shopify.svg` : présent dans `/app/public/marketplaces/`

### Routes BFF Shopify
- `/api/shopify/connect` : présent
- `/api/shopify/disconnect` : présent
- `/api/shopify/status` : présent

### OrderSidePanel enrichi
- `shopifyPaymentStatus` : présent dans l'Inbox
- `shopifyFulfillmentStatus` : présent dans l'Inbox
- Bloc "Statut Shopify" avec badges paiement/fulfillment

### Catalogue canaux
- Shopify visible dans `/channels` avec icône correcte

---

## 5. Validation PROD

| Test | Résultat |
|---|---|
| Client PROD image | `v3.5.238-ph-shopify-client-prod` — Running |
| API PROD Health | `{"status":"ok"}` |
| Client PROD accessible | HTTP 200 (`client.keybuzz.io/login`) |
| `shopify.svg` dans le pod | Présent (714 octets) |
| Routes BFF Shopify | connect, disconnect, status — Présentes |
| Shopify connections PROD | 0 (aucune boutique connectée encore) |

---

## 6. Non-régression PROD

| Vérification | Résultat |
|---|---|
| Amazon orders | 11 835 (inchangé) |
| Conversations | 447 (inchangé) |
| AI Wallet ecomlg-001 | 899.03 KBA remaining (inchangé) |
| Playbooks actifs | 6 tenants × 8 playbooks (inchangé) |
| Billing subscriptions | 3 (inchangé) |
| Client PROD | HTTP 200 |
| API PROD | `{"status":"ok"}` |

---

## 7. Rollback

```bash
# Client PROD rollback
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.225-ph-playbooks-v2-prod \
  -n keybuzz-client-prod
```

Ou via GitOps : restaurer la ligne `image:` dans `k8s/keybuzz-client-prod/deployment.yaml`.

---

## 8. GitOps

- `k8s/keybuzz-client-prod/deployment.yaml` : image mise à jour
- Commit local : `PH-SHOPIFY-PROD-CLIENT-ALIGN-01: Align client PROD with Shopify DEV (v3.5.238)`
- `git push` : bloqué par GitHub Push Protection (secrets Vault dans commits antérieurs `ph-studio-*`). Nécessite autorisation via le lien GitHub Security.

---

## 9. État final DEV / PROD

| Service | DEV | PROD | Aligné |
|---|---|---|---|
| API | `v3.5.238-ph-shopify-04-ai-dev` | `v3.5.237-ph-shopify-expiring-prod` | Partiel (PH-SHOPIFY-04 API non promu) |
| Client | `v3.5.228-ph-shopify-04-dev` | `v3.5.238-ph-shopify-client-prod` | **OUI** (même code source) |

Note : L'API PROD n'a pas le profil marketplace SHOPIFY de PH-SHOPIFY-04 (il est en DEV uniquement). C'est volontaire — la promotion API sera faite dans une phase dédiée.

---

## Verdict

**CLIENT PROD ALIGNÉ — SHOPIFY UI OPÉRATIONNEL — ZÉRO RÉGRESSION**
