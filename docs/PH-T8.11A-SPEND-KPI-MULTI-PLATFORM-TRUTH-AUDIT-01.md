# PH-T8.11A-SPEND-KPI-MULTI-PLATFORM-TRUTH-AUDIT-01 — TERMINÉ

**Verdict : GO — Cas A (une plateforme spend/KPI est DÉJÀ opérationnelle)**

> Meta Ads est fonctionnel en PROD avec des données réelles.
> Le cockpit Paid Channels ne reflète pas cette réalité.
> Le prochain chantier est de rendre le cockpit dynamique et d'enrichir Meta.

**KEY** : KEY-191 — audit vérité spend/KPI multi-plateforme pour le cockpit Admin

---

## Préflight

| Repo | Branche | HEAD | Clean |
|---|---|---|---|
| Admin | `main` | `0c7f2a0` — PH-ADMIN-T8.10Y Paid Channels | Oui |
| API (local) | `ph-t72/tiktok-tracking-dev` | `bfb9cdc2` — TikTok Pixel | Non (modifications non stagées) |
| API (bastion) | `main` déployé | `v3.5.120-linkedin-launch-readiness` | DEV + PROD |

Mode : **lecture seule** — aucune modification effectuée.

---

## Audit Admin

### Ce que les surfaces Admin disent vs ce qu'elles prouvent

| Surface Admin | Ce que ça dit | Ce que ça prouve réellement |
|---|---|---|
| `/marketing/paid-channels` | 0/4 spend connecté, 4/4 tracking, 3/4 conversions | **100% statique/hardcodé** — aucun fetch API, tableau `PLATFORMS` constant, aucune donnée dynamique. Ment sur Meta qui EST connecté. |
| `/marketing/ad-accounts` | CRUD comptes Meta Ads + sync spend | **Vrai pipeline API** — appels réels vers `/ad-accounts`. Création, édition, sync, suppression. Résultat de sync avec spend + rows_upserted. Meta uniquement (plateforme figée en UI). |
| `/metrics` | Spend total, by_channel, impressions, clicks, CTR, CPC, CAC, ROAS, MRR | **Vrai pipeline API** — appelle `/metrics/overview`. Données réelles si elles existent en base. Aucun mock. FX ECB temps réel. |

### Ambiguïtés identifiées

1. `Paid Channels` dit "0/4 spend" alors que Meta EST connecté avec 16j de données réelles
2. `Ad Accounts` ne permet que Meta (plateforme hardcodée dans le formulaire de création)
3. `Metrics` affiche le spend réel mais ne précise pas d'où il vient (quelle sync, quelle fraîcheur)

---

## Audit API / Data Spend

### Architecture technique existante

| Couche | Fichier | Lignes | Rôle |
|---|---|---|---|
| Routes CRUD | `src/modules/ad-accounts/routes.ts` | 239 | CRUD comptes + sync |
| Métriques | `src/modules/metrics/routes.ts` | 477 | `/metrics/overview` (KPI complets) |
| Métriques settings | `src/modules/metrics/settings-routes.ts` | — | Devise, exclusion CAC |
| Adaptateur Meta | `src/modules/metrics/ad-platforms/meta-ads.ts` | 91 | Client Meta Graph API v21.0 (insights) |
| Adaptateur Meta CAPI | `src/modules/outbound-conversions/adapters/meta-capi.ts` | 134 | Conversions server-side |
| Adaptateur TikTok Events | `src/modules/outbound-conversions/adapters/tiktok-events.ts` | 130 | Conversions server-side |
| Crypto ads | `src/lib/ads-crypto.ts` | — | Chiffrement tokens AES-256-GCM |

### Types de destinations prévus dans le code

```typescript
const DESTINATION_TYPES = [
  'webhook',       // ✅ Implémenté
  'meta_capi',     // ✅ Implémenté (adaptateur + données PROD)
  'tiktok_events', // ✅ Implémenté (adaptateur + données PROD)
  'google_ads',    // ⚠️ Type prévu, AUCUN adaptateur
  'linkedin_capi', // ⚠️ Type prévu, AUCUN adaptateur
];
```

