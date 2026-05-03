# PH-SAAS-T8.12AJ — Shopify Connector Truth Audit & Official Logo DEV

> **Phase** : PH-SAAS-T8.12AJ-SHOPIFY-CONNECTOR-TRUTH-AUDIT-AND-OFFICIAL-LOGO-DEV-01
> **Date** : 3 mai 2026
> **Environnement** : DEV (PROD lecture seule)
> **Type** : Audit vérité + correction logo DEV
> **Verdict** : **GO PARTIEL — SHOPIFY PARTIAL RESTORE NEEDED**

---

## Objectif

Vérifier si le connecteur Shopify est réellement fonctionnel dans KeyBuzz de bout en bout, et corriger le logo Shopify avec l'asset officiel fourni par Ludovic.

---

## ÉTAPE 0 — Preflight

### Repos

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `38f221f1` | non | **GO** |
| keybuzz-client | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `39591d9` | non | **GO** |
| keybuzz-infra | `main` | `main` | `07a64f5` | non | **GO** |

### Runtimes

| Service | DEV image | PROD image | Manifest = runtime | Verdict |
|---|---|---|---|---|
| API DEV | `v3.5.144-conversation-tracking-code-fallback-dev` | — | oui | OK |
| API PROD | — | `v3.5.137-conversation-order-tracking-link-prod` | oui | OK |
| Client DEV | `v3.5.146-sample-demo-platform-aware-dev` | — | oui | OK |
| Client PROD | — | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | oui | OK |
| Admin PROD | — | `v2.11.37-acquisition-baseline-truth-prod` | oui | OK |
| Website PROD | — | `v0.6.8-tiktok-browser-pixel-prod` | oui | OK |
| 17TRACK CronJob | — | — | `suspend: true` | OK |

---

## ÉTAPE 1 — Synthèse documentation historique

| Rapport | Promesse Shopify | Preuve historique | Vérifiable runtime |
|---|---|---|---|
| PH-SHOPIFY-01 | Architecture Shopify audit | Plan d'insertion | Non (plan uniquement) |
| PH-SHOPIFY-02 | OAuth managed install | Code implémenté (v3.5.237+) | **NON — routes 404** |
| PH-SHOPIFY-02.1 | UX réelle + OAuth activation | Testé avec boutique DEV | **NON — routes absentes** |
| PH-SHOPIFY-02.2-03 | Webhooks compliance | Compliance Shopify Partner | **NON — routes absentes** |
| PH-SHOPIFY-03.1 | Validation réelle | Connexion boutique dev testée | **NON — routes absentes** |
| PH-SHOPIFY-04 | AI policy enrichment | marketplace-channel-context | **OUI** — présent runtime |
| PH-SHOPIFY-PROD-PROMOTION-01 | PROD promotion | Image v3.5.239 | **NON — image actuelle v3.5.137** |
| PH147.6 | UI restore (fallback catalogue) | Client injecte shopifyEntry | **OUI** — client présent |
| PH153.* | Récupération source compilée | Triage fichier par fichier | **NON — source API absente** |

**Constat critique** : les phases Shopify utilisaient des images API `v3.5.237/238/239`. L'API actuelle est `v3.5.137/v3.5.144`. Les routes Shopify ont été **perdues** lors des rebuilds/rebase ultérieurs.

---

## ÉTAPE 2 — Audit source API actuelle

### Fichiers Shopify API

| Fichier | Rôle attendu | Présent source | Présent dist/runtime | Verdict |
|---|---|---|---|---|
| `src/modules/marketplaces/shopify/` | Dossier Shopify | **NON** | **NON** | **ABSENT** |
| `shopifyAuth.service.ts` | Auth OAuth | **NON** | **NON** | **ABSENT** |
| `shopifyCrypto.service.ts` | Chiffrement tokens | **NON** | **NON** | **ABSENT** |
| `shopify.routes.ts` | Routes API | **NON** | **NON** | **ABSENT** |
| `shopifyWebhook.routes.ts` | Webhooks | **NON** | **NON** | **ABSENT** |
| `shopifyOrders.service.ts` | Sync commandes | **NON** | **NON** | **ABSENT** |
| Enregistrement `app.ts` | Routes Shopify | **NON** (0 refs) | **NON** | **ABSENT** |
| `src/lib/marketplace-channel-context.ts` | Contexte IA Shopify | **OUI** | **OUI** (2 hits) | **OK** |
| `src/services/refundProtectionLayer.ts` | Protection refund | **OUI** | **OUI** | OK (0 refs Shopify directes) |
| `src/services/responseStrategyEngine.ts` | Stratégie réponse | **OUI** | **OUI** | OK (0 refs Shopify directes) |

### Infra K8s Shopify

