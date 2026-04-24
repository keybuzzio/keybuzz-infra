# PH-T7.3.2-REPLAY-LINKEDIN-ON-VALID-BRANCHES-DEV-01 — TERMINE

> Date : 2026-03-01 (execute le 2026-04-19)
> Type : Replay propre LinkedIn sur branches validees
> Environnement : DEV uniquement
> Verdict : **GO — LINKEDIN DEV REPLAY SUCCESS ON VALID BRANCHES**

---

## Preflight


| Element                  | Valeur                                                  |
| ------------------------ | ------------------------------------------------------- |
| Client branche           | `ph148/onboarding-activation-replay`                    |
| API branche              | `ph147.4/source-of-truth`                               |
| Repos clean avant modifs | **OUI** (reset des modifications PH-T7.3 non commitees) |
| PROD touchee             | **NON**                                                 |
| LinkedIn Partner ID      | `9969977`                                               |
| LinkedIn Conversion ID   | `27491233`                                              |
| LinkedIn Access Token    | **NON disponible** — sGTM reporte                       |


---

## Client

### Fichiers modifies


| Fichier                                     | Modif                                                   | Scope LinkedIn pur ? | OK  |
| ------------------------------------------- | ------------------------------------------------------- | -------------------- | --- |
| `src/components/tracking/SaaSAnalytics.tsx` | +23 lignes : const, shouldLoad, JSX Insight Tag         | **OUI**              | OK  |
| `Dockerfile`                                | +2 lignes : ARG + ENV `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | **OUI**              | OK  |


### Commit

```
bad2e22 PH-T7.3.2: LinkedIn Insight Tag + Dockerfile env (replay on valid branch)
```

Branche : `ph148/onboarding-activation-replay`
Diff : 2 fichiers, 24 insertions, 1 deletion — strictement LinkedIn, zero TikTok/refactoring.

### Image

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.83-linkedin-replay-dev
Image ID: 0a72abe59065
Build: --no-cache, build-from-git, NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977
```

---

## API

### Fichiers modifies


| Fichier                         | Modif                                               | Scope LinkedIn pur ? | OK  |
| ------------------------------- | --------------------------------------------------- | -------------------- | --- |
| `src/modules/billing/routes.ts` | +8 lignes : SELECT fix (`user_email`) + SHA256 hash | **OUI**              | OK  |


### Fix du bug critique PH-T7.3

Le bug de PH-T7.3 etait que `user_email` n'etait pas dans le SELECT de `emitConversionWebhook`,
rendant le hash SHA256 mort. **Corrige dans ce replay** :

```diff
-              attribution_id, plan, cycle, ttclid
+              attribution_id, plan, cycle, ttclid, user_email
```

### Commit

```
431776e6 PH-T7.3.2: SHA256 email hash for LinkedIn CAPI via sGTM (SELECT fix + replay on valid branch)
```

Branche : `ph147.4/source-of-truth`
Diff : 1 fichier, 8 insertions, 1 deletion.

### Image

```
ghcr.io/keybuzzio/keybuzz-api:v3.5.81-linkedin-api-replay-dev
Digest: sha256:7e9d0788c8d1fbb35cca0dad3ad459a9668a6fe3046ade2777d822f326317cca
Build: --no-cache, build-from-git
```

---

## Validation

### Fonctionnel


| Page       | OK                     |
| ---------- | ---------------------- |
| /login     | OK (200)               |
| API health | OK (`{"status":"ok"}`) |


### LinkedIn client


| Element             | OK     | Detail                                                      |
| ------------------- | ------ | ----------------------------------------------------------- |
| Insight Tag charge  | **OK** | `snap.licdn.com/li.lms-analytics/insight.min.js` (304)      |
| Attribution trigger | **OK** | `px.ads.linkedin.com/attribution_trigger?pid=9969977` (200) |
| Collect pixel       | **OK** | `px4.ads.linkedin.com/collect?pid=9969977` (200)            |
| Partner ID correct  | **OK** | `pid=9969977` dans toutes les requetes                      |


### LinkedIn API


