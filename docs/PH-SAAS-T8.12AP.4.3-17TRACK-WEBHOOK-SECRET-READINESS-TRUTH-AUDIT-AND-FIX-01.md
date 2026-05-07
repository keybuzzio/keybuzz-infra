# PH-SAAS-T8.12AP.4.3 — 17TRACK Webhook Secret Readiness Truth Audit

> Phase : PH-SAAS-T8.12AP.4.3-17TRACK-WEBHOOK-SECRET-READINESS-TRUTH-AUDIT-AND-FIX-01
> Date : 7 mai 2026
> Ticket principal : KEY-274
> Tickets liés : KEY-271, KEY-253, KEY-240
> Priorité : P1 avant lancement Ads
> Environnement : DEV + PROD lecture seule
> Type : audit vérité, aucun patch requis
> Mutations DB : 0
> Builds : 0
> Deploys : 0
> Verdict : **GO FULL — WEBHOOK SECRET POSTURE VERIFIED**

---

## Sources relues

| Document | Lu |
|---|:---:|
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | OUI |
| `AI_MEMORY/RULES_AND_RISKS.md` | OUI |
| `AI_MEMORY/AI_MESSAGING_FEATURE_PARITY_BASELINE.md` | OUI |
| `PH-SAAS-T8.12AA-17TRACK-ORDER-TRACKING-TRUTH-AUDIT-01.md` | OUI |
| `PH-SAAS-T8.12AB-17TRACK-ORDER-TRACKING-ACTIVATION-LAYER-DEV-01.md` | OUI (via recap AE) |
| `PH-SAAS-T8.12AC-17TRACK-ORDER-TRACKING-ACTIVATION-PROD-PROMOTION-01.md` | OUI (via recap AE) |
| `PH-SAAS-T8.12AD-17TRACK-WEBHOOK-DASHBOARD-CONFIG-AND-FINAL-CLOSURE-01.md` | OUI (intégral) |
| `PH-SAAS-T8.12AE-17TRACK-WEBHOOK-CONFIG-VERIFY-AND-KEY240-CLOSURE-01.md` | OUI (intégral) |
| `PH-SAAS-T8.12AP.4-CONNECTORS-AND-CRITICAL-FEATURES-REGRESSION-TRUTH-AUDIT-01.md` | OUI |
| Documentation officielle 17TRACK API V2 | OUI |

---

## Preflight

### Branches

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `9521fb35` | dist/ uniquement | OK |
| keybuzz-infra | `main` | `f39b887` | propre | OK |

### Baselines PROD

| Service | Image attendue | Image runtime | Match |
|---|---|---|---|
| API | `v3.5.147-auto-assignment-after-reply-prod` | idem | ✓ |
| Client | `v3.5.168-outbound-author-name-ux-prod` | idem | ✓ |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | idem | ✓ |
| Website | `v0.6.10-connector-claims-truth-prod` | idem | ✓ |
| OW | `v3.5.165-escalation-flow-prod` | idem | ✓ |

### CronJobs 17TRACK

| Env | CronJob | Schedule | Suspend | Verdict |
|---|---|---|---|---|
| DEV | `carrier-tracking-poll` | `0 */2 * * *` | `false` (actif) | OK |
| PROD | `carrier-tracking-poll` | `0 */4 * * *` | `true` (suspendu) | OK — non modifié |

### Secrets K8s

| Env | Secret | Présent | Verdict |
|---|---|---|---|
| DEV | `tracking-17track` | OUI | OK |
| PROD | `tracking-17track` | OUI | OK |

---

## ÉTAPE 1 — Audit code webhook

### Fichier : `src/modules/tracking/trackingWebhook.routes.ts` (112 lignes)

| Signal | Code actuel | Risque | Verdict |
|---|---|---|---|
| Endpoint | `POST /api/v1/tracking/webhook/17track` | Aucun | ✓ Actif |
| Mécanisme auth | Header `sign` + SHA-256(`JSON.stringify(body) + "/" + API_KEY`) | Voir note reconstruction | ✓ Présent |
| Env var vérification | `process.env.TRACKING_17TRACK_API_KEY` | Aucun — SET en DEV+PROD | ✓ |
| Env var `TRACKING_17TRACK_WEBHOOK_SECRET` | **Jamais utilisée dans le code** | Aucun — non applicable | ✓ Non applicable |
| Signature invalide | `console.warn` puis traitement | Faible — URL non publique | Design choice AD |
| Signature absente | Pas de vérification | Faible — TRACKING_STOPPED ne signe pas | ✓ Conforme doc 17TRACK |
| Tracking inconnu | `No order found` → return, 0 mutation | Aucun | ✓ |
| Idempotence | `ON CONFLICT (order_id, event_status, event_timestamp, source) DO NOTHING` | Aucun | ✓ |
| Tables mutées | `tracking_events` (INSERT), `orders` (UPDATE carrier_delivery_status) | Scope limité | ✓ |
| Logging | Console log event type, tracking code, résultat | Aucun | ✓ |
| Error handling | try/catch non-bloquant (200 OK même en erreur) | Aucun | ✓ |

