# PH-T5.3-SERVER-CONTAINER-CLIENT-INTEGRATION-DEV-01 — TERMINÉ

> **Date** : 1er mars 2026
> **Environnement** : DEV uniquement
> **Image déployée** : `v3.5.49-tracking-t5.3-dev`
> **Image rollback** : `v3.5.48-white-bg-dev`

---

## Verdict : CLIENT SERVER-SIDE ROUTING ACTIVE — NO REGRESSION

**GA4 : 100% opérationnel via `t.keybuzz.io` (Addingwell sGTM)**
**Meta Pixel : intact, non modifié**
**Zéro erreur console, zéro régression**

---

## 1. Audit (ÉTAPE 1)

### 1.1 Fichier modifié


| Fichier                                     | Rôle                                        |
| ------------------------------------------- | ------------------------------------------- |
| `src/components/tracking/SaaSAnalytics.tsx` | Injection GA4 + Meta Pixel sur pages funnel |


### 1.2 Config GA4 avant modification

```js
window.gtag('config', GA4_ID, {
  send_page_view: true,
  linker: {
    domains: ['keybuzz.pro', 'www.keybuzz.pro'],
    accept_incoming: true,
  },
});
```

- Script source : `https://www.googletagmanager.com/gtag/js?id=${GA4_ID}`
- Pas de `server_container_url`
- Tracking limité aux pages funnel (`/register`, `/login`)

### 1.3 Fichiers NON modifiés


| Fichier                 | Raison                                                 |
| ----------------------- | ------------------------------------------------------ |
| `src/lib/tracking.ts`   | Utilise `window.gtag` — route automatiquement via sGTM |
| `app/layout.tsx`        | Monte `<SaaSAnalytics />` — aucun changement           |
| `app/register/page.tsx` | Events tracking inchangés                              |
| API (keybuzz-api)       | Zero modification                                      |
| Webhook                 | Zero modification                                      |


---

## 2. Modification (ÉTAPE 2)

### 2.1 Changements dans `SaaSAnalytics.tsx`


| Changement          | Détail                                                                            |
| ------------------- | --------------------------------------------------------------------------------- |
| Variable `SGTM_URL` | `process.env.NEXT_PUBLIC_SGTM_URL || ''`                                          |
| `gtag('config')`    | Ajout conditionnel `server_container_url: SGTM_URL`                               |
| Script source       | Conditionnel : `SGTM_URL/gtag/js?id=...` ou `googletagmanager.com/gtag/js?id=...` |


### 2.2 Config GA4 après modification

```js
window.gtag('config', GA4_ID, {
  send_page_view: true,
  ...(SGTM_URL ? { server_container_url: SGTM_URL } : {}),
  linker: {
    domains: ['keybuzz.pro', 'www.keybuzz.pro'],
    accept_incoming: true,
  },
});
```

### 2.3 Dockerfile

Ajout de 3 build args et 3 ENVs :

- `NEXT_PUBLIC_GA4_MEASUREMENT_ID`
- `NEXT_PUBLIC_META_PIXEL_ID`
- `NEXT_PUBLIC_SGTM_URL`

---

## 3. Sécurité (ÉTAPE 3)

### 3.1 Matrice de fallback


| Scénario                       | Comportement                                                    |
| ------------------------------ | --------------------------------------------------------------- |
| `NEXT_PUBLIC_SGTM_URL` absent  | `server_container_url` non ajouté → routing standard Google CDN |
| `NEXT_PUBLIC_SGTM_URL` absent  | Script charge depuis `googletagmanager.com` → client-side pur   |
| `NEXT_PUBLIC_SGTM_URL` présent | Script charge depuis sGTM → data route via server container     |
| sGTM down                      | gtag.js continue de fonctionner (chargé au démarrage)           |
| Meta Pixel                     | Aucun changement — fonctionne indépendamment                    |


### 3.2 Points vérifiés


| Point                      | Statut                                                |
| -------------------------- | ----------------------------------------------------- |
| Fallback client-side       | OK — env var absente = zéro changement                |
| Tracking existant préservé | OK — `tracking.ts` inchangé                           |
| Meta Pixel intact          | OK — zéro modification                                |
| Pages protégées bloquées   | OK — BLOCKED_PREFIXES inchangé                        |
| Onboarding non impacté     | OK — dans BLOCKED_PREFIXES                            |
| Stripe non impacté         | OK — API non modifiée, checkout = redirection externe |


---

## 4. Build (ÉTAPE 4)

### 4.1 Détails build


| Paramètre | Valeur                                                                    |
| --------- | ------------------------------------------------------------------------- |
| Tag       | `ghcr.io/keybuzzio/keybuzz-client:v3.5.49-tracking-t5.3-dev`              |
| Branche   | `ph152.6-client-parity`                                                   |
| Commit    | `5d5d7df4`                                                                |
| Build     | `docker build --no-cache` sur bastion                                     |
| Digest    | `sha256:1aa8801dd7d946c5a1c6f9cca2531e5b22fbb21e694c2953cba3e9c8b2db2033` |


### 4.2 Build args injectés


| Variable                         | Valeur                       |
| -------------------------------- | ---------------------------- |
| `NEXT_PUBLIC_API_URL`            | `https://api-dev.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL`       | `https://api-dev.keybuzz.io` |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG`               |
| `NEXT_PUBLIC_META_PIXEL_ID`      | `1234164602194748`           |
| `NEXT_PUBLIC_SGTM_URL`           | `https://t.keybuzz.io`       |


