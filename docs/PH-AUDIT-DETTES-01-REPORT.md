# PH-AUDIT-DETTES-01 — Audit Dettes Techniques (PH par PH)

**Date:** 2026-01-06  
**Environnement:** DEV uniquement  
**Auditeur:** Cursor Executor

---

## 1. Résumé Exécutif

Cet audit a analysé l'ensemble des repos KeyBuzz, les clusters DEV, et comparé les docs "vérité terrain" aux implémentations réelles.

**Constats majeurs:**
1. ✅ **Infra Stripe V1 complète** : Portal, Checkout, Webhook, DB tables - OK
2. ✅ **UI Billing/Pricing fonctionnelles** : Pages accessibles, portal-session OK
3. ⚠️ **Nombreux mocks non câblés** : ~50+ fichiers avec mock/fallback
4. ⚠️ **tenantId hardcodé** : "kbz-001" dans plusieurs endpoints
5. ⚠️ **Admin UI PH10** : UI shell uniquement, API mocks
6. 🔴 **Auth social (Google/Microsoft)** : Mock users, pas d'OAuth réel
7. ✅ **Aucun secret réel exposé** dans le code

---

## 2. Tableau PH par PH

### Phases PH10 (Admin UI)

| PH | Prévu | Fait | Constat Code | Cluster | Dette |
|----|-------|------|--------------|---------|-------|
| PH10-UI-01 | Tenant listing | ✅ Shell | Mock `globalTenants.service.ts` | N/A | API mock → API réelle |
| PH10-UI-02 | Teams & Agents | ✅ Shell | Mock `TEAMS_MOCK`, `AGENTS_MOCK` | N/A | API mock → API réelle |
| PH10-UI-03 | Integrations | ✅ Shell | N/A | N/A | Intégration Amazon SP-API |
| PH10-UI-04 | AI & Automations | ✅ Shell | Mock actions | N/A | Actions réelles |
| PH10-UI-05 | Messages & SLA | ✅ Shell | N/A | N/A | Câbler API messages |
| PH10-UI-06 | Billing/Plans | ✅ Shell | `billing-app` existe | N/A | Câbler Stripe Admin |
| PH10-UI-07 | Settings | ✅ Shell | Mock complet | N/A | API Keys, Webhooks réels |
| PH10-UI-08 | Logs | ✅ Shell | N/A | N/A | Câbler logs API |
| PH10-UI-09 | Super Admin | ✅ Shell | N/A | N/A | Rôles et permissions |
| PH10-UI-10 | Monitoring | ✅ Shell | Mock `mocks.ts` | N/A | Workers/queues réels |
| PH10-UI-11 | Settings & API Keys | ✅ Shell | Mock complet | N/A | Intégration complète |

### Phases PH11 (Product + SRE)

| PH | Prévu | Fait | Constat Code | Cluster | Dette |
|----|-------|------|--------------|---------|-------|
| PH11-SRE-04 | Observability | ✅ | Prometheus/Grafana | OK | - |
| PH11-SRE-05 | DNS Matrix | ✅ | Docs | OK | - |
| PH11-SRE-06 | DNS/TLS Runbook | ✅ | Docs | OK | - |
| PH11-SRE-07 | Alerting | ✅ | Docs | OK | - |
| PH11-SRE-08 | Watchdog Version | ✅ | `version_guard.py` | monitor-01 | - |
| PH11-PRODUCT-01A | AI Core | ✅ | Routes `/ai/*` | OK | - |
| PH11-PRODUCT-01B | AI Playbooks | ✅ | localStorage | OK | Persistance API |
| PH11-PRODUCT-01C | AI Journal | ✅ | localStorage mock | OK | Persistance API |
| PH11-PRODUCT-01D | AI Decision | ✅ | Mock `AIDecisionPanel.mock.tsx` | OK | API réelle |
| PH11-PRODUCT-02 | Conversation Hardening | ✅ | Routes messages | OK | - |
| PH11-PRODUCT-03B | Notes Persistence | ✅ | Fix `visibility` | OK | - |
| PH11-PRODUCT-03C | Badge IA visuel | ✅ | `MessageBubble.tsx` | OK | - |
| PH11-PRODUCT-03D | Fix source HUMAN/AI | ✅ | `detectMessageSource()` | OK | - |
| PH11-AUTH-401 | DB Reconnect | ✅ | `database.ts` pool | OK | - |

### Phases PH12 (Billing/Stripe)

| PH | Prévu | Fait | Constat Code | Cluster | Dette |
|----|-------|------|--------------|---------|-------|
| PH12-02 | Pricing Page | ✅ | `/pricing` | HTTP 200 | - |
| PH12-03 | Feature Gating | ✅ | `planCapabilities.ts` | OK | - |
| PH12-04 | Billing UI | ✅ | `/billing/*` | HTTP 200 | - |
| PH12-STRIPE-01 | Stripe Checkout | ✅ | `routes.ts` billing | OK | - |
| PH12-STRIPE-02 | Customer Portal | ✅ | `/portal-session` | URL OK | - |
| PH12-STRIPE-ACTIVATE | Stripe Activation | ✅ | Products/Prices créés | Stripe OK | - |

---

## 3. Top 10 Dettes Techniques (Priorité)

### 🔴 Critiques (Sécurité/Business)

