# PH-WEBSITE-TRACKING-FOUNDATION-01 — TERMINÉ

**Phase** : Tracking Foundation (GA4 + Meta Pixel)
**Date** : 16 avril 2026
**Scope** : keybuzz-website uniquement — zéro impact SaaS

---

## Verdict : TRACKING WEBSITE OPERATIONAL — EVENTS OK — NO REGRESSION — PROD SAFE

---

## 1. IDs configurés


| Service            | ID                 | Propriétaire           |
| ------------------ | ------------------ | ---------------------- |
| Google Analytics 4 | `G-R3QQDYEBFG`     | KeyBuzz                |
| Meta Pixel         | `1234164602194748` | KeyBuzz Consulting LLP |


Les IDs sont passés via `NEXT_PUBLIC_GA_ID` et `NEXT_PUBLIC_META_PIXEL_ID` (build args Docker). Zéro hardcode dans le code source.

---

## 2. Fichiers créés / modifiés


| Fichier                        | Action   | Rôle                                                          |
| ------------------------------ | -------- | ------------------------------------------------------------- |
| `src/lib/tracking.ts`          | **Créé** | Librairie tracking typée (GA4 + Meta Pixel)                   |
| `src/components/Analytics.tsx` | **Créé** | Composant client — charge gtag.js + fbevents.js               |
| `src/app/layout.tsx`           | Modifié  | Import + rendu du composant Analytics                         |
| `src/app/pricing/page.tsx`     | Modifié  | Events view_pricing, select_plan, click_signup + gclid/fbclid |
| `src/app/contact/page.tsx`     | Modifié  | Event contact_submit                                          |
| `Dockerfile`                   | Modifié  | Build args NEXT_PUBLIC_GA_ID + NEXT_PUBLIC_META_PIXEL_ID      |


---

## 3. Events trackés

### Google Analytics 4


| Event            | Déclencheur                         | Paramètres                   |
| ---------------- | ----------------------------------- | ---------------------------- |
| `page_view`      | Chaque navigation                   | Automatique                  |
| `view_pricing`   | Visite page /pricing                | category: engagement         |
| `select_plan`    | Clic sur plan Starter/Pro/Autopilot | plan, cycle (monthly/yearly) |
| `click_signup`   | Clic CTA vers SaaS                  | label: nom du plan           |
| `contact_submit` | Soumission formulaire contact       | category: conversion         |


### Meta Pixel


| Event Pixel        | Déclencheur                   | Paramètres                        |
| ------------------ | ----------------------------- | --------------------------------- |
| `PageView`         | Chaque navigation             | Automatique                       |
| `ViewContent`      | Visite page /pricing          | content_name: pricing             |
| `InitiateCheckout` | Clic sur un plan              | content_name: plan, currency: EUR |
| `Lead`             | Clic CTA vers SaaS            | content_name: plan                |
| `Contact`          | Soumission formulaire contact | —                                 |


---

## 4. Paramètres préservés lors de la redirection Website → SaaS

Les paramètres suivants sont capturés sur `/pricing` et ajoutés aux liens vers `client.keybuzz.io/register` :

- `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`
- `gclid` (Google Ads click ID)
- `fbclid` (Facebook click ID)

---

## 5. Cross-domain GA4

### Côté code

```js
gtag('config', 'G-R3QQDYEBFG', {
  linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }
});
```

### Côté admin GA4

- Configuration multidomaine activée : `keybuzz.pro` + `client.keybuzz.io`
- Type de correspondance : "Correspond exactement à"

---

## 6. Consent Mode v2

```js
gtag('consent', 'default', {
  analytics_storage: 'granted',
  ad_storage: 'denied',
  ad_user_data: 'denied',
  ad_personalization: 'denied'
});
```

L'analytics est autorisé par défaut. Les données publicitaires sont refusées par défaut (conformité RGPD). L'intégration avec le composant `CookieConsent` existant pourra être affinée ultérieurement pour basculer `ad_storage` sur `granted` si l'utilisateur accepte.

---

## 7. Références de déploiement

### Website repo


| Champ  | Valeur                                         |
| ------ | ---------------------------------------------- |
| SHA    | `8a16767f09b118e460ef4c740a0534f0ce694acd`     |
| Commit | feat: add GA4 + Meta Pixel tracking foundation |


### DEV (preview.keybuzz.pro)


| Champ     | Valeur                                                                    |
| --------- | ------------------------------------------------------------------------- |
| Tag image | `v0.6.4-tracking-foundation-dev`                                          |
| Digest    | `sha256:673075ab7d45f50d8b88124cd6212a565a882eaf16c1190ca86fd75cb016058d` |


### PROD ([www.keybuzz.pro](http://www.keybuzz.pro))


