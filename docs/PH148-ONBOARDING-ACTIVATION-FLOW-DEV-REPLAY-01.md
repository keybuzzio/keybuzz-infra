# PH148-ONBOARDING-ACTIVATION-FLOW-DEV-REPLAY-01

> Replay propre du flow onboarding dynamique /start
> Date : 16 avril 2026
> Environnement : DEV uniquement

---

## VERDICT : GO — ONBOARDING ACTIVATION FLOW RESTORED

---

## PREFLIGHT


| Service     | Image avant                           | Image après                           |
| ----------- | ------------------------------------- | ------------------------------------- |
| Client DEV  | `v3.5.65-ph147.6-shopify-ui-dev`      | `v3.5.66-ph148-onboarding-replay-dev` |
| API DEV     | `v3.5.55-ph147.4-source-of-truth-dev` | inchangé                              |
| Backend DEV | `v1.0.44-ph150-thread-fix-prod`       | inchangé                              |


**Rollback** : `kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.65-ph147.6-shopify-ui-dev -n keybuzz-client-dev`

---

## SOURCE DU BUILD


| Élément      | Valeur                                                                                      |
| ------------ | ------------------------------------------------------------------------------------------- |
| Repo         | `/opt/keybuzz/keybuzz-client` (bastion `46.62.171.61`)                                      |
| Branche      | `ph148/onboarding-activation-replay`                                                        |
| Commits      | `03970a1` + `f37b5c2` (2 commits)                                                           |
| Lieu         | bastion `install-v3` (`46.62.171.61`)                                                       |
| Preuve clean | `git status --porcelain` = 0 fichiers dirty avant build                                     |
| Build        | `docker build --no-cache` avec `--build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io` |
| Aucun SCP    | fichiers créés directement sur le repo bastion via script Python                            |


---

## SYNTHESE PH148 ATTENDU vs REALISE


| Élément PH148                     | Fichier ciblé                                          | Résultat |
| --------------------------------- | ------------------------------------------------------ | -------- |
| Hook `useOnboardingState`         | `src/features/onboarding/hooks/useOnboardingState.ts`  | CRÉÉ     |
| `OnboardingHub` dynamique 4 cas   | `src/features/onboarding/components/OnboardingHub.tsx` | RÉÉCRIT  |
| `app/start/page.tsx`              | `app/start/page.tsx`                                   | INCHANGÉ |
| Stepper 4 étapes (vert/bleu/gris) | dans `OnboardingHub.tsx`                               | OK       |
| CAS 1 : 0 canal → grille          | dans `OnboardingHub.tsx`                               | OK       |
| CAS 2 : canal, 0 msg → loader     | dans `OnboardingHub.tsx`                               | OK       |
| CAS 3 : messages → CTA IA         | dans `OnboardingHub.tsx`                               | OK       |
| CAS 4 : répondu → Autopilot       | dans `OnboardingHub.tsx`                               | OK       |
| Amazon OAuth direct               | via `startAmazonOAuth` existant                        | OK       |
| Shopify/Cdiscount → /channels     | redirect                                               | OK       |
| Fnac/eBay "Bientôt"               | badges disabled                                        | OK       |


---

## ÉTAT AVANT

L'ancien onboarding (`OnboardingHub.tsx` PH29.1) était une **checklist statique** de 5 items :

1. Créer votre espace (hardcodé `done: true`)
2. Compléter vos informations entreprise → `/settings/tenant`
3. Ajouter un canal (Amazon) → `/channels`
4. Vérifier la réception des messages → `/inbox`
5. Tester une réponse IA → `/inbox`

Aucune détection dynamique, aucune progression, aucun CTA adaptatif.

---

## ÉTAT APRÈS

### Flow dynamique CONNECTER → VOIR → RÉPONDRE

4 cas basés sur l'état réel détecté par `useOnboardingState()` :

- **CAS 1** : 0 canal → grille marketplaces (Amazon recommandé, Shopify, Cdiscount, Fnac, eBay)
- **CAS 2** : canal connecté, 0 message → loader animé + navigation inbox/canaux
- **CAS 3** : messages disponibles → compteur + badge IA + CTA "Répondre avec l'IA"
- **CAS 4** : réponses envoyées → CTA "Configurer l'Autopilot" + "Continuer manuellement"

