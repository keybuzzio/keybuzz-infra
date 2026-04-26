# PH-ADMIN-T8.10U-GOOGLE-ADDINGWELL-OBSERVABILITY-FOUNDATION-01 — TERMINÉ

**Verdict : GO**

## KEY

**KEY-187** — améliorer l'observabilité Google / Addingwell dans l'Admin sans faux logs natifs

---

## Préflight

| Point | Valeur |
|---|---|
| Branche Admin | `main` |
| HEAD Admin (avant) | `8a12901` |
| Image DEV Admin (avant) | `v2.11.17-google-admin-visibility-dev` |
| Image PROD Admin | `v2.11.16-google-admin-visibility-prod` — **INCHANGÉE** |
| API branche (lecture) | `ph147.4/source-of-truth`, HEAD `ec56782b` |
| API PROD | `v3.5.118-google-sgtm-owner-aware-quick-win-prod` — **INCHANGÉE** |
| Repo Admin | clean |
| Source = main | ✅ |
| Scope = DEV uniquement | ✅ |

---

## Audit des données observables

| Signal | Existe ? | Où ? | Réutilisable ? |
|---|---|---|---|
| `gclid` | ✅ | `signup_attribution.gclid` | Oui, via SQL |
| `utm_source=google` | ✅ | `signup_attribution.utm_source` | Oui, via SQL |
| `utm_campaign` | ✅ | `signup_attribution.utm_campaign` | Oui, via SQL |
| `conversion_sent_at` | ✅ | `signup_attribution.conversion_sent_at` | Oui — horodatage envoi sGTM |
| `marketing_owner_tenant_id` | ✅ | `signup_attribution.marketing_owner_tenant_id` | Oui |
| `landing_url` | ✅ | `signup_attribution.landing_url` | Oui |
| Delivery logs Google natifs | ❌ | N'existe pas — sGTM opaque | Non |
| Status HTTP sGTM | ❌ | Console log API uniquement | Non lisible Admin |
| Endpoint Admin existant | ❌ | Aucun proxy vers `signup_attribution` | **Créé dans cette phase** |

**Conclusion** : les données existent en DB, mais aucun endpoint ne les exposait. Circuit API + proxy créé.

---

## Design retenu

| Sujet | Décision | Pourquoi |
|---|---|---|
| Architecture | API endpoint + Admin proxy + UI | Circuit minimal pour signaux réels |
| Endpoint API | `GET /outbound-conversions/google-observability` (read-only) | 1 SELECT, aucun write |
| Données | Counts gclid/utm/conversions + derniers signaux | Répond aux 4 questions support |
| Proxy Admin | `src/app/api/admin/marketing/google-observability/route.ts` | Pattern standard |
| UI | Bloc "Observabilité" enrichi sur Google Tracking page | Pas de nouvelle page |
| Limites | Encart "Observabilité indirecte" violet | Pas de faux delivery log |

---

## Patch

### API (`keybuzz-api`)

| Fichier | Action |
|---|---|
| `src/modules/outbound-conversions/google-observability.ts` | **CRÉÉ** — endpoint read-only |
| `src/app.ts` | **MODIFIÉ** — import + registration du plugin |

- Commit : `6e0dac5e` — `feat(google-observability): add read-only endpoint for Google/sGTM signals from signup_attribution (KEY-187)`
- Branche : `ph147.4/source-of-truth`

### Admin (`keybuzz-admin-v2`)

| Fichier | Action |
|---|---|
| `src/app/api/admin/marketing/google-observability/route.ts` | **CRÉÉ** — proxy Next.js |
| `src/app/(admin)/marketing/google-tracking/page.tsx` | **MODIFIÉ** — +441/-235 lignes |

- Commit : `107344d` — `feat(google-tracking): add observability section with live signals from signup_attribution (KEY-187)`
- Branche : `main`

### Changements UI (page Google Tracking enrichie)

1. **Bloc "Observabilité Google — Signaux réels"** — 4 cartes stats : gclid capturés, utm_source=google, conversions envoyées sGTM, signups totaux
2. **Dernier gclid vu** — tenant, timestamp, campagne, owner tenant
3. **Dernière conversion envoyée (sGTM)** — tenant, timestamp, owner
4. **Encart violet "Observabilité indirecte"** — explique la source (`signup_attribution`), les limites (pas ce que Google a reçu), et le rôle d'Addingwell
5. **Bouton "Actualiser"** — refresh manuel des signaux
6. **RequireTenant wrapper** — les signaux sont contextualisés par tenant
7. **Sections existantes préservées** — bandeau status, architecture, comparatif, checklist, ressources

---

## Validation DEV (code)

| Test | Attendu | Résultat |
|---|---|---|
| Bundle `Observabilit` | Présent dans page.js | ✅ 1 match |
| Bundle `sGTM` | Présent | ✅ |
| Bundle `gclid` | Présent | ✅ |
| Bundle `conversion_sent` | Présent | ✅ |
| Bundle `indirecte` | Présent | ✅ |
| Proxy route compilée | `route.js` dans google-observability/ | ✅ 7KB |

---

## Non-régression