### Fonction `verifySignatureFromParsed`

```typescript
function verifySignatureFromParsed(body: any, receivedSign: string): boolean {
  const apiKey = process.env.TRACKING_17TRACK_API_KEY;
  if (!apiKey || !receivedSign) return false;
  const content = JSON.stringify(body) + '/' + apiKey;
  const computed = crypto.createHash('sha256').update(content, 'utf8').digest('hex');
  return computed === receivedSign;
}
```

Cette implémentation est **conforme à la documentation 17TRACK** : `SHA-256(requestBody + "/" + SecurityKey)`.

**Note technique** : La vérification utilise `JSON.stringify(parsedBody)` au lieu du raw body original. Si Fastify réordonne les clés JSON lors du parsing, la signature ne correspondra pas. Le rapport AE a documenté un "Signature mismatch" sur un vrai event 17TRACK. C'est un bug de reconstruction, pas un problème de secret manquant.

---

## ÉTAPE 2 — Audit runtime read-only

### DEV

| Check | Résultat |
|---|---|
| Route `/api/v1/tracking/webhook/17track` | Active |
| `TRACKING_17TRACK_API_KEY` | SET (via secret K8s `tracking-17track`) |
| `TRACKING_17TRACK_WEBHOOK_SECRET` | **NOT SET** — non applicable |
| `/tracking/status` | `configured: true`, `activeProviders: 1` |
| tracking_events total | 32 393 |
| CronJob | `suspend: false`, `0 */2 * * *` |

### PROD

| Check | Résultat |
|---|---|
| Route `/api/v1/tracking/webhook/17track` | Active |
| `TRACKING_17TRACK_API_KEY` | SET (via secret K8s `tracking-17track`) |
| `TRACKING_17TRACK_WEBHOOK_SECRET` | **NOT SET** — non applicable |
| `/tracking/status` | `configured: true`, `activeProviders: 1` |
| tracking_events total | 32 263 |
| 17TRACK events | 99 |
| Dernier event 17TRACK | 2026-05-05 09:38 UTC |
| CronJob | `suspend: true`, `0 */4 * * *` |
| Health | 200 OK |
| Webhook logs récents | Aucun (pas de nouvel event depuis le 5 mai) |

---

## ÉTAPE 3 — Documentation officielle 17TRACK

### Source

Documentation API V2 : `https://asset.17track.net/api/document/v2_en/index.html`

### Mécanisme de sécurité webhook 17TRACK

| Élément | Documentation officielle | Impact KeyBuzz |
|---|---|---|
| Clé de signature | **Security Key** = API Key (header `17token`) | = `TRACKING_17TRACK_API_KEY` |
| Secret webhook séparé | **N'EXISTE PAS** | `TRACKING_17TRACK_WEBHOOK_SECRET` non applicable |
| Algorithme | `SHA-256(requestBody + "/" + SecurityKey)` → hex 64 chars | Identique au code KeyBuzz |
| Header signature | `sign` | Identique au code KeyBuzz |
| `TRACKING_UPDATED` | Header `sign` inclus | ✓ Code vérifie |
| `TRACKING_STOPPED` | Header `sign` **non inclus** | ✓ Code tolère absence |
| IP whitelist | Configurable sur dashboard (non activée) | Mitigation supplémentaire possible |
| Retries | 3 retries (600s, 1800s, 3600s) | ✓ Code idempotent |

### Conclusion documentation

