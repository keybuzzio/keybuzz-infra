# PH152 — POST-PROD STABILITY BASELINE

> Date : 2026-04-16
> Type : Audit documentaire (aucun build, aucun deploy, aucune modification)
> Reference : PH151.2.3-PROD-PROMOTION-API-THEN-CLIENT-01.md

---

## 1. BASELINE OFFICIELLE

### PROD (apres promotion PH151.2.3)


| Service              | Image PROD                                                                        | Status        |
| -------------------- | --------------------------------------------------------------------------------- | ------------- |
| API                  | `ghcr.io/keybuzzio/keybuzz-api:v3.5.55-ph147.4-source-of-truth-prod`              | Running (1/1) |
| Client               | `ghcr.io/keybuzzio/keybuzz-client:v3.5.75-ph151-step4.1-filters-collapse-prod`    | Running (1/1) |
| Backend              | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-ph150-thread-fix-prod`                 | Running (1/1) |
| Outbound Worker      | `ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod`                     | Running (1/1) |
| Amazon Items Worker  | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-amz-tracking-visibility-backfill-prod` | Running (1/1) |
| Amazon Orders Worker | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-amz-tracking-visibility-backfill-prod` | Running (1/1) |
| Backfill Scheduler   | running                                                                           | Running (1/1) |


### DEV


| Service | Image DEV                                                                     | Aligne PROD                       |
| ------- | ----------------------------------------------------------------------------- | --------------------------------- |
| API     | `ghcr.io/keybuzzio/keybuzz-api:v3.5.55-ph147.4-source-of-truth-dev`           | OUI (meme codebase, suffixe seul) |
| Client  | `ghcr.io/keybuzzio/keybuzz-client:v3.5.75-ph151-step4.1-filters-collapse-dev` | OUI (meme codebase, suffixe seul) |
| Backend | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-ph150-thread-fix-prod`             | OUI (image identique)             |


### DEV = PROD aligne

Les images DEV et PROD ont le meme codebase. Seules les variables d'environnement (API URLs, DB) et le suffixe d'image different.

### Health checks


| Service      | Endpoint                            | Resultat                |
| ------------ | ----------------------------------- | ----------------------- |
| API PROD     | `https://api.keybuzz.io/health`     | `{"status":"ok"}`       |
| Backend PROD | `https://backend.keybuzz.io/health` | `{"status":"ok"}`       |
| Client PROD  | `https://client.keybuzz.io`         | 307 → `/login` (normal) |


### CronJobs actifs (PROD)


| CronJob                 | Schedule      | Status              |
| ----------------------- | ------------- | ------------------- |
| outbound-tick-processor | `*/1 * * * *` | Completed (continu) |
| sla-evaluator           | `*/1 * * * *` | Completed (continu) |
| amazon-orders-sync      | `*/5 * * * *` | Completed (continu) |


### Git


| Repo            | Branche                              | Clean |
| --------------- | ------------------------------------ | ----- |
| keybuzz-client  | `ph148/onboarding-activation-replay` | OUI   |
| keybuzz-api     | `ph147.4/source-of-truth`            | OUI   |
| keybuzz-backend | `main`                               | OUI   |


---

## 2. DETTES IMMEDIATES

### D0 — Bloquant production

Aucune dette D0 identifiee. La production est stable.

### D1 — Important mais non bloquant


| #    | Dette                                               | Niveau | Impact                                                                       | Recommandation                                                                                                                              |
| ---- | --------------------------------------------------- | ------ | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| D1-1 | Vault API inaccessible (TLS `wrong version number`) | D1     | Secrets dynamiques inoperants ; services fonctionnent via K8s secrets caches | Diagnostiquer la config TLS de Vault ; le service systemd est `active (running)` depuis 2026-03-03 mais l'API HTTPS retourne une erreur SSL |
| D1-2 | Branches feature non mergees dans `main`            | D1     | Pas d'impact technique (build from HEAD) mais hygiene Git reduite            | Merger `ph148/onboarding-activation-replay` et `ph147.4/source-of-truth` dans `main`                                                        |
| D1-3 | Outbound Worker sur une image ancienne (`v3.5.165`) | D1     | Fonctionne mais diverge du codebase API actuel (`v3.5.55`)                   | Reconstruire le worker depuis le HEAD API actuel lors de la prochaine phase                                                                 |


### D2 — Confort / amelioration


| #    | Dette                                                | Niveau | Impact                                 | Recommandation                                   |
| ---- | ---------------------------------------------------- | ------ | -------------------------------------- | ------------------------------------------------ |
| D2-1 | Amazon Workers sur `v1.0.40` (backend est `v1.0.44`) | D2     | Fonctionnels mais 4 versions de retard | Mettre a jour lors de la prochaine phase backend |
| D2-2 | 5 utilisateurs sans association tenant en DB DEV     | D2     | Pollution DB dev uniquement            | Nettoyage optionnel                              |
| D2-3 | Tenants de test dans ai_wallets                      | D2     | Pollution donnees dev uniquement       | Nettoyage optionnel                              |


### Dettes infra RESOLUES depuis le dernier audit (28 fev 2026)


