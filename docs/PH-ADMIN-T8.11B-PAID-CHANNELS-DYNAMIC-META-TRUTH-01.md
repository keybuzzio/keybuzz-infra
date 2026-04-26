# PH-ADMIN-T8.11B-PAID-CHANNELS-DYNAMIC-META-TRUTH-01 — TERMINÉ

**Verdict : GO**

## KEY

KEY-192 — rendre Paid Channels dynamique et aligner la vérité Meta spend/KPI.

---

## Préflight

| Point | Valeur |
|---|---|
| Admin branche | `main` |
| Admin HEAD (avant) | `0c7f2a0` |
| Admin clean | Oui |
| Admin DEV image (avant) | `v2.11.19-ad-accounts-kpi-foundation-dev` |
| API DEV image | `v3.5.120-linkedin-launch-readiness-dev` — inchangée |
| API PROD image | `v3.5.120-linkedin-launch-readiness-prod` — inchangée |
| PROD inchangée | Confirmé |

---

## Audit

### Parties hardcodées dans Paid Channels (avant)

| Élément | Hardcodé ? |
|---|---|
| `PLATFORMS` array (4 objets) | 100% statique — `spend.status: 'none'` pour toutes |
| Stat cards | Calculées sur données statiques — toujours 0/4 spend |
| SummaryTable | Lecture du tableau hardcodé |
| PlatformCard Meta | `detail: 'Aucune API Meta Ads connectee'` — **faux** |
| Note en bas de page | Statique — dit "pas encore importées" — **faux pour Meta** |

### Données réelles déjà disponibles

| Page | Données Meta réelles |
|---|---|
| Metrics (`/metrics`) | Spend total, by_channel (meta), impressions, clicks, CAC, ROAS |
| Ad Accounts (`/marketing/ad-accounts`) | 1 compte Meta actif, `last_sync_at: 2026-04-23`, `status: active` |

### Données DEV vérifiées

| Table | Tenant | Platform | Rows | Total spend | Période |
|---|---|---|---|---|---|
| `ad_platform_accounts` | `keybuzz-consulting-mo9y479d` | meta | 1 compte actif | — | créé 2026-04-22 |
| `ad_spend` | (global) | meta | 16 jours | 445.20 GBP | 2026-03-16 → 2026-03-31 |
| `ad_spend_tenant` | `keybuzz-consulting-mo9y479d` | meta | 16 jours | 445.20 GBP | 2026-03-16 → 2026-03-31 |

### Endpoints API existants

| Endpoint | Suffisant ? |
|---|---|
| `GET /ad-accounts/` | **OUI** — retourne `platform`, `status`, `last_sync_at`, `last_error` |
| `GET /metrics/overview` | **OUI** — retourne `spend.spend_available`, `by_channel` |

**Conclusion : aucun nouvel endpoint API nécessaire.**

---

## Design

| Point | Décision retenue |
|---|---|
| Source de vérité Meta | `GET /api/admin/marketing/ad-accounts?tenantId=X` — si ≥1 compte `platform: 'meta'` + `status: 'active'` → Meta spend = `'active'` |
| Stat cards dynamiques | `spendReady` calculé à partir des comptes connectés réels |
| Niveau de détail Meta | Nombre de comptes, dernière synchro (relative), mention erreur si applicable |
| Google/TikTok/LinkedIn | Restent `'none'` (vérité) |
| Besoin API supplémentaire | Aucun |
| Tenant ID source | `useCurrentTenant()` du TenantContext Admin |

---

## Patch Admin

### Fichier modifié

`keybuzz-admin-v2/src/app/(admin)/marketing/paid-channels/page.tsx`

### Changements clés

1. **`BASE_PLATFORMS`** : tableau statique de base (fallback quand pas de comptes)
2. **`enrichPlatforms(base, accounts)`** : enrichit dynamiquement le spend status quand des comptes actifs existent
3. **`useEffect` fetch** : au mount, fetch `GET /api/admin/marketing/ad-accounts?tenantId=X`
4. **`useMemo`** : `platforms = enrichPlatforms(BASE_PLATFORMS, accounts)`
5. **Stat cards** : calculées à partir de `platforms` enrichi
6. **Note conditionnelle** : bleue si 0 spend, verte si ≥1 spend
7. **Tenant warning** : message amber si aucun tenant sélectionné
8. **Loading state** : spinner sur la carte Spend pendant le fetch
9. **Ajout `platform_key`** : champ pour matcher les comptes API (meta/google/tiktok/linkedin)
10. **Lien Ad Accounts** : ajouté dans les links Meta

### Diff statistique

- 1 fichier modifié
- 142 insertions, 27 suppressions

---

## Patch API

**Aucun patch API.** L'endpoint `GET /ad-accounts/` existant retourne toutes les informations nécessaires.

---

## Validation DEV

### Pré-build (structurelle)

