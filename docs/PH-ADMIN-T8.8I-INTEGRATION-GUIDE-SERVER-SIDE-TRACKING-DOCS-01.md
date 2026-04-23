# PH-ADMIN-T8.8I — Integration Guide Server-Side Tracking Docs

**Phase** : PH-ADMIN-T8.8I-INTEGRATION-GUIDE-SERVER-SIDE-TRACKING-DOCS-01
**Date** : 2026-04-23
**Environnement** : DEV uniquement
**Type** : Documentation Admin UI — Server-Side Tracking / Ads Accounts / Destinations / Metrics
**Priorite** : P1

---

## 1. PREFLIGHT

| Element | Valeur |
|---|---|
| Branche Admin | `main` |
| HEAD avant | `461e08a` (fix metrics display_currency) |
| Image Admin DEV avant | `v2.11.6-metrics-currency-cac-controls-dev` |
| Image Admin PROD | `v2.11.6-metrics-currency-cac-controls-prod` |
| API DEV | `v3.5.107-ad-spend-idempotence-fix-dev` |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` |
| Rapport H | Committe (`5687f45`) dans keybuzz-infra |
| Repo Admin | clean |

---

## 2. SOURCES RELUES

| Source | Statut |
|---|---|
| PH-T8.8G — Ad Spend Idempotence Fix and PROD Cleanup | Relu |
| PH-ADMIN-T8.8H — KBC Meta CAPI Outbound Real Config Validation | Relu |
| PH-T8.8E — PROD Promotion Metrics Currency CAC Controls API | Relu |
| PH-ADMIN-T8.8E — PROD Promotion Metrics Currency CAC Controls UI | Relu (conversation) |
| PH-T8.8C — PROD Promotion Ad Accounts Secret Store | Relu (conversation) |
| PH-T8.7B.3 — Meta CAPI Error Sanitization | Relu (conversation) |
| PH-T8.8 — Business Events Inbound Sources Architecture | Relu (conversation) |

---

## 3. SECTIONS AJOUTEES DANS INTEGRATION GUIDE

La page `/marketing/integration-guide` a ete entierement reecrite (191 lignes → 404 lignes).

### Sections

| # | Section | Contenu |
|---|---|---|
| 1 | Vue d'ensemble — Server-Side Tracking | Architecture 4 briques, isolation tenant, token safety |
| 2 | Ads Accounts — Depenses publicitaires | Meta Ads supporte, token chiffre, sync, depreciation /import/meta (410) |
| 3 | Destinations — Evenements outbound | Meta CAPI natif vs Webhook, PageView test vs business events |
| 4 | Evenements business | 4 events (StartTrial, Purchase, SubscriptionRenewed, SubscriptionCancelled), payload exemple, badges Standard Meta / Custom |
| 5 | Anti-doublon — Regles critiques | Regle fondamentale (1 proprietaire par event), 4 scenarios A-D, deduplication event_id, recommandation Addingwell |
| 6 | Metrics — KPIs tenant-scoped | 5 KPIs (Spend, New customers, MRR, CAC, ROAS), 3 devises (EUR/GBP/USD), controle CAC Super Admin |
| 7 | Delivery Logs — Preuves d'envoi | 5 colonnes, token sanitization |
| 8 | Webhook — Verification HMAC | Headers, code Node.js, code Python |
| 9 | Bonnes pratiques | 8 regles (HMAC, idempotence, retries, HTTPS, etc.) |
| 10 | Website / Landing — Etat actuel | Pas de changement, futur audit dedie |

### Composants UI utilises

- `CodeBlock` avec bouton Copier
- `SectionTitle` avec icones Lucide
- `Badge` avec variants (default, warning, success, info)
- Tableaux, listes, encarts colores (bleu, emeraude, ambre, rouge)
- Grid responsive 2 colonnes pour Destinations (Meta CAPI vs Webhook)
- Grid 3 colonnes pour les devises

---

## 4. CAPTURES D'ECRAN

Captures prises depuis `admin-dev.keybuzz.io` (DEV) :

| Page | Statut | Token safe |
|---|---|---|
| `/marketing/integration-guide` (haut) | OK — Vue d'ensemble + Ads Accounts visibles | Oui |
| `/marketing/integration-guide` (scroll 2) | OK — Destinations + Evenements business | Oui |
| `/marketing/integration-guide` (scroll 3) | OK — Anti-doublon + Metrics | Oui |
| `/marketing/integration-guide` (scroll 4) | OK — Delivery Logs + Webhook HMAC | Oui |
| `/marketing/integration-guide` (scroll 5) | OK — Bonnes pratiques + Website/Landing | Oui |
| `/metrics` | OK — KBC 445 GBP, devise GBP, banner donnees reelles | Oui |
| `/marketing/ad-accounts` | OK — Meta Ads, Active, Encrypted | Oui |
| `/marketing/destinations` | OK — Aucune destination (DEV, normal) | Oui |
| `/marketing/delivery-logs` | OK — Aucun log (DEV, normal) | Oui |

**Aucun token brut, access_token, ou secret dans les captures.**

---

## 5. VALIDATION NAVIGATEUR DEV

| Check | Resultat |
|---|---|
| Login admin-dev.keybuzz.io | OK |
| Tenant selector | KeyBuzz Consulting selectionne |
| Page integration-guide lisible | OK — 10 sections completes |
| Overlap UI | Aucun |
| Texte tronque | Aucun |
| NaN / undefined / mock | Aucun |
| Navigation Marketing ordre | 1. Metrics, 2. Ads Accounts, 3. Destinations, 4. Delivery Logs, 5. Integration Guide |
| Metrics — KBC spend | 445 GBP (coherent) |
| Ad Accounts — token | Masque (Encrypted badge) |
| Console errors | Aucune erreur liee au code (uniquement next-auth pre-existant) |

---

## 6. TOKEN SAFETY

| Check | Resultat |
|---|---|
| Token brut dans UI | 0 |
| Token dans captures | 0 |
| Token dans rapport | 0 |
| Secret webhook dans captures | 0 |
| Payload sensible | 0 |

---

## 7. IMAGE DEV

| Element | Valeur |
|---|---|
| Tag | `v2.11.7-integration-guide-server-side-tracking-dev` |
| Digest | `sha256:c3e4601e32240aefdbd2a2e18f53ad442f8e0deb939a3448acdb0867293c7b8a` |
| Commit Admin | `dfa328d` (PH-ADMIN-T8.8I: integration guide server-side tracking) |
| Build-from-git | Oui (commit + push avant build) |
| Deploy | `kubectl set image` via script (DEV uniquement) |
| Rollout | Success |

---

## 8. GITOPS

| Fichier | Image |
|---|---|
| `k8s/keybuzz-admin-v2-dev/deployment.yaml` | `v2.11.7-integration-guide-server-side-tracking-dev` |
| `k8s/keybuzz-admin-v2-prod/deployment.yaml` | `v2.11.6-metrics-currency-cac-controls-prod` (INCHANGE) |

### Rollback DEV

```
image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.6-metrics-currency-cac-controls-dev
```

### Rollback PROD

Non applicable — PROD non touche.

---

## 9. ETAT PROD

| Element | Valeur |
|---|---|
| Image Admin PROD | `v2.11.6-metrics-currency-cac-controls-prod` (INCHANGE) |
| Image API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` (INCHANGE) |
| Modifications PROD | **ZERO** |

