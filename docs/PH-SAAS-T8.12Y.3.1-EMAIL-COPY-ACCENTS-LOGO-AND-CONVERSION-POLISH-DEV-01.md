# PH-SAAS-T8.12Y.3.1 — Email Copy, Accents, Logo & Conversion Polish DEV

> **Phase** : PH-SAAS-T8.12Y.3.1-EMAIL-COPY-ACCENTS-LOGO-AND-CONVERSION-POLISH-DEV-01
> **Date** : 2026-05-02
> **Environnement** : DEV uniquement
> **Type** : Polish copy/design email + QA inbox contrôlée
> **Priorité** : P1

---

## 1. Objectif

Corriger et améliorer les emails du design system après retour inbox Ludovic (Y.3) :

1. Corriger tous les accents et apostrophes françaises
2. Vérifier l'encodage UTF-8 HTML + text/plain
3. Doubler la taille du logo dans les templates
4. Ajouter une psychologie marketing sobre pour les emails lifecycle trial
5. Aucune promesse mensongère, aucune urgence artificielle
6. Rebuild API DEV + envoi contrôlé
7. PROD inchangée

---

## 2. Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| `keybuzz-api` | `ph147.4/source-of-truth` | `1a87a1c7` | `dist/` seulement | **OK** |
| `keybuzz-infra` | `main` | `e3c17ae` | Docs non-trackés | **OK** |

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API DEV | `v3.5.132-billing-email-design-dev` | Identique | **OK** |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | Identique | **OK** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Identique | **OK** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | Identique | **OK** |

---

## 3. Audit accents/encodage

### Problèmes identifiés

| Problème | Occurrences | Impact | Correction |
|---|---|---|---|
| `&#8217;` (curly apostrophe RIGHT SINGLE QUOTATION MARK) | 21 | Rendu potentiellement incorrect dans certains clients email | Remplacé par `&#39;` (apostrophe standard ASCII) |
| `\u00a0` (Unicode escape non-breaking space) | 8 | Caractère brut U+00A0 émis dans HTML au lieu de l'entité standard | Remplacé par `&nbsp;` |
| Logo `width="40"` | 1 | Trop petit selon retour Ludovic | Doublé à `width="80"` |

### Résultat par template

| Template | HTML accents | Text accents | Correction appliquée |
|---|---|---|---|
| otp | `&#39;` + `&nbsp;` | UTF-8 OK | **Corrigé** |
| invite | `&#39;` | UTF-8 OK | **Corrigé** |
| billing-* | Via wrapper | UTF-8 OK | **Corrigé** (wrapper) |
| trial-j0 à trial-grace | `&#39;` + `&nbsp;` | UTF-8 OK | **Corrigé** |

---

## 4. Logo/design changes

| Élément | Avant | Après |
|---|---|---|
| Logo width | 40px | **80px** |
| Logo height | 40px | **80px** |
| Logo border-radius | 8px | **12px** |
| Header text "KeyBuzz" | 20px | **24px** |
| Header margin-left | 10px | **12px** |
| Mobile rendering | Responsive | **Conservé** (responsive via @media) |
| HTML weight impact | — | +0B (même structure, attributs changés) |

---

## 5. Copywriting marketing sobre

### Principes respectés

- Valeur perçue : le copilote protège temps et marge
- Perte évitée : scénarios concrets (remboursements prématurés, métriques dégradées)
- Effet copilote IA : "elle suggère, vous décidez"
- Invitation douce à connecter le premier canal
- Continuité naturelle essai → plan
- Aucune promesse mensongère
- Aucune urgence artificielle

### Changements par template

