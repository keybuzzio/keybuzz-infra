# Audit lecture seule — Module Amazon PrestaShop

**Date :** 2026-01-30  
**Périmètre :** Module Amazon PrestaShop + module ecomlgbridge  
**Source :** Dossier `KEYBUZZ_MIGRATION` (documentation interne, aucune modification).

---

## Source de l’audit

L’analyse s’appuie **uniquement** sur les fichiers du dossier **`C:\Users\ludov\Mon Drive\V3\KEYBUZZ_MIGRATION`** :

| Fichier | Contenu utilisé |
|---------|------------------|
| `07_PRESTASHOP.md` | Module ecomlgbridge, module Amazon, hook flow, cron, tables, problèmes connus, code controller stock.php |
| `03_SERVERS.md` | Chemins PrestaShop, structure modules, tables |
| `01_ARCHITECTURE.md` | Flux SaaS → PrestaShop → Amazon, composants |
| `05_AMAZON_SPAPI.md` | SP-API (côté SaaS) ; rate limits, erreurs, endpoints Listings/Reports — **pas** le code du module Amazon PrestaShop |
| `04_DATABASE.md` | Tables SaaS (amazon_stock_cache, tenant_amazon_*, etc.) ; pas de schéma des tables PrestaShop `ps_*` |
| `09_CODE_STRUCTURE.md` | Structure SaaS (prestashop/bridge.py) ; pas de code PHP PrestaShop |
| `10_BEST_PRACTICES.md` | Rate limits SP-API, sécurité, pièges SKU |
| `02_CREDENTIALS.md` | Référence bridge URL/token (sans secret en clair) |
| `00_PROMPT_AGENT.md` | Contexte migration KeyBuzz |

Aucune connexion SSH au serveur PrestaShop n’a été utilisée. Aucun fichier PHP du module Amazon (common-services) n’est présent dans KEYBUZZ_MIGRATION ; seuls le flux, le chemin du cron et les tables sont documentés dans `07_PRESTASHOP.md` et `03_SERVERS.md`.

---

## 1. Schéma de flux (ASCII)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  SAAS eComLG-Sync (65.21.243.139) — optionnel                               │
│  app/prestashop/bridge.py → POST /module/ecomlgbridge/stock                 │
│  Body: { "sku": "1PV87A#B19", "qty": 54 }   (07_PRESTASHOP.md)              │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  PrestaShop (65.109.146.218)                                                │
│  Racine: .../5fa3154018554fe79630a7c0d082187b.ecomlg.fr/  (07, 03)          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. Module ecomlgbridge                                                     │
│     modules/ecomlgbridge/controllers/front/stock.php                        │
│     → Vérifie X-Bridge-Token (Configuration::get('ECOMLG_BRIDGE_TOKEN'))   │
│     → SELECT id_product FROM ps_product WHERE reference = pSQL(sku)        │
│     → StockAvailable::setQuantity(id_product, 0, qty)                       │
│     → Réponse JSON { ok, sku, id_product, previous_qty, new_qty,           │
│                      hook_triggered: true }                                  │
│                                                                              │
│  2. PrestaShop déclenche hook actionUpdateQuantity                           │
│     → Module Amazon (common-services) écoute ce hook                        │
│     → INSERT INTO ps_marketplace_product_action  (07)                       │
│                                                                              │
│  3. Cron Amazon                                                              │
│     modules/amazon/functions/products_json.php                               │
│     Paramètres: cron_token, action=update, lang=fr, sp_mkp=1,               │
│                 no-price=1, extended-datas=0  (07)                           │
│     → Traite la queue → Envoi vers Amazon via leur API  (07)                │
│                                                                              │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Amazon                                                                      │
│  (API — type exact du module PrestaShop non détaillé dans KEYBUZZ_MIGRATION) │
│  Doc 05_AMAZON_SPAPI décrit SP-API côté SaaS (Listings, Reports).            │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Réponses factuelles (avec preuves dans KEYBUZZ_MIGRATION)

### 2.1 Mécanisme de synchronisation

| Question | Réponse | Preuve |
|----------|---------|--------|
| Le module Amazon PrestaShop pousse-t-il des **fichiers** (feeds XML/CSV) vers Amazon ? | **Non** documenté. | `07_PRESTASHOP.md` : « Cron Amazon traite la queue » puis « Envoi vers Amazon **via leur API** ». Aucune mention de génération de fichiers ou d’upload de feeds. |
| Utilise-t-il l’**API Amazon** directement ? | **Oui**. | `07_PRESTASHOP.md` : « Envoi vers Amazon via leur API ». |
| Ou un **mix** des deux ? | **API** comme mécanisme documenté ; mix non mentionné. | Même référence. |
| Quels **endpoints Amazon** sont utilisés (si visibles) ? | **Non visibles** dans KEYBUZZ_MIGRATION. | Aucun fichier PHP du module `amazon/` dans le dossier. `05_AMAZON_SPAPI.md` décrit les endpoints **SP-API côté SaaS** (Listings Items GET/PATCH, Reports), pas le code du module PrestaShop. |

