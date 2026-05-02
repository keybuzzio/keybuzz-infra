# PH-SAAS-T8.12Y.9C - Lifecycle Progressive Activation Design & Safety Gates

> Phase : PH-SAAS-T8.12Y.9C-LIFECYCLE-PROGRESSIVE-ACTIVATION-DESIGN-AND-SAFETY-GATES-01
> Date : 2026-05-02
> Type : Audit + Design (read-only, zero envoi, zero deploy)
> Environnement : PROD (lecture seule)
> Predecesseurs : Y.9A (CronJob dry-run), Y.9B (envoi controle), Y.9B.1 (QA closure)

---

## PREFLIGHT

### Etat repos

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-infra | main | `15c4e82` | Non (legacy docs/client non lies) | **GO** |
| keybuzz-api (bastion) | ph147.4/source-of-truth | `e8d3ff48` | src/ propre | **GO** |

### Etat runtime PROD

| Service | Runtime | Manifest | Verdict |
|---|---|---|---|
| API PROD | v3.5.134-trial-lifecycle-controlled-send-prod | Conforme | **GO** |
| CronJob lifecycle | trial-lifecycle-dryrun (`0 8 * * *`, dryRun:true) | Conforme | **GO** |
| CronJob reel lifecycle | Aucun | Attendu | **GO** |

### Idempotence PROD

| Tenant (masque) | Template | Status | Date |
|---|---|---|---|
| ludovic-mojo... | trial-welcome | sent | 2026-05-02T14:56:59Z |

**1 seule row** = envoi controle Y.9B. Aucun email supplementaire.

### Baselines preservees

| Service | Image attendue | Statut |
|---|---|---|
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | Non touche |
| Admin PROD | v2.11.37-acquisition-baseline-truth-prod | Non touche |
| Website PROD | v0.6.8-tiktok-browser-pixel-prod | Non touche |

---

## SOURCES RELUES

- `CE_PROMPTING_STANDARD.md` : converti en regles de phase
- `RULES_AND_RISKS.md` : risques lifecycle verifies
- `TRIAL_WOW_STACK_BASELINE.md` : baseline lifecycle validee
- `PH-SAAS-T8.12Y.4` : promotion transactional emails PROD
- `PH-SAAS-T8.12Y.8` : foundation + unsubscribe PROD
- `PH-SAAS-T8.12Y.9A` : CronJob dry-run PROD
- `PH-SAAS-T8.12Y.9B` : envoi controle PROD allowlist
- `PH-SAAS-T8.12Y.9B.1` : QA closure GO COMPLET
- `trial-lifecycle.service.ts` : logique exclusions, candidats, envoi
- `trial-lifecycle.routes.ts` : guards PROD, controlledSend, dry-run
- CronJob manifest PROD : dry-run confirme
- Table `trial_lifecycle_emails_sent` : 1 row attendue

---

## ETAPE 1 - AUDIT CANDIDATS PROD

### Matrice agregee (sans PII)

| Categorie | Count |
|---|---|
| Total trial tenants | 23 |
| Excluded billing_exempt | 21 |
| Excluded already_paid | 0 |
| Excluded opt_out | 0 |
| Excluded already_sent | 0 (*) |
| Excluded missing_owner_email | 0 |
| Excluded invalid_trial_dates | 0 |
| **Eligible** | **2** |

(*) L'envoi controle Y.9B a cree 1 row (trial-welcome pour ludovic-mojo...) mais ce tenant reste eligible pour les autres templates.

### Breakdown exemptions

| Raison | Count |
|---|---|
| internal_admin | 2 |
| test_account | 20 |
| **Total exempt** | **22** |

Note : 1 tenant est doublement compte (exempt + 1 des 2 eligibles, mais les 2 eligibles ont des domaines `keybuzz.pro`).

### Breakdown domaines

| Domaine | Count | Type |
|---|---|---|
| gmail.com | 15 | Ludovic/test |
| keybuzz.pro | 6 | Interne |
| keybuzz.io | 1 | Interne |
| switaa.com | 1 | Interne |

