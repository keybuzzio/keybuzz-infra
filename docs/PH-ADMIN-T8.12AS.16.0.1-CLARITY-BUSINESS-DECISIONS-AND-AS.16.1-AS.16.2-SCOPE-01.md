# PH-ADMIN-T8.12AS.16.0.1-CLARITY-BUSINESS-DECISIONS-AND-AS.16.1-AS.16.2-SCOPE

> Date : 2026-05-15
> Linear : KEY-322 related (suit AS.16.0 commit 9c4f843)
> Phase : T8.12AS.16.0.1 (note de decisions docs-only + scope detaille AS.16.1 / AS.16.2)
> Environnement : docs-only (aucun code, aucune env var, aucun build, aucun deploy)

---

## 0. VERDICT

GO AS.16.1 + AS.16.2 SCOPE LOCKED. ATTENTE PROJECT IDS CLARITY.

Decisions business prises par Ludovic post-AS.16.0. AS.16.1 (website Clarity DEV first) peut demarrer des que les Project IDs Clarity (DEV et PROD) sont generes cote Microsoft Clarity dashboard. AS.16.2 (client funnel pre-auth) suivra apres AS.16.1-PROD validee, avec une decision Project ID a prendre a ce moment-la (meme PROD ID commun ou ID separe pour lisibilite Clarity).

Aucun ticket Linear cree dans cette phase. Aucune mutation. Aucun code.

---

## 1. DECISIONS BUSINESS ACTEES

| # | Question AS.16.0 | Decision Ludovic | Statut |
|---|---|---|---|
| 1 | Project IDs DEV + PROD a creer | OUI 2 separes. **Pre-requis bloquant AS.16.1**. A creer via clarity.microsoft.com par Ludovic | TODO Ludovic |
| 2 | Consent opt-in strict 3eme categorie RGPD | OUI opt-in strict + CookieConsent etendu | ACTE |
| 3 | Domain strategy keybuzz.pro + www.keybuzz.pro | OUI 1 Project ID PROD commun pour les 2 hosts (meme audience marketing) | ACTE |
| 4 | Masking strategy AS.16.2 funnel | Confirme en AS.16.2 design (Clarity native + data-clarity-mask) | DEFERRED a AS.16.2 |
| 5 | Update /cookies texte AVANT activation PROD | OUI obligatoire | ACTE (sera dans AS.16.1-PROD pre-flight) |
| 6 | Project ID client.keybuzz.io funnel : meme PROD ID ou separe ? | A confirmer en AS.16.2 selon lisibilite Clarity dashboard | DEFERRED a AS.16.2 |

---

## 2. CONTEXTE BUSINESS COMPLEMENTAIRE

### 2.1 Ajouts homepage anticipes

Ludovic annonce des modifications a venir sur la homepage keybuzz.pro :
- **Nouveaux CTA** : variantes / placements / wording a tester
- **Reviews / avis clients** : section temoignages avec photos / quotes / etoiles

**Objectif Clarity** : mesurer l impact UX de ces nouveaux blocs :
- Scroll depth jusqu aux nouvelles sections
- Clics CTA (taux + position)
- Heatmaps zones d hesitation (rage clicks, hover sans clic)
- Friction parcours homepage -> /pricing -> register
- Comparaison avant/apres (sessions A/B si necessaire)

### 2.2 Implication pour AS.16.1

L implementation AS.16.1 **ne doit pas bloquer** ni rendre les ajouts homepage difficiles. Pour cela :

- ClarityProvider doit etre **mount au layout** racine (pas par-page), pour capturer toute nouvelle section automatiquement
- Aucune liste hardcoded de selectors specifiques a tracker (Clarity capture le DOM globalement)
- Allowlist routes **base sur prefix `/`** (toute page publique website), pas une liste specifique
- Configuration masking via classes/data-attributes (`data-clarity-mask="true"`) - permet d ajouter facilement de nouveaux composants prive sans toucher Clarity setup
- Aucune dependance code Clarity sur des composants homepage specifiques

Resultat attendu : quand Ludovic ajoute "Reviews" ou "CTA variante", aucune modification ClarityProvider n est necessaire. Clarity capture automatiquement.

### 2.3 Funnel cible AS.16.2 affine

Clarification importante : l onboarding **avant SaaS** se passe sur **client.keybuzz.io** (pas sur keybuzz.pro).

