# PH-T7.2.2.1-EMERGENCY-ROLLBACK-AND-TIKTOK-FORENSIC-RECOVERY-01 — TERMINE

> **Date** : 2026-04-18
> **Environnement** : DEV uniquement
> **Type** : rollback d'urgence + recuperation forensique TikTok

**Verdict : GO — DEV SANE STATE RESTORED — TIKTOK WORK RECOVERABLE**

---

## Preflight


| Element                           | Valeur                                                              |
| --------------------------------- | ------------------------------------------------------------------- |
| Image client DEV (avant rollback) | `ghcr.io/keybuzzio/keybuzz-client:v3.5.49-tiktok-dev`               |
| Image API DEV (avant rollback)    | `ghcr.io/keybuzzio/keybuzz-api:v3.5.48-tiktok-dev`                  |
| Baseline rollback client          | `ghcr.io/keybuzzio/keybuzz-client:v3.5.79-tracking-t5.3-replay-dev` |
| Baseline rollback API             | `ghcr.io/keybuzzio/keybuzz-api:v3.5.78-ga4-mp-webhook-dev`          |
| sGTM TikTok EAPI tag              | Publie (Version 5, container GTM-NTPDQ7N7)                          |
| DB colonne `ttclid`               | Existe (`text`), 0 lignes avec donnees                              |


---

## Rollback


| Action                                          | Resultat                                              |
| ----------------------------------------------- | ----------------------------------------------------- |
| Client DEV → `v3.5.79-tracking-t5.3-replay-dev` | `deployment "keybuzz-client" successfully rolled out` |
| API DEV → `v3.5.78-ga4-mp-webhook-dev`          | `deployment "keybuzz-api" successfully rolled out`    |
| PROD                                            | NON TOUCHE                                            |
| Website                                         | NON TOUCHE                                            |


---

## Validation apres rollback


| Domaine       | Etat apres rollback                                                                                                    |
| ------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `/start`      | OK — page Bienvenue + wizard 4 etapes                                                                                  |
| Dashboard     | OK — KPIs, SLA, repartition canaux, activite                                                                           |
| Inbox         | OK — conversations, messages, IA suggestions, commandes                                                                |
| Settings      | OK — tous onglets (Entreprise, Horaires, Conges, Messages auto, Signature, Notifications, IA, Espaces, Agents, Avance) |
| Agents        | OK — onglet visible dans settings                                                                                      |
| Autopilot     | OK — section visible dans inbox                                                                                        |
| Tracking GA4  | OK — `gtag` present dans le bundle (1 occurrence)                                                                      |
| Tracking Meta | OK — `fbq` present dans le bundle (1 occurrence)                                                                       |
| TikTok Pixel  | ABSENT — 0 occurrence `D7HQO0JC77U2ODPGMDI0` dans le bundle (attendu)                                                  |
| TikTok `ttq`  | ABSENT — 0 occurrence dans le bundle (attendu)                                                                         |


**Aucun comportement TikTok cassant visible. Baseline saine restauree.**

---

## Forensic Inventory

### Client


| Attribut                    | Valeur                                                                           |
| --------------------------- | -------------------------------------------------------------------------------- |
| Branche utilisee            | `ph-t72/tiktok-tracking-dev` (creee depuis `ph148/onboarding-activation-replay`) |
| Branche correcte (attendue) | `ph148/onboarding-activation-replay`                                             |
| Commits TikTok              | `be29738d` (code TikTok) + `bfb9cdc2` (Dockerfile ARG)                           |
| Branche pushee sur GitHub   | Oui (`origin/ph-t72/tiktok-tracking-dev`)                                        |
| Branche bastion client      | `ph-t72/tiktok-tracking-dev` (checkout effectue)                                 |


### Fichiers client modifies (TikTok uniquement)


