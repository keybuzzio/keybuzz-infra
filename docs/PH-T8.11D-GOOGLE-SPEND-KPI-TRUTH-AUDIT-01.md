# PH-T8.11D-GOOGLE-SPEND-KPI-TRUTH-AUDIT-01 — TERMINÉ

**Verdict : GO**

---

## KEY

**KEY-193** — brancher Google spend/KPI dans le cockpit Admin sans faux signaux

---

## Préflight

| Repo | Branche | HEAD | Clean |
|---|---|---|---|
| `keybuzz-admin-v2` | `main` | `3b0bc85` — PH-ADMIN-T8.11B | oui |
| `keybuzz-api` | `ph147.4/source-of-truth` | `4941379a` — PH-T8.10W | oui |

---

## Audit Admin

| Surface Admin | Ce que ça dit sur Google | Ce que ça prouve réellement |
|---|---|---|
| `/marketing/paid-channels` | Spend = `none`, "Aucune API Google Ads connectée" | Vérité : aucun spend Google branché |
| `/marketing/ad-accounts` | Formulaire hardcodé `meta` uniquement | Google n'est pas un choix possible |
| `/marketing/google-tracking` | "Google Ads spend sync" = ✗, "Bientôt" | Spend explicitement déclaré comme absent |
| `/marketing/metrics` | 404 (page inexistante dans le bundle) | Rien ne peut être affiché |
| Rapport T8.11A | Google spend = "ZÉRO" | Confirmé par audit précédent |

---

## Audit API / Data

| Sujet | Existe ? | Où ? | Niveau de preuve |
|---|---|---|---|
| Routes Google Ads spend/import | Non | — | Aucune route spécifique |
| Module `fetchGoogleAdsInsights` | Non | seul `meta-ads.ts` | Dossier `ad-platforms/` ne contient que `meta-ads.ts` |
| `ad_platform_accounts` schéma | Oui — générique | `platform` = TEXT libre | Compatible Google sans migration |
| Données Google dans `ad_platform_accounts` | Non | 0 rows | Aucun compte enregistré |
| Données Google dans `ad_spend_tenant` | Non | 0 rows | Aucune donnée spend |
| Metrics `by_channel` query | Oui — générique | `GROUP BY platform` | Fonctionnerait si données présentes |
| Google Ads API env vars | Non | 0 env vars | Pas de credentials configurés |
| Route sync supportant Google | Non | Hardcodé `meta` only | `if (platform !== 'meta')` → 400 |
| npm Google Ads dependency | Non | — | Aucune dépendance installée |
| `signup_attribution` gclid | Oui | 3 gclid PROD | Tracking fonctionne, pas spend |

---

## Vérité Google par couche

### A. Tracking — ACTIF

| Signal | État | Preuve |
|---|---|---|
| gclid capture | Actif | 3 gclid dans `signup_attribution` PROD |
| UTM google | Actif | 3 rows `utm_source ILIKE 'google%'` |
| Attribution owner-aware | Actif | `marketing_owner_tenant_id` présent |

### B. Conversions — ACTIF (via Addingwell/sGTM)

| Signal | État | Preuve |
|---|---|---|
| GA4 MP pipeline | Actif | `emitConversionWebhook` → `https://t.keybuzz.io/mp/collect` |
| Payload owner-aware | Actif | `routing_tenant_id`, `marketing_owner_tenant_id` dans payload |
| `conversion_sent_at` | Actif | Mis à jour après envoi GA4 MP réussi |
| Google Ads conversion | Actif (opaque) | Addingwell forward vers Google Ads |

### C. Spend/KPI — TOTALEMENT ABSENT

| Signal | État | Preuve |
|---|---|---|
| Compte Google Ads | ABSENT | 0 rows dans `ad_platform_accounts` |
| Google Ads API token | ABSENT | 0 env vars |
| Module fetch | ABSENT | Seul `meta-ads.ts` existe |
| Route sync | ABSENT | Hardcodé meta-only |
| Données spend | ABSENT | 0 rows dans `ad_spend_tenant` |
| CAC/ROAS Google | ABSENT | Impossible sans spend |
| Admin Ad Accounts Google | ABSENT | Formulaire hardcodé `meta` |

