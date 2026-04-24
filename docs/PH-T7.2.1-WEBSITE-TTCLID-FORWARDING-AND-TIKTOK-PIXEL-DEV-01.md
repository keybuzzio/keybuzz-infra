# PH-T7.2.1 — Website TikTok ttclid Forwarding + Pixel — DEV

**Phase** : PH-T7.2.1-WEBSITE-TTCLID-FORWARDING-AND-TIKTOK-PIXEL-DEV-01
**Date** : 10 avril 2026
**Environnement** : DEV uniquement
**Verdict** : **WEBSITE TIKTOK FORWARDING READY**

---

## Preflight


| Element            | Valeur                                                         |
| ------------------ | -------------------------------------------------------------- |
| Repo               | `keybuzz-website`                                              |
| Branche            | `main`                                                         |
| Commit avant patch | `cc9ec960a3c85de37dad8b085b779c624acd5d86`                     |
| Image DEV avant    | `ghcr.io/keybuzzio/keybuzz-website:v0.6.5-sgtm-addingwell-dev` |
| TikTok Pixel ID    | `D7HQO0JC77U2ODPGMDI0`                                         |


---

## Modifications effectuees

### 1. Forwarding `ttclid` — `src/app/pricing/page.tsx`

Ajout de `ttclid` a la liste des parametres forwarded vers `client.keybuzz.io/register` :

```
Avant : ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "gclid", "fbclid"]
Apres  : ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "gclid", "fbclid", "ttclid"]
```

Impact : quand un visiteur arrive via TikTok Ads avec `?ttclid=xxx`, le parametre est preserve dans le CTA vers le SaaS.

### 2. TikTok Pixel — `src/components/Analytics.tsx`

Ajout du TikTok Pixel browser-side via le SDK officiel :

- Variable : `NEXT_PUBLIC_TIKTOK_PIXEL_ID`
- SDK : `https://analytics.tiktok.com/i18n/pixel/events.js`
- Init : `ttq.load('D7HQO0JC77U2ODPGMDI0')`
- PageView automatique : `ttq.page()` sur changement de route
- Strategie : `afterInteractive` (comme GA4 et Meta)
- Fallback : si `NEXT_PUBLIC_TIKTOK_PIXEL_ID` absent, le bloc TikTok n'est pas rendu

GA4 et Meta Pixel inchanges.

### 3. Events TikTok — `src/lib/tracking.ts`

Mapping des events existants vers les events standard TikTok :


| Event website    | TikTok Event       | Parametres                                                     |
| ---------------- | ------------------ | -------------------------------------------------------------- |
| `view_pricing`   | `ViewContent`      | `content_type: "product", content_name: "pricing"`             |
| `select_plan`    | `InitiateCheckout` | `content_type: "product", content_name: plan, currency: "EUR"` |
| `click_signup`   | `SubmitForm`       | `content_type: "product", content_name: plan`                  |
| `contact_submit` | `Contact`          | `{}`                                                           |


Ajout de `window.ttq` a l'interface `Window` globale TypeScript.

### 4. Dockerfile

Ajout des ARG/ENV :

```
ARG NEXT_PUBLIC_TIKTOK_PIXEL_ID=
ENV NEXT_PUBLIC_TIKTOK_PIXEL_ID=${NEXT_PUBLIC_TIKTOK_PIXEL_ID}
```

---

## Fichiers modifies


| Fichier                        | Nature                              |
| ------------------------------ | ----------------------------------- |
| `src/app/pricing/page.tsx`     | Ajout `ttclid` au forwarding        |
| `src/components/Analytics.tsx` | Ajout TikTok Pixel SDK              |
| `src/lib/tracking.ts`          | Ajout events TikTok (ttq)           |
| `Dockerfile`                   | Ajout `NEXT_PUBLIC_TIKTOK_PIXEL_ID` |


**4 fichiers — 55 insertions, 2 suppressions**

---

## Build et deploiement


