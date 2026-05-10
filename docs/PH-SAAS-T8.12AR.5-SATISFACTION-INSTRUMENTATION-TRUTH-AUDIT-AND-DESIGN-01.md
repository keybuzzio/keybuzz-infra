# PH-SAAS-T8.12AR.5 — Satisfaction Instrumentation Truth Audit & Design

> Date : 2026-05-10
> Linear : KEY-290 / Parent KEY-282
> Phase : audit verite + design
> Environnement : PROD read-only / aucun build / aucun deploy

## VERDICT

**GO PARTIEL — PRODUCT DECISION REQUIRED**

Une option claire et conforme existe pour les canaux email. Les canaux marketplace (Amazon, Octopia) ne permettent PAS de CSAT client explicite. Le design DB/API/UI est pret. Ludovic doit arbitrer entre les options avant implementation.

---

## 0. Preflight

| Repo | Branche attendue | Branche reelle | HEAD | Verdict |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | fbb45c0c | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | ce1bdd2 | OK |
| keybuzz-infra | main | main | 0f3765a | OK |

| Service | Image PROD attendue | Runtime observe | Verdict |
|---|---|---|---|
| API | v3.5.150-performance-sav-milestones-prod | v3.5.150-performance-sav-milestones-prod | OK |
| Client | v3.5.173-performance-sav-milestones-ux-prod | v3.5.173-performance-sav-milestones-ux-prod | OK |
| Backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | OK |
| OW | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | OK |

---

## 1. Audit sources existantes

### DB Schema

| Source potentielle | Existe ? | Fiabilite | Mesure satisfaction client ? | Commentaire |
|---|---|---|---|---|
| Table satisfaction/csat/feedback/survey | NON | — | — | 0 table trouvee |
| Colonne satisfaction/csat/feedback | NON | — | — | 0 colonne pertinente |
| ai_action_log.confidence_score | OUI | Haute | NON | Score confiance IA, pas satisfaction client |
| conversation_learning_events.difference_score | OUI | Moyenne | NON | Score apprentissage ML |
| ai_execution_control.require_human_review | OUI | Haute | NON | Flag controle IA |
| conversation status (resolved/open/pending) | OUI | Haute | NON | Etat operationnel, pas satisfaction |
| suppliers.rating | NON | — | — | Colonne inexistante |
| message_events | OUI | Haute | NON | Evenements messages, pas de feedback |
| conversation_events | OUI | Haute | NON | Evenements conversations, pas de feedback |
| billing cancelSurvey | OUI (Client) | Haute | NON | Survey d'annulation abonnement SaaS, pas satisfaction client final |

### ai_action_log action_types (PROD)

```
AI_DECISION_TRACE: 48
AI_SUGGESTION_GENERATED: 31
draft_applied: 15
autopilot_escalate: 13
autopilot_reply: 12
AI_FALSE_PROMISE_DETECTED: 11
AI_AUTO_ESCALATED: 7
draft_modified: 5
draft_dismissed: 1
```

Aucun type lie a la satisfaction client.

### Code search API

Seules references a "satisfaction" dans le code API :
- `performance-stats.service.ts` : placeholder `satisfaction_not_instrumented`
- Engines IA : mentions textuelles dans des prompts/configs, pas des metriques

### Code search Client

- `billing/plan/page.tsx` : survey d'annulation Stripe (pas CSAT client)
- `performance/page.tsx` : placeholder `satisfactionRate` (null, non instrumente)
- `response-templates/data.ts` : mot "satisfaction" dans le texte des templates de reponse

### Conclusion audit

- **Source CSAT existante : NON**
- **Source exploitable immediatement : NON**
- **Source compatible dashboard /performance : NON**

---

## 2. Audit conformite Amazon / Marketplace

### Sources officielles consultees

1. Amazon Communication Guidelines PDF (m.media-amazon.com)
2. Amazon Seller Central — Communication Guidelines (forum)
3. Amazon SP-API — Solicitations API (developer-docs.amazon.com)
4. Amazon SP-API — Messaging API (developer-docs.amazon.com)
5. Seller Labs — Buyer-Seller Messaging 2026

