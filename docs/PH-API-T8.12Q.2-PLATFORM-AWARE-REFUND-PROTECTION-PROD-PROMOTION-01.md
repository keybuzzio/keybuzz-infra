# PH-API-T8.12Q.2 — Platform-Aware Refund Protection PROD Promotion

> **Phase** : PH-API-T8.12Q.2-PLATFORM-AWARE-REFUND-PROTECTION-PROD-PROMOTION-01
> **Type** : Promotion PROD API
> **Priorite** : P0
> **Linear** : KEY-235
> **Date** : 2026-05-01
> **Verdict** : **PLATFORM-AWARE REFUND PROTECTION LIVE IN PROD**

---

## Objectif

Promouvoir en PROD la stack API validee en DEV pour rendre l'IA KeyBuzz reellement platform-aware :

- Contexte channel/marketplace injecte dans les prompts IA
- Refund Protection platform-aware (5 nouvelles regles)
- Response Strategy platform-aware (overrides par posture)
- Posture stricte Amazon/Octopia (marketplace_strict)
- Posture direct seller Shopify/email (direct_seller_controlled)
- Unknown safe (aucune decision financiere)
- Client/Admin/Website inchanges

---

## Sources relues

- `CE_PROMPTING_STANDARD.md`
- `RULES_AND_RISKS.md`
- `API_AUTOPILOT_CONTEXT.md`
- `SELLER_FIRST_REFUND_PROTECTION_DOCTRINE.md`
- `PH-SAAS-T8.12O.1-PLATFORM-AWARE-AI-BEHAVIOR-AND-MARKETPLACE-POLICY-AUDIT-01.md`
- `PH-API-T8.12P-MARKETPLACE-CHANNEL-CONTEXT-INJECTION-DEV-01.md`
- `PH-API-T8.12Q-PLATFORM-AWARE-REFUND-PROTECTION-AND-RESPONSE-STRATEGY-DEV-01.md`
- `PH-API-T8.12Q.1-PLATFORM-AWARE-RUNTIME-VALIDATION-DEV-01.md`
- `PH49-REFUND-PROTECTION-REPORT.md`
- `PH137-A-AUTOPILOT-SMART-RESPONSE-01-REPORT.md`
- `PH147-AUTOPILOT-GUARDRAILS-BUSINESS-01.md`

---

## Preflight

| Repo | Branche attendue | Branche constatee | HEAD | Dirty ? | Verdict |
|---|---|---|---|---|---|
| `keybuzz-infra` | `main` | `main` | `5d29a37` | Non (docs untracked) | OK |
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `16106d23` | dist/ seulement | OK |

| Service | ENV | Image avant | Image runtime | Match ? |
|---|---|---|---|---|
| API | DEV | `v3.5.130-platform-aware-refund-strategy-dev` | idem | OK |
| API | PROD | `v3.5.128-trial-autopilot-assisted-prod` | idem | OK |
| Client | PROD | `v3.5.145-client-ga4-sgtm-parity-prod` | idem | OK |
| Backend | PROD | `v1.0.46-ph-recovery-01-prod` | idem | OK |

---

## Source promue

| Brique | Fichier | Presente ? |
|---|---|---|
| Helper marketplace channel | `src/lib/marketplace-channel-context.ts` (62 lignes) | Oui |
| Injection AI Assist | `ai-assist-routes.ts` (2 refs) | Oui |
| Injection Autopilot | `autopilot/engine.ts` (2 refs) | Oui |
| Refund Protection (15 rules total) | `refundProtectionLayer.ts` | Oui |
| 5 nouvelles regles platform-aware | idem | Oui |
| Response Strategy override | `responseStrategyEngine.ts` (2 refs) | Oui |
| Promise Detection | `autopilotGuardrails.ts` (2 refs) | Oui |
| Guardrails channel bonus | idem (CHANNEL_AMAZON, CHANNEL_OCTOPIA) | Oui |

---

## Tests avant build

| Test | Resultat |
|---|---|
| TypeScript (`tsc --noEmit`) | PASS (0 erreur) |
| 29/29 tests platform-aware | PASS |

---

## Build PROD

