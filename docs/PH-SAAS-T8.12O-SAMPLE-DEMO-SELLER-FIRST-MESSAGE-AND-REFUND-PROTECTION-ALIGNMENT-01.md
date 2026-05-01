# PH-SAAS-T8.12O — Sample Demo Seller-First Message & Refund Protection Alignment

> Phase : PH-SAAS-T8.12O-SAMPLE-DEMO-SELLER-FIRST-MESSAGE-AND-REFUND-PROTECTION-ALIGNMENT-01
> Date : 2026-05-01
> Environnement : DEV uniquement
> Type : correction produit wording demo + audit refund protection / seller-first
> Priorite : P1
> Linear : KEY-235 (partiel)

---

## Sources relues

- `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md`
- `keybuzz-infra/docs/AI_MEMORY/API_AUTOPILOT_CONTEXT.md`
- `keybuzz-infra/docs/AI_MEMORY/SELLER_CONTEXT.md`
- `keybuzz-infra/docs/PH49-REFUND-PROTECTION-REPORT.md`
- `keybuzz-infra/docs/PH49.1-REFUND-PROTECTION-AUDIT.md`
- `keybuzz-infra/docs/PH147-AUTOPILOT-GUARDRAILS-BUSINESS-01.md`
- `keybuzz-infra/docs/PH147.2-GUARDRAILS-FINAL-TUNING-01-REPORT.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N-SAMPLE-DATA-NON-POLLUTING-WOW-DESIGN-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.1-SAMPLE-DEMO-CLIENT-FOUNDATION-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.2-SAMPLE-DEMO-WOW-UI-INTEGRATION-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.3-SAMPLE-DEMO-LAMBDA-RUNTIME-VALIDATION-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.3.1-SAMPLE-DEMO-MOBILE-OVERFLOW-HOTFIX-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.4-SAMPLE-DEMO-WOW-PROD-PROMOTION-01.md`

---

## Preflight

| Repo | Branche attendue | Branche constatee | HEAD | Dirty ? | Verdict |
|---|---|---|---|---|---|
| `keybuzz-infra` | `main` | `main` | `b4e789a` | Non | OK |
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `a5d8656` | `tsconfig.tsbuildinfo` only | OK |
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `91b860b2` | Non | OK |

| Service | ENV | Image manifest | Image runtime | Match ? |
|---|---|---|---|---|
| Client | DEV | `v3.5.142-sample-demo-mobile-overflow-dev` | `v3.5.142-sample-demo-mobile-overflow-dev` | OK |
| Client | PROD | `v3.5.142-sample-demo-wow-prod` | `v3.5.142-sample-demo-wow-prod` | OK |
| API | PROD | `v3.5.128-trial-autopilot-assisted-prod` | `v3.5.128-trial-autopilot-assisted-prod` | OK |

---

## Doctrine seller-first

Document cree : `keybuzz-infra/docs/AI_MEMORY/SELLER_FIRST_REFUND_PROTECTION_DOCTRINE.md`

Principes cles :
1. Remboursement = dernier recours
2. Empathie sans capitulation
3. Diagnostic avant compensation (photo, reference, tracking)
4. Solution proportionnee
5. Escalade humaine obligatoire (haute valeur, client agressif, cas ambigu)
6. Ne jamais dispenser de retour produit

---

## Audit des messages sample

### Problemes identifies

| Fichier | Message / scenario | Probleme | Risque vendeur | Action |
|---|---|---|---|---|
| `sampleData.ts` conv-001 | Sophie retour : "Le remboursement sera effectue sous 3-5 jours" | Promet remboursement sans diagnostic | ELEVE | REECRIT |
| `sampleData.ts` conv-002 | Thomas livraison : "lancerons immediatement une enquete" | Ton legerement presse | FAIBLE | AJUSTE |
| `sampleData.ts` conv-003 | Marie defectueux : agent demande photos | BON — seller-first | Aucun | CONSERVE |
| `sampleData.ts` conv-004 | Pierre adresse : redirige vers Amazon | BON — explique les limites | Aucun | CONSERVE |
| `sampleData.ts` conv-005 | Julie avis negatif : "remplacement immediat sans frais OU remboursement integral" + "pas besoin de retourner" | CRITIQUE — aucun diagnostic, aucune preuve, perte seche | TRES ELEVE | REECRIT INTEGRALEMENT |

### Corrections appliquees

| Fichier | Ancien comportement | Nouveau comportement | Pourquoi seller-first |
|---|---|---|---|
| conv-001 | Promet remboursement sous 3-5 jours | Demande photo + reference, propose "solution la plus adaptee" | Diagnostic avant compensation |
| conv-002 | "lancerons immediatement une enquete" | "ouvrirons une enquete pour clarifier la situation" | Ton proportionne |
| conv-005 | "Remplacement immediat OU remboursement integral" + dispense retour | Demande photo/video + reference, propose "echange, avoir ou autre" apres analyse | Preuve obligatoire, solution proportionnee, pas de perte seche |
| conv-005 | Categorie "Satisfaction client" | Categorie "Qualite produit" | Plus precis, evite le biais "satisfaire a tout prix" |

---

## Audit doctrine IA / refund protection (API — lecture seule)