### Amazon Buyer-Seller Messaging

| Regle | Detail | Source |
|---|---|---|
| Messages autorises | Uniquement les "Permitted Messages" necessaires a la commande ou au service client | Communication Guidelines |
| Demande de feedback/avis | Autorise UNE SEULE fois par commande, dans les 30 jours apres livraison | Solicitations API docs |
| Template obligatoire | La demande DOIT utiliser le template Amazon (via SP-API Solicitations) | Solicitations API |
| Survey custom | INTERDIT — constitue du contenu marketing non necessaire a la commande | Communication Guidelines |
| Liens externes | INTERDITS sauf HTTPS et necessaires au traitement | Communication Guidelines |
| Donnees feedback | Restent sur Amazon — aucune API pour recuperer le score par conversation | SP-API docs |
| AI scanning | Amazon scanne chaque message avec de l'IA pour detecter les violations | Seller Labs 2026 |

### Matrice conformite par canal

| Canal | Survey CSAT autorisee ? | Lien externe autorise ? | Risque | Source | Decision |
|---|---|---|---|---|---|
| Amazon BSM | NON (sauf template Amazon Solicitations) | NON | Suspension compte seller | Communication Guidelines | INTERDIT pour CSAT custom |
| Email direct | OUI | OUI | Faible (canal propre) | Pas de restriction marketplace | AUTORISE |
| Octopia / Cdiscount | NON verifie formellement | Risque moyen | Probablement similaire Amazon | Pas de doc officielle consultee | A VERIFIER avant implementation |
| Shopify (futur) | OUI (post-purchase) | OUI | Faible | Canal propre du marchand | AUTORISE quand implemente |
| 17TRACK | N/A | N/A | Aucun | Canal tracking, pas de messaging | HORS SCOPE |
| Canal interne KeyBuzz | OUI | OUI | Aucun | Canal propre | AUTORISE |

### Conclusion conformite

**Il est IMPOSSIBLE d'envoyer un questionnaire de satisfaction custom via Amazon Buyer-Seller Messaging.** Le feedback Amazon reste sur Amazon. Le seul canal viable pour le CSAT client explicite est le canal **email direct** (et potentiellement Shopify a l'avenir).

---

## 3. Classification des metriques

| Metrique | Categorie | Peut etre affichee comme satisfaction ? | Source | Risque de confusion |
|---|---|---|---|---|
| Score CSAT client (email post-resolution) | A. Satisfaction reelle | OUI | Feedback explicite client | Faible si labelle correctement |
| Score CSAT client (Amazon) | A. Satisfaction reelle | NON MESURABLE | N'existe pas via SP-API | — |
| Temps de premiere reponse | B. Qualite operationnelle | NON | Messages DB | ELEVE si appele "satisfaction" |
| Taux de resolution | B. Qualite operationnelle | NON | Conversations DB | ELEVE |
| Taux de reouverture | B. Qualite operationnelle | NON | Conversations DB | ELEVE |
| Taux d'escalade | B. Qualite operationnelle | NON | ai_action_log | ELEVE |
| Suggestion IA acceptee | C. Qualite IA | NON | ai_action_log | MOYEN |
| Brouillon modifie/rejete | C. Qualite IA | NON | ai_action_log | MOYEN |
| Agent feedback interne | C. Qualite IA | NON | A creer | FAIBLE si labelle |
| Sentiment dernier message client | D. Proxy IA | NON | IA/NLP | TRES ELEVE |
| Frustration detectee | D. Proxy IA | NON | IA/NLP | TRES ELEVE |

---

## 4. Options produit

### Option 1 — CSAT client explicite post-resolution (email uniquement)

