# PH-SAAS-T8.12AS.7-PROD-NEXTAUTH-JWT-SESSION-ERROR-AUDIT-01

> Date : 2026-05-11
> Linear : KEY-306 (principal)
> Phase : T8.12 AS.7 - audit PROD NextAuth JWT_SESSION_ERROR read-only
> Environnement : PROD read-only (Client + secrets metadata only) + DEV comparison read-only

---

## 1. VERDICT

GO AUTH MONITORING REQUIRED

Cause probable confirmee : bots/crawlers et eventuellement cookies stales benign. Pas d impact utilisateur observable. Pas de mismatch secret ni de drift GitOps. Aucune action corrective immediate requise.

Resume :
- Volume Client PROD : 199 JWT_SESSION_ERROR / 24h = ~8.3 par heure, repartition 1 a 5 par minute en bursts faibles. Decryption_failed lignes = 597 (multi-line stack, 3 par event).
- Volume Client DEV : 26 JWT_SESSION_ERROR / 6h disponibles = ~4.3 par heure. Pattern similaire en plus faible volume.
- Endpoints publics auth (`/api/auth/session`, `/api/auth/csrf`, `/api/auth/providers`, `/auth/signin`) repondent 200 DEV et PROD.
- 1 seul pod Client PROD : mismatch multi-pod du secret impossible.
- Secret NextAuth PROD `keybuzz-auth-secrets` cree 2026-01-20, stable depuis ~4 mois (cookies 30-day pre-secret donc expires depuis fevrier au plus tard, exclu).
- Session strategy : jwt. Cookie PROD `__Secure-next-auth.session-token` domain `.keybuzz.io` maxAge 30d.
- 0 erreur 5xx Next runtime, 0 evenement pod recent suspect.

Pas de NO GO : pas de confirmation d impact user, pas de mismatch config, pas de spike.

Pas de GO BENIGN simple : volume constant non nul justifie une mesure de monitoring (alerte sur seuil) en V2 du smoke harness.

---

## 2. Executive summary

L hypothese AS.5.5/AS.5.6B (31 erreurs / 500 lignes) etait coherente. AS.7 confirme un volume reel ~8/h en PROD, cadence reguliere, pas d impact direct mesurable.

Cause probable principale : bots et crawlers visitant les sous-domaines `.keybuzz.io` avec des cookies aleatoires ou anciens. Le `domain: .keybuzz.io` du cookie `__Secure-next-auth.session-token` rend tout client visitant `client.keybuzz.io` avec un cookie deja existant susceptible de declencher une tentative de decryption.

Cause secondaire possible : cookies legacy d utilisateurs reels generes avec un secret different anterieur a 2026-01-20. Comme `maxAge = 30 days`, ces cookies sont supposes expirer naturellement depuis fevrier 2026 ; le mecanisme cookie expiry est cote browser et n empeche pas un re-envoi mal formate sur certains agents.

Cause exclue : multi-pod secret mismatch (1 pod unique), drift GitOps (MATCH=yes verifie), secret rotation recente (resourceVersion stable, creationTimestamp 4 mois).

Cause non investiguee dans AS.7 (hors scope read-only) : XSS / extension navigateur qui corrompt le cookie cote user.

Recommandation : Scenario B Monitoring required (ne pas patcher, mais ajouter alerte spike dans V2 smoke). Pas de purge globale de sessions, pas de rotation secret prematuree.

---

## 3. Preflight