### Constat critique

**Zero client externe reel** dans le pipeline trial PROD. Les 23 tenants sont tous internes, test ou Ludovic. Les 2 tenants eligibles restants ont des emails `@keybuzz.pro` (interne).

**Implication** : le design d'activation progressive doit preparer l'infrastructure pour les futurs vrais signups, pas pour un rattrapage sur la base existante.

---

## ETAPE 2 - SEGMENTATION D'ELIGIBILITE

### Regles d'eligibilite (etat actuel vs recommande)

| # | Regle | Source DB | Implementee ? | Obligatoire | Justification |
|---|---|---|---|---|---|
| E1 | Trial actif ou recemment termine | `tenant_metadata.is_trial`, `trial_ends_at` | Oui | Oui | Base du lifecycle |
| E2 | Owner email valide | `users.email` via `user_tenants(role=owner)` | Oui | Oui | Pas d'envoi sans destinataire |
| E3 | Pas billing_exempt | `tenant_billing_exempt.exempt=true` | Oui | Oui | Exclure tenants internes/admin |
| E4 | Pas subscription active/paid | `billing_subscriptions.status='active'` | Oui | Oui | Clients deja payants |
| E5 | Pas opt-out lifecycle | `tenant_settings.lifecycle_email_optout=true` | Oui | Oui | Respect preference |
| E6 | Template non deja envoye | `trial_lifecycle_emails_sent(status='sent')` | Oui | Oui | Idempotence |
| **E7** | **Domaine email non interne** | `users.email` (split @domain) | **NON** | **Oui** | **GAP CRITIQUE** |
| **E8** | **Tenant cree apres baseline date** | `tenant_metadata.created_at >= BASELINE` | **NON** | **Oui** | **GAP CRITIQUE** |
| **E9** | **Tenant status = active** | `tenants.status` | **NON** | **Recommande** | Pas d'envoi aux archives/suspendus |
| **E10** | **Pattern tenant ID non test/internal** | `tenants.id` regex | **NON** | **Recommande** | Filet de securite |
| E11 | Plan choisi connu | `tenants.plan` | Implicite | Recommande | Coherence template |

### Domaines internes a bloquer (INTERNAL_DOMAINS_BLOCKLIST)

```
keybuzz.io
keybuzz.pro
ecomlg.fr
ecomlg.com
switaa.com
test.com
test-keybuzz.io
```

### Baseline date

La `ACTIVATION_BASELINE_DATE` doit etre definie au moment de l'activation Y.9D. Seuls les tenants crees **apres** cette date recevront des emails lifecycle. Cela evite :
- rattrapage sur les 23 tenants test existants
- emails incoherents (trial-welcome a un tenant cree il y a 30 jours)
- confusion avec les anciens envois controles

Valeur recommandee : date de deploiement Y.9D (a definir).

---

## ETAPE 3 - STRATEGIE TEMPLATE

### Deploiement progressif par template

| Template | Objectif | Risque | Phase recommandee | Declencheur |
|---|---|---|---|---|
| `trial-welcome` | Accueil, premier nudge onboarding | Faible | Phase 1 (Y.9D) | Day 0, creation trial |
| `trial-day-2` | Rappel connexion, decouverte | Faible | Phase 2 (Y.9E) | Day 2, trial actif |
| `trial-day-5` | Feature discovery, engagement | Moyen | Phase 3 (Y.9F) | Day 5, trial actif |
| `trial-day-10` | Urgency, 4 jours restants | Moyen | Phase 3 (Y.9F) | Day 10, trial actif |
| `trial-day-13` | Derniere chance, 1 jour restant | Eleve (conversion push) | Phase 4 (Y.9G) | Day 13, trial actif |
| `trial-ended` | Fin de trial, upgrade CTA | Moyen | Phase 4 (Y.9G) | Day 14, trial termine |
| `trial-grace` | Derniere relance post-trial | Eleve (risque spam) | Phase 4 (Y.9G) | Day 16+, trial expire |