| Fichier                                     | Modification TikTok                                                                                                                     | Reutilisable ?                        |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `src/lib/attribution.ts`                    | +`ttclid` dans `AttributionContext`, `CLICK_ID_PARAMS`, `captureAttribution()`, `hasSignals()`, `initAttribution()`                     | Oui — code propre, strictement TikTok |
| `src/lib/tracking.ts`                       | +`window.ttq` type, `trackTikTok()` helper, appels dans `trackSignupStart`, `trackBeginCheckout`, `trackPurchase` avec `event_id` dedup | Oui — code propre, strictement TikTok |
| `src/components/tracking/SaaSAnalytics.tsx` | +TikTok Pixel base code (events.js), `NEXT_PUBLIC_TIKTOK_PIXEL_ID` env var, condition `shouldLoad`                                      | Oui — code propre, strictement TikTok |
| `Dockerfile`                                | +`ARG/ENV NEXT_PUBLIC_TIKTOK_PIXEL_ID`                                                                                                  | Oui — 2 lignes, propre                |
| `scripts/ph-t72-db-migration.sql`           | Script ALTER TABLE ttclid                                                                                                               | Oui — deja applique                   |
| `scripts/ph-t72-patch-api.js`               | Script patch API (version initiale, remplacee par v2)                                                                                   | Non — utilise mauvais chemins         |


### API


| Attribut                  | Valeur                                                            |
| ------------------------- | ----------------------------------------------------------------- |
| Branche bastion           | `ph147.4/source-of-truth` (correcte)                              |
| Patches appliques         | Oui — `ttclid` dans tenant-context-routes.ts et billing/routes.ts |
| Patches commites          | Non — modifications locales non commitees                         |
| Image deployee (rollback) | `v3.5.78-ga4-mp-webhook-dev` (sans ttclid)                        |


### Diff API (patches non commites sur bastion)


| Fichier                                     | Modification TikTok                                             | Reutilisable ?         |
| ------------------------------------------- | --------------------------------------------------------------- | ---------------------- |
| `src/modules/auth/tenant-context-routes.ts` | +`ttclid` dans INSERT `signup_attribution` ($18) + params array | Oui — 3 lignes, propre |
| `src/modules/billing/routes.ts`             | +`ttclid` dans SELECT, GA4 params, Stripe metadata              | Oui — 3 lignes, propre |


### DB