Parcours typique :
1. Visiteur arrive sur keybuzz.pro (Clarity Phase 1 actif)
2. Click CTA pricing -> redirige vers `client.keybuzz.io/register?plan=X` (cross-domain)
3. Visiteur fait /register (Clarity Phase 2 actif avec masking)
4. Visiteur fait eventuellement /signup ou /login (Clarity Phase 2 actif)
5. Visiteur arrive sur /onboarding apres signup (Clarity EXCLU - post-auth)
6. Visiteur entre dans SaaS authenticated (/inbox, /dashboard, etc.) (Clarity EXCLU)

Routes AS.16.2 (revisees) :

| Route Client | Phase Clarity | Masking necessaire |
|---|---|---|
| /register | INCLU | email + password + company + phone (data-clarity-mask) |
| /signup | INCLU | idem |
| /login | INCLU (a confirmer si necessaire pour mesurer login UX) | email + password |
| /onboarding | EXCLU (post-auth sensible : config tenant, marketplace) | n/a |
| /auth, /auth/[...callbacks] | EXCLU (tokens transient) | n/a |
| Tous SaaS authenticated | EXCLU STRICT | n/a |

**Question /login subtilite** : si Antoine veut mesurer la friction login (retours utilisateurs existants), inclure. Si pas besoin, exclure pour reduire la surface PII (login est utilise par customers existants, pas leads marketing). **A trancher en AS.16.2 design**.

### 2.4 Exclusion stricte SaaS authentifie (confirme)

Aucun changement par rapport a AS.16.0 :
- /inbox, /orders, /dashboard, /settings, /billing, /channels, /suppliers, /knowledge, /playbooks, /ai-journal, /workspace-setup, /start, /help -> CLARITY EXCLUS
- Admin v2 entierement -> CLARITY EXCLUS (pas d env var dans manifest)

---

## 3. SCOPE AS.16.1 (DETAILLE)

### 3.1 Pre-requis bloquants

- Ludovic genere les 2 Clarity Project IDs (DEV + PROD) via https://clarity.microsoft.com
- Ludovic communique ces IDs (PUBLIC, peuvent etre dans le chat sans risque secret car les Clarity Project IDs sont public-safe par design Microsoft)
- Politique cookies actuelle (/cookies/page.tsx) sera mise a jour AVANT AS.16.1-PROD

### 3.2 Implementation prevue AS.16.1 (DEV first)

Repo : keybuzz-website branche main
Fichiers a creer / modifier (proposition, sera execute en AS.16.1) :

| Fichier | Action | Contenu |
|---|---|---|
| `src/components/ClarityProvider.tsx` | NOUVEAU | Mount au layout, check consent + env var, load Clarity script async |
| `src/components/CookieConsent.tsx` | UPDATE | Ajouter 3eme categorie "Heatmaps & session replay (Clarity)" + storage `keybuzz_clarity_consent` + default `denied` (opt-in strict) |
| `src/app/layout.tsx` | UPDATE | Mount `<ClarityProvider />` apres `<Analytics />` et `<CookieConsent />` |
| `src/app/cookies/page.tsx` | UPDATE | Politique cookies mise a jour pour mentionner Clarity opt-in |
| K8s ConfigMap keybuzz-website-dev | UPDATE | Ajouter `NEXT_PUBLIC_CLARITY_PROJECT_ID` = (DEV Project ID) |
| K8s ConfigMap keybuzz-website-prod | UPDATE en AS.16.1-PROD | Ajouter `NEXT_PUBLIC_CLARITY_PROJECT_ID` = (PROD Project ID) |

### 3.3 Tag image cible

- AS.16.1 DEV : `v0.6.13-clarity-dev` (ou similaire selon convention SemVer Ludovic)
- AS.16.1 PROD : `v0.6.13-clarity-prod`

### 3.4 Tests AS.16.1

| Test | Cible | Resultat attendu |
|---|---|---|
| Navigateur DEV consent refuse | https://www-dev.keybuzz.pro (ou domain DEV exact) | 0 requete vers clarity.ms (DevTools Network) |
| Navigateur DEV consent accepte | idem | Script clarity.ms charge, session visible dans dashboard Clarity DEV |
| Navigateur DEV /cookies | DEV | Texte mis a jour mentionne Clarity |
| Toutes pages publiques | DEV | Clarity capture (sauf si consent refuse) |
| QA Ludovic + agence DEV | Visite manuelle | Confirmation visibilite sessions dashboard |

### 3.5 Anti-regression AS.16.1