| Élément | DEV | PROD | Verdict |
|---|---|---|---|
| Secret `keybuzz-shopify` | **OUI** (3 clés) | **OUI** (3 clés) | Présent mais inutilisé |
| Env `SHOPIFY_CLIENT_ID` | dans manifest | dans manifest | Présent mais route absente |
| Env `SHOPIFY_CLIENT_SECRET` | dans manifest | dans manifest | Présent mais route absente |
| Env `SHOPIFY_ENCRYPTION_KEY` | dans manifest | dans manifest | Présent mais route absente |
| Env `SHOPIFY_REDIRECT_URI` | dans manifest | dans manifest | Présent mais route absente |

**Les secrets et env vars sont injectés dans le pod, mais le code API n'a plus de routes pour les consommer.**

---

## ÉTAPE 3 — Audit source Client actuelle

| Fichier | Rôle | Présent | Verdict |
|---|---|---|---|
| `app/channels/page.tsx` | Page canaux + Shopify catalogue inject | **OUI** | OK |
| `app/api/shopify/connect/route.ts` | BFF connect → backend | **OUI** | OK (backend 404) |
| `app/api/shopify/status/route.ts` | BFF status → backend | **OUI** | OK (backend 404) |
| `app/api/shopify/disconnect/route.ts` | BFF disconnect → backend | **OUI** | OK (backend 404) |
| `src/services/shopify.service.ts` | Service client Shopify | **OUI** | OK |
| `public/marketplaces/shopify.svg` | Ancien logo | **OUI** | Remplacé par PNG |
| `public/marketplaces/shopify.png` | Logo officiel | **OUI** (ajouté PH-T8.12AJ) | **OK** |
| `src/features/onboarding/hooks/useOnboardingState.ts` | Onboarding Shopify | **OUI** | OK |
| `app/billing/options/page.tsx` | Logo billing | **OUI** | OK |
| `.cursor/rules/shopify-integration-rules.mdc` | Règles Cursor | **OUI** | OK |

**Client FULL** — toute l'UI Shopify est en place, mais les appels BFF vers le backend retournent 404.

---

## ÉTAPE 4 — Audit DB DEV / PROD

| Table | DEV count | PROD count | Risque | Verdict |
|---|---|---|---|---|
| `shopify_connections` | 12 (tous disconnected, tenant `keybuzz-mnqnjna8`) | 0 | Aucun | OK |
| `shopify_webhook_events` | 18 | 1 | Aucun | OK |
| `orders` channel=shopify | 2 | 1 | Données test/legacy | OK |
| `conversations` channel=shopify | 1 | 1 | Données test/legacy | OK |

Les tables Shopify existent dans la DB DEV et PROD, avec des données de test historiques.

---

## ÉTAPE 5 — Audit endpoints runtime

| Endpoint | DEV | PROD | Réponse | Verdict |
|---|---|---|---|---|
| `GET /health` | 200 | 200 | `{"status":"ok"}` | **OK** |
| `GET /shopify/status` | **404** | **404** | Route not found | **ABSENT** |
| `POST /shopify/connect` | **404** (implicite) | **404** | Route not found | **ABSENT** |
| `GET /shopify/callback` | **404** (implicite) | **404** | Route not found | **ABSENT** |
| `POST /shopify/disconnect` | **404** (implicite) | **404** | Route not found | **ABSENT** |
| `POST /webhooks/shopify` | **404** (implicite) | **404** | Route not found | **ABSENT** |
| `GET /channels/catalog` | 200 | — | Amazon/Octopia seulement, **pas Shopify** | OK (Shopify injecté côté client) |

**Toutes les routes API Shopify retournent 404.** Le client injecte Shopify dans le catalogue côté client uniquement.

---

## ÉTAPE 6 — Audit IA propagation Shopify

| Couche IA | Shopify branché | Utilise order | Utilise tracking | Refund-first bloqué | Verdict |
|---|---|---|---|---|---|
| `marketplace-channel-context.ts` | **OUI** — `direct_seller_controlled` | N/A (contexte) | N/A (contexte) | N/A | **OK** |
| `refundProtectionLayer.ts` | **NON** (0 refs Shopify) | — | — | — | GAP |
| `responseStrategyEngine.ts` | **NON** (0 refs Shopify) | — | — | — | GAP |
| `shared-ai-context.ts` | **NON** (0 refs) | N/A | N/A | N/A | GAP |
| `ai-assist-routes.ts` | **NON** (0 refs) | N/A | N/A | N/A | GAP |
| `autopilot/engine.ts` | **NON** (0 refs) | N/A | N/A | N/A | GAP |

**Le contexte marketplace Shopify est défini** (`direct_seller_controlled`, guidance correcte, pas de risque A-to-Z). Mais les modules IA spécifiques (refund protection, response strategy) ne font **pas de branchement spécifique Shopify** — ils utilisent le contexte via `resolveMarketplaceContext()` qui couvre Shopify indirectement.

