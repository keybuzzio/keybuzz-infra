# PH-ADMIN-T8.12AS.15.3.1-CAPI-AUDIT-CONTEXT-NOTE-AND-AS.15.4-SCOPE

> Date : 2026-05-15
> Linear : KEY-322 (Open). Suit AS.15.3 (commit 6a52726).
> Phase : T8.12AS.15.3.1 (note de contexte docs-only + scope AS.15.4)
> Environnement : docs-only (aucun changement code/build/deploy/DB/manifests/runtime)

---

## 0. VERDICT

GO CONTEXT NOTE + AS.15.4 SCOPE EXTENDED.

Note de contexte business critique fournie par Ludovic apres AS.15.3 : tous les signups recents observes dans `signup_attribution` sont **des creations manuelles** (tests internal, validations, onboardings concours/partners) et NON des leads issus de campagnes publicitaires.

Cela confirme et reframe les findings AS.15.3 :
- 0 delivery_log CAPI sur 7 jours = NORMAL (aucun signup eligible attribute par campagne)
- `signup_attribution.fbclid` = 0 / `li_fat_id` = 0 / `ttclid` rare = NORMAL (signups manuels n ont pas de click IDs ad)
- Pipeline CAPI server-side n est PAS en panne ni casse

Le vrai sujet a investiguer en AS.15.4 n est PAS le pipeline emission CAPI (deja prouve fonctionnel par AS.15.3) mais le **PARCOURS LANDING PAGE -> SIGNUP** pour les futurs vrais leads ad-attributed, incluant le systeme de promo codes / bons de reduction.

KEY-322 reste Open. Aucun ticket Linear cree. Aucune mutation.

---

## 1. CONTEXTE BUSINESS RAPPELE PAR LUDOVIC

Quote (paraphrase fidele) :

> Tous les comptes recents ont ete crees manuellement. Il n y a pas encore de vrais nouveaux clients issus des pubs. Donc fbclid/li_fat_id a 0 et absence de delivery CAPI recent peuvent etre normaux.

Consequences interpretatives :

| Indicateur AS.15.3 | Lecture naive | Lecture correcte (avec contexte) |
|---|---|---|
| 0 delivery_log 7d | "Pipeline CAPI casse ?" | "Aucun signup ad-attributed dans la fenetre, normal" |
| signup_attribution.fbclid = 0 (8/8) | "Capture LP Meta cassee ?" | "Aucun signup via lead Meta encore, capture pas verifiable jusqu a 1er lead reel" |
| signup_attribution.li_fat_id = 0 (8/8) | "Capture LP LinkedIn cassee ?" | "Aucun signup via lead LinkedIn encore" |
| 4/8 signups avec marketing_owner_tenant_id NULL | "Resolution attribution defaillante ?" | "Signups organic/manuel sans UTM -> marketing_owner non resolu, attendu" |
| conversion_events = 2 rows total | "Pipeline emission rare ?" | "Pipeline emis pour 2 signups eligibles (bon-kb concours + test-owner-runtime), coherent volume" |

**Plus important** : il est faux de conclure a une panne / bug technique a partir de ces indicateurs tant que aucun lead ad reel n est passe par le parcours.

---

## 2. PERIMETRE AS.15.4 ELARGI (a planifier, ne pas demarrer sans GO)

Au lieu d auditer la capture fbclid/li_fat_id sur 8 signups manuels (qui n auront jamais ces IDs), AS.15.4 doit auditer en READ-ONLY :

### 2.1 Parcours Landing Page -> signup

Pour chaque plateforme ad cible (Meta, Google, TikTok, LinkedIn), verifier la chaine theorique :

1. Click sur ad cote plateforme (cote utilisateur)
2. Redirection vers landing page Webflow (keybuzz.pro / equivalents) avec parametres `fbclid`, `gclid`, `ttclid`, `li_fat_id`, `utm_*`
3. Capture cote Webflow : script qui store ces parametres en cookie ou localStorage (per MEDIA-BUYER-LP-TRACKING-CONTRACT.md)
4. Click CTA sur LP -> redirection vers client.keybuzz.io/register avec params propages
5. Signup form -> POST vers backend qui resolve `signup_attribution` avec UTM + click IDs + tenant_id + marketing_owner_tenant_id