---

## 10. INTERDICTIONS RESPECTEES

| Interdiction | Respectee |
|---|---|
| DEV only | OUI |
| Branche main | OUI |
| Build-from-git | OUI |
| Commit + push avant build | OUI |
| GitOps strict | OUI |
| Aucun kubectl set image PROD | OUI |
| Aucun kubectl patch | OUI |
| Aucun kubectl edit | OUI |
| Aucun changement API SaaS | OUI |
| Aucun changement DB | OUI |
| Aucun changement Webflow | OUI |
| Aucun changement DNS | OUI |
| Aucun token brut | OUI |
| Aucun mock data | OUI |
| Aucun faux KPI | OUI |
| Bastion install-v3 (46.62.171.61) | OUI |

---

## 11. LIMITES RESTANTES

1. **Version footer** : la sidebar affiche `v2.10.7` — le composant `build-metadata.ts` n'est pas alimente par le pipeline de build (pre-existant, pas lie a cette phase)
2. **Captures non sauvegardees en fichier** : les screenshots sont dans le browser/temp, pas dans `keybuzz-infra/docs/screenshots/` — a copier manuellement si necessaire
3. **PROD** : la page Integration Guide en PROD reste l'ancienne version (webhooks uniquement) — promotion PROD dans une phase ulterieure

---

## 12. VERDICT FINAL

**ADMIN INTEGRATION GUIDE SERVER-SIDE TRACKING READY IN DEV — ADS ACCOUNTS / DESTINATIONS / METRICS DOCUMENTED — TOKEN SAFE — PROD UNTOUCHED**

- Page reecrite de 191 → 404 lignes
- 10 sections couvrant l'architecture complete Server-Side Tracking
- Anti-doublon Meta / Addingwell documente
- Depreciation `/metrics/import/meta` documentee
- Token safety respectee dans UI, captures, et rapport
- Image DEV `v2.11.7-integration-guide-server-side-tracking-dev` deployee et validee
- PROD strictement inchange
