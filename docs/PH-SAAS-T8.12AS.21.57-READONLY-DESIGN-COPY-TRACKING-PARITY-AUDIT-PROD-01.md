# PH-SAAS-T8.12AS.21.57 - Readonly Design Copy Tracking Parity Audit PROD

Date: 2026-06-15
Role: Codex Executor
Mode: READONLY DESIGN strict
Linear: KEY-337 reference parent PH-21, KEY-284/KEY-285 media buyer LP contract, KEY-322/KEY-325 Clarity references
Verdict: GO READONLY DESIGN COPY TRACKING PARITY AUDIT PROD READY_WITH_GAPS PH-SAAS-T8.12AS.21.57

## 1. Preflight

| Repo/service | Branche/image attendue | Observe | Dirty/ready | Verdict |
| --- | --- | --- | --- | --- |
| Bastion | install-v3 / 46.62.171.61 | install-v3 / IP OK | date UTC 2026-06-15 | OK |
| keybuzz-infra | main | 92def4f = origin | dirty 0 | OK |
| keybuzz-website | main / redesign audit | redesign/light-business 020794b = origin | dirty 0 | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ad4e862 = origin | dirty 1 preexistant tsconfig.tsbuildinfo | OK compris |
| keybuzz-api | ph147.4/source-of-truth | 76483e3 = origin | dirty preexistant | OK, non touche |
| Website DEV | v0.7.0-redesign-light-dev | ready 1/1, restarts 0, digest sha256:71be73f2...77ffff | runtime stable | OK |
| Website PROD | v0.6.22-clarity-restore-prod | ready 2/2, restarts 0, digest sha256:974350d5...87ac | runtime stable | OK |
| Client PROD | v3.5.259-ai-assist-notification-scope-prod | ready 1/1, restarts 0, digest sha256:e63494db...bf791 | runtime stable | OK |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | ready 1/1, restarts 0, digest sha256:ecc2080f...d5037 | runtime stable | OK |

Notes: dettes runtime non liees observees: backfill-scheduler ImagePullBackOff DEV/PROD et amazon-orders-worker PROD restarts preexistants. Aucune action.

## 2. Sources relues

- AI_MEMORY: CURRENT_STATE, RULES_AND_RISKS, DOCUMENT_MAP, CE_PROMPTING_STANDARD.
- Modele prompt: PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01.
- Tracking/media buyer: MEDIA_BUYER_LP_TRACKING_CONTRACT, PH-WEBSITE-T8.12AQ.4, PH-WEBSITE-T8.12AQ.4.1.
- Admin Campaign QA: PH-ADMIN-T8.11AN, PH-ADMIN-T8.11AO.
- Website copy/tracking: PH-WEBSITE-T8.12AQ.1A, 1A.1, 1A.2, 1A.3, 1A.4, 1A.5, 1B, AQ.2, AQ.3.
- Clarity/build args: PH-2015E/I/J/K, website-BUILD-ARGS, client-BUILD-ARGS.
- PH-21.55 StartTrial RCA and PH-21.56 precheckout temporal user journey.
- Runtime/source: keybuzz-website src/app/page.tsx, src/app/pricing/page.tsx, src/components/Analytics.tsx, src/components/ClarityProvider.tsx, src/components/Navbar.tsx, src/lib/tracking.ts.

## 3. Surface cible identifiee

| Surface | Source probable | Runtime/provenance | Modifiable via Git ? | Tracking porte | Verdict |
| --- | --- | --- | --- | --- | --- |
| www.keybuzz.pro / | keybuzz-website main | Website PROD v0.6.22 | Oui, via main pour PROD future | GA4, sGTM, Meta, TikTok, LinkedIn, Clarity | Corps PROD = source de verite hors hero |
| www.keybuzz.pro/pricing | keybuzz-website main | Website PROD v0.6.22 | Oui | UTM/click IDs/promo forwarding vers register | Source de verite pricing |
| preview / Website DEV | keybuzz-website redesign/light-business | Website DEV v0.7.0-redesign-light-dev | Oui, branche redesign/light-business | herite layout tracking, mais preview non canonique | Surface design a corriger en DEV |
| try.keybuzz.io | Webflow/Cloudflare | x-wf-region us-east-1, surrogate-key Webflow | Non via Git KeyBuzz | Meta + Clarity Webflow, script forwarding externe | GAP attribution owner |
| client.keybuzz.io/register | keybuzz-client | Client PROD v3.5.259 | Non cible PH-21.57 | signup_complete, Clarity client, dette GA4 connue | Read-only seulement |
| admin.keybuzz.io/marketing/campaign-qa | keybuzz-admin-v2 main | Admin PROD v2.12.2 | Non cible PH-21.57 | URL builder/Event Lab safe mode | Pas de patch requis |

