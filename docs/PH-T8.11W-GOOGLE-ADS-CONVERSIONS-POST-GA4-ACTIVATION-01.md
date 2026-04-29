# PH-T8.11W — Google Ads Conversions Post GA4 Activation

> **Date** : 28 avril 2026
> **KEY** : KEY-214
> **Objectif** : Configurer les conversions Google Ads après activation GA4 client
> **Prérequis** : PH-GA4-CLIENT-ACTIVATION-PROD-PROMOTION-01 (GA4 actif en PROD)

---

## 1. État post-activation GA4

### GA4 client PROD — Confirmé actif

| Élément | Statut |
|---|---|
| GA4 ID | `G-R3QQDYEBFG` — baked in client PROD `v3.5.122-ga4-activation-prod` |
| sGTM | `https://t.keybuzz.pro` — healthy (200 ok) |
| Cross-domain | Website `linker: ['keybuzz.pro', 'client.keybuzz.io']` → Client `accept_incoming: true` |
| Consent Mode v2 | `analytics_storage: granted`, `ad_storage: denied` |
| Funnel pages | `/register`, `/login` uniquement |
| Protected pages | `/dashboard`, `/inbox`, etc. — GA4 non chargé |

### Events GA4 disponibles (compilés, prêts à remonter)

| Event GA4 | Params | Déclenché depuis | Type Google Ads |
|---|---|---|---|
| `signup_start` | plan, cycle, funnel_step | `/register` | Observation |
| `signup_step` | step, plan | `/register` | Observation |
| `signup_complete` | plan, cycle, tenant_id, funnel_step | `/register` | **Conversion primaire (StartTrial)** |
| `begin_checkout` | currency(EUR), value, items[] | `/register` | Observation |
| `purchase` | transaction_id, currency(EUR), value, items[] | `/register/success` | **Conversion primaire (Purchase)** |

### Website GA4 — Comparaison

| Source | Events | Conversion events |
|---|---|---|
| `www.keybuzz.pro` (website) | `page_view` sur chaque route | Aucun |
| `client.keybuzz.io` (client) | `page_view` initial + 5 funnel events | `signup_complete`, `purchase` |

---

## 2. Google Ads — Diagnostic observable

### Identifiants

| Élément | Valeur |
|---|---|
| Google Ads Customer ID | `5947963982` |
| Google Ads Conversion ID | `AW-18098643667` |
| GA4 Measurement ID | `G-R3QQDYEBFG` |

### Tags installés

| Tag | Client | Website |
|---|---|---|
| GA4 `G-R3QQDYEBFG` via sGTM | ✅ | ✅ |
| Google Ads `AW-18098643667` direct | ❌ absent (by design) | ❌ absent (by design) |

### Conversions Google Ads existantes

- **Aucune conversion** n'est actuellement remontée à Google Ads
- 0 destination `google_ads` dans `outbound_conversion_destinations`
- 0 delivery log Google Ads
- Google Ads affiche "0 conversions" — correct et honnête

### Warning YouTube

