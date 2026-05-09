# PH-SAAS-T8.12AR.4 — TERMINÉ

**Verdict : GO PROD**

**DASHBOARD PERFORMANCE SAV LIVE IN PROD — API PERFORMANCE METRICS AND CLIENT /PERFORMANCE PAGE PROMOTED — TENANT-SCOPED READ-ONLY KPI / CURVES / AI PANEL / MILESTONES AVAILABLE — SATISFACTION HONESTLY DISPLAYED AS NOT INSTRUMENTED — NO FAKE METRICS — NO PII — NO DB MUTATION — NO BILLING/TRACKING/CAPI DRIFT — AP/AQ BASELINES PRESERVED — API/CLIENT GITOPS STRICT — READY FOR POST-PROD QA**

---

## Résumé exécutif

Le Dashboard Performance SAV, validé en DEV (AR.2 API + AR.3 Client), a été promu en PROD avec succès via GitOps strict.

- **API PROD** : `GET /stats/performance` — endpoint read-only, tenant-scoped, retournant messages reçus, réponses envoyées, temps médian de première réponse, adoption IA, panel IA, jalons, limitations
- **Client PROD** : page `/performance` — consomme uniquement les métriques du tenant courant via BFF authentifié
- **Satisfaction** : affichée comme `Bientôt disponible` (null, confidence=none, reason=satisfaction_not_instrumented)
- **Aucune mutation DB**, aucun fake event, aucun tracking ajouté, aucune régression

---

## Sources relues

| Document | Statut |
|---|---|
| `keybuzz-infra/docs/PH-SAAS-T8.12AR.1-*` | Relu (audit + design) |
| `keybuzz-infra/docs/PH-SAAS-T8.12AR.2-*` | Relu (API DEV) |
| `keybuzz-infra/docs/PH-SAAS-T8.12AR.3-*` | Relu (Client DEV) |
| `.cursor/rules/keybuzz-v3-context.mdc` | Relu (infra) |

---

## Preflight

### Repos

| Repo | Branche attendue | Branche réelle | HEAD | Status | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `dac5b790` | src clean (dist deleted) | ✅ PASS |
| keybuzz-client | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `c8e0ffe` | tsconfig.tsbuildinfo modified | ✅ PASS |
| keybuzz-infra | `main` | `main` | `0fce232` | clean | ✅ PASS |

### Images PROD avant

| Service | Image PROD avant | Doit changer ? |
|---|---|---|
| API | `v3.5.147-auto-assignment-after-reply-prod` | OUI |
| Client | `v3.5.170-shopify-visible-disabled-channels-prod` | OUI |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | NON |
| Website | `v0.6.12-linkedin-insight-seo-prod` | NON |
| Admin | `v2.12.2-media-buyer-lp-domain-qa-prod` | NON |
| Outbound Worker | `v3.5.165-escalation-flow-prod` | NON |

---

## Vérification source API (AR.2)

| Point API | Preuve | Résultat |
|---|---|---|
| GET /stats/performance | `performance-stats.routes.ts` | ✅ |
| Ranges 7d, 30d, 90d, all | `performance-stats.service.ts` | ✅ |
| messagesReceived | SQL COUNT FILTER inbound + HUMAN | ✅ |
| repliesSent | SQL COUNT FILTER outbound | ✅ |
| medianFirstResponseSeconds | SQL PERCENTILE_CONT(0.5) | ✅ |
| aiAdoptionRate | SQL ai_action_log | ✅ |
| satisfactionRate.value = null | ligne 223 | ✅ |
| satisfactionRate.confidence = none | source | ✅ |
| reason = satisfaction_not_instrumented | source | ✅ |
| aiMetrics | SQL ai_action_log | ✅ |
| series | SQL time series | ✅ |
| milestones | SQL conversations/messages/ai_action_log | ✅ |
| limitations | array explicite | ✅ |
| Tenant scoping | WHERE tenant_id = $1 | ✅ |
| 0 write SQL (INSERT/UPDATE/DELETE) | grep = 0 matches | ✅ |
| 0 event tracking | source | ✅ |
| 0 PII dans réponse | PII scan JSON = CLEAN | ✅ |

---

## Vérification source Client (AR.3)

| Point Client | Preuve | Résultat |
|---|---|---|
| Page /performance | `app/performance/page.tsx` | ✅ |
| BFF /api/stats/performance | `app/api/stats/performance/route.ts` | ✅ |
| Sidebar "Performance SAV" | ClientLayout + i18n | ✅ |
| Tenant via useTenant() | ligne 213 `currentTenantId` | ✅ |
| 0 champ tenantId saisissable | grep input.*tenant = 0 | ✅ |
| 0 tenant hardcodé | source | ✅ |
| KPI cards | source | ✅ |
| Courbe messages/réponses | MiniBarChart CSS | ✅ |
| Panel IA | source | ✅ |
| Milestones | source | ✅ |
| Limitations | source | ✅ |
| Satisfaction "Bientôt disponible" | ligne 344 | ✅ |
| État vide honnête | source | ✅ |
| 0 tracking ajouté | source | ✅ |
| 0 fake data | source | ✅ |

