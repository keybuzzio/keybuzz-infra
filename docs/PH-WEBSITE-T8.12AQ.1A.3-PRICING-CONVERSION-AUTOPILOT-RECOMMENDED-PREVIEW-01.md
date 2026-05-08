# PH-WEBSITE-T8.12AQ.1A.3 — Pricing Conversion & Autopilot Recommended Preview

> Date : 8 mai 2026
> Ticket : KEY-278
> Env : DEV uniquement — PROD interdit
> Verdict : **GO DEV PREVIEW READY**

---

## 1. Preflight

| Surface | Attendu | Observé | Verdict |
|---|---|---|---|
| Website HEAD | `016da54` (AQ.1A.2) | idem | OK |
| Website DEV | `v0.6.13-paid-search-conversion-copy-preview-dev` | idem | OK |
| Website PROD | `v0.6.10-connector-claims-truth-prod` | idem | OK |
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | idem | OK |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | idem | OK |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | idem | OK |
| OW PROD | `v3.5.165-escalation-flow-prod` | idem | OK |

---

## 2. Audit pricing actuel (avant AQ.1A.3)

| Élément | Avant | Problème | Action |
|---|---|---|---|
| Hero H1 | "Un système de support qui s'adapte..." | Vague | Renforcé |
| Plan recommandé | Pro | Incohérent avec promesse "automatisez" | Déplacé vers Autopilot |
| Starter features | "Réponses assistées par IA" | 0 KBActions = trompeur | Clarifié "en option" |
| Pro CTA | "Structurer mon support" | Même que Starter | Différencié "Essayer Pro" |
| Autopilot CTA | "Passer au système" | Vague | "Essayer Autopilot" |
| Comparatif highlight | Colonne Pro | Devrait être Autopilot | Aligné |
| FAQ | 6 items | Manque objections clés | 10 items |
| CTA final | Absent | Manque critique | Ajouté |

---

## 3. Vérité produit des plans

| Plan | Prix | KBActions/mois | IA | Auto-exécution | Verdict |
|---|---|---|---|---|---|
| Starter | 97€ | 0 incluses | Widget visible, wallet vide | Non | Copy "IA en option via KBActions" |
| Pro | 297€ | 1 000 | Assistée, validation humaine | Non | Copy correcte |
| Autopilot | 497€ | 3 500 | Autonome sous garde-fous | Configurable | Copy "garde-fous stricts" |
| Enterprise | Sur devis | Sur-mesure | Personnalisée | Configurable | Inchangé |

---

## 4. Décision offre recommandée

| Plan | Positionnement | Badge | CTA | Highlight |
|---|---|---|---|---|
| Starter | Centraliser et structurer | - | Démarrer simplement | Non |
| Pro | Gérer le SAV avec IA assistée | - | Essayer Pro | Non |
| **Autopilot** | **Automatiser sans perdre le contrôle** | **Recommandé** | **Essayer Autopilot** | **Oui** |

Raison : Autopilot est le seul plan qui porte la promesse homepage "Automatisez votre SAV marketplace sans perdre le contrôle". C'est le plan le plus cohérent avec le positionnement paid search.

---

## 5. Copy finale

### Hero pricing

- H1 : "Choisissez le niveau d'automatisation adapté à votre SAV"
- H2 : "Centralisez, assistez ou automatisez. L'IA progresse avec vous, toujours avec les garde-fous KeyBuzz."
- Trial : "14 jours d'essai sur vos vrais messages, puis facturation mensuelle."

### Cartes plans

**Starter** (97€/mois)
- Tagline : "Centraliser et structurer votre support"
- Features : Centralisation, inbox unifiée, historique, 1 marketplace, support standard
- Note : "IA disponible via packs KBActions en option"
- CTA : "Démarrer simplement"

**Pro** (297€/mois)
- Tagline : "Gérer le SAV avec l'IA assistée"
- Features : 1000 KBA/mois, 3 MP, suggestions IA, playbooks avancés, cockpit SLA, escalade, support prioritaire
- CTA : "Essayer Pro"

**Autopilot** (497€/mois) — **RECOMMANDÉ**
- Tagline : "Automatiser sans perdre le contrôle"
- Features : 3500 KBA/mois, 5 MP, IA autonome garde-fous, auto-exécution playbooks, journal IA détaillé, supervision, support premium
- CTA : "Essayer Autopilot"

### CTA final

- H2 : "Vous hésitez ? Commencez par 14 jours sur vos vrais messages."
- Body : "Connectez Amazon, observez les urgences remontées par KeyBuzz, puis choisissez le niveau d'automatisation."
- CTA : "Commencer l'essai Autopilot" + "Voir les fonctionnalités"
- Badges : 14 jours d'essai / Sans engagement / Annulation en 1 clic