### Adaptateurs existants vs prévus

| Type | Adaptateur fichier | Implémenté | En PROD |
|---|---|---|---|
| `meta_capi` | `adapters/meta-capi.ts` | Oui (134 lignes) | Oui — destination active |
| `tiktok_events` | `adapters/tiktok-events.ts` | Oui (130 lignes) | Oui — destination active |
| `google_ads` | — | **Non** | Non |
| `linkedin_capi` | — | **Non** | Non |

### Données réelles en base

#### DEV

| Table | Lignes | Contenu |
|---|---|---|
| `ad_platform_accounts` | 3 | 1 compte Meta actif (`1485150039295668`) + 2 revoked test |
| `ad_spend` | 16 | 16 jours Meta, channel=`meta`, GBP, mars 2026 |
| `ad_spend_tenant` | 16 | Même data, tenant=`keybuzz-consulting-mo9y479d` |
| `metrics_tenant_settings` | 2 | Devise d'affichage + exclusion CAC |

#### PROD

| Table | Lignes | Contenu |
|---|---|---|
| `ad_platform_accounts` | 1 | 1 compte Meta actif (`1485150039295668`), last sync: 23 avr 2026 |
| `ad_spend` | 16 | Identique DEV — 16j Meta, GBP |
| `ad_spend_tenant` | 16 | Tenant=`keybuzz-consulting-mo9zndlk` |

#### Conversion destinations PROD

| Destination | Type | Tenant | Actif | Dernier test |
|---|---|---|---|---|
| KeyBuzz Consulting — Meta CAPI | `meta_capi` | `keybuzz-consulting-mo9zndlk` | Oui | success |
| KeyBuzz Consulting — TikTok | `tiktok_events` | `keybuzz-consulting-mo9zndlk` | Oui | success |

#### Échantillon données spend (PROD)

```
date: 2026-03-31, channel: meta, spend: £38.85, impressions: 6697, clicks: 45
date: 2026-03-30, channel: meta, spend: £39.28, impressions: 7821, clicks: 61
date: 2026-03-29, channel: meta, spend: £38.88, impressions: 4330, clicks: 86
```

### Données par plateforme

| Plateforme | Route/API existante | Données réellement présentes | Niveau de preuve |
|---|---|---|---|
| **Meta** | `POST /ad-accounts/:id/sync` + `GET /metrics/overview` | 16j spend réel (GBP), impressions, clicks. Compte actif. | **PRODUCTION** — données réelles Meta Graph API v21.0 |
| **Google** | Aucune route import spend | Aucune donnée spend | **ZÉRO** |
| **TikTok** | Aucune route import spend | Aucune donnée spend | **ZÉRO** |
| **LinkedIn** | Aucune route import spend | Aucune donnée spend | **ZÉRO** |

---

## Audit par plateforme

| Plateforme | Tracking | Conversions | Spend | KPI | Gap principal |
|---|---|---|---|---|---|
| **Meta** | **Actif** — Pixel + fbclid/fbc/fbp | **Actif** — CAPI native PROD (success) | **Actif** — 16j données réelles, GBP | **Actif** — CAC, ROAS, impressions, clicks | Campaign/adset = NULL (account-level only) |
| **Google** | **Actif** — GA4 MP + gclid + _gl via sGTM | **Actif** — GA4 via sGTM → Google Ads | **Absent** — pas d'adaptateur | **Absent** | Pas de `google-ads.ts` dans `ad-platforms/` |
| **TikTok** | **Actif** — Pixel + ttclid | **Actif** — Events API PROD (success) | **Absent** — pas d'adaptateur | **Absent** | Pas d'import spend TikTok |
| **LinkedIn** | **Actif** — Insight Tag + li_fat_id | **Absent** — CAPI non branchée | **Absent** | **Absent** | Pas de CAPI, pas de spend, le moins mûr |