| Element        | Valeur                                                                                                                     |
| -------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Commit website (ttclid+pixel) | `4962f294fbf089cf07a3f5b5f4d2c6c55cd0501d`                                                                     |
| Commit website (fix SDK officiel) | `29c66d2879ffb42a68a3ade536c37795df5abf94`                                                                |
| Tag image      | `ghcr.io/keybuzzio/keybuzz-website:v0.6.6-tiktok-ttclid-dev`                                                               |
| Digest         | `sha256:7c0b4545f1c1f8e048da027651e0bb8514d6613d8f9fa92082f47bfa0d58df52`                                                  |
| Commit infra   | `a3d10673e6feeaafce2795f4bb55e710451892d5`                                                                                 |
| Build          | `--no-cache` depuis repo git clean                                                                                         |
| Build args     | `GA_ID=G-R3QQDYEBFG`, `META_PIXEL=1234164602194748`, `SGTM_URL=https://t.keybuzz.pro`, `TIKTOK_PIXEL=D7HQO0JC77U2ODPGMDI0` |


---

## Validation

### Bundles JS


| Verification                                  | Resultat |
| --------------------------------------------- | -------- |
| `ttclid` dans pricing bundle                  | OK       |
| `TiktokAnalyticsObject` dans analytics bundle | OK       |
| `D7HQO0JC77U2ODPGMDI0` dans analytics bundle  | OK       |
| `G-R3QQDYEBFG` (GA4) toujours present         | OK       |
| `1234164602194748` (Meta) toujours present    | OK       |
| `t.keybuzz.pro` (sGTM) toujours present       | OK       |
| `gclid` + `fbclid` toujours presents          | OK       |


### HTTP


| Test                 | Resultat |
| -------------------- | -------- |
| Homepage (`/`)       | HTTP 200 |
| Pricing (`/pricing`) | HTTP 200 |
| Preview externe      | HTTP 200 |


### Pod K8s


| Element | Valeur                                      |
| ------- | ------------------------------------------- |
| Pod     | `keybuzz-website-b768bc7cc-cp4bq` (Running) |
| Next.js | 16.1.4 — Ready in 919ms                     |
| Erreurs | Aucune                                      |


---

## Non-regression


| Element                                                  | Statut |
| -------------------------------------------------------- | ------ |
| GA4 via sGTM (`t.keybuzz.pro`)                           | Intact |
| Meta Pixel browser-side                                  | Intact |
| UTM forwarding (utm_source/medium/campaign/term/content) | Intact |
| gclid forwarding                                         | Intact |
| fbclid forwarding                                        | Intact |
| CTA pricing -> SaaS                                      | Intact |
| Cross-domain linker                                      | Intact |


---

## Rollback

Rollback GitOps :

```
# Remettre ancien tag
image: ghcr.io/keybuzzio/keybuzz-website:v0.6.5-sgtm-addingwell-dev

# Commit + push + apply
cd /opt/keybuzz/keybuzz-infra
git add k8s/website-dev/deployment.yaml
git commit -m "rollback: website DEV to v0.6.5-sgtm-addingwell"
git push origin main
kubectl apply -f k8s/website-dev/deployment.yaml
```

---

## Architecture tracking website mise a jour

```
Visiteur -> keybuzz.pro
  |
  +-- GA4 (gtag.js via t.keybuzz.pro / sGTM Addingwell)
  |     events: view_pricing, select_plan, click_signup, contact_submit
  |
  +-- Meta Pixel (fbevents.js browser-side)
  |     events: PageView, ViewContent, InitiateCheckout, Lead, Contact
  |
  +-- TikTok Pixel (events.js browser-side)  [NOUVEAU]
  |     events: page(), ViewContent, InitiateCheckout, SubmitForm, Contact
  |
  +-- CTA /pricing -> client.keybuzz.io/register
        forwarding: utm_source, utm_medium, utm_campaign, utm_term, utm_content,
                    gclid, fbclid, ttclid [NOUVEAU]
```

---

## Verdict

**WEBSITE TIKTOK FORWARDING READY**

- `ttclid` forward : OK
- TikTok Pixel : OK (ID `D7HQO0JC77U2ODPGMDI0`)
- Events TikTok : OK (4 events mappes)
- GA4 : intact
- Meta Pixel : intact
- sGTM Addingwell : intact
- UTM/gclid/fbclid : intact
- Zero regression

**STUDIO SCOPE VERIFIED — ZERO CLIENT IMPACT**