- **Quand** : apres passage en `resolved`, delai configurable (ex: 1h)
- **Canal** : email direct uniquement (pas Amazon, pas Octopia)
- **Format** : email avec lien vers page de feedback (1-5 etoiles + commentaire optionnel)
- **Stockage** : table `conversation_feedback` tenant-scoped
- **Affichage** : taux reel sur /performance avec sample size et filtre canal

### Option 2 — Feedback interne agent sur qualite IA

- **Quand** : agent clique thumbs up/down apres interaction IA
- **Mesure** : qualite des suggestions IA, pas satisfaction client
- **Affichage** : dashboard IA separe, jamais comme CSAT
- **Interet** : ameliorer les modeles IA

### Option 3 — Score de sante conversationnel (proxy)

- **Base** : SLA respect, taux reouverture, escalade, FRT
- **Label** : "Qualite de traitement" (jamais "Satisfaction")
- **Affichage** : indicateur operationnel sur /performance
- **Risque** : confusion avec CSAT si mal labelle

### Option 4 — CSAT manuel cote marchand

- **Quand** : marchand renseigne manuellement un resultat apres resolution
- **Biais** : tres eleve (subjectif marchand, pas client)
- **Interet** : faible pour un vrai CSAT

### Comparaison

| Option | Valeur produit | Conformite | Complexite | Fiabilite | Recommandation |
|---|---|---|---|---|---|
| 1. CSAT email post-resolution | HAUTE | OK (email) | MOYENNE | HAUTE | **RECOMMANDEE** |
| 2. Feedback agent IA | MOYENNE | OK | FAIBLE | MOYENNE | Complementaire |
| 3. Score sante proxy | MOYENNE | OK | FAIBLE | BASSE | Utile si labelle honnete |
| 4. CSAT manuel marchand | FAIBLE | OK | FAIBLE | TRES BASSE | Deconseille |

### Recommandation

**Option 1 + Option 2** en complementaire.

Option 1 fournit le vrai CSAT (canal email). Option 2 fournit le feedback interne IA. Les deux coexistent sans confusion si correctement labelles.

Pour les canaux Amazon/Octopia, afficher honnètement : "Satisfaction non mesurable sur ce canal."

---

## 5. Design DB propose (additif uniquement)

### Table `conversation_feedback`

| Colonne | Type | Nullable | Raison | Risque |
|---|---|---|---|---|
| id | UUID PK DEFAULT gen_random_uuid() | NON | Identifiant unique | — |
| tenant_id | TEXT NOT NULL | NON | Multi-tenant obligatoire | — |
| conversation_id | UUID NOT NULL REFERENCES conversations(id) | NON | Lie au contexte | — |
| channel | TEXT NOT NULL | NON | 'email', 'amazon', 'octopia' — pour filtrer dashboard | — |
| source | TEXT NOT NULL | NON | 'customer_survey', 'agent_assessment' | — |
| score | INTEGER NOT NULL CHECK (score >= 1 AND score <= 5) | NON | Note 1-5 | — |
| max_score | INTEGER NOT NULL DEFAULT 5 | NON | Permettre d'autres echelles futures | — |
| comment | TEXT | OUI | Commentaire libre client | PII — stocker uniquement si politique acceptee |
| is_customer_explicit | BOOLEAN NOT NULL DEFAULT FALSE | NON | Distinguer feedback reel vs proxy | — |
| collected_at | TIMESTAMPTZ NOT NULL | NON | Date de collecte | — |
| created_at | TIMESTAMPTZ NOT NULL DEFAULT NOW() | NON | Date insertion | — |
| metadata | JSONB DEFAULT '{}' | OUI | Contexte additionnel | Ne pas stocker de PII |
| token | TEXT | OUI | Token unique pour lien feedback | — |

### Index

```sql
CREATE UNIQUE INDEX idx_cf_conversation_source ON conversation_feedback(conversation_id, source);
CREATE INDEX idx_cf_tenant_collected ON conversation_feedback(tenant_id, collected_at);
CREATE INDEX idx_cf_token ON conversation_feedback(token) WHERE token IS NOT NULL;
```

### Contraintes