Conclusion surface: la demande design/copy concerne la preview Website DEV issue de `redesign/light-business`. Le corps hors hero a remettre en parite doit reprendre `www.keybuzz.pro` / `keybuzz-website main` comme source de verite. `try.keybuzz.io` est une LP Webflow externe: elle ne doit pas etre patchee via Git.

## 4. Source-of-truth branch audit

| Source | Branche/tag/runtime | Hero DEV inventorie ? | Corps PROD correspond ? | Tracking correspond ? | Verdict |
| --- | --- | --- | --- | --- | --- |
| keybuzz-website current | redesign/light-business / 020794b | Oui | Non, page.tsx entierement redesign | Layout tracking conserve, pricing source identique | Patch DEV possible sur cette branche uniquement |
| keybuzz-website main | main / contient 5fc6f2b | Hero PROD valide | Oui | Oui, v0.6.22 runtime | Baseline corps PROD |
| Website DEV runtime | v0.7.0-redesign-light-dev | Oui par source 020794b | Non | non re-teste via preview auth dans ce rapport | Surface design |
| Website PROD runtime | v0.6.22-clarity-restore-prod | Hero PROD valide | Oui | Oui, bundle/HTML OK | Source de verite publique |
| Webflow LP | try.keybuzz.io | Externe | Non | forwarding incomplet | Instructions Webflow separees si cible active |

Relation claire: `redesign/light-business` est au-dessus de `main` et contient un commit redesign `020794b` modifiant `src/app/page.tsx`. `src/app/pricing/page.tsx` ne diverge pas significativement du main inspecte. La prochaine phase peut patcher DEV sans reintroduire une ancienne version si elle cible seulement `redesign/light-business` et restaure les sections hors hero depuis `main`.

## 5. Inventaire hero DEV actuel

| Section | Source DEV | Copy actuel | Peut changer ? | Raison |
| --- | --- | --- | --- | --- |
| Eyebrow | redesign page.tsx | OS IA pour le SAV marketplace / v2.4 | Oui | v2.4 ressemble a un label produit non verifie, a clarifier |
| H1 | redesign page.tsx | Automatisez votre SAV marketplace sans perdre le controle | Oui, avec validation Ludovic | Promesse centrale OK mais peut etre plus orientee marge/operation |
| Subtitle | redesign page.tsx | KeyBuzz centralise vos messages, commandes et litiges Amazon, Cdiscount, Fnac, Shopify, Mirakl, Octopia - puis aide votre equipe a repondre plus vite grace a une IA encadree par vos regles SAV. | Oui | Trop long et inclut des canaux a verifier selon disponibilite actuelle |
| Primary CTA | redesign page.tsx | Commencer gratuitement -> /pricing | Oui micro-copy seulement | Preferer le wording PROD "Essayer 14 jours gratuitement" |
| Secondary CTA | redesign page.tsx | Voir comment ca fonctionne -> #solution | Oui micro-copy seulement | OK |
| Badges | redesign page.tsx | 14 jours gratuits / IA + validation humaine / Sans engagement | Conserver | Promesses marketing valides |
| Visual | redesign page.tsx | cockpit fictif, IA suggestion, SLA risk, Autopilot securise | Conserver avec prudence | Doit rester demonstratif, pas KPI business prouve |

## 6. Propositions hero copy ameliorees

Verdict copy: HERO_COPY_PROPOSAL_READY.

