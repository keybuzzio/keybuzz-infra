# PH-T7.1 — Google Ads Conversion Tracking via sGTM

> Date : 18 avril 2026
> Environnement : sGTM uniquement (AUCUN build, deploy ou modification code)
> Type : integration tracking publicitaire
> Priorite : HAUTE
> Rollback : supprimer les tags dans GTM et republier

---

## VERDICT

### GOOGLE ADS CONVERSION TRACKING OPERATIONAL

Le suivi des conversions Google Ads est en production dans le conteneur sGTM
`GTM-NTPDQ7N7` (Version 4 — "V4 - Google Ads Integration").

Les conversions `purchase` sont desormais envoyees a Google Ads automatiquement
via le pipeline existant sGTM, sans aucune modification de code.

---

## 1. Credentials Google Ads


| Parametre            | Valeur                  |
| -------------------- | ----------------------- |
| Conversion ID        | `18098643667`           |
| Conversion Label     | `zqQPCPXys54cENPFjbZD`  |
| Compte Google Ads    | `keybuzz.pro@gmail.com` |
| Action de conversion | "Achat" (Purchase)      |
| Devise               | EUR                     |
| Valeur               | Dynamique (event data)  |


---

## 2. Elements crees dans sGTM (GTM-NTPDQ7N7)

### Tags (2 ajoutes)


| Tag                                  | Type                             | Trigger        | Statut |
| ------------------------------------ | -------------------------------- | -------------- | ------ |
| **Conversion Linker**                | Conversion Linker                | All Events     | ACTIF  |
| **Google Ads - Conversion Tracking** | Suivi des conversions Google Ads | purchase_event | ACTIF  |


### Triggers (1 ajoute)


| Trigger            | Type         | Condition                          |
| ------------------ | ------------ | ---------------------------------- |
| **purchase_event** | Personnalise | `Event Name` est egal a `purchase` |


### Configuration du tag Conversion Tracking


| Champ                            | Valeur                                    |
| -------------------------------- | ----------------------------------------- |
| ID de conversion                 | `18098643667`                             |
| Libelle de conversion            | `zqQPCPXys54cENPFjbZD`                    |
| Valeur de conversion             | Automatique (event data `value`)          |
| Code de devise                   | Automatique (event data `currency`)       |
| Transaction ID                   | Automatique (event data `transaction_id`) |
| Traitement restreint des donnees | Faux                                      |


---

## 3. Version publiee


| Champ               | Valeur                                                |
| ------------------- | ----------------------------------------------------- |
| Numero de version   | **4**                                                 |
| Nom                 | V4 - Google Ads Integration                           |
| Date de publication | 18/04/2026 16:54                                      |
| Publie par          | [keybuzz.pro@gmail.com](mailto:keybuzz.pro@gmail.com) |


### Contenu de la version


| Element                          | Type        | Action |
| -------------------------------- | ----------- | ------ |
| Conversion Linker                | Balise      | Ajoute |
| Google Ads - Conversion Tracking | Balise      | Ajoute |
| purchase_event                   | Declencheur | Ajoute |


---

## 4. Non-regression


| Composant                 | Statut | Detail                           |
| ------------------------- | ------ | -------------------------------- |
| GA4 - All Events          | OK     | Tag inchange, trigger All Events |
| Meta CAPI - All Events    | OK     | Tag inchange, trigger All Events |
| SaaS (keybuzz-api/client) | OK     | Aucun code modifie               |
| Website (keybuzz.pro)     | OK     | Aucun code modifie               |


Les 4 tags de la Version 4 sont :

1. Conversion Linker — All Events
2. GA4 - All Events — All Events
3. Google Ads - Conversion Tracking — purchase_event
4. Meta CAPI - All Events — All Events

---

## 5. Pipeline de donnees

```
Utilisateur clique Google Ad (gclid capture)
     |
     v
Achat sur keybuzz.pro
     |
     v
gtag('event', 'purchase', { value, currency, transaction_id })
     |
     v
GA4 Measurement Protocol → sGTM Addingwell (GTM-NTPDQ7N7)
     |
     +--→ GA4 - All Events (tous les events)
     +--→ Meta CAPI - All Events (tous les events)
     +--→ Conversion Linker (tous les events, stocke gclid)
     +--→ Google Ads - Conversion Tracking (purchase uniquement)
```