### 4.3 Déploiement

```
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.49-tracking-t5.3-dev -n keybuzz-client-dev
deployment "keybuzz-client" successfully rolled out
```

Pod : `keybuzz-client-57d9b55fdf-4crkb` — `1/1 Running`

---

## 5. Validation (ÉTAPE 5)

### 5.1 Requêtes réseau vers `t.keybuzz.io`


| Requête           | URL                                                    | Status  | Type     |
| ----------------- | ------------------------------------------------------ | ------- | -------- |
| Service Worker    | `t.keybuzz.io/_/service_worker/63b0/sw_iframe.html`    | **200** | subFrame |
| **GA4 page_view** | `t.keybuzz.io/ng962?tid=G-R3QQDYEBFG&...&en=page_view` | **200** | xhr      |
| **GA4 scroll**    | `t.keybuzz.io/ng962?tid=G-R3QQDYEBFG&...&en=scroll`    | **200** | xhr      |


### 5.2 Requêtes Meta Pixel (inchangées)


| Requête         | URL                                                        | Status  |
| --------------- | ---------------------------------------------------------- | ------- |
| PageView        | `www.facebook.com/tr/?id=1234164602194748&ev=PageView`     | **200** |
| Privacy Sandbox | `www.facebook.com/privacy_sandbox/pixel/register/trigger/` | **200** |


### 5.3 Données GA4 transmises

Paramètres confirmés dans les requêtes :

- `tid=G-R3QQDYEBFG` (Measurement ID correct)
- `dl=https://client-dev.keybuzz.io/register` (page URL)
- `dt=KeyBuzz Client Portal` (page title)
- `cid=914111397.1776428335` (client ID)
- `sst.etld=google.fr` (server-side tag metadata)
- `sst.rnd=...` (server-side randomization)

---

## 6. Non-régression (ÉTAPE 6)

### 6.1 Pages testées


| Page         | Résultat | Détails                                                     |
| ------------ | -------- | ----------------------------------------------------------- |
| `/register`  | OK       | 3 plans affichés, boutons fonctionnels, tracking sGTM actif |
| `/login`     | OK       | Formulaire email + OAuth Google/Microsoft                   |
| `/dashboard` | OK       | Redirige vers /login (AuthGuard 401 = attendu)              |
| `/start`     | OK       | Redirige vers /login (AuthGuard = attendu)                  |
| `/inbox`     | OK       | Redirige vers /login (AuthGuard = attendu)                  |
| Stripe       | N/A      | API non modifiée, checkout flow intact                      |


### 6.2 Console

**Zéro erreur JavaScript.**

Seuls warnings présents :

- `[CursorBrowser] Native dialog overrides` — interne au navigateur de test
- `[TRACKING] attribution context captured` — système PH-T1 fonctionnel
- `[AuthGuard] Not authenticated (401)` — comportement normal sans session

---

## 7. Rollback

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.48-white-bg-dev -n keybuzz-client-dev
```

Alternative (rebuild sans sGTM) : retirer `--build-arg NEXT_PUBLIC_SGTM_URL=...` du build.

---

## 8. Résumé des changements


| Fichier                                     | Type    | Changement                                            |
| ------------------------------------------- | ------- | ----------------------------------------------------- |
| `src/components/tracking/SaaSAnalytics.tsx` | Modifié | `server_container_url` conditionnel + script src sGTM |
| `Dockerfile`                                | Modifié | 3 ARG/ENV ajoutés (GA4, Meta, SGTM)                   |
| `scripts/ph-t53-build-deploy.sh`            | Créé    | Script de build+deploy DEV                            |


### Commit

```
5d5d7df4 PH-T5.3: route GA4 through Addingwell sGTM server container (DEV)
```

---

## 9. État après PH-T5.3


| Service | Image DEV                   | Image PROD                         |
| ------- | --------------------------- | ---------------------------------- |
| Client  | `v3.5.49-tracking-t5.3-dev` | `v3.5.48-white-bg-prod` (inchangé) |
| API     | `v3.5.47-vault-tls-fix-dev` | `v3.5.47-vault-tls-fix-prod`       |
| Backend | `v1.0.38-vault-tls-dev`     | `v1.0.38-vault-tls-prod`           |


---

## 10. Prochaines étapes (PH-T5.4+)


| Étape                     | Description                                                        | Pré-requis              |
| ------------------------- | ------------------------------------------------------------------ | ----------------------- |
| Publier le workspace sGTM | Sortir du preview mode dans GTM                                    | Validation PH-T5.3 ✅    |
| Monitorer 24-48h          | Dashboard Addingwell + GA4 Realtime                                | Publication sGTM        |
| GA4 DebugView             | Vérifier events dans GA4 Debug                                     | Publication sGTM        |
| Promotion PROD            | Build `v3.5.49-tracking-t5.3-prod` avec les URLs PROD              | Monitoring OK           |
| Website integration       | Ajouter `server_container_url: 'https://t.keybuzz.pro'` au website | Après PROD SaaS         |
| Webhook PH-T4             | Activer `CONVERSION_WEBHOOK_ENABLED=true`                          | Après monitoring stable |
| Meta CAPI activation      | Publier le tag Meta CAPI dans sGTM                                 | Après GA4 stable        |


