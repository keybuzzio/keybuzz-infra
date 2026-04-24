# PH153 — CLIENT SOURCE CONSOLIDATION PLAN

> Date : 2026-04-14
> Type : audit + strategie de consolidation
> Environnement : DEV + GitHub
> Aucune modification de code effectuee

---

## 1. Preflight


| Element                      | Valeur                                             |
| ---------------------------- | -------------------------------------------------- |
| DEV                          | `v3.5.63-ph151.2-case-summary-clean-dev` (stable)  |
| PROD                         | `v3.5.63-ph151.2-case-summary-clean-prod` (stable) |
| Aucune modification en cours | confirme                                           |


---

## 2. Matrice comparative des branches

**Cible image v3.5.63 : 134 routes, 52 pages, 34 public**


| Branche                     | Commit    | Date   | Fichiers | Routes | Pages | Public | Src | Ecart routes | Pollution                      |
| --------------------------- | --------- | ------ | -------- | ------ | ----- | ------ | --- | ------------ | ------------------------------ |
| `release/client-v3.5.220`   | `2adbd40` | 8 avr  | 407      | 130    | 51    | 33     | 121 | **-4**       | 0                              |
| `ph152.7-full-image-mirror` | `09bb488` | 14 avr | 412      | 134    | 51    | 34     | 121 | 0            | 0 (shopify reconstruit)        |
| `rebuild/ph143-client`      | `6ffeebd` | 7 avr  | 604      | 131    | 51    | 33     | 124 | **-3**       | ~200 (docs, studio anciens)    |
| `main`                      | `1a7c51d` | 5 avr  | 605      | 131    | 51    | 33     | 124 | **-3**       | ~200                           |
| `ph152.6-client-parity`     | `3988489` | 14 avr | 614      | 132    | 51    | 34     | 129 | **-2**       | **200** (keybuzz-studio, .bak) |
| `d16-settings`              | `db8f4a8` | 20 mar | 356      | 104    | 48    | 33     | 97  | **-30**      | 0 (mais obsolete)              |


---

## 3. Couverture fonctionnelle


| Feature                          | release/v3.5.220 | ph152.7           | rebuild/ph143 | main | ph152.6 | d16     |
| -------------------------------- | ---------------- | ----------------- | ------------- | ---- | ------- | ------- |
| SupervisionPanel                 | oui              | oui               | oui           | oui  | oui     | non     |
| OnboardingHub (/start)           | oui              | oui               | oui           | oui  | oui     | oui     |
| autopilot/draft routes           | oui              | oui               | oui           | oui  | **non** | non     |
| billing agent-keybuzz            | oui              | oui               | oui           | oui  | oui     | non     |
| shopify routes                   | **non**          | oui (reconstruit) | non           | non  | oui     | non     |
| space-invites/resolve            | **non**          | oui               | oui           | oui  | oui     | non     |
| shopify.svg                      | **non**          | oui               | non           | non  | oui     | non     |
| channels (add/remove/list)       | oui              | oui               | oui           | oui  | oui     | oui     |
| settings/agents + ai-supervision | oui              | oui               | oui           | oui  | oui     | non     |
| roles/me + permissions           | oui              | oui               | oui           | oui  | oui     | non     |
| conversations escalation         | oui              | oui               | oui           | oui  | oui     | non     |
| AI suggestions                   | oui              | oui               | oui           | oui  | oui     | partiel |
| middleware.ts                    | oui              | oui               | oui           | oui  | oui     | oui     |
| Dockerfile (explicit COPY)       | oui              | oui               | oui           | oui  | oui     | oui     |


---

## 4. Decouverte critique : 5 composants inbox orphelins

Les fichiers suivants sont dans `ph152.6-client-parity` (commit PH152.9) mais ne sont **importes par AUCUN fichier** dans AUCUNE branche :


| Fichier                                                    | Taille       | Import par InboxTripane | Import par autre fichier |
| ---------------------------------------------------------- | ------------ | ----------------------- | ------------------------ |
| `src/features/inbox/components/AICaseSummary.tsx`          | 6313B / 150L | non                     | non                      |
| `src/features/inbox/components/ConversationSummaryBar.tsx` | 4771B / 103L | non                     | non                      |
| `src/features/inbox/components/MessageBubble.tsx`          | 9231B / 191L | non                     | non                      |
| `src/features/inbox/components/MessageFilterToggle.tsx`    | 1324B / 35L  | non                     | non                      |
| `src/features/inbox/utils/messageClassifier.ts`            | 3701B / 88L  | non                     | refs internes uniquement |


**Conclusion** : code mort. Present sur le disque lors du build mais non compile dans l'image v3.5.63. Preserve dans Git (PH152.9) pour reference future mais ne participe pas au rendu.

---

## 5. Ecarts detailles par branche

### Routes manquantes vs image (134)


| Route                         | release/v3.5.220 | rebuild/ph143 | main     | ph152.6      |
| ----------------------------- | ---------------- | ------------- | -------- | ------------ |
| `api/shopify/connect`         | manquant         | manquant      | manquant | present      |
| `api/shopify/disconnect`      | manquant         | manquant      | manquant | present      |
| `api/shopify/status`          | manquant         | manquant      | manquant | present      |
| `api/space-invites/resolve`   | manquant         | present       | present  | present      |
| `api/autopilot/draft`         | present          | present       | present  | **manquant** |
| `api/autopilot/draft/consume` | present          | present       | present  | **manquant** |


### Provenance des fichiers manquants