| Template | Objectif | Changement | Risque spam |
|---|---|---|---|
| **trial-j0** | Activation immédiate | Ajout infoBlock "Conseil : connectez votre premier canal" + CTA `/channels` | **Aucun** |
| **trial-j2** | Valeur perçue | Ajout paragraphe "temps précieux gagné" | **Aucun** |
| **trial-j5** | Perte évitée | Ajout "La différence ? Un copilote qui analyse avant que vous ne répondiez" | **Aucun** |
| **trial-j10** | Continuité | Ajout "Le copilote vous a accompagné, choisir un plan c'est continuer" | **Aucun** |
| **trial-j13** | Réassurance | Remplacé "volume" par "vos conversations et paramètres sont conservés" | **Aucun** |
| **trial-j14** | Facilité retour | Ajout "Votre compte est prêt — un plan suffit pour reprendre" | **Aucun** |
| **trial-grace** | Besoin persistant | "Vos messages continuent d'arriver + chaque retard affecte vos métriques" | **Aucun** |
| invite | Transactionnel pur | Accents seulement | **Aucun** |
| billing-* | Hors scope copy | Wrapper accents seulement | **Aucun** |

### Formulations interdites vérifiées (0 match)

- "remboursement garanti" : 0
- "résultat garanti" : 0
- "nous envoyons automatiquement" : 0
- "dernière chance" : 0
- "urgence absolue" : 0
- "suppression définitive demain" : 0

---

## 6. Patch minimal

### Fichier modifié

- `keybuzz-api/src/services/emailTemplates.ts` : seul fichier touché

### Fichiers NON modifiés

- `billing/routes.ts` : inchangé
- `space-invites-routes.ts` : inchangé
- `emailService.ts` : inchangé
- Aucun trigger, provider, DB, Stripe modifié

### Détails du patch

1. Logo header : `width="40"` → `width="80"`, `height="40"` → `height="80"`, border-radius 8→12, text 20→24px
2. 21 occurrences `&#8217;` → `&#39;` (apostrophe HTML standard)
3. 8 occurrences `\u00a0` → `&nbsp;` (entité HTML standard)
4. 1 occurrence `\u0153` → `&#339;` (ligature œ en HTML entity)
5. 7 templates trial lifecycle enrichis avec marketing sobre
6. Text/plain versions mises à jour en parallèle

---

## 7. Validation statique

| Check | Attendu | Résultat |
|---|---|---|
| `tsc --noEmit` | 0 erreur | **0** |
| No secret | 0 | **0** (faux positif `tokens` dans commentaire ignoré) |
| No tracking pixel | 0 | **0** |
| Forbidden copy | 0 | **0** |
| HTML/text parity | 12/12 | **12/12** (`buildEmail` = `buildEmailText`) |

---

## 8. Build DEV API

| Champ | Valeur |
|---|---|
| Source commit | `fbaaf121` (`ph147.4/source-of-truth`) |
| Tag | `v3.5.133-email-copy-logo-polish-dev` |
| Digest | `sha256:3e5f056948ce30701232047dcaded6971efd129b58dc230a03fdf5ccd9c7b285` |
| Build source | Clone propre depuis GitHub (pas de workspace dirty) |
| Rollback | `v3.5.132-billing-email-design-dev` |

---

## 9. GitOps DEV

| Étape | Résultat |
|---|---|
| Manifest modifié | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| Commit infra | `e770313` |
| Push | `main → main` |
| `kubectl apply` | `deployment.apps/keybuzz-api configured` |
| `kubectl rollout status` | `successfully rolled out` |
| Runtime = manifest | `v3.5.133-email-copy-logo-polish-dev` ✓ |

### Rollback GitOps strict

```
1. Modifier deployment.yaml: image → v3.5.132-billing-email-design-dev
2. git add k8s/keybuzz-api-dev/deployment.yaml
3. git commit -m "rollback(api-dev): revert to v3.5.132-billing-email-design-dev"
4. git push origin main
5. kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
6. kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 10. Runtime preview DEV

| Template | HTML runtime | Text runtime | Accents | Logo | Verdict |
|---|---|---|---|---|---|
| `invite` | 3.8KB | 542B | `&#39;`=3, `&#8217;`=0 | width=80 | **OK** |
| `billing-welcome` | 3.3KB | 599B | OK | width=80 | **OK** |
| `billing-payment-failed` | 3.3KB | 566B | OK | width=80 | **OK** |
| `trial-j0` | 4.7KB | 821B | `&#39;`=1 | width=80 | **OK** |
| `trial-j5` | 4.4KB | 954B | `&#39;`=1 | width=80 | **OK** |
| `trial-j13` | 4.0KB | 738B | `&#39;`=1 | width=80 | **OK** |
| `trial-grace` | 4.0KB | 714B | `&#39;`=1 | width=80 | **OK** |