| Element | Valeur |
|---|---|
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.130-platform-aware-refund-strategy-prod` |
| Source | Clone propre `ph147.4/source-of-truth` |
| HEAD | `16106d23` |
| Build | `docker build --no-cache` |
| Digest | `sha256:1c1ccb19c5f56e1262a0d6b681f4ab5fdfa3c2251a991820f371671a7e4df2c7` |

---

## GitOps PROD

| Manifest | Image avant | Image apres | Runtime | Verdict |
|---|---|---|---|---|
| `keybuzz-api-prod/deployment.yaml` | `v3.5.128-trial-autopilot-assisted-prod` | `v3.5.130-platform-aware-refund-strategy-prod` | `v3.5.130-platform-aware-refund-strategy-prod` | OK |

Commit infra : `18fab80` — `deploy(api-prod): v3.5.130-platform-aware-refund-strategy-prod (PH-API-T8.12Q.2, KEY-235)`

---

## Validation PROD structurelle

| Check | Attendu | Resultat |
|---|---|---|
| Pod Running 1/1 | 1/1 | OK |
| 0 restart post rollout | 0 | OK |
| API health | `{"status":"ok"}` | OK |
| Client PROD inchange | `v3.5.145-client-ga4-sgtm-parity-prod` | OK |
| Website PROD inchange | `v0.6.8-tiktok-browser-pixel-prod` | OK |
| Backend PROD inchange | `v1.0.46-ph-recovery-01-prod` | OK |
| Aucun secret dans logs | Aucun | OK |

---

## Validation PROD dry-run (17/17 PASS)

| Test | Channel | Resultat |
|---|---|---|
| T1-ctx-amazon | amazon | marketplace_strict OK |
| T2-ctx-octopia | octopia | marketplace_strict OK |
| T3-ctx-shopify | shopify | direct_seller_controlled OK |
| T4-ctx-email | email | direct_seller_controlled OK |
| T5-ctx-null | null | unknown OK |
| T6-prompt-amazon | amazon | Prompt block correct OK |
| T7-prompt-shopify | shopify | Prompt block correct OK |
| T8-prompt-unknown | null | Prompt block correct OK |
| T9-refund-rule-return | n/a | marketplace_requires_return_procedure OK |
| T10-refund-rule-unknown | n/a | unknown_channel_no_financial_decision OK |
| T11-strategy-override | n/a | applyPlatformAwareOverrides OK |
| T12-promise-detection | n/a | FORBIDDEN_PROMISE_PATTERNS OK |
| T13-guardrails-bonus | n/a | CHANNEL_AMAZON + CHANNEL_OCTOPIA OK |
| T14-refund-eval-amazon | amazon | Eval structure valide OK |
| T15-refund-eval-shopify | shopify | Eval structure valide OK |
| T16-refund-eval-unknown | null | Eval structure valide OK |
| T17-strategy-amazon | amazon | Forbidden phrases OK |

Aucun envoi reel marketplace durant les tests.

---

## Validation Autopilot safe

| Check | Attendu | Resultat |
|---|---|---|
| Channel context autopilot engine | Present | OK |
| Channel context ai-assist | Present | OK |
| FORBIDDEN_PROMISE_PATTERNS | Intactes | OK |
| Channel bonus guardrails | Amazon+Octopia | OK |
| No auto-send config | 0 | OK |
| Recent outbound (1h) | 0 | OK |
| ESCALATION_DRAFT/safe_mode | Present | OK |
| Promise patterns | Intactes | OK |

---

## Non-regression PROD

| Surface | Attendu | Resultat |
|---|---|---|
| 0 outbound marketplace (2h) | 0 | OK |
| 0 billing event (2h) | 0 | OK |
| 0 restart pod | 0 | OK |
| API DEV health | OK | OK |
| API PROD health | OK | OK |
| Client DEV inchange | OK | OK |
| Client PROD inchange | OK | OK |
| Backend DEV/PROD inchange | OK | OK |
| Website PROD inchange | OK | OK |
| 0 funnel/CAPI event (2h) | 0 | OK |
| 0 error logs | 0 | OK |

---

## Rollback GitOps

Image de rollback : `v3.5.128-trial-autopilot-assisted-prod`

Procedure :

1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` : image -> `v3.5.128-trial-autopilot-assisted-prod`
2. `git add` + `git commit -m "rollback(api-prod): v3.5.128 (revert PH-API-T8.12Q.2)"` + `git push`
3. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`
5. Verifier runtime = manifest = `v3.5.128-trial-autopilot-assisted-prod`

---

## Gaps restants

1. Client demo/docs/playbooks pas encore realignes avec la doctrine platform-aware
2. Pas de tests e2e avec de vrais messages marketplace (hors scope delibere)
3. KEY-235 reste ouverte pour alignement Client

---

## Statut KEY-235

**Promotion PROD effectuee.** Validations completes. Ne pas fermer — Client demo/docs/playbooks restent a aligner.

---

## Verdict

**PLATFORM-AWARE REFUND PROTECTION LIVE IN PROD — AMAZON/OCTOPIA STRICT — SHOPIFY/EMAIL SELLER-CONTROLLED — UNKNOWN SAFE — NO AUTO-SEND/TRACKING/BILLING/CAPI DRIFT — GITOPS STRICT — CLIENT/ADMIN/WEBSITE UNCHANGED**

---

*Rapport : `keybuzz-infra/docs/PH-API-T8.12Q.2-PLATFORM-AWARE-REFUND-PROTECTION-PROD-PROMOTION-01.md`*