| Cas | Attendu | Résultat |
|---|---|---|
| Vérité Meta (tenant avec compte) | `spend.status: 'active'`, détail synchro | OK |
| Honnêteté Google/TikTok/LinkedIn | `spend.status: 'none'` | OK |
| Tenant sans compte | 0/4 spend, texte "Aucune API…" | OK |
| Stat cards dynamiques | Calculées sur données enrichies | OK |
| Note conditionnelle | Bleue si 0, verte si ≥1 | OK |
| Tenant non sélectionné | Bannière amber | OK |

### Vérification API directe

| Tenant | `GET /ad-accounts/` count | Meta actif ? |
|---|---|---|
| `keybuzz-consulting-mo9y479d` | 1 | OUI — `platform: meta`, `status: active`, `last_sync: 2026-04-23` |
| `proof-no-owner-t810b-mocqwkvo` | 0 | Non |

---

## Non-régression

| Page | Résultat |
|---|---|
| `/metrics` | OK — charge correctement |
| `/marketing/ad-accounts` | OK — charge correctement |
| `/marketing/integration-guide` | OK — charge correctement |
| `/marketing/destinations` | OK — charge correctement |

---

## Build

| Élément | Valeur |
|---|---|
| Commit Admin | `3b0bc85` |
| Message | `PH-ADMIN-T8.11B: Paid Channels dynamic truth -- Meta spend/KPI now reflected from real ad_platform_accounts (KEY-192)` |
| Image DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.20-paid-channels-dynamic-dev` |
| Digest | `sha256:072ac9b8ff2f30080f10b2e2da70dd69004ee0998fb32bb70945a4203845a8fd` |
| Build | `docker build --no-cache` sur bastion |

---

## GitOps

| Manifest | Image avant | Image après |
|---|---|---|
| `k8s/keybuzz-admin-v2-dev/deployment.yaml` | `v2.11.19-ad-accounts-kpi-foundation-dev` | `v2.11.20-paid-channels-dynamic-dev` |

Commit infra : `9910cb8`

---

## Déploiement

| Élément | Valeur |
|---|---|
| Méthode | `kubectl apply -f deployment.yaml` |
| Rollout | `deployment "keybuzz-admin-v2" successfully rolled out` |
| Pod | `keybuzz-admin-v2-594b8cd798-9gfdj` |
| Status | Running 1/1 |
| Restarts | 0 |
| Image runtime | `v2.11.20-paid-channels-dynamic-dev` |

---

## Validation navigateur

### Bundle inspection

| Test | Résultat |
|---|---|
| `enrichPlatforms` | Minifié (attendu) |
| `ad-accounts` fetch path | TROUVÉ |
| "Ads connecte" (texte dynamique) | TROUVÉ |
| "Spend / KPI actifs" (note verte) | TROUVÉ |
| `useCurrentTenant` | TROUVÉ |
| Ancien texte statique | DISPARU |

### Test navigateur — Tenant sans Meta (Proof No Owner)

| Test | Résultat |
|---|---|
| Stat card Spend | 0/4 — **correct** (pas de compte Meta) |
| Meta Spend | "Aucune API Meta Ads connectee" — **correct** |
| Note | Bleue "Aucune plateforme…" — **correct** |

### Test navigateur — Tenant avec Meta (KeyBuzz Consulting)

| Test | Résultat |
|---|---|
| Tenant sélectionné | KeyBuzz Consulting |
| Stat card Tracking | **4/4** |
| Stat card Conversions | **3/4** |
| Stat card Spend | **1/4** |
| Meta Spend status | **Actif** |
| Meta Spend detail | **"1 compte Meta Ads connecte et actif. Derniere synchro : il y a 3j. Spend, impressions et clicks importes."** |
| Meta next action | **"Spend Meta actif — enrichir avec breakdown campagnes si besoin"** |
| Google Spend | Non connecte — honnête |
| TikTok Spend | Non connecte — honnête |
| LinkedIn Spend | Non connecte — honnête |

---

## Rollback DEV

```
Image Admin DEV : v2.11.19-ad-accounts-kpi-foundation-dev
Manifest : k8s/keybuzz-admin-v2-dev/deployment.yaml
```

---

## Conclusion

**GO** — Paid Channels reflète correctement la réalité Meta spend/KPI.

La page est désormais dynamique :
- Fetch les comptes `ad_platform_accounts` au mount via la route BFF existante
- Enrichit le statut spend de chaque plateforme en fonction des comptes actifs réels
- Meta affiche correctement 1/4 spend connecté avec dernière synchro
- Google/TikTok/LinkedIn restent honnêtement "Non connecte"
- Un tenant sans comptes Meta montre correctement 0/4
- Aucune API modifiée — l'endpoint existant suffisait
- Note conditionnelle : verte quand spend actif, bleue quand aucun spend
- Aucune régression sur les pages existantes

**Prochaine phase possible : promotion PROD.**

---

## PROD inchangée

Oui — aucun changement PROD dans cette phase.

- API PROD : `v3.5.120-linkedin-launch-readiness-prod` (inchangée)
- Admin PROD : `v2.11.17-paid-channels-prod` (inchangée)
