# PH-SAAS-T8.12Y.7.2 — Lifecycle Email QA Closure DEV

**Date** : 2026-05-02
**Type** : Clôture QA visuelle Ludovic, documentation uniquement
**Environnement** : DEV (aucune action code/build/deploy)
**Priorité** : P1

---

## Objectif

Documenter la validation finale Ludovic des emails lifecycle DEV après hotfix Y.7.1.
Aucun code, build, déploiement ou envoi d'email dans cette phase.

---

## Preflight

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-infra | `main` | `main` | `2c0e848` (Y.7.1 rapport) | Fichiers non liés (autres phases) | **OK** |
| keybuzz-api | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `2b0b2adc` (Y.7.1) | Lecture seule | **OK** |

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API DEV | `v3.5.138-lifecycle-visible-unsubscribe-copy-dev` | Identique | **OK** |
| API PROD | `v3.5.131-transactional-email-design-prod` | Identique | **OK** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Identique | **OK** |

---

## Validation QA Ludovic

Ludovic a vérifié les 2 emails lifecycle envoyés par Y.7.1 dans son inbox Gmail.

| Check Ludovic | Résultat |
|---|---|
| Emails reçus en inbox, pas spam | **OK** |
| Accents / apostrophes / caractères spéciaux lisibles | **OK** |
| Rendu mobile | **OK** |
| Lien unsubscribe visible dans le corps de l'email | **OK** |
| Tirets classiques (plus de `—`) | **OK** |
| Rendu global validé | **OK** |

---

## Audit rapport Y.7.1

| Point requis | Présent dans Y.7.1 | Correction appliquée |
|---|---|---|
| 2 emails envoyés | Oui | - |
| Destinataire `ludo.gonthier@gmail.com` | Oui | - |
| Lien unsubscribe visible HTML/text | Oui | - |
| `—` / `&mdash;` absents | Oui | - |
| Text/plain sans entités HTML | Oui | - |
| Aucun CronJob | Oui | - |
| Aucun email PROD | Oui | - |
| Rollback GitOps strict | **Non** (utilisait `kubectl set image`) | **Corrigé** en procédure GitOps stricte (manifest + commit + push + apply) |

### Correction appliquée au rapport Y.7.1

La section rollback utilisait `kubectl set image` (commande impérative interdite).
Remplacée par une procédure GitOps stricte :
1. Modifier le manifest `deployment.yaml`
2. `git add` + `git commit` + `git push`
3. `kubectl apply -f` + `kubectl rollout status`

---

## Zero forbidden doc patterns

Scan des rapports Y.6, Y.7 et Y.7.1 (après correction) pour patterns interdits.

| Rapport | `kubectl set image` | `kubectl set env` | `kubectl patch` | `kubectl edit` | `git reset --hard` | `git clean` | Verdict |
|---|---|---|---|---|---|---|---|
| Y.7.1 (corrigé) | 0 | 0 | 0 | 0 | 0 | 0 | **OK** |
| Y.7 | 0 | 0 | 0 | 0 | 0 | 0 | **OK** |
| Y.6 | 0 | 0 | 0 | 0 | 0 | 0 | **OK** |

---

## Confirmation : 0 code / build / deploy / email

| Action | Exécutée | Preuve |
|---|---|---|
| Modification de code | **Non** | Aucun fichier `.ts` modifié |
| Build Docker | **Non** | Aucune commande `docker build` |
| Push image | **Non** | Aucune commande `docker push` |
| `kubectl apply` | **Non** | Aucune commande kubectl exécutée |
| Envoi d'email | **Non** | Aucun appel API lifecycle/tick |
| Mutation DB | **Non** | Aucune requête INSERT/UPDATE/DELETE |
| Modification PROD | **Non** | Runtimes PROD vérifiés identiques |

---

## Baselines inchangées

| Service | Image avant Y.7.2 | Image après Y.7.2 | Verdict |
|---|---|---|---|
| API DEV | `v3.5.138-lifecycle-visible-unsubscribe-copy-dev` | Identique | **Inchangée** |
| API PROD | `v3.5.131-transactional-email-design-prod` | Identique | **Inchangée** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Identique | **Inchangée** |

---

## Readiness Y.8 — Promotion PROD fondation lifecycle

### Ce qui est prêt pour PROD

1. **Email design system** : tirets classiques, accents UTF-8, logo 80x80, responsive
2. **Templates lifecycle** : 7 templates (J0 → J16) avec copy validé
3. **Unsubscribe visible** : lien HTML + text/plain injecté par le service lifecycle
4. **Unsubscribe header** : `List-Unsubscribe` + `List-Unsubscribe-Post` (RFC 8058)
5. **Unsubscribe endpoint** : HMAC-SHA256 signé, page HTML de confirmation, idempotent
6. **Idempotence** : table `trial_lifecycle_emails_sent` avec contrainte UNIQUE
7. **Opt-out** : colonne `lifecycle_email_optout` dans `tenant_settings`
8. **Text/plain** : entity cleanup automatique dans `buildEmailText()`
9. **DEV-only guards** : `NODE_ENV` check, `recipientOverride` allowlist, pas de CronJob

### Ce qui doit être fait en Y.8

1. **Build PROD** de l'API avec le code lifecycle (même codebase que DEV v3.5.138)
2. **Migration DB PROD** : créer `trial_lifecycle_emails_sent` + ajouter `lifecycle_email_optout`
3. **GitOps PROD** : mettre à jour le manifest API PROD
4. **Vérifier** que les routes `/internal/trial-lifecycle/*` retournent 404 en PROD (`NODE_ENV=production`)
5. **Vérifier** que l'endpoint `/lifecycle/unsubscribe` fonctionne en PROD

### Ce qui est HORS SCOPE Y.8

- CronJob d'envoi automatique (phase Y.9+)
- Envoi d'emails lifecycle en PROD
- Modification des templates
- Modification du Client/Admin/Website

---

## Prochaine phase recommandée

- **PH-SAAS-T8.12Y.8** : Promotion PROD de la fondation lifecycle/unsubscribe (build + migrate + GitOps), **sans CronJob d'envoi**
- **PH-SAAS-T8.12Y.9** : Activation CronJob lifecycle DEV (envoi automatique quotidien, dry-run d'abord)
- **PH-SAAS-T8.12Y.10** : Activation CronJob lifecycle PROD (envoi réel aux nouveaux trials)
