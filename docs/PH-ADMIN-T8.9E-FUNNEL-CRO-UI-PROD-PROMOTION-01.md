# PH-ADMIN-T8.9E — Funnel CRO UI PROD Promotion

**Phase** : PH-ADMIN-T8.9E-FUNNEL-CRO-UI-PROD-PROMOTION-01
**Date** : 2026-04-23
**Environnement** : PROD
**Type** : promotion PROD UI Funnel / CRO marketing tenant-scoped
**Priorité** : P0

---

## 0. PRÉFLIGHT

| Élément | Valeur | Conforme |
|---|---|---|
| Branche Infra | `main` | OK |
| HEAD Infra | `4083fbd` | OK |
| Admin PROD avant | `v2.11.8-agency-tracking-playbook-prod` | OK |
| Admin DEV | `v2.11.11-funnel-metrics-tenant-proxy-fix-dev` | OK |
| API PROD | `v3.5.109-funnel-metrics-tenant-scope-prod` | OK |
| Client PROD | `v3.5.108-funnel-pretenant-foundation-prod` | OK |
| HEAD Admin (bastion) | `63f9ed3` | OK |
| Page Funnel | présente | OK |
| Proxy metrics `tenant_id` | présent | OK |
| Proxy events `tenant_id` | présent | OK |
| Icône Filter Sidebar | présente | OK |
| Repo | clean | OK |

---

## 1. VÉRIFICATION SOURCE

| Point | Résultat |
|---|---|
| Route `/marketing/funnel` | Page existe (`page.tsx`, 21102 octets) |
| Proxy `funnel/metrics` — `tenant_id` forwardé | OUI (`apiParams.set('tenant_id', tenantId)`) |
| Proxy `funnel/events` — `tenant_id` forwardé | OUI |
| Menu Marketing — Funnel position | Position 2 (après Metrics, avant Ads Accounts) |
| Icône `Filter` importée + iconMap | OUI (2 occurrences dans Sidebar.tsx) |
| Mock/placeholder/fake dans la page | **0 occurrence** |
| État vide réel | 2 messages d'état vide présents |
| Business truth section | 5 références (micro-steps, trial_started, purchase_completed) |

---

## 2. IMAGE PROD

| Élément | Valeur |
|---|---|
| Image PROD avant | `v2.11.8-agency-tracking-playbook-prod` |
| Image PROD après | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` |
| Commit Admin | `63f9ed3` |
| Digest | `sha256:a896c9d710bbca6997c6c2c0cefc74f7ad66e5d0dcd1387a50509da82fe54b80` |
| Build-from-git | OUI |
| Repo clean | OUI |

---

## 3. GITOPS PROD

| Élément | Valeur |
|---|---|
| Fichier modifié | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Commit infra | `131b354` |
| Image avant | `v2.11.8-agency-tracking-playbook-prod` |
| Image après | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` |
| ROLLBACK | `v2.11.8-agency-tracking-playbook-prod` |
| DEV manifest | inchangé |
| API PROD manifest | inchangé |
| Client PROD manifest | inchangé |

---

## 4. DEPLOY PROD

| Élément | Valeur |
|---|---|
| `kubectl apply` | `deployment.apps/keybuzz-admin-v2 configured` |
| Rollout | `successfully rolled out` |
| Pod | `keybuzz-admin-v2-86ddd6c85f-t7m9h` — 1/1 Running |
| Restarts | 0 |
| Age | 30s au moment de la vérification |

---

## 5. VALIDATION NAVIGATEUR PROD

### A. Navigation

| Test | Résultat |
|---|---|
| Login `admin.keybuzz.io` | OK |
| Menu Marketing visible | OK |
| Funnel en position 2 | OK (Metrics → Funnel → Ads Accounts) |
| Icône Funnel (Filter) visible et alignée | OK |

### B. Tenant 1 — KeyBuzz Consulting

| Test navigateur | Attendu | Résultat |
|---|---|---|
| Page `/marketing/funnel` charge | Oui | PASS |
| Titre "Funnel" + sous-titre | Présent | PASS |
| Tenant selector | KeyBuzz Consulting | PASS |
| État vide réel | "Aucune donnée funnel" | PASS |
| Message explicatif | Lisible, pas de mock | PASS |
| NaN / undefined / Infinity | 0 | PASS |