| Zone | Copy actuel | Proposition | Raison | Risque | Recommandation |
| --- | --- | --- | --- | --- | --- |
| Hero A recommande | Automatisez votre SAV marketplace sans perdre le controle | Reprenez le controle de votre SAV marketplace avec une IA qui protege vos marges | Plus direct sur douleur vendeur: controle + marge + IA encadree | "protege vos marges" doit rester lie aux garde-fous, pas a un gain chiffre | Recommandee si Ludovic valide |
| Subtitle A | voir inventaire | KeyBuzz centralise vos messages, retrouve le contexte commande et prepare des reponses controlees pour Amazon, Cdiscount et vos canaux e-mail. Vous validez, automatisez seulement ce qui est sur. | Plus court, plus prudent sur les connecteurs, anti-autopilot aveugle | Ne mentionne pas Fnac/Shopify si futurs seulement | Recommandee |
| Hero B | idem | Un cockpit SAV pour vos marketplaces, vos commandes et vos decisions IA | Tres B2B SaaS, insiste sur cockpit operationnel | Moins conversion que A | Variante secondaire |
| Subtitle B | idem | Messages, commandes, tracking, playbooks et SLA dans un seul espace. L'IA suggere les bonnes actions, votre equipe garde la decision finale. | Tres clair pour produit | Moins emotionnel | Variante secondaire |
| Hero C | idem | Moins de remboursements subis. Des reponses marketplace plus rapides. | Focalise pertes + vitesse | Peut suggerer un resultat non chiffre, a cadrer | Variante testable seulement |
| Subtitle C | idem | KeyBuzz aide vos agents a prioriser les conversations, analyser le contexte commande et appliquer vos regles SAV sans declencher de remboursement automatique. | Tres anti-risque | Plus long | Utilisable si angle seller protection prioritaire |

Contraintes d'application PH-21.58: ne pas changer les URLs/CTA IDs, ne pas ajouter de fausse promesse de conversion, ne pas appliquer le hero sans choix explicite Ludovic.

## 7. Corps PROD hors hero a reprendre comme reference

| Section PROD | Type | Copy/titres critiques | Action DEV attendue | Raison |
| --- | --- | --- | --- | --- |
| Pain points | Problem | Si vous vendez sur marketplace, vous connaissez ca... / boite mail deborde / client de mauvaise foi / Garanties A a Z / delais SLA | Restaurer depuis main | Baseline ads validee AQ.2 |
| Comment ca marche | Mechanism | Centraliser & Classer / Analyser & Suggerer / Agir & Tracer | Restaurer depuis main | Explique produit sans surpromesse |
| CTA mid-page | Trial | Pret a essayer KeyBuzz sur vos messages reels ? / 14 jours d'essai gratuit | Restaurer depuis main | Conversion et trial proof |
| Benefices | Features | Contexte automatique / IA sous controle / Regles metier d'abord / Conformite marketplace / Tracabilite complete / Moins de travail repetitif | Restaurer depuis main | Features essentielles validees |
| Reassurance | Proof | Ce que KeyBuzz evite aux vendeurs marketplace | Restaurer depuis main | Proof sans faux temoignage |
| CTA apres reassurance | Navigation | Voir les offres / Comparer les fonctionnalites | Restaurer depuis main | Relais CTA tracking KEY-324 |
| Securite Amazon | Trust | Conformite Amazon SP-API / OAuth / moindre privilege / donnees limitees / audit | Restaurer depuis main | Critique Amazon/App review |
| Marketplaces | Integrations | Marketplaces & Integrations / Amazon, Cdiscount et autres marketplaces europeennes | Restaurer depuis main | Wording prudent |
| About | Founder trust | Qui est derriere KeyBuzz ? / Ludovic fondateur | Restaurer depuis main | Rassurance existante |
| FAQ | Objections | compatibilite marketplace, IA, risque Amazon, demarrage, annulation, protection donnees | Restaurer depuis main | Objection handling valide |
| Final CTA | Trial | 14 jours pour voir ce que KeyBuzz change dans votre SAV / Des 97EUR/mois | Restaurer depuis main | Coherence pricing actuelle |
| Footer/legal/cookies | Legal | Footer global, privacy/terms/cookies, CookieConsent | Conserver | Compliance/tracking consent |

## 8. Ecarts DEV vs PROD hors hero

| Ecart | DEV redesign | PROD main | Risque | Action PH-21.58 |
| --- | --- | --- | --- | --- |
| Pricing homepage | Starter 49 EUR / Pro 199 EUR / Autopilot sur devis | Pricing actuel 97 / 297 / 497 + Enterprise | Eleve: contradiction tarifaire | Supprimer bloc DEV ou remplacer par renvoi pricing PROD |
| KPI | -84% de temps SAV, benchmark interne | Pas de KPI chiffre equivalent | Eleve: metric non prouvee | Retirer sauf preuve validee |
| Canaux | Fnac, Shopify, Mirakl, Octopia listes dans hero/problem | Wording PROD plus prudent: Amazon, Cdiscount, e-mail, autres en preparation | Moyen/eleve: promesse connecteur | Aligner avec verite produit |
| Sections | Problem/Solution/Controlled AI/Order Cockpit/BeforeAfter/Pricing/FinalCTA | Pain/How/CTA/Benefits/Reassurance/Security/Marketplaces/About/FAQ/FinalCTA | Fort: perte sections SP-API/FAQ/About | Restaurer structure PROD hors hero |
| Claims Autopilot | Garde-fous automatiques, Autopilot securise | Autopilot configurable/sous garde-fous | Moyen | Garder prudent |
| Design | Light-business dense avec nombreuses cartes flottantes | LP paid search validee | Moyen | Garder hero design si valide, restaurer corps |

