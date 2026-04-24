# Guide Tracking — KeyBuzz.pro

## Pour Media Buyer & Agence

**Date** : 16 avril 2026
**Site** : [https://www.keybuzz.pro](https://www.keybuzz.pro)
**SaaS** : [https://client.keybuzz.io](https://client.keybuzz.io)

---

## 1. Outils de tracking installés


| Outil              | ID                 | Statut        |
| ------------------ | ------------------ | ------------- |
| Google Analytics 4 | `G-R3QQDYEBFG`     | Actif en PROD |
| Meta Pixel         | `1234164602194748` | Actif en PROD |


---

## 2. Funnel de conversion

```
Ads (Meta / Google / TikTok / etc.)
  ↓
keybuzz.pro (site vitrine)          ← tracking GA4 + Meta Pixel
  ↓
keybuzz.pro/pricing (page tarifs)   ← events: view_pricing, select_plan
  ↓
CTA "Commencer" / "Essai gratuit"  ← event: click_signup (Lead)
  ↓
client.keybuzz.io/register          ← UTM/gclid/fbclid transmis dans l'URL
  ↓
Inscription + Paiement Stripe
```

---

## 3. Events disponibles

### Google Analytics 4


| Event            | Déclencheur                                  | Type                               |
| ---------------- | -------------------------------------------- | ---------------------------------- |
| `page_view`      | Chaque page visitée                          | Automatique                        |
| `view_pricing`   | Visite de la page /pricing                   | Custom                             |
| `select_plan`    | Clic sur un plan (Starter / Pro / Autopilot) | Custom                             |
| `click_signup`   | Clic sur un CTA vers le SaaS                 | Custom — **conversion principale** |
| `contact_submit` | Soumission du formulaire contact             | Custom                             |
| `scroll`         | Défilement de page                           | Automatique (mesures améliorées)   |
| `first_visit`    | Première visite                              | Automatique                        |
| `session_start`  | Début de session                             | Automatique                        |


#### Paramètres custom envoyés avec les events


| Event            | Paramètres                                                     |
| ---------------- | -------------------------------------------------------------- |
| `select_plan`    | `plan` (starter / pro / autopilot), `cycle` (monthly / yearly) |
| `click_signup`   | `label` (nom du plan)                                          |
| `view_pricing`   | `category` = engagement                                        |
| `contact_submit` | `category` = conversion                                        |


### Meta Pixel


| Event Pixel                             | Déclencheur                   | Équivalent GA4 |
| --------------------------------------- | ----------------------------- | -------------- |
| `PageView`                              | Chaque page visitée           | page_view      |
| `ViewContent` (content_name: pricing)   | Visite de /pricing            | view_pricing   |
| `InitiateCheckout` (content_name: plan) | Clic sur un plan              | select_plan    |
| `Lead` (content_name: plan)             | Clic CTA vers SaaS            | click_signup   |
| `Contact`                               | Soumission formulaire contact | contact_submit |


---

## 4. Paramètres UTM supportés

Le site capture et transmet automatiquement les paramètres suivants vers le SaaS lors du clic CTA :


| Paramètre      | Usage                | Exemple                             |
| -------------- | -------------------- | ----------------------------------- |
| `utm_source`   | Source du trafic     | `facebook`, `google`, `tiktok`      |
| `utm_medium`   | Type de média        | `cpc`, `social`, `email`            |
| `utm_campaign` | Nom de campagne      | `launch-q2-2026`, `retargeting-pro` |
| `utm_term`     | Mot-clé (Google Ads) | `support+marketplace`               |
| `utm_content`  | Variante créative    | `video-a`, `carousel-b`             |
| `gclid`        | Google Ads click ID  | Automatique                         |
| `fbclid`       | Facebook click ID    | Automatique                         |


### Exemple d'URL de campagne

```
https://www.keybuzz.pro/pricing?utm_source=facebook&utm_medium=cpc&utm_campaign=launch-q2-2026&utm_content=video-a
```

Quand l'utilisateur clique sur un CTA, il est redirigé vers :

```
https://client.keybuzz.io/register?plan=pro&cycle=monthly&utm_source=facebook&utm_medium=cpc&utm_campaign=launch-q2-2026&utm_content=video-a
```

---

## 5. Cross-domain

GA4 est configuré pour le suivi cross-domain entre :

- `keybuzz.pro` (site vitrine)
- `client.keybuzz.io` (SaaS)

Un même utilisateur qui passe du site au SaaS est comptabilisé comme **une seule session** dans GA4.

---

## 6. Comment accéder aux données

### Google Analytics 4

- **URL** : [https://analytics.google.com](https://analytics.google.com)
- **Compte** : KeyBuzz
- **Propriété** : KeyBuzz
- **ID de mesure** : `G-R3QQDYEBFG`

#### Rapports utiles

- **Temps réel** : voir les événements en direct
- **Acquisition > Vue d'ensemble** : voir les sources de trafic (utm_source)
- **Engagement > Événements** : voir tous les events et leurs volumes
- **Engagement > Pages et écrans** : voir les pages les plus visitées

#### Accès pour Media Buyer / Agence

Le propriétaire du compte GA4 doit ajouter l'adresse email du Media Buyer / Agence :

1. Admin → Gestion des accès au compte
2. Ajouter l'adresse email
3. Rôle recommandé : **Lecteur** (consultation uniquement) ou **Analyste** (consultation + création de rapports)

### Meta Pixel

- **URL** : [https://business.facebook.com/events_manager](https://business.facebook.com/events_manager)
- **Pixel ID** : `1234164602194748`
- **Business** : KeyBuzz Consulting LLP

#### Accès pour Media Buyer / Agence

Dans Meta Business Manager :

1. Paramètres de l'entreprise → Partenaires
2. Ajouter le Business Manager ID du partenaire
3. Partager le Pixel avec le rôle approprié

---

## 7. Convention de nommage recommandée

Pour distinguer les campagnes du Media Buyer et de l'Agence, utiliser une convention dans `utm_campaign` :


| Acteur          | Préfixe utm_campaign | Exemple                                       |
| --------------- | -------------------- | --------------------------------------------- |
| Media Buyer     | `mb-`                | `mb-launch-q2-meta`, `mb-retargeting-google`  |
| Agence          | `ag-`                | `ag-branding-tiktok`, `ag-awareness-linkedin` |
| Interne KeyBuzz | `kb-`                | `kb-newsletter-april`, `kb-organic-linkedin`  |


Cela permet de filtrer facilement dans GA4 :

- Rapport > Acquisition > Filtre sur `utm_campaign` contient `mb-` → campagnes Media Buyer
- Rapport > Acquisition > Filtre sur `utm_campaign` contient `ag-` → campagnes Agence

---

## 8. Pages de destination recommandées


| Page     | URL                                | Quand l'utiliser          |
| -------- | ---------------------------------- | ------------------------- |
| Accueil  | `https://www.keybuzz.pro`          | Branding / awareness      |
| Pricing  | `https://www.keybuzz.pro/pricing`  | Conversion directe        |
| Services | `https://www.keybuzz.pro/features` | Considération / éducation |
| Contact  | `https://www.keybuzz.pro/contact`  | Génération de leads       |
| Amazon   | `https://www.keybuzz.pro/amazon`   | Ciblage vendeurs Amazon   |


---

## 9. Points importants

1. **Les UTM sont obligatoires** sur toutes les URLs de campagne pour un tracking correct
2. **gclid et fbclid** sont capturés automatiquement — pas besoin de les ajouter manuellement
3. **Ne pas utiliser de raccourcisseurs d'URL** (bit.ly, etc.) qui suppriment les paramètres UTM
4. **Le pixel Meta et GA4 se déclenchent sur toutes les pages** — pas besoin de configuration supplémentaire pour les nouvelles pages
5. **Les conversions GA4** (`click_signup`, `contact_submit`) seront marquées comme événements clés d'ici 24-48h dans l'interface GA4
6. **Le tracking server-side (Addingwell/CAPI)** n'est pas encore en place — c'est une évolution future qui améliorera la précision des données

---

## 10. Résumé pour lancer une campagne

```
1. Construire l'URL avec UTM :
   https://www.keybuzz.pro/pricing?utm_source=facebook&utm_medium=cpc&utm_campaign=mb-launch-q2

2. Vérifier avec Meta Pixel Helper que le pixel se déclenche

3. Vérifier dans GA4 Temps réel que les events remontent

4. Lancer la campagne

5. Suivre les résultats dans :
   - GA4 → Acquisition → Vue d'ensemble
   - Meta Events Manager → Events → conversions
```