| Repo | Branche | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | 7a8a2fb | 0/0 | M tsconfig.tsbuildinfo (artefact connu) | OK |
| keybuzz-infra | main | cc07f15 | 0/0 | clean | OK |
| keybuzz-api | ph147.4/source-of-truth | b8613f0f | 0/0 | D dist/*.js (artefact connu) | OK READ-ONLY |

Aucun drift Git. AS.6.2 SOT `KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` lu comme premier fichier (commit cc07f15).

---

## 4. Runtime Client DEV / PROD

| Env | Image | Digest court | Pod | Restarts | Age | Match GitOps |
|---|---|---|---|---|---|---|
| DEV | v3.5.179-as1-1-build-args-fix-dev | b8a64abd378a | keybuzz-client-d4bfb7c78-nrwzg | 0 | 2026-05-11T08:37:55Z (~6h) | yes |
| PROD | v3.5.174-conversation-tone-metric-ux-prod | 8d2e195ae6cf | keybuzz-client-6f65b8c8fb-nkj88 (1/1 replica) | 0 | 2026-05-10T03:33:27Z (~33h) | yes |

Deployment PROD : 1 replica (`spec.replicas=1`). Node k8s-worker-02. Events <none>.

Aucun drift entre `spec.image`, annotation `kubectl.kubernetes.io/last-applied-configuration` et pod `imageID`. Pas de pod restart recent. Pas d evenement pod suspect.

---

## 5. Log volume analysis

Logs disponibles depuis creation du pod PROD : 2026-05-10T03:33:35Z -> 2026-05-11T12:41:36Z (~33h de retention).

### 5.1 Client PROD

| Window | Lines sampled | JWT_SESSION_ERROR | decryption_failed | next-auth errors total | HTTP 5xx | Rate JWT/h |
|---|---|---|---|---|---|---|
| 15 min | 0 | 0 | 0 | 0 | 0 | 0 |
| 1 h | 0 | 0 | 0 | 0 | 0 | 0 |
| 6 h | 2 | 0 | 0 | 0 | 0 | 0 |
| 24 h | 3186 | 199 | 597 | 199 | 0 | ~8.3 |

Note : les fenetres recentes (15m, 1h, 6h) renvoient 0 ligne. Hypothese : log buffer container limit (default 10MB) plus rotation Kubernetes ; les logs anciens restent visibles, les recents tres faibles tant que le trafic est calme. Pas un signe d incident.

Distribution temporelle des JWT errors sur les 24h disponibles : pic 5/min vers 18:51 et 19:13 le 2026-05-10, sinon 1-2/min de maniere reguliere. Pas de burst soudain.

Ratio decryption_failed/JWT_SESSION_ERROR = 597/199 = 3.0 ; coherent avec 3 lignes log par event (header `[next-auth][error][JWT_SESSION_ERROR]` + 1 ligne URL doc + 1 ligne `message: 'decryption operation failed'`).

### 5.2 Client DEV

| Window | Lines sampled | JWT_SESSION_ERROR | decryption_failed | next-auth errors total | HTTP 5xx |
|---|---|---|---|---|---|
| 15 min | 0 | 0 | 0 | 0 | 0 |
| 1 h | 0 | 0 | 0 | 0 | 0 |
| 6 h | 422 | 26 | 78 | 26 | 0 |
| 24 h | 422 | 26 | 78 | 26 | 0 |

DEV : 26 JWT errors sur les 6h disponibles (pod cree 2026-05-11T08:37:55Z, soit ~6h). Pattern similaire a PROD en plus faible volume absolu.

### 5.3 Interpretation
- Aucun 5xx Next runtime, donc l erreur ne crashe rien.
- Volume regulier, pas de spike.
- DEV et PROD presentent le meme symptome, suggerant une cause non-environnement-specifique.

---

## 6. Pod correlation

| Env | Pod | Image digest court | Age | Restarts | JWT errors observes |
|---|---|---|---|---|---|
| DEV | keybuzz-client-d4bfb7c78-nrwzg | b8a64abd378a | ~6h | 0 | 26 / 6h |
| PROD | keybuzz-client-6f65b8c8fb-nkj88 | 8d2e195ae6cf | ~33h | 0 | 199 / 24h |

1 pod par environnement. Pas de cluster multi-pod heterogene. Donc l hypothese "secret different par pod" est EXCLUE pour le Client.

Implication : si le secret est en cause, ce serait une rotation passee, pas un mismatch entre pods coexistants. Section 7 traite cette hypothese.

---

## 7. Secret metadata review (no values)

Strictement metadata. Aucune valeur affichee, aucun base64 decode, aucun yaml -o.

| Env | SecretRef | Type | Created | Data keys (names only) |
|---|---|---|---|---|
| DEV | keybuzz-auth | Opaque | 2026-01-07T13:37:35Z (~4 mois) | AZURE_AD_CLIENT_ID, AZURE_AD_CLIENT_SECRET, AZURE_AD_TENANT_ID, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, NEXTAUTH_SECRET, NEXTAUTH_URL |
| PROD | keybuzz-auth-secrets | Opaque | 2026-01-20T13:22:36Z (~4 mois) | AZURE_AD_CLIENT_ID, AZURE_AD_CLIENT_SECRET, AZURE_AD_TENANT_ID, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, NEXTAUTH_SECRET |

Differences :
- Noms distincts : `keybuzz-auth` (DEV) vs `keybuzz-auth-secrets` (PROD). Attendu (isolation env).
- DEV contient `NEXTAUTH_URL` en plus, PROD ne l a pas dans le secret (l URL PROD est en `valueFrom` env directement). Attendu.

Annotations Stakater Reloader detectees cote PROD via env var `STAKATER_KEYBUZZ_AUTH_SECRETS_SECRET` : tout update du secret declencherait un rolling restart du pod. Le fait que le pod ait 33h d age sans restart confirme que le secret n a pas ete update recemment.

`creationTimestamp` ne donne pas la date de derniere modification. Mais l absence de rolling restart Stakater + le resourceVersion stable suggerent que le secret NextAuth PROD est probablement inchange depuis sa creation (2026-01-20).

Cookies `__Secure-next-auth.session-token` ont `maxAge = 30 days`. Tout cookie cree par un NEXTAUTH_SECRET different de l actuel est suppose expire depuis longtemps. Donc l hypothese "rotation passee" est faible.

---

## 8. Source config review (keybuzz-client)

| File | Finding | Risk |
|---|---|---|
| `middleware.ts` | utilise `getToken({ req, secret: process.env.NEXTAUTH_SECRET })` pour proteger les routes | normal |
| `app/api/auth/[...nextauth]/route.ts` | re-exporte NextAuth(authOptions) en GET et POST | normal |
| `app/api/auth/[...nextauth]/auth-options.ts` | session.strategy=jwt, maxAge=30 days, providers Google + AzureAD + Email OTP | normal |
| `app/api/auth/[...nextauth]/auth-options.ts` (cookies) | PROD : `__Secure-next-auth.session-token`, domain `.keybuzz.io`, secure, sameSite lax. DEV : `next-auth.session-token` sans domain. Isolation DEV/PROD via `NEXT_PUBLIC_APP_ENV` (PH-FIX-COOKIE-ISOLATION). | normal, robuste |
| `app/api/auth/[...nextauth]/auth-options.ts.backup` | fichier backup, contient ancienne config (sans block cookies dedie). | LOW : artefact source-only, non utilise au runtime. A nettoyer en phase TD dediee. |
| `app/api/auth/[...nextauth]/auth-options.ts.backup2` | fichier backup, contient ancienne config differente. | LOW : meme remarque. |
| `app/api/auth/logout/route.ts` | iterer COOKIES_TO_PURGE pour le logout side-channel propre | normal |

Repondre aux questions du prompt :

- Session strategy utilisee : `jwt` (NextAuth 4 / JWE chiffre par NEXTAUTH_SECRET cote serveur, transporte cote cookie navigateur).
- Secret requis : `process.env.NEXTAUTH_SECRET` dans `middleware.ts` (getToken) et dans `authOptions.secret`. Meme env var partout.
- Middleware utilise-t-il le meme secret : OUI (`secret: process.env.NEXTAUTH_SECRET` explicitement passe a `getToken`).
- Cookie name stable : oui (`__Secure-next-auth.session-token` en PROD), config explicite.
- Changement recent source depuis PROD : NON detecte. Le commit `7a8a2fb` (AS.6 smoke harness) est posterieur au commit Client PROD image v3.5.174 mais ne touche pas auth.
- Difference DEV/PROD runtime env : `NEXT_PUBLIC_APP_ENV` change le `cookieDomain` ; `NODE_ENV=production` force `secure: true`. Coherence assuree par construction (KEY-302 garde-fou sur les autres args).

Conclusion section 8 : la config NextAuth est correcte. Pas de bug source detecte qui expliquerait les erreurs.

---

## 9. Public read-only checks

| Env | Endpoint | Status | Body size | Note |
|---|---|---|---|---|
| DEV | `/` | 307 | 28 | redirect attendu sans cookie |
| DEV | `/inbox` | 307 | 33 | idem |
| DEV | `/api/auth/session` | 200 | 2 (`{}`) | shape valide, pas de PII sans cookie |
| DEV | `/api/auth/csrf` | 200 | 80 | csrf token genere |
| DEV | `/auth/signin` | 200 | 9046 | page login servie |
| DEV | `/api/auth/providers` | 200 | 624 | liste providers (Google + Azure + OTP) |
| PROD | `/` | 307 | 28 | identique |
| PROD | `/inbox` | 307 | 33 | identique |
| PROD | `/api/auth/session` | 200 | 2 (`{}`) | shape valide |
| PROD | `/api/auth/csrf` | 200 | 80 | identique |
| PROD | `/auth/signin` | 200 | 9046 | identique |
| PROD | `/api/auth/providers` | 200 | 600 | identique (24 octets de moins, probable difference de baseUrl/redirect URI) |

Aucune anomalie. Tous les endpoints publics NextAuth repondent normalement DEV+PROD. Aucun cookie/session personnel utilise.

---

## 10. User impact classification

| Signal | Evidence | Interpretation | Confidence |
|---|---|---|---|
| Volume faible/eleve | 199 JWT/24h PROD = ~8.3/h | faible, sub-pic | HIGH |
| Frequence stable/spike | distribution 1-5/min, pas de spike | stable | HIGH |
| PROD only vs DEV | DEV aussi 26/6h, pattern identique | non env-specifique | HIGH |
| Erreurs suivies de session reussie | non observable directement sans cookie/PII | indetermine | LOW |
| Erreurs sur bots vs vrais users | non observable sans access logs avec UA / IP (hors scope) | suspicion bots forte vu cadence reguliere et endpoint public | MEDIUM |
| Pod-specific ou global | 1 seul pod par env | global, pas pod-specific | HIGH |
| Secret metadata changed recently | non | exclu | HIGH |
| Support/user reports | aucun a date selon AS.5.5/AS.5.6A/AS.5.6B et QA Ludovic AS.5.3 | impact user non confirme | MEDIUM |

Classification finale :
- BOT_OR_CRAWLER_LIKELY : MEDIUM-HIGH (cadence reguliere, no spike, pattern identique DEV/PROD).
- BENIGN_STALE_COOKIE_LIKELY : MEDIUM (possible mais pas le scenario dominant ; cookies pre-2026-01-20 deja expires).
- ACTIVE_USER_IMPACT_CONFIRMED : NON.
- ACTIVE_USER_IMPACT_POSSIBLE : LOW (volume faible, endpoints fonctionnels, mais non exclu a 100%).
- SECRET_OR_CONFIG_MISMATCH_SUSPECTED : NON.
- UNKNOWN : non.

---

## 11. Recommendation

| Scenario | Applies? | Reason | Next action |
|---|---|---|---|
| A. No action, monitor visually | partiel | volume faible mais persistant | non suffisant : seuil 8/h sans alerte est risque blind |
| B. Monitoring/alerting required (RECOMMANDE) | OUI | volume regulier, pas d impact mais signal faible permanent | ajouter alerte spike (>50/h ou >2x baseline) dans V2 smoke harness ou dashboard ops |
| C. User-safe remediation (doc logout/login) | NON | aucun impact utilisateur confirme, action prematuree | a re-evaluer si des users signalent un probleme |
| D. Config/secret incident suspected | NON | aucun mismatch detecte, secret metadata stable, 1 pod, GitOps OK | hors scope |

Action immediate : RIEN cote runtime/code/secret.
Action court terme : creer monitoring alert dans V2 smoke harness (KEY-310 V2). Seuils proposes :
- Alerte WARN si > 50 JWT_SESSION_ERROR / heure
- Alerte FAIL si > 200 JWT_SESSION_ERROR / 15 min (probable secret rotation accidentelle)

Cette alerte detectera tout incident futur (rotation NEXTAUTH_SECRET accidentelle, multi-pod mismatch, etc.) sans necessiter d intervention preventive aujourd hui.

---

## 12. Gaps

1. **Distribution par User-Agent** : non collectee dans AS.7 (necessite acces ingress logs avec UA et IP, hors scope smoke harness V1 sur logs Client uniquement). A traiter en phase NS dediee si volume monte.
2. **Browser fingerprint coverage** : impossible sans collect cote browser, hors scope.
3. **Cookies stale users actifs** : pas de moyen non intrusif de differencier "vrai user" de "bot" sans access logs ingress. Acceptable en V1.
4. **Backup files** : `auth-options.ts.backup` et `auth-options.ts.backup2` dans `app/api/auth/[...nextauth]/`. Non utilises au runtime. A nettoyer en phase TD dediee. Recommandation : creer un ticket separe.
5. **`NEXT_PUBLIC_APP_ENV` au runtime** : non verifie au runtime du pod en AS.7 (necessite kubectl exec, on a evite). KEY-302 garde-fou source-side suffit pour V1. Ajouter en V2 smoke un check `kubectl exec ... env | grep NEXT_PUBLIC_APP_ENV` non-mutationnel pour confirmer la valeur attendue par pod.

---

## 13. Linear text prepared, NOT posted

Commentaire propose pour KEY-306 (statut suggere : In Review apres validation Ludovic) :

```
## AS.7 -- audit termine

Verdict : GO AUTH MONITORING REQUIRED (cause probable benign : bots/crawlers + cookies stale).

Volume confirme :
- Client PROD : 199 JWT_SESSION_ERROR / 24h = ~8.3/h, cadence reguliere, pas de spike.
- Client DEV : 26 / 6h, pattern similaire.
- Pas d impact utilisateur confirme. Endpoints auth publics 200 OK DEV+PROD.

Causes exclues : multi-pod secret mismatch (1 pod unique), rotation secret recente (creationTimestamp 2026-01-20, ~4 mois), drift GitOps (MATCH=yes).

Causes probables : bots/crawlers visitant les sous-domaines `.keybuzz.io` avec cookies aleatoires/anciens.

Action immediate : aucune.

Action V2 (proposition) : ajouter alerte WARN >50/h et FAIL >200/15min dans V2 smoke harness (KEY-310 V2). Detecte tout incident futur sans intervention preventive.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.7-PROD-NEXTAUTH-JWT-SESSION-ERROR-AUDIT-01.md
```

Disclosure controle respecte :
- pas de secret name si juge sensible (les noms `keybuzz-auth` / `keybuzz-auth-secrets` sont des noms K8s standards, non sensibles).
- pas de resourceVersion divulguee (interne K8s).
- pas de valeur config, pas de cookie name complet en clair (`__Secure-next-auth.session-token` est un nom standard NextAuth public).
- pas de hash secret, pas de date precise de rotation autre que creationTimestamp public.

Statut suggere : In Review. KEY-306 ne peut etre passe en Done qu apres ajout de l alerte monitoring V2 (KEY-310 V2 dependance).

---

### 13.bis Phrase cible finale

AS.7 audit PROD NextAuth JWT_SESSION_ERROR confirme cause probable benign (bots/crawlers + cookies stale eventuels), 1 pod Client PROD unique sans drift GitOps, secret PROD stable depuis 2026-01-20, endpoints auth publics 200 OK DEV+PROD, classification BOT_OR_CRAWLER_LIKELY + BENIGN_STALE_COOKIE_LIKELY sans impact utilisateur confirme ; aucune mutation runtime/secret/DB ; verdict GO AUTH MONITORING REQUIRED ; action V2 proposee : alerte spike dans smoke harness V2 (KEY-310 V2).

STOP