| Couche | Source | Etat reel | Protege le vendeur ? | Gap |
|---|---|---|---|---|
| Refund Protection Layer | `refundProtectionLayer.ts` | Deploye (PH49) — 10 regles | **Oui** | Aucun |
| Autopilot Guardrails | `autopilotGuardrails.ts` | Deploye (PH147) — pre-LLM blocking | **Oui** | Mineur (`remplacement immediat` sans accent) |
| Promise Detection | Dans guardrails | `FORBIDDEN_PROMISE_PATTERNS` + `UNSAFE_COMMITMENT` | **Oui** | Couvert |
| Conversation Learning | `conversationLearningEngine.ts` | Deploye (PH51) | **Indirect** | Aucun |
| Conversation Memory | `conversationMemoryEngine.ts` | Deploye (PH58) | **Indirect** | Aucun |
| Platform-aware behavior | 2 lignes guardrails | **Minimal** (Amazon +10, Octopia +5) | **Partiel** | **GAP — phase PH-SAAS-T8.12O.1** |
| Playbooks / SAV policies | `ai-policy-debug-routes.ts` | Deploye | **Oui** | Aucun |

---

## Build DEV

| Element | Valeur |
|---|---|
| Commit client | `f6ae911` |
| Tag DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.143-sample-demo-seller-first-dev` |
| Digest | `sha256:f193d7571091b65ce5e3a206c8677b9e5e410e6a0e5602b371968a24a03efc18` |
| Source build | Clone temporaire propre (HEAD `f6ae911`) |
| Repo clean | Oui |

---

## GitOps DEV

| Element | Valeur |
|---|---|
| Commit infra | `cbf1813` |
| Image avant | `v3.5.142-sample-demo-mobile-overflow-dev` |
| Image apres | `v3.5.143-sample-demo-seller-first-dev` |
| Runtime | `v3.5.143-sample-demo-seller-first-dev` |
| Rollback DEV | `v3.5.142-sample-demo-mobile-overflow-dev` |
| Rollout | `deployment "keybuzz-client" successfully rolled out` |

---

## Validation navigateur DEV

| Tenant | Route | Attendu | Resultat |
|---|---|---|---|
| eComLG (459 conv) | `/inbox` | InboxTripane reel, 0 demo | OK |
| eComLG | `/dashboard` | Dashboard reel | OK |
| eComLG | `/onboarding` | Onboarding data-aware | OK |
| Lambda (0 conv) | `/inbox` | Demo visible, messages seller-first | OK |
| Lambda | `/dashboard` | DemoDashboardPreview | OK |

### Bundle seller-first verification

| Check | Resultat |
|---|---|
| "remboursement sera effectue" dans bundle | **0** |
| "remplacement immediat" dans bundle | **0** |
| "pas besoin de retourner" dans bundle | **0** |
| photo/preuve/seller-first present | **7 chunks** |
| Mobile master/detail intact | **1 chunk** |

---

## Non-pollution

| Surface | Attendu | Resultat |
|---|---|---|
| DB `conversations demo-*` | 0 | **0** |
| DB `messages demo-*` | 0 | **0** |
| billing_events | Aucun post-phase | **OK** (dernier: 30 avr) |
| CAPI / tracking | 0 | **OK** |
| Stripe | 0 | **OK** |
| GA4/Ads | 0 | **OK** |

---

## Non-regression

| Surface | Attendu | Resultat |
|---|---|---|
| Client DEV routes | Toutes OK | **OK** |
| Client PROD routes | Toutes OK | **OK** |
| API DEV health | OK | **OK** |
| API PROD health | OK | **OK** |

---

## Rollback GitOps DEV

```yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.142-sample-demo-mobile-overflow-dev
```

---

## PROD strictement inchangee

| Service | Image PROD | Status |
|---|---|---|
| Client | `v3.5.142-sample-demo-wow-prod` | **Inchangee** |
| API | `v3.5.128-trial-autopilot-assisted-prod` | **Inchangee** |
| Website | `v0.6.7-pricing-attribution-forwarding-prod` | **Inchangee** |

---

## Gaps et suite

### Corrige dans cette phase

- 3 suggestions IA demo reecrites seller-first
- 0 suggestion IA promet un remboursement
- Doctrine SELLER_FIRST_REFUND_PROTECTION_DOCTRINE.md creee
- Audit 7 couches IA protection vendeur documente

### Gaps restants

1. **Platform-aware behavior** : le comportement IA ne distingue pas finement les regles par marketplace (Amazon vs Octopia vs boutique propre). Actuellement seul un bonus risque est applique.
   - Phase recommandee : `PH-SAAS-T8.12O.1-PLATFORM-AWARE-AI-BEHAVIOR-AND-MARKETPLACE-POLICY-AUDIT-01`

2. **Playbooks/templates seller-first audit** : les templates de reponse et playbooks existants n'ont pas ete audites pour la conformite seller-first dans cette phase.

3. **Pattern `remplacement immediat` sans accent** : non couvert par `FORBIDDEN_PROMISE_PATTERNS` dans les guardrails API (mineur).

### Statut KEY-235

**KEY-235 partiellement resolu** :
- Sample demo wording : FAIT
- Doctrine seller-first : FAIT
- Audit IA protection vendeur API : FAIT
- Platform-aware behavior : GAP
- Playbooks/templates audit : GAP

**Ne pas fermer KEY-235.**

---

## Rapport

`keybuzz-infra/docs/PH-SAAS-T8.12O-SAMPLE-DEMO-SELLER-FIRST-MESSAGE-AND-REFUND-PROTECTION-ALIGNMENT-01.md`

---

## Verdict

```
SAMPLE DEMO SELLER-FIRST ALIGNMENT READY IN DEV
REFUND-FIRST WORDING REMOVED
SELLER MARGIN PROTECTION PRESERVED
NO DB/API/TRACKING/BILLING/CAPI DRIFT
PROD UNCHANGED
PLATFORM-AWARE AUDIT GAPS DOCUMENTED
```