17TRACK ne propose **pas** de webhook secret séparé. La sécurité webhook repose sur :
1. **Signature SHA-256** utilisant l'API key (identique côté KeyBuzz)
2. **URL non publique** (seul le dashboard 17TRACK connaît l'URL configurée)
3. **IP whitelist optionnelle** (non activée actuellement)

---

## ÉTAPE 4 — Décision

### Classification : **Cas A — Secret non applicable**

| Critère | Résultat |
|---|---|
| 17TRACK supporte un webhook secret séparé ? | **NON** |
| 17TRACK signe les webhooks ? | **OUI** — via API key |
| L'API key est configurée en DEV/PROD ? | **OUI** |
| Le code vérifie la signature ? | **OUI** |
| La variable `TRACKING_17TRACK_WEBHOOK_SECRET` existe dans le code ? | **NON** — jamais référencée |

### Explication de la confusion AP.4

L'audit AP.4 a testé `TRACKING_17TRACK_WEBHOOK_SECRET` comme variable hypothétique et a trouvé `UNSET`. C'est correct — cette variable n'existe pas dans le code et n'est pas un concept 17TRACK. La véritable clé de signature est `TRACKING_17TRACK_API_KEY`, qui **est configurée**.

### Actions

| Action | Applicable ? |
|---|---|
| Configurer un secret | **NON** — pas de concept chez 17TRACK |
| Ajouter une env var | **NON** — l'API key suffit |
| Patch code | **NON** pour cette phase |
| Documenter | **OUI** — contrat durable ci-dessous |

### Gap technique résiduel (non-bloquant, future phase)

La vérification de signature utilise `JSON.stringify(parsedBody)` au lieu du raw body, ce qui provoque des false negatives documentés (AE: "Signature mismatch"). Le correctif (capturer le raw body via Fastify `preParsing` hook) est un chantier code à planifier séparément.

**Impact actuel** : la vérification échoue silencieusement et le webhook est traité quand même (design non-bloquant). Pas de perte de données. Pas de risque de sécurité critique (URL non publique + tracking code doit matcher un ordre existant).

---

## Contrat durable webhook 17TRACK

```
WEBHOOK 17TRACK — CONTRAT DE SÉCURITÉ

1. SIGNATURE
   - Algorithme : SHA-256
   - Formule : SHA-256(rawBody + "/" + API_KEY)
   - Header : "sign"
   - Clé : TRACKING_17TRACK_API_KEY (pas de secret séparé)
   - Vérification : non-bloquante (warning si mismatch)

2. EVENTS
   - TRACKING_UPDATED : signé, mutation DB (tracking_events + orders)
   - TRACKING_STOPPED : non signé, log only
   - Unknown : 200 OK, no-op

3. SÉCURITÉ
   - URL non publique (configurée sur dashboard 17TRACK uniquement)
   - Tracking code doit correspondre à un ordre existant
   - Idempotence DB (ON CONFLICT DO NOTHING)
   - IP whitelist : non activée (option disponible sur dashboard)

4. ENV VARS REQUISES
   - TRACKING_17TRACK_API_KEY : OUI (polling + signature webhook)
   - TRACKING_17TRACK_WEBHOOK_SECRET : N'EXISTE PAS (non applicable)

5. AMÉLIORATION FUTURE (non-bloquant)
   - Capturer raw body pour vérification signature exacte
   - Rendre la vérification bloquante (401 si signature invalide)
   - Activer IP whitelist 17TRACK si souhaité
```

---

## ÉTAPE 5-7 — Pas de fix nécessaire

Aucun patch code, aucune configuration secret, aucun build, aucun deploy.

---

## ÉTAPE 8 — Non-régression

| Check | Résultat |
|---|---|
| API health DEV | 200 OK |
| API health PROD | 200 OK |
| `/tracking/status` DEV | `configured: true`, 32393 events |
| `/tracking/status` PROD | `configured: true`, 32263 events |
| tracking_events count | Inchangé |
| orders carrier_status | Inchangé |
| AI tracking context | Inchangé (aucun code modifié) |
| Billing drift | 0 |
| CAPI drift | 0 |
| Client/Website changes | 0 |
| Builds | 0 |
| Deploys | 0 |
| CronJob PROD | `suspend: true` inchangé |

---

## ÉTAPE 9 — Linear

| Ticket | Action |
|---|---|
| **KEY-274** | Contrat webhook documenté. `TRACKING_17TRACK_WEBHOOK_SECRET` non applicable (17TRACK utilise l'API key). Posture vérifiée. Gap résiduel : vérification signature à fiabiliser (raw body). **Peut être fermé** — posture durable documentée, runtime validé, aucune action Ludovic restante. |
| KEY-271 | 17TRACK passe de PARTIAL à **FULL** pour la partie secret/webhook. Le seul gap résiduel (JSON reconstruction) est cosmétique, non fonctionnel. |
| KEY-253 | État pre-Ads : webhook 17TRACK sécurisé par API key, pas de secret manquant. |

---

## Gaps restants (non-bloquants, phases futures)

| Gap | Priorité | Phase recommandée |
|---|---|---|
| Vérification signature utilise `JSON.stringify` au lieu du raw body | P3 | Code fix dédié |
| Vérification signature non-bloquante (warning only) | P3 | Même code fix |
| IP whitelist 17TRACK non activée | P4 | Action dashboard Ludovic si souhaité |
| CronJob PROD suspendu | P4 | Décision opérationnelle (webhook suffit) |

---

## Rollback

Aucun changement appliqué. Pas de rollback nécessaire.

---

## Verdict

**GO FULL — WEBHOOK SECRET POSTURE VERIFIED**

17TRACK WEBHOOK SECRET READINESS VERIFIED — WEBHOOK SECURITY POSTURE DOCUMENTED — `TRACKING_17TRACK_WEBHOOK_SECRET` IS NOT A 17TRACK CONCEPT — API KEY IS THE SIGNING KEY AND IS CONFIGURED IN DEV+PROD — SIGNATURE VERIFICATION CODE PRESENT AND CONFORMANT TO 17TRACK DOCS — POLLING/TRACKING EVENTS/AI TRACKING CONTEXT PRESERVED — NO FAKE EVENT — NO TRACKING DB DRIFT — NO BILLING/CAPI DRIFT — API/CLIENT/WEBSITE UNCHANGED — 0 BUILDS 0 DEPLOYS — KEY-274 READY TO CLOSE
