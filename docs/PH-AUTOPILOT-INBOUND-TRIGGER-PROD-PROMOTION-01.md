# PH-AUTOPILOT-INBOUND-TRIGGER-PROD-PROMOTION-01 — TERMINÉ

**Verdict : GO**

**Date** : 2026-04-20
**Environnement** : PROD
**Type** : Promotion PROD du recovery inbound Autopilot

---

## Préflight

| Element | Valeur |
|---|---|
| Branche | `ph147.4/source-of-truth` |
| HEAD commit | `4f60aad5` |
| Repo clean | OUI (untracked `.bak` uniquement) |
| Image PROD avant | `ghcr.io/keybuzzio/keybuzz-api:v3.5.88-test-control-safe-prod` |
| Image DEV validée | `ghcr.io/keybuzzio/keybuzz-api:v3.5.89-autopilot-inbound-trigger-dev` |
| Manifest PROD avant | `v3.5.88-test-control-safe-prod` |
| Commit `4f60aad5` présent | OUI — confirmé sur `ph147.4/source-of-truth` |
| PROD ne contenait pas le fix | OUI — confirmé `v3.5.88` sans `evaluateAndExecute` dans inbound |

---

## Source

| Element | Valeur |
|---|---|
| Commit | `4f60aad5` |
| Message | `PH-AUTOPILOT-INBOUND-TRIGGER-RECOVERY-01: add evaluateAndExecute() fire-and-forget trigger after inbound message processing` |
| Fichier | `src/modules/inbound/routes.ts` |
| Changement | +1 import, +2 blocs fire-and-forget (13 lignes ajoutées, 0 supprimées) |

### Vérification source (3 points)

| Point | Résultat |
|---|---|
| Import `evaluateAndExecute` (ligne 2) | **OUI** — `import { evaluateAndExecute } from '../autopilot/engine';` |
| Injection `/inbound/email` (ligne 290) | **OUI** — `evaluateAndExecute(conversationId, body.tenantId, 'inbound')` |
| Injection `/inbound/amazon-forward` (ligne 577) | **OUI** — `evaluateAndExecute(conversationId, inboundPayload.tenantId, 'inbound')` |

---

## Build

| Element | Valeur |
|---|---|
| Image PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.89-autopilot-inbound-trigger-prod` |
| Digest | `sha256:6e8c1087b6e25175db8f36036397467feef9b05451e99a209d1d37a14bfba3cf` |
| Commit source | `4f60aad5` |
| Branche | `ph147.4/source-of-truth` |
| Build type | `docker build --no-cache` (build-from-git) |
| TypeScript compilation | OK (0 erreurs) |
| Push GHCR | OK |

---

## Déploiement GitOps

| Element | Valeur |
|---|---|
| Manifest | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` |
| Commit infra | `28929ff` — `PH-AUTOPILOT-INBOUND-TRIGGER-PROD: update PROD manifest to v3.5.89-autopilot-inbound-trigger-prod` |
| Image avant | `v3.5.88-test-control-safe-prod` |
| Image après | `v3.5.89-autopilot-inbound-trigger-prod` |
| Méthode | `kubectl apply -f` (GitOps strict, pas de `kubectl set image`) |
| Rollout | `deployment "keybuzz-api" successfully rolled out` |
| Pod | `keybuzz-api-6b567f4bb4-65sdx` — 1/1 Running, 0 restarts |
| Health | `{"status":"ok"}` |

---

## Validation PROD réelle

### CAS A — AUTOPILOT inbound (`switaa-sasu-mnc1ouqu`)

| Element | Valeur |
|---|---|
| Tenant | `switaa-sasu-mnc1ouqu` |
| Plan | AUTOPILOT |
| Mode | `autonomous` |
| safe_mode | `true` |
| allow_auto_reply | `true` |
| Message injecté | `POST /inbound/email` — sujet: "PH-AUTOPILOT-PROD-VALIDATION" |
| Conversation créée | `conv-4837f801` |
| ai_action_log AVANT | 4 |
| ai_action_log APRÈS | **5** (+1) |
| Entrée créée | `alog-1776720356907-4xhpzow65` |
| action_type | `autopilot_escalate` |
| status | `skipped` |
| blocked_reason | `ESCALATION_DRAFT:0.75` |
| confidence_score | `0.75` |

