# PH-T5.3.1-EMERGENCY-ROLLBACK-AND-PROVENANCE-AUDIT-01 — TERMINÉ

> **Date** : 1er mars 2026
> **Environnement** : DEV uniquement
> **Priorité** : CRITIQUE

---

## Verdict : DEV SANE STATE RESTORED — PH-T5.3 INVALIDATED

---

## 1. Préflight


| Élément                   | Valeur                                                                           |
| ------------------------- | -------------------------------------------------------------------------------- |
| Client DEV avant rollback | `ghcr.io/keybuzzio/keybuzz-client:v3.5.49-tracking-t5.3-dev`                     |
| API DEV                   | `ghcr.io/keybuzzio/keybuzz-api:v3.5.77-tracking-t4-api-dev` (saine, non touchée) |
| Backend DEV               | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-ph150-thread-fix-prod` (non touché)   |
| Client rollback cible     | `ghcr.io/keybuzzio/keybuzz-client:v3.5.78-tracking-replay-on-valid-branch-dev`   |
| API conservée             | `ghcr.io/keybuzzio/keybuzz-api:v3.5.77-tracking-t4-api-dev`                      |


---

## 2. Rollback

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.78-tracking-replay-on-valid-branch-dev \
  -n keybuzz-client-dev
```


| Élément             | Valeur                                                |
| ------------------- | ----------------------------------------------------- |
| Image client finale | `v3.5.78-tracking-replay-on-valid-branch-dev`         |
| Pod                 | `keybuzz-client-66f946957b-nzd2g` — `1/1 Running`     |
| Rollout             | `deployment "keybuzz-client" successfully rolled out` |
| API touchée         | NON                                                   |
| Backend touché      | NON                                                   |


---

## 3. Validation après rollback


| Domaine               | État après rollback                                                                                                      |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `/register`           | OK — 3 plans (Starter/Pro/Autopilot), boutons fonctionnels                                                               |
| `/login`              | OK — formulaire email OTP + Google OAuth + Microsoft                                                                     |
| `/start`              | OK — wizard onboarding 3 étapes, Autopilot proposé                                                                       |
| `/dashboard`          | OK — supervision, KPI (396 conv, 303 ouvertes, 334 SLA dépassés), répartition canaux, activité récente                   |
| `/inbox`              | OK — tripane layout, 396 conversations, suggestions IA, panneau commande, fournisseur                                    |
| `/settings/signature` | OK — formulaire nom entreprise + expéditeur + fonction + aperçu en direct                                                |
| `/settings/agents`    | OK — onglet Agents avec bouton Ajouter                                                                                   |
| Tracking PH-T1/T3/T4  | OK — gtag.js via `googletagmanager.com`, GA4 hits vers `region1.google-analytics.com`, Meta Pixel via `facebook.com/tr/` |
| Console               | OK — zéro erreur JavaScript                                                                                              |


### Preuve tracking opérationnel (post-rollback)


| Requête           | URL                                                               | Status |
| ----------------- | ----------------------------------------------------------------- | ------ |
| gtag.js script    | `https://www.googletagmanager.com/gtag/js?id=G-R3QQDYEBFG`        | 200    |
| GA4 page_view     | `https://region1.google-analytics.com/g/collect?...&en=page_view` | 204    |
| GA4 scroll        | `https://region1.google-analytics.com/g/collect?...&en=scroll`    | 204    |
| Meta Pixel config | `https://connect.facebook.net/signals/config/1234164602194748`    | 200    |
| Meta PageView     | `https://www.facebook.com/tr/?id=1234164602194748&ev=PageView`    | 200    |
| fbevents.js       | `https://connect.facebook.net/en_US/fbevents.js`                  | 200    |


Confirmation : le tracking est en mode **client-side standard** (pas de sGTM), comme attendu pour la baseline v3.5.78.

---

## 4. Audit provenance PH-T5.3


| Élément                   | Valeur                                                 |
| ------------------------- | ------------------------------------------------------ |
| Branche réelle utilisée   | `ph152.6-client-parity`                                |
| Commit réel               | `5d5d7df4` (17 avril 2026, 14:13)                      |
| Baseline attendue         | `ph148/onboarding-activation-replay`                   |
| Rollback proposé à tort   | `v3.5.48-white-bg-dev` (ancien, pas la baseline saine) |
| Divergence entre branches | **274 fichiers, 45689 insertions, 4750 suppressions**  |
| Merge base                | `8542bf0` (PH131-B.2: rename Autopilot to Pilotage IA) |


