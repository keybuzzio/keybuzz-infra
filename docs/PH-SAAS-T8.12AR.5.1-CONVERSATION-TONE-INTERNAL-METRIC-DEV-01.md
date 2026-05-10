# PH-SAAS-T8.12AR.5.1 — Conversation Tone Internal Metric DEV

> Date : 2026-05-10
> Linear : KEY-292 / Parent KEY-290
> Phase : audit vérité + implémentation DEV
> Environnement : DEV uniquement — PROD inchangée

## VERDICT

**GO DEV FIX READY**

Un indicateur interne de tonalité des conversations est implémenté en DEV, basé sur des règles déterministes. Il remplace la carte grise "Satisfaction client — Bientôt disponible" par un signal honnêtement libellé. Prêt pour QA Ludovic.

---

## 0. Preflight

| Repo | Branche attendue | Branche réelle | HEAD | Verdict |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | fbb45c0c | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | ce1bdd2 | OK |
| keybuzz-infra | main | main | 0eac4c3 | OK |

| Service | Image DEV avant | Image PROD actuelle | Verdict |
|---|---|---|---|
| API DEV | v3.5.166-performance-sav-encoding-fix-dev | v3.5.150-performance-sav-milestones-prod | OK |
| Client DEV | v3.5.175-performance-sav-encoding-fix-dev | v3.5.173-performance-sav-milestones-ux-prod | OK |
| Backend PROD | — | v1.0.47-cross-env-guard-fix-prod | OK |
| OW PROD | — | v3.5.165-escalation-flow-prod | OK |

---

## 1. Audit signaux disponibles

### Sources auditées (sans mutation)

| Source | Signal | Type | Fiabilité | CSAT ? | Tonalité interne ? |
|---|---|---|---|---|---|
| conversations.escalation_status | escalated + reason | structurel | Haute | NON | OUI |
| conversations.sav_status | to_process/in_progress/waiting/closed | structurel | Haute | NON | OUI |
| conversations.sla_state | ok/breached | structurel | Haute | NON | OUI (partiel) |
| conversations.status | open/resolved/pending/escalated | structurel | Haute | NON | OUI |
| messages direction + count | Multi-inbound sans réponse | structurel | Haute | NON | OUI |
| conversations.first_response_at | Première réponse oui/non | structurel | Haute | NON | OUI |
| ai_action_log.autopilot_escalate | 1 event (ecomlg-001) | IA | Haute | NON | OUI |
| ai_action_log.AI_AUTO_ESCALATED | 0 events DEV | IA | Haute | NON | OUI |
| conversations.priority | 484 normal, 1 medium | structurel | Basse | NON | NON (inutile) |
| messages.message_source | HUMAN/AI_ASSISTED/autopilot | structurel | Haute | NON | NON (source, pas tonalité) |

### Données DEV (ecomlg-001)

- 485 conversations (390 open, 57 resolved, 37 pending, 1 escalated)
- 482 SLA breached, 3 ok
- 10 escalations (8 system/promise, 1 AI, 1 autre)
- 56 SAV (42 closed, 8 in_progress, 4 waiting, 2 to_process)
- 1185 inbound HUMAN, 221 outbound HUMAN
- Conversations avec 3+ inbound et 0 outbound : 10+
- FRT médian : 11.13h

### Conclusion audit

- **CSAT explicite : NON** — aucune table, colonne ou source de feedback client
- **Tonalité interne possible : OUI** — via signaux structurels (escalation, SAV, ratio messages)
- **Couverture estimée : ~100%** des conversations classifiables
- **Risque de faux positif : moyen** (signaux structurels ne captent pas toutes les nuances)

---

## 2. Définition produit

### Choix du nom

| Nom | Compréhension | Honnêteté | Risque confusion CSAT | Recommandation |
|---|---|---|---|---|
| **Tonalité des conversations** | Bonne | Haute | Faible | **RETENU** |
| Mécontentement détecté | Moyenne (trop négatif) | Haute | Faible | Acceptable |
| Friction client | Bonne | Haute | Faible | Acceptable |
| Qualité de traitement | Bonne | Haute | Moyen | Risque |
| Signal SAV | Moyenne (technique) | Haute | Faible | Non recommandé |

**Nom retenu : "Tonalité des conversations"**

Raisons :
- Compréhensible pour un marchand
- Honnête (ne prétend pas être un CSAT)
- Couvre positive/neutre/négative
- Faible risque de confusion

---

## 3. Design de calcul

### Option retenue : A — Règles déterministes uniquement

