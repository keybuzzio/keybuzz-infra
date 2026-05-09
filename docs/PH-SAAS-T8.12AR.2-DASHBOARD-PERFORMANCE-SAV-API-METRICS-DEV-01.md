# PH-SAAS-T8.12AR.2 - Dashboard Performance SAV - API Metrics DEV

> Date : 2026-05-09
> Auteur : Cursor Agent
> Ticket : KEY-286 | Parent : KEY-282
> Verdict : **GO DEV API READY**

---

## Résumé

Endpoint API read-only `GET /stats/performance` créé en DEV, fournissant des métriques tenant-scoped pour le futur Dashboard Performance SAV. PROD inchangée.

---

## 0. Préflight

| Élément | Valeur | Status |
|---|---|---|
| API source | `ph147.4/source-of-truth` @ `9521fb35` | OK |
| Infra source | `main` @ `1ef99f5` | OK |
| API DEV runtime avant | `v3.5.161-auto-assignment-after-reply-dev` | OK |
| API PROD runtime | `v3.5.147-auto-assignment-after-reply-prod` | Inchangée |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | Hors scope |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | Hors scope |
| Website PROD | `v0.6.12-linkedin-insight-seo-prod` | Hors scope |
| Admin PROD | `v2.12.2-media-buyer-lp-domain-qa-prod` | Hors scope |
| OW PROD | `v3.5.165-escalation-flow-prod` | Hors scope |

---

## 1. Source Lock / Baselines AP

| Baseline | Signal | Résultat |
|---|---|---|
| AP.1F no-reask | `reask` patterns dans ai-assist-routes, shared-ai-context, autopilot/engine | Présent |
| AP.1F stored draft invalidation | `stale_draft` / `invalidat` dans ai-assist-routes | Présent |
| AP.2.2 author_name réel | `author_name` dans messages/routes.ts (lignes 278, 412, 445, 452) | Présent |
| AP.2.4 lifecycle resolved clear escalation | `escalation_status` reset à `none` on resolve (ligne 757) | Présent |
| AP.2.7 auto-assignment | `assigned_agent_id` UPDATE après reply (ligne 527, 937) | Présent |
| Human validation | `safe_mode`, `validated_by` dans ai/routes.ts | Présent |

---

## 2. Audit Endpoints Existants

| Endpoint existant | Fichier | Réutilisable ? | Risque |
|---|---|---|---|
| `GET /stats/overview` | stats/routes.ts | Non (scope différent) | Aucun |
| `GET /stats/conversations` | stats/routes.ts | Non | Aucun |
| `GET /stats/sla` | stats/routes.ts | Non | Aucun |
| `GET /stats/messages` | stats/routes.ts | Non | Aucun |
| `GET /stats/channels` | stats/routes.ts | Non | Aucun |
| `GET /stats/backlog` | stats/routes.ts | Non | Aucun |
| `GET /stats/agent/kpi` | stats/routes.ts | Non | Aucun |
| `GET /ai/performance-metrics` | ai-policy-debug-routes.ts | Non (admin debug) | Aucun |

**Décision** : Créer `GET /stats/performance` comme endpoint séparé dans le namespace `/stats` existant, avec son propre service dédié. Le endpoint est distinct des routes existantes et ne les modifie pas.

---

## 3. Contrat API

```json
{
  "range": "30d",
  "timezone": "UTC",
  "generatedAt": "2026-05-09T07:48:27.123Z",
  "kpis": {
    "messagesReceived": { "value": 316, "previous": null, "delta": null, "confidence": "high" },
    "repliesSent": { "value": 0, "previous": null, "delta": null, "confidence": "high" },
    "medianFirstResponseSeconds": { "value": null, "coverage": 0, "sampleSize": 0, "confidence": "low", "reason": "insufficient_replied_conversations" },
    "aiAdoptionRate": { "value": 0, "basis": "drafts_used_over_suggestions", "suggestionsGenerated": 5, "draftsUsed": 0, "confidence": "medium" },
    "satisfactionRate": { "value": null, "confidence": "none", "reason": "satisfaction_not_instrumented" }
  },
  "aiMetrics": {
    "suggestionsGenerated": 5,
    "draftsApplied": 0,
    "draftsModified": 0,
    "draftsDismissed": 0,
    "adoptionRate": 0,
    "autopilotCompletions": 0,
    "autopilotSkipped": 1,
    "autoEscalations": 0,
    "falsePromisesDetected": 0
  },
  "series": {
    "interval": "day",
    "messagesReceived": [{ "date": "2026-04-10", "value": 12 }],
    "repliesSent": [{ "date": "2026-04-10", "value": 0 }],
    "medianFirstResponseSeconds": [{ "date": "2026-04-10", "value": null, "sampleSize": 0 }]
  },
  "milestones": [
    { "type": "first_message_received", "label": "Premier message recu", "date": "..." },
    { "type": "first_reply_sent", "label": "Premiere reponse envoyee", "date": "..." },
    { "type": "first_channel_connected", "label": "Premier canal connecte", "date": "..." },
    { "type": "first_ai_suggestion", "label": "Premiere suggestion IA", "date": "..." },
    { "type": "first_ai_draft_used", "label": "Premier brouillon IA utilise", "date": "..." }
  ],
  "limitations": [
    "frt_low_coverage: only 0% of conversations have a first response (0/125)",
    "frt_includes_nights_weekends: business hours are not excluded from response time",
    "replies_breakdown_approximate: AI-assisted replies are correlated via ai_action_log, not tagged in message_source (AR.7)",
    "satisfaction_not_instrumented: no CSAT/feedback source exists (AR.5)"
  ]
}
```

