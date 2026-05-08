# PH-WEBSITE-T8.12AQ.4 - Media Buyer LP Autonomy Tracking Contract

> Phase : PH-WEBSITE-T8.12AQ.4-MEDIA-BUYER-LP-AUTONOMY-TRACKING-CONTRACT-01
> Date : 2026-05-09
> Ticket : KEY-284
> Parent : KEY-253
> Verdict : **GO PARTIEL - IMPLEMENTATION REQUIRED**

---

## Résumé exécutif

L'audit révèle que le système d'attribution KeyBuzz est **remarquablement mature**. L'autonomie media buyer est **déjà possible à 90%** grâce au système existant. Le vrai mécanisme d'attribution est le **contrat URL des CTA**, pas le pixel Meta.

**Meta Pixel seul ne suffit PAS pour l'attribution KeyBuzz complète.** Il suffit uniquement pour le retargeting Meta et l'optimisation algorithmique Meta. L'attribution KeyBuzz, le server-side tracking, le routing marketing owner, et les promos reposent entièrement sur les **paramètres URL transmis dans les liens CTA**.

Un media buyer peut créer autant de LP qu'il veut sans intervention Ludovic, à condition de respecter le contrat URL documenté ci-dessous.

---

## 0. Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-website | main | `5fc6f2b` (AQ.3) | Non | OK |
| keybuzz-infra | main | `7f3bf8a` (AQ.3 report) | Non | OK |
| keybuzz-client | ph148/onboarding-activation-replay | `5e24487` | Non | OK |
| keybuzz-api | ph147.4/source-of-truth | `9521fb35` | dist/ artifacts only | OK |
| keybuzz-admin-v2 | main | `22a268e` | Non | OK |

| Service | Image PROD attendue | Runtime | Match |
|---|---|---|---|
| Website | `v0.6.12-linkedin-insight-seo-prod` | match | OK |
| API | `v3.5.147-auto-assignment-after-reply-prod` | match | OK |
| Client | `v3.5.170-shopify-visible-disabled-channels-prod` | match | OK |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | match | OK |
| OW | `v3.5.165-escalation-flow-prod` | match | OK |
| Admin | `v2.12.1-promo-codes-foundation-prod` | match | OK |

---

## 1. Inventaire tracking actuel KeyBuzz

### Architecture tracking complète

| Signal | Où capturé | Où transmis | Où stocké | Où visible | Risque LP ext |
|---|---|---|---|---|---|
| GA4 pageview | Website `Analytics.tsx` | Google Analytics via sGTM | GA4 | GA4 console | LP a son propre tag OU aucun |
| sGTM | Website `Analytics.tsx` | `t.keybuzz.pro` | sGTM container | sGTM | LP NE PEUT PAS utiliser sGTM KeyBuzz |
| Meta Pixel pageview | Website `Analytics.tsx` | Meta | Meta Events Manager | Meta Ads | LP peut avoir son propre Meta Pixel |
| Meta CAPI Purchase | API `outbound-conversions/emitter.ts` | Meta CAPI server-side | Meta | Meta Ads | Server-side, LP non concernée |
| TikTok Pixel | Website `Analytics.tsx` | TikTok | TikTok Events Manager | TikTok Ads | LP peut avoir son propre TikTok Pixel |
| TikTok Events API | API server-side | TikTok Events API | TikTok | TikTok Ads | Server-side, LP non concernée |
| LinkedIn Insight Tag | Website `Analytics.tsx` | LinkedIn | LinkedIn Campaign Manager | LinkedIn Ads | LP peut avoir son propre tag |
| LinkedIn CAPI | API `outbound-conversions` | LinkedIn CAPI | LinkedIn | LinkedIn Ads | Server-side, LP non concernée |
| UTM params | Website pricing + Client register | API | DB `signup_attribution` | Admin | LP **DOIT** forwarder dans CTA |
| gclid | URL param | register -> API | DB `signup_attribution` | Admin | LP **DOIT** forwarder dans CTA |
| fbclid | URL param | register -> API | DB `signup_attribution` | Admin | LP **DOIT** forwarder dans CTA |
| ttclid | URL param | register -> API | DB `signup_attribution` | Admin | LP **DOIT** forwarder dans CTA |
| li_fat_id | URL param | register -> API | DB `signup_attribution` | Admin | LP **DOIT** forwarder dans CTA |
| promo | URL param | register -> API -> Stripe | DB + Stripe | Admin + Billing | LP **DOIT** forwarder dans CTA |
| marketing_owner_tenant_id | URL param | register -> API | DB `tenants` + `signup_attribution` | Admin | LP **DOIT** forwarder dans CTA |
| landing_url | Client JS | API | DB `signup_attribution` | Admin | Contiendra l'URL register, pas l'URL LP |
| referrer | Browser | API | DB `signup_attribution` | Admin | Peut contenir `try.keybuzz.io` |
| fbc (Meta first-party cookie) | Client JS | API -> Meta CAPI | DB + Meta CAPI | Meta | Cross-domain : PERDU entre LP et register |