| Option | Données | Fiabilité | Coût | Risque | Recommandation |
|---|---|---|---|---|---|
| **A — Règles déterministes** | DB existantes | Moyenne | 0 | Faux positifs | **RETENU** |
| B — IA différée | LLM calls | Haute | Élevé (KBActions) | Coût | Future phase |
| C — Hybride | DB + LLM | Haute | Moyen | Complexité | Future phase |

### Règles de classification (par conversation)

Chaque conversation reçoit exactement UNE tonalité, dans cet ordre de priorité :

1. **NEGATIVE** (friction détectée) — au moins un de :
   - `escalation_status = 'escalated'`
   - `sav_status IN ('to_process', 'in_progress', 'waiting')`
   - 3+ messages inbound ET 0 message outbound (client ignoré)

2. **POSITIVE** (traitement fluide) :
   - `status = 'resolved'` ET aucun signal négatif

3. **UNKNOWN** (données insuffisantes) :
   - 1 seul message total ET pas de signal négatif/positif

4. **NEUTRAL** (en cours, pas de signal) :
   - Tout le reste

---

## 4. Contrat API

### Structure ajoutée à `GET /stats/performance`

```json
{
  "kpis": {
    "conversationTone": {
      "label": "Tonalité des conversations",
      "value": { "negative": 20, "neutral": 25, "positive": 0, "unknown": 77 },
      "negativeRate": 0.444,
      "coverage": 0.369,
      "sampleSize": 45,
      "total": 122,
      "confidence": "medium",
      "basis": "deterministic_rules",
      "reason": null
    },
    "satisfactionRate": {
      "value": null,
      "confidence": "none",
      "reason": "satisfaction_not_instrumented"
    }
  },
  "toneMetrics": {
    "negative": 20,
    "neutral": 25,
    "positive": 0,
    "unknown": 77,
    "total": 122,
    "classified": 45,
    "rules": ["escalation_detected", "sav_active_unresolved", "customer_ignored", "..."],
    "limitations": ["no_text_sentiment", "no_customer_feedback", "escalation_detection_partial"]
  }
}
```

| Champ | Type | Source | Fiabilité | Notes |
|---|---|---|---|---|
| conversationTone.value | object{4 numbers} | conversations + messages | Haute | Classif. déterministe |
| conversationTone.negativeRate | number | Calculé | Haute | negative / classified |
| conversationTone.coverage | number | Calculé | Haute | classified / total |
| conversationTone.sampleSize | number | Calculé | Haute | negative + neutral + positive |
| conversationTone.total | number | conversations count | Haute | Total dans range |
| conversationTone.confidence | string | Calculé | Haute | medium >= 20, low >= 5, none < 5 |
| conversationTone.basis | string | Constante | Haute | 'deterministic_rules' |
| toneMetrics.rules | string[] | Constante | Haute | 6 règles documentées |
| toneMetrics.limitations | string[] | Constante | Haute | 3 limitations documentées |

### Contraintes respectées

- Tenant-scoped : OUI (WHERE tenant_id = $1)
- Aucune PII : OUI (agrégats uniquement, pas de texte message)
- Range compatible : OUI (7d/30d/90d/all)
- Tenant vide : OUI (confidence=none, sampleSize=0)
- Pas de mutation DB : OUI (SELECT uniquement)
- satisfactionRate préservé : OUI (backward compat)

---

## 5. Patch API DEV

| Fichier | Changement | Risque | Validation |
|---|---|---|---|
| performance-stats.service.ts | +toneResult query (CASE/JOIN) | Faible | ✓ Runtime |
| performance-stats.service.ts | +tone processing block | Faible | ✓ Runtime |
| performance-stats.service.ts | +conversationTone KPI | Nul | ✓ additive |
| performance-stats.service.ts | +toneMetrics block | Nul | ✓ additive |
| performance-stats.service.ts | limitation updated | Nul | ✓ text only |

- Commit API : `0e26bfc3` — `feat(stats): add conversation tone deterministic metric (AR.5.1 KEY-292)`
- Branche : `ph147.4/source-of-truth`

---

## 6. Patch Client DEV

| Fichier | Changement | Risque | Validation |
|---|---|---|---|
| performance/page.tsx | +conversationTone interface | Nul | ✓ additive |
| performance/page.tsx | +toneMetrics interface | Nul | ✓ additive |
| performance/page.tsx | KpiCard satisfaction → ToneKpiCard | Faible | ✓ Runtime |
| performance/page.tsx | +ToneKpiCard component | Nul | ✓ new component |

- Commit Client : `0a7306a` — `feat(performance): replace satisfaction placeholder with conversation tone card (AR.5.1 KEY-292)`
- Branche : `ph148/onboarding-activation-replay`

