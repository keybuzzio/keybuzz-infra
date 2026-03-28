# PH-PLAYBOOKS-STARTERS-ACTIVATION-03 — Rapport Final

> Date : 28 mars 2026
> Environnement : DEV uniquement (modification DB)
> PROD : NON TOUCHÉ
> Type : activation contrôlée des starters backend (DB-only, pas de build)

---

## 1. Versions avant action

| Service | DEV | PROD |
|---------|-----|------|
| Client | `v3.5.125-playbooks-engine-alignment-dev` | `v3.5.125-playbooks-engine-alignment-prod` |
| API | `v3.5.50-ph-tenant-iso-dev` | `v3.5.50-ph-tenant-iso-prod` |

Aucun build client/API n'a été nécessaire. Cette phase est une modification DB uniquement.

---

## 2. Rollback

### DEV (DB-only)

```sql
UPDATE ai_rules
SET status = 'disabled', updated_at = NOW()
WHERE is_starter = true
  AND trigger_type IN (
    'tracking_request', 'delivery_delay', 'return_request',
    'defective_product', 'payment_declined', 'invoice_request',
    'order_cancelled'
  )
  AND status = 'active';
```

### PROD

PROD non touché — aucun rollback nécessaire.

---

## 3. État avant activation

| Donnée | Valeur |
|--------|--------|
| Tenants avec starters | 7 |
| Total starters DB | 105 (15 × 7 tenants) |
| Starters `active` | 0 |
| Starters `disabled` | 105 |
| Mode | `suggest` (100%) |

---

## 4. Matrice d'activation retenue

### ACTIVÉS (8 starters par tenant, 56 total)

| # | Nom | trigger_type | min_plan | Actions | Risque |
|---|-----|-------------|----------|---------|--------|
| 1 | Où est ma commande ? | tracking_request | starter | show_tracking, send_reply_template, add_tag | FAIBLE |
| 2 | Suivi indisponible | tracking_request | starter | add_note, send_reply_template, set_status(pending) | FAIBLE |
| 3 | Retard de livraison | delivery_delay | starter | add_tag, send_reply_template, set_priority(high) | FAIBLE |
| 4 | Demande de retour | return_request | starter | add_tag, send_reply_template | FAIBLE |
| 5 | Produit défectueux | defective_product | starter | add_tag, request_proof, send_reply_template | FAIBLE |
| 6 | Paiement refusé | payment_declined | starter | send_reply_template, set_status(pending) | FAIBLE |
| 7 | Demande de facture | invoice_request | starter | add_tag, send_reply_template | FAIBLE |
| 8 | Annulation de commande | order_cancelled | starter | send_reply_template, set_status(resolved) | FAIBLE (suggest = manual apply) |

