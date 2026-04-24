# PH-T5.0-ADDINGWELL-ARCHITECTURE-DECISION-01 — TERMINÉ

> Date : 2026-04-17
> Type : décision d'architecture (analyse uniquement)
> Aucune modification effectuée — aucun build, aucun deploy

---

## Verdict : ADDINGWELL ARCHITECTURE DECIDED

**Option retenue : A — 1 container unique, 2 custom domains**

---

## 1. État actuel

### 1.1 Inventaire tracking


| Domaine                    | Stack actuel                                                                 | Events                                                                                                                                               | Conversion                                      | Server-side                         |
| -------------------------- | ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | ----------------------------------- |
| `keybuzz.pro` (website)    | GA4 `G-R3QQDYEBFG` + Meta Pixel `1234164602194748`                           | `page_view`, `view_pricing`, `select_plan`, `click_signup`, `contact_submit` + Meta `PageView`, `ViewContent`, `InitiateCheckout`, `Lead`, `Contact` | Intent uniquement (Lead = clic CTA)             | NON                                 |
| `client.keybuzz.io` (SaaS) | GA4 `G-R3QQDYEBFG` + Meta Pixel `1234164602194748` (funnel pages uniquement) | `signup_start`, `signup_step`, `signup_complete`, `begin_checkout` + Meta `Lead`, `CompleteRegistration`, `InitiateCheckout`                         | `purchase` / `Purchase` sur `/register/success` | Webhook prêt (PH-T4) mais désactivé |


### 1.2 Couches tracking validées (PH-T4.3)


| Couche                                                  | État            | Phase |
| ------------------------------------------------------- | --------------- | ----- |
| Capture attribution (UTM, gclid, fbclid, fbc, fbp, _gl) | Opérationnel    | PH-T1 |
| Storage browser (sessionStorage + localStorage backup)  | Opérationnel    | PH-T1 |
| Persistance DB (`signup_attribution`, 21 colonnes)      | Opérationnel    | PH-T2 |
| GA4 funnel events (5 events)                            | Opérationnel    | PH-T3 |
| Meta funnel events (4 events)                           | Opérationnel    | PH-T3 |
| SaaSAnalytics injection (layout, funnel-only)           | Opérationnel    | PH-T3 |
| Privacy (zero tracking pages protégées)                 | Conforme        | PH-T3 |
| Consent Mode v2                                         | Conforme        | PH-T3 |
| Cross-domain GA4 linker                                 | Conforme        | PH-T3 |
| Stripe metadata enrichment                              | Opérationnel    | PH-T4 |
| `stripe_session_id` linkage DB                          | Opérationnel    | PH-T4 |
| Webhook conversion (HMAC sha256)                        | Prêt, désactivé | PH-T4 |


### 1.3 Ce qui manque


| Manque                                    | Impact                                                          | Addingwell résout ?                 |
| ----------------------------------------- | --------------------------------------------------------------- | ----------------------------------- |
| GA4 + Meta = client-side uniquement       | Vulnérable aux adblockers, ITP, perte ~20-40% des événements    | OUI — server-side bypass            |
| Pas de Facebook CAPI                      | Meta ne voit que les events Pixel browser, attribution dégradée | OUI — Meta CAPI tag sGTM            |
| Pas de cookies first-party server-managed | Durée de vie cookies limitée (7j ITP Safari, blocage Firefox)   | OUI — FPID cookie via custom domain |
| Webhook conversion non connecté           | Le webhook PH-T4 est prêt mais n'a pas de destination           | OUI — Addingwell comme récepteur    |


---

## 2. Contraintes techniques

### 2.1 Cookies first-party


| Contrainte       | Détail                                                                                                                            |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Domaines séparés | `keybuzz.pro` et `keybuzz.io` sont deux TLD différents — impossible de partager un cookie                                         |
| ITP Safari       | Les cookies JS tiers sont limités à 7 jours sur Safari                                                                            |
| Solution         | Un custom domain par domaine principal : `t.keybuzz.pro` et `t.keybuzz.io`, chacun créant des cookies first-party sur son domaine |


### 2.2 Cross-domain GA4