La doctrine seller-first est respectée pour Shopify via la posture `direct_seller_controlled` :
- Diagnostic avant compensation
- Pas de refund-first
- Pas de promesse marketplace Amazon
- Le vendeur contrôle sa politique

---

## ÉTAPE 7 — Audit commande / suivi Shopify

| Signal | Amazon | Shopify actuel | Gap | Verdict |
|---|---|---|---|---|
| Orders en DB | 11155+ | 2 (DEV), 1 (PROD) | Données test uniquement | GAP |
| `orders.channel` | `amazon` | `shopify` | OK | OK |
| `orders.external_order_id` | Amazon ID | Shopify order ID | OK | OK |
| `orders.tracking_code` | renseigné | inconnu (peu de données) | Non vérifiable | GAP |
| `conversation.order_ref` | renseigné | inconnu (1 conv) | Non vérifiable | GAP |
| `resolveOrderRefFromMessages` | Amazon order ID regex | **Pas de Shopify regex** | Pattern Shopify non couvert | **GAP** |
| `tracking_events` Shopify | N/A | 0 events | Pas de tracking Shopify | GAP |
| 17TRACK Shopify | supporté structurellement | Non testé | Jamais activé pour Shopify | GAP |

**Le fallback `resolveOrderRefFromMessages` ne couvre que les Amazon order IDs (`\d{3}-\d{7}-\d{7}`) et UPS tracking (`1Z...`).** Les Shopify order IDs (format `#1001`, `gid://shopify/Order/...`) ne sont pas reconnus.

---

## ÉTAPE 8 — Logo Shopify officiel DEV

| Surface | Ancien logo | Nouveau logo officiel | Validé |
|---|---|---|---|
| `/channels` (PROVIDER_LOGOS) | `shopify.svg` | `shopify.png` (officiel Ludovic) | **OUI** |
| `/channels` (modale Image) | `shopify.svg` | `shopify.png` | **OUI** |
| `/billing/options` | `shopify.svg` | `shopify.png` | **OUI** |
| Onboarding Hub | `shopify.svg` | `shopify.png` | **OUI** |

Asset source : `C:\Users\ludov\Downloads\SHOP.png` (70 528 octets)
4 références mises à jour, 0 résiduel `shopify.svg` dans le code.

---

## ÉTAPE 9 — Build DEV

| Élément | Valeur |
|---|---|
| Source commit | `54ed713` |
| Branche | `ph148/onboarding-activation-replay` |
| Tag image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.148-shopify-official-logo-dev` |
| Digest | `sha256:92b2cf429909d9728a55709d760c545acf3b354771c602d5695a3fc2c65808ac` |
| Build args | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io` |
| Build from git | oui (clone propre bastion) |
| PROD build | **NON** |

---

## ÉTAPE 10 — Validation déploiement DEV

| Élément | Résultat |
|---|---|
| Pod | `keybuzz-client-6d5657db44-9wbfk` |
| Image | `v3.5.148-shopify-official-logo-dev` |
| Restarts | 0 |
| Logo PNG dans pod | `/app/public/marketplaces/shopify.png` (70528 bytes) **OK** |
| Logo SVG ancien | Toujours présent (fichier non supprimé) |
| Client PROD | `v3.5.147` inchangé |

---

## ÉTAPE 11 — Matrice finale

| Domaine | Status | Preuve | Gap | Phase suivante |
|---|---|---|---|---|
| **UI Shopify** | **PRÉSENT** | Client canaux, modale, catalogue, onboarding, billing | — | — |
| **OAuth** | **ABSENT** | Routes API 404, code source supprimé | Routes, services, crypto | Restauration API Shopify |
| **Sync orders** | **ABSENT** | Pas de shopifyOrders service dans API | Service, GraphQL, routes | Restauration API Shopify |
| **Webhooks** | **ABSENT** | Pas de route /webhooks/shopify | Routes, handlers, compliance | Restauration API Shopify |
| **Orders UI** | **PARTIEL** | 2 orders test DEV, 1 PROD | Pas de sync active | Restauration API Shopify |
| **Inbox/conversations** | **PARTIEL** | 1 conversation test | Pas de flux inbound Shopify | Restauration API Shopify |
| **17TRACK** | **NON TESTÉ** | Structure supportée, pas de données | Activation après sync | Phase future |
| **AI Assist** | **PARTIEL** | marketplace-channel-context OK | Pas de branchement spécifique | Fonctionne via contexte générique |
| **Autopilot** | **PARTIEL** | Contexte marketplace injecté | Pas de branchement spécifique | Fonctionne via contexte générique |
| **Refund protection** | **PARTIEL** | Posture `direct_seller_controlled` | Pas de branchement nommé Shopify | Fonctionne via posture |
| **Response strategy** | **PARTIEL** | Guidance seller-first correcte | Pas de branchement nommé Shopify | Fonctionne via posture |
| **Seller-first** | **OK** | `direct_seller_controlled` + guidance | — | — |
| **Logo officiel** | **OK** | PNG officiel Ludovic déployé DEV | — | Promotion PROD future |