### 2.2 Points de verification AS.15.4

| Etape | Verification READ-ONLY | Sans fake event ? |
|---|---|---|
| LP Webflow capture | Inspecter le script tracking Webflow / global config (si accessible) | Oui, juste audit code/config |
| URL params propagation Webflow -> Client | Lecture source LP -> verifier href CTAs contient utm_* + click IDs | Oui |
| Client signup form parsing | Source keybuzz-client `app/register` ou `app/signup` : parse URL params + envoie en POST API | Oui |
| API backend resolution | Source keybuzz-api signup endpoint : INSERT signup_attribution avec UTM + click IDs + marketing_owner resolution rule | Oui |
| marketing_owner_tenant_id rule | Verifier algorithme : si utm_source IN (google/meta/tiktok/linkedin/concours) -> keybuzz-consulting ? si null -> null (organic) ? Decision business pending | Oui |

### 2.3 Systeme promo codes / bons de reduction (NOUVEAU SCOPE)

Ludovic a teste recemment un systeme de promo codes / bons de reduction. AS.15.4 doit determiner :

1. **Source** : ou est code la logique promo (Stripe ? keybuzz-api billing ? Admin v2 ?)
2. **Persistance** : table DB qui store les promo codes utilises (peut etre `signup_attribution` enrichie ? Nouvelle table ?)
3. **Interaction avec attribution** :
   - Promo code passe-t-il dans `signup_attribution.utm_campaign` ou champ dedie ?
   - Si oui : doit-il declencher CAPI (comme une attribution explicite) ?
   - Si non : promo codes restent comptables Stripe uniquement
4. **Admin KPIs** : la page /marketing/metrics ou /marketing/funnel affiche-t-elle les conversions promo ?
5. **GA4** : un event "promo_code_used" est-il emis ?
6. **CAPI** : Meta CAPI a un parametre `promotion_code` standard, est-il transmis ?

Decisions business attendues :
- Est-ce que les conversions via promo code doivent etre comptees dans le ROAS ad ? Si oui : promo = nouvelle source d attribution
- Ou bien les promo codes sont des conversions "directes" (pas d ad attribution) et restent hors ROAS ?

### 2.4 Test E2E DEV controle (sans fake event PROD)

Une fois l audit READ-ONLY termine, proposer un protocole de test E2E :

1. **Cibler DEV uniquement** : `https://client-dev.keybuzz.io`
2. **Simuler un click Meta** :
   - Construire URL LP DEV avec params `?utm_source=meta&utm_medium=cpc&utm_campaign=test-as154-dev&fbclid=PAxxxxxxxxxxxxxxx`
   - Visiter URL en navigateur (Ludovic)
   - Suivre le parcours jusqu au signup DEV (avec email test dedie marque)
   - Verifier `signup_attribution` DEV : fbclid present + utm + marketing_owner resolu
   - Si DEV emet CAPI : verifier que le destination DEV est marque pour test ou que META_TEST_EVENT_CODE est set (sinon events vont compter PROD Meta)
3. **Aucun event sur PROD** :
   - Aucun signup test sur client.keybuzz.io
   - Aucune destination PROD touchee
   - Aucune mutation DB PROD
4. **Cleanup** : delete signup test DEV apres validation, ou marquer comme test pour exclusion KPI

### 2.5 Live verification post-deploy ad campaigns

Quand l agence active enfin les UGC/videos/statics et que de vrais leads passent :

1. Surveiller `signup_attribution` last 24h apres go-live
2. Verifier captures fbclid/li_fat_id/gclid/ttclid sur signups reels
3. Verifier marketing_owner_tenant_id resolution
4. Verifier `conversion_events` rows + delivery_logs apparaissent sous H+24
5. Si gap apparait alors : escalader AS.15.x dedie

---

## 3. POINTS DE VIGILANCE POUR AS.15.4

### 3.1 Anti-pattern : "panne CAPI" sans verifier amont