12 templates dans l'index preview. 0 secret. 0 `&#8217;` résiduel.

---

## 11. Emails envoyés

4 emails envoyés à `ludo.gonthier@gmail.com` via `kubectl exec` + `sendEmail()` dans le pod API DEV.

| Email | Envoyé | Message ID | Provider | Statut | Verdict |
|---|---|---|---|---|---|
| Invite | **Oui** | `<e9061805-..@keybuzz.io>` | SMTP DEV | Accepté | **OK** |
| Billing welcome | **Oui** | `<4b189a63-..@keybuzz.io>` | SMTP DEV | Accepté | **OK** |
| Billing payment failed | **Oui** | `<48faac86-..@keybuzz.io>` | SMTP DEV | Accepté | **OK** |
| Trial J0 (Ludovic) | **Oui** | `<aa7126c8-..@keybuzz.io>` | SMTP DEV | Accepté | **OK** |

Subjects préfixés `[DEV TEST Y3.1]`. Aucun trigger Stripe. Aucune mutation DB.

---

## 12. Non-régression

| Surface | Attendu | Résultat | Verdict |
|---|---|---|---|
| API DEV health | OK | `{"status":"ok"}` | **OK** |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | Inchangée | **OK** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Inchangée | **OK** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | Inchangée | **OK** |
| Billing DB | Aucune mutation | 0 events, 0 subscriptions | **OK** |
| Stripe | Aucune mutation | — | **OK** |
| CAPI | Aucun event | — | **OK** |
| Tracking | Aucun event | — | **OK** |
| CronJobs DEV | Inchangés | 3 jobs | **OK** |

---

## 13. Gaps

| # | Gap | Impact | Action |
|---|---|---|---|
| G1 | QA inbox/rendu en attente Ludovic | Verdict conditionnel | Ludovic vérifie sa boîte Gmail |
| G2 | OTP et outbound agent replies non migrés | Templates anciens actifs | Phase future |
| G3 | List-Unsubscribe absent | Requis avant activation lifecycle auto | Phase future |
| G4 | SPF/DKIM/DMARC non vérifiés code-side | Infra DNS, hors scope | À vérifier séparément |

---

## 14. PROD inchangée

| Service PROD | Image avant | Image après | Changement |
|---|---|---|---|
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | Identique | **Aucun** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Identique | **Aucun** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | Identique | **Aucun** |

---

## 15. Prochaine phase recommandée

Selon le résultat de la QA Ludovic :

- **Si GO** : `PH-SAAS-T8.12Y.4` — Promotion PROD des emails transactionnels migrés (invite + billing)
- **Si retouche nécessaire** : itération Y.3.2 avant promotion

---

## 16. Artefacts

### Commits

| Repo | Commit | Message |
|---|---|---|
| `keybuzz-api` | `fbaaf121` | `feat(email): polish copy accents logo for design system (PH-SAAS-T8.12Y.3.1)` |
| `keybuzz-infra` | `e770313` | `gitops(api-dev): deploy v3.5.133-email-copy-logo-polish-dev (PH-SAAS-T8.12Y.3.1)` |
| `keybuzz-infra` | (ce rapport) | `docs: PH-SAAS-T8.12Y.3.1 email copy accents logo and conversion polish DEV` |

### Image Docker

| Tag | Digest |
|---|---|
| `v3.5.133-email-copy-logo-polish-dev` | `sha256:3e5f056948ce30701232047dcaded6971efd129b58dc230a03fdf5ccd9c7b285` |
