# PH-SAAS-T8.12Y.3.2 — Email Subject Encoding Hotfix DEV

> **Phase** : PH-SAAS-T8.12Y.3.2-EMAIL-SUBJECT-ENCODING-HOTFIX-DEV-01
> **Date** : 2026-05-02
> **Environnement** : DEV uniquement
> **Type** : hotfix subject encoding email
> **Priorité** : P1

---

## 1. Objectif

Corriger l'encodage des sujets email qui contenaient des entités HTML (`&#39;`) au lieu de caractères UTF-8 réels.

**Symptôme observé dans Gmail** :
```
[DEV TEST Y3.1] Invitation KeyBuzz — Rejoindre l&#39;espace eComLG
```

**Attendu** :
```
[DEV TEST Y3.2] Invitation KeyBuzz — Rejoindre l'espace eComLG
```

**Cause racine** : le patch Y.3.1 a remplacé globalement les apostrophes françaises par `&#39;` (entité HTML), correct pour le body HTML mais incorrect pour les champs `subject:` qui sont transmis comme texte brut dans les headers SMTP/email.

---

## 2. Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| `keybuzz-api` | `ph147.4/source-of-truth` | `fbaaf121` | Clean (`src/`) | **OK** |
| `keybuzz-infra` | `main` | `10dabef` | Clean (`k8s/`) | **OK** |

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API DEV | `v3.5.133-email-copy-logo-polish-dev` | Identique | **OK** |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | Identique | **OK** |

---

## 3. Audit subjects

Scan de tous les champs `subject:` dans `emailTemplates.ts` et des call sites (`space-invites-routes.ts`, `billing/routes.ts`).

| Template | Subject | Entité trouvée | Correction |
|---|---|---|---|
| `inviteEmailTemplate` | `` `Invitation KeyBuzz — Rejoindre l&#39;espace ${tenantName}` `` | `&#39;` | `l'espace` (UTF-8) |
| `trialDay10Template` | `` `KeyBuzz — Plus que ${remaining} jours d&#39;essai` `` | `&#39;` | `d'essai` (UTF-8) |
| `otpEmailTemplate` | `'Votre code de connexion KeyBuzz'` | Aucune | — |
| `trialWelcomeTemplate` | `'Bienvenue sur KeyBuzz — ...'` | Aucune | — |
| `trialDay2Template` | `'KeyBuzz — Découvrez ...'` | Aucune | — |
| `trialDay5Template` | `'KeyBuzz — Ce que nous ...'` | Aucune | — |
| `trialDay13Template` | `'KeyBuzz — Votre essai ...'` | Aucune | — |
| `trialEndedTemplate` | `'KeyBuzz — Votre essai est terminé'` | Aucune | — |
| `trialGraceTemplate` | `'KeyBuzz — Vos messages ...'` | Aucune | — |
| billing (routes.ts) | Sujets avec emoji Unicode | Aucune entité | — |

**Total** : 2 subjects affectés, les deux utilisant des backtick template literals (où `'` est safe sans échappement).

---

## 4. Patch

### Fichier modifié

`keybuzz-api/src/services/emailTemplates.ts` — 2 lignes

### Changements

| Ligne | Avant | Après |
|---|---|---|
| 266 | `l&#39;espace ${tenantName}` | `l'espace ${tenantName}` |
| 452 | `jours d&#39;essai` | `jours d'essai` |

### Fichiers NON modifiés

- `billing/routes.ts` — inchangé
- `space-invites-routes.ts` — inchangé (passe `emailData.subject` du template)
- `emailService.ts` — inchangé
- `email-preview.ts` — inchangé

---

## 5. Validation statique

| Check | Attendu | Résultat |
|---|---|---|
| `tsc --noEmit` | 0 erreur | **0** |
| Subject entities (`&#` dans subjects) | 0 | **0** |
| HTML body `&#39;` escape | Conservé | **26** occurrences (corps HTML intact) |
| Secrets | 0 | **0** (faux positif `tokens` commentaire) |
| Subject runtime (invite) | `Invitation KeyBuzz — Rejoindre l'espace eComLG` | **Confirmé** |

---

## 6. Build DEV API

| Champ | Valeur |
|---|---|
| Source commit | `b1390a1a` (`ph147.4/source-of-truth`) |
| Tag | `v3.5.134-email-subject-encoding-hotfix-dev` |
| Digest | `sha256:60596c66712f068189173275dab34a895c5533054278767918f51c7f57a069eb` |
| Build source | Clone propre depuis GitHub |
| Rollback | `v3.5.133-email-copy-logo-polish-dev` |

---

## 7. GitOps DEV

| Étape | Résultat |
|---|---|
| Manifest modifié | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| Commit infra | `ecea5c6` |
| Push | `main → main` |
| `kubectl apply` | `deployment.apps/keybuzz-api configured` |
| `kubectl rollout status` | `successfully rolled out` |
| Runtime = manifest | `v3.5.134-email-subject-encoding-hotfix-dev` |

### Rollback GitOps strict

```
1. Modifier deployment.yaml: image → v3.5.133-email-copy-logo-polish-dev
2. git add k8s/keybuzz-api-dev/deployment.yaml
3. git commit -m "rollback(api-dev): revert to v3.5.133-email-copy-logo-polish-dev"
4. git push origin main
5. kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
6. kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 8. Email test envoyé

| Email | Envoyé | Subject dans le header | Message ID | Provider | Verdict |
|---|---|---|---|---|---|
| Invite | **Oui** | `[DEV TEST Y3.2] Invitation KeyBuzz — Rejoindre l'espace eComLG` | `<23f3a477-..@keybuzz.io>` | SMTP DEV | **OK** |

- Subject confirmé en UTF-8 propre dans les logs runtime (`console.log('SUBJECT:', ...)`)
- Aucun trigger Stripe, aucune mutation DB

---

## 9. Non-régression

| Surface | Attendu | Résultat | Verdict |
|---|---|---|---|
| API DEV health | OK | `{"status":"ok"}` | **OK** |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | Inchangée | **OK** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Inchangée | **OK** |
| Billing DB | 0 mutation | 0 events, 0 subscriptions | **OK** |
| Stripe | 0 mutation | — | **OK** |
| CAPI/Tracking | 0 event | — | **OK** |

---

## 10. PROD inchangée

| Service PROD | Image | Changement |
|---|---|---|
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | **Aucun** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | **Aucun** |

---

## 11. Artefacts

### Commits

| Repo | Commit | Message |
|---|---|---|
| `keybuzz-api` | `b1390a1a` | `fix(email): subject encoding hotfix — remove HTML entities from subjects (PH-SAAS-T8.12Y.3.2)` |
| `keybuzz-infra` | `ecea5c6` | `gitops(api-dev): deploy v3.5.134-email-subject-encoding-hotfix-dev (PH-SAAS-T8.12Y.3.2)` |
| `keybuzz-infra` | (ce rapport) | `docs: PH-SAAS-T8.12Y.3.2 email subject encoding hotfix DEV` |

### Image Docker

| Tag | Digest |
|---|---|
| `v3.5.134-email-subject-encoding-hotfix-dev` | `sha256:60596c66712f068189173275dab34a895c5533054278767918f51c7f57a069eb` |
