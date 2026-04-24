# PH-T8.10E.1-OUTBOUND-ROUTING-OWNER-AWARE-RUNTIME-TRUTH-VALIDATION-01 — TERMINÉ

**Verdict : GO**

> OUTBOUND ROUTING OWNER-AWARE RUNTIME TRUTH ESTABLISHED IN DEV — OWNER LOOKUP PROVED — LEGACY PRESERVED — PROD UNTOUCHED

---

## Préflight

| Point | Résultat |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API | `e368d318` |
| Image API DEV | `v3.5.113-outbound-routing-owner-aware-dev` |
| Image API PROD | `v3.5.111-activation-completed-model-prod` |
| Repo clean | Oui |
| Mode | Validation runtime — aucun patch, aucun build, aucun deploy |

---

## Runtime déployé

| Service | Image attendue | Image runtime observée | Statut |
|---|---|---|---|
| API DEV | `v3.5.113-outbound-routing-owner-aware-dev` | `v3.5.113-outbound-routing-owner-aware-dev` | OK |
| API PROD | `v3.5.111-activation-completed-model-prod` | `v3.5.111-activation-completed-model-prod` | Inchangée |

Pod : `keybuzz-api-6df5964654-n8gct` — Running, 0 restarts, worker k8s-worker-05.

---

## État des données avant test

### A. Owner mapping

| Tenant | `marketing_owner_tenant_id` | Status |
|---|---|---|
| `keybuzz-consulting-mo9y479d` (owner) | `null` | active |
| `proof-owner-valid-t8-mocqwjk7` (enfant) | `keybuzz-consulting-mo9y479d` | pending_payment |
| `proof-no-owner-t810b-mocqwkvo` (legacy) | `null` | pending_payment |

### B. Destinations outbound (avant test)

| Tenant | Destinations | Actives | Types |
|---|---|---|---|
| `keybuzz-consulting-mo9y479d` | 2 | 0 (toutes deleted/inactive) | webhook, meta_capi |
| `proof-owner-valid-t8-mocqwjk7` | 0 | 0 | — |
| `proof-no-owner-t810b-mocqwkvo` | 0 | 0 | — |

### C. Tables de preuve (baseline)

| Vue | Mesure | Résultat |
|---|---|---|
| `conversion_events` | count | 0 |
| `outbound_conversion_delivery_logs` | count | 3 (anciens) |
| `outbound_conversion_destinations` | count | 6 |
| `billing_subscriptions` | count | 16 |
| `signup_attribution` | count | 8 |
| `funnel_events` | count | 14 |

---

## Préparation des cas de test

| Cas | Préparation requise | Méthode retenue |
|---|---|---|
| A — Owner-mappé | Destination active sur owner | INSERT webhook `T810E1-proof-webhook` (httpbin.org) sur `keybuzz-consulting-mo9y479d` |
| B — Legacy | Aucune | Tenant `proof-no-owner-t810b-mocqwkvo` déjà sans owner ni destination |
| C — Owner sans destination | Désactiver destination Cas A | UPDATE `is_active = false` sur `T810E1-proof-webhook` après Cas A |

Destination de test créée : `d9f62395-4404-4498-99a7-27111264b6e9` (webhook, active, sur owner).

---

## Validation owner-mappé (Cas A)

### Appel

```
emitOutboundConversion('StartTrial', 'proof-owner-valid-t8-mocqwjk7', {
  stripe_subscription_id: 'sub_t810e1_cas_a_proof',
  status: 'trialing', plan: 'PRO', billing_cycle: 'monthly'
}, { amount: 0, currency: 'EUR' })
```

### Logs runtime

```
[OutboundConv] Owner-aware routing: runtime=proof-owner-valid-t8-mocqwjk7 -> owner=keybuzz-consulting-mo9y479d
[OutboundConv] StartTrial sent to T810E1-proof-webhook: HTTP 200 (attempt 1)
```

### Preuves durables en DB

**`conversion_events`** (preuve durable — conservée) :

```json
{
  "event_id": "conv_proof-owner-valid-t8-mocqwjk7_StartTrial_sub_t810e1_cas_a_proof",
  "tenant_id": "proof-owner-valid-t8-mocqwjk7",
  "event_name": "StartTrial",
  "status": "sent",
  "created_at": "2026-04-24T13:52:38.041Z"
}
```