### Justification de la progressivite

1. **trial-welcome** est le plus safe : envoye immediatement apres inscription, contexte clair
2. **trial-day-2** et **trial-day-5** sont informatifs, faible risque
3. **trial-day-10** et **trial-day-13** sont urgents, necessitent validation copy + conversion
4. **trial-ended** et **trial-grace** sont les plus risques : l'utilisateur a deja quitte, risque de perception spam

---

## ETAPE 4 - LIMITES DE VOLUME

### Limites de securite recommandees

| Limite | Phase 1 (Y.9D) | Phase 2 (Y.9E) | Phase 3 (Y.9F) | Phase 4 (Y.9G) | Justification |
|---|---|---|---|---|---|
| `maxEmailsPerRun` | 3 | 10 | 25 | 50 | Protection bulk accidentel |
| `maxEmailsPerDay` | 5 | 20 | 50 | 200 | Reputation SMTP + delivrabilite |
| `maxEmailsPerTenant` | 1/template | 1/template | 1/template | 1/template | Idempotence (deja implementee) |
| `maxEmailsPerTemplatePerDay` | 3 | 10 | 25 | 50 | Progression par template |
| `batchSize` | 1 | 3 | 5 | 10 | Granularite controle |
| `cooldownBetweenBatches` | N/A | 30s | 30s | 15s | Eviter saturation SMTP |
| Mode | `pilot` | `pilot` | `public` | `public` | Transition progressive |

### Modes operationnels

| Mode | Description | Requis |
|---|---|---|
| `dryRun` | Calcule candidats, n'envoie rien | Actuel (CronJob) |
| `controlledSend` | Envoi unique, allowlist stricte, parametres explicites | Y.9B (valide) |
| `pilot` | Envoi reel, cap faible, baseline date, domaine filtre | **Y.9D** (a implementer) |
| `public` | Envoi reel, caps normaux, tous domaines externes eligibles | **Y.9F** (a implementer) |

---

## ETAPE 5 - STOP CONDITIONS

### Conditions d'arret automatique

| # | Stop condition | Seuil | Action | Implementee ? |
|---|---|---|---|---|
| S1 | Bounce/error SMTP par run | > 2 ou > 20% du batch | Log ERROR + suspendre run en cours | Non |
| S2 | Unsubscribe par jour | > 5 ou > 30% des envois du jour | Alert log + review humain obligatoire | Non |
| S3 | Spam complaint | > 0 (si signal disponible) | Stop immediat + alert | Non |
| S4 | SMTP connection failure | > 3 retries echoues | Stop run + alert | Non |
| S5 | `sentCount > maxEmailsPerRun` | Depassement cap | Impossible (cap en amont) | A implementer |
| S6 | CronJob real-send detecte hors phase validee | Detection anomale | Alert critique + investigation | Non (design) |
| S7 | Billing/tracking/CAPI drift | Toute mutation non prevue | Stop immediat | Non (separation architecture) |
| S8 | Idempotence breach (duplicate insert) | > 0 | Stop immediat + audit DB | Partiel (ON CONFLICT DO NOTHING) |
| S9 | PII leak dans logs | Detection pattern email/token | Stop immediat + purge logs | Non |
| S10 | Plainte utilisateur | 1 | Review humain + possible stop | Humain |

### Precedence des stop conditions

1. **Immediat** : S3, S7, S8, S9 -> arret total du systeme lifecycle
2. **Run-level** : S1, S4, S5 -> arret du run en cours, prochain run OK si corrige
3. **Review** : S2, S6, S10 -> alert + intervention humaine requise

---

## ETAPE 6 - OBSERVABILITE

### Signals autorises (PII-safe)

