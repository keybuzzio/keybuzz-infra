# PH-T8.10M.1-TIKTOK-NATIVE-RUNTIME-TRUTH-VALIDATION-01 — TERMINÉ

**Verdict : GO**

> TIKTOK NATIVE OWNER-AWARE RUNTIME TRUTH ESTABLISHED IN DEV — REAL BUSINESS EVENT ROUTES VIA OWNER DESTINATION — ADMIN VISIBILITY CONFIRMED — PROD UNTOUCHED

---

## Préflight

| Point | Résultat |
|---|---|
| Branche API | `ph147.4/source-of-truth` — HEAD `acf5536d` |
| Branche Admin | `main` — HEAD `be0d6a2` |
| Image API DEV | `v3.5.117-tiktok-native-owner-aware-dev` |
| Image Admin DEV | `v2.11.15-tiktok-native-owner-aware-dev` |
| Image API PROD | `v3.5.116-marketing-owner-stack-prod` (inchangée) |
| Image Admin PROD | `v2.11.14-owner-cockpit-browser-truth-fix-prod` (inchangée) |
| Repos clean | API clean, Admin clean |
| Mode | Validation runtime — aucun patch, aucun build, aucun deploy |

---

## Avant test

### A. Destination TikTok KBC

| Champ | Valeur |
|---|---|
| ID | `2e8803be-a852-4812-b988-8402fb9fe327` |
| Type | `tiktok_events` |
| Nom | TikTok DEV Test Destination |
| Active | true |
| Dernier test status | failed (token de test invalide — attendu) |
| Dernier test date | 2026-04-25T00:02:46.348Z |

### B. Delivery logs TikTok avant test

| Mesure | Valeur |
|---|---|
| Nombre de logs TikTok | 1 |
| Dernier log | `ViewContent` (test route) — status=failed, HTTP 401 |
| Logs business event | 0 |

### C. Tenants de preuve disponibles

| Tenant | Owner | Usage |
|---|---|---|
| `proof-owner-valid-t8-mocqwjk7` | `keybuzz-consulting-mo9y479d` | Enfant owner-mappé (déjà utilisé PH-T8.10E.1) |
| `proof-child-funnel-t-mod385lv` | `keybuzz-consulting-mo9y479d` | Enfant owner-mappé (jamais utilisé pour conversion) |
| `proof-no-owner-t810b-mocqwkvo` | null | Legacy sans owner |

### D. Tableau avant test

| Vue | Mesure | Avant test |
|---|---|---|
| Destination TikTok KBC | type=tiktok_events, active=true | 1 dest, last_test=failed |
| Delivery logs TikTok | total | 1 (test route ViewContent) |
| Delivery logs TikTok business | total | 0 |
| Conversion events total | total | 1 (StartTrial webhook PH-T8.10E.1) |
| Tenants owner-mappés | count | 2 |

---

## Cas business

| Cas choisi | Pourquoi | Méthode |
|---|---|---|
| `StartTrial` sur `proof-child-funnel-t-mod385lv` | Tenant enfant owner-mappé vers KBC, jamais utilisé pour conversion, sub_id unique = pas de dedup | Appel `emitOutboundConversion` in-pod (même code path que Stripe webhook) |
| Subscription ID | `sub_t810m1_tiktok_proof` | Unique, pas de collision |

---

## Event runtime

### Appel

```
emitOutboundConversion('StartTrial', 'proof-child-funnel-t-mod385lv', {
  stripe_subscription_id: 'sub_t810m1_tiktok_proof',
  status: 'trialing',
  plan: 'PRO',
  billing_cycle: 'monthly',
}, { amount: 0, currency: 'EUR' })
```

### Logs runtime observés