| Attribut                            | Valeur                                              |
| ----------------------------------- | --------------------------------------------------- |
| Colonne `signup_attribution.ttclid` | Existe (`text`, nullable)                           |
| Donnees ecrites                     | 0 lignes                                            |
| Migration appliquee en              | DEV uniquement                                      |
| Impact suppression                  | Aucun (nullable, 0 donnees, pas de FK, pas d'index) |
| Decision                            | NE PAS SUPPRIMER (regle du prompt + inutile)        |


### sGTM


| Attribut            | Valeur                                                                                                               |
| ------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Container           | GTM-NTPDQ7N7 (Addingwell)                                                                                            |
| Version publiee     | 5 — "v5 - TikTok Events API"                                                                                         |
| Tag                 | "TikTok EAPI - Purchase Events"                                                                                      |
| Template            | TikTok Events API (Official) - Community Gallery                                                                     |
| Pixel ID            | `D7HQO0JC77U2ODPGMDI0`                                                                                               |
| Access Token        | `23c74707a34c6ee86f3d94dea98afdfeceb20a99`                                                                           |
| Event               | CompletePayment                                                                                                      |
| Trigger             | `purchase_event` (event_name = purchase)                                                                             |
| Etat actuel         | Publie et actif (recoit les events purchase via GA4 MP)                                                              |
| Impact sur baseline | Aucun — le tag ne se declenche que si un event purchase arrive, ce qui fonctionne deja pour GA4/Google Ads/Meta CAPI |


---

## Classification


| Element                                                | Classe                              | Justification                                                                     |
| ------------------------------------------------------ | ----------------------------------- | --------------------------------------------------------------------------------- |
| `src/lib/attribution.ts` diff ttclid                   | **A** — recuperable tel quel        | Code strictement TikTok, pas de dependance parasite, diff propre                  |
| `src/lib/tracking.ts` diff trackTikTok                 | **A** — recuperable tel quel        | Helper + appels event, code isole, dedup event_id inclus                          |
| `src/components/tracking/SaaSAnalytics.tsx` diff Pixel | **A** — recuperable tel quel        | Base code TikTok Pixel, pattern identique a GA4/Meta                              |
| `Dockerfile` ARG/ENV TikTok                            | **A** — recuperable tel quel        | 2 lignes, pattern existant                                                        |
| API `tenant-context-routes.ts` patch                   | **B** — recuperable avec adaptation | Patch non commite sur bastion, a rejouer dans la bonne branche                    |
| API `billing/routes.ts` patch                          | **B** — recuperable avec adaptation | Patch non commite sur bastion, a rejouer dans la bonne branche                    |
| `scripts/ph-t72-patch-api.js` (v1)                     | **C** — a rejeter                   | Utilise mauvais chemins (`/routes.ts` vs `tenant-context-routes.ts`)              |
| `scripts/ph-t72-patch-api-v2.js`                       | **B** — recuperable avec adaptation | Version corrigee, fonctionne mais a integrer proprement                           |
| DB migration `ttclid`                                  | **A** — recuperable tel quel        | Deja appliquee, colonne existe, 0 donnees, idempotente                            |
| sGTM tag TikTok EAPI                                   | **A** — recuperable tel quel        | Publie, fonctionnel, pas d'impact negatif sur baseline                            |
| Branche `ph-t72/tiktok-tracking-dev`                   | **C** — a rejeter                   | Branche freestyle, pas la branche prescrite                                       |
| Image `v3.5.49-tiktok-dev`                             | **C** — a rejeter                   | Build hors baseline                                                               |
| Image `v3.5.48-tiktok-dev`                             | **C** — a rejeter                   | Build hors baseline                                                               |
| Rapport `keybuzz-docs/PH-T7.2.2-...md`                 | **C** — a rejeter                   | Mauvais emplacement (keybuzz-docs/ au lieu de keybuzz-infra/docs/), rollback faux |


---

## Plan de replay propre (sans execution)

### Ordre

1. **DB** — rien a faire, colonne `ttclid` deja presente
2. **Client** — cherry-pick ou re-appliquer les diffs sur `ph148/onboarding-activation-replay`
3. **API** — re-appliquer le patch sur `ph147.4/source-of-truth` et commiter
4. **sGTM** — rien a faire, tag deja publie (Version 5)
5. **Build Client** — depuis `ph148/onboarding-activation-replay` avec `--build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7HQO0JC77U2ODPGMDI0`
6. **Build API** — depuis `ph147.4/source-of-truth` apres commit du patch
7. **Deploy DEV** — client + API
8. **Test DEV** — verifier pixel, events, ttclid capture, dedup

### Client — fichiers a modifier


| Fichier                                     | Action                                       |
| ------------------------------------------- | -------------------------------------------- |
| `src/lib/attribution.ts`                    | Appliquer le diff ttclid (4 hunks, 8 lignes) |
| `src/lib/tracking.ts`                       | Appliquer le diff trackTikTok (30 lignes)    |
| `src/components/tracking/SaaSAnalytics.tsx` | Appliquer le diff Pixel (29 lignes)          |
| `Dockerfile`                                | Appliquer le diff ARG/ENV (2 lignes)         |


### API — fichiers a patcher


| Fichier                                     | Action                                                       |
| ------------------------------------------- | ------------------------------------------------------------ |
| `src/modules/auth/tenant-context-routes.ts` | +ttclid dans INSERT (3 lignes modifiees)                     |
| `src/modules/billing/routes.ts`             | +ttclid dans SELECT, params, Stripe meta (3 lignes ajoutees) |


### sGTM — aucune action

Le tag TikTok EAPI est deja publie et actif dans la Version 5 du container GTM-NTPDQ7N7. Il ne cause aucun effet de bord car il ne se declenche que sur l'event `purchase`.

---

## Conclusion

- Rollback DEV execute avec succes
- Client DEV : `v3.5.79-tracking-t5.3-replay-dev` — Running
- API DEV : `v3.5.78-ga4-mp-webhook-dev` — Running
- PROD : non touchee
- Website : non touche
- Tracking GA4/Meta/Google Ads : intact
- TikTok Pixel : retire du client (baseline sans TikTok)
- DB `ttclid` : colonne preservee (0 donnees, nullable, non destructive)
- sGTM TikTok EAPI : publie, actif, sans impact negatif
- Tout le code TikTok est recuperable (classe A ou B)
- Les images freestyle et la branche hors cadre sont a rejeter (classe C)

**Aucune autre action effectuee.**

**STOP**