# PH-T5.3.2-REPLAY-SERVER-CONTAINER-INTEGRATION-ON-VALID-BRANCH-01 — TERMINÉ

> **Date** : 17 avril 2026
> **Environnement** : DEV uniquement
> **Priorité** : CRITIQUE
> **Verdict** : SERVER CONTAINER INTEGRATION REPLAY SUCCESS — VALID BRANCH

---

## 1. Préflight


| Élément                        | Valeur                               |
| ------------------------------ | ------------------------------------ |
| Branche source                 | `ph148/onboarding-activation-replay` |
| HEAD avant modification        | `f165e1b` (PH-T4.2)                  |
| Repo                           | clean                                |
| Historique PH-T1→T4            | intact (5 commits tracking)          |
| API touchée                    | NON                                  |
| Backend touché                 | NON                                  |
| `ph152.6-client-parity` touché | NON                                  |
| `main` touché                  | NON                                  |


---

## 2. Branche source

```
ph148/onboarding-activation-replay

Historique :
05c9163 PH-T1: marketing attribution capture
e579f1e PH-T3: GA4 + Meta Pixel SaaS funnel tracking
461a6f6 PH-T3: fix TrackingParams type
7a94f2a PH-T4: pass attribution to checkout-session
f165e1b PH-T4.2: add GA4/Meta Pixel ARG+ENV to Dockerfile
9e13d88 PH-T5.3.2: add sGTM server_container_url for Addingwell  ← NEW
```

---

## 3. Commit utilisé


| Élément | Valeur                                                    |
| ------- | --------------------------------------------------------- |
| Commit  | `9e13d887889243ba394e7bbbd94099af90cb30cc`                |
| Message | `PH-T5.3.2: add sGTM server_container_url for Addingwell` |
| Auteur  | `ecomlgfr <ludovic@ecomlg.fr>`                            |
| Branche | `ph148/onboarding-activation-replay`                      |
| Parent  | `f165e1b` (PH-T4.2)                                       |


---

## 4. Fichiers modifiés


| Fichier                                     | Modification | Scope tracking pur ? | Détail                                                                                        |
| ------------------------------------------- | ------------ | -------------------- | --------------------------------------------------------------------------------------------- |
| `src/components/tracking/SaaSAnalytics.tsx` | +5 -1        | OUI                  | Ajout `SGTM_URL` const, `server_container_url` dans gtag config, script src conditionnel sGTM |
| `Dockerfile`                                | +2           | OUI                  | Ajout `ARG NEXT_PUBLIC_SGTM_URL=` + `ENV NEXT_PUBLIC_SGTM_URL=${NEXT_PUBLIC_SGTM_URL}`        |


### Fichiers NON touchés (confirmation)


| Fichier/Répertoire        | Touché ? |
| ------------------------- | -------- |
| `app/start/`              | NON      |
| `app/dashboard/`          | NON      |
| `app/inbox/`              | NON      |
| `app/settings/`           | NON      |
| `src/features/`           | NON      |
| `src/services/`           | NON      |
| API (keybuzz-api)         | NON      |
| Backend (keybuzz-backend) | NON      |
| Stripe                    | NON      |
| Addingwell/GTM config     | NON      |


### Diff exact