---

## Gap principal

| Gap | Impact | Taille estimée | Bloquant ? |
|---|---|---|---|
| Aucun compte Google Ads branché | Pas de source spend | Manuel — 1-2h | **OUI** |
| Pas de credentials Google Ads API | Impossible de fetcher | Manuel — config | **OUI** |
| Module `google-ads.ts` absent | Pas de fetch function | ~80 lignes | **OUI** |
| Route sync hardcodée `meta` | Google rejeté par le backend | ~15 lignes | **OUI** |
| Aucune dépendance npm Google Ads | Pas de client API | Petit | **OUI** |
| Admin formulaire hardcodé `meta` | Impossible de créer un compte Google | ~20 lignes | Non bloquant |
| Schéma DB | DÉJÀ GÉNÉRIQUE | `platform` = TEXT | Non bloquant |
| Metrics by_channel | DÉJÀ GÉNÉRIQUE | `GROUP BY platform` | Non bloquant |

**Le gap principal est une chaîne de 4 maillons manquants : credentials → module fetch → route sync → Admin UI.**

**Bonne nouvelle : l'infrastructure est déjà générique.** Le schéma DB, les métriques `by_channel`, et `enrichPlatforms()` dans Paid Channels fonctionneraient immédiatement si des données Google existaient dans `ad_spend_tenant`.

---

## Plan minimal

| Étape | Action | Taille | Pourquoi |
|---|---|---|---|
| 1. Credentials | Obtenir `customer_id` + `developer_token` + OAuth refresh token Google Ads | Manuel 1-2h | Prérequis business absolu |
| 2. Module fetch | Créer `src/modules/metrics/ad-platforms/google-ads.ts` — fetch REST API Google Ads v18 (`searchStream` + GAQL) | ~80 lignes | Calqué sur `meta-ads.ts` |
| 3. Route sync | Débloquer Google dans la route sync (switch platform → fetch function) | ~15 lignes | Le reste (upsert, update) est déjà générique |
| 4. Admin UI | Ajouter Google au sélecteur plateforme dans Ad Accounts | ~20 lignes | Permet de créer un compte Google depuis l'Admin |
| 5. Vérification | Créer un compte Google, lancer sync, vérifier Paid Channels + Metrics | Test e2e | 3 surfaces déjà prêtes (enrichPlatforms, by_channel, schema) |

**Aucune migration DB nécessaire.** Le schéma est déjà générique.

**Aucun changement Addingwell/sGTM.** Le spend est indépendant des conversions.

**Aucune modification Client.** Admin-only.

---

## Conclusion

**Cas B — Google spend n'existe pas encore, mais un petit chemin réaliste existe.**

### Constat
- Google **tracking** et **conversions** sont déjà actifs (gclid, GA4 MP, sGTM, owner-aware)
- Google **spend/KPI** est totalement absent : aucun compte, aucun module, aucune donnée, aucune API credentials
- L'infrastructure DB et metrics est **déjà générique** — prête à recevoir des données Google

### Prochain ticket

**KEY-194 — Implémenter Google Ads spend sync (API + Admin)**

- **Prérequis** : obtenir credentials Google Ads réels (étape business)
- **Taille** : S-M (1 session CE si credentials disponibles)
- **Impact** : Google passe de "0 spend" à un vrai canal spend/KPI
- **Commencer par** : API d'abord (module fetch + route sync), puis Admin UI
- **Pas de migration DB** nécessaire
- **Pas de changement Addingwell** nécessaire

---

## Aucune modification effectuée

**oui** — cet audit est 100% lecture seule.

## PROD inchangée

**oui** — aucun build, aucun deploy, aucun patch.

---

## Chemin du rapport

```
keybuzz-infra/docs/PH-T8.11D-GOOGLE-SPEND-KPI-TRUTH-AUDIT-01.md
```