| Contrainte      | Détail                                                                                                                       |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Linker actif    | Le GA4 cross-domain linker est déjà configuré côté client (`keybuzz.pro` ↔ `client.keybuzz.io`) avec `accept_incoming: true` |
| Paramètre `_gl` | Ajouté automatiquement par gtag.js lors du passage d'un domaine à l'autre                                                    |
| Server-side     | Le sGTM Addingwell peut maintenir la continuité de session via le même GA4 client                                            |


### 2.3 Attribution handoff


| Contrainte           | Détail                                                                                         |
| -------------------- | ---------------------------------------------------------------------------------------------- |
| UTM forwarding       | Les CTA `/pricing` transmettent déjà tous les UTM + gclid + fbclid dans l'URL vers `/register` |
| Attribution PH-T1    | Le module `attribution.ts` capture et stocke tout à l'arrivée sur le SaaS                      |
| DB persistence PH-T2 | Les UTM sont persistés en DB dès le `create-signup`                                            |
| Stripe linkage PH-T4 | Le `stripe_session_id` est lié à l'attribution en DB                                           |


### 2.4 Multi-tenant SaaS


| Contrainte                      | Détail                                                                           |
| ------------------------------- | -------------------------------------------------------------------------------- |
| Pages funnel = publiques        | `/register`, `/register/success`, `/login` — pas de données tenant sensibles     |
| Pages protégées = zero tracking | `/inbox`, `/dashboard`, `/orders`, `/settings` — aucun script tiers chargé       |
| Données tenant                  | Jamais envoyées dans les events GA4/Meta client-side                             |
| Webhook server-side             | Contient le `tenant_id` mais est envoyé server-to-server (pas exposé au browser) |


### 2.5 Addingwell = sGTM managé


| Fait technique | Détail                                                                      |
| -------------- | --------------------------------------------------------------------------- |
| Produit        | Google Tag Manager Server-Side (sGTM) hébergé et managé par Addingwell      |
| Infrastructure | Auto-scaling, multi-région, private network Google Cloud                    |
| Custom domains | 1 inclus, +10€/domaine supplémentaire                                       |
| Meta CAPI      | Tag dédié Addingwell avec deduplication automatique browser/server          |
| Pricing        | Pay-as-you-go à partir de 90€/mois pour 2M requêtes                         |
| Comptage       | Seules les requêtes entrantes sont comptées (pas les sorties vers GA4/Meta) |


---

## 3. Options Addingwell

### Option A — 1 container unique, 2 custom domains

```
keybuzz.pro (browser)
  → t.keybuzz.pro (custom domain)
      → Addingwell container unique
          → GA4 (server-side)
          → Meta CAPI
          → BigQuery (optionnel)

client.keybuzz.io (browser, funnel pages)
  → t.keybuzz.io (custom domain)
      → Addingwell container unique (même)
          → GA4 (server-side)
          → Meta CAPI

API KeyBuzz (server-side webhook PH-T4)
  → Addingwell container unique
      → Meta CAPI (purchase conversion offline)
```

- 1 workspace Addingwell
- 1 server container sGTM
- 2 custom domains : `t.keybuzz.pro` + `t.keybuzz.io`
- Routage par hostname dans les rules sGTM

### Option B — 2 containers séparés

```
keybuzz.pro (browser)
  → t.keybuzz.pro (custom domain)
      → Container 1 (website)
          → GA4 + Meta CAPI

client.keybuzz.io (browser, funnel pages)
  → t.keybuzz.io (custom domain)
      → Container 2 (SaaS)
          → GA4 + Meta CAPI
```

- 2 workspaces Addingwell (ou 1 workspace avec 2 containers)
- 2 server containers sGTM
- 1 custom domain par container
- Isolation totale

---

## 4. Comparaison


