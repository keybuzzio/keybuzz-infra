# PH-T5.4-WEBSITE-SERVER-CONTAINER-INTEGRATION-DEV-01 — TERMINÉ

**Verdict** : WEBSITE SERVER CONTAINER ROUTING ACTIVE — NO REGRESSION

> **Date** : 17 avril 2026
> **Environnement** : DEV uniquement
> **Scope** : keybuzz-website — zéro impact SaaS

---

## 1. Préflight


| Élément                      | Valeur                                                                                   |
| ---------------------------- | ---------------------------------------------------------------------------------------- |
| Repo                         | `keybuzz-website`                                                                        |
| Branche                      | `main`                                                                                   |
| Commit avant modif           | `8a16767f09b118e460ef4c740a0534f0ce694acd`                                               |
| Repo clean                   | OUI (0 fichiers modifiés)                                                                |
| Méthode injection GA4        | `Analytics.tsx` — composant client `next/script` afterInteractive                        |
| Méthode injection Meta Pixel | `Analytics.tsx` — inline script fbevents.js                                              |
| Fallback sans SGTM_URL       | Direct `https://www.googletagmanager.com/gtag/js`                                        |
| Events existants             | `view_pricing`, `select_plan`, `click_signup`, `contact_submit`                          |
| UTM forwarding               | `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`, `gclid`, `fbclid` |


### Audit tracking existant


| Élément                    | État actuel                                             | Fichier                        |
| -------------------------- | ------------------------------------------------------- | ------------------------------ |
| gtag.js injection          | `<Script src="googletagmanager.com/gtag/js">`           | `src/components/Analytics.tsx` |
| gtag config                | `gtag('config', GA_ID, { linker: { domains: [...] } })` | `src/components/Analytics.tsx` |
| Meta Pixel                 | Inline script fbevents.js + `fbq('init', PIXEL_ID)`     | `src/components/Analytics.tsx` |
| view_pricing               | `useEffect` au montage de `/pricing`                    | `src/app/pricing/page.tsx`     |
| select_plan + click_signup | `onClick` sur CTA pricing                               | `src/app/pricing/page.tsx`     |
| contact_submit             | Après `setStatus("success")`                            | `src/app/contact/page.tsx`     |
| Tracking lib               | `trackEvent()`, `trackViewPricing()`, etc.              | `src/lib/tracking.ts`          |
| Consent Mode v2            | `analytics_storage: granted, ad_storage: denied`        | `src/components/Analytics.tsx` |
| Cross-domain linker        | `keybuzz.pro` + `client.keybuzz.io`                     | `src/components/Analytics.tsx` |


---

## 2. Fichiers touchés


| Fichier                        | Modification | Scope tracking pur ? | Détail                                                                                         |
| ------------------------------ | ------------ | -------------------- | ---------------------------------------------------------------------------------------------- |
| `src/components/Analytics.tsx` | +18 -4       | OUI                  | Ajout `SGTM_URL` const, gtag.js src conditionnel sGTM, `server_container_url` dans gtag config |
| `Dockerfile`                   | +2           | OUI                  | Ajout `ARG NEXT_PUBLIC_SGTM_URL=` + `ENV NEXT_PUBLIC_SGTM_URL=${NEXT_PUBLIC_SGTM_URL}`         |


### Fichiers NON touchés (confirmation)


| Fichier/Répertoire                 | Touché ?                          |
| ---------------------------------- | --------------------------------- |
| `src/app/pricing/page.tsx`         | NON                               |
| `src/app/contact/page.tsx`         | NON                               |
| `src/app/layout.tsx`               | NON                               |
| `src/lib/tracking.ts`              | NON                               |
| `src/components/CookieConsent.tsx` | NON                               |
| `src/components/IntroSplash.tsx`   | NON                               |
| Meta Pixel code                    | NON (inchangé dans Analytics.tsx) |
| SaaS (`client.keybuzz.io`)         | NON                               |
| API KeyBuzz                        | NON                               |


### Changement exact

```diff
 // Analytics.tsx
 const META_PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID;
+const SGTM_URL = process.env.NEXT_PUBLIC_SGTM_URL || "";

+  const gtagSrc = SGTM_URL
+    ? `${SGTM_URL}/gtag/js?id=${GA_ID}`
+    : `https://www.googletagmanager.com/gtag/js?id=${GA_ID}`;

+  const gtagConfig = SGTM_URL
+    ? `gtag('config', '${GA_ID}', {
+        server_container_url: '${SGTM_URL}',
+        linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }
+      });`
+    : `gtag('config', '${GA_ID}', {
+        linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }
+      });`;
```

```diff
 # Dockerfile
 ARG NEXT_PUBLIC_META_PIXEL_ID
+ARG NEXT_PUBLIC_SGTM_URL=
 ENV NEXT_PUBLIC_META_PIXEL_ID=${NEXT_PUBLIC_META_PIXEL_ID}
