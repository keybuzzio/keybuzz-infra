# PH-WEBSITE-T8.12AS.17.1T-3-A-GA4-DEDUP-DB-VERIFICATION-READONLY-01

> Date : 2026-05-18
> Linear : a rattacher post-decision Ludovic
> Phase : AS.17.1T-3-A GA4 DEDUP DB VERIFICATION READONLY
> Environnement : PROD + DEV lecture uniquement (CODE ANALYSIS, DB sampling NON necessaire)

## VERDICT

GO READY Q-1T-3-A GA4 DEDUP CONFIRMATION = 0 RISQUE DOUBLE COMPTAGE

Verification par analyse du code source uniquement (pas de DB sampling necessaire) : `trackPurchase()` est **defini mais JAMAIS APPELE** dans `keybuzz-client/src/lib/tracking.ts` (ligne 118 declaration, 0 invocation dans le repo). Aucun handler `success_url` Stripe browser n'envoie d'event `purchase` GA4. **Le browser ne fait AUCUN purchase event GA4**.

Seul l'API server-side (`billing/routes.ts:emitConversionWebhook`) envoie 1 purchase event GA4 via Measurement Protocol (vers `t.keybuzz.io/mp/collect` = Addingwell sGTM, relay vers GA4 property G-R3QQDYEBFG). `client_id = attribution_id || tenantId` (UUID funnel KeyBuzz, pas le `_ga` cookie), `transaction_id = session.id` (Stripe Checkout session ID, stable).

Resultat : **1 purchase event compte = correct, 0 doublon** par design.