| Champ | Source | Fiabilité | Limitation |
|---|---|---|---|
| messagesReceived | `messages WHERE direction='inbound' AND message_source='HUMAN'` | Haute | Aucune |
| repliesSent | `messages WHERE direction='outbound'` | Haute | Inclut humain + IA sans distinction |
| medianFirstResponseSeconds | `conversations.first_response_at - created_at` | Moyenne | Coverage partielle, inclut nuits/WE |
| aiAdoptionRate | `ai_action_log` (drafts_used / suggestions) | Haute si suggestions > 0 | Aucune si suggestions existent |
| satisfactionRate | **null** | None | Non instrumenté (AR.5) |
| series | Agrégation par jour/semaine | Haute | Idem que KPIs |
| milestones | MIN(created_at) des événements clés | Haute | Fiables uniquement si données existent |

---

## 4. No Fake Metrics Rules

| Métrique | Peut être affichée ? | Condition |
|---|---|---|
| Messages reçus | Oui | inbound tenant-scoped |
| Réponses envoyées | Oui | outbound tenant-scoped |
| FRT médian | Oui | coverage documentée |
| Adoption IA | Oui | source ai_action_log |
| Satisfaction | **Non** | AR.5 requis |
| Ventilation humain/IA précise | **Non** | AR.7 requis |

Vérifications appliquées :
- satisfaction jamais déduite depuis sentiment
- pas de "temps gagné" calculé
- pas de ratio estimé présenté comme vérité
- pas d'event tracking généré
- `satisfactionRate.value` = null partout

---

## 5. Patch API

| Fichier | Changement | Risque | Verdict |
|---|---|---|---|
| `src/modules/stats/performance-stats.service.ts` | NOUVEAU - Service read-only | Aucun | OK |
| `src/modules/stats/performance-stats.routes.ts` | NOUVEAU - Route GET /stats/performance | Aucun | OK |
| `src/app.ts` | +2 lignes (import + register) | Minimal | OK |

---

## 6. Tests Source / TSC

| Test | Attendu | Résultat |
|---|---|---|
| TSC --noEmit | 0 erreur | OK |
| Hardcoding check | Aucun tenant/email/nom | OK |
| PII check | Aucune PII dans réponse | OK |
| Mutation check | Aucun INSERT/UPDATE/DELETE | OK |
| Satisfaction check | value = null | OK |
| message_source modification | Aucune | OK |

---

## 7. Validation DEV DB

| Cas | Attendu | Résultat |
|---|---|---|
| Tenant avec données (ecomlg-001) 30d | 200 + données | 200, received=316 |
| Tenant avec données 7d | 200 | 200, received=55 |
| Tenant avec données 90d | 200, interval=week | 200, received=970, sent=53 |
| Tenant avec données all | 200 | 200, received=1181, sent=230, milestones=5 |
| Tenant sans données | 200 + zeros | 200, received=0, sent=0, satisfaction=null |
| Range invalide | 400 | 400 `invalid_range` |
| Tenant manquant | 400 | 400 `tenantId is required` |
| Satisfaction | null | null partout |

---

## 8. Build DEV

| Élément | Valeur |
|---|---|
| Commit API | `dac5b790` |
| Tag DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.162-performance-sav-metrics-dev` |
| Digest | `sha256:8511fbfb719f6e5d6c878311d12ca6af4e6ebee20c59139e1b3b92ca705d8839` |
| Rollback DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.161-auto-assignment-after-reply-dev` |
| Pre-build-check | TSC OK, pas de hardcoding, pas de PII |

