# PH-T8.9M-PROD-FUNNEL-DATA-TRUTH-AUDIT-01 — TERMINÉ

**Date** : 2026-05-01
**Type** : Audit vérité lecture seule — données Funnel PROD vs DEV
**Environnement** : PROD (lecture seule) + DEV (comparaison)
**Verdict** : **NORMAL**

---

## Objectif

Établir noir sur blanc pourquoi `/marketing/funnel` affiche des données en DEV mais un état vide en PROD pour le tenant `KeyBuzz Consulting`, malgré une plage de dates large.

Trancher entre 5 hypothèses :
1. Aucune donnée funnel réelle n'existe en PROD
2. Des données existent mais ne sont pas reliées correctement
3. Des données existent mais sont filtrées incorrectement
4. L'API PROD renvoie bien des données mais l'Admin lit mal
5. La différence DEV/PROD vient du fait que DEV contient des datasets de validation et PROD non

**Résultat** : **Hypothèse 5 confirmée. PROD est légitimement vide.**

---

## Préflight

| Élément | Valeur |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API | `c0b0f195` (PH-T8.9J: activation_completed derived event) |
| Repo status | Clean (aucune modification) |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.111-activation-completed-model-prod` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.110-post-checkout-activation-foundation-prod` |
| Admin PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.11-funnel-metrics-tenant-proxy-fix-prod` |
| Modifications effectuées | **Aucune** |

Toutes les images correspondent aux versions attendues post-PH-T8.9L.

---

## Tenant PROD — KeyBuzz Consulting

| Champ | Valeur |
|---|---|
| `tenant_id` | `keybuzz-consulting-mo9zndlk` |
| Nom exact | KeyBuzz Consulting |
| Status | `active` |
| Date de création | **2026-04-22T11:47:39Z** |
| signup_attribution | **Aucune entrée** |
| DEV equivalent | `keybuzz-consulting-mo9y479d` |

### Point critique

KeyBuzz Consulting a été créé le **22 avril 2026** — soit **2 jours AVANT** le déploiement du funnel en PROD (24 avril, PH-T8.9D). Le tenant n'a donc jamais traversé le flow `/register` instrumenté.

### Tous les tenants PROD (15 total)

| Tenant ID | Nom | Créé le | Status |
|---|---|---|---|
| ecomlg-001 | eComLG | 2026-02-06 | active |
| ecomlg-mn3rdmf6 | eComLG | 2026-03-23 | active |
| ecomlg-mn3roi1v | eComLG | 2026-03-23 | pending_payment |
| romruais-gmail-com-mn7mc6xl | romruais@gmail.com | 2026-03-26 | active |
| switaa-sasu-mn9c3eza | SWITAA SASU | 2026-03-27 | active |
| switaa-sasu-mnc1ouqu | SWITAA SASU | 2026-03-29 | active |
| compta-ecomlg-gmail--mnvu4649 | compta.ecomlg@gmail.com | 2026-04-12 | active |
| test-mnyycio7 | test | 2026-04-14 | pending_payment |
| ecomlg-mo45atga | eComLG | 2026-04-18 | active |
| ecomlg-mo4h93e7 | eComLG | 2026-04-18 | active |
| tiktok-prod-test-sas-mo5jsh7z | TikTok PROD Test SAS | 2026-04-19 | pending_payment |
| tiktok-prod-v2-sas-mo5k10ku | TikTok PROD V2 SAS | 2026-04-19 | active |
| ludo-gonthier-ga4mpf-mo5ldw59 | ludo.gonthier+GA4MPFinal | 2026-04-19 | active |
| ecomlg07-mo957dzr | ecomlg07 | 2026-04-21 | active |
| **keybuzz-consulting-mo9zndlk** | **KeyBuzz Consulting** | **2026-04-22** | **active** |

**Fait critique** : le **dernier tenant créé en PROD** est KeyBuzz Consulting le 22 avril. Le funnel a été déployé le 24 avril. **Aucun tenant n'a été créé après le déploiement du funnel.** La table est donc légitimement vide.

---

## Vérité DB — PROD `funnel_events`

### A. Global PROD

| Mesure | Résultat |
|---|---|
| Total rows | **0** |
| Min created_at | N/A |
| Max created_at | N/A |
| Répartition event_name | N/A |
| Répartition par jour | N/A |

**La table `funnel_events` est VIDE en PROD pour TOUS les tenants.**

### B. Tenant-scoped (KeyBuzz Consulting)

| Mesure | Résultat |
|---|---|
| Rows avec tenant_id = keybuzz-consulting-mo9zndlk | 0 |
| Rows via cohort stitching | 0 |
| Counts par event_name | N/A |
| funnel_id distincts | 0 |

### C. NULL tenant rows

| Mesure | Résultat |
|---|---|
| Rows tenant_id IS NULL | 0 |
| Rattachables à KeyBuzz Consulting | 0 |
| Orphelins | 0 |

### Preuve

Il y a réellement **0 row utile** dans `funnel_events` pour ce tenant ET pour TOUS les tenants en PROD. Ce n'est pas un problème de couture ou de filtrage — la table est totalement vide.

### Tables complémentaires

| Table | Rows | Commentaire |
|---|---|---|
| `signup_attribution` | 3 | Toutes créées AVANT le déploiement funnel (19-21 avril) |
| `conversion_events` | 0 | Cohérent — pas de conversions tracking non plus |
| `funnel_events` | 0 | Objet de cet audit |

### signup_attribution PROD (3 entrées)

| Tenant | Créé le | Attribution ID | Commentaire |
|---|---|---|---|
| tiktok-prod-v2-sas-mo5k10ku | 2026-04-19 | 43523a6e... | Test TikTok |
| ludo-gonthier-ga4mpf-mo5ldw59 | 2026-04-19 | c13c277e... | Test GA4 MP |
| ecomlg07-mo957dzr | 2026-04-21 | 286984d3... | Test réel |

Aucune de ces attributions ne correspond à KeyBuzz Consulting. Les 3 ont été créées AVANT le déploiement du funnel (24 avril).

---

## Vérité API PROD

### Endpoints testés

| Endpoint | Paramètres | Attendu | Résultat |
|---|---|---|---|
| `GET /funnel/metrics` | `from=2026-01-01&to=2026-05-02` | 16 steps, counts=0 si table vide | ✅ 16 steps, total=0 |
| `GET /funnel/events` | `from=2026-01-01&to=2026-05-02&limit=100` | count=0 | ✅ count=0 |
| `GET /funnel/metrics` | `tenant_id=keybuzz-consulting-mo9zndlk&from=2026-01-01&to=2026-05-02` | 16 steps, counts=0, cohort=0 | ✅ 16 steps, counts=0, cohort=0 |
| `GET /funnel/events` | `tenant_id=keybuzz-consulting-mo9zndlk` | count=0 | ✅ count=0 |
| `GET /funnel/metrics` | tous les 15 tenants PROD | 0 non-zero pour chacun | ✅ confirmé |

L'API fonctionne correctement. Elle renvoie 16 steps (la structure complète du funnel) mais avec tous les counts à 0 — ce qui est le reflet exact de la table vide.

### Cohort stitching vérifié

Pour chaque tenant, le cohort_size est 0 car aucun funnel_id n'existe dans la table. Le mécanisme de stitching n'a rien à coudre.

---

## Filtre `to` — Vérification

| Test | Résultat |
|---|---|
| `to=2026-05-01` | total=0 |
| `to=2026-05-02` | total=0 |
| `to=2026-05-01T23:59:59Z` | total=0 |
| sans dates | total=0 |
| `from=2026-04-24&to=2026-04-25` | total=0 |
| `from=2026-04-24&to=2026-04-30` | total=0 |

**Conclusion** : le bug `to` exclusif n'est PAS la cause du vide observé. Toutes les variantes de dates retournent 0. La cause est l'absence totale de données, pas un filtrage incorrect.

---

## Admin PROD — Vérification consommateur

| Couche | Résultat |
|---|---|
| Admin PROD pod | Running (1/1, keybuzz-admin-v2-86ddd6c85f-t7m9h) |
| Admin env `KEYBUZZ_API_INTERNAL_URL` | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local` ✅ |
| Admin env `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` ✅ |
| API backend PROD `/health` | 200 OK ✅ |
| API backend PROD `/funnel/metrics` | 200, 16 steps, total=0 ✅ |
| API backend PROD `/funnel/metrics?tenant_id=...` | 200, 16 steps, cohort=0 ✅ |
| Proxy Admin PROD | Forwards correctement vers l'API interne ✅ |
| UI navigateur PROD | Affiche "vide" ✅ — reflet exact de l'API |