| Surface | Verification |
|---|---|
| keybuzz-website analytics existant | GA4 + Meta + TikTok + LinkedIn + sGTM chargent comme avant (CookieConsent banner declenche) |
| Pages legal | /privacy + /terms + /legal + /sla inchanges |
| Cross-domain linker | GA4 keybuzz.pro <-> client.keybuzz.io preserve |
| Client + Admin v2 + Backend | Aucun changement (AS.16.1 = website only) |

### 3.6 Rollback AS.16.1

- Revert manifest keybuzz-website-dev (image v0.6.12 reste valide GHCR)
- Revert ConfigMap (remove NEXT_PUBLIC_CLARITY_PROJECT_ID)
- Apply, rollout
- Clarity dashboard reste actif cote Microsoft mais ne recoit plus de sessions

---

## 4. SCOPE AS.16.2 (PREVIEW, sera detaille au moment du GO)

### 4.1 Pre-requis bloquants AS.16.2

- AS.16.1 PROD livre et valide (QA Ludovic OK)
- Decision : Project ID client.keybuzz.io = meme PROD ID que website ou ID separe ?
  - **Pro meme ID** : 1 seule audience cross-domain "KeyBuzz acquisition", facile a configurer linker
  - **Pro ID separe** : dashboards Clarity distincts website vs client funnel = analyses propres + permissions agence differentes possible
  - Recommandation soft : tester d abord en DEV avec 2 IDs separes (DEV website + DEV client), puis decider PROD selon retour Ludovic + Antoine

### 4.2 Implementation prevue AS.16.2 (DEV first)

Repo : keybuzz-client branche ph148/onboarding-activation-replay
Fichiers a creer / modifier (proposition) :

| Fichier | Action | Contenu |
|---|---|---|
| `src/components/ClarityProvider.tsx` | NOUVEAU (equivalent website) | Mount layout pre-auth, check consent + funnel allowlist `['/register','/signup','/login']` |
| `src/components/tracking/SaaSAnalytics.tsx` | NE PAS modifier | Funnel pattern existant reste intact (NE PAS modifier FUNNEL_PREFIXES ni BLOCKED_PREFIXES) |
| `app/register/page.tsx` + `app/signup/page.tsx` + `app/login/page.tsx` | UPDATE | Ajouter `data-clarity-mask="true"` sur inputs email/password/company/phone |
| `app/layout.tsx` | UPDATE | Mount `<ClarityProvider />` conditional (verifier consent ET funnel allowlist) |
| K8s ConfigMap keybuzz-client-dev + keybuzz-client-prod | UPDATE | `NEXT_PUBLIC_CLARITY_PROJECT_ID` (DEV + PROD) |

### 4.3 Tests AS.16.2 critiques

| Test | Cible | Resultat attendu |
|---|---|---|
| Capture session DEV sur /register | DEV | Clarity dashboard recoit, email + password en [REDACTED] |
| /inbox /orders /dashboard /settings /billing /channels | DEV | 0 requete clarity.ms (Network DevTools) |
| /login Clarity inclus ou exclu | A decider AS.16.2 design | Si inclus : email masque ; si exclu : 0 requete |
| Cross-domain Clarity continue session keybuzz.pro -> client.keybuzz.io | DEV (si meme Project ID) | Meme `clarity_user_id` sur les 2 domains |
| Anti-regression GA4 funnel existant | DEV | GA4 charge sur /register comme avant |

---

## 5. ANTICIPATION AJOUTS HOMEPAGE FUTURS

### 5.1 Architecture compatible

L implementation ClarityProvider sera **independante des sections homepage specifiques**. Quand Ludovic ajoute :
- Nouveau CTA (variante, placement, wording, A/B test)
- Section "Reviews" avec temoignages clients (photos, quotes, etoiles)
- Toute nouvelle section homepage (FAQ, integrations showcase, etc.)

Aucune modification ClarityProvider n est requise. Clarity capture automatiquement scroll depth, clics, heatmaps sur tous les nouveaux elements DOM.

### 5.2 Privacy a anticiper pour reviews

Si la section Reviews affiche :
- Nom complet client + photo + societe -> probable consentement utilisateurs deja obtenu (temoignages opt-in)
- **Note** : Clarity capturera ces noms / photos cote DOM. C est OK si testimonials sont des **clients reels qui ont consenti a etre presents sur le site marketing public**.
- Pas de probleme RGPD specifique (consentement temoignage = base juridique distincte de Clarity consent visiteur)

### 5.3 Mesures Clarity attendues pour CTA + Reviews

