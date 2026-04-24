# Cartographie Tracking — Website vs SaaS

**Date** : 16 avril 2026
**Objectif** : Définir clairement quel agent gère quel domaine, quelles URLs, et quels events de tracking.

---

## 1. Deux domaines, deux agents


| Domaine             | Agent responsable | Rôle                                           |
| ------------------- | ----------------- | ---------------------------------------------- |
| `keybuzz.pro`       | **Agent Website** | Site vitrine, acquisition, intent              |
| `client.keybuzz.io` | **Agent SaaS**    | Application, inscription, paiement, conversion |


---

## 2. Domaine `keybuzz.pro` — Agent Website

### IDs tracking installés


| Service            | ID                 | Statut        |
| ------------------ | ------------------ | ------------- |
| Google Analytics 4 | `G-R3QQDYEBFG`     | Actif en PROD |
| Meta Pixel         | `1234164602194748` | Actif en PROD |


### Pages et events


| URL                  | Rôle                       | Events GA4                                                 | Events Meta Pixel                                     |
| -------------------- | -------------------------- | ---------------------------------------------------------- | ----------------------------------------------------- |
| `/`                  | Page d'accueil             | `page_view`                                                | `PageView`                                            |
| `/pricing`           | Page tarifs                | `page_view`, `view_pricing`, `select_plan`, `click_signup` | `PageView`, `ViewContent`, `InitiateCheckout`, `Lead` |
| `/features`          | Services / fonctionnalités | `page_view`                                                | `PageView`                                            |
| `/contact`           | Formulaire contact         | `page_view`, `contact_submit`                              | `PageView`, `Contact`                                 |
| `/about`             | À propos                   | `page_view`                                                | `PageView`                                            |
| `/amazon`            | Landing Amazon             | `page_view`                                                | `PageView`                                            |
| `/amazon/data-usage` | Politique données Amazon   | `page_view`                                                | `PageView`                                            |
| `/amazon/security`   | Sécurité Amazon            | `page_view`                                                | `PageView`                                            |
| `/privacy`           | Politique confidentialité  | `page_view`                                                | `PageView`                                            |
| `/terms`             | CGU                        | `page_view`                                                | `PageView`                                            |
| `/legal`             | Mentions légales           | `page_view`                                                | `PageView`                                            |
| `/cookies`           | Politique cookies          | `page_view`                                                | `PageView`                                            |
| `/sla`               | SLA                        | `page_view`                                                | `PageView`                                            |


### Détail des events custom


| Event GA4        | Event Meta         | Déclencheur                              | Paramètres envoyés                          |
| ---------------- | ------------------ | ---------------------------------------- | ------------------------------------------- |
| `view_pricing`   | `ViewContent`      | Visite de `/pricing`                     | category: engagement, content_name: pricing |
| `select_plan`    | `InitiateCheckout` | Clic sur un plan (Starter/Pro/Autopilot) | plan, cycle (monthly/yearly)                |
| `click_signup`   | `Lead`             | Clic CTA vers le SaaS                    | label: nom du plan                          |
| `contact_submit` | `Contact`          | Soumission formulaire `/contact`         | category: conversion                        |


### Liens sortants vers le SaaS (points de sortie)


| Depuis                      | URL de destination                                        | UTM transmis                                                               |
| --------------------------- | --------------------------------------------------------- | -------------------------------------------------------------------------- |
| `/pricing` → CTA Starter    | `client.keybuzz.io/register?plan=starter&cycle=monthly`   | utm_source, utm_medium, utm_campaign, utm_term, utm_content, gclid, fbclid |
| `/pricing` → CTA Pro        | `client.keybuzz.io/register?plan=pro&cycle=monthly`       | idem                                                                       |
| `/pricing` → CTA Autopilot  | `client.keybuzz.io/register?plan=autopilot&cycle=monthly` | idem                                                                       |
| Navbar → "Créer un compte"  | `client.keybuzz.io/signup`                                | Aucun (pas de forwarding UTM)                                              |
| Navbar → "Connexion"        | `client.keybuzz.io`                                       | Aucun                                                                      |
| Accueil → "Créer un compte" | `client.keybuzz.io/signup`                                | Aucun                                                                      |


---

## 3. Domaine `client.keybuzz.io` — Agent SaaS

### URLs d'entrée (reçues depuis le site vitrine)


| URL                                                     | Rôle                            | Paramètres reçus dans l'URL                                                             |
| ------------------------------------------------------- | ------------------------------- | --------------------------------------------------------------------------------------- |
| `/register?plan=starter&cycle=monthly&utm_source=...`   | Inscription avec plan Starter   | plan, cycle, utm_source, utm_medium, utm_campaign, utm_term, utm_content, gclid, fbclid |
| `/register?plan=pro&cycle=monthly&utm_source=...`       | Inscription avec plan Pro       | idem                                                                                    |
| `/register?plan=autopilot&cycle=monthly&utm_source=...` | Inscription avec plan Autopilot | idem                                                                                    |
| `/signup`                                               | Inscription générique           | Aucun UTM (arrivée directe)                                                             |
| `/`                                                     | Login                           | Aucun tracking acquisition                                                              |


### URLs internes SaaS (parcours utilisateur)


