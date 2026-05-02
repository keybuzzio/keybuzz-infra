# PH-SAAS-T8.12Y.4 — Transactional Email Design PROD Promotion

> Date : 2026-05-02
> Environnement : PROD
> Type : Promotion PROD design system email transactionnel
> Priorité : P1

---

## 1. OBJECTIF

Promouvoir en PROD le design system email validé en DEV pour les emails transactionnels API :
- Invitation espace migrée vers design system
- Billing welcome migré vers design system
- Billing trial ending migré vers design system
- Billing payment failed migré vers design system
- Subjects UTF-8 corrigés (0 entité HTML)
- Logo 80x80
- Copy polishing validé par Ludovic
- Preview endpoint présent dans le code mais DEV-only (inaccessible en PROD)

**Exclusions** : lifecycle trial automation, CronJob lifecycle, table lifecycle, OTP Client, outbound agent replies, contact form, tout changement billing/Stripe/Client/Admin/Website.

---

## 2. PREFLIGHT

### Repos

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `b1390a1a` | Clean | **OK** |
| `keybuzz-infra` | `main` | `main` | `97649ae` | Clean | **OK** |

### Runtimes avant déploiement

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API DEV | `v3.5.134-email-subject-encoding-hotfix-dev` | Identique | **OK** |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | Identique | **OK** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Identique | **OK** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | Identique | **OK** |

---

## 3. SOURCE VERIFICATION

| Brique | Attendu | Résultat |
|---|---|---|
| `emailTemplates.ts` | Présent | **PRESENT** |
| `email-preview.ts` | Présent | **PRESENT** |
| `app.ts` preview registered | Présent | **2 refs** (import + register) |
| Preview DEV-only | `NODE_ENV === 'production'` bloque | **Confirmé** (`return` immédiat) |
| Invitation migrée | Oui | **2 refs** `inviteEmailTemplate` |
| Billing 3 emails migrés | Oui | **4 refs** `billingEmailTemplate` |
| Logo 80x80 | Oui | **1 ref** `width="80"` |
| Subjects UTF-8 | 0 entité HTML | **0** |
| Body HTML escape | Préservé | **26 occurrences** `&#39;` |

---

## 4. VALIDATION PROD-SAFETY

| Check | Attendu | Résultat |
|---|---|---|
| `tsc --noEmit` | 0 erreur | **0** |
| Secrets scan | 0 | **0** (faux positif `tokens` dans commentaire `// Design tokens`) |
| Tracking pixel | 0 | **0** |
| Lifecycle scheduler | Aucun actif | **0** |
| DB migration | Aucune | **0** |
| Billing/Stripe logic | Inchangé | **Oui** (dernière modif billing = Y.2, template wrapper) |
| Preview route PROD | Désactivé | **1 guard** confirmé |

---

## 5. BUILD PROD

| Élément | Valeur |
|---|---|
| Source commit API | `b1390a1a` — fix(email): subject encoding hotfix (PH-SAAS-T8.12Y.3.2) |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.131-transactional-email-design-prod` |
| Digest | `sha256:8c71809ae9ea7ebed31d44dd9b3e9ce4f0a4662e4d93bd53e3355b6c8c6622aa` |
| Build method | Clone propre (--depth 1) + `docker build --no-cache` |
| tsc build | Succès (0 erreur) |
| Rollback | `v3.5.130-platform-aware-refund-strategy-prod` |

Chaîne de commits email design system inclus dans le build :
1. `b9b03122` — feat(email): add email design system + preview endpoint (PH-SAAS-T8.12Y)
2. `956da28d` — feat(email): register preview endpoint + migrate invite (PH-SAAS-T8.12Y.1)
3. `1a87a1c7` — feat(email): migrate billing emails to design system (PH-SAAS-T8.12Y.2)
4. `fbaaf121` — feat(email): polish copy accents logo (PH-SAAS-T8.12Y.3.1)
5. `b1390a1a` — fix(email): subject encoding hotfix (PH-SAAS-T8.12Y.3.2)

---

## 6. GITOPS PROD

| Étape | Résultat |
|---|---|
| Manifest modifié | `k8s/keybuzz-api-prod/deployment.yaml` |
| Commit infra | `488120b` — gitops(api-prod): deploy v3.5.131-transactional-email-design-prod |
| Push | `main -> main` OK |
| `kubectl apply -f` | `deployment.apps/keybuzz-api configured` |
| `kubectl rollout status` | `deployment "keybuzz-api" successfully rolled out` |
| Manifest = runtime | **Oui** |

### Rollback GitOps strict

```bash
# 1. Modifier deployment.yaml -> v3.5.130-platform-aware-refund-strategy-prod
# 2. git commit + push
# 3. kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
# 4. kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