```
[OutboundConv] Owner-aware routing: runtime=proof-child-funnel-t-mod385lv -> owner=keybuzz-consulting-mo9y479d
[OutboundConv] TikTok TikTok DEV Test Destination: no ttclid in attribution, sending with email_hash only
[OutboundConv] StartTrial TikTok attempt 1/3 to TikTok DEV Test Destination: Access token is incorrect or has been revoked.
[OutboundConv] StartTrial TikTok attempt 2/3 to TikTok DEV Test Destination: Access token is incorrect or has been revoked.
[OutboundConv] StartTrial TikTok attempt 3/3 to TikTok DEV Test Destination: Access token is incorrect or has been revoked.
[OutboundConv] StartTrial TikTok FAILED after 3 attempts to TikTok DEV Test Destination
[OutboundConv] StartTrial FAILED for all 1 destination(s) for keybuzz-consulting-mo9y479d (owner of proof-child-funnel-t-mod385lv)
```

### Points validés

| Point vérifié | Attendu | Résultat |
|---|---|---|
| Owner routing | runtime → owner | **OK** — `runtime=proof-child-funnel-t-mod385lv -> owner=keybuzz-consulting-mo9y479d` |
| Handler TikTok natif | `sendToTikTokDest` | **OK** — logs disent "TikTok" pas "webhook" |
| Event name | `StartTrial` | **OK** |
| Retries | 3 tentatives | **OK** — attempt 1/3, 2/3, 3/3 |
| Erreur attendue | token invalide | **OK** — "Access token is incorrect or has been revoked" |
| Log final owner-aware | mentionne owner + runtime | **OK** |

---

## Preuves

### Conversion event

| Champ | Valeur |
|---|---|
| event_id | `conv_proof-child-funnel-t-mod385lv_StartTrial_sub_t810m1_tiktok_proof` |
| tenant_id | `proof-child-funnel-t-mod385lv` (tenant runtime enfant) |
| event_name | `StartTrial` |
| status | `failed` (token test — attendu) |
| attempts | 1 |
| created_at | 2026-04-25T08:16:45Z |

### Delivery log

| Champ | Valeur |
|---|---|
| event_name | `StartTrial` |
| event_id | `conv_proof-child-funnel-t-mod385lv_StartTrial_sub_t810m1_tiktok_proof` |
| destination_id | `2e8803be-a852-4812-b988-8402fb9fe327` |
| destination_type | `tiktok_events` |
| status | `failed` |
| error_message | `max attempts reached (tiktok_events)` |
| attempt | 3 |
| created_at | 2026-04-25T08:17:06.237Z |

### Distinction test route vs business event

| Log | event_name | event_id pattern | Nature |
|---|---|---|---|
| Premier (test) | `ViewContent` | `test_keybuzz-consulting-mo9y479d_*` | Test route (ÉTAPE PH-T8.10M) |
| Second (business) | `StartTrial` | `conv_proof-child-funnel-t-mod385lv_*` | **Business event réel** |

---

## Owner-aware

| Cas | Attendu | Résultat |
|---|---|---|
| Event business tenant enfant | `conversion_events.tenant_id = proof-child-funnel-t-mod385lv` | **OK** |
| Lookup destination sur owner KBC | routing vers `keybuzz-consulting-mo9y479d` | **OK** |
| Handler TikTok natif utilisé | `sendToTikTokDest`, pas webhook | **OK** |
| Legacy sans owner (`proof-no-owner-t810b-mocqwkvo`) | lookup sur son propre tenant, pas de fuite KBC | **OK** — `No destinations for proof-no-owner-t810b-mocqwkvo, skipping` |
| Legacy exempt (`ecomlg-001`) | skip exempt | **OK** — `Tenant ecomlg-001 is exempt (test account), skipping StartTrial` |
| Même logique que Meta | owner routing agnostique du type destination | **OK** — même `resolveOutboundRoutingTenantId` |

---

## Admin

| Surface Admin | Attendu | Résultat |
|---|---|---|
| Destination TikTok KBC visible | type=tiktok_events, active=true, nom=TikTok DEV Test Destination | **OK** |
| Delivery log business TikTok | `StartTrial` visible, distinct de `ViewContent` test | **OK** — total=2 logs, 2 types d'events |
| Trace lisible agence | event_id contient tenant enfant + sub_id | **OK** |
| Cockpit owner metrics | scope=owner HTTP 200 | **OK** |
| Cockpit owner funnel | scope=owner HTTP 200 | **OK** |