| Ancienne dette                   | Statut actuel             | Detail                                                                                                        |
| -------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------- |
| db-postgres-02 en `start failed` | **RESOLUE**               | Patroni cluster complet : 1 leader + 2 replicas streaming (lag=0)                                             |
| Redis 0 replicas connectees      | **RESOLUE**               | Redis : 2 replicas connectes (HA restaure)                                                                    |
| k8s-worker-01 cordone            | **RESOLUE**               | Node `Ready`, plus de `SchedulingDisabled`                                                                    |
| LiteLLM en `:main-latest`        | **RESOLUE**               | Image passe a `main-v1.81.14-stable`                                                                          |
| CronJobs en `:latest`            | **RESOLUE**               | Aucun CronJob ne utilise `:latest`                                                                            |
| Vault DOWN (service failed)      | **PARTIELLEMENT RESOLUE** | Service `active (running)` depuis 2026-03-03, mais API HTTPS inaccessible (erreur TLS `wrong version number`) |


---

## 3. ZONES FONCTIONNELLES STABLES


| Domaine                | Statut | Reference                                                               |
| ---------------------- | ------ | ----------------------------------------------------------------------- |
| Guardrails / Autopilot | STABLE | PH147.4 (source of truth), PH143-E (escalation flow)                    |
| Onboarding             | STABLE | PH148 + PH148.1 (activation flow + visual polish)                       |
| Inbox UX               | STABLE | PH151.1-STEP1→STEP4.1 (classifier, bubbles, sidebar, priority, filters) |
| Shopify UI             | STABLE | PH147.6 (entry channels catalog)                                        |
| Dashboard              | STABLE | PH143-G (supervision panel)                                             |
| Settings               | STABLE | PH143-F (signature deep-links)                                          |
| Billing                | STABLE | PH143-B (plans addon)                                                   |
| Channels               | STABLE | PH147.6 (Shopify), Octopia (PH35), Amazon (PH34)                        |
| Agents RBAC            | STABLE | PH143-C + PH143-AGENTS-R2→R5                                            |
| IA Assist              | STABLE | PH143-D                                                                 |
| Escalation             | STABLE | PH143-E.4→E.10                                                          |
| Playbooks backend      | STABLE | PH-PLAYBOOKS-BACKEND-MIGRATION-02 + ALIGNMENT-02B                       |
| Francisation           | STABLE | PH143-FR→FR.3                                                           |
| Tracking               | STABLE | PH143-H                                                                 |
| SLA                    | STABLE | CronJobs actifs, batch fonctionne                                       |
| Outbound email         | STABLE | Worker + tick processor actifs                                          |
| Amazon sync            | STABLE | Orders sync CronJob actif (*/5 min)                                     |


---

## 4. PROCHAINE PHASE RECOMMANDEE

### Option A — PH153 : Validation humaine PROD + smoke tests


| Critere       | Detail                                                                                                                                                                        |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Nom           | PH153-PROD-HUMAN-VALIDATION-SMOKE-TESTS                                                                                                                                       |
| Objectif      | Valider manuellement toutes les pages internes PROD (Inbox, Dashboard, Settings, Billing, Channels, Onboarding) via connexion reelle                                          |
| Perimetre     | Tests navigateur authentifie sur `client.keybuzz.io` — aucune modification code                                                                                               |
| Risque        | Nul (lecture seule)                                                                                                                                                           |
| Justification | La promotion PH151.2.3 n'a pas pu valider les pages internes car elles necessitent une authentification OTP/OAuth. C'est le chainnon manquant pour une confiance PROD totale. |


### Option B — PH154 : Enrichissement Inbox (visu rapide, apercu commande)


| Critere       | Detail                                                                                                                                                                                          |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Nom           | PH154-INBOX-ENRICHMENT-QUICK-VIEW                                                                                                                                                               |
| Objectif      | Ajouter un apercu rapide des informations commande/retour au survol ou clic leger dans la liste des conversations                                                                               |
| Perimetre     | Client uniquement (composants Inbox)                                                                                                                                                            |
| Risque        | Faible (UX additive, pas de refactoring)                                                                                                                                                        |
| Justification | L'Inbox est desormais stable avec PH151. Le prochain pas logique est d'enrichir l'experience utilisateur avec un acces plus rapide aux donnees commande sans ouvrir le panneau lateral complet. |


### Option C — PH-GIT-HYGIENE : Merge branches dans main


| Critere       | Detail                                                                                                                                            |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Nom           | PH-GIT-HYGIENE-MERGE-MAIN                                                                                                                         |
| Objectif      | Merger les branches feature (`ph148/`*, `ph147.4/*`) dans `main` pour aligner Git                                                                 |
| Perimetre     | Git uniquement, aucun build ni deploy                                                                                                             |
| Risque        | Tres faible (meme codebase, pas de conflit attendu)                                                                                               |
| Justification | Les branches feature contiennent tout le code deploye en PROD. Les merger dans `main` assure la coherence Git et simplifie les prochaines phases. |


### Recommandation

**Option C (PH-GIT-HYGIENE)** en priorite (5 min, zero risque), puis **Option A (PH153)** pour la validation humaine, puis **Option B (PH154)** pour l'enrichissement fonctionnel.

---

## 5. VERDICT

### BASELINE STABLE AND NEXT PHASE READY


| Critere                                   | Statut                                         |
| ----------------------------------------- | ---------------------------------------------- |
| PROD stable (tous services Running)       | OK                                             |
| Health checks OK                          | OK                                             |
| CronJobs actifs                           | OK                                             |
| DEV aligne avec PROD                      | OK                                             |
| Aucune dette D0 (bloquante)               | OK                                             |
| Dettes D1 identifiees et documentees      | 3 items non bloquants                          |
| Dettes infra majeures resolues depuis fev | 5 sur 6 resolues                               |
| Zones fonctionnelles stables              | 17 domaines                                    |
| Prochaine phase identifiee                | Git hygiene → validation PROD → enrichissement |


---

*Rapport genere le 2026-04-16 — Audit documentaire uniquement, aucune modification effectuee.*