| Signal | Ou | PII-safe | Phase |
|---|---|---|---|
| Run ID (UUID) | Logs stdout pod API | Oui | Y.9D |
| dryRun flag (true/false) | Logs stdout | Oui | Existant |
| Template name | Logs stdout | Oui | Existant |
| Eligible count | Logs stdout | Oui | Existant |
| Excluded counts (par raison) | Logs stdout | Oui | Existant |
| Sent count | Logs stdout | Oui | Existant |
| Provider accepted count | Logs stdout | Oui | Y.9D |
| Provider failed count + error code | Logs stdout | Oui | Y.9D |
| Idempotence skipped count | Logs stdout | Oui | Y.9D |
| Batch number / total | Logs stdout | Oui | Y.9E |
| Timestamp run start/end | Logs stdout | Oui | Existant |
| Mode (dryRun/controlledSend/pilot/public) | Logs stdout | Oui | Y.9D |
| Opt-out count total | Logs stdout | Oui | Y.9D |

### Signals interdits

| Signal | Pourquoi |
|---|---|
| Token unsubscribe | Secret HMAC, permet opt-out par un tiers |
| Full signed unsubscribe URL | Contient le token |
| Email complet du destinataire | PII |
| Contenu HTML complet de l'email | Volume + PII potentiel |
| Tenant ID complet (si non necessaire) | Masquer suffisamment (12 chars + "...") |
| COOKIE_SECRET / LIFECYCLE_TOKEN | Secrets |
| Provider message ID | Inutile dans les logs normaux |

### Metriques futures (Y.9F+)

| Metrique | Endpoint | Description |
|---|---|---|
| Total emails sent (24h) | `/internal/lifecycle/metrics` | Compteur daily |
| Unsubscribe rate (7d) | `/internal/lifecycle/metrics` | % opt-out vs envois |
| Template distribution | `/internal/lifecycle/metrics` | Repartition par template |
| Error rate (24h) | `/internal/lifecycle/metrics` | % erreurs vs tentatives |

---

## ETAPE 7 - UNSUBSCRIBE / OPT-OUT POLICY

| # | Point | Regle |
|---|---|---|
| O1 | Scope opt-out | Emails lifecycle trial uniquement |
| O2 | Emails transactionnels | Jamais bloques (invite, billing, auth, OTP) |
| O3 | Mecanisme | Lien HMAC-SHA256 signe dans le footer de chaque email lifecycle |
| O4 | Page confirmation | HTML statique claire ("Vous etes desabonne") |
| O5 | Idempotence opt-out | Oui : visite repetee = page "Deja desabonne" |
| O6 | Stockage | `tenant_settings.lifecycle_email_optout = true` |
| O7 | Headers email | `List-Unsubscribe` + `List-Unsubscribe-Post` (RFC 8058) |
| O8 | Audit count | Via dry-run (comptabilise dans exclusions) |
| O9 | UI Client opt-out future | Non prioritaire (lien email suffit pour MVP) |
| O10 | Reactivation opt-in | Non prevu (irreversible sauf intervention DB manuelle) |

### Validation actuelle

- `buildUnsubscribeUrl()` : implementee, HMAC-SHA256, secret = `JWT_SECRET`
- `verifyUnsubscribeToken()` : implementee, timing-safe compare
- `processUnsubscribe()` : implementee, upsert `tenant_settings`
- Page HTML : implementee (`UNSUBSCRIBE_HTML`, `ALREADY_HTML`, `ERROR_HTML`)
- Headers RFC 8058 : implementes dans `executeLifecycleTick`
- Testee en PROD (Y.9B) : endpoint repond, token invalide rejete

---

## ETAPE 8 - CONTROLE DES TENANTS TEST / INTERNAL

### Audit des exclusions actuelles

| Source exclusion | Mecanisme | Count exclu | Suffisant ? | Gap |
|---|---|---|---|---|
| `tenant_billing_exempt` (internal_admin) | DB flag | 2 | Oui pour ces 2 | - |
| `tenant_billing_exempt` (test_account) | DB flag | 20 | Oui pour les 20 existants | Nouveaux tests non auto-exemptes |
| Domaine interne (@keybuzz.io, @keybuzz.pro, etc.) | **Non implemente** | ~8 seraient exclus | **Non** | **GAP CRITIQUE** |
| Pattern tenant ID (test-, internal-, proof-) | **Non implemente** | ~6 seraient exclus | **Non** | **Recommande** |
| Baseline date (created_at < activation) | **Non implemente** | 23 (tous) | **Non** | **GAP CRITIQUE** |
| Tenant status != active | **Non implemente** | A verifier | **Non** | **Recommande** |