| Critère                        | Option A (1 container)                                | Option B (2 containers)                         |
| ------------------------------ | ----------------------------------------------------- | ----------------------------------------------- |
| **Simplicité setup**           | Moyen — routage hostname nécessaire                   | Simple — isolation naturelle                    |
| **Simplicité maintenance**     | Bon — 1 seul endroit à maintenir                      | Complexe — 2 configs à synchroniser             |
| **Coût mensuel**               | ~100€ (90€ + 10€ 2e domaine)                          | ~190€ (90€ × 2 + 10€)                           |
| **Risque d'erreur**            | Moyen — mauvais routage hostname                      | Faible — isolation                              |
| **Attribution cross-domain**   | Excellent — contexte partagé naturellement            | Difficile — pas de contexte partagé server-side |
| **Meta CAPI deduplication**    | Excellent — events browser + server dans le même flux | Complexe — dedup entre 2 containers             |
| **Performance**                | Bonne — requêtes partagées                            | Bonne — mais 2× infra                           |
| **Évolutivité**                | Très bonne — ajouter un domaine = +10€                | Moyenne — ajouter un container = +90€           |
| **Multi-tenant**               | Safe — hostname routing, pas de tenant data           | Safe — isolation                                |
| **Webhook conversion (PH-T4)** | Simple — 1 URL de destination                         | Ambiguë — quel container reçoit ?               |
| **Cohérence GA4**              | Totale — même propriété, même traitement              | Totale — même propriété                         |
| **Cohérence Meta**             | Totale — même pixel, même CAPI token                  | Totale — même pixel                             |
| **Debug sGTM preview**         | 1 preview mode                                        | 2 preview modes                                 |
| **Monitoring**                 | 1 dashboard                                           | 2 dashboards                                    |


---

## 5. Recommandation

### Option retenue : A — 1 container unique, 2 custom domains

### Pourquoi

1. **Même GA4 + même Meta Pixel** : les deux domaines utilisent les mêmes IDs tracking (`G-R3QQDYEBFG` et `1234164602194748`). Un container unique traite naturellement les events des deux domaines vers les mêmes destinations.
2. **Cross-domain = même funnel** : le parcours utilisateur est `keybuzz.pro → client.keybuzz.io`. Un container unique voit le parcours complet et maintient la continuité de session server-side.
3. **Meta CAPI deduplication** : le tag Meta CAPI d'Addingwell déduplique automatiquement les events browser et server en utilisant le même `event_id`. Avec un seul container, cette deduplication est native. Avec deux, il faudrait synchroniser les `event_id` entre containers.
4. **Webhook conversion (PH-T4)** : notre webhook `emitConversionWebhook` envoie un POST server-to-server. Avec un seul container, il y a une seule URL de destination. Avec deux, il faudrait router.
5. **Coût** : ~100€/mois vs ~190€/mois. Économie de ~1080€/an.
6. **Addingwell supporte explicitement le multi-domaine** dans un seul container via plusieurs custom domains.
7. **Maintenance** : un seul endroit pour les tags, triggers, variables sGTM. Pas de risque de désynchronisation entre deux containers.

### Risques acceptés


| Risque                     | Probabilité | Impact                                   | Mitigation                                                  |
| -------------------------- | ----------- | ---------------------------------------- | ----------------------------------------------------------- |
| Mauvais routage hostname   | Faible      | Moyen — events routés au mauvais domaine | Rules sGTM basées sur `page_hostname`, testables en preview |
| Complexité config initiale | Faible      | Faible — one-time setup                  | Documentation + tests preview avant publication             |


### Conditions de succès

1. DNS configuré correctement pour les 2 custom domains
2. Rules sGTM testées en preview mode avant publication
3. Meta CAPI access token configuré dans le container
4. Webhook PH-T4 URL pointant vers le container Addingwell

---

## 6. Design cible

### 6.1 Endpoint tracking


| Custom domain   | Domaine parent | Rôle                                                 |
| --------------- | -------------- | ---------------------------------------------------- |
| `t.keybuzz.pro` | `keybuzz.pro`  | Tracking website — cookie first-party `.keybuzz.pro` |
| `t.keybuzz.io`  | `keybuzz.io`   | Tracking SaaS — cookie first-party `.keybuzz.io`     |


Les deux pointent vers le même container Addingwell.

Le préfixe `t.` est choisi car :

- Court et non-descriptif (pas bloqué par les adblockers)
- Cohérent entre les deux domaines
- Pas dans les listes de blocage connues (`gtm`, `analytics`, `tracking`, `collect` sont connus)

### 6.2 Flux complets

#### Flux Website (acquisition)