| Fichier                                  | Jamais commite ? | Source disponible                           |
| ---------------------------------------- | ---------------- | ------------------------------------------- |
| `app/api/shopify/status/route.ts`        | OUI              | workspace local (PH152.9 commit `39884893`) |
| `app/api/shopify/connect/route.ts`       | OUI              | workspace local (PH152.9 commit `39884893`) |
| `app/api/shopify/disconnect/route.ts`    | OUI              | workspace local (PH152.9 commit `39884893`) |
| `app/api/space-invites/resolve/route.ts` | non              | `rebuild/ph143-client` + PH152.9            |
| `public/marketplaces/shopify.svg`        | OUI              | extrait image + PH152.9                     |


---

## 6. Branche recommandee : `release/client-v3.5.220`

### Justification

1. **C'est la branche qui etait checkout lors du build v3.5.63** (confirme par le reflog bastion du 13 avril 21:25 UTC)
2. Structure propre : 407 fichiers, zero pollution
3. Contient deja les features critiques : SupervisionPanel, autopilot/draft, agent-keybuzz billing, roles, escalation, settings agents/ai-supervision
4. Dockerfile correct avec COPY explicites
5. Manque seulement 4 routes + 1 asset (tous preserves dans Git)

### Pourquoi pas les autres


| Option                    | Raison du rejet                                                                                           |
| ------------------------- | --------------------------------------------------------------------------------------------------------- |
| ph152.6-client-parity     | 200 fichiers polluants (keybuzz-studio complet, .bak), manque autopilot/draft, base d16-settings ancienne |
| rebuild/ph143-client      | 604 fichiers (pollution docs), manque shopify routes, pas la branche du build                             |
| main                      | 605 fichiers, manque shopify routes, pas la branche du build                                              |
| ph152.7-full-image-mirror | Routes shopify reconstruites depuis JS compile (pas originales)                                           |
| d16-settings              | Obsolete, manque 30 routes                                                                                |


---

## 7. Strategie de consolidation : Option A

**Partir de `release/client-v3.5.220`, ajouter les 5 fichiers manquants.**

### Source des fichiers


| Fichier a ajouter                        | Source                                    | Type                         |
| ---------------------------------------- | ----------------------------------------- | ---------------------------- |
| `app/api/shopify/status/route.ts`        | `ph152.6-client-parity` commit `39884893` | Original workspace           |
| `app/api/shopify/connect/route.ts`       | `ph152.6-client-parity` commit `39884893` | Original workspace           |
| `app/api/shopify/disconnect/route.ts`    | `ph152.6-client-parity` commit `39884893` | Original workspace           |
| `app/api/space-invites/resolve/route.ts` | `ph152.6-client-parity` commit `39884893` | Original (via rebuild/ph143) |
| `public/marketplaces/shopify.svg`        | `ph152.6-client-parity` commit `39884893` | Extrait image                |


### Resultat attendu


| Metrique | Avant (release) | Apres consolidation | Image v3.5.63 |
| -------- | --------------- | ------------------- | ------------- |
| Routes   | 130             | **134**             | 134           |
| Pages    | 51              | 51                  | 51 (+1 auto)  |
| Public   | 33              | **34**              | 34            |


---

## 8. Risques


| Risque                                     | Niveau | Mitigation                                             |
| ------------------------------------------ | ------ | ------------------------------------------------------ |
| Routes Shopify jamais testees isolement    | Faible | BFF proxy simples, pattern identique aux autres routes |
| space-invites/resolve copie depuis rebuild | Faible | Code original, pas reconstruit                         |
| shopify.svg asset statique                 | Nul    | Extrait directement de l'image                         |
| 5 composants inbox orphelins exclus        | Nul    | Code mort, non importe, non compile dans v3.5.63       |
| Build diverge de v3.5.63                   | Faible | Meme base + memes fichiers = meme resultat attendu     |


---

## 9. Plan de rebuild (phase suivante PH153.1)

### Etapes

1. Creer branche `consolidation/client-v3.5.63-source-of-truth` depuis `release/client-v3.5.220` (`2adbd40`)
2. Copier les 5 fichiers manquants depuis `ph152.6-client-parity` (commit PH152.9 `39884893`)
3. Commit unique : "PH153.1 — consolidation source of truth"
4. Push sur GitHub
5. Build `v3.5.71-ph153.1-consolidated-dev` depuis cette branche (clean Git, zero fichier externe)
6. Deploy DEV
7. Validation humaine : comparaison visuelle v3.5.63 vs v3.5.71
8. Si identique : cette branche devient la source de verite officielle

### Validations necessaires apres rebuild

- Inbox : liste conversations, detail, reply
- Dashboard : SupervisionPanel visible
- /start : stepper horizontal OnboardingHub
- Settings : onglets agents, ai-supervision
- Channels : page avec logos
- Billing : page plan, KBActions
- Suggestions IA : slide-over dans inbox

---

## 10. Verdict

### SOURCE CONSOLIDATION PLAN READY


| Critere                  | Statut                                            |
| ------------------------ | ------------------------------------------------- |
| Branches analysees       | 6 branches + workspace local                      |
| Matrice comparative      | complete (routes, pages, public, features)        |
| Couverture fonctionnelle | verifiee pour 14 features critiques               |
| Ecarts identifies        | 4 routes + 1 asset manquants dans la branche base |
| Branche recommandee      | `release/client-v3.5.220`                         |
| Strategie choisie        | Option A — base propre + 5 fichiers               |
| Risques documentes       | tous faibles ou nuls                              |
| Plan de rebuild defini   | 8 etapes + 7 validations                          |
| Code mort identifie      | 5 composants inbox orphelins (exclus)             |


### CLIENT SOURCE CONSOLIDATION STRATEGY DEFINED

---

*Rapport genere par CE — phase PH153*
*ZERO modification de code effectuee*