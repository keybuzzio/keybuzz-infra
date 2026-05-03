# PH-SAAS-T8.12AL — SHOPIFY DEV STORE E2E VALIDATION

> Date : 2026-05-03
> Verdict : **GO PARTIEL — APP REVIEW PENDING**
> Phase précédente : PH-SAAS-T8.12AK (API source restore → GO DEV)
> Bloqueur : App Shopify "KeyBuzz DEV" en cours d'examen par Shopify — bouton "Installer" grisé

---

## Résumé exécutif

La validation E2E avec OAuth réel Shopify sur le tenant `ecomlg-001` n'a **pas pu être complétée** car l'application Shopify "KeyBuzz DEV" est **en cours d'examen** par Shopify et l'installation est bloquée (bouton "Installer" grisé sur la page d'autorisation).

Tout ce qui est validable sans OAuth réel a été vérifié et est **fonctionnel** :
- Routes API actives (plus de 404)
- HMAC webhook vérifié (rejette correctement les signatures invalides/absentes)
- Config secrets DEV complète et correctement pointée vers DEV
- IA seller-first `direct_seller_controlled` pour Shopify
- Non-régression complète
- PROD strictement inchangée

### Preuve visuelle du bloqueur

L'écran Shopify affiche : *"Cette appli est en cours d'examen. KeyBuzz DEV doit être examinée par Shopify avant de pouvoir être installée."* — bouton "Installer" grisé, non cliquable.

---

## ÉTAPE 0 — Preflight

### Repos

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|------|-----------------|-------------------|------|-------|---------|
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `7af350f0` | Clean | **OK** |
| keybuzz-client (local) | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `195fe7cd` | — | **OK** |
| keybuzz-infra | `main` | `main` | `a4d1afe` | Clean | **OK** |

### Runtime

| Service | DEV image | PROD image | Manifest = runtime | Verdict |
|---------|-----------|------------|-------------------|---------|
| API | `v3.5.145-shopify-api-restore-dev` | `v3.5.137-conversation-order-tracking-link-prod` | OUI | **OK** |
| Client | `v3.5.148-shopify-official-logo-dev` | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | OUI | **OK** |
| Admin | — | `v2.11.37-acquisition-baseline-truth-prod` | OUI | **OK** |
| Website | — | `v0.6.8-tiktok-browser-pixel-prod` | OUI | **OK** |

---

## ÉTAPE 1 — Config Shopify DEV

| Config | Présente | Domaine / Masqué | Verdict |
|--------|----------|------------------|---------|
| `SHOPIFY_CLIENT_ID` | OUI | `77b26855...` | **OK** |
| `SHOPIFY_CLIENT_SECRET` | OUI | [REDACTED, len=38] | **OK** |
| `SHOPIFY_ENCRYPTION_KEY` | OUI | [REDACTED, len=64] | **OK** |
| `SHOPIFY_REDIRECT_URI` | OUI | `https://api-dev.keybuzz.io/shopify/callback` | **OK DEV** |
| `SHOPIFY_CLIENT_REDIRECT_URL` | OUI | `https://client-dev.keybuzz.io/channels` | **OK DEV** |
| Aucune URL PROD | — | Vérifié | **OK** |
| Secret PROD existe | OUI | Clés présentes (non utilisées en DEV) | **OK** |

---

## ÉTAPE 2 — État DB avant OAuth (ecomlg-001)

| Table | Count | Détail | Verdict |
|-------|-------|--------|---------|
| `shopify_connections` | 0 | Aucune connexion pour ecomlg-001 | **OK** |
| `orders(channel='shopify')` | 0 | Aucune commande Shopify pour ecomlg-001 | **OK** |
| `shopify_webhook_events` | 0 | Aucun webhook pour ecomlg-001 | **OK** |
| `conversations(channel='shopify')` | 1 | `conv-shopify-test-001` (donnée test avril) | **OK** |

### Données existantes (keybuzz-mnqnjna8, référence)

| Élément | Valeur |
|---------|--------|
| Connexion active | `keybuzz-dev.myshopify.com`, status=active, scopes OK |
| Token chiffré | OUI |
| Refresh token | OUI |
| Commandes Shopify | 2 (#1001 = $3229.95, #1002 = $749.95) |
| Webhooks reçus | 18 events (5 orders/create, 6 orders/updated, 3 app/uninstalled, 3 compliance) |

---

## ÉTAPE 3-5 — OAuth réel → BLOQUÉ

| Étape OAuth | Résultat | Verdict |
|-------------|----------|---------|
| Génération authUrl | OK — URL valide vers `keybuzz-dev.myshopify.com` | **OK** |
| State Redis (TTL 600s) | OK — stocké et récupérable | **OK** |
| Redirect URI vérifié | `api-dev.keybuzz.io` (pas PROD) | **OK** |
| Scopes demandés | `read_orders,read_customers,read_fulfillments,read_returns` | **OK** |
| Autorisation Shopify | **BLOQUÉ** — App en cours d'examen, bouton "Installer" grisé | **BLOQUÉ** |
| Callback | Non testé (bloqué avant) | **N/A** |
| Token exchange | Non testé | **N/A** |
| Connexion DB | Non créée | **N/A** |

### Cause du bloqueur

L'application Shopify "KeyBuzz DEV" (client_id `77b26855...`) est en statut **"en cours d'examen"** dans le Shopify Partner Dashboard. Shopify bloque l'installation de toute app non approuvée, y compris sur les dev stores, lorsque l'app a des scopes sensibles (`read_customers`, données protégées).

### Action requise

Compléter l'examen Shopify dans le Partner Dashboard :
1. Aller dans Partners > Apps > KeyBuzz DEV > API access
2. Compléter le formulaire "Protected customer data access"
3. Soumettre pour examen (ou activer pour les dev stores si possible)
4. Une fois approuvé, relancer cette phase avec OAuth réel

---

## ÉTAPE 6 — Sync commandes → BLOQUÉ

Impossible sans connexion OAuth active pour `ecomlg-001`. Les données existantes sur `keybuzz-mnqnjna8` confirment que le sync fonctionne (2 commandes importées, upsert idempotent, mapping correct).

---

## ÉTAPE 7 — Webhook Shopify DEV

| Test | Attendu | Résultat | Verdict |
|------|---------|----------|---------|
| HMAC invalide | 401 | `{"error":"HMAC verification failed"}` | **OK** |
| HMAC absent | 401 | `{"error":"Unauthorized"}` | **OK** |
| Route `/webhooks/shopify` active | 200/401 selon HMAC | Fonctionnelle | **OK** |
| Webhooks historiques (keybuzz-mnqnjna8) | Events reçus | 18 events (6 topics) | **OK** |
| Compliance webhooks | Présents | `customers/data_request`, `customers/redact`, `shop/redact` | **OK** |

---

## ÉTAPE 8 — UI Client DEV

| Vérification | Résultat | Verdict |
|-------------|----------|---------|
| Logo Shopify officiel (PNG) | Présent, 70 528 bytes | **OK** |
| Logo SVG ancien | Présent (fallback) | **OK** |
| Client DEV image | `v3.5.148-shopify-official-logo-dev` | **OK** |

Note : La page `/channels` affiche Shopify comme canal disponible mais non connecté pour `ecomlg-001` (normal, OAuth bloqué).

---

## ÉTAPE 9 — IA Seller-First Shopify

| Cas | Attendu | Observé | Verdict |
|-----|---------|---------|---------|
| `resolveMarketplaceContext("shopify")` | `direct_seller_controlled` | `direct_seller_controlled` | **OK** |
| `isMarketplace` | `false` | `false` | **OK** |
| `sellerGuidance` | Présent, seller-first | "Boutique propre (Shopify) — le vendeur contrôle sa politique, plus de marge commerciale, mais protéger la marge. Pas de risque A-to-Z." | **OK** |
| Amazon comparaison | `marketplace_strict` | `marketplace_strict` | **OK** |
| Email comparaison | `direct_seller_controlled` | `direct_seller_controlled` | **OK** |
| Pas de refund-first Shopify | Pas de promesse remboursement | Doctrine respectée | **OK** |
| Pas d'auto-send | Aucun message envoyé | 0 outbound 30min | **OK** |

### Note sur le dry-run IA avec commande

Le dry-run IA avec une vraie commande Shopify et tracking est **reporté** à la phase post-approbation Shopify. Les données existantes de `keybuzz-mnqnjna8` (2 commandes, webhooks HMAC validés) confirment que le pipeline order→IA fonctionne.

---

## ÉTAPE 10 — Tracking

Aucune commande Shopify pour `ecomlg-001`, pas de tracking à vérifier. Les commandes existantes (`keybuzz-mnqnjna8`) n'ont pas de tracking code (commandes non expédiées).

---

## ÉTAPE 11 — Non-régression

| Vérification | Résultat | Verdict |
|-------------|----------|---------|
| `/health` | `{"status":"ok"}` | **OK** |
| Conversations ecomlg-001 | 465 | **OK** |
| Orders ecomlg-001 (amazon) | 11 952 | **OK** |
| Billing ecomlg-001 | 200 | **OK** |
| Outbound 30min | 0 | **OK** |
| API PROD | `v3.5.137-conversation-order-tracking-link-prod` | **INCHANGÉ** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | **INCHANGÉ** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | **INCHANGÉ** |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | **INCHANGÉ** |
| 0 CAPI / 0 fake billing | Confirmé | **OK** |

---

## ÉTAPE 12 — Linear

### Bloc prêt à copier

**Titre** : Shopify — validation E2E boutique DEV bloquée par app review

**Description** :

```
## Contexte
- PH-SAAS-T8.12AJ : audit connecteur → API 404 détecté
- PH-SAAS-T8.12AK : API restaurée, routes fonctionnelles DEV
- PH-SAAS-T8.12AL : validation E2E tentée → BLOQUÉ par Shopify app review

## Bloqueur
L'app "KeyBuzz DEV" est en cours d'examen par Shopify.
Le bouton "Installer" est grisé sur la page d'autorisation.
Cause probable : scopes protégés (read_customers) nécessitent l'approbation Shopify.

## Ce qui fonctionne (vérifié)
- Routes API /shopify/* actives (200, plus de 404)
- HMAC webhook vérifié (401 sur signature invalide)
- Config DEV complète (secrets, redirect URIs DEV)
- IA seller-first : policyPosture=direct_seller_controlled
- DB prête (tables shopify_connections, shopify_webhook_events, orders)
- Non-régression OK, PROD inchangée

## Action requise
1. Compléter "Protected customer data access" dans Shopify Partner Dashboard
2. Soumettre pour examen / activer pour dev stores
3. Une fois approuvé : relancer PH-SAAS-T8.12AL.1 avec OAuth réel

## Référence
- Boutique test : keybuzz-dev.myshopify.com
- App DEV : KeyBuzz DEV (77b26855...)
- Tenant cible : ecomlg-001
```

---

## Gaps et actions suivantes

| Gap | Sévérité | Action requise | Phase |
|-----|----------|---------------|-------|
| App Shopify en cours d'examen | **P0 bloqueur** | Compléter le formulaire "Protected customer data access" dans Shopify Partner Dashboard | Manuel (Ludovic) |
| OAuth réel ecomlg-001 non testé | P1 | Relancer après approbation | PH-SAAS-T8.12AL.1 |
| Sync commandes ecomlg-001 non testé | P1 | Dépend OAuth | PH-SAAS-T8.12AL.1 |
| Webhooks réels non testés (ecomlg-001) | P2 | Dépend OAuth | PH-SAAS-T8.12AL.1 |
| IA dry-run avec vraie commande Shopify | P2 | Dépend sync | PH-SAAS-T8.12AL.1 |
| Tracking Shopify | P3 | Dépend commandes expédiées | Futur |

---

## Commits

| Repo | Commit | Description |
|------|--------|-------------|
| keybuzz-infra | Ce commit | Rapport uniquement, 0 code, 0 build, 0 deploy |

---

## Verdict

**GO PARTIEL — APP REVIEW PENDING**

SHOPIFY DEV CONNECTOR STRUCTURALLY VALIDATED — ALL ROUTES ACTIVE — HMAC VERIFIED — CONFIG DEV CORRECT — IA SELLER-FIRST DIRECT_SELLER_CONTROLLED CONFIRMED — OAUTH BLOCKED BY SHOPIFY APP REVIEW (INSTALLER BUTTON GREYED OUT) — 0 CODE CHANGE — 0 BUILD — 0 DEPLOY — PROD UNCHANGED — RESUME AFTER SHOPIFY APPROVAL AS PH-SAAS-T8.12AL.1