| Champ     | Valeur                                                                    |
| --------- | ------------------------------------------------------------------------- |
| Tag image | `v0.6.4-tracking-foundation-prod`                                         |
| Digest    | `sha256:c9f5e770dd466f41e6c187a6ed29c8ce7c23b237e0df52d871c1545b358213d0` |


### Infra


| Champ    | Valeur    |
| -------- | --------- |
| SHA DEV  | `7dce1d8` |
| SHA PROD | `08ae899` |


---

## 8. Validation complète

### DEV — preview.keybuzz.pro

- ✅ Pods Running, logs propres
- ✅ HTTP 200
- ✅ GA4 gtag.js présent dans HTML
- ✅ GA ID `G-R3QQDYEBFG` présent dans HTML + bundles JS
- ✅ Meta Pixel `fbevents.js` présent dans bundles JS
- ✅ Meta Pixel ID `1234164602194748` présent dans bundles JS
- ✅ Events tracking dans bundles JS
- ✅ gclid/fbclid forwarding dans bundles JS
- ✅ Aucune erreur EACCES

### PROD — [www.keybuzz.pro](http://www.keybuzz.pro)

- ✅ 2 pods Running (HA), logs propres
- ✅ HTTP 200
- ✅ GA4 gtag.js + ID présents dans HTML
- ✅ Meta Pixel + ID présents dans bundles JS
- ✅ Tous events tracking présents dans bundles JS
- ✅ gclid/fbclid forwarding présent
- ✅ Aucune erreur

### GA4 — Temps réel validé par Ludovic

- ✅ `page_view` : 12 événements reçus
- ✅ `view_pricing` : 5 événements reçus
- ✅ `click_signup` : 3 événements reçus
- ✅ `select_plan` : 3 événements reçus
- ✅ `scroll` : 2 événements reçus
- ✅ `contact_submit` : 1 événement reçu

### Meta Pixel — Validé par Ludovic via Meta Pixel Helper

- ✅ Page d'accueil : `PageView` Active
- ✅ Page Contact : `Contact` Active, `contact_submit` Active, `PageView` Active
- ✅ Page Pricing : `ViewContent` Active (content_name: pricing), `view_pricing` Active (category: engagement), `PageView` Active

### GA4 Admin

- ✅ Data Stream créé : "Site KeyBuzz" (ID flux : 14381980298)
- ✅ Mesures améliorées activées (Pages vues, Défilements, Clics sortants, +4)
- ✅ Cross-domain configuré : `keybuzz.pro` + `client.keybuzz.io`
- ⏳ Événements clés : `click_signup` et `contact_submit` à marquer sous 24-48h (les events custom n'apparaissent pas encore dans Admin > Événements > Événements récents)

---

## 9. Rollback

### Procédure standard (GitOps)

1. Remettre l'ancien tag dans `keybuzz-infra/k8s/website-prod/deployment.yaml` :
  ```
   image: ghcr.io/keybuzzio/keybuzz-website:v0.6.3-error-boundaries-prod
  ```
2. `git commit && git push`
3. `kubectl apply -f`

### Secours immédiat

```bash
kubectl set image deployment/keybuzz-website \
  keybuzz-website=ghcr.io/keybuzzio/keybuzz-website:v0.6.3-error-boundaries-prod \
  -n keybuzz-website-prod
```

---

## 10. Documentation associée


| Document                                     | Rôle                                                                      |
| -------------------------------------------- | ------------------------------------------------------------------------- |
| `MEDIA-BUYER-TRACKING-GUIDE.md`              | Guide complet pour Media Buyer & Agence : events, UTM, accès, conventions |
| `MEDIA-BUYER-UTM-TRACKING.md`                | Guide UTM antérieur (toujours valide)                                     |
| `BRIEFING-WEBHOOK-CONVERSION-MEDIA-BUYER.md` | Briefing webhook conversion (évolution future)                            |


---

## 11. Prochaines étapes


| Action                                                                    | Qui           | Quand                     |
| ------------------------------------------------------------------------- | ------------- | ------------------------- |
| Marquer `click_signup` et `contact_submit` comme événements clés dans GA4 | Ludovic       | Sous 24-48h               |
| Donner accès GA4 (Lecteur) au Media Buyer / Agence                        | Ludovic       | Avant lancement campagnes |
| Partager le Meta Pixel avec le Business Manager du Media Buyer / Agence   | Ludovic       | Avant lancement campagnes |
| Consent Mode avancé (lier CookieConsent → ad_storage)                     | Agent Website | Évolution future          |
| Tracking server-side Addingwell                                           | Agent Website | Évolution future          |
| Webhook conversion (onboarding data → Facebook CAPI)                      | Agent Client  | Évolution future          |


---

STUDIO SCOPE VERIFIED — ZERO CLIENT IMPACT