**Critères d'inclusion :**
- Mode `suggest` uniquement (l'agent doit approuver)
- Aucune action IA payante (0 KBA sur apply)
- Cas d'usage e-commerce standard et bien défini
- min_plan = starter (accessible à tous les plans)

### CONSERVÉS DÉSACTIVÉS (7 starters par tenant, 49 total)

| # | Nom | trigger_type | min_plan | Raison du maintien disabled |
|---|-----|-------------|----------|-----------------------------|
| 9 | Client agressif | negative_sentiment | pro | `prefill_reply` = action IA payante (6 KBA) |
| 10 | Mauvaise description | wrong_description | pro | `trigger_ai_analysis` = action IA payante (14 KBA) |
| 11 | Produit incompatible | incompatible_product | pro | `prefill_reply` = action IA payante (6 KBA) |
| 12 | Message hors sujet | off_topic | pro | Keywords trop larges ("information", "question"), faux positifs |
| 13 | Client VIP | vip_client | pro | Trigger vide (0 keywords) — ne déclenchera jamais |
| 14 | Message sans réponse | unanswered_timeout | starter | Trigger vide (0 keywords) — conçu pour SLA timeout, pas text match |
| 15 | Escalade vers support | escalation_needed | autopilot | min_plan autopilot + assign_agent = action lourde |

---

## 5. Implémentation

### SQL appliqué (DEV uniquement)

```sql
UPDATE ai_rules
SET status = 'active', updated_at = NOW()
WHERE is_starter = true
  AND trigger_type IN (
    'tracking_request', 'delivery_delay', 'return_request',
    'defective_product', 'payment_declined', 'invoice_request',
    'order_cancelled'
  )
  AND status = 'disabled';
```

**Résultat** : 56 rows updated (8 starters × 7 tenants)

---

## 6. État après activation

| Donnée | Valeur |
|--------|--------|
| Starters `active` | 56 (8 × 7 tenants) |
| Starters `disabled` | 49 (7 × 7 tenants) |
| Distribution par tenant | Uniforme (8 active + 7 disabled chacun) |
| Mode des starters actifs | `suggest` (100%) |
| Actions IA payantes actives | 0 |
| Auto-exécution activée | NON |

### Détail par tenant

| Tenant | Active | Disabled |
|--------|--------|----------|
| ecomlg-001 | 8 | 7 |
| ecomlg07-gmail-com-mn7pn69e | 8 | 7 |
| ecomlg-mmiyygfg | 8 | 7 |
| srv-performance-mn7ds3oj | 8 | 7 |
| switaa-mn9ioy5j | 8 | 7 |
| switaa-sasu-mn9if5n2 | 8 | 7 |
| tenant-1772234265142 | 8 | 7 |

---

## 7. Validation DEV

### Tests effectués

| Test | Résultat |
|------|----------|
| API /playbooks ecomlg-001 | 8 active, 7 disabled ✅ |
| Mode starters actifs | 100% `suggest` ✅ |
| Auto-exécution | 0 starters en mode auto ✅ |
| Actions IA payantes | 0 dans les starters actifs ✅ |
| Distribution multi-tenant | Uniforme (8 par tenant) ✅ |
| Suggestions existantes | 0 (pas de spam) ✅ |
| Page /playbooks | HTTP 200 ✅ |
| Page /inbox | HTTP 200 ✅ |
| Page /dashboard | HTTP 200 ✅ |
| Page /orders | HTTP 200 ✅ |
| Page /billing | HTTP 200 ✅ |
| API /health | ok ✅ |

### Sécurité anti-spam

- **ZERO action IA payante** dans les starters activés
- **ZERO auto-exécution** : mode `suggest` uniquement
- **ZERO suggestions générées** : le moteur ne crée des suggestions que lors du traitement de messages entrants réels
- **Distribution uniforme** : aucun favoritisme tenant

### Impact Autopilot

- Aucune régression : les starters activés sont en mode `suggest`
- L'autopilot ne traite que les règles en mode `auto` ou `autopilot`
- Aucun starter n'a été basculé en mode auto dans cette phase

### Impact AI Journal

- Pas d'impact : le journal enregistre uniquement les exécutions réelles
- Les suggestions ne sont loguées que si l'agent les applique manuellement

---

## 8. État PROD

**PROD NON TOUCHÉ** — En attente de validation Ludovic.

Pour appliquer en PROD, le même SQL sera exécuté sur la DB PROD (`keybuzz_prod`) via le pod API PROD.

---

## 9. Verdict

**STARTERS ACTIVATED SAFELY — SUGGEST ONLY — TENANT SAFE — NO AUTOPILOT REGRESSION — ROLLBACK READY**

| Critère | Statut |
|---------|--------|
| Activation contrôlée | ✅ 8/15 starters activés |
| Mode suggest uniquement | ✅ 0 auto-exécution |
| Actions IA payantes | ✅ 0 dans les actifs |
| Multi-tenant uniforme | ✅ 8 par tenant sur 7 tenants |
| Anti-spam | ✅ 0 suggestions spam |
| Non-régression inbox | ✅ HTTP 200 |
| Non-régression autopilot | ✅ Aucun impact |
| Non-régression billing | ✅ HTTP 200 |
| PROD | ✅ NON TOUCHÉ |
| Rollback | ✅ SQL ready |

---

**DEV validé. STOP avant PROD. J'attends la validation explicite de Ludovic : "Tu peux push PROD".**
