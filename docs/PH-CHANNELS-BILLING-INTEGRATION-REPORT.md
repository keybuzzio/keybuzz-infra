# PH-CHANNELS-BILLING-INTEGRATION Report

> Date : 2026-03-13
> Auteur : Agent Cursor (CE)
> Environnement : DEV deploye, PROD en attente validation Ludovic

---

## A. Audit existant

### Billing actuel (pre-integration)
| Element | Etat |
|---|---|
| `billing_subscriptions` | 3 tenants (ecomlg-001, switaa-sasu, ecomlg-mmiyygfg) |
| `billing_customers` | 3 clients Stripe (1 pending, 2 reels) |
| `billing_events` | 51 evenements |
| `tenant_channels` | Table creee PH-CHANNELS-FIX-04, 5 lignes (1 active, 4 removed) |

### Stripe actuel
| Element | Etat |
|---|---|
| Stripe mode | **TEST** (`sk_test_...`) |
| Webhook | Configure (`whsec_...`) |
| Plans | Starter/Pro/Autopilot monthly+annual (6 prices) |
| Channel addon | **DEJA EXISTANT** : `STRIPE_PRICE_ADDON_CHANNEL_MONTHLY` + `ANNUAL` |
| Product addon | `prod_TpJTEELacYjLGG` |
| API version | `2023-10-16` |

### Plans existants (planCapabilities.ts)
| Plan | Prix | Canaux inclus | Prix canal suppl. |
|---|---|---|---|
| Starter | 97 EUR | 1 | 50 EUR |
| Pro | 297 EUR | 3 | 50 EUR |
| Autopilot | 497 EUR | 5 | 50 EUR |
| Enterprise | devis | illimite | 0 |

### Addons existants
Le systeme de channel addon Stripe etait **deja implemente** dans `billing/routes.ts` :
- Checkout session supporte `channelsAddonQty`
- Webhook sync les items addon via `findChannelAddonItem()`
- Endpoint `PUT /billing/channels` pour modifier la quantite d'addon

**Ce qui manquait** : la connexion entre `tenant_channels` (source verite) et le billing.

---

## B. Decisions d'architecture

### Statuts billables
| Statut | Billable | Raison |
|---|---|---|
| `active` | OUI | Canal connecte et operationnel |
| `pending` | NON | Pas encore valide (OAuth en cours, etc.) |
| `removed` | NON | Canal retire par l'utilisateur |
| `disabled` | NON | Canal desactive (hypothetique) |

### Source de verite
- **Comptage canaux** : `tenant_channels WHERE status = 'active'`
- **Quotas plan** : `tenants.plan` -> `PLAN_INCLUDED_CHANNELS` map
- **Stripe sync** : existant, base sur `billing_subscriptions.channels_addon_qty`

### Comptage 1 pays = 1 canal
- `amazon-fr` = 1 canal
- `amazon-de` = 1 canal
- `amazon-it` = 1 canal
- `octopia-cdiscount-fr` = 1 canal
- Chaque `marketplace_key` unique = 1 canal

### Comment Stripe est synchronise
Le mecanisme existant dans `billing/routes.ts` fonctionne deja :
1. `PUT /billing/channels` modifie la quantite d'addon sur la subscription Stripe
2. Le webhook `customer.subscription.updated` met a jour `billing_subscriptions.channels_addon_qty`
3. La proration est calculee automatiquement (sauf en trial)

L'integration actuelle ajoute le **moteur de calcul** (`billing-compute`) qui determine
combien d'addons sont necessaires. La sync Stripe reelle peut etre declenchee par un appel
a `PUT /billing/channels` avec la quantite calculee.

**Mode actuel : dry-run** — le calcul est fait, l'affichage est en place, mais la sync
Stripe automatique n'est pas declenchee a chaque add/remove de canal. C'est un choix
delibere pour eviter les modifications Stripe non supervisees.

---

## C. Changements appliques

### Backend (keybuzz-api)

#### `src/modules/channels/channelsService.ts`
Ajout de 2 fonctions :
- `computeChannelBilling(tenantId)` : calcul complet du billing canaux
- `checkCanAddChannel(tenantId)` : verification pre-ajout avec info addon

Retour de `computeChannelBilling` :
```json
{
  "tenantId": "ecomlg-001",
  "plan": "PRO",
  "channelsIncluded": 3,
  "channelsActive": 1,
  "channelsPending": 0,
  "channelsBillable": 1,
  "extraChannelsNeeded": 0,
  "extraChannelUnitPrice": 50,
  "estimatedExtraMonthlyAmount": 0,
  "isEnterprise": false,
  "channels": [...]
}
```

#### `src/modules/channels/channelsRoutes.ts`
- `POST /channels/add` : retourne desormais les infos billing (`wouldNeedAddon`, `addonCost`)
- `POST /channels/remove` : retourne desormais le billing post-suppression
- `GET /channels/billing-compute` : nouvel endpoint pour le calcul complet

#### `src/modules/billing/routes.ts`
- Import de `countBillableChannels` depuis le module channels
- Ajout de `enrichBillingWithChannelCount()` : enrichit toutes les reponses `/billing/current` avec `channelsUsed` reel
- **TOUS les chemins de reponse** (DB, tenant table, fallback, canceled) passent par l'enrichissement

### Frontend (keybuzz-client)