---

## 9. GitOps DEV

| Env | Image avant | Image après | Rollback |
|---|---|---|---|
| API DEV | `v3.5.161-auto-assignment-after-reply-dev` | `v3.5.162-performance-sav-metrics-dev` | `v3.5.161-auto-assignment-after-reply-dev` |

Commit infra : `0ca2fd0` — `gitops(dev): API performance-sav-metrics v3.5.162 (AR.2 KEY-286)`

---

## 10. Validation Runtime DEV

| Test | Attendu | Résultat |
|---|---|---|
| Health API | 200 | 200 OK |
| Performance 30d | 200 + data | 200, received=316, satisfaction=null |
| Performance 7d | 200 | 200, received=55 |
| Performance 90d | 200, interval=week | 200, received=970 |
| Performance all | 200 | 200, received=1181 |
| Range invalide | 400 | 400 |
| Tenant manquant | 400 | 400 |
| Tenant vide | 200 zeros | 200, received=0, satisfaction=null |
| Satisfaction | null | null |
| PROD inchangée | v3.5.147 | Confirmé |

---

## 11. AI Feature Parity / Anti-Régression

| Feature | Source | Résultat | Verdict |
|---|---|---|---|
| No-reask AP.1F | ai-assist-routes.ts, shared-ai-context.ts | Présent | OK |
| Stored drafts invalidation | ai-assist-routes.ts | Présent | OK |
| author_name réel AP.2.2 | messages/routes.ts | Présent | OK |
| auto-assignment AP.2.7 | messages/routes.ts | Présent | OK |
| lifecycle resolved clear escalation AP.2.4 | messages/routes.ts | Présent | OK |
| human validation | ai/routes.ts (safe_mode) | Présent | OK |
| Aucun auto-send ajouté | Aucune modification outbound | OK | OK |
| message_source non modifié | Aucune modification | OK | OK |

---

## 12. Non-Régression Technique

| Surface | Attendu | Résultat |
|---|---|---|
| /stats/conversations | 200 | 200 OK |
| /stats/overview | 200 | 200 OK (2603 bytes) |
| billing | Non touché | OK |
| tracking | Non touché | OK |
| CAPI | Non touché | OK |
| outbound worker | Non touché | OK |
| Client | Non touché | OK |
| Website | Non touché | OK |
| Admin | Non touché | OK |
| PROD | Inchangée | Confirmé |

---

## 13. Linear

### KEY-286
- Endpoint créé : `GET /stats/performance?tenantId=xxx&range=7d|30d|90d|all`
- Commit API : `dac5b790`
- Tag DEV : `v3.5.162-performance-sav-metrics-dev`
- Digest : `sha256:8511fbfb719f6e5d6c878311d12ca6af4e6ebee20c59139e1b3b92ca705d8839`
- Satisfaction = null (AR.5 requis)
- message_source inchangé (AR.7 requis)
- PROD inchangée
- AR.3 peut démarrer

### KEY-282
- AR.2 API foundation ready in DEV
- AR.3 UI peut démarrer
- Satisfaction et message_source restent dans AR.5/AR.7

---

## 14. Rollback DEV

Si incident, modifier `k8s/keybuzz-api-dev/deployment.yaml` :
```yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.161-auto-assignment-after-reply-dev
```
Puis :
```bash
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-api-dev/deployment.yaml
git commit -m "rollback(dev): API to v3.5.161 (revert AR.2)"
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 15. Confirmations

- 0 PROD change
- 0 DB mutation
- 0 Stripe mutation
- 0 CAPI mutation
- 0 fake KPI
- 0 fake CSAT
- 0 PII
- 0 tracking event
- 0 email outbound
- 0 billing drift
- satisfactionRate.value = null
- message_source non modifié

---

## Verdict Final

**GO DEV API READY**

DASHBOARD PERFORMANCE SAV API READY IN DEV - TENANT-SCOPED READ-ONLY METRICS ENDPOINT CREATED - MESSAGES RECEIVED / REPLIES SENT / MEDIAN RESPONSE TIME / AI ADOPTION / RELIABLE MILESTONES AVAILABLE - SATISFACTION CORRECTLY NULL UNTIL AR.5 INSTRUMENTATION - MESSAGE_SOURCE UNCHANGED UNTIL AR.7 - NO FAKE METRICS - NO PII - NO DB MUTATION - NO BILLING/TRACKING/CAPI DRIFT - PROD UNCHANGED - AI/MESSAGING BASELINES PRESERVED - READY FOR CLIENT UI PHASE AR.3
