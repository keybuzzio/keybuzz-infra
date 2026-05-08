# PH-WEBSITE-T8.12AQ.1A.2 — Conversion Copy, Social Proof & CTA Preview Polish

> Date : 8 mai 2026
> Ticket : KEY-278
> Env : DEV uniquement — PROD interdit
> Verdict : **GO DEV PREVIEW READY**

---

## 1. Preflight

| Surface | Attendu | Observé | Verdict |
|---|---|---|---|
| Website HEAD | `3a66064` (AQ.1A.1) | idem | OK |
| Website DEV | `v0.6.12-paid-search-spapi-trust-motion-preview-dev` | idem | OK |
| Website PROD | `v0.6.10-connector-claims-truth-prod` | idem | OK |
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | idem | OK |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | idem | OK |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | idem | OK |
| OW PROD | `v3.5.165-escalation-flow-prod` | idem | OK |

---

## 2. Audit copy AQ.1A.1

| Bloc | Copy avant | Problème | Proposition retenue |
|---|---|---|---|
| H1 | "Un seul endroit pour tout votre SAV marketplace" | Descriptif, pas d'action | "Automatisez votre SAV marketplace sans perdre le contrôle" |
| H2 | "KeyBuzz centralise vos messages Amazon..." | Correct mais pas assez désirable | "L'IA trie, priorise et prépare vos réponses. Vous gardez la main." |
| CTA principal | "Essayer gratuitement" | Générique | "Essayer 14 jours gratuitement" |
| Badges hero | 14j / Amazon 2min / Sans engagement | OK mais "14j" redondant avec CTA | "Connexion Amazon 2min / IA + validation humaine / Sans engagement" |
| Social proof | Absent | Manque critique | Section "Ce que KeyBuzz évite aux vendeurs" ajoutée |
| CTA final H2 | "Reprenez le contrôle..." | Générique | "14 jours pour voir ce que KeyBuzz change dans votre SAV" |
| CTA final body | "Créez votre compte..." | Procédural | "Connectez Amazon, centralisez vos messages..." |
| CTA final bouton | "Essayer gratuitement" | Même que hero | "Démarrer l'essai gratuit" |

---

## 3. Variantes H1/H2

| Variante | H1 | H2 | Risque | Décision |
|---|---|---|---|---|
| A | Automatisez votre SAV marketplace sans perdre le contrôle | L'IA trie, priorise et prépare vos réponses. Vous gardez la main. | "automatisez" couvert par "sans perdre le contrôle" | **RETENUE** |
| B | Un seul endroit pour automatiser tout votre SAV marketplace | KeyBuzz centralise Amazon, Cdiscount et e-mail. | "tout automatiser" = promesse excessive | NON |
| C | Centralisez, priorisez et répondez plus vite | Plus besoin de jongler. KeyBuzz organise votre support. | Trop long | NON |

---

## 4. Social proof strategy

**Option retenue : réassurance vendeur sans faux témoignages** (Option C du prompt)

Section "Ce que KeyBuzz évite aux vendeurs marketplace" — 4 cartes :

1. **Les messages urgents qui se perdent** — KeyBuzz remonte les conversations prioritaires
2. **Les réponses écrites dans l'urgence** — L'IA prépare, vous vérifiez
3. **Les demandes sans contexte de commande** — Commande/suivi affichés automatiquement
4. **La connexion marketplace compliquée** — Guidage SP-API en quelques clics

Aucun faux nom, aucune fausse citation, aucun chiffre inventé. Structure prête pour de vrais témoignages ultérieurement.

---

## 5. Amazon SP-API trust

| Élément | Avant | Après | Verdict |
|---|---|---|---|
| Badge "Conformité Amazon SP-API" | Présent | Préservé | OK |
| 4 items sécurité (OAuth, moindre privilège, données, audit) | Présents | Préservés | OK |
| Lien /amazon | Présent | Préservé + reformulé | OK |
| Phrase détail page dédiée | Absente | Ajoutée | **AMÉLIORÉ** |