---

## Tenant-safe validation

| Test sécurité | Attendu | Résultat |
|---|---|---|
| Tenant courant valide (ecomlg-001, 7d) | 200 + KPIs | ✅ HTTP 200, messagesReceived=57 |
| Tenant courant valide (ecomlg-001, all) | 200 + KPIs | ✅ HTTP 200, messagesReceived=1146 |
| Tenant inexistant (nonexistent-xyz) | 200, valeurs à 0 | ✅ HTTP 200, messagesReceived=0 |
| Tenant manquant | 400 | ✅ HTTP 400 `tenantId is required` |
| BFF protégé par auth | 307 redirect | ✅ client.keybuzz.io/performance → 307 |
| PII scan JSON | 0 PII | ✅ CLEAN sur toutes les ranges |

---

## No fake metrics validation

| Métrique | Source réelle | Limitation | Verdict |
|---|---|---|---|
| messagesReceived | `messages` WHERE direction=inbound | message_source filtre HUMAN uniquement si disponible | ✅ |
| repliesSent | `messages` WHERE direction=outbound | Inclut toutes les sources (human/auto) | ✅ |
| medianFirstResponseSeconds | `conversations.first_response_at` | Couverture ~51% des conversations | ✅ |
| aiAdoptionRate | `ai_action_log` | Dépend de l'usage réel IA | ✅ |
| satisfactionRate | null | Pas encore instrumentée (AR.5) | ✅ |
| milestones | conversations, messages, channels | Détection automatique | ✅ |

---

## Builds PROD

| Service | Commit source | Tag | Digest |
|---|---|---|---|
| API | `dac5b790` | `v3.5.148-performance-sav-metrics-prod` | `sha256:e58a55d436c5f2275484ac11246a083e5bf4e2ce1b7ebd05accf91506aab408e` |
| Client | `c8e0ffe` | `v3.5.171-performance-sav-dashboard-prod` | `sha256:a752a91a2d60b2b577bd9aa198e8710bd6a68894f2d38bb6525466cb1001297e` |

### Build args Client PROD (tracking préservé)

| Variable | Valeur |
|---|---|
| NEXT_PUBLIC_API_URL | https://api.keybuzz.io |
| NEXT_PUBLIC_API_BASE_URL | https://api.keybuzz.io |
| NEXT_PUBLIC_APP_ENV | production |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | G-R3QQDYEBFG |
| NEXT_PUBLIC_META_PIXEL_ID | 1234164602194748 |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 |

---

## GitOps

| Manifest | Image avant | Image après | Rollback |
|---|---|---|---|
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.147-auto-assignment-after-reply-prod` | `v3.5.148-performance-sav-metrics-prod` | `v3.5.147-auto-assignment-after-reply-prod` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.170-shopify-visible-disabled-channels-prod` | `v3.5.171-performance-sav-dashboard-prod` | `v3.5.170-shopify-visible-disabled-channels-prod` |

Commit infra : `2570e45` — `gitops(prod): Performance SAV dashboard API v3.5.148 + Client v3.5.171 (AR.4 KEY-287)`

---

## Validation PROD API

| Range | HTTP | KPI | Satisfaction | PII | Verdict |
|---|---|---|---|---|---|
| 7d | 200 | messagesReceived=57, repliesSent=12, medianFRT=83163s, aiAdoption=0 | `{"value":null,"confidence":"none","reason":"satisfaction_not_instrumented"}` | CLEAN | ✅ |
| 30d | 200 | messagesReceived=314, repliesSent=106, medianFRT=70792s | null, satisfaction_not_instrumented | CLEAN | ✅ |
| 90d | 200 | messagesReceived=935, repliesSent=248, medianFRT=70173s | null, satisfaction_not_instrumented | CLEAN | ✅ |
| all | 200 | messagesReceived=1146, repliesSent=425, medianFRT=69837s | null, satisfaction_not_instrumented | CLEAN | ✅ |

---

## Validation PROD Client

| Page | Attendu | Résultat |
|---|---|---|
| /performance | 307 redirect auth | ✅ (protégé, auth guard OK) |
| /dashboard | 307 redirect auth | ✅ (préservé) |
| /pricing | 200 public | ✅ |
| /register | 200 public | ✅ |
| /performance bundle | page.js exists in bundle | ✅ |

---

## Non-régression AP baselines

| Baseline | Vérification | Résultat |
|---|---|---|
| auto-assignment after reply | Commit `dac5b790` contient `9521fb35` dans l'historique | ✅ Préservé |
| resolved clears escalation | Commit `a18a361d` dans l'historique | ✅ Préservé |
| real agent display name | Commit `3bb929b4` dans l'historique | ✅ Préservé |
| stale draft invalidation | Commit `5ae88713` dans l'historique | ✅ Préservé |
| Shopify visible disabled | Commit `5e24487` dans le client | ✅ Préservé |
| API /stats/conversations | HTTP 200 en PROD | ✅ Fonctionnel |
| API /health | HTTP 200 `{"status":"ok"}` | ✅ |
| Outbound Worker | Image inchangée `v3.5.165-escalation-flow-prod` | ✅ |
| Backend | Image inchangée `v1.0.47-cross-env-guard-fix-prod` | ✅ |
| Website | Image inchangée `v0.6.12-linkedin-insight-seo-prod` | ✅ |
| Admin | Image inchangée `v2.12.2-media-buyer-lp-domain-qa-prod` | ✅ |

