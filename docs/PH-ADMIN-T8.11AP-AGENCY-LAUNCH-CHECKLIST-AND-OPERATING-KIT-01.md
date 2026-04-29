# PH-ADMIN-T8.11AP — Agency Launch Checklist & Operating Kit

**Date** : 29 avril 2026
**Auteur** : Agent Cursor
**Ticket** : KEY-221 (mise à jour manuelle requise)
**Verdict** : AGENCY LAUNCH OPERATING KIT LIVE

---

## Préflight

| Vérification | Résultat |
|---|---|
| Admin `main` clean | PASS — HEAD `97d1775` |
| Infra `main` | docs untracked uniquement |
| Admin DEV runtime | `v2.11.34-campaign-qa-event-lab-dev` |
| Admin PROD runtime | `v2.11.34-campaign-qa-event-lab-prod` |
| API/Client/Website | Inchangés |

## Rapports lus intégralement

- `PH-ADMIN-T8.11AN-CAMPAIGN-QA-URL-BUILDER-FOUNDATION-01.md`
- `PH-ADMIN-T8.11AN.1-CAMPAIGN-QA-SIDEBAR-ICON-HOTFIX-01.md`
- `PH-ADMIN-T8.11AO-CAMPAIGN-QA-EVENT-LAB-SAFE-MODE-01.md`
- `PH-WEBSITE-T8.11AK-PRICING-ATTRIBUTION-FORWARDING-CLOSURE-01.md`
- `PH-T8.11AL-GOOGLE-ADS-SIGNUP-COMPLETE-ACTIVATION-01.md`
- `PH-T8.11AM-GOOGLE-ADS-SIGNUP-COMPLETE-POST-PROPAGATION-VERIFY-01.md`
- `PH-T8.11Z-ANALYTICS-BASELINE-CLEAN-READINESS-01.md`

Contexte intégré dans le contenu de l'onglet Launch Checklist.

## Design UI

Troisième onglet ajouté dans `/marketing/campaign-qa` :

| Onglet | Contenu |
|---|---|
| URL Builder | Générateur d'URL (existant) |
| Event Lab | Validateur d'URL safe mode (existant) |
| **Launch Checklist** | Kit opérationnel agence (nouveau) |

## Contenu ajouté — Launch Checklist

### 1. Avant de lancer (10 items)
Checklist numérotée avec distinction visuelle :
- Items critiques (fond rouge + icône Ban) : `marketing_owner_tenant_id`, `utm_source`, préfixe acteur, pas d'URL raccourcie, pas de click IDs manuels, pas de tag AW-
- Items standard (fond gris) : générer URL, vérifier Event Lab, landing `/pricing`, validation si doute

### 2. Après lancement — Dans les 24h (6 items)
Checklist numérotée (fond ambre) :
- Vérifier impressions/clics/spend
- GA4 Realtime pour Google/YouTube
- Delivery Logs pour CAPI
- Admin Metrics
- Exclusion campagnes test
- Reporting à Ludovic

### 3. Où vérifier quoi — Par plateforme (tableau)
| Plateforme | Cockpit | Conversions server-side | Spend/KPI Admin | Statut |
|---|---|---|---|---|
| Meta | Meta Ads Manager | Events Manager + Delivery Logs | Oui | Complet |
| Google/YouTube | Google Ads | GA4 + Google Ads Conversions | Oui | signup_complete recheck |
| TikTok | TikTok Ads Manager | Events API + Delivery Logs | Bloqué | CAPI OK, spend bloqué |
| LinkedIn | Campaign Manager | CAPI + Delivery Logs | Hors scope | CAPI OK, spend hors scope |

### 4. Peut-on lancer aujourd'hui ? (4 cartes)
- **Meta** : Oui (vert)
- **Google/YouTube** : Oui, recheck propagation non bloquant (vert)
- **TikTok** : Oui si diffusion possible, spend bloqué (ambre)
- **LinkedIn** : Oui dès validation, spend hors scope (ambre)

### 5. Message de briefing agence
Texte complet copiable avec bouton "Copier le message" :
- Instructions URL Builder + Event Lab
- `/pricing` + `marketing_owner_tenant_id`
- Interdiction click IDs manuels
- Reporting post-lancement
- Baseline 29/04/2026 00:00 Europe/Paris