**`outbound_conversion_delivery_logs`** (preuve durable — conservée) :

```json
{
  "destination_id": "d9f62395-4404-4498-99a7-27111264b6e9",
  "event_name": "StartTrial",
  "event_id": "conv_proof-owner-valid-t8-mocqwjk7_StartTrial_sub_t810e1_cas_a_proof",
  "status": "delivered",
  "http_status": 200,
  "delivered_at": "2026-04-24T13:52:38.711Z",
  "dest_tenant": "keybuzz-consulting-mo9y479d",
  "dest_name": "T810E1-proof-webhook"
}
```

### Tableau de preuve

| Point vérifié | Attendu | Résultat |
|---|---|---|
| `conversion_events.tenant_id` | `proof-owner-valid-t8-mocqwjk7` (runtime) | `proof-owner-valid-t8-mocqwjk7` — **OK** |
| Tenant de lookup destination | `keybuzz-consulting-mo9y479d` (owner) | `keybuzz-consulting-mo9y479d` — **OK** |
| Destination trouvée | `T810E1-proof-webhook` sur owner | `d9f62395-...` — **OK** |
| Delivery status | `delivered` | `delivered` (HTTP 200) — **OK** |
| Preuve durable en DB | Oui | `conversion_events` + `delivery_logs` persistés — **OK** |

---

## Validation legacy (Cas B)

### Appel

```
emitOutboundConversion('StartTrial', 'proof-no-owner-t810b-mocqwkvo', {
  stripe_subscription_id: 'sub_t810e1_cas_b_legacy', ...
})
```

### Logs runtime

```
[OutboundConv] No destinations for proof-no-owner-t810b-mocqwkvo, skipping StartTrial
```

### Preuves durables en DB

- `conversion_events` : **vide** (correct — 0 destinations = skip avant insertion)
- `delivery_logs` : **vide** (correct — aucune delivery)

### Tableau de preuve

| Point vérifié | Attendu | Résultat |
|---|---|---|
| `marketing_owner_tenant_id` | `null` | `null` — **OK** |
| Lookup destination tenant | `proof-no-owner-t810b-mocqwkvo` (runtime) | `proof-no-owner-t810b-mocqwkvo` — **OK** |
| Destinations trouvées | 0 | 0 — **OK** |
| Skip propre | Oui | `skipping StartTrial` — **OK** |
| Aucun routing owner parasite | Oui | Log confirme lookup sur le tenant runtime seul — **OK** |

---

## Validation owner sans destination (Cas C)

### Préparation

Destination `T810E1-proof-webhook` désactivée : `UPDATE is_active = false`. Confirmé 0 destinations actives sur le owner.

### Appel

```
emitOutboundConversion('StartTrial', 'proof-owner-valid-t8-mocqwjk7', {
  stripe_subscription_id: 'sub_t810e1_cas_c_no_dest', ...
})
```

### Logs runtime

```
[OutboundConv] Owner-aware routing: runtime=proof-owner-valid-t8-mocqwjk7 -> owner=keybuzz-consulting-mo9y479d
[OutboundConv] No destinations for keybuzz-consulting-mo9y479d (owner of proof-owner-valid-t8-mocqwjk7), skipping StartTrial
```

### Preuves durables en DB

- `conversion_events` : **vide** (correct — 0 destinations = skip)
- `delivery_logs` : **vide** (correct — aucune delivery)

### Tableau de preuve

| Point vérifié | Attendu | Résultat |
|---|---|---|
| Owner résolu | `keybuzz-consulting-mo9y479d` | `keybuzz-consulting-mo9y479d` — **OK** |
| Destinations trouvées | 0 | 0 — **OK** |
| Crash | Non | Non — **OK** |
| Skip propre | Oui | `skipping StartTrial` — **OK** |
| Log mentionne owner ET enfant | Oui | `(owner of proof-owner-valid-t8-mocqwjk7)` — **OK** |

---

## Preuves durables DB / Logs — Récapitulatif

### Cas A — Owner-mappé (CONSERVÉ EN DB)