```
Visiteur → keybuzz.pro/pricing
  ↓ browser gtag.js → server_container_url = t.keybuzz.pro
  ↓
  t.keybuzz.pro (DNS → Addingwell container)
  ↓ sGTM GA4 client reçoit le hit
  ↓ sGTM crée/maintient cookie FPID first-party (.keybuzz.pro)
  ↓
  ├→ GA4 tag : forward vers GA4 property G-R3QQDYEBFG
  ├→ Meta CAPI tag : forward vers Facebook CAPI (+ dedup avec Pixel browser)
  └→ (optionnel) BigQuery tag : archivage raw events
```

#### Flux SaaS (conversion funnel)

```
Visiteur → client.keybuzz.io/register?plan=pro&utm_source=meta
  ↓ SaaSAnalytics injecte gtag.js (funnel page)
  ↓ browser gtag.js → server_container_url = t.keybuzz.io
  ↓
  t.keybuzz.io (DNS → même Addingwell container)
  ↓ sGTM GA4 client reçoit le hit
  ↓ sGTM crée/maintient cookie FPID first-party (.keybuzz.io)
  ↓ Cross-domain : paramètre _gl reçu depuis keybuzz.pro → même session GA4
  ↓
  ├→ GA4 tag : forward events (signup_start, purchase, etc.)
  ├→ Meta CAPI tag : forward events (Lead, Purchase, etc.)
  └→ (optionnel) BigQuery
```

#### Flux Server-Side (webhook conversion PH-T4)

```
Stripe webhook (checkout.session.completed)
  ↓ API Fastify → handleCheckoutCompleted
  ↓ emitConversionWebhook(session)
  ↓ Lit attribution depuis signup_attribution DB
  ↓ Construit payload purchase
  ↓ POST → CONVERSION_WEBHOOK_URL (= endpoint Addingwell ou Make/Zapier)
  ↓ Header X-Webhook-Signature: sha256=<hmac>
  ↓
  Addingwell reçoit le webhook
  ↓ Meta CAPI : envoi purchase event avec fbc/fbclid/email
  ↓ GA4 Measurement Protocol : envoi purchase event server-side
  ↓ conversion_sent_at mis à jour en DB
```

### 6.3 Séparation logique dans sGTM


| Élément sGTM              | Stratégie                                                                     |
| ------------------------- | ----------------------------------------------------------------------------- |
| **Client GA4**            | 1 client unique — reçoit tous les hits GA4 des deux domaines                  |
| **Tags GA4**              | 1 tag GA4 — forward tous les events vers `G-R3QQDYEBFG`                       |
| **Tags Meta CAPI**        | 1 tag Meta CAPI — forward vers Pixel `1234164602194748`                       |
| **Triggers**              | Trigger principal : `Client Name = GA4` (tous les events)                     |
| **Variables**             | `page_hostname` pour identifier le domaine source si nécessaire               |
| **Rules conditionnelles** | Optionnel : tags spécifiques par hostname si besoin de traitement différencié |


### 6.4 Modification client nécessaire

Le passage en server-side nécessite une modification dans `SaaSAnalytics.tsx` (SaaS) et le GTM web du website :


| Modification                             | Fichier/Outil            | Changement                                                                               |
| ---------------------------------------- | ------------------------ | ---------------------------------------------------------------------------------------- |
| SaaS : ajouter `server_container_url`    | `SaaSAnalytics.tsx`      | `gtag('config', GA4_ID, { server_container_url: 'https://t.keybuzz.io' })`               |
| Website : ajouter `server_container_url` | GTM web ou inline script | `gtag('config', GA4_ID, { server_container_url: 'https://t.keybuzz.pro' })`              |
| SaaS : Meta Pixel → optionnel retrait    | `SaaSAnalytics.tsx`      | Si CAPI seul suffit, retirer `fbevents.js` pour performance (la dedup gère le cas mixte) |


### 6.5 DNS à configurer


| Enregistrement  | Type  | Valeur                                | Domaine                                |
| --------------- | ----- | ------------------------------------- | -------------------------------------- |
| `t.keybuzz.pro` | CNAME | (fourni par Addingwell lors du setup) | keybuzz.pro (Hetzner DNS ou registrar) |
| `t.keybuzz.io`  | CNAME | (fourni par Addingwell lors du setup) | keybuzz.io (Hetzner DNS ou registrar)  |


---

## 7. Stratégie de déploiement

