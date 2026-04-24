# PH-T7.2.3 — Website TikTok PROD Promotion

**Phase** : PH-T7.2.3-WEBSITE-TIKTOK-PROD-PROMOTION-01
**Date** : 10 avril 2026
**Environnement** : PROD
**Verdict** : **WEBSITE TIKTOK PROD READY**

---

## Preflight

| Element | Valeur |
|---|---|
| Repo | `keybuzz-website` |
| Branche | `main` |
| Commit | `29c66d2879ffb42a68a3ade536c37795df5abf94` |
| Image DEV validee | `v0.6.6-tiktok-ttclid-dev` |
| SDK TikTok | Officiel (avec `ttq._o`, `ttq._t[e]=+new Date`) |

---

## Correction SDK appliquee avant PROD

Le SDK TikTok initial (commit `4962f29`) utilisait une variante non-officielle.
Corrige en commit `29c66d2` avec le snippet officiel exact fourni par TikTok Ads Manager.

Differences corrigees :

| Element | Variante (avant) | Officiel (apres) |
|---|---|---|
| `ttq._t` | `ttq._t[e+"_"+Date.now()]={partner:o}` | `ttq._t[e]=+new Date` |
| `ttq._o` | absent | `ttq._o=ttq._o\|\|{},ttq._o[e]=n\|\|{}` |
| Variables DOM | `a`, `s` (nouvelles) | Reutilise `n`, `e` |

---

## Build et deploiement PROD

| Element | Valeur |
|---|---|
| Commit website | `29c66d2879ffb42a68a3ade536c37795df5abf94` |
| Tag image PROD | `ghcr.io/keybuzzio/keybuzz-website:v0.6.6-tiktok-ttclid-prod` |
| Digest | `sha256:c165546647eb4cd37b34fc57d172d3e4c7b6c8a6174174de6d80480dcf954b11` |
| Commit infra | `2184c048769732374044fb204ef67d29bad903ea` |
| Build | `--no-cache` depuis repo git clean |
| Build args | `GA_ID=G-R3QQDYEBFG`, `META_PIXEL=1234164602194748`, `SGTM_URL=https://t.keybuzz.pro`, `TIKTOK_PIXEL=D7HQO0JC77U2ODPGMDI0` |

---

## Validation PROD

### Bundles JS

| Verification | Resultat |
|---|---|
| `ttclid` dans pricing bundle | OK |
| `TiktokAnalyticsObject` dans analytics bundle | OK |
| `D7HQO0JC77U2ODPGMDI0` (Pixel ID) | OK |
| `ttq._o` (marqueur SDK officiel) | OK |
| `G-R3QQDYEBFG` (GA4) | OK |
| `1234164602194748` (Meta Pixel) | OK |
| `t.keybuzz.pro` (sGTM Addingwell) | OK |
| `gclid` + `fbclid` | OK |

### HTTP PROD

| Test | Resultat |
|---|---|
| `https://www.keybuzz.pro/` | HTTP 200 |
| `https://www.keybuzz.pro/pricing` | HTTP 200 |
| `https://www.keybuzz.pro/contact` | HTTP 200 |

### Pods K8s PROD

| Element | Valeur |
|---|---|
| Pod 1 | `keybuzz-website-b54fb8668-nb2jc` (Running, worker-01) |
| Pod 2 | `keybuzz-website-b54fb8668-stfc4` (Running, worker-02) |
| Next.js | 16.1.4 — Ready in 1000ms |
| Erreurs | Aucune |

---

## Non-regression

| Element | Statut |
|---|---|
| GA4 via sGTM (`t.keybuzz.pro`) | Intact |
| Meta Pixel browser-side | Intact |
| UTM forwarding (5 params) | Intact |
| gclid forwarding | Intact |
| fbclid forwarding | Intact |
| ttclid forwarding | OK (nouveau) |
| CTA pricing -> SaaS | Intact |
| Cross-domain linker GA4 | Intact |

---

## Architecture tracking PROD finale

```
Visiteur -> www.keybuzz.pro
  |
  +-- GA4 (gtag.js via t.keybuzz.pro / sGTM Addingwell)
  |     events: view_pricing, select_plan, click_signup, contact_submit
  |
  +-- Meta Pixel (fbevents.js browser-side)
  |     events: PageView, ViewContent, InitiateCheckout, Lead, Contact
  |
  +-- TikTok Pixel (events.js browser-side — SDK officiel)
  |     events: page(), ViewContent, InitiateCheckout, SubmitForm, Contact
  |     ID: D7HQO0JC77U2ODPGMDI0
  |
  +-- CTA /pricing -> client.keybuzz.io/register
        forwarding: utm_source, utm_medium, utm_campaign, utm_term,
                    utm_content, gclid, fbclid, ttclid
```

---

## Rollback

```bash
# Remettre ancien tag
cd /opt/keybuzz/keybuzz-infra
sed -i 's|v0.6.6-tiktok-ttclid-prod|v0.6.5-sgtm-addingwell-prod|' k8s/website-prod/deployment.yaml
git add k8s/website-prod/deployment.yaml
git commit -m "rollback: website PROD to v0.6.5-sgtm-addingwell"
git push origin main
kubectl apply -f k8s/website-prod/deployment.yaml
```

---

## Incident en cours de deploiement

Le premier build PROD a echoue avec `no space left on device` (Docker cache saturee a 89GB).
Resolution : `docker system prune -a -f` (58GB recuperes) puis rebuild.
Le K8s a ete rollback avec `kubectl rollout undo` pendant la resolution, puis re-deploye proprement.
Aucun impact sur la PROD pendant l'incident (pods existants non affectes).

---

## Verdict

**WEBSITE TIKTOK PROD READY**

- SDK TikTok officiel exact : OK
- `ttclid` forwarding vers SaaS : OK
- TikTok Pixel ID `D7HQO0JC77U2ODPGMDI0` : OK
- 4 events TikTok mappes : OK
- GA4 / Meta / sGTM : intacts
- UTM / gclid / fbclid : intacts
- Zero regression

**STUDIO SCOPE VERIFIED — ZERO CLIENT IMPACT**