---

## Tracking / Billing / CAPI

| Surface | Attendu | Résultat |
|---|---|---|
| GA4 (G-R3QQDYEBFG) | Présent dans bundle | ✅ 1 occurrence |
| sGTM (t.keybuzz.pro) | Présent dans bundle | ✅ 2 occurrences |
| TikTok (D7PT12JC77U44OJIPC10) | Présent dans bundle | ✅ 1 occurrence |
| LinkedIn (9969977) | Présent dans bundle | ✅ 1 occurrence |
| Meta (1234164602194748) | Présent dans bundle | ✅ 1 occurrence |
| Purchase browser | Absent (0 faux event) | ✅ 0 dans tracking, présent uniquement dans billing (Stripe checkout existant) |
| CompletePayment browser | Absent | ✅ 0 occurrence |
| URL DEV fonctionnelle | Aucune URL DEV client-side active | ✅ (2 fallbacks SSR pré-existants dans auth/logout + billing, jamais atteints car NEXTAUTH_URL défini) |
| Stripe checkout créé | 0 | ✅ |
| Billing modifié | 0 | ✅ |
| CAPI event créé | 0 | ✅ |

---

## DB read-only baseline

| Table | Avant | Après | Delta | Verdict |
|---|---|---|---|---|
| tenants | 14 | 14 | 0 | ✅ |
| conversations | 572 | 572 | 0 | ✅ |
| messages | 1673 | 1673 | 0 | ✅ |
| ai_action_log | 143 | 143 | 0 | ✅ |
| billing_events | 162 | 162 | 0 | ✅ |

---

## Rollback (documenté, non exécuté)

### API rollback

```yaml
# k8s/keybuzz-api-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.147-auto-assignment-after-reply-prod
```

### Client rollback

```yaml
# k8s/keybuzz-client-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.170-shopify-visible-disabled-channels-prod
```

### Procédure rollback

1. Modifier les manifests ci-dessus dans `keybuzz-infra`
2. `git commit -m "rollback(prod): revert AR.4 performance dashboard" && git push origin main`
3. Sur bastion : `cd /opt/keybuzz/keybuzz-infra && git pull origin main`
4. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
5. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`
6. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`
7. `kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod`
8. Vérifier `/health` et les pages client

---

## Linear

### KEY-287 (cette phase)

- Statut : **Done**
- Tag API : `v3.5.148-performance-sav-metrics-prod`
- Tag Client : `v3.5.171-performance-sav-dashboard-prod`
- Digests : voir section Builds
- Rollback : voir section Rollback

### KEY-282 (parent)

- Reste **ouvert** — AR.5, AR.6, AR.7 encore à faire
- AR.4 complété

### Phases futures (non fermées)

| Ticket | Phase | Description | Statut |
|---|---|---|---|
| KEY-289 | AR.5 | Satisfaction instrumentation (CSAT/feedback) | Futur |
| KEY-290 | AR.6 | Milestone tracking enrichment | Futur |
| KEY-291 | AR.7 | message_source enrichment (AI_ASSISTED, AUTOPILOT) | Futur |

---

## Gaps restants

1. **AR.5 — Satisfaction** : Aucune source CSAT/NPS/feedback n'existe. La satisfaction est affichée comme `Bientôt disponible`. Nécessite une instrumentation dédiée.
2. **AR.6 — Milestones** : Les milestones actuels sont détectés automatiquement mais restent basiques. Un tracking dédié permettrait des milestones plus riches.
3. **AR.7 — message_source** : Le champ `message_source` ne contient pas `AI_ASSISTED` ni `AUTOPILOT` en PROD. Un enrichissement est nécessaire pour le breakdown human/AI/autopilot des réponses.
4. **DEV URL fallbacks SSR** : 2 routes SSR (`/api/auth/logout`, `/api/billing/ai-actions-checkout`) contiennent `client-dev.keybuzz.io` comme fallback si `NEXTAUTH_URL` n'est pas défini. Pré-existant, non atteint en PROD. Dette technique mineure.

---

## Deployments réels

| Service | Pod | Image runtime | Restarts | Health | Verdict |
|---|---|---|---|---|---|
| API PROD | keybuzz-api-8647948555-7mlrg | v3.5.148-performance-sav-metrics-prod | 0 | ✅ 200 OK | ✅ |
| Client PROD | keybuzz-client-7f6944d74-jh5jz | v3.5.171-performance-sav-dashboard-prod | 0 | ✅ 307/200 | ✅ |

---

*Date : 9 mai 2026*
*Phase : PH-SAAS-T8.12AR.4-DASHBOARD-PERFORMANCE-SAV-PROD-PROMOTION-01*
*Linear : KEY-287*
*Auteur : Cursor Agent*
