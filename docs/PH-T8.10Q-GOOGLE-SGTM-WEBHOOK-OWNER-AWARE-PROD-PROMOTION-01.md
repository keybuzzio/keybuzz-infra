# PH-T8.10Q-GOOGLE-SGTM-WEBHOOK-OWNER-AWARE-PROD-PROMOTION-01 — TERMINÉ

**Verdict : GO — GOOGLE SGTM WEBHOOK OWNER-AWARE LIVE IN PROD**

> Date : 2026-04-25
> Environnement : PROD
> Type : promotion PROD du quick win Google sGTM owner-aware
> Priorité : P0

---

## Préflight

| Point | Valeur |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API | `ec56782b` (PH-T8.10P) |
| Repo clean | Oui |
| API DEV avant | `v3.5.118-google-sgtm-owner-aware-quick-win-dev` |
| API PROD avant | `v3.5.117-tiktok-native-owner-aware-prod` |
| Client PROD | `v3.5.116-marketing-owner-stack-prod` (INCHANGÉ) |
| Admin PROD | `v2.11.15-tiktok-native-owner-aware-prod` (INCHANGÉ) |

---

## Source à promouvoir

| Point vérifié | Résultat |
|---|---|
| Résolution owner-aware (L1861-1878) | **OK** — `SELECT marketing_owner_tenant_id FROM tenants` avant payload |
| `routing_tenant_id` (L1901) | **OK** — présent dans le payload GA4 MP |
| `marketing_owner_tenant_id` (L1902) | **OK** — conditionnel si owner présent |
| `owner_routed` (L1903) | **OK** — booléen dans le payload |
| Fallback legacy | **OK** — sans owner : `routingTenantId = tenantId`, `isOwnerRouted = false` |
| Outbound moderne intact | **OK** — `emitOutboundConversion` inchangé (3 refs), `resolveOutboundRoutingTenantId` intact (3 refs) |

---

## Build PROD

| Point | Valeur |
|---|---|
| Commit API | `ec56782b` |
| Tag | `v3.5.118-google-sgtm-owner-aware-quick-win-prod` |
| Digest | `sha256:c3469b3a1bdb768110ebfae585160af10dbff072e39f1b072d2985e8c6f99626` |
| Build-from-git | Confirmé (branch `ph147.4/source-of-truth`, repo clean) |
| Patch vérifié dans image | 6 occurrences owner-aware dans `dist/modules/billing/routes.js` |

---

## GitOps PROD

| Point | Valeur |
|---|---|
| Fichier manifest | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` |
| Image avant | `v3.5.117-tiktok-native-owner-aware-prod` |
| Image après | `v3.5.118-google-sgtm-owner-aware-quick-win-prod` |
| Commit infra | `2c50b30` |
| Rollback PROD | `v3.5.117-tiktok-native-owner-aware-prod` |

---

## Déploiement PROD

| Point | Valeur |
|---|---|
| Méthode | GitOps (`kubectl apply -f` manifest) |
| Rollout | Réussi |
| Pod actif | `keybuzz-api-67cf4747cb-6pf58` (Running, 1/1, 0 restarts) |
| Image runtime | `v3.5.118-google-sgtm-owner-aware-quick-win-prod` |
| Health | `{"status":"ok"}` |

---

## Validation structurelle PROD

| Point | Attendu | Résultat |
|---|---|---|
| `routing_tenant_id` dans compilé | Présent | **OK** (6 occurrences) |
| `marketing_owner_tenant_id` dans compilé | Présent | **OK** |
| `owner_routed` dans compilé | Présent | **OK** |
| `CONVERSION_WEBHOOK_ENABLED` | `true` | **OK** |
| `CONVERSION_WEBHOOK_URL` | `https://t.keybuzz.io/mp/collect` | **OK** |
| `GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG` | **OK** |
| `GA4_MP_API_SECRET` | Défini | **OK** |
| Outbound moderne intact | Présent | **OK** (5 refs) |
| Owner-scoped metrics | Intact | **OK** (4 refs) |
| TikTok natif | Intact | **OK** (4 refs) |

---

## Validation runtime contrôlée PROD

Validation exécutée dans le pod PROD via script Node.js reproduisant la logique de résolution owner-aware de `emitConversionWebhook`.

### CAS A — Owner-mapped

| Champ | Attendu | Résultat |
|---|---|---|
| `tenant_id` | Tenant enfant runtime | `test-owner-runtime-p-modeeozl` |
| `routing_tenant_id` | Owner KBC | `keybuzz-consulting-mo9zndlk` |
| `marketing_owner_tenant_id` | Owner KBC | `keybuzz-consulting-mo9zndlk` |
| `owner_routed` | `true` | `true` |
| **PASS** | | **true** |