### Events tracking Website (browser-side)

| Fonction | GA4 event | Meta event | TikTok event | Fichier |
|---|---|---|---|---|
| `trackViewPricing()` | `view_pricing` | `ViewContent` | `ViewContent` | `tracking.ts` |
| `trackSelectPlan()` | `select_plan` | `InitiateCheckout` | `InitiateCheckout` | `tracking.ts` |
| `trackClickSignup()` | `click_signup` | `Lead` | `SubmitForm` | `tracking.ts` |
| `trackContactSubmit()` | `contact_submit` | `Contact` | `Contact` | `tracking.ts` |

### Events supprimés du browser (server-side only)

| Event | Statut | Commentaire code |
|---|---|---|
| Meta `Purchase` | **Supprimé browser, server-side CAPI only** | `PH-T8.12S` |
| TikTok `CompletePayment` | **Supprimé browser, server-side Events API only** | `PH-T8.12P` |

### CookieConsent

Le composant `CookieConsent.tsx` affiche une bannière mais **ne gate PAS** les scripts analytics. Les tags sont chargés inconditionnellement. Le commentaire `// if (status === "accepted") { initializeAnalytics(); }` est inactif.

---

## 2. Vérité Meta Pixel seul vs contrat KeyBuzz complet

### Si une LP `try.keybuzz.io/page-x` contient SEULEMENT Meta Pixel + CTA nu vers KeyBuzz :

| Cas | Meta Pixel seul | Contrat URL KeyBuzz complet | Verdict |
|---|---|---|---|
| Retargeting Meta | OUI | OUI | Meta Pixel suffit |
| Optimisation algo Meta | OUI | OUI | Meta Pixel suffit |
| ViewContent sur LP | OUI (si configuré) | N/A (LP externe) | Meta Pixel suffit |
| Attribution KeyBuzz (utm_source) | NON | OUI | **URL obligatoire** |
| Attribution KeyBuzz (gclid/fbclid/ttclid) | NON | OUI | **URL obligatoire** |
| Server-side CAPI Purchase | Partiel (pas de fbc cookie cross-domain) | OUI (fbclid dans URL -> fbc reconstruit) | **URL obligatoire** |
| Marketing owner routing | NON | OUI | **URL obligatoire** |
| Promo code | NON | OUI | **URL obligatoire** |
| Campaign QA validation | NON | OUI | **URL obligatoire** |
| Cross-platform (Google/TikTok/LinkedIn) | NON | OUI | **URL obligatoire** |
| Identification LP source | NON | Partiel (referrer + param custom) | Gap mineur |
| Funnel tracking (funnel_id) | NON | OUI (attribution_id généré) | **URL obligatoire** |
| Stripe checkout metadata | NON | OUI | **URL obligatoire** |

### Conclusion

**Meta Pixel seul = suffisant pour :** retargeting Meta, optimisation algorithmique Meta, audiences similaires.