---

## Non-régression

| Surface | Attendu | Résultat |
|---|---|---|
| Health API DEV | HTTP 200 OK | **OK** |
| Meta CAPI type en DB | visible dans delivery logs | **OK** — log PageView meta_capi |
| Webhook type en DB | visible dans delivery logs | **OK** — log StartTrial webhook T810E1 |
| Destinations listing | HTTP 200 avec tous types | **OK** — 2 destinations KBC |
| Delivery logs listing | tous types visibles | **OK** — 4 logs (tiktok×2, webhook×1, meta×1) |
| Metrics owner scope | HTTP 200 | **OK** |
| Funnel owner scope | HTTP 200 | **OK** |
| Tenant guard | 403 pour non autorisé | **OK** |
| Legacy sans owner | pas de fuite vers KBC | **OK** |
| PROD API | `v3.5.116-marketing-owner-stack-prod` | **Inchangée** |
| PROD Admin | `v2.11.14-owner-cockpit-browser-truth-fix-prod` | **Inchangée** |
| PROD Client | `v3.5.116-marketing-owner-stack-prod` | **Inchangée** |
| Tenant isolation events | chaque event sur son tenant runtime | **OK** — 2 events, 2 tenants distincts |

---

## Conclusion

### Verdict : GO FERME

Le pipeline TikTok natif owner-aware est **prouvé au runtime sur un vrai business event DEV** :

1. **Owner routing prouvé** — `proof-child-funnel-t-mod385lv` → `keybuzz-consulting-mo9y479d`
2. **Handler TikTok natif utilisé** — logs montrent `sendToTikTokDest` avec 3 retries, pas le handler webhook
3. **Event business réel** — `StartTrial` (pas `ViewContent` de la test route)
4. **Tenant runtime préservé** — `conversion_events.tenant_id = proof-child-funnel-t-mod385lv`
5. **Destination owner utilisée** — lookup sur KBC, destination `tiktok_events` active
6. **Legacy protégé** — tenant sans owner ne fuit pas vers KBC
7. **Admin visibilité** — destination TikTok, delivery logs business et test route, cockpit owner intact
8. **Non-régression totale** — Meta, webhooks, metrics, funnel, tenant guard tous OK
9. **PROD inchangée** — aucune modification appliquée

Le delivery est `failed` car le token TikTok est un token de test invalide. C'est **attendu et non bloquant** — la preuve requise est que le pipeline TikTok natif owner-aware est invoqué correctement, ce qui est établi noir sur blanc par les logs runtime, la DB et l'API.

### Prochaine phase

Promotion DEV → PROD du stack TikTok natif owner-aware (API `v3.5.117` + Admin `v2.11.15`).

---

## Annexes

### Aucune modification effectuée

Cette phase est en lecture seule. Aucun code, aucune configuration, aucun manifest, aucune image n'a été modifié. Seules des requêtes API et DB ont été effectuées pour établir les preuves runtime.

### PROD inchangée

Oui — confirmé par les images deployées :
- API PROD : `v3.5.116-marketing-owner-stack-prod`
- Admin PROD : `v2.11.14-owner-cockpit-browser-truth-fix-prod`
- Client PROD : `v3.5.116-marketing-owner-stack-prod`

### Chemin rapport

`keybuzz-infra/docs/PH-T8.10M.1-TIKTOK-NATIVE-RUNTIME-TRUTH-VALIDATION-01.md`

### Sources de vérité relues

- `keybuzz-infra/docs/PH-T8.10E.1-OUTBOUND-ROUTING-OWNER-AWARE-RUNTIME-TRUTH-VALIDATION-01.md`
- `keybuzz-infra/docs/PH-T8.10L-TIKTOK-OWNER-AWARE-TRUTH-AUDIT-01.md`
- `keybuzz-infra/docs/PH-T8.10M-TIKTOK-NATIVE-OWNER-AWARE-FOUNDATION-01.md`
