# PH145-AUTOPILOT-GUARDRAILS-PROD-01 — Promotion PROD Garde-fous Autopilot

> Date : 10 avril 2026
> Statut : **PROD DEPLOYED — VALIDATED**
> Image DEV : `v3.5.240-ph145-guardrails-dev`
> Image PROD : `v3.5.240-ph145-guardrails-prod`
> Digest PROD : `sha256:80c54989426e797acb1d41e988f75e3526173808a2f7e39985d2fede23d4cf18`

---

## 1. Objectif

Promouvoir les garde-fous métier Autopilot (PH145) de DEV en PROD pour sécuriser les décisions IA en production : bloquer les remboursements non justifiés, les promesses abusives, et activer le scoring de risque.

---

## 2. Precheck (9/9 passés)


| #   | Vérification                               | Résultat |
| --- | ------------------------------------------ | -------- |
| 1   | Image DEV = v3.5.240                       | PASS     |
| 2   | Image PROD = v3.5.239 (avant)              | PASS     |
| 3   | Pod PROD healthy (Running)                 | PASS     |
| 4   | PROD /health HTTP 200                      | PASS     |
| 5   | DEV pod healthy                            | PASS     |
| 6   | Monitoring CronJob actif (*/2 min)         | PASS     |
| 7   | safe_mode = true sur tous les tenants PROD | PASS     |
| 8   | Guardrails actifs dans DEV pod             | PASS     |
| 9   | Source code patchée sur bastion            | PASS     |


### Tenants PROD — safe_mode


| Tenant                        | Enabled | Mode       | safe_mode |
| ----------------------------- | ------- | ---------- | --------- |
| `ecomlg-001`                  | true    | supervised | **true**  |
| `switaa-sasu-mnc1ouqu`        | true    | autonomous | **true**  |
| `switaa-sasu-mn9c3eza`        | true    | supervised | **true**  |
| `romruais-gmail-com-mn7mc6xl` | false   | off        | **true**  |


Tous les tenants avec autopilot activé ont `safe_mode: true` — aucun envoi automatique.

---

## 3. Build PROD

```
Source : /opt/keybuzz/keybuzz-api/ (même code que DEV v3.5.240)
Tag    : ghcr.io/keybuzzio/keybuzz-api:v3.5.240-ph145-guardrails-prod
Digest : sha256:80c54989426e797acb1d41e988f75e3526173808a2f7e39985d2fede23d4cf18
```

Le build utilise le même code source que le build DEV validé. Seul le tag change (`-prod` au lieu de `-dev`).

---

## 4. GitOps

### Fichiers modifiés


| Fichier                                | Changement                               |
| -------------------------------------- | ---------------------------------------- |
| `k8s/keybuzz-api-prod/deployment.yaml` | Image → `v3.5.240-ph145-guardrails-prod` |
| `k8s/keybuzz-api-dev/deployment.yaml`  | Image → `v3.5.240-ph145-guardrails-dev`  |


### Convention de versioning


| Environnement | Ancien tag                           | Nouveau tag                      |
| ------------- | ------------------------------------ | -------------------------------- |
| DEV           | `v3.5.49-ph145-guardrails-dev`       | `v3.5.240-ph145-guardrails-dev`  |
| PROD          | `v3.5.239-ph-autopilot-shopify-prod` | `v3.5.240-ph145-guardrails-prod` |


---

## 5. Déploiement

```
Rollout: deployment "keybuzz-api" successfully rolled out
Pod: keybuzz-api-7f49959f64-7d7v7 (Running)
Health: HTTP 200
```

### Vérifications pod PROD


| Check                                           | Résultat      |
| ----------------------------------------------- | ------------- |
| `engine.js` contient `GUARDRAIL_BLOCKED`        | 3 occurrences |
| `engine.js` contient `evaluateGuardrails`       | 1 occurrence  |
| `engine.js` contient `GUARDRAIL_SYSTEM_RULES`   | 1 occurrence  |
| `autopilotGuardrails.js` présent                | 15,013 octets |
| `autopilotEngine.js` absent (code mort nettoyé) | Confirmé      |


---

## 6. Validation PROD (16/16 passés)