| Champ | Valeur |
|---|---|
| Tenant runtime | `proof-owner-valid-t8-mocqwjk7` |
| Owner tenant | `keybuzz-consulting-mo9y479d` |
| Event name | `StartTrial` |
| Event ID | `conv_proof-owner-valid-t8-mocqwjk7_StartTrial_sub_t810e1_cas_a_proof` |
| Destination tenant | `keybuzz-consulting-mo9y479d` (owner) |
| Destination ID | `d9f62395-4404-4498-99a7-27111264b6e9` |
| Destination nom | `T810E1-proof-webhook` |
| Delivery status | `delivered` |
| HTTP status | 200 |
| Timestamp | `2026-04-24T13:52:38.711Z` |

### Cas B — Legacy (SKIP documenté)

| Champ | Valeur |
|---|---|
| Tenant runtime | `proof-no-owner-t810b-mocqwkvo` |
| Owner | `null` |
| Destination tenant | `proof-no-owner-t810b-mocqwkvo` (runtime, legacy) |
| Destinations trouvées | 0 |
| Delivery | Aucune — skip propre |

### Cas C — Owner sans destination (SKIP documenté)

| Champ | Valeur |
|---|---|
| Tenant runtime | `proof-owner-valid-t8-mocqwjk7` |
| Owner tenant | `keybuzz-consulting-mo9y479d` |
| Destinations actives sur owner | 0 |
| Delivery | Aucune — skip propre |
| Crash | Aucun |

---

## Non-régression

| Sujet | Attendu | Résultat |
|---|---|---|
| `conversion_events` | 1 (preuve Cas A conservée) | 1 — **OK** |
| `billing_subscriptions` | 16 | 16 — **OK** |
| `signup_attribution` | 8 | 8 — **OK** |
| `funnel_events` | 14 | 14 — **OK** |
| Owner mapping | Inchangé | `proof-owner→KBC`, `proof-no-owner→null` — **OK** |
| API PROD | `v3.5.111-activation-completed-model-prod` | Inchangée — **OK** |
| Client DEV | `v3.5.112-marketing-owner-mapping-foundation-dev` | Inchangé — **OK** |
| Client PROD | `v3.5.110-post-checkout-activation-foundation-prod` | Inchangé — **OK** |
| Admin DEV/PROD | Non modifiés | Inchangés — **OK** |

---

## Conclusion actionnable

**Cas A — GO ferme.**

Les 3 cas de validation sont prouvés durablement :

1. **Owner-mappé** : le routing résout `marketing_owner_tenant_id`, le lookup des destinations cible le owner, la delivery est enregistrée en DB avec le tenant de destination = owner. Preuve durable persistée dans `conversion_events` + `delivery_logs`.

2. **Legacy** : le fallback fonctionne — pas de redirection owner parasite, lookup sur le tenant runtime, skip propre quand 0 destinations.

3. **Owner sans destination** : le routing résout bien le owner, constate 0 destinations actives, skip propre sans crash.

La zone d'ombre identifiée au début de cette phase est levée. La prochaine phase possible est **T8.10C** (promotion PROD) ou une phase de configuration des destinations Meta CAPI sur le owner DEV/PROD.

---

## Modifications effectuées (données DEV de validation uniquement)

| Action | Détail | Durable |
|---|---|---|
| INSERT destination test | `T810E1-proof-webhook` sur owner (webhook httpbin.org) | Oui (désactivée) |
| INSERT conversion_events | Cas A — `sub_t810e1_cas_a_proof` | Oui (conservé comme preuve) |
| INSERT delivery_logs | Cas A — delivery sur destination owner | Oui (conservé comme preuve) |
| UPDATE destination | Désactivation `T810E1-proof-webhook` pour Cas C | Oui |

Aucune modification de code, de runtime, de build, ni de deploy.

---

## PROD inchangée

**Oui** — aucun build, aucun deploy, aucune migration, aucune modification cluster/PROD.

---

*Rapport généré le 24 avril 2026*
*Phase : PH-T8.10E.1-OUTBOUND-ROUTING-OWNER-AWARE-RUNTIME-TRUTH-VALIDATION-01*
*Chemin : `keybuzz-infra/docs/PH-T8.10E.1-OUTBOUND-ROUTING-OWNER-AWARE-RUNTIME-TRUTH-VALIDATION-01.md`*
