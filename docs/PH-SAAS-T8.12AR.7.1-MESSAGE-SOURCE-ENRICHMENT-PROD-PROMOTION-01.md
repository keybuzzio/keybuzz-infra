# PH-SAAS-T8.12AR.7.1 — MESSAGE SOURCE ENRICHMENT PROD PROMOTION

**Verdict : GO PROD**

> Date : 2026-05-09
> Linear : KEY-291
> Parent : KEY-282
> Environnement : PROD
> Dépendance validée : PH-SAAS-T8.12AR.7 (DEV — GO DEV FIX READY)

---

## Résumé

Promotion PROD de l'enrichissement `message_source` validé en DEV.
Les futurs messages outbound distinguent `HUMAN` (réponse manuelle) et `AI_ASSISTED` (suggestion IA validée par humain). Les messages legacy restent inchangés. Aucun backfill, aucun auto-send, aucune mutation historique.

---

## Sources relues

- `keybuzz-infra/docs/PH-SAAS-T8.12AR.7-MESSAGE-SOURCE-ENRICHMENT-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AR.4-DASHBOARD-PERFORMANCE-SAV-PROD-PROMOTION-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AR.1-DASHBOARD-PERFORMANCE-SAV-TRUTH-AUDIT-AND-DESIGN-01.md`

---

## Preflight

| Repo | Branche attendue | Branche réelle | HEAD | Verdict |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | `03818fea` | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | `ad0cb6b` | OK |
| keybuzz-infra | main | main | `3640f3f` | OK |

### Baselines PROD avant

| Service | Image PROD avant | Doit changer ? |
|---|---|---|
| API | v3.5.148-performance-sav-metrics-prod | **OUI** |
| Client | v3.5.171-performance-sav-dashboard-prod | **OUI** |
| Backend | v1.0.47-cross-env-guard-fix-prod | NON |
| Website | v0.6.12-linkedin-insight-seo-prod | NON |
| Admin | v2.12.2-media-buyer-lp-domain-qa-prod | NON |
| OW | v3.5.165-escalation-flow-prod | NON |

Toutes les baselines conformes.

---

## Vérification source API

| Point API | Preuve | Résultat |
|---|---|---|
| Whitelist stricte | `ALLOWED_SOURCES = ['HUMAN', 'AI_ASSISTED']` L411 | OK |
| Fallback HUMAN | `clientMessageSource && ALLOWED_SOURCES.includes(...)` L412 | OK |
| Pas de trust arbitraire | Validation avant usage | OK |
| author_name préservé | `formatAgentDisplayName` toujours utilisé L403-406 | OK |
| auto-assignment préservé | `resolvedAgentUserId` toujours utilisé L523 | OK |
| lifecycle préservé | Aucun changement au workflow status | OK |
| No backfill | Aucun UPDATE/DELETE sur messages existants | OK |
| No auto-send | Aucune logique d'envoi automatique ajoutée | OK |
| /stats/performance compatible | Limitation mise à jour, fallback legacy actif | OK |
| No PII | Aucune PII ajoutée | OK |

---

## Vérification source Client

| Point Client | Preuve | Résultat |
|---|---|---|
| aiAssisted tracké | `useState(false)` L344, set true sur insert IA L1577 | OK |
| sendReply transmet source | `message_source: messageSource` dans body L247 | OK |
| Reset après envoi | `setAiAssisted(false)` L738 | OK |
| Réponse manuelle = HUMAN | Pas de source envoyée si !aiAssisted | OK |
| Template picker = HUMAN | TemplatePickerSlideOver non modifié | OK |
| No UX trompeuse | Aucun badge ou label ajouté | OK |
| No tracking ajouté | Diff propre, aucun pixel modifié | OK |
| No fake data | Aucune donnée demo/fake | OK |
| No DEV URL | Aucune URL DEV dans source | OK |

---

## DB PROD read-only avant deploy

| Source | Count total | Count outbound | Commentaire |
|---|---|---|---|
| HUMAN | 1657 | 444 | Inclut legacy IA non taguées |
| SUPPLIER_CONTACT | 10 | 10 | Contact fournisseur |
| SUPPLIER_INBOUND | 6 | 0 | Réponse fournisseur entrante |
| **Total** | **1673** | **454** | |

Schema : `text NOT NULL DEFAULT 'HUMAN'`, aucune CHECK constraint.

---

## Builds PROD

| Service | Commit | Tag | Digest | Rollback |
|---|---|---|---|---|
| API | `03818fea` | v3.5.149-message-source-enrichment-prod | `sha256:0337e6464dbbb9a5d9b461df362170fa23d9013ca7f903c0e9dfc501c3304437` | v3.5.148-performance-sav-metrics-prod |
| Client | `ad0cb6b` | v3.5.172-message-source-enrichment-ux-prod | `sha256:6357ecd33559423c5db96345895b8a1b0a84405a5f04397a95b7e55c0643ceb8` | v3.5.171-performance-sav-dashboard-prod |

### Client PROD build args tracking

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

## GitOps PROD

| Manifest | Image avant | Image après |
|---|---|---|
| k8s/keybuzz-api-prod/deployment.yaml | v3.5.148-performance-sav-metrics-prod | **v3.5.149-message-source-enrichment-prod** |
| k8s/keybuzz-client-prod/deployment.yaml | v3.5.171-performance-sav-dashboard-prod | **v3.5.172-message-source-enrichment-ux-prod** |

Commit infra : `e722fd6` — poussé sur `main`

---

## Deploy + Runtime