```diff
diff --git a/Dockerfile b/Dockerfile
--- a/Dockerfile
+++ b/Dockerfile
@@ -12,6 +12,7 @@
 ARG NEXT_PUBLIC_GA4_MEASUREMENT_ID=
 ARG NEXT_PUBLIC_META_PIXEL_ID=
+ARG NEXT_PUBLIC_SGTM_URL=
 ...
 ENV NEXT_PUBLIC_META_PIXEL_ID=$NEXT_PUBLIC_META_PIXEL_ID
+ENV NEXT_PUBLIC_SGTM_URL=${NEXT_PUBLIC_SGTM_URL}

diff --git a/src/components/tracking/SaaSAnalytics.tsx b/src/components/tracking/SaaSAnalytics.tsx
--- a/src/components/tracking/SaaSAnalytics.tsx
+++ b/src/components/tracking/SaaSAnalytics.tsx
@@ -23,6 +23,7 @@
 const META_PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID || '';
+const SGTM_URL = process.env.NEXT_PUBLIC_SGTM_URL || '';

@@ -68,6 +69,7 @@
       window.gtag('config', GA4_ID, {
         send_page_view: true,
+        ...(SGTM_URL ? { server_container_url: SGTM_URL } : {}),
         linker: {

@@ -84,7 +86,7 @@
         <Script
-          src={`https://www.googletagmanager.com/gtag/js?id=${GA4_ID}`}
+          src={SGTM_URL ? `${SGTM_URL}/gtag/js?id=${GA4_ID}` : `https://www.googletagmanager.com/gtag/js?id=${GA4_ID}`}
```

---

## 5. Image avant/après


| Élément     | Avant                                                                          | Après                                                               |
| ----------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| Client DEV  | `ghcr.io/keybuzzio/keybuzz-client:v3.5.78-tracking-replay-on-valid-branch-dev` | `ghcr.io/keybuzzio/keybuzz-client:v3.5.79-tracking-t5.3-replay-dev` |
| API DEV     | `ghcr.io/keybuzzio/keybuzz-api:v3.5.77-tracking-t4-api-dev`                    | inchangée                                                           |
| Backend DEV | inchangé                                                                       | inchangé                                                            |


### Build


| Élément      | Valeur                                                                                   |
| ------------ | ---------------------------------------------------------------------------------------- |
| Mode         | `build-from-git` (repo clean, pas de SCP)                                                |
| Flag         | `--no-cache`                                                                             |
| Build args   | `NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.io`, `GA4=G-R3QQDYEBFG`, `META=1234164602194748` |
| Image digest | `sha256:77a66605b7d8e002cf404db28f41bb94995ca0d9500a7e0a75f42df7ce625244`                |
| Pod          | `keybuzz-client-7dff9f59cd-489tw` — `1/1 Running`                                        |


---

## 6. Validation SaaS


| Page                  | État                                                                                                                 |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `/start`              | OK — wizard onboarding 3 étapes, Autopilot proposé                                                                   |
| `/dashboard`          | OK — supervision, KPI (396 conv, 303 ouvertes, 334 SLA), canaux, activité récente                                    |
| `/inbox`              | OK — tripane, 396 conversations, suggestions IA, panneau commande/fournisseur                                        |
| `/settings`           | OK — 10 onglets (Entreprise, Horaires, Congés, Messages auto, Signature, Notifications, IA, Espaces, Agents, Avancé) |
| `/settings/signature` | OK — formulaire + aperçu en direct                                                                                   |
| `/settings/agents`    | OK — bouton Ajouter présent                                                                                          |


---

## 7. Validation tracking

### Pages funnel (tracking ACTIF via sGTM)


| Requête                | URL                                                             | Status |
| ---------------------- | --------------------------------------------------------------- | ------ |
| gtag.js                | `https://t.keybuzz.io/gtag/js?id=G-R3QQDYEBFG`                  | 200    |
| GA4 page_view          | `https://t.keybuzz.io/77gjfu?tid=G-R3QQDYEBFG&...&en=page_view` | 200    |
| GA4 scroll             | `https://t.keybuzz.io/77gjfu?tid=G-R3QQDYEBFG&...&en=scroll`    | 200    |
| sGTM service worker    | `https://t.keybuzz.io/_/service_worker/63b0/sw_iframe.html`     | 200    |
| Meta Pixel fbevents.js | `https://connect.facebook.net/en_US/fbevents.js`                | 200    |
| Meta PageView          | `https://www.facebook.com/tr/?id=1234164602194748&ev=PageView`  | 200    |


### Pages protégées (tracking BLOQUÉ)


| Page         | Requêtes tracking                                      | Résultat         |
| ------------ | ------------------------------------------------------ | ---------------- |
| `/inbox`     | 0 requêtes vers t.keybuzz.io/googletagmanager/facebook | BLOQUÉ — correct |
| `/dashboard` | 0                                                      | BLOQUÉ — correct |
| `/settings`  | 0                                                      | BLOQUÉ — correct |
| `/start`     | 0                                                      | BLOQUÉ — correct |


---

## 8. Non-régression


| Page         | État                                | Tracking correct ?    |
| ------------ | ----------------------------------- | --------------------- |
| `/register`  | OK — 3 plans Starter/Pro/Autopilot  | sGTM `t.keybuzz.io`   |
| `/login`     | OK — OTP + Google OAuth + Microsoft | sGTM `t.keybuzz.io`   |
| `/dashboard` | OK — KPI, supervision, canaux, SLA  | Aucun (page protégée) |
| `/start`     | OK — wizard 3 étapes                | Aucun (page protégée) |
| `/inbox`     | OK — tripane, conversations, IA     | Aucun (page protégée) |
| `/settings`  | OK — tous onglets                   | Aucun (page protégée) |


---

## 9. Rollback

En cas de problème :

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.78-tracking-replay-on-valid-branch-dev \
  -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 10. Verdict

### SERVER CONTAINER INTEGRATION REPLAY SUCCESS — VALID BRANCH

- PH-T5.3.2 rejoué proprement sur `ph148/onboarding-activation-replay`
- gtag.js charge depuis `t.keybuzz.io` (Addingwell sGTM)
- GA4 events routés via server container (page_view, scroll)
- Meta Pixel inchangé (client-side direct)
- Pages protégées : zéro tracking injecté
- Aucune régression SaaS
- API et backend non touchés
- `main` et `ph152.6-client-parity` non touchés

---

**STOP**