**Conclusion :** **API** (documenté). Fichiers (feeds) non documentés pour le module Amazon PrestaShop.

---

### 2.2 Gestion des tâches

| Question | Réponse | Preuve |
|----------|---------|--------|
| Où sont définis les crons ? | Script PHP appelé en HTTP. | `07_PRESTASHOP.md` : « Cron de synchronisation » → `modules/amazon/functions/products_json.php`. `03_SERVERS.md` : même chemin. |
| Tâches planifiées internes PrestaShop ? | Le cron est un **script PHP** exposé en URL avec paramètres ; la **planification** (crontab, CloudPanel, EasyCron) n’est pas décrite. | `07_PRESTASHOP.md` : paramètres `?cron_token=xxx&action=update&lang=fr&sp_mkp=1&no-price=1&extended-datas=0`. |
| Scripts appelés par EasyCron ? | **Non documenté**. | Aucune mention d’EasyCron dans 07, 03 ou ailleurs. |
| Fréquence réelle des sync ? | **Non documentée** pour le cron PrestaShop. | 07 et 03 ne donnent pas d’intervalle (ex. 5 min, 1 h). |

**Fichiers référencés :**
- `modules/amazon/functions/products_json.php` — point d’entrée du cron (07, 03).

---

### 2.3 Flux stock / prix / catalogue

| Question | Réponse | Preuve |
|----------|---------|--------|
| Stock : unitaire (SKU par SKU) ou par lot ? | **Non détaillé** dans la doc. | Queue `ps_marketplace_product_action` (07) ; pas de description du traitement (unitaire ou batch) dans le cron. |
| Prix : comment traité ? | **Réduction de charge** recommandée côté cron. | `07_PRESTASHOP.md` : « no-price=1 », « extended-datas=0 (important pour perfs) ». « products_json.php avec extended-datas=1 surcharge le serveur ». |
| Catalogue (titres, images, descriptions) poussé ou seulement stock/prix ? | **Non documenté** pour le module Amazon PrestaShop. | 07 décrit uniquement le flux stock (ecomlgbridge : sku + qty ; hook → queue → API). |

---

### 2.4 Format des données

| Canal | Réponse | Preuve |
|-------|---------|--------|
| Fichiers générés (où, format) ? | **Non documenté** pour le module Amazon PrestaShop. | Aucune mention de génération de fichiers (XML/CSV) par le module dans 07 ou 03. |
| Si API : structures envoyées ? | **Non documentées** pour le module PrestaShop. | 05 décrit les structures SP-API **côté SaaS** (Listings GET/PATCH, Reports), pas le module common-services. |
| Queue ou batch ? | **Queue** côté PrestaShop. | `07_PRESTASHOP.md` : table `ps_marketplace_product_action` ; requête exemple avec `date_upd > NOW() - INTERVAL 1 HOUR`. |

---

### 2.5 Limites et garde-fous

| Question | Réponse | Preuve |
|----------|---------|--------|
| Où est géré le throttling ? | **Non documenté** pour le module Amazon PrestaShop. | 05 et 10 décrivent rate limits et throttle **côté SaaS** (SP-API 5 req/sec, throttle 1–2 req/sec). |
| Sleep / rate limit dans le module PrestaShop ? | **Non documenté**. | Aucune mention dans 07 ou 03. |
| Comportement en cas d’erreur Amazon ? | **Non documenté** pour le module. | 05 donne les codes HTTP et actions pour le **client SaaS**. |
| Retry ? | **Non documenté** pour le module. | Idem. |

---

### 2.6 Découplage / couplage

| Question | Réponse | Preuve |
|----------|---------|--------|
| Le module Amazon dépend-il directement de la DB PrestaShop ? | **Oui**. | 07, 03 : `ps_product`, `ps_stock_available`, `ps_marketplace_product_action`, tables `ps_amazon_*` (ps_amazon_configuration, ps_amazon_product, ps_amazon_product_option). |
| Dépend-il des hooks PrestaShop ? | **Oui**. | 07 : « Module Amazon écoute ce hook » (actionUpdateQuantity). Flux : bridge → setQuantity → hook → module → INSERT queue → cron. |
| Utilisable sans PrestaShop ? | **NON**. | Dépend de PrestaShop : DB `ps_*`, hooks, `StockAvailable`, `Configuration`, `ModuleFrontController`, `Db`, `pSQL`. Impossible en l’état hors PrestaShop. |