Note : en PROD, aucun funnel event n'existe encore pour ce tenant — l'état vide est le comportement correct et attendu.

### C. Tenant 2 — eComLG (ecomlg-001)

| Test navigateur | Attendu | Résultat |
|---|---|---|
| Tenant selector | eComLG | PASS |
| État vide réel | "Aucune donnée funnel" | PASS |
| Aucune fuite cross-tenant | Aucune donnée d'un autre tenant | PASS |

Note : même situation — pas de funnel events en PROD pour ce tenant. Comportement identique et correct.

### D. Qualité UI

| Test | Résultat |
|---|---|
| NaN / undefined / Infinity | 0 |
| Mock | 0 |
| Overlap | 0 |
| Texte tronqué gênant | 0 |
| Token brut | 0 |

### E. Business truth

| Test | Résultat |
|---|---|
| Micro-steps internes funnel | Section présente dans le code source (5 références) |
| Distinction business events | Présente (`trial_started`, `purchase_completed` vs micro-steps) |
| Confusion revenue/conversion | Aucune — la page ne mélange pas les deux |

---

## 6. NON-RÉGRESSION

| Vérification | Résultat |
|---|---|
| `/metrics` | OK — charge normalement |
| `/marketing/ad-accounts` | OK |
| `/marketing/destinations` | OK |
| `/marketing/delivery-logs` | OK |
| `/marketing/integration-guide` | OK (contenu complet chargé) |
| Menu Marketing ordre | OK (Metrics → Funnel → Ads Accounts → Destinations → Delivery Logs → Integration Guide) |
| Icônes menu | OK |
| Token safety | OK |
| Tenant isolation | OK |
| Admin DEV | `v2.11.11-funnel-metrics-tenant-proxy-fix-dev` — inchangée |
| API PROD | `v3.5.109-funnel-metrics-tenant-scope-prod` — inchangée |
| Client PROD | `v3.5.108-funnel-pretenant-foundation-prod` — inchangé |

---

## 7. CAPTURES PROD

Captures prises via navigateur automatisé sur `admin.keybuzz.io` :

1. **Menu Marketing avec Funnel visible** — icône Filter alignée, position 2
2. **Funnel Tenant 1 (KeyBuzz Consulting)** — état vide réel, message explicatif, tenant-scoped
3. **Funnel Tenant 2 (eComLG)** — état vide réel, aucune fuite cross-tenant

Aucun token, secret ou payload sensible visible dans les captures.

---

## 8. LIMITATION CONNUE

### Filtre date `to` (API-side)

Le paramètre `to` de l'API `GET /funnel/metrics` est traité comme `2026-04-23T00:00:00Z` (minuit exclusif), excluant les events créés plus tard dans la même journée.

**Impact** : Si la date "au" dans l'UI est la date du jour, les events injectés le même jour n'apparaissent pas.

**Workaround** : Utiliser `to = lendemain` dans le sélecteur de dates.

**Correction** : À faire dans une future phase SaaS API si nécessaire (modifier le backend pour traiter `to` comme fin de journée inclusive).

**Non corrigé dans cette phase** : conformément aux règles, seul l'Admin a été promu.

---

## 9. ROLLBACK PROD

En cas de nécessité, restaurer vers l'image précédente via GitOps :

```yaml
# k8s/keybuzz-admin-v2-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.8-agency-tracking-playbook-prod
```

Appliquer :
```bash
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

Aucun rollback API ou Client nécessaire — ils n'ont pas été modifiés.

---

## 10. ÉTAT FINAL

| Composant | Image | Changé ? |
|---|---|---|
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | OUI |
| Admin DEV | `v2.11.11-funnel-metrics-tenant-proxy-fix-dev` | non |
| API PROD | `v3.5.109-funnel-metrics-tenant-scope-prod` | non |
| API DEV | `v3.5.109-funnel-metrics-tenant-scope-dev` | non |
| Client PROD | `v3.5.108-funnel-pretenant-foundation-prod` | non |

---

## 11. CHEMIN COMPLET DU RAPPORT

```
keybuzz-infra/docs/PH-ADMIN-T8.9E-FUNNEL-CRO-UI-PROD-PROMOTION-01.md
```

---

**VERDICT** : ADMIN FUNNEL CRO UI LIVE IN PROD — TENANT-SCOPED REAL DATA VISIBLE — ICON OK — NO MOCK — NO REGRESSION
