# PH-SAAS-T8.12Y.6 — Trial Lifecycle Unsubscribe & Controlled Send DEV

> **Date** : 2 mai 2026
> **Auteur** : Agent Cursor
> **Verdict** : GO PARTIEL — UNSUBSCRIBE AND DRY-RUN VALIDATED — CONTROLLED SEND DEFERRED — NO AUTOMATIC EMAILS — PROD UNCHANGED

---

## 1. Preflight

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | `a88715eb` (Y.5) | Clean | OK |
| keybuzz-infra | main | main | `65a04b0` (Y.5 rapport) | Clean | OK |

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API DEV | v3.5.135-trial-lifecycle-foundation-dev | Identique | OK |
| API PROD | v3.5.131-transactional-email-design-prod | Identique | OK |
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | Identique | OK |

---

## 2. Audit Y.5

| Brique | Attendu | Résultat |
|---|---|---|
| Table idempotence | Présente DEV | Oui (1 table) |
| Opt-out column | Présent DEV | Oui (lifecycle_email_optout) |
| dryRun default | true | Oui |
| force required | true pour envoi | Oui |
| List-Unsubscribe | Préparé | 2 refs (header + Post) |
| Endpoint unsubscribe | Absent | GAP confirmé — à créer |
| PROD endpoint | 404 | 404 |
| CronJob lifecycle | Absent | NONE |

---

## 3. Endpoint Unsubscribe — Design

### Token Strategy : HMAC-SHA256

| Point | Attendu | Décision |
|---|---|---|
| Token signé | Oui | HMAC-SHA256 avec COOKIE_SECRET |
| Scope lifecycle only | Oui | Met lifecycle_email_optout=true uniquement |
| Transactionnels préservés | Oui | OTP, billing, invite, security non affectés |
| Réponse HTML | Oui | Page HTML propre et responsive |
| Secret-free | Oui | Secret en env, jamais exposé |
| Timing-safe | Oui | crypto.timingSafeEqual |

### Architecture

```
Token = base64url(JSON{t:tenantId, ts:timestamp}).HMAC-SHA256(payload, COOKIE_SECRET)
```

- `generateUnsubscribeToken(tenantId)` → token signé
- `verifyUnsubscribeToken(token)` → { tenantId } | null
- `buildUnsubscribeUrl(tenantId)` → URL complète avec token
- `processUnsubscribe(tenantId)` → set opt-out + idempotent
- Route : `GET /lifecycle/unsubscribe?token=...`
- Réponses HTML : confirmation, déjà-désinscrit, erreur

### Fichier créé

- `src/modules/lifecycle/trial-lifecycle-unsubscribe.ts` (nouveau)

### Fichiers modifiés

- `src/modules/lifecycle/trial-lifecycle.routes.ts` — ajout route unsubscribe + export `lifecycleUnsubscribeRoutes`
- `src/modules/lifecycle/trial-lifecycle.service.ts` — import `buildUnsubscribeUrl`, URL signée
- `src/app.ts` — registration `lifecycleUnsubscribeRoutes` prefix `/lifecycle`

---

## 4. Validation Statique

| Check | Attendu | Résultat |
|---|---|---|
| tsc --noEmit | 0 erreur | 0 |
| No secrets | 0 | 0 |
| Token not plaintext | HMAC-SHA256 | 2 createHmac + 1 timingSafeEqual |
| Transactionnels inchangés | Oui | OK (invite 2, billing 4) |
| Lifecycle no auto-send | Oui | 0 scheduler/timer |
| List-Unsubscribe URL functional | Signed token | 2 refs buildUnsubscribeUrl |
| DEV-only tick guard | Oui | 1 NODE_ENV check |

---

## 5. Build DEV

| Élément | Valeur |
|---|---|
| Source commit | `76cd7d9c` feat(lifecycle): unsubscribe HMAC endpoint + signed List-Unsubscribe URL (PH-SAAS-T8.12Y.6) |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.136-trial-lifecycle-unsubscribe-dev` |
| Digest | `sha256:d2d31561124103ffce1b1f360ca7d34fe7730040e866e5e42e509010470f7501` |
| Rollback | `v3.5.135-trial-lifecycle-foundation-dev` |
| Build method | `docker build --no-cache` depuis source propre sur bastion |

---

## 6. GitOps DEV

| Étape | Résultat |
|---|---|
| Manifest mis à jour | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| Commit infra | `5791df4` gitops(api-dev): deploy v3.5.136-trial-lifecycle-unsubscribe-dev |
| Push | `main → main` |
| kubectl apply | deployment.apps/keybuzz-api configured |
| Rollout status | successfully rolled out |
| Manifest = runtime | ghcr.io/keybuzzio/keybuzz-api:v3.5.136-trial-lifecycle-unsubscribe-dev |
| Health | OK |

### Rollback GitOps strict

```bash
# Modifier deployment.yaml : image -> v3.5.135-trial-lifecycle-foundation-dev
# git add + commit + push
# kubectl apply -f keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml
# kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 7. Runtime Unsubscribe DEV