| Surface | Attendu | Résultat |
|---|---|---|
| `/marketing/google-tracking` | Page enrichie | ✅ |
| `/marketing/destinations` | Intact | ✅ |
| `/marketing/funnel` | Intact | ✅ |
| `/marketing/integration-guide` | Intact | ✅ |
| Erreurs console | Pas de nouvelles | ✅ (seul `CLIENT_FETCH_ERROR` préexistant) |
| PROD Admin | Inchangée | ✅ `v2.11.16-google-admin-visibility-prod` |
| PROD API | Inchangée | ✅ `v3.5.118-google-sgtm-owner-aware-quick-win-prod` |

---

## Build DEV

| Image | Tag | Digest |
|---|---|---|
| API DEV | `v3.5.119-google-observability-dev` | `sha256:4a4c0d3d128f16a8fb00fadc0633f85c6feddfd7d969043ffb673ae874b8aeca` |
| Admin DEV | `v2.11.18-google-observability-dev` | `sha256:b33a8f76bd2c1a7631303211ecef0dbfeb153ad961250823a8ca8bc31de3ef5d` |

Build-from-git : ✅ (commit + push AVANT build)

---

## GitOps DEV

| Fichier manifest | Image avant | Image après |
|---|---|---|
| `k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.118-google-sgtm-owner-aware-quick-win-dev` | `v3.5.119-google-observability-dev` |
| `k8s/keybuzz-admin-v2-dev/deployment.yaml` | `v2.11.17-google-admin-visibility-dev` | `v2.11.18-google-observability-dev` |

Commit infra : `3e24c45` — `gitops(dev): deploy API v3.5.119-google-observability-dev + Admin v2.11.18-google-observability-dev (KEY-187)`

---

## Déploiement DEV

| Pod | Image runtime | Status | Restarts |
|---|---|---|---|
| `keybuzz-api-698f9cbb79-6rs7t` | `v3.5.119-google-observability-dev` | Running | 0 |
| `keybuzz-admin-v2-8455684b6f-r7hnh` | `v2.11.18-google-observability-dev` | Running | 0 |

Rollout : ✅ les deux deployments ont roll out avec succès.

---

## Validation navigateur DEV

| Test navigateur | Attendu | Résultat |
|---|---|---|
| Page Google Tracking charge | Oui | ✅ |
| Bloc "Observabilité Google — Signaux réels" | Visible avec stats live | ✅ 4 cartes : 0/1/0/1 |
| Bouton "Actualiser" | Présent, fonctionnel | ✅ |
| "Dernier gclid vu" | Info ou "Aucun gclid capturé" | ✅ (tenant test) |
| "Dernière conversion sGTM" | Info ou "Aucune conversion" | ✅ (tenant test) |
| Encart "Observabilité indirecte" | Message honnête violet | ✅ mentionne `signup_attribution` |
| Architecture diagram | KeyBuzz API → sGTM → Google Ads | ✅ |
| Tableau comparatif | Badges corrects | ✅ "Via sGTM", "Signaux indirects" |
| "Pourquoi pas de destination Google native" | Explication honnête | ✅ |
| Checklist activation | 5 étapes | ✅ |
| Qui fait quoi | KeyBuzz vs Agence | ✅ |
| Ressources | Liens fonctionnels | ✅ |
| Destinations intact | Page fonctionnelle | ✅ |
| Integration Guide intact | Contenu complet | ✅ |
| Erreurs console nouvelles | Aucune | ✅ |

---

## Rollback DEV

```
# API DEV
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.118-google-sgtm-owner-aware-quick-win-dev -n keybuzz-api-dev

# Admin DEV
kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.11.17-google-admin-visibility-dev -n keybuzz-admin-v2-dev
```

---

## Conclusion

### Verdict : GO

L'observabilité Google est opérationnelle en DEV avec des signaux réels :

1. **Circuit complet** : API endpoint → Admin proxy → UI bloc observabilité
2. **Signaux réels** : gclid capturés, utm_source=google, conversions envoyées sGTM, total signups — tous issus de `signup_attribution`
3. **Derniers signaux** : dernier gclid vu (tenant, timestamp, campagne, owner) et dernière conversion sGTM
4. **Honnêteté** : encart "Observabilité indirecte" explique clairement les limites — pas de faux delivery logs
5. **Architecture préservée** : Addingwell/sGTM = transport, KeyBuzz = vérité business
6. **Aucune régression** : toutes les pages marketing intactes
7. **PROD inchangée** : aucun impact

### Prochaine phase suggérée

`PH-ADMIN-T8.10V-GOOGLE-OBSERVABILITY-PROD-PROMOTION-01` — promotion PROD du circuit observabilité (API + Admin)

---

## PROD inchangée

**oui** — aucun manifest PROD modifié, aucune image PROD changée.

- API PROD : `v3.5.118-google-sgtm-owner-aware-quick-win-prod`
- Admin PROD : `v2.11.16-google-admin-visibility-prod`

---

## Rapport

`keybuzz-infra/docs/PH-ADMIN-T8.10U-GOOGLE-ADDINGWELL-OBSERVABILITY-FOUNDATION-01.md`