---

## 7. VALIDATION RUNTIME PROD

| Test | Attendu | Résultat |
|---|---|---|
| API health | OK | **`{"status":"ok"}`** |
| Preview endpoint PROD | 404/disabled | **404** (route non enregistrée, logs: `Route GET:/debug/email/preview not found`) |
| Billing routes | Répondent | **HTTP 400** (normal, pas de tenantId) |
| Invite route | Répond | **HTTP 401** (normal, pas d'auth) |
| Logs API | 0 erreur nouvelle | **0** |
| Pod restarts | 0 | **0** |
| Manifest = runtime | Oui | **Oui** (`v3.5.131-transactional-email-design-prod`) |

---

## 8. NON-RÉGRESSION

| Surface | Attendu | Résultat |
|---|---|---|
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | **Identique** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | **Identique** |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | **Identique** |
| Billing DB | Aucune mutation | **Dernière entrée 2026-04-29** (avant déploiement) |
| Stripe | Aucune mutation | **Confirmé** |
| CAPI | Aucun event | **Non affecté** |
| Tracking | Aucun event | **Non affecté** |
| CronJobs PROD | Inchangés | **2** (`outbound-tick-processor`, `sla-evaluator`) |
| Lifecycle emails | Non automatisés | **Aucun CronJob lifecycle** |

---

## 9. CONFIRMATIONS EXPLICITES

- **Rapport complet** : `keybuzz-infra/docs/PH-SAAS-T8.12Y.4-TRANSACTIONAL-EMAIL-DESIGN-PROD-PROMOTION-01.md`
- **Tag PROD** : `v3.5.131-transactional-email-design-prod`
- **Digest** : `sha256:8c71809ae9ea7ebed31d44dd9b3e9ce4f0a4662e4d93bd53e3355b6c8c6622aa`
- **Commit API** : `b1390a1a` (branche `ph147.4/source-of-truth`)
- **Commit infra** : `488120b` (branche `main`)
- **Preview PROD désactivé** : Confirmé (404, guard `NODE_ENV === 'production'`)
- **Lifecycle non automatisé** : Aucun CronJob lifecycle, aucun scheduler
- **Aucun email PROD envoyé** : Aucun email envoyé pendant cette promotion
- **Aucun changement billing/Stripe/DB** : Confirmé

---

## 10. GAPS RESTANTS

| # | Description | Impact |
|---|---|---|
| G1 | Trial lifecycle emails non automatisés (emails J0-J14 présents dans le code mais aucun CronJob ne les déclenche) | Les emails trial ne sont pas envoyés automatiquement |
| G2 | OTP Client utilise toujours son propre template (pas le design system) | Incohérence visuelle OTP vs transactionnels |
| G3 | Contact form interne utilise un template basique | Pas d'impact utilisateur |
| G4 | Outbound agent replies utilisent le format existant | Pas d'impact (canal différent) |

---

## VERDICT

**TRANSACTIONAL EMAIL DESIGN LIVE IN PROD — INVITE/BILLING EMAILS USE UNIFIED DESIGN SYSTEM — SUBJECT UTF8 CLEAN — PREVIEW DEV-ONLY DISABLED IN PROD — LIFECYCLE EMAILS NOT AUTOMATED — NO TRACKING/BILLING/CAPI DRIFT — GITOPS STRICT**