Ne pas conclure :
- "0 delivery_log = bug pipeline"
- "0 fbclid = capture cassee"

avant d avoir verifie :
- Y a-t-il eu des leads ads reels arrives dans la fenetre ?
- Si non : 0 indicateur ad-attributed est NORMAL
- Si oui : alors le 0 indicateur est suspect, audit pipeline pertinent

### 3.2 Anti-pattern : test E2E PROD

Ne JAMAIS faire de test signup PROD avec ad params synthetiques. Risques :
- Compte Meta peut peser ces events sur le pixel reel
- Spend potentiel deflate ROAS
- Audit logs polluent
- Confusion attribution si vrai lead arrive en parallele

Test E2E uniquement DEV avec destination DEV-tagged + email test dedie.

### 3.3 Anti-pattern : modifier signup_attribution pour "tester"

Aucun UPDATE signup_attribution.fbclid manuel pour "voir si CAPI marche". Voir AS.15.3 : on a deja la preuve que le pipeline marche (deliveries 2026-05-05). Pas besoin de fake.

### 3.4 Promo codes : eviter le double-counting

Si une conversion vient d un promo code (acquired via partner concours, par exemple), il faut decider AVANT de declencher CAPI :
- Soit promo = source attribution (=> CAPI emis avec source=promo)
- Soit promo = direct conversion hors-ad (=> pas de CAPI emis)

Pas de "both" : risque double-count Meta/Google si une meme conversion est attribuee via plusieurs sources.

---

## 4. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 mutation provider declenchee par cette note
- 0 token / secret / payload expose
- 0 modification DB
- 0 build / deploy
- 0 changement Linear statut
- 0 patch source

Cette phase est uniquement docs-only : note de contexte + scope AS.15.4.

---

## 5. NON-REGRESSION

Aucun changement runtime. PROD + DEV identiques a AS.15.3 post-rapport :
- keybuzz-api PROD : v3.5.190-channels-tenantguard-prod
- keybuzz-client PROD : v3.5.197-channels-bff-userauth-prod
- keybuzz-admin-v2 PROD : v2.12.2-media-buyer-lp-domain-qa-prod
- keybuzz-backend PROD : v1.0.47-cross-env-guard-fix-prod

---

## 6. LINEAR (note brouillon KEY-322)

Pas necessaire de poster un commentaire separe pour cette note (qui complete AS.15.3). Si commentaire desire :

```
Note contexte AS.15.3 : signups recents sont des creations manuelles, pas des leads ad. Donc 0 fbclid + 0 delivery_log recent = NORMAL et NON un bug pipeline. AS.15.3 confirme pipeline OK (3 deliveries succes 2026-05-05).

Scope AS.15.4 ajuste :
- Auditer le parcours Landing Page -> signup pour FUTURS vrais leads ad (Webflow capture click IDs + propagation Client + INSERT signup_attribution)
- Inclure systeme promo codes / bons de reduction (decision business : alimentent-ils attribution marketing / Admin KPIs / GA4 / CAPI ?)
- Proposer test E2E DEV controle (sans fake event PROD)
- Live verification post go-live UGC/videos/statics agence

Priorite : comprendre l attribution AMONT (LP capture + parsing + resolution marketing_owner), pas accuser le pipeline CAPI deja prouve fonctionnel.

Rapport docs-only : keybuzz-infra/docs/PH-ADMIN-T8.12AS.15.3.1-CAPI-AUDIT-CONTEXT-NOTE-AND-AS.15.4-SCOPE.md
```

Aucun statut Linear change.

---

## 7. PHRASE CIBLE FINALE

Note de contexte business integree apres AS.15.3 : signups recents = creations manuelles, donc 0 fbclid / 0 delivery_log recent = NORMAL. AS.15.3 garde son verdict "pipeline OK + 0 eligible event 7d". AS.15.4 doit auditer LE PARCOURS LP -> signup pour futurs vrais leads, incluant le systeme promo codes + decision business attribution, et proposer un test E2E DEV controle sans fake event PROD. Priorite : attribution AMONT, pas accusation pipeline CAPI. Memoire persistante mise a jour pour les futurs audits.

STOP