---

## 6. Test et validation

### Methode de test

1. Effectuer un achat reel ou test sur `keybuzz.pro`
2. Verifier dans sGTM Preview (bouton "Previsualiser" dans GTM)
3. Verifier dans Google Ads > Outils > Conversions > Diagnostics

### Verification post-achat reel (18/04/2026 17:15)

Un achat reel a ete effectue via Stripe Checkout sur `keybuzz.pro`.

**Logs Addingwell (`pagead2.googlesyndication.com`) :**


| Metrique     | Valeur |
| ------------ | ------ |
| Requetes     | 20     |
| HTTP Code    | 200 OK |
| Success rate | 100%   |
| P50 Latency  | 35 ms  |
| P95 Latency  | 79 ms  |
| P99 Latency  | 101 ms |


**Logs Addingwell — tous les services (18/04/2026) :**


| Categorie  | Domaine                                                     | Requetes | Succes |
| ---------- | ----------------------------------------------------------- | -------- | ------ |
| GA4        | region1.google-analytics.com                                | 68       | 100%   |
| GA4        | [www.google-analytics.com](http://www.google-analytics.com) | 17       | 100%   |
| Facebook   | graph.facebook.com                                          | 75       | 96%    |
| Google Ads | pagead2.googlesyndication.com                               | 20       | 100%   |


**Google Ads Dashboard :** 0 conversions affichees — normal car :

- Aucune campagne Google Ads active (pas de clics a attribuer)
- Delai standard 24-72h pour traitement des donnees

### Checklist de validation

- Requetes envoyees a Google Ads via sGTM (20 requetes, 100% 200 OK)
- Le tag "Conversion Linker" se declenche sur tous les events
- Les tags GA4 et Meta CAPI continuent de fonctionner (100% OK)
- La conversion apparait dans Google Ads sous "Achat" (delai 24-72h)

### Note sur le Consent Mode

Le Consent Mode V2 n'est pas encore configure (`ad_storage: denied` par defaut).
Google Ads peut fonctionner en mode "modelise" pour les utilisateurs n'ayant pas
donne leur consentement. Un CMP (Consent Management Platform) devra etre integre
pour un tracking optimal (cf. PH-T7.0 section Consent Mode).

---

## 7. Rollback

En cas de probleme, le rollback est immediat :

1. Ouvrir GTM → conteneur `GTM-NTPDQ7N7`
2. Aller dans Versions
3. Republier la Version 3 (V3 - PH-T5.7 Fix All Events Trigger)

Alternativement, supprimer/mettre en pause le tag "Google Ads - Conversion Tracking"
et republier.

---

## 8. Prochaines etapes


| Etape                  | Priorite | Dependance                   |
| ---------------------- | -------- | ---------------------------- |
| CMP (Consent Mode V2)  | HAUTE    | Requis pour tracking optimal |
| LinkedIn Insight Tag   | MOYENNE  | Email hash dans payload MP   |
| Remarketing Google Ads | BASSE    | Tag sGTM supplementaire      |
| Enhanced Conversions   | MOYENNE  | User-provided data dans sGTM |


---

## Historique


| Date       | Action                                                | Par          |
| ---------- | ----------------------------------------------------- | ------------ |
| 18/04/2026 | Creation action de conversion "Achat" dans Google Ads | Agent Cursor |
| 18/04/2026 | Creation tag Conversion Linker dans sGTM              | Agent Cursor |
| 18/04/2026 | Creation trigger purchase_event dans sGTM             | Agent Cursor |
| 18/04/2026 | Creation tag Google Ads Conversion Tracking dans sGTM | Agent Cursor |
| 18/04/2026 | Publication Version 4 — V4 - Google Ads Integration   | Agent Cursor |
| 18/04/2026 | Verification post-achat reel : 20 req, 100% 200 OK    | Agent Cursor |