---

## 7. Tests DEV

### Tests API

| Test | Attendu | Résultat |
|---|---|---|
| tenant actif 30d | 200 + conversationTone | ✓ 200 + tone present |
| tenant vide | confidence=none, sample=0 | ✓ Confirmé |
| satisfactionRate préservé | value=null, backward compat | ✓ Confirmé |
| anciens KPIs préservés | messagesReceived, repliesSent, FRT, AI | ✓ Tous présents |
| milestones préservés | 7 milestones | ✓ Confirmé |
| pas de PII | aucun texte message | ✓ Agrégats uniquement |
| toneMetrics.rules | 6 règles | ✓ Confirmé |
| toneMetrics.limitations | 3 limitations | ✓ Confirmé |

### Tests Client

| Page | Attendu | Résultat |
|---|---|---|
| /performance tenant actif | carte tonalité visible | ✓ Build réussi, ToneKpiCard rendu |
| /performance tenant vide | état vide honnête | ✓ "Données insuffisantes" si confidence=none |
| Satisfaction client carte | disparue | ✓ Remplacée par ToneKpiCard |

---

## 8. Build DEV

| Service | Commit | Tag DEV | Digest | Rollback |
|---|---|---|---|---|
| API | 0e26bfc3 | v3.5.167-conversation-tone-metric-dev | sha256:68c99e1c5d94... | v3.5.166-performance-sav-encoding-fix-dev |
| Client | 0a7306a | v3.5.176-conversation-tone-metric-ux-dev | sha256:4be6eeaafd5b... | v3.5.175-performance-sav-encoding-fix-dev |

---

## 9. Validation Runtime DEV

| Validation | Attendu | Résultat |
|---|---|---|
| API health | 200 ok | ✓ |
| /stats/performance 200 | oui | ✓ |
| conversationTone present | oui | ✓ |
| toneMetrics present | oui | ✓ |
| satisfactionRate backward compat | oui | ✓ |
| anciens blocs préservés | messagesReceived, repliesSent, FRT, AI, milestones | ✓ |
| limitations mises à jour | tone_not_csat remplace satisfaction_not_instrumented | ✓ |
| label honnête | "Tonalité des conversations" | ✓ |
| confidence=none pour tenant vide | oui | ✓ |
| PROD inchangée | oui | ✓ (images vérifiées) |

### Données runtime observées (ecomlg-001, 30d)

```
negative: 20
neutral: 25
positive: 0
unknown: 77
negativeRate: 0.444 (44.4% des conversations classifiées ont de la friction)
coverage: 0.369 (36.9% des conversations classifiables)
sampleSize: 45 (conversations classifiées non-unknown)
total: 122 (conversations dans le range 30d)
confidence: medium
```

Interprétation honnête : Sur 122 conversations des 30 derniers jours, 77 n'ont qu'un seul message (unknown). Parmi les 45 classifiées, 20 présentent des signaux de friction (escalation, SAV actif, client ignoré). 0 sont résolues sans friction (positive) car aucune conversation récente n'a été résolue.

---

## 10. No Fake Metrics / No Fake Events

| Risque | Contrôle | Résultat |
|---|---|---|
| Faux CSAT | Label = "Tonalité des conversations", NOT "Satisfaction client" | ✓ 0 faux CSAT |
| Questionnaire client | Aucun envoyé | ✓ 0 questionnaire |
| Email satisfaction | Aucun envoyé | ✓ 0 email |
| Message marketplace | Aucun envoyé | ✓ 0 message |
| Feedback inventé | Classification basée sur signaux structurels uniquement | ✓ 0 feedback faux |
| Mutation PROD | Aucune — images PROD inchangées | ✓ 0 mutation |
| Fake CAPI/GA4 | Aucun event tracking ajouté | ✓ 0 fake event |
| Checkout/paiement | Aucun | ✓ 0 checkout |
| Billing drift | Aucun | ✓ 0 billing change |
| Tracking drift | Aucun | ✓ 0 tracking change |

---

## 11. AI Feature Parity / Anti-régression

| Baseline | Source | Signal vérifié | Résultat |
|---|---|---|---|
| no-reask AP.1A-1F | Code non touché | Pas de régression | ✓ |
| author_name AP.2.2/2.3 | Code non touché | Pas de régression | ✓ |
| auto-assignment AP.2.7/2.8 | Code non touché | Pas de régression | ✓ |
| lifecycle AP.2.4-2.6 | Code non touché | Pas de régression | ✓ |
| message_source AR.7 | Champ préservé dans KPIs | ✓ messagesReceived filtre HUMAN | ✓ |
| milestones AR.6 | 7 milestones dans response | ✓ | ✓ |
| performance dashboard AR.2-6.2 | Tous KPIs/séries/milestones/limitations présents | ✓ | ✓ |
| Amazon connector | Code non touché | Pas de régression | ✓ |
| tracking server-side | Code non touché | Pas de régression | ✓ |

