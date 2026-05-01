# PH-T8.12Q.2 — TikTok Events Manager Test Code Closure

> Date : 2026-05-01
> Environnement : PROD
> Type : validation visuelle TikTok Events Manager avec test_event_code
> Verdict : **GO KEYBUZZ OK / TIKTOK UI PENDING LUDOVIC**

---

## Objectif

Fermer la validation visuelle TikTok Events Manager restee pending apres PH-T8.12Q.1, en utilisant le test code `TEST88534`.

---

## Test effectue

| Element | Valeur |
|---------|--------|
| Destination | `75a3c56a-2508-4fa9-ab12-6b1514951877` |
| Destination type | `tiktok_events` |
| Pixel/Data Source | `D7PT12JC77U44OJIPC10` |
| Tenant | `keybuzz-consulting-mo9zndlk` |
| test_event_code | `TEST88534` |
| Event type envoye | `ViewContent` (safe, pas un business event) |
| Methode | `POST /outbound-conversions/destinations/{id}/test` via curl pod K8s |
| HTTP status API | `200` |
| tiktok_code | `0` (succes) |
| event_id | `test_keybuzz-consulting-mo9zndlk_1777634033523` |
| Timestamp | 2026-05-01 11:13:53 UTC |

### Reponse API brute

```json
{
  "test_result": {
    "status": "success",
    "destination_type": "tiktok_events",
    "http_status": 200,
    "error": null,
    "events_received": null,
    "tiktok_code": 0,
    "event_id": "test_keybuzz-consulting-mo9zndlk_1777634033523",
    "tested_at": "2026-05-01T11:13:53.755Z"
  }
}
```

### Delivery logs (outbound_conversion_delivery_logs)

| Event | HTTP | event_id | Date |
|-------|------|----------|------|
| ViewContent | 200 | `test_keybuzz-consulting-mo9zndlk_1777634033523` | 2026-05-01 11:13:53 UTC |
| ViewContent | 200 | `test_keybuzz-consulting-mo9zndlk_1777587642471` | 2026-04-30 22:20:42 UTC |

---

## Verification TikTok Events Manager

**Statut : PENDING LUDOVIC**

Points a verifier par Ludovic dans le TikTok Events Manager :
- [ ] Onglet Test Events avec code `TEST88534`
- [ ] Event ViewContent visible avec event_id `test_keybuzz-consulting-mo9zndlk_1777634033523`
- [ ] Bon Pixel/Data Source `D7PT12JC77U44OJIPC10`
- [ ] Bon Ad Account `7634494806858252304`
- [ ] Pas de faux StartTrial/Purchase

---

## Controles de securite

| Check | Resultat |
|-------|----------|
| Build effectue | NON |
| Deploy effectue | NON |
| kubectl set/patch/edit | NON |
| Faux StartTrial | NON |
| Faux Purchase | NON |
| Faux CompletePayment | NON |
| Fake spend | NON |
| Secret expose | NON |
| Token dans rapport | NON |
| Modification destination | NON |
| Modification token | NON |

---

## PROD inchangee

| Service | Image PROD | Modifiee |
|---------|-----------|----------|
| Client | `v3.5.144-tiktok-browser-pixel-prod` | NON |
| Website | `v0.6.8-tiktok-browser-pixel-prod` | NON |
| Admin | `v2.11.35-agency-launch-kit-prod` | NON |
| API | `v3.5.165-escalation-flow-prod` | NON |

---

## Verdict

**GO KEYBUZZ OK / TIKTOK UI PENDING LUDOVIC**

Le test ViewContent avec `test_event_code=TEST88534` a ete envoye avec succes a TikTok Events API (HTTP 200, tiktok_code 0). Le delivery log confirme la livraison. Aucun faux event business. Aucun build, aucun deploy.

La verification visuelle dans le TikTok Events Manager (onglet Test Events) reste en attente de validation par Ludovic.