| #   | Test                                 | Résultat   |
| --- | ------------------------------------ | ---------- |
| 1   | `/health`                            | PASS (200) |
| 2   | `/messages/conversations`            | PASS (200) |
| 3   | `/api/v1/orders`                     | PASS (200) |
| 4   | `/dashboard/summary`                 | PASS (200) |
| 5   | `/stats/conversations`               | PASS (200) |
| 6   | `/autopilot/settings`                | PASS (200) |
| 7   | `safe_mode = true`                   | PASS       |
| 8   | `/ai/wallet/status`                  | PASS (200) |
| 9   | `/billing/current`                   | PASS (200) |
| 10  | `/tenant-context/me`                 | PASS (200) |
| 11  | POST `/autopilot/evaluate` (Amazon)  | PASS (200) |
| 12  | POST `/autopilot/evaluate` (Shopify) | PASS (200) |
| 13  | `/ai/rules` (playbooks)              | PASS (200) |
| 14  | Logs PROD (0 erreurs critiques)      | PASS       |
| 15  | Outbound worker PROD running         | PASS       |
| 16  | DEV toujours healthy                 | PASS       |


### Autopilot Evaluate — Comportement observé

Le tenant `ecomlg-001` est en mode `supervised` → l'évaluation retourne `MODE_NOT_AUTOPILOT:suggestion`, ce qui est le comportement attendu. Les guardrails s'activeront automatiquement quand un tenant passera en mode `autonomous`.

Le tenant `switaa-sasu-mnc1ouqu` est en mode `autonomous` avec `safe_mode: true` → les guardrails seront actifs lors de la prochaine évaluation, mais le `safe_mode` empêche tout envoi automatique (draft uniquement).

---

## 7. Logs PROD

- 0 erreurs critiques (`fatal`, `crash`, `unhandled`)
- Pas encore d'entrées `GUARDRAIL_BLOCKED` ou `DRAFT_FOR_REVIEW` (attendu : les guardrails loguent quand l'autopilot évalue en mode `autonomous`)
- Les logs apparaîtront dès qu'un message inbound déclenchera l'autopilot en mode `autonomous`

---

## 8. Rollback

```bash
# Rollback PROD immédiat
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.239-ph-autopilot-shopify-prod \
  -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod

# Rollback DEV si nécessaire
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.239-ph-autopilot-shopify-dev \
  -n keybuzz-api-dev
```

---

## 9. Composants déployés

### Pipeline Autopilot enrichi (engine.ts)

```
Message inbound
  → evaluateAndExecute()
    → loadSettings + loadContext + loadOrderContext
    → evaluateGuardrails() ← [PH145] Scoring risque client + produit
    → getAISuggestion() ← [PH145] Prompt enrichi (GUARDRAIL_SYSTEM_RULES + risk context)
    → validateDraft() ← [PH145] Validation post-LLM (patterns interdits)
    → if BLOCK → log GUARDRAIL_BLOCKED + escalation
    → if REVIEW → force draft mode
    → if SEND → execute/draft selon safe_mode
```

### Fichiers runtime


| Fichier                               | Rôle                           |
| ------------------------------------- | ------------------------------ |
| `src/modules/autopilot/engine.ts`     | Moteur principal (994 lignes)  |
| `src/modules/autopilot/routes.ts`     | Routes Fastify `/autopilot/*`  |
| `src/services/autopilotGuardrails.ts` | Module garde-fous (505 lignes) |


---

## 10. Prochaines étapes

1. **Monitoring** : Surveiller les logs `[Autopilot]` pour les entrées `risk:` et `GUARDRAIL_BLOCKED`
2. **Premier test réel** : Quand un message inbound arrive sur un tenant en mode `autonomous`, vérifier le scoring dans les logs
3. **Tuning** : Ajuster les seuils si trop/pas assez restrictif (seuils actuels : LOW < 25, MEDIUM < 50, HIGH >= 50)
4. **Dashboard** : Afficher le risk level dans le panel autopilot du client (future phase)

---

## 11. Verdict

**PH145 PROD DEPLOYED — AUTOPILOT GUARDRAILS ACTIVE**

- Image : `v3.5.240-ph145-guardrails-prod`
- Validation : 16/16 checks passés
- Guardrails : confirmés dans le pod PROD (3 refs GUARDRAIL_BLOCKED dans engine.js compilé)
- Safe mode : actif sur tous les tenants
- Non-régression : Amazon, Shopify, conversations, wallet, playbooks, workers — tous OK
- DEV : toujours healthy et aligné