---

## Vérité KPI exploitable

| Question | Réponse | Preuve |
|---|---|---|
| Que peut-on lire sans aller sur les plateformes ? | **Meta** : spend £38-39/j, impressions 4K-8K/j, clicks 45-86/j, CAC, ROAS, MRR | `ad_spend` = 16 lignes. `/metrics/overview` = calcul temps réel |
| Ce qui reste déclaratif ? | `Paid Channels` = 100% statique. Dit "0/4 spend" alors que Meta = 1/4 | Code source : tableau `PLATFORMS` hardcodé |
| Ce qui est mûr pour agences ? | **Meta Ads** : pipeline complet déployé en PROD | Routes API, token chiffré, sync fonctionnel |
| Premier canal après Meta ? | **Google Ads** : tracking complet, conversions OK, type prévu | sGTM actif, `google_ads` dans `DESTINATION_TYPES` |
| Plus petit chemin crédible ? | (1) Paid Channels dynamique, (2) Meta campaign breakdown, (3) Google Ads adapter | `meta-ads.ts` = 91 lignes — pattern clair à dupliquer |

---

## Ordre recommandé

| Ordre | Plateforme | Pourquoi maintenant | Effort | Impact |
|---|---|---|---|---|
| **1** | **Meta Ads** (enrichissement) | Pipeline DÉJÀ en PROD. Manque : campaign breakdown, auto-sync, Paid Channels dynamique. | ~1-2j | Cockpit passe de déclaratif à réel |
| **2** | **Google Ads** | Tracking + conversions complets. Pattern clair. 2e budget pub typique. | ~3-5j | Ajoute le 2e canal le plus important |
| **3** | **TikTok Ads** | Conversions natives OK. API Marketing bien documentée. | ~3-4j | 3e canal ads couvert |
| **4** | **LinkedIn Ads** | Le moins mûr. Pas de CAPI. OAuth complexe. Faible volume. | ~5-7j | Couverture complète 4/4 |

---

## Conclusion actionnable

### Cas A confirmé : Meta Ads spend/KPI est DÉJÀ opérationnel

La surprise de cet audit est que **Meta Ads est bien plus avancé que ce que Paid Channels laisse croire** :

- Un compte Meta actif avec token chiffré synchronise depuis le 20 avril 2026
- 16 jours de données spend réelles sont en base (DEV + PROD)
- Le calcul CAC/ROAS/impressions/clicks fonctionne dans `/metrics/overview`
- La conversion Meta CAPI est active en PROD avec dernier test = success

**Le cockpit Paid Channels ment par omission** en affichant "0/4 Spend connecté" alors que la réalité est "1/4".

### Prochain chantier : PH-T8.11B

1. **Rendre Paid Channels dynamique** (~50 lignes) — fetch `/metrics/overview` pour refléter la réalité Meta
2. **Enrichir Meta sync** (~30 lignes) — ajouter campaign_id/name, adset breakdown
3. **Auto-sync CronJob** (~20 lignes) — sync quotidien automatique Meta
4. **Mise à jour Ad Accounts** — permettre la sélection multi-plateforme (optionnel)

**Taille totale estimée : 2 jours**
**Impact : cockpit KPI passe de déclaratif (0%) à opérationnel (25% avec Meta)**

---

## Aucune modification effectuée

**Oui** — cet audit est 100% lecture seule. Aucun fichier modifié, aucun build, aucun deploy.

## PROD inchangée

**Oui** — aucune modification en DEV ou PROD.

---

## Rapport

**Chemin complet** : `keybuzz-infra/docs/PH-T8.11A-SPEND-KPI-MULTI-PLATFORM-TRUTH-AUDIT-01.md`

---

> **MULTI-PLATFORM SPEND/KPI TRUTH ESTABLISHED — META ADS ALREADY OPERATIONAL WITH REAL DATA — PAID CHANNELS UNDERSTATES REALITY — GOOGLE NEXT — PROD UNCHANGED**
