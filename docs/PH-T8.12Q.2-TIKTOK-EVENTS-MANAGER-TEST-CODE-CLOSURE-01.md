# PH-T8.12Q.2 — TikTok Events Manager Test Code Closure

> Date : 2026-05-01
> Environnement : PROD
> Type : validation visuelle TikTok Events Manager avec test_event_code
> Verdict : **GO CLOSED**

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

**Statut : VALIDE PAR LUDOVIC**

Preuve visuelle (capture TikTok Events Manager) :

- [x] Pixel `Pixel_KeyBuzz` — ID `D7PT12JC77U44OJIPC10`
- [x] Business Center owner : `KeyBuzz Consulting`
- [x] Onglet Test Events — Status : Connected
- [x] Event `View content` (code `ViewContent`) visible
- [x] Connection method : `Server`
- [x] Received time : `2026-05-01 11:13:53 UTC+00:00`
- [x] Setup method : `Custom code`
- [x] event_id : `test_keybuzz-consulting-mo9zndlk_1777634033523` — confirme
- [x] contents : `[{"content_category":"subscription","content_name":"KeyBuzz test"}]`
- [x] hashed_email : present (SHA-256, non recopie)
- [x] Aucun faux StartTrial / Purchase / CompletePayment

### Avertissement TikTok

TikTok signale : `Content ID is missing in your events` — le parametre `content_id` est absent du payload ViewContent. Cet avertissement est non bloquant pour la livraison mais a auditer pour la qualite du signal.

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
| API (principal) | `v3.5.128-trial-autopilot-assisted-prod` | NON |
| API (outbound-worker) | `v3.5.165-escalation-flow-prod` | NON |

---

## Gaps

| # | Gap | Severite | Description |
|---|-----|----------|-------------|
| G1 | TikTok payload quality — `content_id` manquant | P2 | TikTok Test Events signale `Content ID is missing in your events` sur ViewContent. Non bloquant pour la livraison. A auditer dans une phase separee avant optimisation scale avancee. |

---

## Verdict

**GO CLOSED**

Le test ViewContent avec `test_event_code=TEST88534` a ete envoye avec succes a TikTok Events API (HTTP 200, tiktok_code 0). Le delivery log confirme la livraison. La verification visuelle dans le TikTok Events Manager a ete validee par Ludovic : event recu, bon pixel, bon Business Center, connection method Server, event_id confirme. Aucun faux event business. Aucun build, aucun deploy.
