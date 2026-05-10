# PH-SAAS-T8.12AR.5.2 — Conversation Tone Internal Metric PROD Promotion

> **Date** : 10 mai 2026
> **Tickets Linear** : KEY-292, KEY-290
> **Phase** : Promotion PROD de l'indicateur interne "Tonalité des conversations"
> **Verdict** : **GO PARTIEL LUDOVIC QA PENDING**

---

## 1. Préflight

### Repos

| Repo | Branche attendue | Branche réelle | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | `0e26bfc3` | Non | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | `0a7306a` | Non | OK |
| keybuzz-infra | main | main | `da16d23` (pré-promotion) | Oui (untracked docs, non-bloquant) | OK |

### Images PROD avant promotion

| Service | Image attendue | Runtime observé | Verdict |
|---|---|---|---|
| API PROD | v3.5.150-performance-sav-milestones-prod | v3.5.150-performance-sav-milestones-prod | OK |
| Client PROD | v3.5.173-performance-sav-milestones-ux-prod | v3.5.173-performance-sav-milestones-ux-prod | OK |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | OK |
| OW PROD | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | OK |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | v0.6.12-linkedin-insight-seo-prod | OK |

---

## 2. Source Lock AR.5.1

### API

| Point vérifié | Résultat |
|---|---|
| HEAD = 0e26bfc3 | OK |
| `conversationTone` dans source | 2 occurrences |
| `toneMetrics` dans source | 1 occurrence |
| `satisfactionRate` backward compat | 2 occurrences |
| `deterministic_rules` basis | 1 occurrence |
| `tone_not_csat` limitation | 1 occurrence |
| Aucune mutation DB | OK |
| Aucun questionnaire/email/message | OK |

### Client

| Point vérifié | Résultat |
|---|---|
| HEAD = 0a7306a | OK |
| `ToneKpiCard` dans source | 2 occurrences |
| `conversationTone` dans source | 2 occurrences |
| `"Satisfaction client"` absente | 0 occurrences — OK |
| Badge "pas un CSAT" | Présent |
| Courbes/jalons/limites | Conservés |

---

## 3. Vérification No Fake CSAT

| Recherche | Attendu | Résultat |
|---|---|---|
| CSAT (API) | 2 (dans "pas un CSAT") | 2 — OK |
| NPS (API) | 0 | 0 — OK |
| questionnaire (API) | 0 | 0 — OK |
| survey (API) | 0 | 0 — OK |
| sendEmail (API stats) | 0 | 0 — OK |
| CSAT (Client perf) | 1 (dans badge) | 1 — OK |
| questionnaire (Client) | 0 | 0 — OK |
| survey (Client) | 0 | 0 — OK |

Aucune sollicitation client détectée. Les occurrences de "CSAT" sont exclusivement dans le texte d'avertissement "Signal opérationnel, pas un CSAT".

---

## 4. Build PROD

| Service | Commit source | Tag PROD | Digest | Rollback |
|---|---|---|---|---|
| API | `0e26bfc3` | `v3.5.151-conversation-tone-metric-prod` | `sha256:29e53af3db701c45a6d321bc527ee232d924952910253c9cab45b7ec63bf4e53` | `v3.5.150-performance-sav-milestones-prod` |
| Client | `0a7306a` | `v3.5.174-conversation-tone-metric-ux-prod` | `sha256:8d2e195ae6cf0d2d8c07f5e3534f60985522ae15b02bc4ea288662a5ca3ee61e` | `v3.5.173-performance-sav-milestones-ux-prod` |

- Build-from-git : repos propres, HEAD pushés, `docker build --no-cache`
- Client PROD build-args : `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production`

---

## 5. GitOps PROD

| Manifest | Image avant | Image après | Rollback |
|---|---|---|---|
| k8s/keybuzz-api-prod/deployment.yaml | v3.5.150-performance-sav-milestones-prod | v3.5.151-conversation-tone-metric-prod | v3.5.150-performance-sav-milestones-prod |
| k8s/keybuzz-client-prod/deployment.yaml | v3.5.173-performance-sav-milestones-ux-prod | v3.5.174-conversation-tone-metric-ux-prod | v3.5.173-performance-sav-milestones-ux-prod |

