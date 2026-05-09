# PH-SAAS-T8.12AR.3 - Dashboard Performance SAV - Client UI DEV

> Date : 2026-05-09
> Auteur : Cursor Agent
> Ticket : KEY-288 | Parent : KEY-282
> Dependance : KEY-286 / AR.2 API metrics foundation
> Verdict : **GO DEV UI READY**

---

## Resume

Page Client `/performance` creee en DEV, consommant l'API AR.2 `GET /stats/performance`, avec KPI cards, courbes, panel IA, milestones, limitations, et satisfaction explicitement affichee "Bientot disponible". PROD inchangee.

---

## 0. Preflight

| Element | Valeur | Status |
|---|---|---|
| Client source | `ph148/onboarding-activation-replay` @ `5e24487` | OK |
| Infra source | `main` @ `0ca2fd0` | OK |
| API DEV runtime | `v3.5.162-performance-sav-metrics-dev` (AR.2) | OK |
| Client DEV runtime avant | `v3.5.170-shopify-visible-disabled-channels-dev` | OK |
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | Inchangee |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | Inchangee |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | Hors scope |
| Website PROD | `v0.6.12-linkedin-insight-seo-prod` | Hors scope |
| Admin PROD | `v2.12.2-media-buyer-lp-domain-qa-prod` | Hors scope |
| OW PROD | `v3.5.165-escalation-flow-prod` | Hors scope |

---

## 1. Source Lock / Baselines Client

| Baseline Client | Fichier / signal | Resultat |
|---|---|---|
| Shopify visible disabled | app/channels/page.tsx, OnboardingHub.tsx | Present |
| Amazon inbound guide | AmazonInboundSetupGuide.tsx | Present |
| No-reask client | AISuggestionSlideOver.tsx (KEY-256) | Present |
| Author name UX | MessageBubble.tsx, MessageSourceBadge.tsx | Present |
| Demo gating | useDemoMode.ts | Present |
| Tracking build args | Dockerfile (GA4, Meta, sGTM, TikTok, LinkedIn) | Present |

---

## 2. Audit Architecture Dashboard Client

| Surface | Fichier | Reutilisable ? | Risque |
|---|---|---|---|
| Dashboard page | app/dashboard/page.tsx | Pattern useTenant() | Aucun |
| KpiCards | src/features/dashboard/components/KpiCards.tsx | Design pattern | Aucun |
| DashboardSkeleton | src/features/dashboard/components/DashboardSkeleton.tsx | Pattern loading | Aucun |
| ClientLayout nav | src/components/layout/ClientLayout.tsx | Ajout nav item | Minimal |
| BFF stats pattern | app/api/stats/conversations/route.ts | Pattern proxy | Aucun |
| TenantProvider | src/features/tenant/TenantProvider.tsx | useTenant() | Aucun |
| Chart library | Aucune | CSS/div charts crees | Aucun |

**Decision** : Creer `/performance` comme route separee avec son propre BFF, suivant le pattern existant des routes stats. Navigation ajoutee apres "IA Performance" dans la sidebar.

---

## 3. Contrat UI / Data Mapping

| API field | UI label | Format | Limitation affichee |
|---|---|---|---|
| kpis.messagesReceived.value | Messages recus | Nombre + delta | Non |
| kpis.repliesSent.value | Reponses envoyees | Nombre + delta | Non |
| kpis.medianFirstResponseSeconds.value | Temps median de reponse | Xh Xmin / Xmin / Xs | Coverage si < 100% |
| kpis.aiAdoptionRate.value | Adoption IA | Pourcentage | N utilises / N suggestions |
| kpis.satisfactionRate.value | Satisfaction client | "Bientot disponible" | "Instrumentation prevue (AR.5)" |
| aiMetrics.* | Panel IA | Nombre par ligne | Non |
| series.messagesReceived | Courbe messages recus | Bar chart CSS | Non |
| series.repliesSent | Courbe reponses envoyees | Bar chart CSS | Non |
| milestones | Jalons | Timeline | Non |
| limitations | Limitations connues | Liste | Affichees integralement |

---

## 4. No Fake Metrics Checks

| Signal | Attendu | Resultat |
|---|---|---|
| satisfactionRate numerique | Absent | OK ("Bientot disponible") |
| Mock data / fake | Absent | OK |
| Hardcoded tenant | Absent | OK |
| Hardcoded chiffre | Absent | OK |
| Event tracking ajoute | Absent | OK |
| Mutation API | Absent | OK |
| localStorage tenant arbitraire | Absent | OK |
| Input tenantId utilisateur | Absent | OK |