**Logs PROD :**
```
[Autopilot] switaa-sasu-mnc1ouqu conv=conv-4837f801 risk: buyer=LOW(0) product=MEDIUM(40) combined=MEDIUM
[Autopilot] switaa-sasu-mnc1ouqu conv=conv-4837f801 → ESCALATION_DRAFT (safe_mode, false_promises=je vais m'assurer, draft=285 chars)
```

**Analyse** : L'engine Autopilot a été automatiquement déclenché par le message inbound. Il a effectué l'évaluation de risque complète (buyer LOW, product MEDIUM, combined MEDIUM), généré un draft de 285 caractères, détecté une fausse promesse ("je vais m'assurer"), et correctement décidé une escalation en mode safe (draft disponible pour revue humaine au lieu d'envoi automatique).

**VERDICT CAS A : PASS**

### CAS B — PRO gating (`ecomlg-001`)

| Element | Valeur |
|---|---|
| Tenant | `ecomlg-001` |
| Plan | PRO |
| Mode | `supervised` |
| ai_action_log AVANT | 64 |
| ai_action_log APRÈS | **64** (inchangé) |
| Message injecté | `POST /inbound/email` — sujet: "PH-AUTOPILOT-PROD-VALIDATION PRO" |
| Conversation créée | `conv-a7abd174` |

**Logs PROD :**
```
[Autopilot] ecomlg-001 conv=conv-a7abd174 → MODE_NOT_AUTOPILOT:suggestion
```

**Analyse** : L'engine a été appelé mais a correctement identifié que le plan PRO ne permet que le mode `suggestion` (pas d'exécution autonome). Sortie immédiate sans impact sur le ai_action_log. Le gating par plan fonctionne parfaitement.

**VERDICT CAS B : PASS**

### CAS C — Logs

| Pattern recherché | Trouvé | Contexte |
|---|---|---|
| `[Autopilot]` | OUI | Entrées pour les deux cas A et B |
| `ESCALATION_DRAFT` | OUI | `switaa-sasu-mnc1ouqu` — escalation avec draft |
| `MODE_NOT_AUTOPILOT:suggestion` | OUI | `ecomlg-001` — gating PRO correct |
| `DRAFT_GENERATED` | N/A | L'engine a produit un draft mais l'a escaladé (safe_mode) |

**VERDICT CAS C : PASS**

---

## Tableau de synthèse validation

| Test | Attendu | Résultat |
|---|---|---|
| CAS A — AUTOPILOT inbound auto | Trigger auto + ai_action_log +1 | **PASS** — 4→5, ESCALATION_DRAFT:0.75 |
| CAS B — PRO gating | Sortie immédiate, 0 impact | **PASS** — 64→64, MODE_NOT_AUTOPILOT:suggestion |
| CAS C — Logs [Autopilot] | Entrées visibles | **PASS** — Risk scoring + ESCALATION + MODE_NOT visible |

---

## Non-régression PROD

| Endpoint | HTTP Status |
|---|---|
| `/health` | 200 |
| `/messages/conversations` | 200 |
| `/tenant-context/me` | 200 |
| `/dashboard/summary` | 200 |
| `/autopilot/settings` | 200 |
| `/billing/current` | 200 |
| `/metrics/overview` | 200 |
| Client PROD (`client.keybuzz.io`) | 200 |
| API PROD external (`api.keybuzz.io/health`) | 200 |

### Confirmations non-régression