## 9. Propositions hors hero optionnelles (non appliquees par defaut)

| Section hors hero | Copy PROD actuel | Proposition optionnelle | Pourquoi | Appliquer en PH-21.58 ? |
| --- | --- | --- | --- | --- |
| Benefits | Ce que KeyBuzz change pour vous | Garder titre, ajouter sous-titre plus operationnel: "Moins de recherche, plus de decisions tracees." | Clarifie usage quotidien | Non par defaut |
| Security | Securite & protection de votre compte seller | Garder copy, eventuellement raccourcir la phrase API officielle | Lisibilite mobile | Non par defaut |
| FAQ IA | Est-ce que l'IA repond a la place de mes clients ? | Ajouter "jamais de remboursement automatique sans regle explicite" | Aligne seller protection | Non sans validation |
| Final CTA | 14 jours pour voir ce que KeyBuzz change... | Garder, option: "Essayez sur vos vrais messages, pas sur une demo vide." | Plus concret | Non sans validation |

## 10. Features/promesses a ne pas supprimer

| Feature/promise | Ou observee | Risque si supprimee | Must preserve | Commentaire |
| --- | --- | --- | --- | --- |
| 14 jours d'essai gratuit | Hero, pricing, CTA final | Perte conversion | Oui | Ne pas inventer "sans CB" |
| Sans engagement / annulation | Hero/pricing/final | Perte reassurance | Oui | Present PROD |
| Amazon / marketplace support | Homepage, FAQ, security | Perte positionnement | Oui | Wording prudent |
| IA SAV / copilote | Hero, benefits, pricing | Perte valeur produit | Oui | Toujours controlee |
| Validation humaine | Hero, FAQ, Controlled AI | Risque surpromesse IA | Oui | Point cle |
| Autopilot | Pricing, possible hero visual | Confusion plan | Oui avec garde-fous | Ne pas promettre tout automatique |
| Inbox / messages clients | Benefits, visual | Perte clarte produit | Oui | Core product |
| Order/tracking context | Benefits, cockpit | Perte differentiation | Oui | Important SAV marketplace |
| SP-API/OAuth/securite | Security, Amazon page | Risque compliance | Oui | Critique |
| Pricing plans/cycle/promo | Pricing page | Perte attribution/billing | Oui | 97/297/497 + promo forwarding |
| UTM/click ID forwarding | Navbar/pricing | Perte attribution | Oui | inclut owner sur Website |
| Legal/cookies/privacy | Layout/footer | Risque compliance | Oui | CookieConsent preserve |
| Clarity website/client | Website/client | Perte replay | Oui | Consent-gated |

## 11. CTA/tracking contract

| CTA | URL actuelle | Params requis presents | Click ID forwarding | Verdict | Action recommandee |
| --- | --- | --- | --- | --- | --- |
| Website homepage hero | /pricing | Pas de register direct; conserve query via navigation/pricing patterns si URL contient params | Via pricing page pour register | OK | Ne pas changer ctaId/href sans test |
| Website navbar signup | https://client.keybuzz.io/signup | ATTRIBUTION_KEYS inclut utm_*, gclid, fbclid, ttclid, marketing_owner_tenant_id, li_fat_id, _gl, promo | Oui | OK | Conserver |
| Website pricing Starter | client.keybuzz.io/register?plan=starter&cycle=monthly | pricing useEffect forwarde utm_*, gclid/fbclid/ttclid/li_fat_id, marketing_owner_tenant_id, _gl, promo | Oui | OK | Conserver |
| Website pricing Pro | client.keybuzz.io/register?plan=pro&cycle=monthly | idem | Oui | OK | Conserver |
| Website pricing Autopilot | client.keybuzz.io/register?plan=autopilot&cycle=monthly | idem | Oui | OK | Conserver |
| Website pricing final | client.keybuzz.io/register?plan=autopilot&cycle=monthly | idem | Oui | OK | Conserver |
| try.keybuzz.io register links | register, register?plan=starter/pro/autopilot&cycle=monthly | marketing_owner_tenant_id absent des static hrefs | trackingParams forwarde utm/click IDs mais PAS marketing_owner_tenant_id | GAP P0 | Webflow script doit ajouter marketing_owner_tenant_id avant traffic paid |

