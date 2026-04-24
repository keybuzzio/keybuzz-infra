# PH-T6.1-WEBSITE-PROD-PROMOTION-ADDINGWELL-01 — TERMINÉ

**Verdict** : WEBSITE PROD TRACKING ACTIVE — NO REGRESSION

> **Date** : 18 avril 2026
> **Environnement** : PROD
> **Scope** : keybuzz-website uniquement — zéro impact SaaS

---

## 1. Préflight


| Élément           | Valeur                                     |
| ----------------- | ------------------------------------------ |
| Repo              | `keybuzz-website`                          |
| Branche           | `main`                                     |
| Commit            | `cc9ec960a3c85de37dad8b085b779c624acd5d86` |
| Image DEV validée | `v0.6.5-sgtm-addingwell-dev`               |
| Repo clean        | OUI                                        |


---

## 2. Build


| Élément    | Valeur                                                                                                                                                        |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Source     | repo `keybuzz-website`, branche `main`, commit `cc9ec96`                                                                                                      |
| Mode       | `build-from-git`, `--no-cache`                                                                                                                                |
| Build args | `NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro`, `GA4=G-R3QQDYEBFG`, `META=1234164602194748`, `SITE_MODE=production`, `CLIENT_APP_URL=https://client.keybuzz.io` |
| Tag PROD   | `ghcr.io/keybuzzio/keybuzz-website:v0.6.5-sgtm-addingwell-prod`                                                                                               |
| Digest     | `sha256:f7bb9753bf89f7d77b73daa3b7406e1ae0ef3bbb8b15bb45d5b6519237d967d9`                                                                                     |


---

## 3. Deploy


| Élément      | Avant                             | Après                         |
| ------------ | --------------------------------- | ----------------------------- |
| Website PROD | `v0.6.4-tracking-foundation-prod` | `v0.6.5-sgtm-addingwell-prod` |
| Pods         | 2/2 Running                       | 2/2 Running                   |
| Rollout      | —                                 | Successfully rolled out       |


---

## 4. Validation website


| Test                   | Résultat                                         | OK/NOK |
| ---------------------- | ------------------------------------------------ | ------ |
| 2 pods Running (HA)    | `1/1 Running`, 0 restarts, worker-01 + worker-02 | OK     |
| Logs propres           | `Ready in 1518ms`, aucune erreur                 | OK     |
| HTTP `www.keybuzz.pro` | 200                                              | OK     |
| Homepage               | OK                                               | OK     |
| Pricing                | OK                                               | OK     |
| CTA                    | OK                                               | OK     |


---

## 5. Validation tracking


| Test                                | Résultat                 | OK/NOK |
| ----------------------------------- | ------------------------ | ------ |
| `t.keybuzz.pro` dans HTML PROD      | Présent                  | OK     |
| `t.keybuzz.pro` dans bundles JS     | 2 fichiers               | OK     |
| `server_container_url` dans bundles | Présent                  | OK     |
| GA4 ID `G-R3QQDYEBFG`               | Présent (HTML + bundles) | OK     |
| Meta Pixel `fbevents.js`            | Présent (inchangé)       | OK     |
| Meta Pixel ID `1234164602194748`    | Présent (inchangé)       | OK     |
| `t.keybuzz.pro/gtag/js` accessible  | HTTP 200                 | OK     |
| Events `view_pricing`               | Présent dans bundles     | OK     |
| Events `contact_submit`             | Présent dans bundles     | OK     |
| Aucune erreur logs                  | Confirmé                 | OK     |


### Routage PROD confirmé

```
gtag.js chargé depuis :     https://t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG  (HTTP 200)
GA4 hits routés via :        https://t.keybuzz.pro (server_container_url)
Meta Pixel :                 inchangé (browser-side direct)
```

---

## 6. Non-régression


| Test                                                     | Résultat                                     | OK/NOK |
| -------------------------------------------------------- | -------------------------------------------- | ------ |
| UTM forwarding (utm_source/medium/campaign/term/content) | Intact (code non touché)                     | OK     |
| gclid/fbclid forwarding                                  | Intact (`gclid` trouvé dans bundles)         | OK     |
| Cross-domain GA4 linker                                  | Intact (`keybuzz.pro` + `client.keybuzz.io`) | OK     |
| CTA pricing → `client.keybuzz.io/register`               | Intact                                       | OK     |
| Consent Mode v2                                          | Intact                                       | OK     |
| Meta Pixel events (ViewContent, Lead, Contact)           | Intact                                       | OK     |


---

## 7. Rollback

### GitOps standard

```yaml
# Remettre dans keybuzz-infra/k8s/website-prod/deployment.yaml :
image: ghcr.io/keybuzzio/keybuzz-website:v0.6.4-tracking-foundation-prod
```

Puis `git commit && git push && kubectl apply -f`

### Secours immédiat

```bash
kubectl set image deployment/keybuzz-website \
  keybuzz-website=ghcr.io/keybuzzio/keybuzz-website:v0.6.4-tracking-foundation-prod \
  -n keybuzz-website-prod
```

---

## 8. Références


| Élément               | Valeur                                                                    |
| --------------------- | ------------------------------------------------------------------------- |
| SHA website           | `cc9ec960a3c85de37dad8b085b779c624acd5d86`                                |
| Tag PROD              | `v0.6.5-sgtm-addingwell-prod`                                             |
| Digest PROD           | `sha256:f7bb9753bf89f7d77b73daa3b7406e1ae0ef3bbb8b15bb45d5b6519237d967d9` |
| SHA infra             | `0374596`                                                                 |
| Ancien tag (rollback) | `v0.6.4-tracking-foundation-prod`                                         |


---

## 9. Conclusion

- `www.keybuzz.pro` route maintenant ses hits GA4 via `t.keybuzz.pro` (Addingwell sGTM)
- Server container actif : `server_container_url: https://t.keybuzz.pro`
- Meta Pixel inchangé (browser-side direct)
- Events marketing intacts
- UTM / gclid / fbclid forwarding intact
- Cross-domain GA4 intact
- 2 pods HA, 0 erreurs
- Aucune modification de code par rapport au DEV validé (même commit `cc9ec96`)
- Aucun impact SaaS

**WEBSITE PROD TRACKING ACTIVE — NO REGRESSION**

STOP