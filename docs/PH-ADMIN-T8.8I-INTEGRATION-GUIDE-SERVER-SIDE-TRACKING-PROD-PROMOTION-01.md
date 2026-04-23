# PH-ADMIN-T8.8I — Integration Guide Server-Side Tracking PROD Promotion

**Phase** : PH-ADMIN-T8.8I-INTEGRATION-GUIDE-SERVER-SIDE-TRACKING-PROD-PROMOTION-01
**Date** : 2026-04-23
**Environnement** : PROD
**Type** : Promotion PROD — Documentation Admin UI Server-Side Tracking
**Priorite** : P1

---

## 1. PREFLIGHT

| Element | Valeur |
|---|---|
| Branche Infra | `main` |
| HEAD avant | `b2346de` (PH-ADMIN-T8.8I DEV) |
| Image Admin PROD avant | `v2.11.6-metrics-currency-cac-controls-prod` |
| Image Admin DEV | `v2.11.7-integration-guide-server-side-tracking-dev` |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` (inchange) |
| API DEV | `v3.5.107-ad-spend-idempotence-fix-dev` (inchange) |
| Rapport DEV | `PH-ADMIN-T8.8I-INTEGRATION-GUIDE-SERVER-SIDE-TRACKING-DOCS-01.md` (commit `b2346de`) |
| Rapport H (Meta CAPI) | `PH-ADMIN-T8.8H-KBC-META-CAPI-OUTBOUND-REAL-CONFIG-VALIDATION-01.md` (commit `5687f45`) |
| Repo Infra | clean |

---

## 2. SOURCE VERIFICATION

| Verification | Resultat |
|---|---|
| Fichier source | `/opt/keybuzz/keybuzz-admin-v2/src/app/(admin)/marketing/integration-guide/page.tsx` |
| Taille | 404 lignes |
| Sections presentes | 10/10 |
| Tokens bruts | 0 (aucun secret en clair) |
| Menu sidebar | Marketing > Integration Guide present |

### Sections confirmees

| # | Section |
|---|---|
| 1 | Vue d'ensemble — Server-Side Tracking |
| 2 | Ads Accounts — Depenses publicitaires |
| 3 | Destinations — Evenements outbound |
| 4 | Evenements business (StartTrial, Purchase, SubscriptionRenewed, SubscriptionCancelled) |
| 5 | Anti-doublon — Regles critiques |
| 6 | Metrics — KPIs tenant-scoped |
| 7 | Delivery Logs — Preuves d'envoi |
| 8 | Webhook — Verification HMAC (Node.js + Python) |
| 9 | Bonnes pratiques |
| 10 | Website / Landing — Etat actuel |

---

## 3. BUILD PROD

| Element | Valeur |
|---|---|
| Tag | `v2.11.7-integration-guide-server-side-tracking-prod` |
| Registry | `ghcr.io/keybuzzio/keybuzz-admin` |
| Build | `docker build --platform linux/amd64 -t ... .` |
| Push | `docker push ...` |
| Digest | `sha256:f1d7f984...` |
| Duree build | ~3 min |

---

## 4. GITOPS PROD

| Element | Valeur |
|---|---|
| Fichier | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.7-integration-guide-server-side-tracking-prod` |
| ROLLBACK comment | `v2.11.6-metrics-currency-cac-controls-prod` |
| Commit | `482296a` |
| Message | `PH-ADMIN-T8.8I-PROD: Admin v2.11.7-integration-guide-server-side-tracking-prod -- rollback: v2.11.6-metrics-currency-cac-controls-prod -- API PROD unchanged v3.5.107` |

---

## 5. DEPLOY PROD

| Element | Valeur |
|---|---|
| Methode | `kubectl set image` |
| Rollout | Complete, 0 restarts |
| Pod status | Running |
| DEV image | Inchangee (`v2.11.7-...dev`) |
| API PROD image | Inchangee (`v3.5.107-...-prod`) |

---

## 6. VALIDATION NAVIGATEUR PROD

### 6.1 Integration Guide (`/marketing/integration-guide`)