### Tenants eligibles actuels (masques)

| Tenant (masque) | Plan | Jour trial | Domaine | Interne ? | Risque |
|---|---|---|---|---|---|
| ludovic-mojo... | PRO | J3 | keybuzz.pro | Oui | Serait bloque par E7 |
| internal-val... | PRO | J3 | keybuzz.pro | Oui | Serait bloque par E7+E10 |

### Recommandation

Avant toute activation :
1. **E7 (domaine blocklist)** : OBLIGATOIRE
2. **E8 (baseline date)** : OBLIGATOIRE
3. **E10 (pattern tenant ID)** : RECOMMANDE (filet de securite)
4. **E9 (tenant status)** : RECOMMANDE

Avec E7+E8 implementes, les 2 tenants eligibles actuels seraient exclus, et seuls les futurs vrais clients (post-baseline, domaine externe) recevraient des emails.

---

## ETAPE 9 - RISQUES ET GAPS CODE

### Modifications necessaires avant activation

| # | Gap | Severite | Phase | Fichier(s) | Patch description |
|---|---|---|---|---|---|
| G1 | Pas de filtre domaine interne | **CRITIQUE** | Y.9D | `trial-lifecycle.service.ts` | Ajouter `INTERNAL_DOMAINS_BLOCKLIST`, filtrer dans `computeLifecycleCandidates()` |
| G2 | Pas de baseline date | **CRITIQUE** | Y.9D | `trial-lifecycle.service.ts` | Ajouter `ACTIVATION_BASELINE_DATE` en constante, `WHERE created_at >= $BASELINE` |
| G3 | Pas de `maxEmailsPerRun` | **ELEVE** | Y.9D | `trial-lifecycle.service.ts` | Ajouter cap sur `eligible.length` apres filtrage |
| G4 | Pas de mode pilot/allowlist/public | MOYEN | Y.9D | `trial-lifecycle.routes.ts` | Enum mode dans le body, guards differents par mode |
| G5 | Logs PII pas systematiquement masques | MOYEN | Y.9D | `trial-lifecycle.service.ts` | Masquer emails dans les logs de resultat |
| G6 | Pas de tenant status check | FAIBLE | Y.9E | `trial-lifecycle.service.ts` | Ajouter `AND t.status = 'active'` dans la query |
| G7 | Pas de pattern test/internal tenant ID | FAIBLE | Y.9E | `trial-lifecycle.service.ts` | Regex exclusion sur `tenant_id` (test-, internal-, proof-) |
| G8 | Pas de metrics endpoint | FAIBLE | Y.9F | Nouveau fichier ou ajout dans routes | Endpoint `/internal/lifecycle/metrics` |
| G9 | Pas de daily send counter | MOYEN | Y.9E | `trial-lifecycle.service.ts` | Query `trial_lifecycle_emails_sent WHERE created_at >= today` avant envoi |
| G10 | Pas de stop condition automatique | MOYEN | Y.9E | `trial-lifecycle.service.ts` | Check error rate mid-batch, abort si seuil |

### Matrice priorisation

```
Y.9D (pilot) - PRE-REQUIS :
  G1 (domaine blocklist)    — CRITIQUE
  G2 (baseline date)        — CRITIQUE
  G3 (maxEmailsPerRun)      — ELEVE
  G4 (mode pilot)           — MOYEN
  G5 (PII masking)          — MOYEN

Y.9E (CronJob pilot) :
  G6 (tenant status)        — FAIBLE
  G7 (pattern ID)           — FAIBLE
  G9 (daily counter)        — MOYEN
  G10 (stop conditions)     — MOYEN

Y.9F+ (gradual) :
  G8 (metrics endpoint)     — FAIBLE
```

