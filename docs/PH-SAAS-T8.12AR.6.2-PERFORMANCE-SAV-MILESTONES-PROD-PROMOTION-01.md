# PH-SAAS-T8.12AR.6.2 — Performance SAV Milestones PROD Promotion

> Date : 2026-05-10
> Linear : KEY-289 / Parent KEY-282
> Phase : promotion PROD API + Client
> Environnement : PROD
> Dependencies validees : AR.6, AR.6.1, AR.6.1A

## VERDICT

**PERFORMANCE SAV MILESTONES LIVE IN PROD** — ENRICHED TENANT MILESTONES / CURVES / HONEST AI KPI / FRENCH COPY / UNICODE FIX PROMOTED — NO FAKE METRICS — NO DB MUTATION — NO BILLING/TRACKING/CAPI DRIFT — MESSAGE_SOURCE / AUTHOR_NAME / NO_REASK BASELINES PRESERVED — API/CLIENT GITOPS STRICT — AR.6 COMPLETE

---

## 0. Preflight

| Repo | Branche attendue | Branche reelle | HEAD | Status | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | fbb45c0c | Clean (src/) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | ce1bdd2 | Clean | OK |
| keybuzz-infra | main | main | feef0fc | Clean | OK |

| Service | Image PROD avant | Doit changer ? |
|---|---|---|
| API | v3.5.149-message-source-enrichment-prod | OUI |
| Client | v3.5.172-message-source-enrichment-ux-prod | OUI |
| Backend | v1.0.47-cross-env-guard-fix-prod | NON |
| Website | v0.6.12-linkedin-insight-seo-prod | NON |
| Admin | v2.12.2-media-buyer-lp-domain-qa-prod | NON |
| OW | v3.5.165-escalation-flow-prod | NON |

---

## 1. Verification source API

| Point API | Preuve | Resultat |
|---|---|---|
| Jalons enrichis AR.6 | 8 types dans milestoneConfig (tenant_created, autopilot, etc.) | OK |
| Labels FR corriges | grep 15 lignes FR avec accents | OK |
| Limitations FR | 5 strings francais | OK |
| Unicode AR.6.1A | grep -cF '\u00' = 0 | OK |
| Satisfaction non instrumentee | value null, reason satisfaction_not_instrumented | OK |
| Pas de mutation DB | SELECT read-only uniquement | OK |
| Pas de fake metrics | Aucune donnee inventee | OK |
| TSC OK | npx tsc --noEmit = 0 erreurs | OK |

---

## 2. Verification source Client

| Point Client | Preuve | Resultat |
|---|---|---|
| Courbes corrigees | items-end supprime du flex container | OK |
| Etat tout-a-zero | Message "Aucune activite sur cette periode." | OK |
| KPI IA sans % >100 | Affiche compteur brut draftsUsed | OK |
| Labels FR avec accents | grep 21 lignes FR | OK |
| Unicode AR.6.1A | grep -cF '\u00' = 0 | OK |
| Jalons preserves | Rendering conditionnel intact | OK |
| Non instrumentes honnetes | Section "Non instrumentes" visible | OK |
| Satisfaction Bientot disponible | value/subtitle = "Bientot disponible" | OK |
| Pas de tracking ajoute | Aucun GA4/CAPI/TikTok ajoute | OK |
| Pas de fake data | Aucune donnee inventee | OK |

---

## 3. Pre-build checks

| Repo | Check | Resultat |
|---|---|---|
| API | TypeScript tsc --noEmit | OK |
| API | Unicode escapes = 0 | OK |
| API | Pas de hardcoding tenant/email | OK |
| API | Pas de mutation/backfill | OK |
| Client | Unicode escapes = 0 | OK |
| Client | Pas de fake data | OK |
| Client | Pas de tracking ajoute | OK |
| Client | Pas d'URL DEV | OK |

---

## 4. Build PROD

| Service | Commit source | Tag | Digest | Rollback |
|---|---|---|---|---|
| API PROD | fbb45c0c | v3.5.150-performance-sav-milestones-prod | sha256:edd1e9de4b2d... | v3.5.149-message-source-enrichment-prod |
| Client PROD | ce1bdd2 | v3.5.173-performance-sav-milestones-ux-prod | sha256:60f62bf03909... | v3.5.172-message-source-enrichment-ux-prod |

Build args Client PROD : `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production`

---

## 5. GitOps PROD

| Manifest | Image avant | Image apres | Rollback |
|---|---|---|---|
| k8s/keybuzz-api-prod/deployment.yaml | v3.5.149-message-source-enrichment-prod | v3.5.150-performance-sav-milestones-prod | v3.5.149 |
| k8s/keybuzz-client-prod/deployment.yaml | v3.5.172-message-source-enrichment-ux-prod | v3.5.173-performance-sav-milestones-ux-prod | v3.5.172 |