---

## 3. Points clés à retenir

### Réutilisable conceptuellement
- **Queue avant envoi** : table type `ps_marketplace_product_action` entre mise à jour stock et envoi marketplace.
- **Séparation bridge / module marketplace** : un module reçoit les mises à jour (HTTP), met à jour le stock, le moteur marketplace réagit au hook et pousse vers Amazon.
- **Paramètres du cron** : token, action, lang, marketplace (sp_mkp), no-price, extended-datas pour limiter charge et périmètre (07).

### À ne pas reproduire tel quel
- **Sécurité** : l’exemple de requête dans 07 utilise `pSQL(sku)` ; toute requête dynamique doit rester paramétrée / échappée.
- **Double envoi** : si bridge PrestaShop et SP-API direct sont utilisés en parallèle pour les mêmes SKUs, conflit possible (07). Utiliser **soit** le bridge **soit** SP-API direct.
- **SKU avec caractères spéciaux** : 07 signale que le module Amazon PrestaShop gère mal les SKU avec `#` (ex. 1PV87A#B19, risque de double listing). À gérer explicitement (encoding, règles métier).
- **Charge du cron** : 07 recommande toujours `extended-datas=0` ou `no-price=1` ; `extended-datas=1` surcharge le serveur.

### Spécifique PrestaShop
- Hooks (`actionUpdateQuantity`), tables `ps_*`, classes PrestaShop (`StockAvailable`, `Db`, `Configuration`, `ModuleFrontController`).
- Cron = script PHP appelé en HTTP avec query string (cron_token, etc.).
- Dépendance au cycle de vie et au schéma PrestaShop.

---

## 4. Risques si on copie tel quel

| Risque | Commentaire |
|--------|-------------|
| **Scalabilité** | Un cron PHP monolithique + une queue en DB peuvent devenir un goulot ; pas de notion de workers ou parallélisation dans la doc. |
| **Multi-tenant** | Architecture décrite pour un seul site PrestaShop ; pas de notion de tenant_id dans le flux 07. |
| **Dépendances** | Fort couplage DB et hooks PrestaShop ; évolution du core ou des modules peut casser le flux. |
| **Observabilité** | Pas de détail dans la doc sur logs, métriques, alertes en cas d’échec Amazon ou saturation de la queue. |

---

## 5. Fichiers référencés (tous issus de KEYBUZZ_MIGRATION)

### PrestaShop — chemins (07_PRESTASHOP.md, 03_SERVERS.md)
- Racine : `/home/ecomlg-cat-prestashop/htdocs/5fa3154018554fe79630a7c0d082187b.ecomlg.fr/`
- **ecomlgbridge :** `modules/ecomlgbridge/ecomlgbridge.php`, `modules/ecomlgbridge/controllers/front/stock.php`, `modules/ecomlgbridge/config.xml`
- **Amazon :** `modules/amazon/`, `modules/amazon/functions/products_json.php`
- Config : `config/settings.inc.php`
- Logs : `var/logs/dev.log` (chemin tronqué dans 07)

### Tables PrestaShop (07, 03)
- `ps_product`, `ps_stock_available`, `ps_amazon_configuration`, `ps_amazon_product`, `ps_amazon_product_option`, `ps_marketplace_product_action`

### Documentation KEYBUZZ_MIGRATION utilisée
- `00_PROMPT_AGENT.md`, `01_ARCHITECTURE.md`, `02_CREDENTIALS.md`, `03_SERVERS.md`, `04_DATABASE.md`, `05_AMAZON_SPAPI.md`, `06_FTP_CSV.md`, `07_PRESTASHOP.md`, `09_CODE_STRUCTURE.md`, `10_BEST_PRACTICES.md`

### Code cité dans la doc (extrait 07)
- Classe `EcomlgbridgeStockModuleFrontController` dans `stock.php` : vérification token, lecture body JSON (sku, qty), requête `ps_product` par reference, `StockAvailable::setQuantity`, réponse JSON (07_PRESTASHOP.md).

---

## Confirmation obligatoire

> Analyse effectuée en lecture seule.  
> Source : dossier KEYBUZZ_MIGRATION uniquement.  
> Aucun fichier, base de données ou configuration n’a été modifié.  
> Aucun script ni cron n’a été exécuté. Aucun appel API Amazon n’a été effectué.
