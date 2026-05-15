# PH-ADMIN-T8.12AS.16.0-MICROSOFT-CLARITY-DESIGN-AUDIT-01

> Date : 2026-05-15
> Linear : KEY-322 related (parent tracking audit). KEY-301/KEY-313 Done. KEY-314 Open + pause AS.14.2.
> Phase : T8.12AS.16.0 (design audit docs-only Microsoft Clarity)
> Environnement : design only (aucun code, aucune env var ajoutee, aucun build, aucun deploy)

---

## 0. VERDICT

GO MICROSOFT CLARITY DESIGN READY.

Le design pour integrer Microsoft Clarity est valide et coherent avec l existant analytics stack KeyBuzz. Aucune installation faite. Aucune env var ajoutee. Aucun ticket Linear cree.

L architecture proposee :
- Phase 1 (AS.16.1) : Clarity sur keybuzz-website pages marketing publiques (homepage, pricing, features, about, contact, amazon/*) - faible risque PII
- Phase 2 (AS.16.2) : Clarity sur keybuzz-client funnel pre-auth (/login, /register, /signup, /onboarding) avec masking strict password/email/company/phone
- Phase 3 (AS.16.3) : verification stricte d EXCLUSION sur Admin v2 + routes authenticated sensibles Client (Inbox, orders, settings, billing, channels, suppliers, knowledge, playbooks, ai-journal, dashboard)

Stack analytics existant deja consent-aware (GA4 + sGTM + Meta + TikTok + LinkedIn via Consent Mode v2 + CookieConsent banner + politique cookies + privacy policy). Clarity s ajoute proprement en suivant le meme pattern.

Cinq decisions business a prendre avant lancement AS.16.1 (cf section 9) : Project IDs, consent category specifique session replay, domain strategy keybuzz.pro/www, masking strategy registre form, periode pre-lancement.

KEY-322 reste Open. Ticket Linear dedie propose pour AS.16.x mais non cree (attente GO Ludovic).

---

## 1. PERIMETRE EXACT DE CETTE PHASE

Scope strict (AS.16.0 design audit READ-ONLY) :
- 0 implementation Clarity
- 0 script Microsoft ajoute
- 0 env var ajoutee
- 0 secret modifie
- 0 build / docker push / kubectl apply / manifest edit / GitOps commit
- 0 patch source
- 0 ticket Linear cree (KEY-322 commentaire prepare uniquement, non poste sans GO)
- 0 tracking live / capture session / appel Microsoft Clarity
- 0 changement consentement / RGPD / cookies

Actions effectuees :
- SSH read-only install-v3 (46.62.171.61 confirme, pas 51.159.99.247)
- git status read-only sur 6 repos
- kubectl get deploy / ingress read-only
- Agent Explore cartographie source code keybuzz-website + keybuzz-client + keybuzz-admin-v2

---

## 2. PREFLIGHT

### 2.1 Bastion + repos

| Champ | Valeur |
|---|---|
| Bastion | install-v3 (46.62.171.61, conforme) |
| IP interdite | 51.159.99.247 (NON CONTACTE) |

| Repo | Branche | HEAD | Verdict |
|---|---|---|---|
| keybuzz-website | main | 660dc60 (KEY-308 OCI) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | 3fe90ab (AS.14.1-FIX) | OK |
| keybuzz-admin-v2 | main | 3707c83 (KEY-308 OCI) | OK |
| keybuzz-infra | main | b8bfc0f (AS.15.3.1 context) | OK |

### 2.2 Runtime + domains

| Service | Image | Domain |
|---|---|---|
| keybuzz-website PROD | v0.6.12-linkedin-insight-seo-prod | www.keybuzz.pro + keybuzz.pro |
| keybuzz-website DEV | v0.6.12-linkedin-insight-seo-dev | (a determiner, probable www-dev.keybuzz.pro) |
| keybuzz-client PROD | v3.5.197-channels-bff-userauth-prod | client.keybuzz.io |
| keybuzz-client DEV | v3.5.197-channels-bff-userauth-dev | client-dev.keybuzz.io |
| keybuzz-admin-v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod | admin.keybuzz.io |

---

## 3. INVENTAIRE SURFACES

### 3.1 keybuzz-website (Next.js 16.1.4 standalone)

Pages publiques marketing :

| Surface | Repo | Route | Audience | Donnees visibles | Sensibilite | Clarity |
|---|---|---|---|---|---|---|
| Homepage | website | / | Public marketing | Hero, pain points, features | ZERO | OUI |
| Pricing | website | /pricing | Prospects/trials | 3 plans + Enterprise + CTA register | ZERO | OUI |
| Features | website | /features | Public marketing | Feature showcase | ZERO | OUI |
| About | website | /about | Public marketing | Equipe / vision | ZERO | OUI |
| Contact | website | /contact | Prospects | Form contact (email + message) | LOW (email opt-in) | OUI avec masking |
| Amazon sales | website | /amazon, /amazon/security, /amazon/data-usage | Public marketing | Integration docs | ZERO | OUI |
| Privacy | website | /privacy | Public legal | Politique RGPD | ZERO | OUI (peu d interet) |
| Cookies | website | /cookies | Public legal | Politique cookies | ZERO | OUI (peu d interet) |
| Terms / Legal / SLA | website | /terms, /legal, /sla | Public legal | CGU/CGV/SLA | ZERO | OUI (peu d interet) |

CTA Pricing -> redirige vers `client.keybuzz.io/register?plan=X` (cross-domain, linker GA4 deja configure).

### 3.2 keybuzz-client pre-auth (funnel)

Pages pre-auth :

| Surface | Repo | Route | Audience | Donnees visibles | Sensibilite | Clarity |
|---|---|---|---|---|---|---|
| Login | client | /login | Prospects funnel | Form email + password | **HIGH** (password input) | OUI avec MASKING obligatoire |
| Register | client | /register | Prospects funnel | Form email + password + company + plan | **HIGH** (multi-PII) | OUI avec MASKING obligatoire |
| Signup | client | /signup | Alias register | idem | HIGH | OUI avec MASKING |
| Onboarding | client | /onboarding | New users (auth post-signup) | Setup workspace | MODERATE (company, tenant config) | NO (post-auth, sensitive) |
| Auth callbacks | client | /auth, /auth/[...callbacks] | OAuth providers | Tokens, codes | CRITICAL | NO (technical flow) |

### 3.3 keybuzz-client authenticated (EXCLUSION STRICTE)

Pages a EXCLURE Clarity :

| Surface | Route | Raison exclusion |
|---|---|---|
| Inbox | /inbox, /inbox/* | HAUT PII : messages clients reels, customer email, marketplace order details |
| Orders | /orders, /orders/* | HAUT PII : numeros commande, tracking carrier, amounts, customer addresses |
| Dashboard | /dashboard | MODERATE : KPIs metiers, business intelligence |
| Settings | /settings, /settings/* | HIGH PII : tenant config, webhook secrets, API keys preview |
| Billing | /billing, /billing/* | CRITIQUE : carte bancaire (Stripe Elements), facturation, transactions |
| Channels | /channels, /channels/* | HIGH PII : OAuth tokens preview, marketplace credentials state |
| Suppliers | /suppliers, /suppliers/* | MODERATE : fournisseur data, contacts |
| Knowledge | /knowledge, /knowledge/* | SENSIBLE : regles metier custom, IA context, business logic |
| Playbooks | /playbooks, /playbooks/* | SENSIBLE : automations, escalation rules |
| AI Journal | /ai-journal, /ai-journal/* | HIGH : journal IA detaille, decisions, contexte enrichi conversations |
| Workspace setup | /workspace-setup, /start | SENSIBLE : onboarding admin marketplace |
| Help | /help, /help/* | LOW mais utile a exclure pour consistency |

### 3.4 keybuzz-admin-v2 (EXCLUSION TOTALE)

| Surface | Route | Raison exclusion |
|---|---|---|
| Admin home | / | CRITIQUE : interne SaaS Ludovic + agence, jamais expose clients |
| Marketing | /marketing/* | CRITIQUE : Ad accounts, destinations, delivery logs, conversions |
| Tenants | /tenants/* | CRITIQUE : liste tous tenants clients, business intelligence |
| Users | /users/* | CRITIQUE : utilisateurs clients, emails, permissions |
| Logs | /logs/* | CRITIQUE : audit logs internes |
| Tous autres | /* | CRITIQUE : interne uniquement |

**Decision** : Admin v2 ne doit JAMAIS recevoir Clarity. Recommandation : meme pas d env var Clarity injectee dans le manifest Admin v2.

---

## 4. PRIVACY / PII RISK AUDIT

### 4.1 Zones critiques identifiees

| Zone | PII possible | Risque session replay Clarity | Masquage necessaire |
|---|---|---|---|
| Form login email | email user | Capture email in DOM | YES `data-clarity-mask` ou class `.clarity-mask` |
| Form login password | password (clair pendant typing) | Capture password keystrokes potential | YES (Clarity native + `input[type=password]` auto-masked par defaut) |
| Form register email | email | idem | YES |
| Form register password | password | idem | YES |
| Form register company name | nom societe (peut etre PII) | Capture company name | YES |
| Form contact website (email + message) | email + texte libre | Capture content | YES si form Clarity-enabled |
| Customer name display | si afichage post-auth | n/a (Clarity exclu post-auth) | EXCLUSION suffit |
| Marketplace order tracking | tracking numbers, addresses | n/a (Clarity exclu /orders) | EXCLUSION suffit |
| Billing card | Stripe Elements iframe | Stripe iframe = isole, Clarity ne capture pas | EXCLUSION + iframe natif suffit |
| API keys preview Admin | partial keys visible | n/a (Clarity exclu Admin) | EXCLUSION TOTALE Admin |

### 4.2 Strategie de masking pour Phase 2 (Client funnel)

Configuration Clarity dashboard cote Microsoft :
- **Mode** : "Mask all by default, unmask selectively" (recommande pour RGPD)
- Champs `input[type="password"]` : auto-mask Clarity (par defaut)
- Champs `input[type="email"]` : add `data-clarity-mask="true"`
- Champs `input[name*="company"]`, `input[name*="phone"]`, `input[name*="card"]` : `data-clarity-mask="true"`
- localStorage keys contenant `token`, `auth`, `secret`, `api_key` : configurer Clarity custom redaction rules
- URL parameters sensibles : ne pas inclure tokens dans URLs (deja respecte cote KeyBuzz)

### 4.3 Risque DOM capture

Clarity capture le DOM serialisable. Risque si :
- Composants React rendent du contenu sensible cote DOM (memes pages exclues, le `display:none` parent ne suffit pas)
- Toasts/notifications rendent messages clients (verifier client-side)

Mitigation :
- Strict route-level exclusion via `excludePages` config Clarity
- Double protection : conditional `<ClarityProvider>` mount + Clarity SDK `excludePages`

---

## 5. ANALYTICS / CONSENT STACK EXISTANT

### 5.1 Stack analytics actuel

| Stack | Present | Where | Consent-aware | Notes |
|---|---|---|---|---|
| GA4 | OUI (G-R3QQDYEBFG) | Website + Client funnel (registered/login) | OUI Consent Mode v2 | NEXT_PUBLIC_GA4_MEASUREMENT_ID |
| sGTM | OUI (t.keybuzz.pro) | Website + Client | OUI | NEXT_PUBLIC_SGTM_URL |
| Meta Pixel | OUI (1234164602194748) | Website + Client funnel | OUI | NEXT_PUBLIC_META_PIXEL_ID |
| TikTok Pixel | OUI (D7PT12JC77U44OJIPC10) | Website + Client funnel | OUI | NEXT_PUBLIC_TIKTOK_PIXEL_ID |
| LinkedIn Insight | OUI (9969977) | Website + Client funnel | OUI | NEXT_PUBLIC_LINKEDIN_PARTNER_ID |
| **Clarity** | **NON** | --- | --- | A AJOUTER |
| Hotjar | NON | --- | --- | --- |
| Fullstory | NON | --- | --- | --- |

### 5.2 Consent banner existant

| Composant | Path | Comportement |
|---|---|---|
| CookieConsent.tsx | `/opt/keybuzz/keybuzz-website/src/components/CookieConsent.tsx` | Banner bas de page (fixed), boutons "Accepter" + "Refuser cookies optionnels" |
| Storage | localStorage key `keybuzz_cookie_consent` | Persist 12 mois, re-displays si version change |
| Default consent | analytics_storage=granted, ad_storage=denied | GA4 OK, ads pause |

### 5.3 Funnel-aware tracking (Client)

Composant `SaaSAnalytics` dans Client :
- `FUNNEL_PREFIXES = ['/register', '/login']` -> charge GA4 + Meta + tracking pixels
- `BLOCKED_PREFIXES = ['/inbox', '/dashboard', '/orders', '/settings', '/channels', '/suppliers', '/knowledge', '/playbooks', '/ai-journal', '/billing', '/onboarding', '/workspace-setup', '/start', '/help']` -> **NOT loaded**

Resultat : GA4 + Meta + TikTok + LinkedIn n ont JAMAIS de pageview sur les pages sensibles. Clarity doit suivre le **MEME pattern** : meme allowlist (funnel pages) + meme blocklist (sensitive pages).

### 5.4 Privacy / Cookies policy

| Page | URL | Status | Content |
|---|---|---|---|
| Politique de confidentialite | https://keybuzz.pro/privacy | PUBLIE 2026-01 | Responsable traitement KeyBuzz Consulting LLP UK, conformite RGPD |
| Politique cookies | https://keybuzz.pro/cookies | PUBLIE 2026-01 | Dit "aucun cookie optionnel actif" (a mettre a jour si Clarity active) |

**Gap a noter** : la politique cookies actuelle dit *"Aucun outil de mesure d audience tiers n est actuellement actif"*. Si Clarity est active, cette phrase devient FAUSSE et la politique doit etre mise a jour AVANT activation Clarity.

---

## 6. DESIGN INTEGRATION PROPOSE

### 6.1 Architecture composant

Composant `ClarityProvider` (a creer en AS.16.1) :

```typescript
// src/components/ClarityProvider.tsx (PROPOSITION, non implemente)
'use client';
import { useEffect } from 'react';
import { usePathname } from 'next/navigation';

const CLARITY_PROJECT_ID = process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID;
const CLARITY_ENABLED_ROUTES = ['/login', '/register', '/signup']; // Client funnel
// Website : enabled sur toutes routes publiques (pas de routes authenticated cote website)

export function ClarityProvider() {
  const pathname = usePathname();
  useEffect(() => {
    if (!CLARITY_PROJECT_ID) return; // no-op fallback if env var absent
    if (!hasConsentForClarity()) return; // consent gate
    if (typeof window === 'undefined') return;
    if (!isRouteAllowed(pathname)) return;
    loadClarityScript(CLARITY_PROJECT_ID);
  }, [pathname]);
  return null;
}
```

### 6.2 Env vars proposees

| Env var | Service | DEV | PROD | Type |
|---|---|---|---|---|
| NEXT_PUBLIC_CLARITY_PROJECT_ID | keybuzz-website + keybuzz-client | Project ID DEV (a creer Microsoft Clarity dashboard) | Project ID PROD (a creer) | Public (NEXT_PUBLIC_) |

Aucune env var SECRET necessaire (Clarity Project ID est public-safe).

### 6.3 Consent gate

Etendre `CookieConsent.tsx` :
- Ajouter une 3eme categorie : "Heatmaps & session replay (Clarity)"
- Storage : ajouter key `keybuzz_clarity_consent` (boolean) avec validation 12 mois
- Default : `denied` (opt-in obligatoire RGPD pour session replay)
- ClarityProvider check `hasConsentForClarity()` avant load script

### 6.4 Allowlist / Blocklist

| Surface | Allowlist (Clarity OUI) | Blocklist (Clarity NON) |
|---|---|---|
| keybuzz-website | / + /pricing + /features + /about + /contact + /amazon + /amazon/security + /amazon/data-usage + /privacy + /cookies + /terms + /legal + /sla | (rien : tout public sur website) |
| keybuzz-client | /login + /register + /signup | TOUS les autres (Inbox, dashboard, orders, settings, billing, channels, suppliers, knowledge, playbooks, ai-journal, onboarding, workspace-setup, start, help, auth callbacks) |
| keybuzz-admin-v2 | (rien) | TOUS routes Admin |

### 6.5 No hardcode

- Clarity Project ID **JAMAIS** hardcode dans le code source
- Env var NEXT_PUBLIC_CLARITY_PROJECT_ID via K8s ConfigMap (pas Secret, valeur publique)
- DEV vs PROD : 2 Project IDs separes (dashboards Clarity distincts pour analyses propres)
- Fallback no-op : si env var absente, `ClarityProvider` ne fait rien (pas d erreur, pas de script)

---

## 7. PHASES PROPOSES

### 7.1 AS.16.1 Website Clarity DEV (P1)

- Type : code change keybuzz-website DEV first
- Fichiers probables :
  - `src/components/ClarityProvider.tsx` (nouveau)
  - `src/components/CookieConsent.tsx` (ajout 3eme categorie)
  - `src/app/layout.tsx` (mount ClarityProvider apres CookieConsent + Analytics)
  - `src/app/cookies/page.tsx` (mettre a jour politique cookies pour mentionner Clarity)
  - K8s ConfigMap keybuzz-website-dev : ajouter NEXT_PUBLIC_CLARITY_PROJECT_ID (DEV ID)
- Tests : navigation pages publiques DEV, verifier Clarity charge avec consent OK + ne charge pas si refus
- Rollback : revert composant + manifest, image v0.6.12 reste valide
- QA : Ludovic + agence visite manuellement DEV, verifier Clarity dashboard Microsoft recoit sessions
- Privacy checks : pas de PII captee (form contact si present, verifier mask)
- GO required : OUI (Ludovic genere les Clarity Project IDs + decide consent strategy)

### 7.2 AS.16.1-PROD Website Clarity PROD (P1 apres AS.16.1)

- Type : promotion PROD apres QA DEV OK
- Patterns : build-from-git website (v0.6.13-clarity-prod ou similaire), KEY-308 OCI, KEY-309 tag check
- Manifest : ConfigMap PROD ajoutee
- QA : Ludovic visite https://www.keybuzz.pro + verifier Clarity recoit sessions PROD
- Rollback : revert manifest, retour v0.6.12-linkedin-insight-seo-prod
- GO required : OUI

### 7.3 AS.16.2 Signup/onboarding Clarity DEV+PROD avec masquage (P2)

- Type : code change keybuzz-client DEV first
- Fichiers probables :
  - `src/components/ClarityProvider.tsx` (nouveau, equivalent website)
  - `src/components/tracking/SaaSAnalytics.tsx` (NE PAS modifier le funnel pattern existant)
  - `app/register/page.tsx` + `app/login/page.tsx` : ajouter `data-clarity-mask` sur inputs sensibles
  - `app/layout.tsx` (mount ClarityProvider conditional pages funnel)
  - K8s ConfigMap keybuzz-client-dev + keybuzz-client-prod : NEXT_PUBLIC_CLARITY_PROJECT_ID
- Tests : navigation /login, /register, /signup avec consent OK -> Clarity charge ; sur /inbox -> Clarity NON charge (consistency avec GA4 funnel pattern)
- Privacy validation : capture session DEV, verifier dans Microsoft Clarity que password + email sont [REDACTED]
- Rollback : revert composant + manifest
- GO required : OUI

### 7.4 AS.16.3 Verification exclusion Admin v2 + sensitive Client (P1 priorite : avant AS.16.1 ?)

- Type : audit READ-ONLY + assertions
- Verifier que Clarity n est PAS injectable dans Admin v2 sans config explicite (pas de NEXT_PUBLIC_CLARITY_PROJECT_ID dans manifest Admin)
- Tests : QA navigateur Admin PROD avec Network tab DevTools : aucune requete vers clarity.ms
- Tests : QA navigateur Client sur /inbox, /orders, /dashboard, /settings, /billing, etc. -> aucune requete clarity.ms
- GO required : OUI (verification)

### 7.5 AS.16.4 Agency handoff docs (P3)

- Type : docs only
- Mettre a jour MEDIA-BUYER-TRACKING-GUIDE.md avec :
  - Acces Clarity dashboard pour Ludovic + Antoine + agence
  - Limites attendues (pages publiques + funnel only, pas authenticated)
  - Politique masking
  - URL dashboards Clarity DEV + PROD
- Ludovic donne acces directement dans Microsoft Clarity (pas de gestion droits cote KeyBuzz)
- GO required : non (docs only)

### 7.6 Tableau plan synthese

| Phase | Surface | Routes incluses | Routes exclues | Conditions | Tests |
|---|---|---|---|---|---|
| AS.16.1 DEV | keybuzz-website | Toutes pages marketing | Aucune | DEV Project ID + consent | Navigation DEV + Clarity dashboard receive |
| AS.16.1-PROD | keybuzz-website PROD | Toutes pages marketing | Aucune | PROD Project ID + consent | Navigation PROD + dashboard |
| AS.16.2 | keybuzz-client | /login + /register + /signup | TOUS authenticated | Funnel allowlist + consent + masking | Capture session, verify [REDACTED] |
| AS.16.3 | Admin v2 | (aucune) | TOUTES | Pas d env var Clarity dans manifest | Network tab DevTools 0 requete clarity.ms |
| AS.16.4 | Docs only | n/a | n/a | n/a | Mise a jour MEDIA-BUYER-TRACKING-GUIDE |

---

## 8. AGENCY / ANTOINE ACCESS MODEL

| Sujet | Decision |
|---|---|
| Acces Clarity dashboard | Ludovic gere directement dans Microsoft Clarity UI (clarity.microsoft.com) |
| Droits a accorder | Antoine media buyer + agence marketing nominee, scope read-only sur dashboards Website + Client funnel |
| Gestion droits cote KeyBuzz | AUCUN (Microsoft Clarity gere ses propres permissions) |
| Stockage identifiants Microsoft | AUCUN (Clarity Project IDs sont PUBLIC, pas de secret) |
| Clarity Project ID exposure | NEXT_PUBLIC_ env var acceptable (project ID public-safe par design Microsoft) |

---

## 9. DECISIONS BUSINESS A PRENDRE AVANT AS.16.1

| # | Question | Options | Recommandation |
|---|---|---|---|
| 1 | Clarity Project IDs DEV + PROD a creer ? | Reuser 1 seul ID ou 2 separes ? | 2 separes (DEV / PROD) pour analyses propres + eviter pollution dashboard PROD |
| 2 | Consent obligation RGPD session replay | (a) opt-in strict 3eme categorie / (b) opt-in implicite via cookie banner global / (c) opt-out | (a) opt-in strict (RGPD recommande session replay) |
| 3 | Domain strategy keybuzz.pro vs www.keybuzz.pro | Si Clarity sert sur les 2 hosts ingress, 1 Project ID ou 2 ? | 1 Project ID partage entre les 2 hosts (meme audience) |
| 4 | Masking strategy `/register` form | (a) Clarity native masking inputs + add data-clarity-mask / (b) iframe isole pour register / (c) serveur-side proxy | (a) Clarity native + data-clarity-mask sur company / phone (suffisant en pratique RGPD) |
| 5 | Mettre a jour politique cookies AVANT activation Clarity ? | OUI obligatoire | OUI : mettre a jour /cookies texte AVANT GO AS.16.1-PROD |

---

## 10. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 session Clarity creee (Clarity n est pas installe)
- 0 trafic fake
- 0 conversion fake
- 0 event analytics declenche
- 0 modification configurations Clarity Microsoft
- 0 modification DB
- 0 build / docker push / kubectl apply / manifest edit
- 0 ticket Linear cree
- 0 secret / token / project ID expose

---

## 11. NON-REGRESSION

Aucune action mutationnelle pendant l audit. Etat avant = etat apres pour :

| Service | Image PROD |
|---|---|
| keybuzz-website | v0.6.12-linkedin-insight-seo-prod (UNCHANGED) |
| keybuzz-client | v3.5.197-channels-bff-userauth-prod (UNCHANGED) |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod (UNCHANGED) |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-prod (UNCHANGED) |

DEV inchange. Aucune env var ajoutee. Aucun composant cree.

---

## 12. LINEAR (commentaire propose KEY-322)

Commentaire propose pour KEY-322 (disclosure-controlled, sans secret) :

```
PH-ADMIN-T8.12AS.16.0 Microsoft Clarity design audit livre.

Verdict : GO MICROSOFT CLARITY DESIGN READY.

Stack analytics existant deja consent-aware (GA4 + sGTM + Meta + TikTok + LinkedIn via Consent Mode v2 + CookieConsent banner). Clarity s ajoute proprement sans toucher au pipeline server-side CAPI (independant).

Architecture proposee :
- Phase 1 AS.16.1 : Clarity sur keybuzz-website pages marketing publiques (homepage, pricing, features, about, contact, amazon/*, legal). 12 routes incluses, 0 exclues car site marketing public.
- Phase 2 AS.16.2 : Clarity sur keybuzz-client funnel pre-auth (/login, /register, /signup) avec masking strict via data-clarity-mask sur password + email + company + phone. 14 routes authenticated EXCLUES strictement (Inbox, dashboard, orders, settings, billing, channels, suppliers, knowledge, playbooks, ai-journal, onboarding, workspace-setup, start, help).
- Phase 3 AS.16.3 : verification exclusion Admin v2 + sensitive Client. Network DevTools 0 requete clarity.ms sur ces routes.
- Phase 4 AS.16.4 : agency handoff docs (MEDIA-BUYER-TRACKING-GUIDE update).

Env vars (publiques, pas de secret) :
- NEXT_PUBLIC_CLARITY_PROJECT_ID (DEV) sur keybuzz-website-dev + keybuzz-client-dev
- NEXT_PUBLIC_CLARITY_PROJECT_ID (PROD) sur keybuzz-website-prod + keybuzz-client-prod
- AUCUNE env var Clarity sur Admin v2 (exclusion totale)

5 decisions business a prendre avant AS.16.1 :
1. 2 Clarity Project IDs DEV/PROD a creer ?
2. Consent opt-in strict 3eme categorie RGPD session replay ?
3. Domain strategy : 1 Project ID partage keybuzz.pro + www ?
4. Masking strategy /register : Clarity native + data-clarity-mask ?
5. Mise a jour politique cookies AVANT activation Clarity (texte actuel dit "aucun outil tiers actif") ?

Ticket Linear dedie propose mais NON cree sans GO Ludovic :
- Titre : Website/Client integrer Microsoft Clarity avec consentement et masquage PII
- Priorite : High
- Relations : related to KEY-322 (tracking/acquisition). PAS lie a KEY-314 (Clarity n impacte pas Client BFF security surfaces).

Hygiene :
- 0 Clarity installe
- 0 script Microsoft ajoute
- 0 env var modifiee
- 0 build / deploy
- 0 ticket Linear cree
- 0 PII / secret / token expose

KEY-322 reste Open. KEY-301 et KEY-313 restent Done. KEY-314 reste Open + pause AS.14.2.

Rapport : keybuzz-infra/docs/PH-ADMIN-T8.12AS.16.0-MICROSOFT-CLARITY-DESIGN-AUDIT-01.md
```

Aucun changement Linear statut effectue. Aucun ticket cree.

---

## 13. AI FEATURE PARITY / ANTI-REGRESSION

| Surface | Risque Clarity | Mitigation |
|---|---|---|
| Inbox | HAUT (messages clients) | Exclusion /inbox totale + verification Network DevTools |
| Brouillon IA | HAUT (contenu IA + escalation) | Exclusion /inbox couvre, exclusion /ai-journal aussi |
| Messages | HAUT (PII conversation) | Exclusion /inbox |
| Commandes | HAUT (order details) | Exclusion /orders |
| Escalation | MODERATE (status info) | Exclusion /inbox couvre |
| Playbooks | SENSIBLE (rules) | Exclusion /playbooks |
| Channels | HAUT (OAuth state) | Exclusion /channels |
| Admin v2 navigation | CRITIQUE | Exclusion totale Admin v2 |

Aucune action mutationnelle dans ces surfaces. Design respecte le principe "Clarity sur surface publique + funnel pre-auth uniquement".

---

## 14. GAPS / UNKNOWNS

| Gap | Statut | Action proposee |
|---|---|---|
| Microsoft Clarity Project IDs (DEV + PROD) | NOT YET CREATED | Ludovic genere via clarity.microsoft.com avant AS.16.1 |
| Politique cookies texte "aucun outil tiers actif" | OUTDATED apres Clarity activation | Update /cookies/page.tsx AVANT AS.16.1-PROD |
| Texte CookieConsent banner | Doit etre etendu pour mentionner Clarity | Update CookieConsent.tsx (AS.16.1) |
| DEV website domain exact | A confirmer (probable www-dev.keybuzz.pro ou keybuzz-dev.pro) | Verifier ingress keybuzz-website-dev |
| Cross-domain linking Clarity | Doit-il etre configure Clarity-side ? | Investiguer Microsoft Clarity docs |
| Tests E2E sur DEV | A faire dans AS.16.1 | Inclus dans plan |

Aucun gap bloquant pour le design.

---

## 15. PHRASE CIBLE FINALE

Microsoft Clarity design pret pour integration en 4 phases controlees. Phase 1 website marketing public (12 routes safe), Phase 2 client funnel pre-auth (3 routes avec masking strict), Phase 3 exclusion Admin v2 + Client authenticated, Phase 4 agency handoff docs. Stack analytics existant + consent + privacy policy + CookieConsent banner deja en place permet integration propre. 5 decisions business a prendre avant AS.16.1 (Project IDs, consent strict, domain, masking, politique cookies update). Aucun code, env var, ticket Linear cree dans cette phase. KEY-322 reste Open. Aucun enchainement AS.16.1 sans GO Ludovic explicite.

STOP
