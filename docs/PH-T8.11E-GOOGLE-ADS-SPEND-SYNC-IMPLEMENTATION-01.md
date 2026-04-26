# PH-T8.11E-GOOGLE-ADS-SPEND-SYNC-IMPLEMENTATION-01 — TERMINÉ

**Verdict : NO GO — BLOCAGE PRÉREQUIS BUSINESS**

## KEY

**KEY-194** — Implémenter Google Ads spend sync (API + Admin)

---

## Préflight

| Point | Valeur |
|---|---|
| API branche | `ph147.4/source-of-truth` |
| API HEAD | `4941379a` |
| Admin branche | `main` |
| Admin HEAD | `3b0bc85` |
| Repos clean | Oui (API et Admin) |
| API image DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.120-linkedin-launch-readiness-dev` |
| Admin image DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.20-paid-channels-dynamic-dev` |
| API image PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.120-linkedin-launch-readiness-prod` |
| Admin image PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.18-paid-channels-dynamic-prod` |

---

## Prérequis business

### Credentials requis pour Google Ads spend sync

| Élément | Reçu ? | Suffisant ? | Note |
|---|---|---|---|
| Google Ads `customer_id` (MCC ou compte direct) | **NON** | — | Aucun customer_id configuré |
| Google Ads `developer_token` | **NON** | — | Aucune env var, aucun secret K8s |
| OAuth2 `client_id` (Google Cloud Console) | **NON** | — | Aucun secret Google OAuth |
| OAuth2 `client_secret` | **NON** | — | Idem |
| OAuth2 `refresh_token` | **NON** | — | Idem |

### Périmètre vérifié

| Périmètre | Résultat |
|---|---|
| Env vars pods DEV (`keybuzz-api-dev`) | 0 variable Google |
| Env vars pods PROD (`keybuzz-api-prod`) | 0 variable Google |
| Secrets K8s namespace `keybuzz-api-dev` | 0 secret Google Ads (22 secrets listés, aucun Google) |
| Code source `keybuzz-api` (grep `GOOGLE_ADS`, `googleAds`) | 0 résultat |
| Code source `keybuzz-admin-v2` | Références textuelles UI uniquement |
| Config `keybuzz-infra` | 0 credential Google Ads |
| Fichiers `.env` bastion | Aucun fichier `.env` présent |

### Verdict prérequis

**AUCUN des 5 éléments requis n'est disponible.**

Le prompt exige : *"Cette phase ne démarre que si les credentials Google Ads réels sont disponibles. Si les credentials ne sont pas fournis / pas exploitables : documenter le blocage, STOP, ne pas bricoler de faux connecteur."*

**→ STOP appliqué conformément aux règles.**

---

## Design technique

Non démarré — bloqué par prérequis business.

Le design technique identifié dans KEY-193 (audit PH-T8.11D) reste valide :

1. **Credentials** → 5 env vars à obtenir
2. **Module fetch** → `src/modules/metrics/ad-platforms/google-ads.ts` (~80 lignes, calqué sur `meta-ads.ts`)
3. **Route sync** → débloquer Google dans `src/modules/ad-accounts/routes.ts` (~15 lignes)
4. **Admin UI** → aucun changement requis (Paid Channels et Metrics sont déjà génériques)
5. **Taille estimée** → S-M (1 session CE si credentials disponibles)

---

## Patch API

Non démarré — bloqué par prérequis business.

---

## Patch Admin

Non démarré — bloqué par prérequis business.

---

## Build

Non démarré — bloqué par prérequis business.

---

## GitOps

Non démarré — bloqué par prérequis business.

---

## Déploiement

Non démarré — bloqué par prérequis business.

---

## Validation DEV

Non effectuée — bloqué par prérequis business.

---

## Preuves

Aucune preuve runtime — aucune implémentation effectuée.

---

## Gaps restants

Le gap complet identifié par KEY-193 reste intact :

| Gap | Description | Taille estimée |
|---|---|---|
| Credentials Google Ads | 5 éléments manquants (customer_id, developer_token, client_id, client_secret, refresh_token) | Action business manuelle |
| Module `google-ads.ts` | Fonction `fetchGoogleAdsInsights` absente | ~80 lignes |
| Route sync hardcodée `meta` | `if (platform !== 'meta')` → 400 dans `ad-accounts/routes.ts` | ~15 lignes |
| Dependency npm | Aucun package Google Ads installé (REST direct ou SDK) | 1 dépendance |
| Admin UI pour ajouter compte Google | Formulaire "Add Google Ads account" absent | ~100 lignes |

**Infrastructure déjà prête :**
- Schéma DB (`ad_platform_accounts`, `ad_spend_tenant`) → générique
- Metrics `by_channel` → `GROUP BY platform` → fonctionnerait immédiatement
- `enrichPlatforms()` dans Paid Channels → fonctionnerait immédiatement
- Clé de chiffrement ads (`keybuzz-ads-encryption`) → déjà présente en DEV

---

## Conclusion

### Verdict : **NO GO**

**Blocage réel : absence totale de credentials Google Ads.**

Aucune implémentation n'a été effectuée. Aucun code n'a été modifié. Aucune image n'a été construite. Aucun déploiement n'a eu lieu.

### Prochaine phase : résolution du blocage

Pour débloquer KEY-194, il faut obtenir les 5 credentials suivants :

1. **Google Ads `customer_id`** — identifiant du compte Google Ads (format `XXX-XXX-XXXX`) ou du MCC
2. **Google Ads `developer_token`** — obtenu via Google Ads API Center (nécessite un compte MCC approuvé)
3. **OAuth2 `client_id`** — créé dans Google Cloud Console (projet avec l'API Google Ads activée)
4. **OAuth2 `client_secret`** — associé au client_id ci-dessus
5. **OAuth2 `refresh_token`** — obtenu via le flow OAuth2 pour le compte Google Ads cible

### Guide pour obtenir les credentials

1. Aller sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créer ou sélectionner un projet
3. Activer l'API "Google Ads API"
4. Créer des identifiants OAuth 2.0 (type "Application de bureau")
5. Aller sur [Google Ads API Center](https://ads.google.com/aw/apicenter) dans le compte MCC
6. Demander un `developer_token` (mode test pour commencer)
7. Utiliser l'outil `generate_user_credentials` du SDK Google Ads pour obtenir le `refresh_token`
8. Fournir les 5 valeurs à injecter en DEV

### Une fois les credentials disponibles

Relancer `PH-T8.11E` — l'implémentation est estimée à 1 session CE (S-M).

---

## PROD inchangée

**Oui** — aucune modification PROD dans cette phase.

| Image PROD | Avant | Après |
|---|---|---|
| API | `v3.5.120-linkedin-launch-readiness-prod` | Inchangée |
| Admin | `v2.11.18-paid-channels-dynamic-prod` | Inchangée |

---

## Rapport

`keybuzz-infra/docs/PH-T8.11E-GOOGLE-ADS-SPEND-SYNC-IMPLEMENTATION-01.md`