Test read-only `try.keybuzz.io/?utm_source=meta&utm_medium=cpc&utm_campaign=mb-test-ph2157&utm_content=test-link&fbclid=test123&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk`: inspection HTML/script seulement, aucun clic checkout/register. Resultat: `trackingParams` = utm_source, utm_medium, utm_campaign, utm_content, utm_term, fbclid, gclid, ttclid, li_fat_id, _gl, gbraid, wbraid, msclkid. `marketing_owner_tenant_id` absent. Donc owner non garanti au clic vers client.keybuzz.io/register.

## 12. Clarity / browser tracking parity

| Surface | Marker | Attendu | Observe | Verdict |
| --- | --- | --- | --- | --- |
| Website PROD home | wrff07upjx + clarity.ms/tag | present bundle, consent-gated | 1 + 1 via bundle scan | OK |
| Website PROD pricing | wrff07upjx + clarity.ms/tag | present bundle, consent-gated | 1 + 1 via bundle scan | OK |
| Website PROD home/pricing | GA4 G-R3QQDYEBFG | present | 2 / 2 via bundle scan | OK |
| Website PROD home/pricing | sGTM t.keybuzz.pro | present | 2 / 2 via bundle scan | OK |
| Website PROD home/pricing | Meta 1234164602194748 | present | 1 / 1 via bundle scan | OK |
| Website PROD home/pricing | TikTok D7PT12JC77U44OJIPC10 | present | 1 / 1 via bundle scan | OK |
| Website PROD home/pricing | LinkedIn 9969977 | present | 2 / 2 via bundle scan | OK |
| Website PROD | AW- direct | absent | 0 | OK |
| Website PROD | Purchase/CompletePayment/StartTrial/InitiateCheckout browser | absent | 0 | OK |
| Website PROD | Lead literal | no fake Lead call | 2 literal occurrences from source comments/guard text | OK with note |
| Client PROD | Clarity wuk12h9i33 | present per PH-20.15J | source/runtime history confirms | OK, not re-triggered |
| Client PROD | API prod base | https://api.keybuzz.io | PH-21.55/20.15 refs | OK |
| Client PROD | GA4 marker | debt from PH-21.55 | GA4 Client runtime parity debt remains | GAP known |
| try.keybuzz.io | Meta 1234164602194748 | if Webflow pixel active | present 2 | OK |
| try.keybuzz.io | Clarity | if Webflow tag active | clarity.ms/tag present | OK |
| try.keybuzz.io | Purchase/Lead/InitiateCheckout fake | absent | 0 observed | OK |

Interpretation: Website PROD tracking is intact. The only current attribution risk found in this phase is Webflow owner forwarding, not a Website Git regression.

## 13. Design audit read-only

No browser screenshot was taken to avoid adding extra interactive pageviews beyond the public GET/HTML audit. Design notes are based on source/runtime HTML and prior preview reports.

| Point design | Observe | Risque conversion | Recommendation PH-21.58 |
| --- | --- | --- | --- |
| Premier viewport DEV | Strong visual cockpit, dense floating cards | Good product signal, but possible visual overload | Keep hero visual only after mobile QA |
| Hero message | Strong but long subtitle | Dilution of promise | Apply validated hero variant only |
| Corps DEV | New redesign removes multiple PROD proof/trust sections | Loss of proven conversion and compliance content | Restore PROD body |
| Pricing embedded homepage | Outdated 49/199/devis | Direct pricing contradiction | Remove/replace |
| KPI visual | -84% benchmark | Unproven metric risk | Remove unless proof available |
| Palette/UI | Light business with blue/violet cards | Can become card-heavy but acceptable for SaaS if controlled | Avoid nested cards in body restoration |
| Mobile text | Source has long paragraphs and floating visuals | Overflow risk | Mandatory Playwright/mobile QA in patch phase |

## 14. No fake metrics / no fake events

