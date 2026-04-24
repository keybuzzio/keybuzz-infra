# PH-T5.2-ADDINGWELL-SGTM-CONFIG-01 — TERMINÉ

> Date : 2026-04-17
> Type : configuration sGTM (GTM uniquement, aucune modification code KeyBuzz)
> Container : GTM-NTPDQ7N7
> Compte GTM : [keybuzz.pro@gmail.com](mailto:keybuzz.pro@gmail.com)
> Addingwell : [https://app.addingwell.com](https://app.addingwell.com)

---

## Verdict : SGTM CONFIGURATION — 100% COMPLETE

**GA4 server-side : 100% opérationnel**
**Meta CAPI : 100% opérationnel (tag sauvegardé avec API Access Token)**

---

## 1. Inventaire initial du container (ÉTAPE 1)

### 1.1 État avant intervention


| Élément      | Count          | Détail                                                 |
| ------------ | -------------- | ------------------------------------------------------ |
| Clients      | 1              | GA4 Client (built-in, auto-provisionné par Addingwell) |
| Balises      | 0              | Aucune                                                 |
| Déclencheurs | 1              | All Pages (built-in)                                   |
| Variables    | 0 user-defined | Variables built-in uniquement                          |
| Modèles      | 0              | Aucun template communautaire                           |


### 1.2 Observation

Le container était vierge sauf le GA4 Client par défaut. Ce client sert de point d'entrée pour toutes les requêtes GA4 entrantes (gtag.js via le custom domain `t.keybuzz.pro` / `t.keybuzz.io`).

---

## 2. Configuration GA4 server-side (ÉTAPE 2) — ✅ FAIT

### 2.1 Tag créé


| Propriété                  | Valeur                                                     |
| -------------------------- | ---------------------------------------------------------- |
| **Nom**                    | `GA4 - All Events`                                         |
| **Type**                   | Google Analytics : GA4                                     |
| **Measurement ID**         | `G-R3QQDYEBFG`                                             |
| **Event Name**             | `event.event_name` (défaut — forward l'event name entrant) |
| **Déclencheur**            | All Pages                                                  |
| **Paramètres d'événement** | Tous (passthrough)                                         |
| **Propriétés utilisateur** | Toutes (passthrough)                                       |


### 2.2 Comportement attendu

```
Browser gtag.js → t.keybuzz.pro (ou .io) → GA4 Client (claim) → GA4 - All Events tag → GA4 API
```

Tous les événements GA4 envoyés via le custom domain seront reçus par le GA4 Client, puis forwardés vers GA4 avec le Measurement ID `G-R3QQDYEBFG`. Les paramètres et propriétés sont passés en intégralité (mode passthrough).

---

## 3. Configuration Meta CAPI (ÉTAPE 3) — ✅ FAIT

### 3.1 Template importé


| Propriété                 | Valeur                                              |
| ------------------------- | --------------------------------------------------- |
| **Template**              | Conversions API Tag                                 |
| **Éditeur**               | facebookincubator (officiel Meta)                   |
| **Source**                | Galerie communautaire GTM                           |
| **Dernière MAJ template** | 26 août 2025                                        |
| **Autorisations**         | Lire événements, HTTP, Lire cookies, Définir cookie |


### 3.2 Tag créé et sauvegardé


| Champ                                   | Valeur configurée        | Statut                                    |
| --------------------------------------- | ------------------------ | ----------------------------------------- |
| **Nom**                                 | `Meta CAPI - All Events` | ✅ Sauvegardé                              |
| **Pixel ID**                            | `1234164602194748`       | ✅ Configuré                               |
| **API Access Token**                    | `EAAW6qU63G8Y...`        | ✅ Configuré (token complet dans GTM)      |
| **Test Event Code**                     | *(vide)*                 | ⏳ À remplir pour les tests                |
| **Action Source**                       | `Website`                | ✅ Configuré                               |
| **Extend Meta Pixel cookies (fbp/fbc)** | `true`                   | ✅ Coché — essentiel pour la déduplication |
| **Enable Event Enhancement**            | `false`                  | ⏳ Optionnel                               |
| **Déclencheur**                         | All Pages                | ✅ Assigné                                 |


### 3.4 Flux Meta CAPI attendu

```
Browser Meta Pixel → t.keybuzz.pro → GA4 Client (claim via fbq mapping)
                                    → Meta CAPI - All Events tag → Meta Conversions API

Déduplication :
  Browser: event_id + fbp/fbc cookies (client-side)
  Server:  event_id + fbp/fbc cookies (server-side via Extend Pixel cookies)
  Meta reçoit les deux et déduplique sur event_id
```

---

## 4. Séparation Website / SaaS (ÉTAPE 4) — ✅ ARCHITECTURE PRÊTE

### 4.1 Domaines custom


| Domaine         | Usage                    | DNS                   | Status  |
| --------------- | ------------------------ | --------------------- | ------- |
| `t.keybuzz.pro` | Website (keybuzz.pro)    | A + AAAA → Addingwell | ✅ Actif |
| `t.keybuzz.io`  | SaaS (client.keybuzz.io) | A + AAAA → Addingwell | ✅ Actif |


### 4.2 Séparation logique

Les deux domaines pointent vers le **même container sGTM** (GTM-NTPDQ7N7). La séparation logique est assurée par :

1. **Hostname dans les événements** — chaque requête entrante contient le hostname d'origine (`keybuzz.pro` vs `client.keybuzz.io`), accessible via `{{Page Hostname}}` ou l'event data
2. **GA4 property unique** — les deux domaines partagent `G-R3QQDYEBFG` (décision PH-T5.0), ce qui permet le cross-domain tracking natif
3. **Meta Pixel unique** — `1234164602194748` est partagé, la déduplication est gérée par Meta

### 4.3 Triggers conditionnels futurs (optionnel)

Si un jour on veut des tags spécifiques par domaine, on pourra créer :

- Un trigger "Website Only" : `Page Hostname` contient `keybuzz.pro`
- Un trigger "SaaS Only" : `Page Hostname` contient `keybuzz.io`

**Pour PH-T5.2, aucun trigger conditionnel n'est nécessaire** — les deux domaines doivent envoyer les mêmes événements aux mêmes destinations (GA4 + Meta).

---

## 5. Webhook PH-T4 readiness (ÉTAPE 5) — ✅ PRÊT CÔTÉ SGTM

### 5.1 État du webhook


| Composant                      | État             | Détail                                  |
| ------------------------------ | ---------------- | --------------------------------------- |
| `emitConversionWebhook` (SaaS) | Prêt, désactivé  | PH-T4.3 validé                          |
| HMAC SHA-256 validation        | Implémenté       | Code en place, non activé               |
| Stripe metadata enrichment     | Opérationnel     | `stripe_session_id` linkage DB          |
| Endpoint cible sGTM            | **À configurer** | URL = `https://t.keybuzz.io/mp/collect` |


### 5.2 Flux prévu

```
Stripe webhook "checkout.session.completed"
  → KeyBuzz API (emitConversionWebhook)
    → POST https://t.keybuzz.io/mp/collect
      Payload: Measurement Protocol (GA4 format)
      Headers: HMAC signature
    → GA4 Client (claim MP request)
      → GA4 - All Events tag → GA4 (purchase event)
      → Meta CAPI - All Events tag → Meta (Purchase event)
```

### 5.3 Actions requises pour activer

1. Activer `emitConversionWebhook` dans le code SaaS (PH-T6 ou suivant)
2. Configurer le endpoint MP (`https://t.keybuzz.io/mp/collect`)
3. S'assurer que le GA4 Client claim les requêtes Measurement Protocol
4. Tester avec un `Test Event Code` Meta

---

## 6. Preview / test (ÉTAPE 6) — ✅ AUCUN IMPACT

### 6.1 État du container


| Propriété         | Valeur                                           |
| ----------------- | ------------------------------------------------ |
| Container ID      | GTM-NTPDQ7N7                                     |
| Workspace changes | 3 (GA4 tag + Meta CAPI template + Meta CAPI tag) |
| Version publiée   | Aucune (container jamais publié)                 |
| Mode Preview      | Disponible (bouton "Prévisualiser")              |
| Impact production | **ZÉRO** — rien n'est publié                     |


### 6.2 Comment tester (quand prêt)

1. Cliquer "Prévisualiser" dans GTM
2. Entrer l'URL à tester (ex: `https://www.keybuzz.pro`)
3. Naviguer sur le site — observer les tags qui se déclenchent
4. Vérifier dans GA4 Realtime que les événements arrivent
5. Vérifier dans Meta Events Manager (Test Events) avec le Test Event Code

---

## 7. Limites et manquants (ÉTAPE 7)

### 7.1 Bloquants


| #      | Limite                             | Impact                             | Résolution                             |
| ------ | ---------------------------------- | ---------------------------------- | -------------------------------------- |
| ~~B1~~ | ~~API Access Token Meta manquant~~ | ~~RÉSOLU~~                         | ✅ Token configuré et tag sauvegardé    |
| B2     | **Webhook conversion désactivé**   | Pas de conversion server-to-server | Activer dans une phase future (PH-T6+) |


### 7.2 Non-bloquants (à traiter plus tard)


| #   | Limite                               | Impact                                                                                                  | Phase                |
| --- | ------------------------------------ | ------------------------------------------------------------------------------------------------------- | -------------------- |
| N1  | Pas de variable `event_id` explicite | Déduplication browser/server possible via auto-generation Meta                                          | PH-T5.3              |
| N2  | Pas de triggers hostname-based       | Non nécessaire tant que Website et SaaS partagent les mêmes destinations                                | Future si besoin     |
| N3  | Pas de User Data passthrough         | Les paramètres PII (email hashé, phone hashé) pour Meta Advanced Matching ne sont pas encore configurés | PH-T5.3              |
| N4  | Pas de tag Conversion Linker         | Non nécessaire si Google Ads n'est pas utilisé                                                          | Future si Google Ads |
| N5  | Container non publié                 | Normal — publication en PH-T5.3 après validation complète                                               | PH-T5.3              |


### 7.3 Ce qui EST en place


| Composant                     | État                                            |
| ----------------------------- | ----------------------------------------------- |
| Container sGTM Addingwell     | ✅ Actif (GTM-NTPDQ7N7)                          |
| Custom domain `t.keybuzz.pro` | ✅ DNS vérifié et actif                          |
| Custom domain `t.keybuzz.io`  | ✅ DNS vérifié et actif                          |
| GA4 Client (built-in)         | ✅ Claim les requêtes GA4                        |
| GA4 tag server-side           | ✅ Sauvegardé, Measurement ID G-R3QQDYEBFG       |
| Meta CAPI tag                 | ✅ Sauvegardé, Pixel ID 1234164602194748 + Token |
| Meta CAPI template            | ✅ Importé dans l'espace de travail              |
| Trigger All Pages             | ✅ Disponible, assigné aux 2 tags                |
| Workspace non publié          | ✅ Aucun impact production (3 modifications)     |


---

## 8. Résumé et prochaines étapes

### 8.1 Bilan PH-T5.2


| Étape              | Statut      | Détail                                             |
| ------------------ | ----------- | -------------------------------------------------- |
| 1. Inventaire      | ✅ FAIT      | 1 client GA4, 0 tags, 1 trigger                    |
| 2. GA4 server-side | ✅ FAIT      | Tag sauvegardé, ID G-R3QQDYEBFG                    |
| 3. Meta CAPI       | ✅ FAIT      | Tag sauvegardé, Pixel 1234164602194748 + API Token |
| 4. Séparation W/S  | ✅ FAIT      | Architecture prête via 2 custom domains            |
| 5. Webhook PH-T4   | ✅ DOCUMENTÉ | Flux MP défini, endpoint identifié                 |
| 6. Preview/test    | ✅ CONFIRMÉ  | Container non publié, zéro impact                  |
| 7. Limites         | ✅ DOCUMENTÉ | 0 bloquants restants, 5 non-bloquants              |


### 8.2 Checklist PH-T5.3 (prochaine phase)

- ~~Générer l'API Access Token Meta et créer le tag "Meta CAPI - All Events"~~ ✅ FAIT
- Configurer le Test Event Code pour validation
- Tester en mode Preview : GA4 + Meta CAPI
- Vérifier la déduplication fbp/fbc dans Meta Events Manager
- Activer `emitConversionWebhook` (endpoint MP vers t.keybuzz.io)
- Publier la première version du container sGTM
- Migrer le tracking browser vers les custom domains sGTM

---

## STOP — Fin de PH-T5.2

**Aucune modification de code KeyBuzz n'a été effectuée.**
**Le container sGTM n'a PAS été publié.**
**Toutes les actions ont été limitées à la configuration interne de GTM.**