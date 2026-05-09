# PH-SAAS-T8.12AR.6.1 — Performance SAV UI Polish DEV

> Date : 2026-05-10
> Linear : KEY-289 / Parent KEY-282
> Phase : polish DEV avant promotion PROD
> Environnement : DEV uniquement

## VERDICT

**PERFORMANCE SAV UI POLISH READY IN DEV** — CURVES NO LONGER APPEAR BROKEN — AI KPI MADE HONEST AND UNDERSTANDABLE — FRENCH COPY POLISHED — MILESTONES PRESERVED — NON-INSTRUMENTED ITEMS HONEST — NO FAKE METRICS — NO DB MUTATION — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR LUDOVIC QA THEN AR.6.2 PROD PROMOTION

---

## 0. Preflight

| Repo | Branche attendue | Branche reelle | HEAD | Verdict |
|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | c300ea2 | OK |
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 462ec358 | OK |
| keybuzz-infra | main | main | 83331f6 | OK |

| Service | Image DEV avant | Image PROD | Doit changer ? |
|---|---|---|---|
| API DEV | v3.5.164-tenant-milestones-dev | v3.5.149-message-source-enrichment-prod | OUI (API) |
| Client DEV | v3.5.173-tenant-milestones-ux-dev | v3.5.172-message-source-enrichment-ux-prod | OUI (Client) |
| Backend PROD | — | v1.0.47-cross-env-guard-fix-prod | NON |
| OW PROD | — | v3.5.165-escalation-flow-prod | NON |

---

## 1. Audit contrat API

Tenant audite : `switaa-sasu-mnc1x4eq` (meme que capture Ludovic 09/05, KPIs 35 recus / 32 envoyes).

| Champ | Valeur | Utilisable UI ? | Commentaire |
|---|---|---|---|
| kpis.messagesReceived.value | 35 | OUI | Correct |
| kpis.repliesSent.value | 32 | OUI | Correct |
| series.messagesReceived | 21 points, max=7 | OUI | Series valide |
| series.repliesSent | 21 points, max=8 | OUI | Series valide |
| kpis.aiAdoptionRate.value | 2.222 | NON tel quel | 222% = draftsUsed(20) / suggestions(9) |
| kpis.aiAdoptionRate.draftsUsed | 20 | OUI | Compteur honnete |
| kpis.aiAdoptionRate.suggestionsGenerated | 9 | OUI | Compteur honnete |
| kpis.satisfactionRate.value | null | OK | Non instrumente |
| milestones | 7 jalons | OUI | Dates reelles |
| unavailableMilestones | 3 | OUI | Honnete |
| limitations | 4 strings EN | NON | A franciser |

### Diagnostic

- **Courbes vides** : Bug CSS. Le flex container utilise `items-end` ce qui empeche les flex children de recevoir la hauteur du parent (96px). Les bars avec `height: h%` resolvent a 0px car leur parent n'a pas de hauteur definie.
- **222%** : `draftsApplied` (20) compte TOUTES les applications de brouillons, pas seulement celles issues de suggestions IA. Le ratio drafts/suggestions n'a pas de sens comme "taux d'adoption".
- **Labels EN** : Strings hardcodees sans accents dans l'API (milestones, limitations) et le Client (titres, sous-titres).

---

## 2. Fix courbes

| Cas serie | Affichage attendu | Implemente ? |
|---|---|---|
| Serie >= 2 points, total > 0 | Barres visibles | OUI |
| Serie >= 1 point, total = 0 | "Aucune activite sur cette periode." | OUI |
| Serie vide | "Aucune donnee sur cette periode." | OUI |

Fix : supprime `items-end` du flex container (default = `stretch`), les flex children recoivent la hauteur parentale 96px, les barres `height: h%` resolvent correctement.

---

## 3. Fix KPI IA

| Option | Avantage | Risque | Decision |
|---|---|---|---|
| A — Compteur "Actions IA utilisees" | Pas de % confus, valeur honnete | Moins "KPI" | **CHOISI** |
| B — Taux borne a 100% | Familier | Plafonne sans explication, trompeur | Rejete |
| C — Separer suggestions/brouillons | Granulaire | 2 cartes, surcharge visuelle | Rejete |

Resultat : KPI affiche `20` (valeur brute) avec sous-texte `9 suggestions generees`.

---

## 4. Francisation