| Metrique Clarity | Utilisation business |
|---|---|
| Scroll depth section Reviews | % visiteurs qui voient les temoignages |
| Clic rate CTA variantes | Comparer placement / wording |
| Heatmap homepage | Identifier zones froides / chaudes |
| Rage clicks | Detection friction sur CTA non-cliquables ou mal places |
| Dead clicks (clic sans action) | Wording CTA peu clair ? boutton mal cible ? |
| Time to first interaction | Engagement homepage |

---

## 6. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 Clarity installe (Phase actuelle = decisions only)
- 0 session test
- 0 trafic fake
- 0 modification code
- 0 modification ConfigMap / env / secret
- 0 build / deploy / docker push / kubectl apply / GitOps commit
- 0 ticket Linear cree
- 0 PII / token / secret expose

---

## 7. NON-REGRESSION

Etat runtime inchange depuis AS.16.0 :

| Service | Image PROD |
|---|---|
| keybuzz-website | v0.6.12-linkedin-insight-seo-prod (UNCHANGED) |
| keybuzz-client | v3.5.197-channels-bff-userauth-prod (UNCHANGED) |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod (UNCHANGED) |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-prod (UNCHANGED) |

---

## 8. LINEAR (note brouillon KEY-322)

Pas necessaire de poster un commentaire separe pour cette note (qui complete AS.16.0). Si commentaire desire :

```
Note AS.16.0 : decisions business actees pour AS.16.1 + AS.16.2.

Decisions :
- 1 Project ID PROD commun keybuzz.pro + www.keybuzz.pro (Phase 1 website)
- Consent opt-in strict 3eme categorie RGPD session replay
- /cookies texte update obligatoire avant activation PROD
- Project IDs Clarity DEV + PROD a generer par Ludovic via clarity.microsoft.com (pre-requis bloquant AS.16.1)
- Project ID client.keybuzz.io funnel : decision deferred a AS.16.2 (meme commun ou ID separe pour lisibilite)
- /login inclusion Clarity : decision deferred a AS.16.2

Contexte complementaire : ajouts homepage anticipes (nouveaux CTA + reviews/avis clients). Le design ClarityProvider AS.16.1 sera independant des sections homepage specifiques -> capture automatique des nouveaux blocs sans toucher Clarity setup.

Funnel cible AS.16.2 : client.keybuzz.io /register + /signup + (peut-etre /login) avec masking strict email+password+company+phone. Onboarding /onboarding et SaaS authenticated restent strictement EXCLUS.

Aucun ticket Linear cree sans GO Ludovic. Aucune mutation. KEY-322 reste Open.

Rapport : keybuzz-infra/docs/PH-ADMIN-T8.12AS.16.0.1-CLARITY-BUSINESS-DECISIONS-AND-AS.16.1-AS.16.2-SCOPE.md
```

---

## 9. STATUT GLOBAL POST-DECISIONS

| Sous-phase | Statut | Pre-requis | Action prochaine |
|---|---|---|---|
| AS.16.0 | LIVRE 2026-05-15 (commit 9c4f843) | n/a | n/a |
| AS.16.0.1 | LIVRE 2026-05-15 (ce doc) | n/a | n/a |
| AS.16.1 DEV | PRET sur design | Ludovic genere 2 Clarity Project IDs (DEV + PROD) | Demarrer apres reception Project ID DEV + GO Ludovic |
| AS.16.1 PROD | PRET sur design | AS.16.1 DEV QA OK + /cookies texte update + Project ID PROD | Demarrer apres GO Ludovic |
| AS.16.2 DEV | DEFERRED | AS.16.1 PROD livre + decision Project ID client | Design detaille au moment du GO |
| AS.16.2 PROD | DEFERRED | AS.16.2 DEV QA OK | Promotion apres validation |
| AS.16.3 | DEFERRED | AS.16.2 PROD livre | Verification exclusion Admin + Client authenticated |
| AS.16.4 | DEFERRED | AS.16.3 livre | Docs agency handoff |

---

## 10. PHRASE CIBLE FINALE

Decisions business AS.16.0 actees. AS.16.1 design valide et compatible avec les ajouts homepage futurs (nouveaux CTA + reviews). Implementation pretes a demarrer DEV first des reception des Clarity Project IDs (DEV + PROD) generes par Ludovic via Microsoft Clarity dashboard. AS.16.2 funnel client.keybuzz.io detaille avec masking strict /register /signup et eventuellement /login. Exclusion stricte SaaS authentifie + Admin v2 maintenue. Aucun code touche dans cette phase. KEY-322 reste Open. Aucun enchainement AS.16.1 sans GO Ludovic explicite et Project IDs Clarity disponibles.

STOP