- `UNIQUE(conversation_id, source)` : un seul feedback par source par conversation (idempotent)
- `CHECK(score >= 1 AND score <= 5)` : bornes strictes
- Pas de commentaire stocke par defaut (PII) — activer par config tenant

---

## 6. Design API propose

| Endpoint | Methode | Auth | Payload | Reponse | Mutations | Risques |
|---|---|---|---|---|---|---|
| `/feedback/collect` | POST | Token unique (pas de session) | `{ token, score, comment? }` | `{ success: true }` | INSERT conversation_feedback | Anti-abuse: rate limit 5/min par token, token single-use |
| `/feedback/page/:token` | GET | Aucune (page publique) | — | HTML/redirect vers page feedback | AUCUNE | Token validation, expiration 7j |
| `/feedback/summary` | GET | JWT + tenant-scoped | `?tenantId=xxx&range=30d` | `{ avg, count, distribution, byChannel }` | AUCUNE | RBAC owner/admin |
| `/feedback/agent-rate` | POST | JWT + tenant-scoped | `{ conversationId, score, note? }` | `{ success: true }` | INSERT conversation_feedback (source=agent_assessment) | Anti-doublon: UNIQUE(conversation_id, source) |

### Gardes

- `/feedback/collect` : token valide, non expire, non utilise, score 1-5
- `/feedback/summary` : tenant_id obligatoire, RBAC owner/admin
- `/feedback/agent-rate` : JWT valide, user appartient au tenant, conversation existe
- Rate limit : 5 requetes/min par IP sur `/feedback/collect`

### Integration /stats/performance

Ajouter dans la reponse existante :

```json
"satisfactionRate": {
  "value": 4.2,
  "sampleSize": 38,
  "channelBreakdown": { "email": { "avg": 4.2, "count": 38 }, "amazon": { "count": 0, "reason": "not_measurable" } },
  "confidence": "high",
  "minSampleForDisplay": 5
}
```

---

## 7. Design UI propose

| Etat | Affichage recommande | Exemple copy | Donnees requises |
|---|---|---|---|
| Non instrumente (actuel) | Placeholder grise | "Bientot disponible" | Aucune |
| Instrumente, 0 reponse | Placeholder actif | "Aucun retour client collecte pour le moment." | sampleSize = 0 |
| Instrumente, sample < 5 | Nombre brut | "3 retours clients — pas assez pour afficher un taux fiable." | sampleSize < 5 |
| Instrumente, sample >= 5 | KPI reel | "Satisfaction client — 4.2/5 sur 38 retours" | sampleSize >= 5 |
| Canal Amazon uniquement | Info explicite | "Satisfaction non mesurable sur le canal Amazon." | channel = amazon, 0 email feedback |
| Mix canaux | Split visible | "4.2/5 sur 38 retours (email) — Amazon: non mesurable" | byChannel data |

---

## 8. No fake metrics

| Risque | Controle | Resultat |
|---|---|---|
| Taux satisfaction invente | Non — placeholder "Bientot disponible" preserve | OK |
| Faux feedback cree | Non — 0 INSERT en DB | OK |
| Message client envoye | Non — 0 email/BSM envoye | OK |
| Event tracking declenche | Non — 0 GA4/CAPI/TikTok | OK |
| Paiement ou checkout | Non — 0 Stripe mutation | OK |
| Mutation DB | Non — SELECT read-only uniquement | OK |
| Modification /performance runtime | Non — aucun build/deploy | OK |
| Backfill | Non — aucun | OK |

---

## 9. AI feature parity / anti-regression