| Test | Attendu | Résultat |
|---|---|---|
| URL générée | Token HMAC signé | OK (base64url.sig) |
| Unsubscribe first call | HTTP 200 + optout=true | OK |
| Unsubscribe second call | Idempotent "Déjà désinscrit" | OK |
| Invalid token | HTTP 400 "Lien invalide" | OK |
| Transactionnels | Non affectés | OK |
| PROD endpoint | 404 (image ancienne) | OK |

Après test : optout remis à false pour `ecomlg-001`.

---

## 8. Dry-Run Lifecycle DEV

| Test | Attendu | Résultat |
|---|---|---|
| body absent | dryRun=true, 0 sent | OK (45 candidates, 0 sent) |
| dryRun=true | candidats listés, 0 sent | OK |
| dryRun=false sans force | 400 rejeté | OK |
| opt-out tenant | exclu (lifecycle_optout) | OK |
| paid/exempt | exclu (billing_exempt) | 42/45 exclus |

Candidats éligibles (3) :
- `tenant-1772234265142` | `ludovic@ecomlg.fr` | trial-welcome (day 2)
- `tenant-1772234265142` | `ludovic@ecomlg.fr` | trial-day-2 (day 2)
- `test-lambda-k1-sas-molcr3ha` | `switaa26+trialk1@gmail.com` | trial-welcome (day 1)

---

## 9. Envoi Contrôlé — DIFFÉRÉ

### Raison

Tous les tenants propriétés de `ludo.gonthier@gmail.com` en mode trial ont une `billing_subscriptions` avec `status = 'active'`, ce qui les exclut automatiquement via le filtre `already_paid` du lifecycle service.

| Tenant Ludovic | billing_sub status | Résultat |
|---|---|---|
| test-conversion-t5-5-mo32vwbp | active | Exclu (already_paid) |
| test-ga4-mp-t5-6-mo3gq3kg | active | Exclu (already_paid) |
| test-ph-t5-6-1-sas-mo3hnap2 | active | Exclu (already_paid) |
| test-e2e-ph563-mo3wa85t | active | Exclu (already_paid) |

Modifier le status billing_subscriptions constituerait une mutation billing interdite par le scope.

Les tenants `+address` (`tiktok-test-e2e`, `tiktok-fix-test`) ont `status=trialing` mais l'adresse exacte `ludo.gonthier@gmail.com` n'est pas garantie.

**Verdict envoi : DIFFÉRÉ** conformément à la règle "Si le destinataire ne peut pas être garanti à ludo.gonthier@gmail.com, ne pas envoyer."

---

## 10. Validation Post-Envoi — N/A

Pas d'envoi effectué. Table `trial_lifecycle_emails_sent` : 0 rows.

---

## 11. Non-Régression

| Surface | Attendu | Résultat |
|---|---|---|
| API DEV health | OK | OK |
| API PROD | v3.5.131 inchangée | OK |
| Client PROD | v3.5.147 inchangée | OK |
| Website PROD | v0.6.8 inchangée | OK |
| Billing DB | Aucune mutation | 0 events, 0 subs modifiées |
| CronJobs lifecycle | Absent | NONE |
| Lifecycle automatic send | Absent | Absent |
| PROD internal endpoint | 404 | 404 |
| trial_lifecycle_emails_sent | 0 | 0 |

---

## 12. Confirmations Explicites

- **Endpoint unsubscribe fonctionnel** : Oui (HMAC-SHA256, idempotent, HTML propre)
- **dryRun par défaut** : Oui (true)
- **Aucun CronJob lifecycle** : Confirmé
- **Aucun email PROD** : Confirmé
- **Nombre d'emails DEV envoyés** : 0 (différé)
- **PROD inchangée** : Confirmé (v3.5.131)
- **Table idempotence** : 0 rows (clean)
- **Opt-out mécanisme** : Validé fonctionnel
- **List-Unsubscribe** : Pointe vers endpoint fonctionnel avec token signé

---

## 13. Gaps et Recommandations

### Gap envoi contrôlé
Pour tester l'envoi réel dans une phase future :
1. Créer un tenant frais DEV avec `ludo.gonthier@gmail.com` comme owner, sans billing_subscription active
2. Ou ajouter un paramètre `recipientOverride` au tick endpoint (DEV-only, limité à l'adresse autorisée)

### Phase suivante recommandée
**PH-SAAS-T8.12Y.7** — Controlled lifecycle email send + PROD unsubscribe deployment :
1. Créer un tenant test clean pour envoi contrôlé
2. Valider réception email + List-Unsubscribe fonctionnel E2E
3. Promouvoir l'endpoint unsubscribe en PROD (sécurisé, HMAC)
4. Valider non-régression PROD complète

---

## 14. Artefacts

| Type | Valeur |
|---|---|
| Rapport | `keybuzz-infra/docs/PH-SAAS-T8.12Y.6-TRIAL-LIFECYCLE-UNSUBSCRIBE-AND-CONTROLLED-SEND-DEV-01.md` |
| Tag DEV | `v3.5.136-trial-lifecycle-unsubscribe-dev` |
| Digest | `sha256:d2d31561124103ffce1b1f360ca7d34fe7730040e866e5e42e509010470f7501` |
| Commit API | `76cd7d9c` |
| Commit infra | `5791df4` |