| Ancien libelle | Nouveau libelle |
|---|---|
| Messages recus | Messages recus (accent) |
| Reponses envoyees | Reponses envoyees (accent) |
| Adoption IA | Actions IA utilisees |
| utilises / suggestions | suggestions generees |
| Aucune donnee | Aucune donnee (accent) |
| Pas encore de donnees | Pas encore de donnees (accent) |
| Aucun jalon detecte | Aucun jalon detecte (accent) |
| Non instrumentes | Non instrumentes (accent) |
| Reessayer | Reessayer (accent) |
| Suggestions generees | Suggestions generees (accent) |
| Brouillons appliques | Brouillons appliques (accent) |
| Brouillons modifies | Brouillons modifies (accent) |
| Brouillons rejetes | Brouillons rejetes (accent) |
| Reponses autopilot | Reponses autopilot (accent) |
| Limitations connues | Limites connues |
| conversations without a reply... | Les conversations sans reponse sont exclues... |
| business hours are not excluded... | Les heures non ouvrees ne sont pas encore exclues... |
| new outbound messages have explicit... | Les nouveaux messages sortants utilisent une source explicite... |
| no CSAT/feedback source exists... | Aucune source de satisfaction client n'existe encore... |
| Espace cree | Espace cree (accent) |
| Premier canal connecte | Premier canal connecte (accent) |
| Premier message recu | Premier message recu (accent) |
| Premiere reponse envoyee | Premiere reponse envoyee (accent) |
| Premiere suggestion IA | Premiere suggestion IA (accent) |
| Premier brouillon IA utilise | Premier brouillon IA utilise (accent) |
| Premiere reponse autopilot | Premiere reponse autopilot (accent) |
| Mode suggestion active | Mode suggestion active (accent) |
| Mode autopilot active | Mode autopilot active (accent) |
| Agent KeyBuzz active | Agent KeyBuzz active (accent) |

---

## 5. Patchs

| Fichier | Changement | Pourquoi |
|---|---|---|
| API: performance-stats.service.ts | Labels milestones avec accents FR | Francisation source de verite |
| API: performance-stats.service.ts | Limitations en francais | Francisation |
| Client: app/performance/page.tsx | Supprime `items-end` du flex chart container | Bars resolvent a 0px |
| Client: app/performance/page.tsx | Ajout check all-zeros avec message explicite | UX serie vide |
| Client: app/performance/page.tsx | KPI IA = compteur brut, pas % | 222% incomprehensible |
| Client: app/performance/page.tsx | Tous labels avec accents FR | Francisation |

---

## 6. Build

| Service | Commit source | Tag | Digest | Rollback |
|---|---|---|---|---|
| API DEV | 881c2a38 | v3.5.165-performance-sav-polish-dev | sha256:f7bdedfcac72... | v3.5.164-tenant-milestones-dev |
| Client DEV | 749d0d8 | v3.5.174-performance-sav-polish-dev | sha256:e6722b0ef545... | v3.5.173-tenant-milestones-ux-dev |

---

## 7. GitOps

| Manifest | Image avant | Image apres |
|---|---|---|
| k8s/keybuzz-api-dev/deployment.yaml | v3.5.164-tenant-milestones-dev | v3.5.165-performance-sav-polish-dev |
| k8s/keybuzz-client-dev/deployment.yaml | v3.5.173-tenant-milestones-ux-dev | v3.5.174-performance-sav-polish-dev |

Commit infra : `a97d734` (main, pousse)

---

## 8. Runtime validation DEV

| Surface | Validation | Resultat |
|---|---|---|
| Pod API DEV | Running | OK |
| Pod Client DEV | Running | OK |
| Image API runtime | v3.5.165-performance-sav-polish-dev | OK |
| Image Client runtime | v3.5.174-performance-sav-polish-dev | OK |
| Milestones FR (accents) | Espace cree, Premier message recu, Premiere reponse envoyee... | OK |
| Unavailable FR (accents) | Mode suggestion active, Mode autopilot active, Agent KeyBuzz active | OK |
| Limitations FR | 4 phrases en francais | OK |
| AI KPI contrat | draftsUsed=20, suggestionsGenerated=9, value=2.222 | OK (Client affiche compteur) |
| Satisfaction | null, not instrumented | OK |
| Series messagesReceived | 21 points, total=35 | OK |
| Series repliesSent | 21 points, total=32 | OK |

---

## 9. Non-regression PROD

| Service PROD | Image avant | Image apres | Verdict |
|---|---|---|---|
| API PROD | v3.5.149-message-source-enrichment-prod | v3.5.149-message-source-enrichment-prod | INCHANGEE |
| Client PROD | v3.5.172-message-source-enrichment-ux-prod | v3.5.172-message-source-enrichment-ux-prod | INCHANGEE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | INCHANGEE |
| OW PROD | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | INCHANGEE |

Aucun manifest PROD modifie. Aucune DB mutation. Aucun billing/tracking/CAPI drift.

---

## 10. Rollback DEV

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.164-tenant-milestones-dev -n keybuzz-api-dev
# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.173-tenant-milestones-ux-dev -n keybuzz-client-dev
```

---

## 11. Linear

- KEY-289 : AR.6.1 complete. Charts fix, AI KPI honest count, French copy. API v3.5.165 + Client v3.5.174 DEV.
- KEY-282 : Polish DEV pret, prochaine etape QA Ludovic puis AR.6.2 PROD promotion.