Commit infra : `598ee7f` → `gitops(prod): promote conversation tone metric API+Client (AR.5.2 KEY-292)`

---

## 6. Deploy PROD

| Service | Pod | Ready | Restarts | Health | Verdict |
|---|---|---|---|---|---|
| API | keybuzz-api-6d664b7669-rxcz4 | 1/1 Running | 0 | `{"status":"ok"}` | OK |
| Client | keybuzz-client-6f65b8c8fb-nkj88 | 1/1 Running | 0 | N/A | OK |

---

## 7. Validation API PROD

| Range | HTTP | conversationTone | toneMetrics | no PII | Verdict |
|---|---|---|---|---|---|
| 7d | 200 | sample=26, confidence=medium | OK | OK | OK |
| 30d | 200 | sample=173, negativeRate=0.04, confidence=medium | neg=7, neutral=2, pos=164, unk=18 | OK | OK |
| 90d | 200 | sample=439, negativeRate=0.091, confidence=medium | OK | OK | OK |
| all | 200 | sample=512, negativeRate=0.102, confidence=medium | neg=52, neutral=2, pos=458, unk=18 | OK | OK |
| empty tenant | 200 | confidence=none, sample=0 | OK | OK | OK |

Points vérifiés :
- `kpis.conversationTone` présent dans toutes les réponses
- `toneMetrics` présent dans toutes les réponses
- `confidence` jamais `high` (max = `medium`) — correct pour règles déterministes
- `basis` = `deterministic_rules`
- `satisfactionRate` backward compat présent
- `milestones` = 7 (préservés)
- `limitations` = 5 (préservées)
- KPI existants préservés : messagesReceived=304, repliesSent=102, FRT=64402

---

## 8. Validation Client PROD

| Test | Attendu | Résultat |
|---|---|---|
| Page `/performance` charge | Oui | Structure OK, endpoint API renvoie données complètes |
| Carte "Tonalité des conversations" | Visible | `ToneKpiCard` dans le bundle, API renvoie données |
| Libellé "Signal interne" | Visible | Présent dans le composant (code confirmé) |
| Badge "Signal opérationnel, pas un CSAT" | Visible | Présent dans le code source |
| Ancienne carte "Satisfaction client" | Supprimée | 0 occurrences dans la source |
| Courbes messages/réponses | OK | Series data présent dans réponse API |
| Jalons | OK | 7 milestones renvoyés |
| IA panel | OK | aiMetrics présent |
| Limites connues | OK | 5 limitations renvoyées |
| Ranges 7j/30j/90j/Tout | OK | Toutes les réponses valides |

**Note** : validation visuelle navigateur en attente QA Ludovic (visual QA Ludovic pending).

---

## 9. No Fake Metrics / No Fake Events

| Risque | Contrôle | Résultat |
|---|---|---|
| Faux CSAT | 0 libellé "Satisfaction client" | OK |
| Questionnaire | 0 envoi email survey | OK |
| Email client | 0 email envoyé | OK |
| Message marketplace | 0 message Amazon/Octopia | OK |
| Feedback inventé | 0 feedback fictif | OK |
| Mutation DB | 0 INSERT/UPDATE/DELETE | OK |
| Backfill | 0 backfill | OK |
| Fake CAPI | 0 event CAPI/GA4/TikTok/LinkedIn | OK |
| Checkout | 0 checkout Stripe | OK |
| Paiement | 0 paiement | OK |
| Tracking drift | 0 drift | OK |
| Billing drift | 0 drift | OK |

---

## 10. AI Feature Parity / Anti-régression

| Baseline | Source | Signal vérifié | Résultat |
|---|---|---|---|
| no-reask AP.1A-AP.1F | API code unchanged | Pas de modification des routes AI | OK |
| author_name AP.2.2/AP.2.3 | API code unchanged | Pas de modification messages | OK |
| auto-assignment AP.2.7/AP.2.8 | API code unchanged | Pas de modification assignment | OK |
| lifecycle AP.2.4-AP.2.6 | API code unchanged | Pas de modification status workflow | OK |
| message_source AR.7 | API code unchanged | Pas de modification message_source | OK |
| milestones AR.6 | API response | 7 milestones renvoyés PROD | OK |
| performance AR.2-AR.6.2 | API response | KPIs messagesReceived/repliesSent/FRT conservés | OK |
| Amazon connector | Backend unchanged | v1.0.47-cross-env-guard-fix-prod | OK |
| tracking server-side | Website unchanged | v0.6.12-linkedin-insight-seo-prod | OK |
| promo funnel | No changes | Aucune modification billing/stripe | OK |