| Element | Impact |
|---|---|
| Tracking ads | Aucun (pas touché) |
| Billing / Stripe | Aucun (`/billing/current` OK) |
| Metrics | Aucun (`/metrics/overview` OK) |
| Client SaaS | Aucun (pas touché, client.keybuzz.io OK) |
| Admin | Aucun (pas touché) |
| Outbound worker | Aucun (pas touché) |

---

## Preuves

### Preuve inbound CAS A
```json
POST /inbound/email
{"tenantId":"switaa-sasu-mnc1ouqu","from":"test-autopilot-validation@example.com","subject":"PH-AUTOPILOT-PROD-VALIDATION - Test trigger automatique","body":"Bonjour, je voudrais savoir ou en est ma commande numero 402-1234567-8901234. Merci."}
→ {"ok":true,"conversationId":"conv-4837f801","messageId":"msg-21236c79a9b05ab8","created":true}
```

### Preuve ai_action_log CAS A
```json
{
  "id": "alog-1776720356907-4xhpzow65",
  "action_type": "autopilot_escalate",
  "status": "skipped",
  "blocked_reason": "ESCALATION_DRAFT:0.75",
  "confidence_score": "0.75",
  "conversation_id": "conv-4837f801",
  "created_at": "2026-04-20T21:25:56.910Z"
}
```

### Preuve logs CAS A
```
[Autopilot] switaa-sasu-mnc1ouqu conv=conv-4837f801 risk: buyer=LOW(0) product=MEDIUM(40) combined=MEDIUM
[Autopilot] switaa-sasu-mnc1ouqu conv=conv-4837f801 → ESCALATION_DRAFT (safe_mode, false_promises=je vais m'assurer, draft=285 chars)
```

### Preuve inbound CAS B
```json
POST /inbound/email
{"tenantId":"ecomlg-001","from":"test-pro-validation@example.com","subject":"PH-AUTOPILOT-PROD-VALIDATION PRO - Test gating","body":"Bonjour, est-ce que ma commande est en route? Merci beaucoup."}
→ {"ok":true,"conversationId":"conv-a7abd174","messageId":"msg-82be85feb362c0e3","created":true}
```

### Preuve logs CAS B
```
[Autopilot] ecomlg-001 conv=conv-a7abd174 → MODE_NOT_AUTOPILOT:suggestion
```

### Preuve plan PRO non cassé
- ai_action_log inchangé : 64→64
- Aucune action Autopilot exécutée
- Le mode suggestion reste disponible pour les suggestions IA manuelles

---

## Rollback PROD

| Element | Valeur |
|---|---|
| Image précédente | `ghcr.io/keybuzzio/keybuzz-api:v3.5.88-test-control-safe-prod` |
| Image actuelle | `ghcr.io/keybuzzio/keybuzz-api:v3.5.89-autopilot-inbound-trigger-prod` |

### Procédure de rollback

1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` :
   ```yaml
   image: ghcr.io/keybuzzio/keybuzz-api:v3.5.88-test-control-safe-prod
   ```
2. Committer et pusher le manifest
3. Appliquer : `kubectl apply -f deployment.yaml`
4. Vérifier : `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`

---

## Conclusion

- **Patch minimal** : 1 import + 2 appels fire-and-forget dans `src/modules/inbound/routes.ts`
- **Aucun autre fichier modifié**
- **Aucune autre action effectuée** (pas de changement engine.ts, routes.ts autopilot, settings DB, client, admin, tracking, billing, metrics)
- **Build-from-git** depuis la branche `ph147.4/source-of-truth`, commit `4f60aad5`
- **GitOps strict** : manifest PROD commité (`28929ff`), pas de `kubectl set image`
- **Validation PROD réelle** : trigger automatique confirmé (CAS A), gating PRO confirmé (CAS B), logs confirmés (CAS C)
- **Non-régression** : 9/9 endpoints OK, aucun impact collatéral

---

## VERDICT FINAL

**AUTOPILOT INBOUND TRIGGER RESTORED IN PROD — MINIMAL PATCH — NON REGRESSION OK**