---

## ETAPE 10 - PLAN D'ACTIVATION PROGRESSIVE

### Vue d'ensemble

```
Y.9A  CronJob dry-run PROD         [FAIT]
Y.9B  Envoi controle allowlist       [FAIT]
Y.9C  Design activation (ce doc)    [FAIT]
Y.9D  Pilot send PROD               [A FAIRE]
Y.9E  CronJob pilot real-send       [A FAIRE]
Y.9F  Activation publique graduelle [A FAIRE]
Y.9G  Full activation               [A FAIRE]
```

### Y.9D - Pilot send PROD

| Aspect | Detail |
|---|---|
| Objectif | Premier envoi reel a un vrai client externe (pas Ludovic) |
| Pre-requis code | G1 (domaine blocklist), G2 (baseline date), G3 (maxEmailsPerRun) |
| Mode | `controlledSend` ou nouveau `pilotSend` |
| Template | `trial-welcome` uniquement |
| Volume | 1-3 emails maximum |
| Eligibilite | Tenant cree apres baseline, domaine externe, non exempt, non paid |
| CronJob | Reste dry-run |
| Validation | Inbox QA, logs review, idempotence check |
| Conditions GO | Pre-requis code deployes, au moins 1 signup externe reel |

### Y.9E - CronJob pilot real-send

| Aspect | Detail |
|---|---|
| Objectif | CronJob reel mais tres limite |
| Pre-requis code | G6, G7, G9, G10 |
| CronJob | Nouveau `trial-lifecycle-pilot` (distinct du dryrun) |
| `maxEmailsPerRun` | 5 |
| `maxEmailsPerDay` | 10 |
| Templates | `trial-welcome` + `trial-day-2` |
| Monitoring | 48h minimum avant GO Y.9F |
| Conditions GO | Y.9D valide, 0 complaint, 0 bounce, unsubscribe < 30% |

### Y.9F - Activation publique graduelle

| Aspect | Detail |
|---|---|
| Objectif | Tous les templates informatifs actifs |
| CronJob | `trial-lifecycle-pilot` renomme `trial-lifecycle` |
| `maxEmailsPerRun` | 25 |
| `maxEmailsPerDay` | 50 |
| Templates | trial-welcome, day-2, day-5, day-10 |
| Monitoring | 7 jours minimum avant GO Y.9G |
| Conditions GO | Y.9E stable 7j, 0 complaint, bounce < 5%, unsubscribe < 20% |

### Y.9G - Full activation

| Aspect | Detail |
|---|---|
| Objectif | Tous les templates actifs y compris conversion |
| CronJob | `trial-lifecycle` (production) |
| `maxEmailsPerRun` | 50 |
| `maxEmailsPerDay` | 200 |
| Templates | Tous (welcome, day-2, day-5, day-10, day-13, ended, grace) |
| Stop conditions | Automatiques (S1-S10) |
| Conditions GO | Y.9F stable 14j, observabilite OK, metriques endpoint |

### Tableau recapitulatif

| Phase | Portee | Max volume/run | Max volume/jour | Templates | Conditions GO |
|---|---|---|---|---|---|
| Y.9D | Pilot manuel | 3 | 5 | trial-welcome | G1+G2+G3 deployes, signup externe |
| Y.9E | CronJob pilot | 5 | 10 | welcome + day-2 | Y.9D valide, 48h stable |
| Y.9F | Public graduel | 25 | 50 | welcome a day-10 | Y.9E stable 7j, 0 complaint |
| Y.9G | Full | 50 | 200 | Tous | Y.9F stable 14j, metriques OK |

---

## ETAPE 11 - LINEAR / TICKETS

Acces Linear non disponible. Tickets recommandes a creer :

### Ticket 1 : Lifecycle Progressive Activation Gates (Y.9D)

