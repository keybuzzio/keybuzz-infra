# PH-T8.10D.1-OWNER-SCOPED-FUNNEL-AND-ACTIVATION-RUNTIME-TRUTH-VALIDATION-01 — TERMINÉ

**Verdict : GO FERME (Cas A)**

> OWNER-SCOPED FUNNEL AND ACTIVATION RUNTIME TRUTH ESTABLISHED IN DEV — CHILD FUNNEL REALLY AGGREGATES TO OWNER — LEGACY PRESERVED — PROD UNTOUCHED

---

## Préflight

| Point | Résultat |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API | `3162056a` (PH-T8.10D) |
| Image API DEV | `v3.5.115-owner-scoped-funnel-activation-aggregation-dev` |
| Image API PROD | `v3.5.111-activation-completed-model-prod` (inchangée) |
| Client DEV | `v3.5.112-marketing-owner-mapping-foundation-dev` |
| Client PROD | `v3.5.110-post-checkout-activation-foundation-prod` (inchangé) |
| Pod | `keybuzz-api-86f5dc985f-84qcq` Running, 0 restarts |
| Repo clean | Oui |

---

## Vérification runtime déployé

| Service | Image attendue | Image runtime observée | Statut |
|---|---|---|---|
| API DEV | `v3.5.115-owner-scoped-funnel-activation-aggregation-dev` | `v3.5.115-owner-scoped-funnel-activation-aggregation-dev` | **OK** |
| API PROD | `v3.5.111-activation-completed-model-prod` | `v3.5.111-activation-completed-model-prod` | **OK** |
| Client DEV | N/A (non modifié) | `v3.5.112-marketing-owner-mapping-foundation-dev` | **OK** |
| Client PROD | N/A (non modifié) | `v3.5.110-post-checkout-activation-foundation-prod` | **OK** |

---

## État des données avant test

### A. Owner / enfants

| Tenant | `marketing_owner_tenant_id` | Status | Plan |
|---|---|---|---|
| `keybuzz-consulting-mo9y479d` | NULL (owner) | active | AUTOPILOT |
| `proof-owner-valid-t8-mocqwjk7` | `keybuzz-consulting-mo9y479d` | pending_payment | PRO |
| `proof-no-owner-t810b-mocqwkvo` | NULL (legacy) | pending_payment | STARTER |

### B. Funnel data avant test

| Tenant | Events with tenant_id | Funnel_ids | Pre-tenant NULL events | Total events all funnels |
|---|---|---|---|---|
| `keybuzz-consulting-mo9y479d` | 2 | `["funnel-kbc-001"]` | 6 | 8 |
| `proof-owner-valid-t8-mocqwjk7` | **0** | `[]` | 0 | 0 |
| `proof-no-owner-t810b-mocqwkvo` | **0** | `[]` | 0 | 0 |

### C. Owner-scoped API avant test

| Vue | Mesure | Résultat |
|---|---|---|
| `/funnel/metrics?scope=owner` | cohort_size | 1 (seul funnel-kbc-001) |
| `/funnel/metrics?scope=owner` | non_zero_steps | 8 (tous du owner) |
| `/funnel/events?scope=owner` | count | 8 (tous de funnel-kbc-001) |

**Constat** : Le tenant enfant `proof-owner-valid-t8-mocqwjk7` a **0 funnel events** car il a été créé via API directement (pas via le flow `/register` qui émet les funnel events). L'agrégation owner-scoped ne montrait que le funnel du owner lui-même.

---

## Préparation du cas enfant réel

### Stratégie

Simuler le flow réel `/register` en émettant les funnel events via `POST /funnel/event`, puis en créant le tenant via `POST /tenant-context/create-signup` avec `marketing_owner_tenant_id`.

### Exécution