Commit infra : `a4d11d5` (main, pousse)

---

## 6. Deploy PROD

| Service | Pod | Image runtime | Restarts | Health | Verdict |
|---|---|---|---|---|---|
| API PROD | keybuzz-api-58fbd574cd-ljnr7 | v3.5.150-performance-sav-milestones-prod | 0 | OK (port 3001) | OK |
| Client PROD | keybuzz-client-775d579f67-xtmlx | v3.5.173-performance-sav-milestones-ux-prod | 0 | Running | OK |

---

## 7. Validation API PROD

| Range | HTTP | Jalons | Satisfaction | Unicode | PII | Verdict |
|---|---|---|---|---|---|---|
| 7d | 200 | Structure OK | null | false | false | OK |
| 30d | 200 | Structure OK | null | false | false | OK |
| 90d | 200 | Structure OK | null | false | false | OK |

Notes :
- Limitations en francais confirme : `Seulement 0% des conversations ont une première réponse`
- Unavailable en francais confirme : `Mode suggestion activé | Mode autopilot activé | Agent KeyBuzz activé`
- `HAS_LITERAL_ESCAPES: false`

---

## 8. Non-regression

| Service PROD | Image avant | Image apres | Verdict |
|---|---|---|---|
| API | v3.5.149-message-source-enrichment-prod | v3.5.150-performance-sav-milestones-prod | PROMU |
| Client | v3.5.172-message-source-enrichment-ux-prod | v3.5.173-performance-sav-milestones-ux-prod | PROMU |
| Backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| OW | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | INCHANGE |

---

## 9. DB Read-Only PROD

| Table | Avant | Apres | Delta | Verdict |
|---|---|---|---|---|
| tenants | 14 | 14 | 0 | OK |
| conversations | 573 | 573 | 0 | OK |
| messages | 1674 | 1674 | 0 | OK |
| ai_action_log | 143 | 143 | 0 | OK |
| billing_events | 165 | 165 | 0 | OK |

---

## 10. Tracking / Billing / CAPI

| Surface | Attendu | Resultat |
|---|---|---|
| Fake Purchase | Aucun | OK |
| Fake CompletePayment | Aucun | OK |
| CAPI event | Aucun | OK |
| Stripe mutation | Aucune | OK |
| Billing change | Aucun | OK |
| URL DEV dans PROD | Aucune | OK |

---

## 11. Rollback PROD (GitOps strict, non execute)

```bash
# 1. Modifier manifests
# k8s/keybuzz-api-prod/deployment.yaml : v3.5.149-message-source-enrichment-prod
# k8s/keybuzz-client-prod/deployment.yaml : v3.5.172-message-source-enrichment-ux-prod

# 2. Commit + push infra

# 3. Apply
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.149-message-source-enrichment-prod -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod

kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.172-message-source-enrichment-ux-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod

# 4. Valider health + /performance
```

---

## 12. Linear

- KEY-289 : AR.6.2 PROD promotion complete. API v3.5.150 + Client v3.5.173 PROD. Statut Done.
- KEY-282 : AR.6 complete. Garder ouvert pour AR.5 satisfaction instrumentation.
- KEY-290 : Ne pas fermer (AR.5 satisfaction non encore traite).

---

## 13. Contenu promu (recap)

| Feature | Source | Phase |
|---|---|---|
| Jalons tenant enrichis (8 types deterministes) | AR.6 | DEV → PROD |
| Jalons non instrumentes honnetes (3 types) | AR.6 | DEV → PROD |
| Confidence metadata par jalon | AR.6 | DEV → PROD |
| Courbes bar-chart corrigees (flex layout) | AR.6.1 | DEV → PROD |
| Etat explicite serie tout-a-zero | AR.6.1 | DEV → PROD |
| KPI IA compteur brut (plus de % >100) | AR.6.1 | DEV → PROD |
| Labels francais avec accents | AR.6.1 | DEV → PROD |
| Limitations en francais | AR.6.1 | DEV → PROD |
| Correction encodage Unicode | AR.6.1A | DEV → PROD |

---

## 14. Gaps restants

| Gap | Phase prevue |
|---|---|
| Satisfaction client non instrumentee | AR.5 (KEY-290) |
| Mode suggestion/autopilot non traque | Instrumenter ai_settings history |
| FRT exclut heures non ouvrees | Future phase |
| message_source legacy = correlation | Historique preserve, pas de backfill |