**Meta Pixel seul = insuffisant pour :** attribution KeyBuzz, server-side CAPI enrichi, tracking cross-platform, marketing owner routing, promos, Campaign QA, funnel tracking, Stripe metadata.

**Le vrai mécanisme d'attribution KeyBuzz est le contrat URL, pas le pixel.**

---

## 3. Audit DNS try.keybuzz.io

| Point | Résultat | Impact | Action |
|---|---|---|---|
| DNS existe | OUI : `try.keybuzz.io -> cdn.webflow.com (198.202.211.1)` | LP sera sur Webflow | Attendu |
| HTTPS | Via Webflow CDN (automatique) | OK | Aucune |
| Cookie cross-domain try.keybuzz.io / client.keybuzz.io | Même TLD `.keybuzz.io`, mais cookies first-party non partageables (SameSite, Webflow vs K8s) | fbc/fbp Meta non transmissibles | Documenter dans contrat |
| Cookie cross-domain try.keybuzz.io / keybuzz.pro | TLDs différents | Aucun partage possible | Documenter dans contrat |
| CORS | LP Webflow -> liens CTA (pas d'API call) | Aucun besoin CORS | Aucune |
| Campaign QA allowlist | `VALID_DOMAINS` ne contient pas `try.keybuzz.io` | Campaign QA ne validera pas les URLs LP | **Gap AQ.4.1** |
| Referrer | Webflow envoie le referrer par défaut | `signup_attribution.referrer` contiendra `try.keybuzz.io` | OK |

---

## 4. Contrat LP Media Buyer universel

### 4.1. URL CTA obligatoire - Template register direct

```
https://client.keybuzz.io/register?plan={PLAN}&cycle={CYCLE}&utm_source={SOURCE}&utm_medium={MEDIUM}&utm_campaign={CAMPAIGN}&utm_content={CONTENT}&utm_term={TERM}&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk&promo={PROMO_CODE}
```

Les click IDs (`gclid`, `fbclid`, `ttclid`, `li_fat_id`) sont **ajoutés automatiquement** par les plateformes publicitaires. Ne JAMAIS les ajouter manuellement.

### 4.2. URL CTA alternative - Via pricing

```
https://www.keybuzz.pro/pricing?utm_source={SOURCE}&utm_medium={MEDIUM}&utm_campaign={CAMPAIGN}&utm_content={CONTENT}&utm_term={TERM}&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk&promo={PROMO_CODE}
```

La page `/pricing` forward automatiquement tous les UTM et click IDs vers le formulaire d'inscription.

### 4.3. Paramètres obligatoires

| Paramètre | Obligatoire | Valeurs | Exemple |
|---|---|---|---|
| `plan` | OUI (register direct) | `starter`, `pro`, `autopilot` | `autopilot` |
| `cycle` | OUI (register direct) | `monthly`, `yearly` | `monthly` |
| `utm_source` | OUI | `meta`, `google`, `tiktok`, `linkedin` | `meta` |
| `utm_medium` | OUI | `cpc`, `cpm`, `social`, `display`, `video` | `cpc` |
| `utm_campaign` | OUI | Convention : `{actor}-{platform}-{objective}-{country}-{quarter}` | `mb-meta-lead-fr-q2` |
| `marketing_owner_tenant_id` | RECOMMANDÉ | ID tenant marketing owner | `keybuzz-consulting-mo9zndlk` |

### 4.4. Paramètres optionnels

| Paramètre | Usage | Exemple |
|---|---|---|
| `utm_content` | Identifiant créa/variante | `hero-v2-cta-blue` |
| `utm_term` | Mot-clé ciblé | `sav-marketplace` |
| `promo` | Code promo Stripe | `LAUNCH50` |
| `_gl` | GA4 cross-domain linker | Ajouté automatiquement si GA4 est sur la LP |

### 4.5. Paramètres automatiques (ajoutés par les plateformes)

| Paramètre | Plateforme | Action media buyer |
|---|---|---|
| `gclid` | Google Ads | Ne rien faire, auto-tag Google |
| `fbclid` | Meta Ads | Ne rien faire, auto-tag Meta |
| `ttclid` | TikTok Ads | Ne rien faire, auto-tag TikTok |
| `li_fat_id` | LinkedIn Ads | Ne rien faire, auto-tag LinkedIn |

### 4.6. Pixels autorisés sur LP externe

| Pixel | Autorisé | Condition |
|---|---|---|
| Meta Pixel (PageView, ViewContent) | OUI | Pixel Meta du compte publicitaire du media buyer |
| TikTok Pixel (PageView, ViewContent) | OUI | ID pixel du compte TikTok |
| Google tag (gtag pageview) | OUI | ID Google du compte Google Ads |
| LinkedIn Insight Tag (pageview) | OUI | Partner ID du compte LinkedIn |

### 4.7. Events INTERDITS sur LP externe

| Event | Interdit | Raison |
|---|---|---|
| `Purchase` | OUI | Server-side only, déclenché par l'API après paiement réel |
| `CompletePayment` | OUI | Server-side only, déclenché par l'API après paiement réel |
| `Lead` avec données fictives | OUI | Fausse conversion |
| `InitiateCheckout` avec montant fictif | OUI | Fausse conversion |
| Tout event de conversion avec données inventées | OUI | Pollution du funnel |

### 4.8. Events AUTORISÉS sur LP externe

| Event | Autorisé | Quand |
|---|---|---|
| `PageView` | OUI | Chargement de la LP |
| `ViewContent` | OUI | Scroll ou engagement sur la LP |
| `ButtonClick` (custom) | OUI | Clic CTA (pour optimisation audiences) |

---

## 5. Autonomie media buyer

| Action media buyer | Autonome ? | Condition | Validation |
|---|---|---|---|
| Créer une nouvelle LP | OUI | Respecter contrat URL CTA | Aucune intervention KeyBuzz |
| Créer une nouvelle variation créa | OUI | Utiliser `utm_content` différent | Aucune intervention KeyBuzz |
| Changer le copywriting | OUI | Ne pas modifier les URLs CTA | Aucune intervention KeyBuzz |
| Changer le design | OUI | Ne pas modifier les URLs CTA | Aucune intervention KeyBuzz |
| Ajouter Meta Pixel | OUI | PageView + ViewContent uniquement | Aucune intervention KeyBuzz |
| Ajouter TikTok Pixel | OUI | PageView + ViewContent uniquement | Aucune intervention KeyBuzz |
| Ajouter Google tag | OUI | Pageview uniquement | Aucune intervention KeyBuzz |
| Ajouter LinkedIn tag | OUI | Pageview uniquement | Aucune intervention KeyBuzz |
| Modifier les CTA | OUI | Garder TOUS les params obligatoires | Vérifier dans Campaign QA |
| Ajouter une promo | OUI | Utiliser param `promo=CODE` | Le code doit exister dans Stripe (Admin) |
| Changer marketing_owner_tenant_id | NON | **Nécessite un tenant_id valide en DB** | Config unique par Admin |
| Créer un nouveau domaine | OUI | DNS vers Webflow/hébergeur, CTA conformes | Documenter le domaine |
| Lancer une campagne | OUI | URLs conformes | Vérifier dans Campaign QA avant lancement |
| Vérifier remontée Campaign QA | PARTIEL | URL builder fonctionne, mais VALID_DOMAINS exclut try.keybuzz.io | **Gap AQ.4.1** |

### Ce qui nécessite une config unique initiale (1 fois)

1. **Création du `marketing_owner_tenant_id`** - KeyBuzz Admin doit créer le tenant marketing owner
2. **Création des codes promo Stripe** - via Admin `/marketing/promo-codes`
3. **Allowlist du domaine LP dans Campaign QA** - `VALID_DOMAINS` dans le code admin

### Ce qui est interdit

1. Modifier l'URL du CTA pour supprimer des paramètres
2. Déclencher des events Purchase/CompletePayment/Lead fictifs
3. Hardcoder des click IDs manuellement
4. Créer un formulaire d'inscription sur la LP elle-même (bypass du register KeyBuzz)

---

## 6. Directives Antoine - prêtes à copier-coller

---

### DIRECTIVES LP EXTERNE - KEYBUZZ

**Ce que tu dois installer sur ta LP :**
- Ton Meta Pixel (le notre est déjà sur keybuzz.pro, pas besoin de le dupliquer)
- Tu peux ajouter ton TikTok Pixel, Google tag, LinkedIn tag si tu fais du multi-canal
- Events autorisés : PageView, ViewContent uniquement

**Ce que tu ne dois PAS installer :**
- Aucun event Purchase, CompletePayment, ou Lead avec données fictives
- Pas de formulaire d'inscription sur la LP (les inscriptions passent par client.keybuzz.io)

**Comment construire les liens CTA :**

Tous tes boutons CTA doivent pointer vers cette URL :

```
https://client.keybuzz.io/register?plan=autopilot&cycle=monthly&utm_source=meta&utm_medium=cpc&utm_campaign=mb-meta-lead-fr-q2&utm_content=ta-variante&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

Remplace :
- `plan=autopilot` par le plan ciblé (`starter`, `pro`, ou `autopilot`)
- `cycle=monthly` par `yearly` si tu pousses l'annuel
- `utm_campaign=mb-meta-lead-fr-q2` par le vrai nom de ta campagne
- `utm_content=ta-variante` par l'identifiant de ta créa/variante

**Ce qu'il ne faut JAMAIS supprimer de l'URL :**
- `utm_source`, `utm_medium`, `utm_campaign` - c'est notre attribution
- `marketing_owner_tenant_id` - c'est le routing media buyer
- `plan` et `cycle` - c'est la pré-sélection du plan

**Les click IDs (fbclid, gclid, ttclid, li_fat_id) sont ajoutés automatiquement par les plateformes publicitaires.** Ne les ajoute JAMAIS manuellement.

**Si tu as un code promo, ajoute `&promo=TON_CODE` à l'URL.**

**Comment tester avant mise en ligne :**
1. Ouvre ta LP dans un navigateur
2. Clique sur le CTA
3. Vérifie que l'URL de destination contient bien TOUS les paramètres (utm_source, utm_medium, utm_campaign, plan, cycle, marketing_owner_tenant_id)
4. Demande à Ludovic de vérifier dans Campaign QA

**Exemple CTA correct :**
```
https://client.keybuzz.io/register?plan=autopilot&cycle=monthly&utm_source=meta&utm_medium=cpc&utm_campaign=mb-meta-lead-fr-q2&utm_content=hero-v2&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

**Exemple CTA incorrect :**
```
https://www.keybuzz.pro/
```
(manque tous les paramètres, attribution perdue)

**Le pixel Meta seul ne suffit pas pour l'attribution KeyBuzz complète. Il peut rester pour le retargeting Meta, mais les liens CTA doivent obligatoirement transmettre les paramètres KeyBuzz.**

---

## 7. Audit Admin Campaign QA

Le Campaign QA (`/marketing/campaign-qa`) est **mature** et offre :

| Fonctionnalité | Support actuel | Statut |
|---|---|---|
| URL builder avec plateformes | OUI (Meta, Google, TikTok, LinkedIn) | OK |
| Acteurs (mb, ag, kb) | OUI | OK |
| Convention nommage campagne | OUI (`{actor}-{platform}-{objective}-{country}-{quarter}`) | OK |
| Warning click IDs manuels | OUI | OK |
| Warning landing hors /pricing | OUI | OK |
| Validation domaines (`VALID_DOMAINS`) | OUI : `www.keybuzz.pro`, `keybuzz.pro`, `client.keybuzz.io` | **Gap : try.keybuzz.io absent** |
| Validation URL externe complète | NON | **Gap** |
| Détection pixels sur URL externe | NON (pas de crawler) | **Gap mineur** |
| Détection UTMs dans URL | OUI (dans l'URL builder) | OK |
| Détection click IDs | OUI (warning si manuels) | OK |
| Détection redirections CTA | NON | Gap mineur |
| Détection marketing_owner_tenant_id | OUI (prédéfini) | OK |
| Détection promo | NON (séparé dans promo-codes) | Gap mineur |
| Détection faux events | NON (pas de crawler) | Gap mineur |
| Support multi-LP | PARTIEL (builder unique, pas de registre LP) | **Gap** |

---

## 8. Gap analysis

| Gap | Gravité | Bloquant autonomie ? | Bloquant Ads ? | Ticket recommandé |
|---|---|---|---|---|
| `VALID_DOMAINS` n'inclut pas `try.keybuzz.io` | Moyenne | Non (le builder fonctionne, juste un warning) | Non | AQ.4.1 |
| Pas de `landing_page_id` param dans le contrat | Faible | Non (referrer + utm_content suffisent) | Non | Optionnel |
| Pas de registre domaines LP externes | Faible | Non | Non | Future feature |
| Pas de validator automatique URL externe | Faible | Non (test manuel) | Non | Future feature |
| Cookie fbc/fbp non partageable cross-domain LP -> register | Moyenne | Non (fbclid dans URL suffit pour CAPI, fbc reconstruit côté client) | Non | Attendu, pas de fix |
| Pas de doc media buyer officielle | Haute | **Oui** (Antoine n'a pas les directives) | Non | **AQ.4.1 : livrer les directives** |
| marketing_owner_tenant_id doit exister en DB | Faible | Non (config unique initiale) | Non | Déjà géré |
| Codes promo doivent exister dans Stripe | Faible | Non (config unique initiale via Admin) | Non | Déjà géré |

---

## 9. Linear

### KEY-284
- Verdict : GO PARTIEL - IMPLEMENTATION REQUIRED
- Meta Pixel seul insuffisant pour attribution KeyBuzz complète
- Contrat URL CTA établi et documenté
- Directives Antoine prêtes
- Campaign QA mature mais `VALID_DOMAINS` à étendre
- Gap principal : livrer les directives à Antoine

**Recommandation :** créer AQ.4.1 pour :
1. Ajouter `try.keybuzz.io` dans `VALID_DOMAINS` du Campaign QA
2. Livrer les directives media buyer à Antoine
3. Tester un CTA depuis try.keybuzz.io -> register avec attribution complète

### KEY-253
- AQ.4 terminé (audit/design)
- Contrat LP media buyer établi
- Ads tracking hardened (AQ.3 + AQ.4)
- Autonomie media buyer documentée

### KEY-282 (Dashboard Performance SAV)
- Hors scope AQ.4, reste post-Ads

### KEY-283 (Démo commerciale)
- Hors scope AQ.4

---

## 10. Rollback

Phase read-only. Aucun code, build, ou deploy. Pas de rollback nécessaire.

---

## 11. Confirmations finales

- 0 code modifié
- 0 build
- 0 deploy
- 0 mutation DB
- 0 mutation Stripe
- 0 mutation DNS
- 0 mutation Meta/TikTok/Google/LinkedIn
- 0 fake event
- 0 checkout
- 0 payment
- 0 CAPI mutation
- 0 secret exposé

---

## Verdict

**PH-WEBSITE-T8.12AQ.4 - TERMINÉ**

**Verdict : GO PARTIEL - IMPLEMENTATION REQUIRED**

**MEDIA BUYER LP TRACKING CONTRACT ESTABLISHED - META PIXEL ALONE IS NOT SUFFICIENT FOR FULL KEYBUZZ ATTRIBUTION - CTA URL CONTRACT / UTM CLICK ID FORWARDING / NO FAKE EVENTS / CAMPAIGN QA REQUIREMENTS DOCUMENTED - TRY.KEYBUZZ.IO NOT DEPLOYED YET - NO CODE - NO BUILD - NO DEPLOY - NO MUTATION - IMPLEMENTATION GAPS READY FOR AQ.4.1**