| # | Dette | Localisation | Impact | Recommandation |
|---|-------|--------------|--------|----------------|
| 1 | **Auth OAuth mock** | `auth/routes.ts:233-262` | Sécurité | Implémenter OAuth Google/Microsoft réel |
| 2 | **tenantId hardcodé** | `billing/plan/page.tsx:28` | Multi-tenant | Obtenir depuis auth context |
| 3 | **tenantId hardcodé** | `attachments/routes.ts:216,273` | Multi-tenant | Obtenir depuis auth context |

### 🟠 Importantes (Produit)

| # | Dette | Localisation | Impact | Recommandation |
|---|-------|--------------|--------|----------------|
| 4 | **Suppliers mock** | `mockSuppliers` | Produit | API réelle |
| 5 | **Knowledge mock** | `mockLibraryData` | Produit | Persistance DB |
| 6 | **Dashboard demo** | `source: 'demo'` | UX | API réelle |
| 7 | **Tenants fallback** | `MOCK_TENANTS` | Admin | API réelle |
| 8 | **AI Journal localStorage** | `storage.ts:191` | Persistance | API + DB |

### 🟡 Normales (Ops/UX)

| # | Dette | Localisation | Impact | Recommandation |
|---|-------|--------------|--------|----------------|
| 9 | **Admin monitoring mock** | `monitoring/mocks.ts` | Observabilité | Câbler Prometheus |
| 10 | **Settings mock** | `settings/mocks.ts` | Admin | API Keys + Webhooks réels |

---

## 4. Divergences Documentation

### Docs Numérotées vs Vérité Terrain

| Source | Contenu | Statut |
|--------|---------|--------|
| `04-PHASES-PH11-TRAITEES.md` | PH11-SRE, PH11-PRODUCT | ✅ Aligné |
| `14-ETAT-ACTUEL-ET-PROCHAINES-ETAPES.md` | Prochaines étapes | ⚠️ PH12 manquant |
| `19-HISTORIQUE-PHASES-COMPLET.md` | Historique | ⚠️ Pas sur serveur |
| `PH12-*-REPORT.md` (local) | Rapports PH12 | ⚠️ Pas synchronisés serveur |

### Rapports Locaux vs Serveur

| Fichier | Local | Serveur |
|---------|-------|---------|
| `PH12-02-PRICING-PAGE-REPORT.md` | ✅ | ❌ |
| `PH12-03-FEATURE-GATING-REPORT.md` | ✅ | ❌ |
| `PH12-04-BILLING-UI-REPORT.md` | ✅ | ❌ |
| `PH12-STRIPE-01-REPORT.md` | ✅ | ❌ |
| `PH12-STRIPE-02-REPORT.md` | ❌ | Créé ce jour |

**Recommandation:** Synchroniser tous les rapports vers `keybuzz-infra/docs/`

---

## 5. Preuves Techniques

### Versions Déployées DEV

```
API:    ghcr.io/keybuzzio/keybuzz-api:v0.1.54-dev
Client: ghcr.io/keybuzzio/keybuzz-client:v0.2.24-dev
Admin:  ghcr.io/keybuzzio/keybuzz-admin:v1.0.57-dev
```

### Endpoints Fonctionnels

```bash
GET  /health                → 200 OK
GET  /debug/version         → {"version":"0.2.24-dev"...}
GET  /billing/status        → {"tablesReady":true,"stripeConfigured":true}
GET  /billing/current       → {"plan":"PRO","source":"fallback"}
POST /billing/portal-session → {"url":"https://billing.stripe.com/..."}
```

### Tables Billing

```
 Schema |         Name          | Type  
--------+-----------------------+-------
 public | billing_customers     | table 
 public | billing_events        | table 
 public | billing_subscriptions | table 
```

### Scan Mocks (Extrait)

```
Client:  41 fichiers avec mock/TODO
API:     17 fichiers avec mock/TODO  
Admin:   47 fichiers avec mock/TODO
TOTAL:  ~105 points de dette technique
```

### Scan Secrets

```
✅ Aucun secret réel (sk_live_, AKIA...) trouvé dans le code
⚠️ whsec_xxx dans mocks (exemples) → OK, pas de vrais secrets
```

---

## 6. Recommandation : Ordre des Prochaines Phases

### Priorité Immédiate (PH13)

1. **PH13-AUTH-OAUTH** - Implémenter OAuth Google/Microsoft réel
2. **PH13-TENANT-CONTEXT** - tenantId depuis auth context (pas hardcodé)
3. **PH13-DOCS-SYNC** - Synchroniser docs locales → serveur

### Priorité Haute (PH14)

4. **PH14-ADMIN-API-01** - Câbler Admin UI → API (tenants, teams)
5. **PH14-ADMIN-API-02** - Câbler Admin UI → API (monitoring, settings)
6. **PH14-AI-PERSIST** - Persistance AI Journal / Playbooks en DB

### Priorité Normale (PH15+)

7. **PH15-SUPPLIERS** - API suppliers réelle
8. **PH15-KNOWLEDGE** - Persistance knowledge base
9. **PH15-DASHBOARD** - Données dashboard réelles
10. **PH15-INTEGRATIONS** - Amazon SP-API activation

---

## 7. Conclusion

L'infrastructure Stripe V1 est opérationnelle. Les principales dettes concernent :
- **Auth OAuth** (critique)
- **Multi-tenant context** (critique)  
- **Mocks Admin UI** (nombreux mais non bloquants)
- **Persistance IA** (AI Journal, Playbooks)

**Score santé code:** 7/10  
**Score production-ready:** 5/10 (DEV OK, PROD nécessite fixes critiques)

---

**Fin du rapport PH-AUDIT-DETTES-01**