1. Génération d'un `funnel_id` unique : `funnel-child-proof-t810d1-1777045846`
2. Émission de 6 steps pré-tenant (tous 201 Created) :
   - `register_started` (tenant_id=NULL)
   - `plan_selected` (tenant_id=NULL, plan=pro)
   - `email_submitted` (tenant_id=NULL)
   - `otp_verified` (tenant_id=NULL)
   - `company_completed` (tenant_id=NULL)
   - `user_completed` (tenant_id=NULL)
3. Création du tenant enfant via `create-signup` :
   - Email : `proof-child-funnel-t810d1@test-keybuzz.io`
   - `marketing_owner_tenant_id` : `keybuzz-consulting-mo9y479d`
   - Résultat : tenant `proof-child-funnel-t-mod385lv` créé (201)
4. Émission de 2 steps post-tenant (tous 201 Created) :
   - `tenant_created` (tenant_id=`proof-child-funnel-t-mod385lv`)
   - `checkout_started` (tenant_id=`proof-child-funnel-t-mod385lv`)

| Point | Attendu | Résultat |
|---|---|---|
| Tenant enfant créé | Oui | `proof-child-funnel-t-mod385lv` — **OK** |
| Owner mapping | `keybuzz-consulting-mo9y479d` | **OK** |
| 6+ steps pré-tenant | Oui | 6 (tous 201) — **OK** |
| tenant_created émis | Oui | 201 — **OK** |
| checkout_started émis | Oui | 201 — **OK** |
| Total funnel events | 8 | 8 — **OK** |

---

## Preuves DB du funnel enfant

| Champ | Valeur |
|---|---|
| tenant_id | `proof-child-funnel-t-mod385lv` |
| marketing_owner_tenant_id | `keybuzz-consulting-mo9y479d` |
| funnel_id | `funnel-child-proof-t810d1-1777045846` |
| Total funnel_events | 8 |
| tenant_id IS NULL (pré-tenant) | 6 |
| tenant_id = enfant (post-tenant) | 2 |

### Détail des 8 events

| # | event_name | tenant_id | source | plan |
|---|---|---|---|---|
| 1 | register_started | NULL | client | - |
| 2 | plan_selected | NULL | client | pro |
| 3 | email_submitted | NULL | client | - |
| 4 | otp_verified | NULL | client | - |
| 5 | company_completed | NULL | client | - |
| 6 | user_completed | NULL | client | - |
| 7 | tenant_created | proof-child-funnel-t-mod385lv | api | pro |
| 8 | checkout_started | proof-child-funnel-t-mod385lv | client | pro |

---

## Preuve owner-scoped API

### A. `/funnel/metrics?tenant_id=keybuzz-consulting-mo9y479d&scope=owner`

| Point vérifié | Attendu | Résultat |
|---|---|---|
| HTTP status | 200 | 200 — **OK** |
| scope | `owner` | `owner` — **OK** |
| cohort_size (funnels) | 2 | 2 — **OK** |
| owner_cohort.total (tenants) | 3 | 3 — **OK** |
| owner_cohort.children | 2 enfants owner-mappés | `["proof-owner-valid-t8-mocqwjk7","proof-child-funnel-t-mod385lv"]` — **OK** |
| register_started count | 2 (owner + enfant) | 2 — **OK** |
| plan_selected count | 2 | 2 — **OK** |
| email_submitted count | 2 | 2 — **OK** |
| tenant_created count | 2 | 2 — **OK** |
| checkout_started count | 2 | 2 — **OK** |
| 16 steps canoniques | Oui | 16 — **OK** |

**Preuve clé** : chaque step avec count=2 prouve l'agrégation réelle de **deux funnels distincts** (owner + enfant).

### B. `/funnel/events?tenant_id=keybuzz-consulting-mo9y479d&scope=owner&limit=100`

| Point vérifié | Attendu | Résultat |
|---|---|---|
| HTTP status | 200 | 200 — **OK** |
| count | 16 (8 owner + 8 enfant) | 16 — **OK** |
| distinct funnel_ids | 2 | 2 — **OK** |
| `funnel-kbc-001` présent | Oui | `true` — **OK** |
| `funnel-child-proof-t810d1-1777045846` présent | Oui | `true` — **OK** |
| Steps pré-tenant enfant (NULL) | 6 | 6 events NULL pour funnel enfant — **OK** |
| Steps post-tenant enfant | 2 | 2 events avec tenant_id enfant — **OK** |