---

## 6. Fichiers modifiés

| Fichier | Repo | Changement |
|---|---|---|
| `src/app/page.tsx` | keybuzz-website | H1/H2 renforcés, section réassurance, CTA final, badges hero, imports Lucide |
| `k8s/website-dev/deployment.yaml` | keybuzz-infra | Image tag v0.6.13 |

---

## 7. Validation tracking / UTM / promo

| Signal | AQ.1A.1 | AQ.1A.2 DEV | Verdict |
|---|---|---|---|
| `/` HTTP | 200 | 200 | OK |
| `/pricing` HTTP | 200 | 200 | OK |
| `/features` HTTP | 200 | 200 | OK |
| `/amazon` HTTP | 200 | 200 | OK |
| `/contact` HTTP | 200 | 200 | OK |
| GA4 (Analytics.tsx) | Client-side | Client-side | OK |
| sGTM | Build-arg | Build-arg | OK |
| TikTok pixel | Build-arg | Build-arg | OK |
| Meta pixel | Build-arg | Build-arg | OK |
| UTM forwarding | Inchangé | Inchangé | OK |
| Promo forwarding | Inchangé | Inchangé | OK |
| Purchase/CompletePayment browser | Non | Non | OK |

---

## 8. Validation claims

| Claim | Page | Verdict |
|---|---|---|
| eBay non disponible | homepage | OK — absent |
| Shopify en préparation | homepage | OK — absent |
| Fnac/Darty bientôt | FAQ "en préparation" | OK |
| Amazon disponible | homepage | OK |
| Cdiscount/Octopia | wording prudent | OK |
| "sans CB" | Non présent | OK |
| Faux témoignages | Aucun | OK |
| Chiffres inventés | Aucun | OK |
| Auto-send total | "vous gardez la main" | OK |
| Équipe humaine KeyBuzz | Non revendiquée | OK |

---

## 9. Tags et images

| Env | Tag | Digest |
|---|---|---|
| DEV | `v0.6.13-paid-search-conversion-copy-preview-dev` | `sha256:0c5539b...` |
| PROD | `v0.6.10-connector-claims-truth-prod` | Inchangé |

---

## 10. Commits

| Repo | Commit | Message |
|---|---|---|
| keybuzz-website | `016da54` | feat(website): strengthen paid search conversion copy (AQ.1A.2) |
| keybuzz-infra | `c548336` | gitops(dev): website conversion copy preview v0.6.13 |

---

## 11. PROD inchangée

| Service | Image PROD | Vérifié |
|---|---|---|
| Website | `v0.6.10-connector-claims-truth-prod` | OK |
| API | `v3.5.147-auto-assignment-after-reply-prod` | OK |
| Client | `v3.5.170-shopify-visible-disabled-channels-prod` | OK |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | OK |
| OW | `v3.5.165-escalation-flow-prod` | OK |

---

## 12. Risques résiduels

| Risque | Sévérité | Action |
|---|---|---|
| Tracking pixels dépendent des build-args (non injectés en DEV preview) | Faible | Vérifier injection lors du build PROD AQ.1B |
| Section réassurance en preview, pas encore de vrais témoignages | Faible | Ludovic fournit contenus avant PROD |
| Visual QA desktop/mobile requise par Ludovic | Bloquant PROD | Attendu avant AQ.1B |

---

## 13. Verdict

**GO DEV PREVIEW READY**

PAID SEARCH LANDING PAGE CONVERSION COPY READY IN DEV — HERO STRONGER AND CLEARER — SOCIAL PROOF / SELLER REASSURANCE ADDED WITHOUT FAKE TESTIMONIAL CLAIMS — FINAL CTA STRENGTHENED — AMAZON SP-API TRUST COPY PRESERVED — MOTION DESIGN POLISHED — WEBSITE TRACKING AND UTM/PROMO FORWARDING PRESERVED — CONNECTOR CLAIMS HONEST — NO PROD TOUCH — READY FOR LUDOVIC VISUAL QA