Seuls fichiers modifiés :
- `performance-stats.service.ts` : +66 lignes, -3 lignes (additif)
- `performance/page.tsx` : +51 lignes, -7 lignes (remplacement carte satisfaction)

Aucun autre module, route, worker, ou service modifié.

---

## 12. Non-régression PROD (read-only)

| Service | Image PROD avant | Image PROD après | Verdict |
|---|---|---|---|
| API | v3.5.150-performance-sav-milestones-prod | v3.5.150-performance-sav-milestones-prod | ✓ INCHANGÉE |
| Client | v3.5.173-performance-sav-milestones-ux-prod | v3.5.173-performance-sav-milestones-ux-prod | ✓ INCHANGÉE |
| Backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | ✓ INCHANGÉE |
| OW | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | ✓ INCHANGÉE |

---

## 13. Linear

### KEY-292
- Statut : In Review
- Commentaire : AR.5.1 implémenté en DEV. Indicateur "Tonalité des conversations" basé sur règles déterministes. API v3.5.167-conversation-tone-metric-dev, Client v3.5.176-conversation-tone-metric-ux-dev. Prêt pour QA Ludovic.

### KEY-290
- Commentaire : AR.5.1 terminé. Indicateur interne de tonalité implémenté en DEV. KEY-293 reste ouvert pour l'ingestion future de feedback officiel marketplace via APIs.

---

## 14. Gaps restants

| Gap | Description | Phase future |
|---|---|---|
| Pas de CSAT client réel | Aucune source de feedback client explicite | KEY-293 (APIs marketplace) |
| Pas d'ingestion API marketplace | Amazon, Octopia ne fournissent pas de CSAT accessible | KEY-293 |
| Pas de feedback Shopify | Connecteur Shopify non approuvé | Future |
| Pas de scoring IA | Classification textuelle par LLM non implémentée | Future phase |
| Règles déterministes limitées | Ne captent pas les nuances textuelles de frustration | Future phase |
| Faux positifs possibles | Un client ignoré (3+ inbound, 0 outbound) peut être un spam ou un doublon | Affinage futur |
| Faux négatifs possibles | Un client mécontent avec 1 seul message = unknown | Affinage futur |
| positive = 0 si aucune conversation résolue dans le range | Normal mais peut surprendre | UX copy à surveiller |
| confidence max = medium | Jamais "high" car basé sur des règles structurelles | Par design |

---

## 15. GitOps DEV

| Manifest | Image avant | Image après | Commit |
|---|---|---|---|
| k8s/keybuzz-api-dev/deployment.yaml | v3.5.166-performance-sav-encoding-fix-dev | v3.5.167-conversation-tone-metric-dev | dc2213a |
| k8s/keybuzz-client-dev/deployment.yaml | v3.5.175-performance-sav-encoding-fix-dev | v3.5.176-conversation-tone-metric-ux-dev | dc2213a |

Aucun manifest PROD modifié.

---

## 16. Rollback DEV

Si nécessaire :
- API : `kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.166-performance-sav-encoding-fix-dev -n keybuzz-api-dev`
- Client : `kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.175-performance-sav-encoding-fix-dev -n keybuzz-client-dev`

---

## Résumé final

```
PH-SAAS-T8.12AR.5.1 — TERMINÉ
Verdict : GO DEV FIX READY

Indicateur retenu : "Tonalité des conversations"
Méthode : règles déterministes (escalation, SAV actif, client ignoré, résolu)
API : v3.5.167-conversation-tone-metric-dev (commit 0e26bfc3)
Client : v3.5.176-conversation-tone-metric-ux-dev (commit 0a7306a)

Données observées (ecomlg-001, 30d) :
- 20 negative / 25 neutral / 0 positive / 77 unknown
- 44.4% friction sur 45 conversations classifiées
- Confidence : medium

Ce qui n'est PAS implémenté :
- CSAT client réel (aucune source)
- Questionnaire / survey
- Scoring IA textuel
- Feedback marketplace officiel

PROD strictement inchangée.
Prêt pour QA Ludovic.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AR.5.1-CONVERSATION-TONE-INTERNAL-METRIC-DEV-01.md
```