Le warning "Your website doesn't have a Google tag" sur `www.keybuzz.pro` :
- Concerne le tag direct `AW-18098643667` (pas GA4)
- **Persistera** même après import GA4 (c'est un check sur le tag AW, pas sur les conversions)
- **N'est pas bloquant** pour la diffusion YouTube
- Est un warning UX Google Ads, pas une erreur technique

---

## 3. Analyse anti-doublon

### Pipelines de conversion — Architecture complète

```
CLIENT-SIDE (via GA4)
  client.keybuzz.io/register
    → gtag('event', 'signup_complete', {...})
    → sGTM t.keybuzz.pro
    → GA4 G-R3QQDYEBFG
    → [Import GA4] → Google Ads  ← NOUVEAU (Option A)

SERVER-SIDE (via CAPI)
  keybuzz-api PROD
    → outbound_conversion_destinations
    → Meta CAPI     (StartTrial) — actif, 2 delivered
    → TikTok Events (StartTrial) — actif, 2 delivered
    → LinkedIn CAPI (StartTrial) — actif, 1 success
    → Google Ads    — AUCUNE destination
```

### Risque de doublon : ZÉRO

| Source | GA4 | Meta | TikTok | LinkedIn | Google Ads |
|---|---|---|---|---|---|
| Client-side (gtag) | ✅ | ❌ pixel inactif | ❌ pixel inactif | ❌ | ❌ |
| Server-side (CAPI) | — | ✅ CAPI | ✅ Events API | ✅ CAPI | ❌ |
| Import GA4 (futur) | — | — | — | — | ✅ |

Les pipelines sont 100% indépendants. Google Ads n'a aucune source existante → aucun doublon possible.

---

## 4. Décision

### **OPTION A — Import GA4 → Google Ads** ✅ Retenue

| Critère | Évaluation |
|---|---|
| Standard Google | ✅ Approche recommandée officiellement |
| Code change requis | **Aucun** |
| gclid linkage | Automatique via GA4 ↔ Google Ads linking |
| `purchase` reconnu | ✅ Event recommandé Google, valeur + devise incluses |
| Délai données | ~24h (acceptable pour YouTube awareness) |
| Risque doublon | Zéro |
| Complexité | Faible — 2 étapes dans les consoles Google |

### Pourquoi pas Option B (sGTM) ?

Option B (tag Google Ads Conversion dans sGTM) est techniquement viable mais :
- Nécessite de connaître les conversion labels Google Ads (créés dans la console)
- Nécessite un Conversion Linker tag additionnel dans sGTM
- Plus de maintenance long-terme
- Aucun avantage pour une campagne awareness (le temps réel n'est pas critique)

Option B reste disponible comme upgrade futur si le temps réel devient nécessaire.

---

## 5. Guide de configuration — Import GA4 → Google Ads

### Étape 1 — Lier GA4 à Google Ads

1. Ouvrir **GA4 Admin** → `G-R3QQDYEBFG`
2. Section **Product Links** → **Google Ads Links**
3. Cliquer **Link**
4. Sélectionner le compte Google Ads `5947963982`
5. Activer **Enable Personalized Advertising** (optionnel, peut rester off)
6. Confirmer le lien

> Si le lien existe déjà, passer à l'étape 2.

### Étape 2 — Importer les conversions GA4 dans Google Ads

1. Ouvrir **Google Ads** → compte `5947963982`
2. **Goals** → **Conversions** → **Summary**
3. Cliquer **+ New conversion action** → **Import** → **Google Analytics 4 properties**
4. Sélectionner la propriété `G-R3QQDYEBFG`
5. Importer les events suivants :

| Event GA4 | Action Google Ads | Category | Value |
|---|---|---|---|
| `signup_complete` | StartTrial (renommer) | Primary | Pas de valeur (ou 0) |
| `purchase` | Purchase (conserver) | Primary | Utiliser la valeur de l'event (`value` en EUR) |

6. Optionnel — importer en observation :

| Event GA4 | Action Google Ads | Category |
|---|---|---|
| `signup_start` | Lead / FunnelStart | Secondary |
| `begin_checkout` | BeginCheckout | Secondary |

7. Sauvegarder

### Étape 3 — Vérifier dans Google Ads (après ~24h)

1. **Goals** → **Conversions** → **Summary**
2. Vérifier que `signup_complete` et `purchase` apparaissent avec status "Recording"
3. Si un signup test a été effectué, vérifier qu'une conversion apparaît

### Vérifications supplémentaires

- **GA4 Realtime** : ouvrir `https://client.keybuzz.io/register`, vérifier qu'un `page_view` apparaît
- **GA4 Events** : après un parcours `/register`, vérifier que `signup_start` apparaît dans GA4 → Reports → Realtime
- **Google Ads Warning** : le warning "missing Google tag" sur `www.keybuzz.pro` **persistera** — c'est attendu et non bloquant

---

## 6. Paramètres GA4 utiles pour Google Ads

### `purchase` event (conforme au standard Google)

```javascript
gtag('event', 'purchase', {
  transaction_id: 'stripe-session-id',    // déduplication
  currency: 'EUR',                         // devise
  value: 97,                               // montant
  items: [{ item_name: 'KeyBuzz Pro', price: 97 }]
});
```

Google Ads exploitera automatiquement `transaction_id` pour la déduplication, `value` + `currency` pour le ROAS.

### `signup_complete` event

```javascript
gtag('event', 'signup_complete', {
  plan: 'pro',
  cycle: 'monthly',
  tenant_id: 'tenant-xxx',
  funnel_step: 'account_created'
});
```

Google Ads verra cet event comme une conversion de type "Lead". La valeur peut être ajoutée ultérieurement si nécessaire.

---

## 7. Impact sur le warning YouTube

| Avant | Après import GA4 |
|---|---|
| Warning "missing Google tag" sur `www.keybuzz.pro` | **Identique** — le warning concerne le tag `AW-`, pas GA4 |
| 0 conversions Google Ads | Conversions visibles (~24h après le premier event) |
| YouTube diffusion | ✅ Non bloquée | ✅ Non bloquée |
| YouTube optimization | Awareness uniquement (pas de bid sur conversions) | Peut optimiser sur conversions importées |

Le warning disparaîtrait uniquement en installant le tag `AW-18098643667` sur `www.keybuzz.pro` — ce qui est interdit par design. Le warning est cosmétique et n'impacte ni la diffusion ni la mesure des conversions.

---

## 8. Validation technique

| Check | Résultat |
|---|---|
| GA4 events compilés dans PROD | ✅ 5 events (`signup_start` → `purchase`) |
| sGTM `t.keybuzz.pro` | ✅ Healthy (200 ok) |
| Cross-domain website → client | ✅ Configuré et actif |
| gclid capturés | ✅ 3 attributions Google dans `signup_attribution` |
| `AW-` absent client | ✅ 0 fichiers |
| `AW-` absent website | ✅ 0 fichiers |
| CAPI Meta/TikTok/LinkedIn | ✅ 3 destinations actives, non impactées |
| Metrics KeyBuzz | ✅ Non pollué — GA4 est indépendant |
| Double conversion | ✅ Zéro risque — aucun overlap |

---

## 9. KEY-214 — Mise à jour

| Champ | Valeur |
|---|---|
| Chemin choisi | **Option A — Import GA4 → Google Ads** |
| Events GA4 disponibles | `signup_complete` (StartTrial), `purchase` (Purchase) + 3 secondaires |
| Conversions Google Ads existantes | Aucune (vérification console requise) |
| Warning YouTube | Persistera (concerne `AW-` tag, non bloquant) |
| Risques | Délai 24h données, vérification manuelle GA4 linking requise |
| Tag direct `AW-` | ✅ **Non ajouté** — confirmé absent (0 fichiers) |
| Code PROD modifié | **Aucun** (cette phase est 100% config externe) |
| Actions manuelles requises | 2 : GA4 linking + Google Ads import (guide section 5) |

---

## 10. Verdict

```
OPTION A — IMPORT GA4 → GOOGLE ADS — GO (CONFIG MANUELLE REQUISE)
```

| Critère | Statut |
|---|---|
| GA4 client actif | ✅ PROD `v3.5.122-ga4-activation-prod` |
| Events conversion disponibles | ✅ `signup_complete`, `purchase` |
| Pipeline anti-doublon | ✅ Zéro overlap avec CAPI |
| Tag `AW-` non installé | ✅ Confirmé |
| CAPI non régressé | ✅ |
| Code PROD modifié | ✅ **Aucun** |
| Config manuelle documentée | ✅ Guide 3 étapes section 5 |
| Warning YouTube documenté | ✅ Non bloquant, persistant |

### Actions Ludovic

1. **GA4 Admin** → Lier `G-R3QQDYEBFG` au compte Google Ads `5947963982`
2. **Google Ads** → Goals → Import → GA4 → `signup_complete` (Primary) + `purchase` (Primary)
3. **Vérifier** après ~24h que les conversion actions apparaissent en status "Recording"