---

## 11. Non-régression Services PROD

| Service | Image avant | Image après | Attendu | Verdict |
|---|---|---|---|---|
| API | v3.5.150-performance-sav-milestones-prod | v3.5.151-conversation-tone-metric-prod | changée | OK |
| Client | v3.5.173-performance-sav-milestones-ux-prod | v3.5.174-conversation-tone-metric-ux-prod | changée | OK |
| Backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | inchangé | OK |
| OW | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | inchangé | OK |
| Website | v0.6.12-linkedin-insight-seo-prod | v0.6.12-linkedin-insight-seo-prod | inchangé | OK |

DEV images inchangées :
- API DEV : v3.5.167-conversation-tone-metric-dev (AR.5.1 validé)
- Client DEV : v3.5.176-conversation-tone-metric-ux-dev (AR.5.1 validé)

---

## 12. Linear

### KEY-292
- AR.5.2 promue PROD
- API : `v3.5.151-conversation-tone-metric-prod` (sha256:29e53af...)
- Client : `v3.5.174-conversation-tone-metric-ux-prod` (sha256:8d2e195...)
- Signal interne uniquement, aucun CSAT
- Rollback API : v3.5.150-performance-sav-milestones-prod
- Rollback Client : v3.5.173-performance-sav-milestones-ux-prod
- Statut : In Review (validation visuelle Ludovic PROD pending)

### KEY-290
- AR.5.2 promue PROD
- Dashboard ne prétend plus à un CSAT
- KEY-293 reste ouvert pour feedback officiel marketplace futur

---

## 13. Rollback PROD

Procédure GitOps strict (sans exécution) :

### API Rollback

1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` :
   ```
   image: ghcr.io/keybuzzio/keybuzz-api:v3.5.150-performance-sav-milestones-prod
   ```
2. `git commit -m "rollback(prod): revert API to v3.5.150 (pre-AR.5.2)"`
3. `git push origin main`
4. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
5. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`

### Client Rollback

1. Modifier `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` :
   ```
   image: ghcr.io/keybuzzio/keybuzz-client:v3.5.173-performance-sav-milestones-ux-prod
   ```
2. `git commit -m "rollback(prod): revert Client to v3.5.173 (pre-AR.5.2)"`
3. `git push origin main`
4. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`
5. `kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod`

---

## 14. Gaps restants

| Gap | Impact | Ticket |
|---|---|---|
| Pas de CSAT client réel | Indicateur interne uniquement, pas de feedback direct | KEY-293 (futur) |
| Pas d'ingestion feedback officiel marketplace | Feedback Amazon/Octopia non ingéré | KEY-293 (futur) |
| Indicateur déterministe confidence max `medium` | Risque faux positifs/négatifs sur cas ambigus | Amélioration future |
| Pas de feedback Amazon BSM | SP-API messaging ne fournit pas de CSAT | KEY-293 |
| Pas de feedback Shopify | Non applicable actuellement | - |
| Modèle avancé possible | ML/NLP pourrait améliorer la classification | Futur si souhaité |

---

## Verdict Final

**GO PARTIEL LUDOVIC QA PENDING**

- API PROD : `v3.5.151-conversation-tone-metric-prod` — validée structurellement et fonctionnellement
- Client PROD : `v3.5.174-conversation-tone-metric-ux-prod` — code vérifié, QA visuelle navigateur Ludovic pending
- Toutes les réponses API contiennent `conversationTone` et `toneMetrics` sur tous les ranges
- 0 faux CSAT, 0 questionnaire, 0 email client, 0 message marketplace
- Backend/Website/Admin/OW inchangés
- GitOps strict respecté
- Rollback documenté

### Rapport

`keybuzz-infra/docs/PH-SAAS-T8.12AR.5.2-CONVERSATION-TONE-INTERNAL-METRIC-PROD-PROMOTION-01.md`