### 6. Baseline analytics
Note informative : 29 avril 2026, 00:00 Europe/Paris.

## Fichiers modifiés

| Fichier | Modification |
|---|---|
| `keybuzz-admin-v2/src/app/(admin)/marketing/campaign-qa/page.tsx` | +215 lignes — onglet Launch Checklist |

## Build tags + digests

| Env | Tag | Digest |
|---|---|---|
| DEV | `v2.11.35-agency-launch-kit-dev` | `sha256:5973085014e723af521f658e11f91b5780d8ed9b649c4dbefd438417321bc3d0` |
| PROD | `v2.11.35-agency-launch-kit-prod` | `sha256:1a0874698c7ba9bb27edd8f517029bcfe658b803dc5a5ee7f0318ef9d2fa5cc9` |

Source commit HEAD : `fbed0d1` (keybuzz-admin-v2)

## GitOps commits

| Repo | Commit | Description |
|---|---|---|
| keybuzz-admin-v2 | `fbed0d1` | feat(marketing): Agency Launch Checklist tab in Campaign QA (KEY-221) |
| keybuzz-infra | `91e2000` | GitOps Admin DEV v2.11.35-agency-launch-kit-dev (KEY-221) |
| keybuzz-infra | `ddd498e` | GitOps Admin PROD v2.11.35-agency-launch-kit-prod (KEY-221) |

## Validation navigateur DEV

- URL : `https://admin-dev.keybuzz.io/marketing/campaign-qa`
- Sidebar Campaign QA avec icône Link2 : OK
- 3 onglets visibles (URL Builder, Event Lab, Launch Checklist) : OK
- Onglet Launch Checklist :
  - "Avant de lancer" (10 items numérotés, critiques en rouge) : OK
  - "Après lancement — Dans les 24h" (6 items ambre) : OK
  - Tableau "Où vérifier quoi" (4 lignes, badges colorés) : OK
  - "Peut-on lancer aujourd'hui ?" (4 cartes vert/ambre) : OK
  - "Message de briefing agence" + bouton "Copier le message" : OK
  - "Baseline analytics" : OK
- Aucun secret, AW-, ou mot interdit visible : OK
- Pas d'erreur console bloquante : OK

## Validation navigateur PROD

- URL : `https://admin.keybuzz.io/marketing/campaign-qa`
- Login avec credentials PROD : OK
- 3 onglets visibles : OK
- Contenu Launch Checklist identique au DEV : OK
- Bouton "Copier le message" : OK
- Tableau plateformes complet : OK
- Aucun secret, AW-, ou mot interdit : OK
- Aucune régression : OK

## Non-régression

| Service | Image | Status |
|---|---|---|
| Admin PROD | `v2.11.35-agency-launch-kit-prod` | 1/1 Running, 0 restarts |
| API PROD | `v3.5.123-linkedin-capi-native-prod` | Inchangé |
| Client PROD | `v3.5.125-register-console-cleanup-prod` | Inchangé |
| Website PROD | `v0.6.7-pricing-attribution-forwarding-prod` | Inchangé |

## Linear

- KEY-221 : mise à jour manuelle requise (pas de token API)
  - Ajouter : "Agency Launch Checklist tab livré dans Campaign QA"
  - Status : Done si PROD validée
- KEY-217 : inchangé (Done)
- Pas de modification des tickets TikTok/LinkedIn

## Rollback GitOps

```bash
# DEV
# Dans keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml :
# image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.34-campaign-qa-event-lab-dev
# git commit, push, kubectl apply

# PROD
# Dans keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml :
# image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.34-campaign-qa-event-lab-prod
# git commit, push, kubectl apply
```

## Confirmations de sécurité

- Aucun secret dans le code, les logs, le bundle ou le rapport
- Aucun tag Google Ads direct (AW-18098643667)
- Aucun faux événement ou faux spend
- Aucun appel CAPI ajouté
- Aucune destination Google native créée
- Aucune conversion business envoyée
- Pas de mot interdit dans le bundle
- Pure client-side — aucun appel API backend