#### `src/features/billing/useCurrentPlan.tsx`
- `channelsUsed` : plus de mock (`useState(2)` -> `useState(0)`)
- `ApiBillingResponse` : ajout du champ `channelsUsed?: number`
- `fetchBillingData` : synchronise `channelsUsed` depuis l'API

#### `src/services/channels.service.ts`
- Ajout du type `ChannelBillingCompute`
- Ajout de `fetchChannelBillingCompute(tenantId)`

#### `app/api/channels/billing-compute/route.ts`
- Nouveau BFF route proxifiant vers `GET /channels/billing-compute`

#### `app/channels/page.tsx`
- Fetch `billing-compute` en parallele avec les autres appels
- Affichage "Canaux utilises : X / Y" avec donnees reelles
- Affichage du cout des canaux supplementaires si au-dessus du quota
- Affichage "Canaux illimites" pour Enterprise

### Objets Stripe crees
**AUCUN** — tout existait deja :
- Les plans (Starter/Pro/Autopilot) existaient
- Le product addon channel (`prod_TpJTEELacYjLGG`) existait
- Les prices addon (monthly + annual) existaient

---

## D. Preuves

### Exemples tenants

#### ecomlg-001 (PRO, 1 canal actif)
```
channelsIncluded: 3
channelsActive: 1
channelsBillable: 1
extraChannelsNeeded: 0
estimatedExtraMonthlyAmount: 0
```

#### Simulation PRO avec 5 canaux
```
channelsIncluded: 3
channelsActive: 5
channelsBillable: 5
extraChannelsNeeded: 2
estimatedExtraMonthlyAmount: 100
```

#### Simulation Enterprise
```
isEnterprise: true
channelsActive: 3
extraChannelsNeeded: 0
estimatedExtraMonthlyAmount: 0
```

#### Simulation Starter (1 canal inclus, 2 actifs)
```
channelsIncluded: 1
channelsActive: 2
extraChannelsNeeded: 1
estimatedExtraMonthlyAmount: 50
```

### Resultats tests
```
21 tests, 46 assertions, 0 echecs
```

Tests couverts :
1. billing/current retourne channelsUsed reel
2. billing-compute calcul complet
3. Ajout canal avec info billing
4. Pending non billable
5. Ajout multiple canaux
6. Over-quota (4/3 = 1 extra, 50 EUR)
7. billing/current reflete channelsUsed dynamique
8. 5/3 = 2 extras, 100 EUR
9. Suppression canal = compteur baisse
10. Canal removed absent de la liste
11. Marketplace invalide = 400
12. Coming-soon = 400
13. Catalogue > 10 entries
14. Legacy billing endpoint compatible
15. Isolation multi-tenant
16. Health check non affecte
17. Stripe status non affecte
18. Enterprise : 0 extras, 0 cout
19. Starter : 1 inclus, 2 actifs, 1 extra, 50 EUR
20. Ajout retourne billing info
21. Ajout idempotent

---

## E. Rollback

### Code
```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.97-channels-fix-dev -n keybuzz-api-dev
# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.57-channels-fix-dev -n keybuzz-client-dev
```

### GitOps
Les tags precedents sont documentes dans `keybuzz-infra/k8s/keybuzz-*-dev/deployment.yaml` (historique git).

### Stripe
**Aucune modification Stripe** — rien a rollback.

### DB
La table `tenant_channels` n'a pas ete modifiee structurellement.
Les donnees de test ont ete nettoyees automatiquement par le script de test.

---

## F. Versions deployees

| Service | Tag DEV |
|---|---|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.58-channels-billing-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.58-channels-billing-dev` |

---

## G. Ce qui existait deja vs ce qui a ete cree

| Element | Existait | Cree/Modifie |
|---|---|---|
| Plans Stripe (6 prices) | OUI | - |
| Channel addon Stripe (product + prices) | OUI | - |
| `billing_subscriptions.channels_addon_qty` | OUI | - |
| `PUT /billing/channels` (sync Stripe) | OUI | - |
| `findChannelAddonItem()` / `findPlanItem()` | OUI | - |
| Checkout avec `channelsAddonQty` | OUI | - |
| Webhook sync addon items | OUI | - |
| `computeChannelBilling()` | - | CREE |
| `checkCanAddChannel()` | - | CREE |
| `GET /channels/billing-compute` | - | CREE |
| `enrichBillingWithChannelCount()` | - | CREE |
| `channelsUsed` dans `/billing/current` | - | AJOUTE |
| UI billing enhanced dans `/channels` | - | MODIFIE |
| `useCurrentPlan` channelsUsed reel | - | MODIFIE |

---

## H. Sync Stripe : etat actuel

- **Mode** : dry-run (calcul fait, affichage en place)
- **Sync reelle** : disponible via `PUT /billing/channels` existant
- **Declenchement auto** : NON implemente volontairement
- **Raison** : eviter les modifications Stripe non supervisees en phase initiale
- **Prochaine etape** : activer la sync auto apres validation Ludovic

---

## STOP POINT

Aucun deploiement PROD sans validation Ludovic.

Pour promotion PROD, il faudra :
1. Valider le comportement en DEV
2. Builder les images `-prod`
3. Mettre a jour les deployment.yaml PROD
4. Deployer via kubectl
5. Verifier les endpoints PROD
