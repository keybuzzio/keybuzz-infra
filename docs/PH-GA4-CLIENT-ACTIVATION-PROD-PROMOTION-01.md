# PH-GA4-CLIENT-ACTIVATION-PROD-PROMOTION-01 — Promotion PROD

> **Date** : 28 avril 2026
> **KEY** : KEY-212
> **Objectif** : Promouvoir l'activation GA4 client en PROD
> **Prérequis** : PH-GA4-CLIENT-ACTIVATION-01 (DEV validé)

---

## 1. Préflight

| Élément | Valeur |
|---|---|
| Client PROD avant | `v3.5.121-linkedin-tracking-hardened-prod` |
| Client DEV validé | `v3.5.122-ga4-activation-dev` |
| Client repo | Propre, `62d3110` |
| Code source modifié | **Aucun** — build args uniquement |
| Rapport DEV | `PH-GA4-CLIENT-ACTIVATION-01.md` disponible |

---

## 2. Build PROD

| Élément | Valeur |
|---|---|
| Tag | `ghcr.io/keybuzzio/keybuzz-client:v3.5.122-ga4-activation-prod` |
| Digest | `sha256:2a652fe2073e2a932b291f8c4fc95a562e23ec9e24473ff659a0fee478f7e577` |
| Commit | `62d3110` |
| `--no-cache` | Oui |

### Build args

| Arg | Valeur |
|---|---|
| `NEXT_PUBLIC_APP_ENV` | `production` |
| `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG` |
| `NEXT_PUBLIC_SGTM_URL` | `https://t.keybuzz.pro` |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | `9969977` |

---

## 3. GitOps

```yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.122-ga4-activation-prod  # rollback: v3.5.121-linkedin-tracking-hardened-prod
```

---

## 4. Déploiement

| Élément | Valeur |
|---|---|
| Namespace | `keybuzz-client-prod` |
| Rollout | `successfully rolled out` |
| Pod | `1/1 Running`, 0 restarts |

---

## 5. Validation PROD

### 5.1 Layout chunk — Code compilé

| Check | Résultat |
|---|---|
| GA4 `G-R3QQDYEBFG` | ✅ Présent |
| sGTM `t.keybuzz.pro` | ✅ Présent |
| `server_container_url` | ✅ Présent |
| Cross-domain `accept_incoming` | ✅ Présent |
| `send_page_view` | ✅ Présent |
| Consent `ad_storage` | ✅ Présent |
| `dataLayer` | ✅ Présent |
| Google Ads `AW-` | ✅ **Absent** |
| LinkedIn `9969977` | ✅ Présent |
| Funnel `/register` | ✅ Présent |
| Blocked `/dashboard` | ✅ Présent |

### 5.2 Module tracking

| Check | Résultat |
|---|---|
| Chunk | `6654-4605bc170ea88610.js` |
| `signup_start` | ✅ |
| `signup_step` | ✅ |
| `signup_complete` | ✅ |
| `begin_checkout` | ✅ |
| `purchase` | ✅ |
| `window.gtag` ref | ✅ |

### 5.3 SSR — Pages servies

| Page | GA4 | gtag | sGTM | AW- | Attendu |
|---|---|---|---|---|---|
| `/register` | ✅ | ✅ | ✅ | ✅ absent | Funnel — GA4 actif |
| `/dashboard` | ✅ absent | — | — | — | Blocked — GA4 absent |
| `/inbox` | ✅ absent | — | — | — | Blocked — GA4 absent |

### 5.4 HTTPS externe

```
curl -sL https://client.keybuzz.io/register → G-R3QQDYEBFG, gtag, t.keybuzz.pro
                                              AW- : ABSENT ✅
```

### 5.5 Sécurité

| Check | Résultat |
|---|---|
| `AW-` dans tout le bundle | 0 fichiers ✅ |
| `api-dev.keybuzz.io` dans PROD | 0 fichiers ✅ |

### 5.6 Non-régression CAPI

| Destination | Type | Statut | Dernier test |
|---|---|---|---|
| KeyBuzz Consulting — Meta CAPI | `meta_capi` | ✅ Active | success |
| KeyBuzz Consulting — TikTok | `tiktok_events` | ✅ Active | success |
| KeyBuzz Consulting — LinkedIn CAPI | `linkedin_capi` | ✅ Active | success |

Pipeline server-side inchangé. GA4 client-side est indépendant.

---

## 6. Rollback

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.121-linkedin-tracking-hardened-prod -n keybuzz-client-prod
```

---

## 7. KEY-212 — Mise à jour

| Champ | Valeur |
|---|---|
| Image PROD | `v3.5.122-ga4-activation-prod` |
| Digest | `sha256:2a652fe2073e2a932b291f8c4fc95a562e23ec9e24473ff659a0fee478f7e577` |
| Rollback | `v3.5.121-linkedin-tracking-hardened-prod` |
| `window.gtag` | ✅ Défini sur `/register` (SSR + HTTPS confirmé) |
| GA4 Realtime | Vérification manuelle recommandée |
| `AW-` absent | ✅ Confirmé (0 fichiers dans le bundle) |
| Non-régression CAPI | ✅ Meta, TikTok, LinkedIn actifs |
| DEV API leak | ✅ 0 fichier avec `api-dev.keybuzz.io` |
| Code source modifié | **Aucun** |

---

## 8. Vérification manuelle recommandée

1. Ouvrir `https://client.keybuzz.io/register` dans Chrome DevTools
2. Console → `typeof window.gtag` → `"function"`
3. Network → requête vers `t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG`
4. GA4 Admin → Realtime → vérifier `page_view` depuis `client.keybuzz.io`
5. Naviguer vers `/dashboard` → confirmer que GA4 ne se charge pas (Network vide de gtag)

---

## 9. État DEV / PROD aligné

| Service | DEV | PROD |
|---|---|---|
| Client | `v3.5.122-ga4-activation-dev` | `v3.5.122-ga4-activation-prod` |
| API | `v3.5.123-linkedin-capi-native-dev` | `v3.5.123-linkedin-capi-native-prod` |
| Admin | `v2.11.28-marketing-surfaces-truth-alignment-dev` | `v2.11.21-marketing-surfaces-truth-alignment-prod` |

---

## 10. Verdict

```
GO — GA4 ACTIVÉ EN PROD
```

| Critère | Statut |
|---|---|
| GA4 chargé sur funnel pages | ✅ |
| sGTM `t.keybuzz.pro` | ✅ |
| Cross-domain `accept_incoming` | ✅ |
| Consent Mode v2 | ✅ |
| 5 tracking events compilés | ✅ |
| Google Ads `AW-` absent | ✅ |
| Protected pages sans GA4 | ✅ |
| CAPI Meta/TikTok/LinkedIn | ✅ Inchangé |
| Anti-doublon | ✅ Aucun double pageview/conversion |
| HTTPS externe confirmé | ✅ |
| Code source | ✅ 0 fichier modifié |
| Rollback documenté | ✅ |