**Conclusion** : L'Admin PROD lit correctement ce que l'API renvoie. L'API renvoie correctement le reflet de la DB. La DB est vide. La chaîne est intègre.

---

## Comparaison DEV vs PROD

### DEV

| Mesure | Valeur |
|---|---|
| Total rows | **14** |
| Min created_at | 2026-04-23T21:00:48Z |
| Max created_at | 2026-04-24T07:05:58Z |
| Events | register_started(2), plan_selected(2), email_submitted(2), otp_verified(1), company_completed(1), user_completed(1), tenant_created(2), checkout_started(1), dashboard_first_viewed(1), onboarding_started(1) |
| Tenants avec events | NULL(9), switaa-sasu-mnc1x4eq(2), keybuzz-consulting-mo9y479d(2), keybuzz-mnqnjna8(1) |

### PROD

| Mesure | Valeur |
|---|---|
| Total rows | **0** |
| Events | Aucun |
| Tenants avec events | Aucun |

### Analyse

Les 14 rows DEV ont été créées le **23-24 avril 2026**, exactement pendant les sessions de validation CE :
- **PH-T8.9B** (23 avril) : validation pre-tenant funnel foundation
- **PH-T8.9G** (24 avril) : validation post-checkout activation events

Ce sont des **données de test/validation** créées manuellement pendant les phases CE, pas des parcours utilisateur réels.