### CAS B — Legacy (sans owner)

| Champ | Attendu | Résultat |
|---|---|---|
| `tenant_id` | Tenant lui-même | `romruais-gmail-com-mn7mc6xl` |
| `routing_tenant_id` | = tenant_id | `romruais-gmail-com-mn7mc6xl` |
| `marketing_owner_tenant_id` | ABSENT | `ABSENT` |
| `owner_routed` | `false` | `false` |
| **PASS** | | **true** |

### ENV VARS

| Variable | Valeur |
|---|---|
| `CONVERSION_WEBHOOK_ENABLED` | `true` |
| `CONVERSION_WEBHOOK_URL` | SET |
| `GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG` |
| `GA4_MP_API_SECRET` | SET |

---

## Validation Addingwell / sGTM

Non nécessaire pour cette phase.

Les nouveaux champs (`routing_tenant_id`, `marketing_owner_tenant_id`, `owner_routed`) sont des paramètres d'événement GA4 Measurement Protocol additionnels. sGTM les reçoit en passthrough sans modification. Aucune reconfiguration Addingwell/sGTM requise.

---

## Non-régression

| Surface | Attendu | Résultat |
|---|---|---|
| Meta owner-aware (CAPI) | Intact | **OK** (4 refs) |
| TikTok owner-aware (Events API) | Intact | **OK** (11 refs) |
| Owner-scoped metrics | Intact | **OK** (4 refs) |
| Owner-scoped funnel | Intact | **OK** (3 refs) |
| Admin PROD | `v2.11.15-tiktok-native-owner-aware-prod` | **INCHANGÉ** |
| Client PROD | `v3.5.116-marketing-owner-stack-prod` | **INCHANGÉ** |
| API DEV | `v3.5.118-google-sgtm-owner-aware-quick-win-dev` | **INCHANGÉ** |
| API PROD health | OK | **OK** |

---

## Digest

```
ghcr.io/keybuzzio/keybuzz-api:v3.5.118-google-sgtm-owner-aware-quick-win-prod
sha256:c3469b3a1bdb768110ebfae585160af10dbff072e39f1b072d2985e8c6f99626
```

---

## Rollback PROD

```bash
# Manifest : keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
# Revenir à :
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.117-tiktok-native-owner-aware-prod
# Appliquer :
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

---

## Gaps restants

| # | Gap | Description |
|---|---|---|
| G1 | Pas de destination native `google_ads` first-class | Google Ads n'a pas d'adapter natif comme Meta CAPI ou TikTok Events API |
| G2 | Google absent de l'UI Destinations Admin | Admin > Destinations n'affiche pas Google comme plateforme configurable |
| G3 | Ads Accounts Google encore "Bientôt" | L'interface Admin affiche "Bientôt" pour Google Ads Accounts |
| G4 | GA4 browser PROD possiblement inactif | Le pixel GA4 côté browser (gtag.js) peut ne pas être injecté en PROD |
| G5 | Integration Guide potentiellement désynchronisée | Le guide d'intégration marketing peut ne pas refléter le comportement owner-aware du pipeline Google/sGTM |
| G6 | Validation runtime end-to-end non réalisée | Le test valide la logique owner dans le pod, mais pas un vrai flow `checkout.session.completed` complet jusqu'à sGTM |

---

## Client/Admin PROD inchangés

**Oui** — confirmé :
- Client PROD : `v3.5.116-marketing-owner-stack-prod` (inchangé)
- Admin PROD : `v2.11.15-tiktok-native-owner-aware-prod` (inchangé)

---

## Conclusion

**GOOGLE SGTM WEBHOOK OWNER-AWARE LIVE IN PROD — KBC OWNER TRUTH NOW FLOWS THROUGH GOOGLE LEGACY PIPELINE — META/TIKTOK PRESERVED — CLIENT/ADMIN PROD UNCHANGED**

La promotion PH-T8.10Q est terminée avec succès :
- Le pipeline legacy Google/sGTM (`emitConversionWebhook`) est désormais owner-aware en PROD
- Un flow owner-mappé avec `gclid` envoie au pipeline sGTM une vérité owner-aware exploitable
- `tenant_id` reste le tenant runtime enfant (vérité business)
- `routing_tenant_id` = owner KBC quand applicable
- `marketing_owner_tenant_id` présent quand applicable
- `owner_routed = true` pour owner-mappé, `false` sinon
- Le comportement legacy sans owner reste intact
- Meta CAPI et TikTok Events API restent intacts
- Owner-scoped metrics et funnel restent intacts

Rapport : `keybuzz-infra/docs/PH-T8.10Q-GOOGLE-SGTM-WEBHOOK-OWNER-AWARE-PROD-PROMOTION-01.md`