```
Titre : [Lifecycle] Implementer gates d'activation progressive (Y.9D)
Priorite : P1
Labels : lifecycle, email, security

Description :
Implementer les pre-requis pour le premier pilot send lifecycle PROD :
- [ ] G1 : INTERNAL_DOMAINS_BLOCKLIST dans trial-lifecycle.service.ts
- [ ] G2 : ACTIVATION_BASELINE_DATE dans trial-lifecycle.service.ts
- [ ] G3 : maxEmailsPerRun cap parametre
- [ ] G4 : mode pilot dans routes (optionnel pour Y.9D)
- [ ] G5 : masquage PII dans logs send

Ref : PH-SAAS-T8.12Y.9C rapport design
```

### Ticket 2 : Lifecycle Observability

```
Titre : [Lifecycle] Ameliorer observabilite et logs PII-safe
Priorite : P2
Labels : lifecycle, observability

Description :
- [ ] Run ID unique par execution
- [ ] Compteurs provider accepted/failed
- [ ] Idempotence skipped count
- [ ] Daily send counter (G9)
- [ ] Stop conditions automatiques (G10)
- [ ] Endpoint /internal/lifecycle/metrics (G8)

Ref : PH-SAAS-T8.12Y.9C etape 6
```

### Ticket 3 : Lifecycle Opt-out UI Future

```
Titre : [Lifecycle] Page opt-out dans Settings Client (future)
Priorite : P3
Labels : lifecycle, client, UX

Description :
Ajouter une option dans Settings > Notifications pour permettre
a l'owner de desactiver les emails lifecycle trial.
Non prioritaire : le lien email fonctionne.

Ref : PH-SAAS-T8.12Y.9C etape 7
```

### Ticket 4 : Lifecycle Admin Reporting

```
Titre : [Admin] Dashboard lifecycle emails dans Admin
Priorite : P3
Labels : lifecycle, admin, reporting

Description :
Dashboard dans keybuzz-admin pour voir :
- Nombre d'emails envoyes par template/jour
- Taux unsubscribe
- Taux erreur
- Tenants actifs lifecycle

Ref : PH-SAAS-T8.12Y.9C etape 6
```

---

## PREUVES DE CONFORMITE

### Zero email envoye

- Aucun appel POST avec `dryRun:false` effectue
- Table `trial_lifecycle_emails_sent` : 1 row (inchangee depuis Y.9B)
- Aucun script d'envoi execute

### Zero build/deploy

- Aucun `docker build` execute
- Aucun `kubectl set image` execute
- Aucun `kubectl apply` execute (sauf lecture)
- API PROD inchangee : v3.5.134-trial-lifecycle-controlled-send-prod
- CronJob inchangee : trial-lifecycle-dryrun

### Zero mutation DB

- Aucun INSERT/UPDATE/DELETE execute
- Lectures SELECT uniquement (audit candidats)

---

## VERDICT

**GO**

LIFECYCLE PROGRESSIVE ACTIVATION DESIGN READY - ELIGIBILITY GATES DEFINED - VOLUME CAPS DEFINED - STOP CONDITIONS DEFINED - OBSERVABILITY DEFINED - ZERO EMAIL SENT - CRONJOB STILL DRY-RUN - READY FOR PILOT SEND PHASE

### Prochaines etapes

1. **Y.9D** : Implementer G1 (domaine blocklist) + G2 (baseline date) + G3 (maxEmailsPerRun), deployer, pilot send 1-3 emails a de vrais clients externes
2. **Y.9E** : CronJob pilot real-send (cap 5/run, trial-welcome + day-2)
3. **Y.9F** : Activation publique graduelle (4 templates, cap 25/run)
4. **Y.9G** : Full activation (7 templates, cap 50/run)

### Blocage actuel

**Aucun client externe reel** n'est inscrit en trial PROD. L'activation Y.9D est conditionnee au premier signup externe reel.

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12Y.9C-LIFECYCLE-PROGRESSIVE-ACTIVATION-DESIGN-AND-SAFETY-GATES-01.md
```