---

## ÉTAPE 12 — Linear

Recommandation : créer/mettre à jour un ticket Shopify.

- **Titre** : Shopify — restauration API connector (routes, OAuth, sync, webhooks)
- **Description** : L'audit PH-SAAS-T8.12AJ révèle que les routes API Shopify ont été perdues lors des rebuilds (images v3.5.237→v3.5.137). Le client est complet mais les appels backend retournent 404. Les tables DB existent. Les secrets K8s sont en place. La restauration nécessite de réintégrer les fichiers source Shopify dans la branche API actuelle.
- **Référence** : `PH-SAAS-T8.12AJ-SHOPIFY-CONNECTOR-TRUTH-AUDIT-AND-OFFICIAL-LOGO-DEV-01.md`
- **Ne pas fermer** tant que Shopify n'est pas testé avec une vraie boutique contrôlée.

---

## Rollback DEV GitOps

**Rollback cible Client DEV** : `v3.5.146-sample-demo-platform-aware-dev`

Procédure (ne pas exécuter sauf incident) :
1. Modifier `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` → image `v3.5.146-sample-demo-platform-aware-dev`
2. Commit + push infra
3. `kubectl apply -f keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml`
4. `kubectl rollout status`

---

## Gaps restants

| # | Gap | Impact | Urgence | Phase suivante |
|---|---|---|---|---|
| G1 | Routes API Shopify absentes (OAuth, status, connect, disconnect, callback, webhooks, orders sync) | **CRITIQUE** — Shopify UI est un mirage, aucun appel backend ne fonctionne | P1 | Restauration source API Shopify depuis Git historique (branches v3.5.237+) |
| G2 | `app.ts` n'enregistre aucune route Shopify | CRITIQUE — même si les fichiers étaient restaurés, il faut aussi le wiring | P1 | Inclus dans G1 |
| G3 | `resolveOrderRefFromMessages` ne couvre pas les Shopify order IDs | Moyen — pas de fallback ordre pour conversations Shopify | P2 | Phase future après restauration |
| G4 | `refundProtectionLayer` et `responseStrategyEngine` n'ont pas de branchement Shopify nommé | Faible — fonctionne via posture `direct_seller_controlled` | P3 | Optionnel |
| G5 | Logo PROD non mis à jour | Faible — cosmétique, PROD a toujours l'ancien SVG | P3 | Inclus dans prochaine promotion PROD client |

---

## Risques

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Un utilisateur tente de connecter Shopify en PROD | Faible | Erreur silencieuse (BFF → 404) | Client devrait afficher "bientôt" ou bloquer si backend 404 |
| Restauration source Shopify crée des conflits | Moyenne | Casse build API | Cherry-pick fichier par fichier, pas merge branche entière |
| Secrets K8s expirent | Faible | Connexion impossible même après restauration | Vérifier validité des credentials Shopify Partner |

---

## Résumé technique

| Élément | Valeur |
|---|---|
| Phase | PH-SAAS-T8.12AJ |
| Client DEV | `v3.5.148-shopify-official-logo-dev` |
| Client PROD | `v3.5.147` (inchangé) |
| API DEV | `v3.5.144` (inchangé) |
| API PROD | `v3.5.137` (inchangé) |
| Digest client DEV | `sha256:92b2cf429909d9728a55709d760c545acf3b354771c602d5695a3fc2c65808ac` |
| Commit client | `54ed713` |
| Commit infra | `ef7038f` |
| Rollback client DEV | `v3.5.146-sample-demo-platform-aware-dev` |
| Chemin rapport | `keybuzz-infra/docs/PH-SAAS-T8.12AJ-SHOPIFY-CONNECTOR-TRUTH-AUDIT-AND-OFFICIAL-LOGO-DEV-01.md` |

---

## Verdict

### **GO PARTIEL — SHOPIFY PARTIAL RESTORE NEEDED**

**SHOPIFY CONNECTOR TRUTH ESTABLISHED — UI PRESENT BUT BACKEND/API RUNTIME ABSENT (ROUTES 404) — AI SELLER-FIRST PATH KNOWN (direct_seller_controlled) — OFFICIAL LOGO READY IN DEV — PROD UNCHANGED — DB TABLES PRESENT — K8S SECRETS PRESENT — API SOURCE RESTORATION REQUIRED FROM GIT HISTORY (v3.5.237+)**