| Element                               | OK     | Detail                                                      |
| ------------------------------------- | ------ | ----------------------------------------------------------- |
| `user_email` dans le SELECT compile   | **OK** | Confirme dans bundle (occurrence 2 de `signup_attribution`) |
| `sha256_email_address` dans le bundle | **OK** | Present                                                     |
| `createHash` dans le bundle           | **OK** | Present                                                     |
| Code NON mort                         | **OK** | SELECT inclut `user_email`, hash sera execute               |


### Non-regression tracking


| Tracker      | OK  | Detail                                                  |
| ------------ | --- | ------------------------------------------------------- |
| GA4 (sGTM)   | OK  | `t.keybuzz.io/gtag/js?id=G-JJ4KBW1BFE` (200)            |
| Meta Pixel   | OK  | `connect.facebook.net/.../fbevents.js` (200) + PageView |
| TikTok Pixel | OK  | `analytics.tiktok.com/.../events.js` (200) + pixel act  |
| Google Ads   | OK  | Via GA4/sGTM (non impacte)                              |


---

## sGTM


| Element                        | Etat                                                 |
| ------------------------------ | ---------------------------------------------------- |
| Tag LinkedIn CAPI              | **NON configure** — Access Token requis              |
| Trigger                        | **NON configure** — evenement `purchase` prevu       |
| Conversion ID                  | `27491233` — pret                                    |
| Mapping `sha256_email_address` | **Pret cote API** — a mapper dans sGTM               |
| Access Token                   | **NON genere** — action manuelle utilisateur requise |


### Ce qui reste a faire pour activer LinkedIn CAPI

1. Generer un LinkedIn Access Token (LinkedIn Developer Portal → Apps → Auth → Token)
2. Creer un tag LinkedIn CAPI dans le container sGTM
3. Configurer : Conversion Rule ID `27491233`, Access Token, trigger `purchase`
4. Mapper `sha256_email_address` → User Data → SHA256 Email
5. Publier le container sGTM

---

## Rollback


| Service     | Image AVANT                           | Image APRES                       | Commande rollback                                                                                                                    |
| ----------- | ------------------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Client DEV  | `v3.5.82-linkedin-dev`                | `v3.5.83-linkedin-replay-dev`     | `kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.82-linkedin-dev -n keybuzz-client-dev` |
| API DEV     | `v3.5.80-linkedin-dev`                | `v3.5.81-linkedin-api-replay-dev` | `kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.80-linkedin-dev -n keybuzz-api-dev`             |
| Client PROD | `v3.5.81-tiktok-attribution-fix-prod` | **NON TOUCHEE**                   | N/A                                                                                                                                  |
| API PROD    | `v3.5.79-tiktok-api-replay-prod`      | **NON TOUCHEE**                   | N/A                                                                                                                                  |


---

## Conclusion

### Differences avec PH-T7.3 (le precedent replay defectueux)


| Aspect                 | PH-T7.3 (defectueux)                      | PH-T7.3.2 (ce replay)                      |
| ---------------------- | ----------------------------------------- | ------------------------------------------ |
| Commits                | ZERO                                      | 2 commits propres (`bad2e22` + `431776e6`) |
| SELECT `user_email`    | **ABSENT** (code mort)                    | **PRESENT** (fix applique)                 |
| Scope LinkedIn pur     | Melange TikTok refactoring                | Strictement LinkedIn                       |
| Build-from-git         | NON (code uncommitte)                     | **OUI**                                    |
| Repo clean avant build | NON                                       | **OUI**                                    |
| Reproductible          | NON                                       | **OUI** (commits + tags)                   |
| Rapport                | Mauvais emplacement + conclusions fausses | `keybuzz-infra/docs/` correct              |


### Verdict final

**GO — LINKEDIN DEV REPLAY SUCCESS ON VALID BRANCHES**

- Client : Insight Tag fonctionnel, pixel LinkedIn actif avec `pid=9969977`
- API : SHA256 email hash corrige, `user_email` dans le SELECT, code vivant
- Non-regression : GA4, Meta, TikTok tous fonctionnels
- sGTM : reporte (Access Token absent), zero impact sur le code deploye
- PROD : intacte

Aucune autre action effectuee.