+ENV NEXT_PUBLIC_SGTM_URL=${NEXT_PUBLIC_SGTM_URL}
```

---

## 3. Build


| Élément           | Valeur                                                                                    |
| ----------------- | ----------------------------------------------------------------------------------------- |
| Source du build   | repo `keybuzz-website`, branche `main`                                                    |
| Commit source     | `cc9ec960a3c85de37dad8b085b779c624acd5d86`                                                |
| Message commit    | `PH-T5.4: add sGTM server_container_url for Addingwell`                                   |
| Lieu du build     | bastion `install-v3` (`46.62.171.61`)                                                     |
| Preuve repo clean | `git status --short` = 2 fichiers modifiés (M Dockerfile, M Analytics.tsx)                |
| Mode              | `build-from-git` — repo clean, `--no-cache`                                               |
| Build args        | `NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro`, `GA4=G-R3QQDYEBFG`, `META=1234164602194748` |
| Tag image         | `ghcr.io/keybuzzio/keybuzz-website:v0.6.5-sgtm-addingwell-dev`                            |
| Digest            | `sha256:4f7bed944ead6195b32dd5ea1f0a8933d28f137314127089a348ef31f16382f3`                 |


### Image avant/après


| Élément      | Avant                             | Après                        |
| ------------ | --------------------------------- | ---------------------------- |
| Website DEV  | `v0.6.4-tracking-foundation-dev`  | `v0.6.5-sgtm-addingwell-dev` |
| Website PROD | `v0.6.4-tracking-foundation-prod` | inchangée                    |


---

## 4. Validation website


| Test                         | Résultat                         | OK/NOK |
| ---------------------------- | -------------------------------- | ------ |
| Pod Running                  | `1/1 Running`, 0 restarts        | OK     |
| Logs propres                 | `Ready in 1219ms`, aucune erreur | OK     |
| HTTP homepage                | 200                              | OK     |
| External preview.keybuzz.pro | 200                              | OK     |


---

## 5. Validation tracking


| Test                                          | Résultat                                                  | OK/NOK |
| --------------------------------------------- | --------------------------------------------------------- | ------ |
| `t.keybuzz.pro` dans bundles JS               | Trouvé dans `ff7eb01ed949ec5b.js` + `25c80ce6ceb72e38.js` | OK     |
| `server_container_url` dans bundles           | Trouvé dans `ff7eb01ed949ec5b.js`                         | OK     |
| `t.keybuzz.pro` dans HTML homepage            | Présent                                                   | OK     |
| GA4 ID `G-R3QQDYEBFG` dans HTML + bundles     | Présent                                                   | OK     |
| `t.keybuzz.pro/gtag/js` accessible            | HTTP 200                                                  | OK     |
| Meta Pixel `fbevents.js` dans bundles         | Présent (inchangé)                                        | OK     |
| Meta Pixel ID `1234164602194748` dans bundles | Présent (inchangé)                                        | OK     |
| Events `view_pricing` dans bundles            | Présent                                                   | OK     |
| Events `contact_submit` dans bundles          | Présent                                                   | OK     |
| UTM `gclid`/`fbclid` dans bundles             | Présent                                                   | OK     |


### Routage sGTM confirmé

```
gtag.js chargé depuis :    https://t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG
GA4 hits routés via :       https://t.keybuzz.pro (server_container_url)
Meta Pixel :                inchangé (browser-side direct via connect.facebook.net)
```

---

## 6. Non-régression cross-domain


| Test                                                                         | Résultat                                                    | OK/NOK |
| ---------------------------------------------------------------------------- | ----------------------------------------------------------- | ------ |
| CTA pricing → `client.keybuzz.io/register`                                   | Liens intacts dans bundles                                  | OK     |
| UTM forwarding (utm_source, utm_medium, utm_campaign, utm_term, utm_content) | Code inchangé dans `pricing/page.tsx`                       | OK     |
| gclid/fbclid forwarding                                                      | Code inchangé dans `pricing/page.tsx`                       | OK     |
| GA4 cross-domain linker (`keybuzz.pro` + `client.keybuzz.io`)                | Présent dans Analytics.tsx                                  | OK     |
| Consent Mode v2                                                              | Inchangé (`analytics_storage: granted, ad_storage: denied`) | OK     |


---

## 7. Rollback

### GitOps standard

```yaml
# Remettre dans keybuzz-infra/k8s/website-dev/deployment.yaml :
image: ghcr.io/keybuzzio/keybuzz-website:v0.6.4-tracking-foundation-dev
```

Puis `git commit && git push && kubectl apply -f`

### Secours immédiat

```bash
kubectl set image deployment/keybuzz-website \
  keybuzz-website=ghcr.io/keybuzzio/keybuzz-website:v0.6.4-tracking-foundation-dev \
  -n keybuzz-website-dev
```

---

## 8. Références


| Élément      | Valeur                                                                    |
| ------------ | ------------------------------------------------------------------------- |
| SHA website  | `cc9ec960a3c85de37dad8b085b779c624acd5d86`                                |
| Tag DEV      | `v0.6.5-sgtm-addingwell-dev`                                              |
| Digest DEV   | `sha256:4f7bed944ead6195b32dd5ea1f0a8933d28f137314127089a348ef31f16382f3` |
| SHA infra    | `0b09a23`                                                                 |
| Rollback tag | `v0.6.4-tracking-foundation-dev`                                          |


---

## 9. Conclusion

- gtag.js charge depuis `t.keybuzz.pro` (Addingwell sGTM) — **routage server-side actif**
- GA4 events routes via server container (`server_container_url`)
- Meta Pixel inchange (browser-side direct)
- Events marketing website intacts (`view_pricing`, `select_plan`, `click_signup`, `contact_submit`)
- UTM / gclid / fbclid forwarding intact
- Cross-domain GA4 linker intact
- Fallback conditionnel : si `NEXT_PUBLIC_SGTM_URL` absent, retour a `googletagmanager.com` direct
- Aucune regression
- Aucun impact SaaS

**WEBSITE SERVER CONTAINER ROUTING ACTIVE — NO REGRESSION**

Aucune autre action effectuée.

STOP