---

## 5. Patch Client

| Fichier | Changement | Risque |
|---|---|---|
| `app/performance/page.tsx` | NOUVEAU - Page Performance SAV (450+ lignes) | Aucun |
| `app/api/stats/performance/route.ts` | NOUVEAU - BFF proxy vers API /stats/performance | Aucun |
| `src/components/layout/ClientLayout.tsx` | +1 nav item + TrendingUp import | Minimal |
| `src/lib/i18n/I18nProvider.tsx` | +1 traduction nav.performance | Minimal |

### Composants crees dans la page

- **KpiCard** : carte KPI avec titre, valeur, icone, couleur, delta
- **MiniBarChart** : bar chart CSS avec tooltips hover (pas de librairie externe)
- **DeltaBadge** : badge trend up/down/neutre
- **AiMetricRow** : ligne metrique panel IA
- **Skeleton** : etat de chargement
- **EmptyState** : tenant sans donnees

---

## 6. Tests Source

| Test | Attendu | Resultat |
|---|---|---|
| TSC --noEmit | 0 erreur | OK |
| Hardcoding check | Aucun tenant/email/nom | OK |
| Fake metrics check | Aucun faux CSAT/satisfaction numerique | OK |
| Tenant check | currentTenantId via useTenant() uniquement | OK |
| No tenant input | Aucun champ de saisie tenant | OK |
| Mutation check | Aucune mutation POST/PUT/PATCH/DELETE | OK |
| Event tracking check | Aucun tracking ajoute | OK |

---

## 7. Build DEV

| Element | Valeur |
|---|---|
| Commit Client | `c8e0ffe` |
| Tag DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.171-performance-sav-dashboard-dev` |
| Digest | `sha256:8c971fba074f1041fd4115121a1c1f0b1e0767cc52ebbd17694d952dfe417102` |
| Rollback DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.170-shopify-visible-disabled-channels-dev` |
| Build args | NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io, NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io, NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977 |
| Pre-build-check | TSC OK, pas de hardcoding, pas de fake metrics |

---

## 8. GitOps DEV

| Env | Image avant | Image apres | Rollback |
|---|---|---|---|
| Client DEV | `v3.5.170-shopify-visible-disabled-channels-dev` | `v3.5.171-performance-sav-dashboard-dev` | `v3.5.170-shopify-visible-disabled-channels-dev` |

Commit infra : `0fce232` — `gitops(dev): Client performance-sav-dashboard v3.5.171 (AR.3 KEY-288)`

---

## 9. Validation Runtime DEV

| Test | Attendu | Resultat |
|---|---|---|
| GET /performance (unauthenticated) | 307 redirect | 307 (auth guard OK) |
| GET /dashboard (unauthenticated) | 307 redirect | 307 (idem) |
| GET /inbox (unauthenticated) | 307 redirect | 307 (idem) |
| GET /channels (unauthenticated) | 307 redirect | 307 (idem) |
| API /stats/performance direct | 200 + data | 200, received=316, satisfaction=null |
| Client DEV runtime | v3.5.171-performance-sav-dashboard-dev | Confirme |
| Login page render | Formulaire visible | OK (screenshot) |

Note : La validation visuelle complete de `/performance` avec donnees reelles necessite une session authentifiee → QA Ludovic.

---

## 10. PROD Unchanged

| Service | Image attendue | Image runtime | Match |
|---|---|---|---|
| API PROD | v3.5.147-auto-assignment-after-reply-prod | v3.5.147-auto-assignment-after-reply-prod | OK |
| Client PROD | v3.5.170-shopify-visible-disabled-channels-prod | v3.5.170-shopify-visible-disabled-channels-prod | OK |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | OK |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | v0.6.12-linkedin-insight-seo-prod | OK |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | OK |
| OW PROD | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | OK |

---

## 11. AI Feature Parity / Anti-Regression