| Baseline | Source | Risque AR.5 | Mesure de protection |
|---|---|---|---|
| no-reask AP.1A-AP.1F | Prompt systeme IA | NUL — AR.5 ne touche pas l'IA | Pas de modification prompts |
| author_name AP.2.2/2.3 | Messages outbound | NUL — AR.5 ne touche pas les messages | Pas de modification outbound |
| auto-assignment AP.2.7/2.8 | Conversation workflow | NUL | Pas de modification workflow |
| lifecycle AP.2.4-2.6 | Conversation status | NUL | Pas de modification lifecycle |
| message_source AR.7 | Messages DB | NUL | Pas de modification messages |
| Performance dashboard AR.2-AR.6 | /stats/performance | FAIBLE — extension satisfactionRate | Ajout conditionnel, pas de suppression |
| Amazon connector | SP-API auth | NUL | Pas de modification Amazon |
| Shopify disabled | Feature flag | NUL | Pas de modification |

---

## 10. Non-regression

| Surface | Avant | Apres | Verdict |
|---|---|---|---|
| API PROD | v3.5.150-performance-sav-milestones-prod | v3.5.150-performance-sav-milestones-prod | INCHANGEE |
| Client PROD | v3.5.173-performance-sav-milestones-ux-prod | v3.5.173-performance-sav-milestones-ux-prod | INCHANGEE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | INCHANGEE |
| OW PROD | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | INCHANGEE |
| DB PROD | 0 mutation | 0 mutation | OK |
| Stripe | 0 mutation | 0 mutation | OK |
| CAPI | 0 event | 0 event | OK |
| /performance | Live, satisfaction "Bientot disponible" | Inchange | OK |

---

## 11. Roadmap AR.5.x

| Phase | Objectif | Env | Risque | Dependances | Critere GO |
|---|---|---|---|---|---|
| AR.5.1 | Schema `conversation_feedback` + API foundation (collect, summary, agent-rate) | DEV | Faible | Decision Ludovic sur options | Migration additive OK, endpoints fonctionnels |
| AR.5.2 | UI /performance : etats satisfaction conditionnnels | DEV | Faible | AR.5.1 API prete | KPI affiche correctement selon donnees |
| AR.5.3 | Channel policy guard : empecher survey sur Amazon, autoriser email | DEV | MOYEN | AR.5.1 | Guard teste par canal |
| AR.5.4 | PROD promotion API + Client + schema | PROD | Moyen | AR.5.1-5.3 valides DEV | Tests PROD, rollback documente |
| AR.5.5 | Collecte feedback : email post-resolution avec lien token | DEV+PROD | MOYEN | AR.5.4, politique email tenant | Emails envoyes uniquement canal email, rate limit OK |
| AR.5.6 | Reporting Admin / export | DEV+PROD | Faible | AR.5.5 | Admin peut voir les feedbacks |

---

## 12. Linear

- KEY-290 : Statut audit/design termine. Verdict GO PARTIEL — decision Ludovic requise sur options.
- KEY-282 : AR.5 design pret, implementation en AR.5.1+.
- Tickets enfants proposes :
  - AR.5.1 — Satisfaction schema + API foundation
  - AR.5.2 — Performance UI satisfaction states
  - AR.5.3 — Amazon-safe feedback policy guard
  - AR.5.4 — PROD promotion
  - AR.5.5 — Customer feedback collection by channel
  - AR.5.6 — Reporting Admin / export

---

## 13. Gaps restants

| Gap | Impact | Phase prevue |
|---|---|---|
| Decision Ludovic : Option 1 seule ou Option 1+2 | Bloquant pour AR.5.1 | Avant AR.5.1 |
| Verification conformite Octopia/Cdiscount | Moyen — pas de doc officielle consultee | AR.5.3 |
| Politique stockage commentaires client (PII) | Moyen — RGPD si commentaire stocke | AR.5.1 design |
| Page feedback publique : design UX | Faible | AR.5.2 |
| Email template post-resolution | Moyen — design + langue | AR.5.5 |
| Shopify canal : pas encore implemente | Faible — pas de Shopify actif | Futur |

---

## PROD

0 code, 0 build, 0 deploy, 0 mutation.

---

## Rapport

`keybuzz-infra/docs/PH-SAAS-T8.12AR.5-SATISFACTION-INSTRUMENTATION-TRUTH-AUDIT-AND-DESIGN-01.md`
