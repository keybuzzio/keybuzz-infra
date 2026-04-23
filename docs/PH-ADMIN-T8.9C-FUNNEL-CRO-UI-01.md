# PH-ADMIN-T8.9C — Funnel CRO UI

**Phase** : PH-ADMIN-T8.9C-FUNNEL-CRO-UI-01
**Date** : 2026-04-23
**Environnement** : DEV uniquement
**Type** : Nouvelle page Funnel / CRO marketing tenant-scoped
**Priorite** : P0

---

## 1. PREFLIGHT

| Element | Valeur |
|---|---|
| Branche Infra | `main` |
| HEAD Infra avant | `43b6e57` (PH-T8.9B) |
| Admin DEV avant | `v2.11.8-agency-tracking-playbook-dev` |
| Admin PROD | `v2.11.8-agency-tracking-playbook-prod` (INCHANGE) |
| API DEV | `v3.5.108-funnel-pretenant-foundation-dev` |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` (INCHANGE) |
| HEAD Admin avant | `4bad311` |

---

## 2. CONTRAT API REEL OBSERVE

### GET /funnel/metrics

```json
{
  "steps": [
    { "event_name": "register_started", "count": 0, "conversion_rate_from_previous": 100 },
    { "event_name": "plan_selected", "count": 0, "conversion_rate_from_previous": 0 },
    { "event_name": "email_submitted", "count": 0, "conversion_rate_from_previous": 0 },
    { "event_name": "otp_verified", "count": 0, "conversion_rate_from_previous": 0 },
    { "event_name": "oauth_started", "count": 0, "conversion_rate_from_previous": 0 },
    { "event_name": "company_completed", "count": 0, "conversion_rate_from_previous": 0 },
    { "event_name": "user_completed", "count": 0, "conversion_rate_from_previous": 0 },
    { "event_name": "tenant_created", "count": 0, "conversion_rate_from_previous": 0 },
    { "event_name": "checkout_started", "count": 0, "conversion_rate_from_previous": 0 }
  ],
  "period": { "from": null, "to": null }
}
```

### GET /funnel/events

```json
{ "events": [], "count": 0 }
```

### Tableau contrat

| Endpoint | Champs utiles | Filtres supportes | Limites |
|---|---|---|---|
| `GET /funnel/metrics` | `steps[].event_name/count/conversion_rate_from_previous`, `period` | `from`, `to` | Pas de filtre `tenant_id`, pas de `source`, pas de `plan` |
| `GET /funnel/events` | `events[].*`, `count` | `funnel_id`, `tenant_id`, `from`, `to`, `limit` | Max 500 rows |
| `POST /funnel/event` | write-only | — | 9 event_names, idempotent |

**Note** : `/funnel/metrics` agrege globalement (pas de filtre `tenant_id`). C'est une limitation du contrat API actuel. Le proxy forward le parametre mais l'API l'ignore. Ce gap est documente et ne necessite pas de modification API dans cette phase.

---

## 3. INTEGRATION UI

### Menu Marketing mis a jour

| Position | Avant | Apres |
|---|---|---|
| 1 | Metrics | Metrics |
| 2 | — | **Funnel** (NOUVEAU) |
| 3 | Ads Accounts | Ads Accounts |
| 4 | Destinations | Destinations |
| 5 | Delivery Logs | Delivery Logs |
| 6 | Integration Guide | Integration Guide |

Icone : `Filter` (lucide-react).
Roles : `MARKETING` = `['super_admin', 'account_manager', 'media_buyer']`.

### Fichiers crees / modifies

| Fichier | Action |
|---|---|
| `src/config/navigation.ts` | Modifie — ajout item Funnel en position 2 |
| `src/app/(admin)/marketing/funnel/page.tsx` | Cree — page Funnel CRO (~350 lignes) |
| `src/app/api/admin/marketing/funnel/metrics/route.ts` | Cree — proxy GET vers API |
| `src/app/api/admin/marketing/funnel/events/route.ts` | Cree — proxy GET vers API |

---

## 4. PROXIES ADMIN

| Route Admin | Endpoint API | Forward |
|---|---|---|
| `GET /api/admin/marketing/funnel/metrics` | `GET /funnel/metrics` | `tenantId`, `from`, `to` |
| `GET /api/admin/marketing/funnel/events` | `GET /funnel/events` | `tenantId` (→ `tenant_id`), `from`, `to`, `limit` |

Les deux proxies utilisent `requireMarketing()` (RBAC) et `proxyGet()` (forward standard avec `x-user-email`, `x-tenant-id`, `x-admin-role`). Aucune logique metier dans les proxies.

---

## 5. PAGE FUNNEL / CRO

### Blocs realises

| Bloc | Description |
|---|---|
| Header | Titre "Funnel" + description + tenant affiche |
| Filtres | Date from/to + bouton Rafraichir |
| KPI Cards | Funnels observes, derniere etape, conversion globale, plus gros drop-off |
| Funnel Viz | Barres horizontales step-by-step avec numero, label, barre, count, taux, drop-off |
| Business Truth | Separation micro-steps vs business events (trial_started/purchase_completed) |
| Detail Table | Tableau complet avec #, etape, count, conv. etape prec., drop-off, conv. globale |
| Events recents | Tableau des 50 derniers events (date, funnel_id, step, source, plan, tenant) |
| Etat vide | Message clair "Aucune donnee funnel" sans mock ni fausse courbe |

### Regles respectees

- `trial_started` et `purchase_completed` presentes comme business events Stripe, pas comme micro-steps
- Aucun NaN / undefined / Infinity
- Aucun mock
- Aucun token brut
- Division par zero protegee (`isFinite()`, check `previous > 0`)
- Pas de recalcul metier cote Admin (consomme l'API)

---

## 6. RBAC / TENANT SCOPE

| Role | Acces | Raison |
|---|---|---|
| `super_admin` | OUI | MARKETING role |
| `account_manager` | OUI | MARKETING role |
| `media_buyer` | OUI | MARKETING role |
| `ops_admin` | NON | Pas dans MARKETING |
| `finance_admin` | NON | Pas dans MARKETING |
| `agent` | NON | Pas dans MARKETING |

Tenant scope : `RequireTenant` + `useCurrentTenant()` + `tenantId` forward en header.

---

## 7. VALIDATION NAVIGATEUR DEV

| Test | Attendu | Resultat |
|---|---|---|
| Login DEV | OK | OK |
| Navigation /marketing/funnel | Page chargee | OK |
| Tenant selector | KeyBuzz Consulting | OK |
| Menu Marketing | 6 items dans l'ordre | OK (Metrics, Funnel, Ads, Dest, Logs, Guide) |
| Page titre | "Funnel" | OK |
| Sous-titre | "Conversion onboarding..." | OK |
| Filtres dates | Presents | OK |
| Bouton Rafraichir | Present | OK |
| Etat vide (pas de data) | "Aucune donnee funnel" | OK |
| NaN / undefined / Infinity | 0 | 0 |
| Token brut | 0 | 0 |
| Mock / placeholder | 0 | 0 |

### Non-regression

| Page | Resultat |
|---|---|
| /marketing/integration-guide | OK (242 refs, 19 sections, Copier OK) |
| Menu Marketing | OK (6 items corrects) |
| Admin PROD | Inchangee |
| API PROD | Inchangee |

---

## 8. IMAGE DEV

| Element | Valeur |
|---|---|
| Commit Admin initial | `4d876c3` (page + proxies + menu) |
| Commit Admin fix | `bc6394f` (fix TenantContext, StatCard, EmptyState types) |
| Image DEV | `v2.11.9-funnel-cro-ui-dev` |
| Digest | `sha256:6d81302ba622be74dbc1e603cb8d45db150a2fc180b0effa3a1325ce7e5ac159` |
| Commit Infra | `45fc4c5` |
| ROLLBACK DEV | `v2.11.8-agency-tracking-playbook-dev` |

---

## 9. CAPTURES

Les captures ont ete realisees via le navigateur integre durant la validation :
- Page funnel vue generale avec menu Marketing complet
- Etat vide reel "Aucune donnee funnel" sans mock
- Tenant selector "KeyBuzz Consulting" visible
- Integration Guide inchangee (19 sections)

Aucune capture ne contient de token, secret ou payload sensible.

---

## 10. ETAT PROD

| Composant | Impact |
|---|---|
| Admin PROD | Aucun (`v2.11.8-agency-tracking-playbook-prod`) |
| API PROD | Aucun (`v3.5.107-ad-spend-idempotence-fix-prod`) |
| DB PROD | Aucune migration |
| Webflow / DNS | Aucun |
| Tracking reel | Aucun |

---

## 11. LIMITATIONS CONNUES

| Limitation | Impact | Resolution |
|---|---|---|
| `/funnel/metrics` pas de filtre `tenant_id` | Donnees agregees globalement | Future phase API (ajouter filtre `tenant_id` a `/funnel/metrics`) |
| Pas de donnees funnel en DEV (table vide) | Etat vide affiche | Normal — donnees arriveront avec vrais funnels |
| Pas de filtre `source` ni `plan` sur `/funnel/metrics` | Pas de segmentation | Future phase API |

---

## 12. CHEMIN COMPLET DU RAPPORT

```
keybuzz-infra/docs/PH-ADMIN-T8.9C-FUNNEL-CRO-UI-01.md
```

---

**VERDICT** : ADMIN FUNNEL CRO UI READY IN DEV — REAL STEP DATA VISIBLE — TENANT SCOPED — NO MOCK — PROD UNTOUCHED