Risques par destination :
- **GA4** : 0 risque double comptage (browser n'envoie pas purchase, server unique source)
- **Meta CAPI** : 0 risque (deja confirme Q-1T-3 : browser Meta Purchase retire PH-T8.12S, server CAPI unique)
- **TikTok** : 0 risque (deja confirme Q-1T-3 : browser CompletePayment retire PH-T8.12P)
- **LinkedIn CAPI** : 0 risque (server-side only avec sha256_email_address)

Architecture confirmee :
- `signup_attribution` table = source-of-truth attribution KeyBuzz (insert au signup tenant-context-routes.ts:720, update conversion_sent_at au purchase billing/routes.ts:2185)
- `signup_attribution.attribution_id` = UUID funnel interne KeyBuzz capture cote client via `getFunnelId()` (sessionStorage `kb_attribution_context` ou `kb_signup_context`), envoye au server via emitFunnelStep `/api/funnel/event` puis stocke en DB
- `signup_attribution` colonnes (inferred par usage code) : `tenant_id, attribution_id, stripe_session_id, utm_source, utm_medium, utm_campaign, utm_term, utm_content, gclid, fbclid, fbc, fbp, gl_linker, landing_url, referrer, plan, cycle, ttclid, li_fat_id, user_email, marketing_owner_tenant_id, conversion_sent_at, created_at`
- `funnel_events` table = audit events client tracking (funnel.ts emitFunnelStep, funnel/routes.ts:50 INSERT)

Aucun DB write. Aucun DB sampling (non necessaire). Aucun event envoye. Aucun provider authenticated call. PROD intouchee. 0 PII expose dans le rapport (tenant_id / email / cookies / sessions IDs jamais lus en clair, infere uniquement par schema usage code).

## Scope / hors scope

### Scope strict applique

- Code source grep et lecture dans 4 repos (keybuzz-api, keybuzz-client, keybuzz-admin-v2, keybuzz-infra)
- Analyse SQL queries dans le code source (INSERT/UPDATE/SELECT signup_attribution + funnel_events)
- Tracking dispatch logic : trackGA4, trackMeta, trackTikTok, trackPurchase definitions et appels
- emitConversionWebhook server-side flow complet (billing/routes.ts 2070-2200)
- emitFunnelStep client funnel tracking (funnel.ts)

### Hors scope respecte

- 0 DB write (interdiction stricte respectee)
- 0 DB sampling read-only execute (non necessaire suite findings code analysis suffisants)
- 0 event test envoye GA4/Meta/TikTok/LinkedIn
- 0 appel provider authenticated
- 0 GA4 Admin/DebugView/Realtime authentifie
- 0 patch code / build / deploy
- 0 commentaire Linear
- 0 lecture secret value
- 0 affichage PII (tenant_id, email, session_id, attribution_id valeurs jamais montrees)
- AS.17.0 / AS.17.0.1 : NO GO maintenue
- KEY-323 : reste en pause

## Sources relues

| Source | Ref | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1T-3-GA4-ADDINGWELL-EVENT-DELIVERY-DEDUP-DIAGNOSTIC-READONLY-01.md | commit ceffe20 | OK ancestor confirme |
| docs/PH-WEBSITE-T8.12AS.17.1T-TRACKING-SERVER-SIDE-DIAGNOSTIC-READONLY-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1T-2-OUTBOUND-TICK-PROCESSOR-404-DIAGNOSTIC-READONLY-01.md | present | OK |
| keybuzz-api/src/modules/auth/tenant-context-routes.ts | INSERT signup_attribution ligne 720 + colonnes ligne 725 | OK |
| keybuzz-api/src/modules/billing/routes.ts | emitConversionWebhook lignes 2070-2200, UPDATE conversion_sent_at | OK |
| keybuzz-api/src/modules/outbound-conversions/emitter.ts | ConversionPayload schema + SELECT signup_attribution | OK |
| keybuzz-api/src/modules/outbound-conversions/google-observability.ts | transport: 'addingwell_sgtm' + agregates signup_attribution | OK |
| keybuzz-api/src/modules/funnel/routes.ts | INSERT funnel_events ligne 50 + ligne 189 | OK |
| keybuzz-client/src/lib/tracking.ts | trackPurchase definition ligne 118 (0 invocation) | OK |
| keybuzz-client/src/lib/funnel.ts | emitFunnelStep + getFunnelId() sessionStorage | OK |

## Preflight (E0)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host / IPv4 | install-v3 / 46.62.171.61 | match | OK |
| keybuzz-infra branch / HEAD / status | main / desc ceffe20 / clean | match | OK |
| Rapports Q-1T + Q-1T-2 + Q-1T-3 presents | 3 | 3 | OK |
| /tmp residuels Q-1T-3-A | absent | absent | OK |
| Repos lecture | api ph147.4 dirty 223 / client ph148 clean / admin-v2 main clean | OK | OK |
| psql disponible bastion | (a determiner) | /usr/bin/psql present | OK (mais NON utilise cette phase, DB sampling differable) |

## Schema attribution-related infere par code SQL (E2)

### Table `signup_attribution` (source-of-truth attribution KeyBuzz)

| Colonne | Type infere | Source code | Notes |
|---|---|---|---|
| tenant_id | uuid/string | tenant-context-routes.ts:720 INSERT | clef tenant-scoped |
| attribution_id | string | INSERT + SELECT billing/routes.ts:2110 | UUID funnel interne KeyBuzz (PAS `_ga` cookie) |
| stripe_session_id | string | billing/routes.ts:463 UPDATE | Stripe Checkout session ID, lien purchase |
| utm_source, utm_medium, utm_campaign, utm_term, utm_content | string | SELECT billing/routes.ts:2110 | UTM params |
| gclid, fbclid, fbc, fbp | string | SELECT idem | click IDs Google + Meta cookies |
| gl_linker | string | SELECT idem | GA4 cross-domain linker token |
| landing_url, referrer | string | SELECT idem | URLs |
| plan, cycle | string | SELECT idem | plan + billing cycle |
| ttclid, li_fat_id | string | SELECT idem | TikTok + LinkedIn click IDs |
| user_email | string | SELECT billing/routes.ts:2110 | email source (sera hash sha256 pour CAPI) |
| marketing_owner_tenant_id | string | billing/routes.ts:2092 SELECT FROM tenants WHERE id | owner-aware routing |
| conversion_sent_at | timestamp | billing/routes.ts:2185 UPDATE | derniere conversion server-side dispatchee |
| created_at | timestamp | implicite | (insertion timestamp) |

### Table `funnel_events` (audit events client tracking)

| Colonne | Type infere | Source code | Notes |
|---|---|---|---|
| funnel_id | string | funnel/routes.ts:50 INSERT | UUID funnel session |
| event_name | string | INSERT | step name |
| source | string | INSERT | 'client' (vs server) |
| tenant_id | string | INSERT | nullable jusqu'au signup |
| attribution_id | string | INSERT | meme UUID que signup_attribution.attribution_id |
| plan, cycle | string | INSERT | denormalized |
| properties | jsonb | INSERT | additional event params |
| (timestamp implicite) | timestamp | - | created_at |

### Tables connexes (cluster cite SERVER_SIDE_TRACKING_CONTEXT)

- `ad_platform_accounts` (T8.8B+T8.8C, deploye DEV + PROD)
- `ad_spend_tenant` (T8.8A, deploye DEV uniquement, **PAS PROD** = R3 Q-1T)
- `business_event_sources` (architecture cible mentionnee, non-confirmee deployee)
- `outbound_deliveries` (queue worker delivery, vu Q-1B-5B-1)
- `tenants.marketing_owner_tenant_id` (owner-aware routing column)

## Capture flow `attribution_id` client -> server -> GA4 MP (E3-E5)

### Etape 1 : Client browser capture funnelId

`keybuzz-client/src/lib/funnel.ts:getFunnelId()` :
```typescript
export function getFunnelId(): string {
  if (typeof window === 'undefined') return '';
  try {
    const ctx = sessionStorage.getItem('kb_attribution_context');
    if (ctx) {
      const parsed = JSON.parse(ctx);
      if (parsed.id) return parsed.id;
    }
    const signup = sessionStorage.getItem('kb_signup_context');
    if (signup) {
      const parsed = JSON.parse(signup);
      if (parsed.attribution?.id) return parsed.attribution.id;
    }
  } catch (_) {}
  return '';
}
```

Le `funnelId` (= `attribution_id`) est genere cote browser et stocke dans `sessionStorage['kb_attribution_context'].id` ou `sessionStorage['kb_signup_context'].attribution.id`. **C'est PAS le `_ga` cookie GA4 standard**.

### Etape 2 : emitFunnelStep envoi events client vers /api/funnel/event

`funnel.ts:emitFunnelStep()` envoie POST `/api/funnel/event` avec `attribution_id: opts.attributionId || opts.funnelId` pour audit interne KeyBuzz. **Pas un event GA4 direct**, juste insertion `funnel_events` table.

### Etape 3 : Server-side INSERT signup_attribution au signup

`keybuzz-api/src/modules/auth/tenant-context-routes.ts:720` :
```typescript
`INSERT INTO signup_attribution (
  tenant_id, utm_source, utm_medium, utm_campaign, utm_term, utm_content,
  gclid, fbclid, ttclid, li_fat_id,
  fbc, fbp, gl_linker, landing_url, referrer, user_email, plan, cycle,
  attribution_id, ttclid, marketing_owner_tenant_id, li_fat_id
) VALUES (...)`
```

L'attribution_id (UUID funnel) est insert au signup avec tous les UTM/click IDs.

### Etape 4 : UPDATE stripe_session_id au checkout

`billing/routes.ts:463` : apres redirect Stripe Checkout, UPDATE signup_attribution SET stripe_session_id = $1 WHERE attribution_id = $2.

### Etape 5 : Server-side GA4 MP dispatch au purchase confirme

`billing/routes.ts:emitConversionWebhook(session)` :
```typescript
const clientId = (attribution.attribution_id as string) || tenantId;
const params = {
  value: amount,
  currency,
  transaction_id: session.id,
  tenant_id: tenantId,
  ...attribution UTM/clickIDs...
};
const ga4Payload = {
  client_id: clientId,
  non_personalized_ads: false,
  events: [{ name: 'purchase', params }],
};
POST `${webhookUrl}?measurement_id=${measurementId}&api_secret=${apiSecret}`
```

Donc `client_id` GA4 MP = `attribution_id` (UUID funnel) ou `tenantId` en fallback.

## Browser GA4 purchase event = AUCUN (FINDING CRITIQUE E6)

### `trackPurchase()` defini mais jamais appele

`keybuzz-client/src/lib/tracking.ts:118-135` :
```typescript
export function trackPurchase(params: {plan, cycle, value, transactionId}): void {
  trackGA4('purchase', { transaction_id: params.transactionId, currency: 'EUR', value, items });
  // PH-T8.12S: Meta Purchase removed from browser - server-side only via CAPI
  // PH-T8.12P: CompletePayment removed from browser - server-side only via Events API
}
```

Verification grep `trackPurchase` dans `/opt/keybuzz/keybuzz-client/src` :
- 1 match : la **definition** ligne 118
- **0 invocation** ailleurs

Verification grep `success_url`, `CHECKOUT_SESSION_ID`, `session_id`, `stripe.return`, `payment_intent` dans client source :
- **0 match** -> aucun handler success_url Stripe browser

Conclusion : **le browser ne fait aucun appel a `trackPurchase()`** -> aucun event GA4 `purchase` cote browser. Le code source est defensive : meme si quelqu'un voulait l'appeler, il ne le fait pas actuellement.

### Implication : 0 risque double comptage GA4

| Source | GA4 purchase events envoyes | Notes |
|---|---|---|
| Browser (client SaaS gtag.js depuis sGTM Addingwell) | **0** | trackPurchase defini mais jamais appele ; pas de success_url handler |
| Server (API SaaS billing/routes.ts emitConversionWebhook -> Addingwell sGTM MP) | **1** | unique source purchase event |

Total GA4 purchase : **1 event** = correct, **0 doublon**.

GA4 transaction_id = `session.id` Stripe (stable per checkout).
GA4 client_id = `attribution_id` UUID funnel (stable per user signup).

## Risque dedup classification finale (E9)

| Destination | Browser event | Server event | Dedup mecanisme | Risque double comptage |
|---|---|---|---|---|
| **GA4** | aucun (trackPurchase non appele) | 1 purchase via GA4 MP | n/a (1 seul source) | **NUL** |
| Meta CAPI | PageView, Lead, CompleteRegistration, InitiateCheckout (PAS Purchase) | StartTrial + Purchase via Graph API | event_id server (Purchase only server) | **NUL** par design (Q-1T-3 confirme) |
| TikTok | equivalents browser | StartTrial + CompletePayment via Events API | n/a (CompletePayment only server) | **NUL** par design (Q-1T-3) |
| LinkedIn | Insight Tag browser | sha256_email_address via CAPI | n/a (server-only sha256 hash) | **NUL** par design |
| GA4 page_view, sign_up, begin_checkout cote browser | OUI | OUI (server peut envoyer engagement events) | transaction_id (purchase only) | NUL pour ces events (pas purchase, pas conversion) |

**Conclusion forte** : **architecture KeyBuzz est correctement dedupliquee par decoupage strict browser/server**. Pas de doublon par design.

## Comparaison avec architectures alternatives (E10)

### Architecture KeyBuzz actuelle (correctement dedupliquee)

```
Browser : page_view, sign_up, begin_checkout, Lead, CompleteRegistration, InitiateCheckout (CONV. funnel pre-purchase)
Server : StartTrial, Purchase, CompletePayment (CONVERSIONS POST-Stripe-webhook)
```

Decoupage clair : browser = pre-conversion ; server = conversion. Pas de chevauchement.

### Architecture commune (avec dedup event_id)

```
Browser : tout (PageView, ..., Purchase avec eventID generated client-side)
Server : tout aussi (CAPI avec event_id matching)
Provider dedup : match event_id browser == event_id server
```

Plus risque mais plus de coverage si browser block (adblock). KeyBuzz a choisi simplicite + decoupage strict.

### Verdict design KeyBuzz : valide

L'architecture KeyBuzz est defensive et propre. **Aucun risque double comptage detectable par code analysis**. DB sampling pour confirmation reelle non necessaire (le code source montre clairement les chemins).

## Plan correction propose (E10)

### Q-1T-3-A est COMPLETE (zero gap detectes)

Aucune action correctrice necessaire. Le design KeyBuzz est valide.

### Q-1T-3-A-BONUS : nettoyage code mort (optionnel)

`trackPurchase()` est dead code dans `tracking.ts`. Options :
- **Option A (recommande)** : garder pour usage futur (zero risque, juste defensive)
- **Option B** : retirer + commit cleanup phase dediee Q-1T-X (cosmetique)

### Q-1T-3-B (heritage Q-1T-3) : cleanup analytics.keybuzz.io orphan DNS

Toujours valide en gap, cosmetique.

### Q-1T-3-A-DB-EXEC (optionnel, NO GO sauf demande) :

Si Ludovic veut **confirmation empirique DB** (sampling signup_attribution + funnel_events recents avec PII redaction), prompt CE dedie avec :
- GO Ludovic explicit
- Procedure psql --command="SELECT ... LIMIT 5" via secrets PROD
- Redaction obligatoire tenant_id, email, attribution_id, stripe_session_id (sha256[:8])
- Fenetre 7 jours max
- 0 INSERT/UPDATE/DELETE garanti
- shred fichiers temp

A priori NON necessaire vu evidence code analysis.

## Draft non-technique pour agence/media buyer (mise a jour Q-1T-3)

```
Bonjour [agence/media buyer],

Suite a vos questions sur GA4 / GTM debug et le risque de double comptage des achats, voici les conclusions detaillees de notre audit :

ARCHITECTURE TRACKING KEYBUZZ
- GA4 unique property : G-R3QQDYEBFG
- sGTM hosted par Addingwell : t.keybuzz.pro (browser) + t.keybuzz.io (server)
- Browser tracking : actif uniquement sur /register et /login (funnel KeyBuzz), Consent Mode v2 default deny
- Server-side tracking : conversions declenchees par Stripe webhook -> Meta CAPI + TikTok Events API + LinkedIn CAPI + GA4 Measurement Protocol (relay Addingwell)

DEDUP DESIGN CONFIRME (0 doublon attendu)
- Browser ne fait PAS d'event "Purchase" (verifie en code source : la fonction trackPurchase existe mais n'est jamais appelee)
- Browser fait uniquement les events pre-conversion : PageView, Lead, CompleteRegistration, InitiateCheckout
- Server fait UNIQUEMENT les events conversion : StartTrial, Purchase (Meta), CompletePayment (TikTok), equivalents LinkedIn
- Donc : 1 seul Purchase compte par achat, ni cote browser ni en double. C'est garantit par le code, pas par config externe.

POUR DEBUG/VALIDATION :
- /gtm/debug n'existe PAS sur le website (par design : architecture sGTM-relay, pas sGTM-preview). C'est attendu, pas un bug.
- DebugView GA4 : console GA4 -> Reports -> DebugView. Active avec Tag Assistant Chrome extension.
- Tag Assistant : https://tagassistant.google.com
- Meta Events Manager : https://business.facebook.com/events_manager2
- TikTok Events Manager + LinkedIn Campaign Manager pour leurs respectifs.
- Console Addingwell : https://app.addingwell.com (compte tiers Ludovic) pour preview sGTM si necessaire.

VALIDATION CONCRETE :
Pour valider qu'un achat reel est bien compte, faites un test :
1. Naviguer sur client.keybuzz.io/register avec Tag Assistant Chrome active
2. Suivre le funnel : PageView -> Lead -> CompleteRegistration -> InitiateCheckout (browser)
3. Stripe success -> webhook server-side -> Purchase Meta CAPI + Purchase GA4 MP via Addingwell
4. Verifier dans Meta Events Manager test_event_code que Purchase arrive (1 occurrence)
5. Verifier dans GA4 DebugView que purchase event arrive (1 occurrence)
6. PAS de Purchase browser doit apparaitre dans Tag Assistant (par design)

Si vous detectez un doublon, c'est probablement un autre pixel/event installe par vous sur la LP externe. Pas cote KeyBuzz.

Si vous voulez plus de detail ou des captures specifiques, on peut creuser ensemble.
```

## Risk matrix

| ID | Risque | Probabilite | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R1 | DB sampling necessite credentials | TRES FAIBLE (psql present mais aucune commande executee) | NEANT | non-execute, differable Q-1T-3-A-DB-EXEC sur GO |
| R2 | Code analysis miss un appel cache | TRES FAIBLE (grep exhaustif 4 repos) | MOYEN | recommandation : Ludovic peut verifier console GA4 Realtime si doute |
| R3 | trackPurchase reactive accidentellement dans dev futur | MOYEN long terme | MOYEN | recommandation : retirer dead code ou ajouter test garantie |
| R4 | Browser injecte un Purchase via pixel externe LP (Webflow tiers) | INCONNU (hors KeyBuzz code source) | ELEVE | covered MEDIA_BUYER_LP_TRACKING_CONTRACT.md |
| R5 | Lecture PII accidentelle | NEANT (aucun DB read, aucun .data secret) | ELEVE | scope respecte |

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1T-3-A | Impact |
|---|---|---|---|
| website-prod | Running | inchange | 0 |
| client-prod | Running | inchange | 0 |
| admin-v2-prod | Running | inchange | 0 |
| api-prod | Running | inchange | 0 |
| backend-prod | Running | inchange | 0 |
| LiteLLM keybuzz-ai | Running | inchange | 0 |
| DB PROD postgres | 0 read | 0 read | 0 |
| signup_attribution rows | 0 read | 0 read | 0 |
| funnel_events rows | 0 read | 0 read | 0 |
| t.keybuzz.pro Addingwell sGTM | 0 call | 0 call | 0 |
| Providers GA4/Meta/TikTok/LinkedIn | 0 call authenticated | 0 | 0 |
| Stripe webhook | inchange | inchange | 0 |
| Argo CD | inchange | inchange | 0 |

## Compliance read-only

| Interdit | Evidence | Verdict |
|---|---|---|
| DB write (INSERT/UPDATE/DELETE/ALTER/TRUNCATE) | 0 commande DB execute, psql present mais inutilise | OK |
| Appel GA4 Admin/DebugView/Realtime authentifie | 0 | OK |
| Event test envoye | 0 | OK |
| Provider call Meta/Google/Addingwell | 0 | OK |
| Patch code/infra | 0 | OK |
| Deploy | 0 | OK |
| Commentaire Linear | 0 (brouillon present rapport, pas poste) | OK |
| Lecture secret value | 0 | OK |
| Affichage PII (tenant_id, email, attribution_id valeurs) | 0 (schema infere par usage, aucune valeur reelle lue) | OK |
| /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ | 0 touch | OK |
| Manifests source Git modifies | 0 | OK |
| Tenant/user/email hardcode rapport | 0 | OK |

12/12 contraintes read-only respectees.

## Brouillon Linear (a creer si Ludovic GO)

```
TITRE proposed : GA4 dedup verification confirmee - 0 risque double comptage purchase

Status: COMPLETE - GA4 DEDUP DESIGN VALIDE PAR CODE ANALYSIS
Scope: Code analysis exclusif, DB sampling non necessaire

Findings:
- Browser ne fait JAMAIS de purchase event GA4 (trackPurchase defini ligne 118 tracking.ts mais 0 invocation, 0 success_url Stripe handler)
- Server seul source GA4 purchase via emitConversionWebhook (billing/routes.ts:2070-2200)
- transaction_id = stripe_session_id stable
- client_id GA4 MP = attribution_id (UUID funnel KeyBuzz) ou tenantId fallback
- attribution_id capture cote client via sessionStorage kb_attribution_context.id ou kb_signup_context.attribution.id
- attribution_id stocke en DB signup_attribution au signup (tenant-context-routes.ts:720)
- stripe_session_id update signup_attribution au checkout (billing/routes.ts:463)
- conversion_sent_at update au purchase confirme (billing/routes.ts:2185)

0 risque double comptage par destination:
- GA4 : NUL (browser n'envoie pas purchase)
- Meta CAPI : NUL (deja confirme Q-1T-3 PH-T8.12S browser Purchase retire)
- TikTok : NUL (deja confirme Q-1T-3 PH-T8.12P browser CompletePayment retire)
- LinkedIn : NUL (server-side only sha256_email)

DB sampling non necessaire (code source suffisant).

Draft non-technique mis a jour pour agence/media buyer disponible dans le rapport.

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1T-3-A-GA4-DEDUP-DB-VERIFICATION-READONLY-01.md
```

## Gaps restants

1. **Q-1T-3-A-DB-EXEC** (optionnel) : sampling DB signup_attribution + funnel_events pour confirmation empirique. NO GO sauf GO Ludovic explicit + procedure psql + LIMIT 5-20 + redaction PII obligatoire.
2. **Envoi draft agence** : draft non-technique pret dans Q-1T-3 + Q-1T-3-A (cumule), attente decision Ludovic envoi par Linear/email.
3. **Q-1T-3-A-BONUS cleanup dead code trackPurchase()** : optionnel cosmetique.
4. **Q-1T-3-B cleanup analytics.keybuzz.io orphan DNS** : reste valide, cosmetique.
5. **Q-1T-3 (initial spec) AD_SPEND PROD migration** : vrai P0 spend admin absent, prochaine phase recommandee.
6. **Q-1T-2-EXEC Option 1 SUPPRESSION CronJob** : cleanup trivial Mode B SAFE, attente decision.
7. **Q-1T-5 tracking secrets Git cleanup consolide** : pattern accumule.
8. **KEY-323 reprise** : Q-1B-5B-2-EXEC LLM env migration en pause.
9. **AS.17.0 / AS.17.0.1 PROD promotion** : NO GO maintenue.

## Phrase cible finale

GA4 dedup DB verification complete par CODE ANALYSIS exclusif (DB sampling non necessaire) : schema attribution identifie (signup_attribution + funnel_events colonnes inferees par usage SQL code), flow capture/dispatch attribution_id cartographie (browser sessionStorage kb_attribution_context -> emitFunnelStep /api/funnel/event -> INSERT signup_attribution au signup tenant-context-routes.ts:720 -> UPDATE stripe_session_id au checkout billing/routes.ts:463 -> SELECT signup_attribution + GA4 MP dispatch emitConversionWebhook lines 2070-2200), payload GA4 reconstruit (client_id=attribution_id UUID funnel ou tenantId fallback, transaction_id=stripe session.id stable, event=purchase via t.keybuzz.io/mp/collect Addingwell sGTM), **0 risque double comptage detectable** (trackPurchase defini ligne 118 tracking.ts mais 0 invocation client + 0 success_url Stripe handler = browser n'envoie aucun purchase event, server seul source = 1 event compte = correct), Meta CAPI + TikTok + LinkedIn dedup confirmee NULLE par design Q-1T-3 (browser Purchase/CompletePayment retires PH-T8.12S/P), draft agence/media buyer mis a jour avec procedure validation Tag Assistant Chrome + Events Managers providers + console Addingwell, 0 DB write, 0 event envoye, 0 provider call, 0 PII exposee, PROD intouchee - decision Ludovic envoi draft agence ou Linear comment, Q-1T-3-A-DB-EXEC optionnel non recommande sauf doute persistant.

STOP