| Endpoint | Attendu | Résultat |
|---|---|---|
| /funnel/metrics owner-scoped | 2 funnels agrégés, counts doublés | **OK** |
| /funnel/events owner-scoped | 16 events, 2 funnel_ids distincts | **OK** |

---

## Cas négatif

### `/funnel/metrics?tenant_id=proof-no-owner-t810b-mocqwkvo&scope=owner`

| Endpoint | Attendu | Résultat |
|---|---|---|
| /funnel/metrics | cohorte=[self], 0 children, 0 steps | **OK** — owner_cohort.children=[], non_zero_steps=0 |
| /funnel/events | cohorte=[self], 0 events | **OK** — count=0, owner_cohort.children=[] |

Aucune fuite cross-tenant. Aucun funnel_id non relié inclus.

---

## Non-régression

| Sujet | Attendu | Résultat |
|---|---|---|
| /funnel/metrics legacy (enfant seul) | tenant-scoped, 8 steps non-zero | scope=NONE, cohort_size=1, 8 non_zero_steps — **OK** |
| /funnel/events legacy | Non modifié | **OK** |
| /metrics/overview owner-scoped | signups agrégés | scope=owner, signups=2, cohort.total=3 — **OK** |
| conversion_events | 1 | 1 — **OK** |
| billing_subscriptions | 16 | 16 — **OK** |
| funnel_events | 22 (14 avant + 8 nouveau) | 22 — **OK** |
| Owner mappings | 2 enfants (proof-owner-valid + proof-child-funnel) | **OK** |
| Client DEV | Non modifié | **OK** |
| Client PROD | Non modifié | **OK** |
| Admin DEV/PROD | Non modifiés | **OK** |
| API PROD | `v3.5.111-activation-completed-model-prod` | Inchangée — **OK** |

---

## Conclusion actionnable

### **Cas A — GO FERME**

Un funnel enfant owner-mappé non vide a été créé et prouvé :

1. **Tenant enfant** `proof-child-funnel-t-mod385lv` créé avec `marketing_owner_tenant_id = keybuzz-consulting-mo9y479d`
2. **Funnel réel** `funnel-child-proof-t810d1-1777045846` avec 8 events (6 pré-tenant NULL + 2 post-tenant)
3. **Agrégation owner-scoped** prouvée :
   - `/funnel/metrics?scope=owner` retourne **count=2** pour chaque step (2 funnels distincts)
   - `/funnel/events?scope=owner` retourne **16 events** avec **2 funnel_ids distincts**
   - Les steps pré-tenant (tenant_id=NULL) du funnel enfant sont bien inclus via le cohort stitching par funnel_id
4. **Cas négatif** validé : tenant legacy non relié ne fuit pas
5. **Non-régression** confirmée sur tous les endpoints

**Prochaine phase possible = Admin owner cockpit marketing.**

---

## Modifications effectuées

| Type | Détail |
|---|---|
| Code API | Aucune modification |
| Code Client | Aucune modification |
| Build | Aucun |
| Deploy | Aucun |
| DB | Données de validation DEV uniquement (1 user + 1 tenant + 8 funnel_events) |

---

## PROD inchangée

**Oui** — aucune action PROD. Images PROD inchangées.

---

*Rapport généré le 24 avril 2026*
*Phase : PH-T8.10D.1-OWNER-SCOPED-FUNNEL-AND-ACTIVATION-RUNTIME-TRUTH-VALIDATION-01*
*Chemin : `keybuzz-infra/docs/PH-T8.10D.1-OWNER-SCOPED-FUNNEL-AND-ACTIVATION-RUNTIME-TRUTH-VALIDATION-01.md`*