### Phase 1 — Setup Addingwell + Website DEV (1-2h)


| Étape | Action                                                     | Risque       |
| ----- | ---------------------------------------------------------- | ------------ |
| 1.1   | Créer un compte Addingwell (plan Free ou Pay-as-you-go)    | Aucun        |
| 1.2   | Créer un workspace et un container sGTM                    | Aucun        |
| 1.3   | Configurer le custom domain `t.keybuzz.pro`                | Faible (DNS) |
| 1.4   | Configurer le GA4 client + GA4 tag dans sGTM               | Faible       |
| 1.5   | Configurer le Meta CAPI tag (access token nécessaire)      | Faible       |
| 1.6   | Tester en preview mode                                     | Aucun        |
| 1.7   | Connecter `preview.keybuzz.pro` (DEV website) au container | Faible       |
| 1.8   | Valider les events dans sGTM preview                       | Aucun        |


### Phase 2 — SaaS DEV (1-2h)


| Étape | Action                                                                       | Risque       |
| ----- | ---------------------------------------------------------------------------- | ------------ |
| 2.1   | Configurer le custom domain `t.keybuzz.io`                                   | Faible (DNS) |
| 2.2   | Modifier `SaaSAnalytics.tsx` : ajouter `server_container_url`                | Faible       |
| 2.3   | Build + deploy client DEV                                                    | Faible       |
| 2.4   | Tester le flux `/register` en preview sGTM                                   | Aucun        |
| 2.5   | Valider GA4 + Meta CAPI events dans sGTM                                     | Aucun        |
| 2.6   | Connecter webhook PH-T4 → endpoint Addingwell (si compatible) ou Make/Zapier | Moyen        |
| 2.7   | Tester le flow complet : website → SaaS → Stripe → webhook                   | Faible       |


### Phase 3 — PROD (1h, après validation humaine)


| Étape | Action                                                     | Risque |
| ----- | ---------------------------------------------------------- | ------ |
| 3.1   | Publier le container sGTM (sortir du preview mode)         | Moyen  |
| 3.2   | Configurer DNS PROD pour `t.keybuzz.pro` et `t.keybuzz.io` | Faible |
| 3.3   | Build + deploy client PROD avec `server_container_url`     | Moyen  |
| 3.4   | Build + deploy website PROD avec `server_container_url`    | Moyen  |
| 3.5   | Activer webhook PROD (`CONVERSION_WEBHOOK_ENABLED=true`)   | Faible |
| 3.6   | Monitorer 24h dans Addingwell dashboard + GA4 Realtime     | Aucun  |
| 3.7   | Validation Media Buyer                                     | Aucun  |


### Rollback par phase


| Phase   | Rollback                                                             |
| ------- | -------------------------------------------------------------------- |
| Phase 1 | Supprimer `server_container_url` du website → retour client-side pur |
| Phase 2 | Rollback client DEV → `v3.5.78-tracking-replay-on-valid-branch-dev`  |
| Phase 3 | Rollback client PROD + website PROD → images pré-Addingwell          |


---

## 8. Risques


| #   | Risque                                  | Probabilité | Impact                                        | Mitigation                                                                                              |
| --- | --------------------------------------- | ----------- | --------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| R1  | Mauvais routage hostname dans sGTM      | Faible      | Moyen — events mal tagués                     | Tester en preview mode avant publication, rules basées sur `page_hostname`                              |
| R2  | Double tracking (client + server)       | Moyen       | Faible — dedup automatique                    | Meta CAPI tag Addingwell déduplique via `event_id`. GA4 déduplique nativement                           |
| R3  | Perte attribution cross-domain          | Faible      | Élevé — funnel cassé                          | Le GA4 linker (`_gl`) continue de fonctionner. Le cookie FPID server-side améliore la situation         |
| R4  | Mauvaise config DNS                     | Faible      | Élevé — tracking down                         | Vérifier propagation DNS (5min-1h). Tester avant publication. Rollback = retirer `server_container_url` |
| R5  | Erreur cookie domain                    | Faible      | Moyen — cookies rejetés                       | Chaque custom domain est sous le TLD principal. Addingwell gère les cookies automatiquement             |
| R6  | Adblockers bloquent le custom domain    | Très faible | Moyen — perte partielle                       | Le préfixe `t.` est non-descriptif. L'option reverse-proxy DNS d'Addingwell bypass complètement         |
| R7  | Meta CAPI access token expiré           | Faible      | Élevé — CAPI down                             | Monitorer via Addingwell Tag Health. Token à renouveler périodiquement                                  |
| R8  | Webhook PH-T4 → Addingwell incompatible | Moyen       | Moyen — CAPI offline conversions non envoyées | Alternative : webhook → Make/Zapier → Meta CAPI directement. Ou GA4 Measurement Protocol                |
| R9  | Coût Addingwell dépassement requêtes    | Faible      | Faible — surcoût prévisible                   | Le trafic KeyBuzz est faible (~1000 sessions/mois). 2M requêtes incluses largement suffisant            |
| R10 | Consent Mode v2 / RGPD                  | Moyen       | Moyen — non-conformité                        | Le Consent Mode est déjà configuré (`ad_storage: denied`). Le server-side ne change pas le consentement |