| Feature | Source | Resultat | Verdict |
|---|---|---|---|
| No-reask client AP.1 | AISuggestionSlideOver.tsx | Present (KEY-256 comments) | OK |
| Brouillon IA client | AI suggestion slide-over | Non modifie | OK |
| Author name UX AP.2.2 | MessageBubble.tsx | Present | OK |
| Auto-assignment display | Conversation context | Non modifie | OK |
| Demo gating | useDemoMode.ts | Present | OK |
| Shopify disabled visible | channels page | Present (KEY-276) | OK |
| Amazon guide | AmazonInboundSetupGuide.tsx | Present | OK |
| Aucun auto-send | Aucune modification outbound | OK | OK |
| STARTER KBActions gate | ClientLayout nav filter | Non modifie | OK |
| Tracking build args | Dockerfile (GA4, Meta, sGTM, TikTok, LinkedIn) | Preserves | OK |

---

## 12. Non-Regression Technique

| Surface | Attendu | Resultat |
|---|---|---|
| API PROD | Inchangee | OK |
| API DEV (AR.2) | Intacte | OK (200 avec donnees) |
| Client PROD | Inchangee | OK |
| Backend | Non touche | OK |
| Admin | Non touche | OK |
| Website | Non touche | OK |
| OW | Non touche | OK |
| Billing | Non touche | OK |
| Tracking | Non touche (build args preserves) | OK |
| CAPI | Non touche | OK |
| DB | Aucune mutation | OK |

---

## 13. Linear

### KEY-288
- Page creee : `/performance`
- BFF route : `/api/stats/performance`
- Navigation ajoutee dans sidebar
- Commit Client : `c8e0ffe`
- Tag DEV : `v3.5.171-performance-sav-dashboard-dev`
- Digest : `sha256:8c971fba074f1041fd4115121a1c1f0b1e0767cc52ebbd17694d952dfe417102`
- Satisfaction = "Bientot disponible" (pas de faux CSAT)
- API AR.2 consommee via BFF
- Tenant via contexte auth uniquement
- QA Ludovic necessaire avant AR.4

### KEY-282
- AR.3 UI ready in DEV
- QA Ludovic necessaire
- AR.4 PROD promotion apres validation
- Satisfaction et message_source restent dans AR.5/AR.7

---

## 14. Rollback DEV

Si incident, modifier `k8s/keybuzz-client-dev/deployment.yaml` :
```yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.170-shopify-visible-disabled-channels-dev
```
Puis :
```bash
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m "rollback(dev): Client to v3.5.170 (revert AR.3)"
git push origin main
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 15. Confirmations

- 0 PROD change
- 0 DB mutation
- 0 fake KPI
- 0 fake CSAT
- 0 billing/tracking/CAPI drift
- 0 PII
- 0 event tracking ajoute
- 0 modification API
- satisfaction = "Bientot disponible" (non numerique)
- tenant via contexte auth uniquement
- aucun champ tenantId saisissable

---

## 16. Description UI

### Page `/performance`

**Header** : Titre "Performance SAV" + sous-titre + selecteur de periode (7j/30j/90j/Tout) + bouton refresh

**KPI Cards** (5 cartes en grille responsive) :
1. Messages recus (bleu) - avec delta vs periode precedente
2. Reponses envoyees (emeraude) - avec delta
3. Temps median de reponse (ambre) - avec coverage si partielle
4. Adoption IA (violet) - avec ratio suggestions/utilisations
5. Satisfaction client (gris) - "Bientot disponible" + note AR.5

**Courbes** (2 bar charts CSS cote a cote) :
- Messages recus par jour/semaine
- Reponses envoyees par jour/semaine
- Tooltips au hover

**Panel IA** : Suggestions generees, brouillons appliques/modifies/rejetes, reponses autopilot, auto-escalations

**Jalons** : Timeline chronologique des premieres actions (canal, message, reponse, suggestion IA, brouillon IA)

**Limitations** : Section ambre avec liste des limitations connues

**Etats vides** : Illustration + texte encourageant si aucune donnee

---

## Verdict Final

**GO DEV UI READY**

DASHBOARD PERFORMANCE SAV UI READY IN DEV - CLIENT PERFORMANCE PAGE CREATED - API AR.2 CONSUMED WITH CURRENT TENANT ONLY - KPI CARDS / MESSAGE AND REPLY CURVES / AI PANEL / MILESTONES / HONEST EMPTY STATES AVAILABLE - SATISFACTION DISPLAYED AS NOT INSTRUMENTED - NO FAKE METRICS - NO PII - NO DB MUTATION - NO BILLING/TRACKING/CAPI DRIFT - PROD UNCHANGED - READY FOR LUDOVIC QA BEFORE AR.4 PROD PROMOTION