### Cause racine

Le prompt PH-T5.3 a été exécuté dans un workspace local (`c:\DEV\KeyBuzz\V3`) qui était sur la branche `ph152.6-client-parity`. L'agent Cursor a travaillé sur la branche active du workspace sans vérifier qu'elle correspondait à la baseline saine (`ph148/onboarding-activation-replay`).

Le bastion était également sur `ph148/onboarding-activation-replay` mais a été switchée vers `ph152.6-client-parity` par l'agent lors du build, propageant l'erreur.

Le rapport PH-T5.3 a proposé `v3.5.48-white-bg-dev` comme image de rollback — cette image est obsolète et ne correspond pas à la baseline saine validée.

---

## 5. Audit des changements PH-T5.3

### Fichiers touchés par le commit `5d5d7df4`


| Fichier                                     | Touché PH-T5.3     | Scope tracking pur ?     | Baseline saine modifiée ?                                      |
| ------------------------------------------- | ------------------ | ------------------------ | -------------------------------------------------------------- |
| `src/components/tracking/SaaSAnalytics.tsx` | Oui (+16 -3)       | Oui                      | Non — fichier identique sur la baseline                        |
| `Dockerfile`                                | Oui (+6)           | Oui (ajout ARG SGTM_URL) | Non — baseline a déjà GA4/Meta ARGs, manque seulement SGTM_URL |
| `scripts/ph-t53-build-deploy.sh`            | Oui (nouveau, +43) | Oui (script de build)    | N/A — fichier nouveau                                          |


### Verdict fichiers

Les 3 fichiers sont **100% dans le scope tracking** et **n'ont aucun lien avec les 274 fichiers divergents** entre `ph152.6-client-parity` et `ph148/onboarding-activation-replay`.

Les changements sont **rejouables** sur la branche `ph148/onboarding-activation-replay` par cherry-pick ou re-application manuelle.

### Comparaison des fichiers base


| Fichier             | Contenu sur `ph152.6-client-parity` (avant PH-T5.3) | Contenu sur `ph148/onboarding-activation-replay` | Identiques ?                     |
| ------------------- | --------------------------------------------------- | ------------------------------------------------ | -------------------------------- |
| `SaaSAnalytics.tsx` | PH-T3 standard (gtag client-side)                   | PH-T3 standard (gtag client-side)                | **Oui**                          |
| `Dockerfile`        | Sans GA4/Meta ARGs                                  | Avec GA4/Meta ARGs (PH-T4.2)                     | **Non** — baseline est en avance |


---

## 6. Statut PH-T5.3


| Élément                           | Statut                                                 |
| --------------------------------- | ------------------------------------------------------ |
| PH-T5.3 dans son ensemble         | **INVALIDÉE** — build depuis la mauvaise branche       |
| Changements code (3 fichiers)     | **À rejouer** sur `ph148/onboarding-activation-replay` |
| Image `v3.5.49-tracking-t5.3-dev` | **Obsolète** — ne pas réutiliser                       |
| Rapport PH-T5.3                   | **Caduc** — provenance incorrecte                      |
| Addingwell/sGTM                   | **Non touché** — configuration GTM inchangée           |


### Ce qui doit être rejoué

1. `SaaSAnalytics.tsx` : ajout `NEXT_PUBLIC_SGTM_URL` + `server_container_url` conditionnel + script src conditionnel
2. `Dockerfile` : ajout `ARG NEXT_PUBLIC_SGTM_URL` + `ENV NEXT_PUBLIC_SGTM_URL` (les ARGs GA4/Meta existent déjà sur la baseline)
3. `scripts/ph-t53-build-deploy.sh` : script de build (à adapter pour la bonne branche)

### Branche de référence

`**ph148/onboarding-activation-replay`** uniquement — pour toute future phase tracking.

---

## 7. Conclusion

- Le rollback a restauré l'état sain DEV
- PH-T5.3 est entièrement invalidée (mauvaise branche)
- Les changements PH-T5.3 sont techniquement corrects et rejouables sur la bonne branche
- L'API et le backend n'ont pas été touchés
- Addingwell n'a pas été touché
- Aucune autre action effectuée

---

**STOP**