| Garantie | Etat |
| --- | --- |
| POST | 0 |
| Fake event | 0 |
| Fake signup/trial/checkout/payment | 0 |
| StartTrial/Lead/Purchase/CompletePayment fake | 0 |
| CAPI test/provider endpoint | 0 |
| Stripe checkout | 0 |
| DB mutation | 0 |
| Build/deploy/kubectl apply | 0 |
| Webflow/Admin/Linear change | 0 |
| Consent manipulation volontaire | 0 |
| KPI invente | 0 |

GET publics effectues pour www.keybuzz.pro, /pricing et try.keybuzz.io: `QA_PAGEVIEW_POSSIBLE_NON_BUSINESS`. Ne pas utiliser comme preuve business.

## 15. Gaps

| Gap | Severite | Prochaine phase |
| --- | --- | --- |
| try.keybuzz.io ne forwarde pas `marketing_owner_tenant_id` vers register | P0 attribution media buyer si LP active | Instructions Webflow/Antoine ou patch Webflow separe avant traffic paid |
| DEV redesign body diverge de PROD hors hero | P0 copy/parity | Source patch Website DEV |
| DEV homepage pricing outdated 49/199/devis | P0 pricing | Source patch Website DEV |
| DEV KPI -84% non prouve dans sources auditees | P1 legal/trust | Retirer ou justifier |
| Client GA4 runtime marker absent/pas clos selon PH-21.55 | Dette tracking separee | Phase Client GA4 parity separee |
| Preview runtime auth HTML non inspecte directement dans ce rapport | Limite | Patch/source audit reste valide par source + runtime image |

## 16. Recommandation PH-21.58

Option A recommandee: source patch Website DEV.

- Repo: `/opt/keybuzz/keybuzz-website`.
- Branche: `redesign/light-business`.
- Fichiers probables: `src/app/page.tsx`, potentiellement composants `src/components/kb2/*` seulement si necessaire.
- Hero: appliquer uniquement la variante explicitement validee par Ludovic. Recommandation: Variante A.
- Corps hors hero: restaurer `main:src/app/page.tsx` comme reference pour toutes les sections hors hero, en conservant le shell/design si Ludovic le valide mais sans inventer de copy.
- Pricing: ne pas embarquer les tarifs 49/199/devis; garder la page pricing 97/297/497 comme source.
- Tracking: conserver `MarketingCTA`, ctaId, hrefs, data attributes, `Analytics`, `ClarityProvider`, `Navbar` forwarding, pricing UTM/click IDs/owner/promo.
- Tests offline: lint/typecheck si possible, grep no fake events, grep no client-dev/api-dev in Website PROD build assumptions, diff source DEV vs main.
- Build/deploy: hors scope PH-21.58 sauf GO separe.
- PROD: aucun changement sans GO explicite.

Option B a traiter en parallele/separement si `try.keybuzz.io` reste une LP media buyer active: instructions Webflow/Antoine pour ajouter `marketing_owner_tenant_id` dans `trackingParams` et verifier les hrefs register, sans fake event.

Prochain GO exact recommande:

`GO SOURCE PATCH WEBSITE DEV HERO COPY AND PROD BODY PARITY PH-SAAS-T8.12AS.21.58`

GO separe recommande pour Webflow si Ludovic confirme que try.keybuzz.io reste dans les campagnes:

`GO READONLY DESIGN WEBFLOW CTA OWNER FORWARDING FIX INSTRUCTIONS PH-SAAS-T8.12AS.21.58A`

## 17. Linear prepared text

PH-21.57 readonly design/copy/tracking audit termine. Surface design cible: Website DEV preview sur branche keybuzz-website redesign/light-business. Corps hors hero source de verite: Website PROD/main. Hero DEV inventorie et 3 variantes proposees sans application. Ecarts majeurs DEV: body non en parite, pricing homepage obsolete 49/199/devis, KPI -84% non prouve. Tracking Website PROD OK (Clarity wrff07upjx, GA4, sGTM, Meta, TikTok, LinkedIn). Pricing forwarding OK avec marketing_owner_tenant_id. Gap P0 externe: try.keybuzz.io Webflow ne forwarde pas marketing_owner_tenant_id dans son script, a corriger par phase Webflow separee si LP active. 0 POST, 0 fake event, 0 checkout, 0 DB/build/deploy. Verdict READY_WITH_GAPS.

## 18. Phrase cible

GO READONLY DESIGN COPY TRACKING PARITY AUDIT PROD READY_WITH_GAPS PH-SAAS-T8.12AS.21.57

STOP.