| URL            | Rôle                     | Event de conversion à implémenter              |
| -------------- | ------------------------ | ---------------------------------------------- |
| `/register`    | Formulaire d'inscription | `signup_start`                                 |
| `/start`       | Onboarding (4 étapes)    | `onboarding_step_1`, `onboarding_step_2`, etc. |
| `/start` (fin) | Paiement Stripe          | `payment_success`, `trial_start`               |
| `/inbox`       | Boîte de réception       | Aucun (usage quotidien)                        |
| `/dashboard`   | Tableau de bord          | Aucun (usage quotidien)                        |


### Ce que l'agent SaaS doit implémenter


| Tâche                        | Détail                                                                                                                      | Priorité |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------- | -------- |
| **Lire les UTM à l'arrivée** | Sur `/register`, lire `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`, `gclid`, `fbclid` depuis l'URL | Haute    |
| **Stocker les UTM**          | Sauvegarder en `sessionStorage` ou `localStorage` au moment de l'inscription pour ne pas les perdre entre les étapes        | Haute    |
| **Installer GA4**            | Même propriété `G-R3QQDYEBFG` pour le cross-domain (le linker est déjà configuré côté website)                              | Haute    |
| **Installer Meta Pixel**     | Même pixel `1234164602194748` pour le suivi cross-domain                                                                    | Haute    |
| **Event signup**             | Envoyer `signup_complete` à GA4 + Meta quand l'inscription est validée                                                      | Haute    |
| **Event paiement**           | Envoyer `purchase` / `payment_success` à GA4 + Meta après paiement Stripe                                                   | Haute    |
| **Webhook conversion**       | Envoyer les données complètes (UTM + données onboarding) vers Facebook CAPI / endpoint externe pour le Media Buyer          | Moyenne  |


### Données collectées pendant l'onboarding (à transmettre via webhook)


| Champ                      | Étape         | Utilité pour le tracking                   |
| -------------------------- | ------------- | ------------------------------------------ |
| Email                      | Inscription   | Identifiant principal (Facebook CAPI, GA4) |
| Nom / Prénom               | Inscription   | Advanced Matching Meta Pixel               |
| Nom entreprise             | Onboarding    | Segmentation                               |
| Marketplaces connectées    | Onboarding    | Qualification du lead                      |
| Plan choisi                | Inscription   | Valeur de conversion                       |
| Cycle (mensuel/annuel)     | Inscription   | Valeur de conversion                       |
| UTM source/medium/campaign | URL d'arrivée | Attribution campagne                       |
| gclid / fbclid             | URL d'arrivée | Attribution Google Ads / Meta Ads          |


---

## 4. Schéma du funnel complet

```
┌──────────────────────────────────────────────────────────────┐
│                    AGENT WEBSITE (keybuzz.pro)                │
│                                                              │
│   Ads (Meta/Google/TikTok/etc.)                              │
│     ↓                                                        │
│   keybuzz.pro/?utm_source=facebook&utm_campaign=mb-launch    │
│     ↓  page_view + PageView                                  │
│   keybuzz.pro/pricing                                        │
│     ↓  view_pricing + ViewContent                            │
│   Clic CTA "Commencer"                                       │
│     ↓  select_plan + InitiateCheckout                        │
│     ↓  click_signup + Lead                                   │
│     ↓                                                        │
│   ═══════════ SORTIE VERS SAAS (UTM transmis) ═══════════    │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                  AGENT SAAS (client.keybuzz.io)               │
│                                                              │
│   /register?plan=pro&cycle=monthly&utm_source=facebook       │
│     ↓  lire UTM → stocker en session                         │
│     ↓  signup_start                                          │
│   /start (onboarding 4 étapes)                               │
│     ↓  données utilisateur collectées                        │
│   Paiement Stripe                                            │
│     ↓  payment_success / purchase                            │
│     ↓  webhook → Facebook CAPI + GA4 Measurement Protocol    │
│     ↓  (UTM + email + nom + plan + montant)                  │
│                                                              │
│   ═══════════════ CONVERSION FINALE ═════════════════════    │
└──────────────────────────────────────────────────────────────┘
```

---

## 5. Résumé des responsabilités


| Responsabilité                                  | Agent Website | Agent SaaS                   |
| ----------------------------------------------- | ------------- | ---------------------------- |
| Installer GA4                                   | ✅ Fait        | À faire (même ID)            |
| Installer Meta Pixel                            | ✅ Fait        | À faire (même ID)            |
| Events acquisition (view_pricing, click_signup) | ✅ Fait        | —                            |
| Events conversion (signup, payment)             | —             | À faire                      |
| Forwarding UTM vers SaaS                        | ✅ Fait        | —                            |
| Lecture UTM à l'arrivée                         | —             | À faire                      |
| Stockage UTM en session                         | —             | À faire                      |
| Webhook conversion (CAPI)                       | —             | À faire                      |
| Cross-domain GA4 (code)                         | ✅ Fait        | À faire (même config linker) |
| Cross-domain GA4 (admin)                        | ✅ Fait        | — (même propriété)           |


---

## 6. Documents associés


| Document                                     | Contenu                                                   |
| -------------------------------------------- | --------------------------------------------------------- |
| `PH-WEBSITE-TRACKING-FOUNDATION-01.md`       | Rapport technique complet de l'implémentation website     |
| `MEDIA-BUYER-TRACKING-GUIDE.md`              | Guide pour Media Buyer & Agence (UTM, accès, conventions) |
| `MEDIA-BUYER-UTM-TRACKING.md`                | Guide UTM initial                                         |
| `BRIEFING-WEBHOOK-CONVERSION-MEDIA-BUYER.md` | Briefing technique webhook conversion (pour l'agent SaaS) |