| Service | Pod | Image runtime | Restarts | Health | Verdict |
|---|---|---|---|---|---|
| API PROD | keybuzz-api-569ff89746-8g2f7 | v3.5.149-message-source-enrichment-prod | 0 | `{"status":"ok"}` | OK |
| Client PROD | keybuzz-client-7ddc78fb98-hm2fd | v3.5.172-message-source-enrichment-ux-prod | 0 | Running | OK |

---

## Validation structurelle PROD

### API runtime

| Signal | Résultat |
|---|---|
| WHITELIST_PRESENT (AI_ASSISTED + ALLOWED_SOURCES) | true |
| NO_BACKFILL | true |
| NO_AUTOSEND | true |
| /stats/performance HTTP 200 | OK |
| Limitation AR.7 présente | `replies_breakdown_improving` |
| Satisfaction null | null |

### Client runtime

| Signal | Résultat |
|---|---|
| AI_ASSISTED dans bundle | true |
| message_source dans bundle | true |
| GA4 (G-R3QQDYEBFG) | true |
| Meta (1234164602194748) | true |
| sGTM (t.keybuzz.pro) | true |
| TikTok (D7PT12JC77U44OJIPC10) | true |
| LinkedIn (9969977) | true |
| DEV_URL_LEAK | **false** (aucune fuite) |
| PROD_API (api.keybuzz.io) | true |
| Purchase browser | **false** (absent = correct) |
| CompletePayment browser | **false** (absent = correct) |

---

## DB PROD read-only après deploy

| Source | Avant | Après | Delta | Verdict |
|---|---|---|---|---|
| HUMAN | 1657 | 1657 | 0 | OK |
| SUPPLIER_CONTACT | 10 | 10 | 0 | OK |
| SUPPLIER_INBOUND | 6 | 6 | 0 | OK |
| **Total** | **1673** | **1673** | **0** | **OK** |

Aucune mutation DB pendant le deploy.

---

## Validation fonctionnelle PROD

Test utilisateur PROD contrôlé : **en attente QA Ludovic**.
Structural PROD live, runtime user QA pending.

---

## Dashboard Performance SAV

| Surface | Attendu | Résultat |
|---|---|---|
| /stats/performance répond | HTTP 200 | OK |
| Limitation AR.7 | `replies_breakdown_improving` | OK |
| Satisfaction | null | OK |
| No fake metrics | Aucune | OK |

---

## Non-régression

| Baseline | Résultat |
|---|---|
| author_name Prénom.N | Préservé (formatAgentDisplayName inchangé) |
| auto-assignment after reply | Préservé (resolvedAgentUserId inchangé) |
| lifecycle status | Préservé (aucun changement) |
| no-reask | Préservé (aucun changement) |
| Dashboard /performance | Accessible, KPIs réels |
| Backend PROD | v1.0.47 inchangé |
| Website PROD | v0.6.12 inchangé |
| Admin PROD | v2.12.2 inchangé |
| OW PROD | v3.5.165 inchangé |

---

## Tracking / Billing / CAPI

| Surface | Attendu | Résultat |
|---|---|---|
| GA4 présent | true | OK |
| sGTM présent | true | OK |
| Meta présent | true | OK |
| TikTok présent | true | OK |
| LinkedIn présent | true | OK |
| Purchase browser absent | false | OK |
| CompletePayment browser absent | false | OK |
| Stripe mutation | Aucune | OK |
| Billing change | Aucun | OK |
| CAPI event | Aucun | OK |

---

## Rollback PROD (non exécuté)

```bash
# API — modifier k8s/keybuzz-api-prod/deployment.yaml
# image: ghcr.io/keybuzzio/keybuzz-api:v3.5.148-performance-sav-metrics-prod
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod

# Client — modifier k8s/keybuzz-client-prod/deployment.yaml
# image: ghcr.io/keybuzzio/keybuzz-client:v3.5.171-performance-sav-dashboard-prod
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## Linear

| Ticket | Action | Statut |
|---|---|---|
| KEY-291 (AR.7) | PROD deployed, tags + digests documentés | **Done** |
| KEY-282 (parent) | AR.7 PROD done, AR.5/AR.6 restent | Ouvert |
| KEY-290 (AR.5 satisfaction) | -- | Non fermé |
| KEY-289 (AR.6 milestones) | -- | Non fermé |

---

## Gaps restants

1. **QA fonctionnelle PROD** : Ludovic doit tester sur `client.keybuzz.io` :
   - Réponse manuelle → vérifier `message_source=HUMAN`
   - Suggestion IA → insérer → envoyer → vérifier `message_source=AI_ASSISTED`
2. **AR.5 satisfaction** : non instrumentée, `null` dans le dashboard
3. **AR.6 milestones** : non instrumenté
4. **Normalisation autopilot** : `'autopilot'` (lowercase legacy) vs `'AI_AUTOPILOT'` (contrat futur) — documenté, pas de changement fonctionnel nécessaire

---

## Conclusion

MESSAGE_SOURCE ENRICHMENT LIVE IN PROD — FUTURE OUTBOUND REPLIES DISTINGUISH HUMAN AND AI_ASSISTED — LEGACY MESSAGES PRESERVED — NO DESTRUCTIVE BACKFILL — AUTHOR_NAME / AUTO_ASSIGNMENT / NO_REASK / LIFECYCLE BASELINES PRESERVED — DASHBOARD PERFORMANCE SAV SOURCE TRUTH IMPROVED — NO AUTO_SEND ADDED — NO FAKE METRICS — NO DB HISTORICAL MUTATION — NO BILLING/TRACKING/CAPI DRIFT — API/CLIENT GITOPS STRICT