### FAQ enrichie (10 items)

Ajouts vs AQ.1A.2 :
- "Est-ce que je peux commencer sans tout connecter ?"
- "Les codes promo s'appliquent-ils aux addons ?"
- "Shopify, eBay ou Fnac sont-ils disponibles ?"
- "Que se passe-t-il après les 14 jours ?"

---

## 6. Comparatif détaillé

Changements :
- Highlight visuel (bg-[#26a9e0]) déplacé de colonne Pro vers colonne Autopilot
- Starter IA : "Réponses assistées" → "Option" dans comparatif IA
- Starter KBActions : "0" affiché explicitement
- Pro KBActions : "1 000" affiché
- Autopilot KBActions : "3 500" affiché
- Starter Playbooks : "Basiques" → false (pas de playbooks sans IA)

---

## 7. Fichiers modifiés

| Fichier | Repo | Changement |
|---|---|---|
| `src/app/pricing/page.tsx` | keybuzz-website | Refonte complète (hero, cartes, comparatif, FAQ, CTA) |
| `k8s/website-dev/deployment.yaml` | keybuzz-infra | Image tag v0.6.14 |

---

## 8. Validation tracking / UTM / promo

| Signal | Avant | Après DEV | Verdict |
|---|---|---|---|
| `/pricing` HTTP | 200 | 200 | OK |
| `/` HTTP | 200 | 200 | OK |
| `/features` HTTP | 200 | 200 | OK |
| `/amazon` HTTP | 200 | 200 | OK |
| `/contact` HTTP | 200 | 200 | OK |
| `trackViewPricing` | Source | Source | OK |
| `trackSelectPlan` | Source | Source | OK |
| `trackClickSignup` | Source | Source | OK |
| UTM forwarding (12 keys) | Source | Source | OK |
| promo forwarding | Oui | Oui | OK |
| gclid/fbclid/ttclid | Source | Source | OK |

---

## 9. Validation claims

| Claim | Page | Verdict |
|---|---|---|
| eBay non disponible | FAQ: "Pas encore" | OK |
| Shopify en préparation | FAQ: "en préparation" | OK |
| Fnac bientôt | FAQ: "en préparation" | OK |
| "sans CB" | Non présent | OK |
| Starter IA incluse | Non — "KBActions en option" | OK |
| Autopilot auto-send total | Non — "garde-fous stricts" | OK |
| Faux témoignages | Aucun | OK |
| Chiffres inventés | Aucun | OK |
| Prix inventés | Aucun (97/297/497 réels) | OK |
| Connecteurs Bientôt | "Shopify, WooCommerce" = "Bientôt" | OK |

---

## 10. Tags et images

| Env | Tag | Digest |
|---|---|---|
| DEV | `v0.6.14-pricing-autopilot-conversion-preview-dev` | `sha256:676839c...` |
| PROD | `v0.6.10-connector-claims-truth-prod` | Inchangé |

---

## 11. Commits

| Repo | Commit | Message |
|---|---|---|
| keybuzz-website | `a4ccf5e` | feat(website): align pricing with autopilot conversion positioning (AQ.1A.3) |
| keybuzz-infra | `a44f8fa` | gitops(dev): website pricing autopilot preview v0.6.14 |

---

## 12. PROD inchangée

| Service | Image PROD | Vérifié |
|---|---|---|
| Website | `v0.6.10-connector-claims-truth-prod` | OK |
| API | `v3.5.147-auto-assignment-after-reply-prod` | OK |
| Client | `v3.5.170-shopify-visible-disabled-channels-prod` | OK |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | OK |
| OW | `v3.5.165-escalation-flow-prod` | OK |

---

## 13. Risques résiduels

| Risque | Sévérité | Action |
|---|---|---|
| Tracking pixels dépendent des build-args (non injectés en DEV preview) | Faible | Vérifier injection lors du build PROD |
| Visual QA desktop/mobile requise par Ludovic | Bloquant PROD | Attendu avant AQ.1B |
| Plans Stripe doivent correspondre aux prix affichés | Moyen | Vérifier correspondance Stripe avant PROD |

---

## 14. Verdict

**GO DEV PREVIEW READY**

PRICING CONVERSION PREVIEW READY IN DEV — AUTOPILOT POSITIONED AS RECOMMENDED OFFER — PLAN DIFFERENCES CLARIFIED — STARTER/PRO/AUTOPILOT CLAIMS ALIGNED WITH SAAS REALITY — PRICING CTA AND OBJECTIONS STRENGTHENED — UTM/PROMO FORWARDING PRESERVED — WEBSITE TRACKING PRESERVED — NO PROD TOUCH — READY FOR LUDOVIC VISUAL QA