En PROD :
- Le funnel a été déployé le **24 avril** (PH-T8.9D)
- Le dernier tenant créé est **KeyBuzz Consulting** le **22 avril** — 2 jours AVANT le déploiement
- **Aucun nouveau tenant n'a été créé depuis le 22 avril**
- Donc aucun parcours `/register` n'a été exécuté après le déploiement du funnel

### Chronologie décisive

```
22 avr : KeyBuzz Consulting créé en PROD (AVANT funnel)
23 avr : Validation CE en DEV → 14 events de test créés
24 avr : Funnel déployé en PROD (PH-T8.9D)
24 avr → 01 mai : AUCUNE inscription PROD via /register
```

---

## Conclusion

### Verdict : **NORMAL** — Cas A

L'absence de données funnel en PROD est **totalement attendue et normale**.

**Preuves** :

1. **La table `funnel_events` PROD contient 0 rows pour TOUS les tenants** — pas seulement pour KeyBuzz Consulting
2. **Aucun tenant PROD n'a été créé après le déploiement du funnel** le 24 avril 2026
3. **KeyBuzz Consulting** a été créé le 22 avril, soit 2 jours AVANT le déploiement — il n'a jamais traversé le flow instrumenté
4. **Les 14 rows DEV** sont des données de validation créées pendant les sessions CE du 23-24 avril
5. **L'API et l'Admin fonctionnent correctement** — la chaîne API backend → proxy Admin → UI est intègre
6. **Le filtre date** n'est pas en cause — toutes les variantes retournent 0 car la table est vide
7. **La structure API** (16 steps) est correcte et prête à recevoir des données

### Ce qui est prêt

- Table `funnel_events` : schéma correct, indexes en place, unique constraint OK
- API `POST /funnel/event` : opérationnelle, allowlist de 16 events
- API `GET /funnel/metrics` : opérationnelle avec cohort stitching
- API `GET /funnel/events` : opérationnelle
- Client `/register` instrumenté avec `emitFunnelStep` pour 7 events pre-tenant
- Client `/register/success`, `/dashboard`, `/start` instrumentés avec `emitActivationStep`
- API `emitActivationEvent` dans inbound/messages pour marketplace_connected, first_conversation_received, first_response_sent
- API `tryEmitActivationCompleted` pour l'événement dérivé activation_completed

### Action suivante recommandée

**Aucun fix immédiat n'est nécessaire.**

Pour valider le pipeline PROD de bout en bout, deux options :

1. **Attendre un vrai parcours PROD** : lorsque les publicités lanceront du trafic vers `/register`, les events funnel seront automatiquement capturés
2. **Validation contrôlée propre** (optionnelle) : créer un parcours de test réel via `/register` en PROD avec un compte de test identifiable, puis vérifier que les 16 steps se peuplent correctement. Ce serait une phase future dédiée (ex: `PH-T8.9N-PROD-FUNNEL-PIPELINE-E2E-VALIDATION-01`)

---

## Aucune modification effectuée

- Aucun patch
- Aucun build
- Aucun deploy
- Aucune migration
- Aucune insertion de données
- Aucun nettoyage
- Aucun test destructif
- Mode lecture seule stricte respecté

---

## Rapport : `keybuzz-infra/docs/PH-T8.9M-PROD-FUNNEL-DATA-TRUTH-AUDIT-01.md`