| Check | Resultat |
|---|---|
| Page accessible | OK |
| Titre principal | "Integration Guide" + sous-titre SST |
| Section 1 — Vue d'ensemble | Architecture 4 briques visible |
| Section 2 — Ads Accounts | Meta Ads Supporte, badge Encrypted, depreciation /import/meta |
| Section 3 — Destinations | Meta CAPI natif + Webhook cote a cote |
| Section 4 — Evenements business | 4 events listes, payload Purchase, event_id |
| Section 5 — Anti-doublon | Regle fondamentale, scenarios courants, recommandation |
| Section 6 — Metrics | Devise par defaut, CAC Super Admin |
| Section 7 — Delivery Logs | Token sanitization |
| Section 8 — Webhook HMAC | Code Node.js + Python, headers envoyes |
| Section 9 — Bonnes pratiques | 8 points |
| Section 10 — Website/Landing | Webflow non concerne, tracking browser deja en place |
| Boutons Copier (code blocks) | 4 visibles |

### 6.2 Menu sidebar PROD

| Rubrique | Lien | Visible |
|---|---|---|
| Metrics | `/metrics` | OK |
| Ads Accounts | `/marketing/ad-accounts` | OK |
| Destinations | `/marketing/destinations` | OK |
| Delivery Logs | `/marketing/delivery-logs` | OK |
| Integration Guide | `/marketing/integration-guide` | OK |

---

## 7. NON-REGRESSION PROD

### 7.1 Metrics (`/metrics`)

| KPI | Valeur | Attendu |
|---|---|---|
| Spend total (GBP) | 445 GBP | ~445 GBP (conforme PH-T8.8G) |
| Boutons devise | EUR / GBP / USD | OK |
| Bouton CAC (Super Admin) | "Inclus dans le CAC" visible | OK |

### 7.2 Destinations (`/marketing/destinations`)

| Element | Valeur |
|---|---|
| Destination KBC Meta CAPI | Visible |
| Badge | Actif + Test: success |
| Token | Masque (`EA*****...`) |
| Pixel | `1234164602194748` |
| Endpoint | `https://graph.facebook.com/v21.0/1234164602194748/events` |
| Boutons | Test PageView Meta, Desactiver, Supprimer |

### 7.3 Token Safety

| Check | Resultat |
|---|---|
| Token dans Integration Guide | Aucun (0 secret en clair) |
| Token dans Destinations | Masque (`EA*****...`) |
| Token dans logs | Non verifie (delivery logs sanitises cote serveur) |

### 7.4 Impacts

| Composant | Impact |
|---|---|
| API SaaS PROD | Aucun (image inchangee) |
| Base de donnees | Aucune migration |
| Admin DEV | Aucun (image inchangee) |
| Webflow / DNS | Aucune modification |
| Metrics spend | Stable (445 GBP) |
| Destinations Meta CAPI | Fonctionnelle (Actif, Test: success) |

---

## 8. ROLLBACK PROD

En cas de regression :

```bash
# Rollback immediat
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.11.6-metrics-currency-cac-controls-prod \
  -n keybuzz-admin-v2-prod

# Verifier rollback
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
kubectl get pods -n keybuzz-admin-v2-prod

# Puis corriger le manifest GitOps
# k8s/keybuzz-admin-v2-prod/deployment.yaml → remettre v2.11.6-metrics-currency-cac-controls-prod
```

---

## 9. TIMELINE

| Heure | Etape |
|---|---|
| T+0 | Preflight : branche main, images confirmees |
| T+1 | Source verification : 10 sections, 0 token brut |
| T+2 | Build PROD : v2.11.7-integration-guide-server-side-tracking-prod |
| T+3 | GitOps : manifest PROD mis a jour (commit 482296a) |
| T+4 | Deploy PROD : kubectl set image, rollout OK, 0 restarts |
| T+5 | Validation navigateur : 10 sections OK, menu OK, boutons Copier OK |
| T+6 | Non-regression : Metrics 445 GBP, Destinations Meta CAPI actif |
| T+7 | Rapport final |

---

## 10. RESUME

| Element | Avant | Apres |
|---|---|---|
| Image Admin PROD | `v2.11.6-metrics-currency-cac-controls-prod` | `v2.11.7-integration-guide-server-side-tracking-prod` |
| Integration Guide | Ancien contenu (basique) | 10 sections SST completes (404 lignes) |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` | Inchangee |
| Metrics spend | ~445 GBP | Stable |
| Destinations Meta CAPI | Actif, Test: success | Inchange |
| Rollback | `v2.11.5-ad-accounts-ui-hardening-prod` | `v2.11.6-metrics-currency-cac-controls-prod` |

---

**Statut** : COMPLETE — PROD v2.11.7 deploye et valide
**Prochaine etape** : PH-ADMIN-T8.8J (a definir)