---

## 9. Matrice de décision finale


| Question                           | Réponse                                                           |
| ---------------------------------- | ----------------------------------------------------------------- |
| Combien de containers Addingwell ? | **1**                                                             |
| Combien de custom domains ?        | **2** (`t.keybuzz.pro` + `t.keybuzz.io`)                          |
| Quel plan Addingwell ?             | Pay-as-you-go (90€/mois + 10€ 2e domaine = **100€/mois**)         |
| Quelle GA4 property ?              | `G-R3QQDYEBFG` (inchangé, même pour les deux domaines)            |
| Quel Meta Pixel ?                  | `1234164602194748` (inchangé, même pour les deux domaines)        |
| Webhook PH-T4 destination ?        | Addingwell endpoint ou Make/Zapier (à déterminer lors du setup)   |
| Conserver le Pixel browser Meta ?  | OUI en parallèle (dedup automatique), retrait optionnel plus tard |
| Conserver gtag.js browser ?        | OUI — requis pour envoyer les events au server container          |
| Modifier les events existants ?    | NON — les events GA4 et Meta restent identiques                   |
| Impact sur le SaaS fonctionnel ?   | ZERO — seul `SaaSAnalytics.tsx` et le build-arg changent          |


---

## 10. Prochaines phases


| Phase       | Description                                                   | Prérequis                   | Effort |
| ----------- | ------------------------------------------------------------- | --------------------------- | ------ |
| **PH-T5.1** | Créer compte Addingwell + container sGTM + custom domains DNS | PH-T5.0 (ce document)       | 1h     |
| **PH-T5.2** | Configurer GA4 + Meta CAPI tags dans sGTM + preview test      | PH-T5.1                     | 1h     |
| **PH-T5.3** | Modifier `SaaSAnalytics.tsx` + build/deploy client DEV        | PH-T5.2                     | 1h     |
| **PH-T5.4** | Modifier website GTM + build/deploy website DEV               | PH-T5.2                     | 1h     |
| **PH-T5.5** | Connecter webhook PH-T4 → Addingwell/Make                     | PH-T5.3                     | 1h     |
| **PH-T5.6** | Validation E2E DEV (website → SaaS → Stripe → CAPI)           | PH-T5.3 + PH-T5.4 + PH-T5.5 | 2h     |
| **PH-T5.7** | Promotion PROD                                                | PH-T5.6 validé              | 1h     |


---

## 11. Conclusion

**ADDINGWELL ARCHITECTURE DECIDED**

- **1 container unique** Addingwell avec **2 custom domains** (`t.keybuzz.pro` + `t.keybuzz.io`)
- Le funnel complet (website → SaaS → Stripe → conversion) est traité dans un seul flux server-side
- Meta CAPI avec deduplication automatique remplace la dépendance au Pixel browser seul
- Cookies first-party server-managed améliorent la durée de vie et la précision de l'attribution
- Le webhook conversion PH-T4 existant s'intègre naturellement comme source d'offline conversions
- Coût estimé : **100€/mois** (Pay-as-you-go + 2e domaine)
- Rollback à chaque phase : retrait du `server_container_url` → retour client-side pur
- Aucune modification du tracking existant — Addingwell est une couche additionnelle

Aucune modification effectuée. Analyse uniquement.

STOP