### Hook `useOnboardingState`

Appels parallèles :

- `GET /api/amazon/status`
- `GET /api/octopia/status`
- `GET /api/shopify/status`
- `GET /api/dashboard/summary`

Retourne : `hasChannel`, `hasMessages`, `hasReplied`, `currentStep` (1-4), `channelDetails`, `messageCount`

**Bug corrigé** : import `useTenantId` pointait vers le fichier standalone (session NextAuth) au lieu du `TenantProvider` (contexte React). Corrigé dans les 2 fichiers.

---

## FICHIERS TOUCHÉS


| Action   | Fichier                                                | Lignes | Pourquoi                                         |
| -------- | ------------------------------------------------------ | ------ | ------------------------------------------------ |
| CRÉÉ     | `src/features/onboarding/hooks/useOnboardingState.ts`  | 78     | Hook détection état dynamique (4 API parallèles) |
| RÉÉCRIT  | `src/features/onboarding/components/OnboardingHub.tsx` | 208    | Flow 4 cas + stepper + CTA adaptatifs            |
| INCHANGÉ | `app/start/page.tsx`                                   | 4      | Rend `<OnboardingHub />`                         |


**0 fichier API modifié. 0 fichier Backend modifié. 0 fichier hors scope.**

---

## VALIDATION /start (VISIBLE dans l'IDE)

### Compte : [ludo.gonthier@gmail.com](mailto:ludo.gonthier@gmail.com) (eComLG, DEV)


| Test                                | Résultat                                                 |
| ----------------------------------- | -------------------------------------------------------- |
| `/start` — Hero visible             | ✅ "Bienvenue sur KeyBuzz"                                |
| `/start` — Stepper 4 étapes         | ✅ Connecter ✅ → Messages ✅ → Répondre ✅ → Automatiser 🔵 |
| `/start` — Plus de checklist legacy | ✅ Totalement supprimée                                   |
| `/start` — CAS 4 correct            | ✅ "Automatiser vos réponses ?"                           |
| CTA "Configurer l'Autopilot"        | ✅ Visible, pointe vers `/playbooks`                      |
| CTA "Continuer manuellement"        | ✅ Visible, pointe vers `/inbox`                          |
| Badge canal "✅ Amazon"              | ✅ Affiché en bas de page                                 |


### Logique dynamique confirmée

```
hasChannel = true   (Amazon DEV connecté)
hasMessages = true  (conversations existantes)
hasReplied = true   (open + resolved > 0)
currentStep = 4     → CAS 4 "Automatiser"
```

---

## NON-RÉGRESSION (VISIBLE dans l'IDE)


| Page         | Statut | Détails                                          |
| ------------ | ------ | ------------------------------------------------ |
| `/start`     | ✅      | Nouveau flow dynamique CAS 4                     |
| `/inbox`     | ✅      | 390 conversations, tri-panneaux, suggestions IA  |
| `/dashboard` | ✅      | 390 conv, KPI, SLA, répartition canaux, activité |
| `/settings`  | ✅      | 10 onglets, formulaire entreprise complet        |
| `/billing`   | ✅      | Plan Pro, KBActions 887.91, canaux 7/3           |
| `/channels`  | ✅      | 7 Amazon connectés (BE, ES, FR, IT, NL, PL, GB)  |


---

## ANTI-CONTAMINATION

- ✅ Seul le client a été modifié (2 fichiers onboarding)
- ✅ API inchangée
- ✅ Backend inchangé
- ✅ Billing inchangé
- ✅ Inbox inchangé
- ✅ Dashboard inchangé
- ✅ Channels inchangé
- ✅ Aucun connecteur modifié (Amazon OAuth réutilisé tel quel)
- ✅ DEV ONLY — aucun push PROD

---

## ROLLBACK

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.65-ph147.6-shopify-ui-dev \
  -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## CONCLUSION

- Flow onboarding dynamique PH148 restauré avec succès
- 4 cas dynamiques fonctionnels (CAS 4 validé sur compte DEV)
- Stepper 4 étapes avec états visuels (vert/bleu/gris)
- Bug import `useTenantId` identifié et corrigé (TenantProvider vs standalone)
- Aucune régression détectée sur les 6 pages critiques
- Aucune autre action effectuée

STOP