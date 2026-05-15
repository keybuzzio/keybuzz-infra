# PH-ADMIN-T8.12AS.15.1-GOOGLE-ADS-REFRESH-TOKEN-RECOVERY-PROD-01

> Date : 2026-05-15
> Linear : KEY-322 (Open). Parent : KEY-301 Done, KEY-313 Done, KEY-314 Open + pause AS.14.2.
> Phase : T8.12AS.15.1 (P0 emergency runbook manuel + verification)
> Environnement : PROD (Google Ads spend chain restored)

---

## 0. VERDICT

GO GOOGLE OAUTH RECOVERY READY.

Refresh token Google Ads regenere par Ludovic via OAuth Playground apres confirmation OAuth app PUBLISHED. Secret K8s `keybuzz-google-ads` patche via kubectl atomique sur le bastion (token jamais affiche dans le chat, jamais persiste sur disque). Pod API PROD restart pour propagation. Triple-egalite spec=last-applied=pod imageID=GHCR digest preservee (AS.14.1 v3.5.190 intact). Test OAuth refresh isole non-mutationnel : HTTP 200, scope `https://www.googleapis.com/auth/adwords`, access_token 253 chars, expires_in 3599. Sync controle declenche via Admin v2 PROD (clic Ludovic) : `last_sync_at` mis a jour, `last_error` passe a null, 0 GOOGLE_OAUTH_ERROR dans les logs, aucun 5xx, Meta non touche, AS.14.1 + AS.13.x protections preservees.

Resultat business : 0 nouvelle row spend inseree dans `ad_spend_tenant` pour Google car la campagne KeyBuzz Consulting Google Ads est en **pause volontaire** (agence attend UGC/videos/statics avant activation). Ce gap est attendu et non-bug. Le bandeau erreur Admin v2 a disparu et le compte est correctement reconnu (customer 594-796-3982).

KEY-322 reste Open. Aucun ticket Linear cree. Aucun token expose. Aucun event fake. Aucune mutation provider hors le sync Google volontaire et controle.

---

## 1. PERIMETRE EXACT DE CETTE PHASE

Scope strict (AS.15.1 P0 emergency runbook + verification) :
- 1 secret K8s patche : `keybuzz-google-ads` cle `GOOGLE_ADS_REFRESH_TOKEN`
- 1 rollout restart : `kubectl rollout restart deploy/keybuzz-api -n keybuzz-api-prod`
- 1 test OAuth refresh isole non-mutationnel (curl token endpoint Google, 0 mutation)
- 1 sync controle Admin v2 (clic Ludovic sur https://admin.keybuzz.io/marketing/ad-accounts)
- 0 build, 0 docker push, 0 manifest edit, 0 GitOps commit deploy
- 0 patch source
- 0 INSERT/UPDATE/DELETE DB (le sync est une mutation provider chain, controlee et auditee)
- 0 Linear status change
- 0 token / secret valeur exposee dans le chat ou les fichiers
- 0 event fake / metric fake / replay conversion

---

## 2. RUNBOOK EXECUTE

### 2.1 Phase 1 - Verifications Google (READ-ONLY Ludovic)

| Etape | URL | Verif | Resultat |
|---|---|---|---|
| OAuth app status | console.cloud.google.com/auth/audience?project=keybuzz-intelligence | "En production" PUBLISHED | OK confirme (deja PUBLISHED depuis PH-T8.11AG 2026-04-28) |
| OAuth Client ID + Secret | console.cloud.google.com/apis/credentials | Copies dans clipboard | OK (jamais dans le chat) |
| Third-party apps revoke check | myaccount.google.com/permissions | Verifier KeyBuzz Intelligence | Non documente cote chat (probable revoke ou rotation policy) |

### 2.2 Phase 2 - Regeneration refresh token via OAuth Playground

| Etape | Action | Resultat |
|---|---|---|
| Playground config | developers.google.com/oauthplayground -> Settings -> "Use your own OAuth credentials" + Client ID/Secret | OK |
| Scope select | `https://www.googleapis.com/auth/adwords` -> Authorize APIs | OK |
| Auth Google account | Login keybuzz.pro@gmail.com -> accept permissions | OK |
| Exchange auth code -> tokens | Step 2 click | refresh_token genere (format `1//...`, longueur 103 chars confirmed by Ludovic) |
| Stockage | clipboard Ludovic (jamais sur disque, jamais dans chat) | OK |

### 2.3 Phase 3 - Update secret K8s atomique

Procedure suivie par Ludovic sur le bastion :

```
ssh install-v3
# Read silently (no echo)
read -s -p "New GOOGLE_ADS_REFRESH_TOKEN: " NEW_TOKEN; echo
# Format sanity check
[[ "$NEW_TOKEN" == 1//* ]] && echo "Format OK"
# Base64 encode + patch atomique
NEW_TOKEN_B64=$(printf '%s' "$NEW_TOKEN" | base64 -w0)
kubectl -n keybuzz-api-prod patch secret keybuzz-google-ads --type=json \
  -p="[{\"op\":\"replace\",\"path\":\"/data/GOOGLE_ADS_REFRESH_TOKEN\",\"value\":\"$NEW_TOKEN_B64\"}]"
unset NEW_TOKEN NEW_TOKEN_B64
```

Verifications post-patch (Ludovic) :
- Token length post-patch : **103 chars** (conforme format Google Ads refresh token `1//0e...`)
- Aucune valeur de token affichee dans la session

### 2.4 Phase 4 step 1 - Rollout restart API PROD

Commande :
```
kubectl -n keybuzz-api-prod rollout restart deploy/keybuzz-api
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
```

Resultat :
- "Waiting for deployment rollout to finish: 1 old replicas are pending termination..."
- "deployment keybuzz-api successfully rolled out"

ReplicaSets post-rollout :
| ReplicaSet | DESIRED | READY | Image |
|---|---|---|---|
| keybuzz-api-67d7b4d758 (ancien) | 0 | none | v3.5.190-channels-tenantguard-prod |
| keybuzz-api-6c64b97644 (nouveau) | 1 | 1 | v3.5.190-channels-tenantguard-prod |

Pod actif : `keybuzz-api-6c64b97644-rzxrl` (cree 2026-05-15T08:12:31Z, READY=true, RESTARTS=0).

### 2.5 Phase 4 step 2 - Triple-egalite preservation

| Source | Valeur |
|---|---|
| spec.template.spec.containers[0].image | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-prod |
| metadata last-applied-configuration | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-prod |
| pod imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:71f0ddc5fe5ad1ffffbd2ae030d89e9e364ff684effff545b181ec8a8db2f9cd |
| GHCR manifest digest (AS.14.1-PROD) | sha256:71f0ddc5fe5ad1... |

Convergence : MATCH. AS.14.1 tenantGuard channels protection preservee.

Env var verification dans le pod actif :
```
GOOGLE_ADS_REFRESH_TOKEN=<MASKED>
```
Variable injectee via secretKeyRef + resolved au pod start. Le nouveau pod a la nouvelle valeur de secret.

Logs startup (extrait pertinent) :
- `Server listening at http://0.0.0.0:3001`
- `[CHANNELS-SAFETY] tenantId=<X> provider=amazon status=READY` (tenantGuard channels init OK pour 6 tenants)
- `[OCTOPIA-SYNC] Completed: tenants=0 imported=0 skipped=0 errors=0`
- WARN pre-existant : `[AIJournal] Could not ensure table` (non-bloquant, non-lie a AS.15.1)
- **0 GOOGLE_OAUTH_ERROR au boot**
- **0 5xx**

### 2.6 Phase 4 step 3 - Test OAuth refresh isole non-mutationnel

But : confirmer que le nouveau refresh_token genere bien un access_token avant de declencher un sync mutation chain.

Commande (executee dans le pod, env vars secret resolved) :
```
curl -s -o /tmp/oauth-r.json -w "HTTP %{http_code}\n" -X POST https://oauth2.googleapis.com/token \
  -d "client_id=$GOOGLE_ADS_CLIENT_ID" \
  -d "client_secret=$GOOGLE_ADS_CLIENT_SECRET" \
  -d "refresh_token=$GOOGLE_ADS_REFRESH_TOKEN" \
  -d "grant_type=refresh_token"
# Parse response WITHOUT printing access_token / refresh_token / id_token
```

Response safe (sans token affiche) :

| Champ | Valeur |
|---|---|
| HTTP status | **200** |
| safe keys | expires_in, scope, token_type |
| has_access_token | true |
| access_token_length | 253 chars (typique Bearer Google) |
| token_type | Bearer |
| expires_in | 3599 (~1h, standard) |
| scope | `https://www.googleapis.com/auth/adwords` (CORRECT) |
| has_error | false |

Verdict OAuth chain : **OPERATIONNEL**. La chain client_id + client_secret + refresh_token -> access_token fonctionne. Aucune mutation DB. Aucune query Google Ads spend.

### 2.7 Phase 4 step 4 - Sync controle Admin v2

Action : Ludovic clic "Sync" sur https://admin.keybuzz.io/marketing/ad-accounts (compte Google KeyBuzz Consulting, customer 594-796-3982).

Logs API observes :
```
GET  /ad-accounts                         (Admin v2 list)
POST /ad-accounts/1d813de7-5c9b-4c98-95fe-66f082c874bc/sync   (sync trigger)
GET  /ad-accounts                         (refresh apres sync)
```
0 GOOGLE_OAUTH_ERROR. 0 5xx.

---

## 3. RESULTATS POST-RECOVERY

### 3.1 ad_platform_accounts Google (DB read-only)

| Champ | Avant AS.15.1 | Apres AS.15.1 |
|---|---|---|
| platform | google | google |
| account_id | 5947963982 (594-796-3982) | 5947963982 (inchange) |
| status | active | active |
| **last_sync_at** | 2026-04-28T20:50:06Z (17j) | **2026-05-15T08:25:16Z** (just now) |
| **last_error** | `GOOGLE_OAUTH_ERROR: 400 invalid_grant Token has been expired or revoked` | **null** |
| updated_at | 2026-05-15T06:37:02Z | 2026-05-15T08:25:16Z |

### 3.2 ad_spend_tenant counts

| Platform | rows pre-sync | rows post-sync | first_date | last_date | total_spend |
|---|---|---|---|---|---|
| google | 2 | 2 (inchange) | 2026-04-28 | 2026-04-28 | 0.06 GBP |
| meta | 19 | 19 (inchange) | 2026-03-16 | 2026-05-15 | 537.52 GBP |

0 nouvelle row Google. **Etat business attendu** : la campagne Google KeyBuzz Consulting est en pause volontaire jusqu a la livraison des UGC/videos/statics par l agence. Pas de bug technique. Le code source confirme la fenetre de sync = 30 derniers jours (`since = NOW - 30 jours`, `until = NOW`), donc toutes les depenses recentes auraient ete importees si elles existaient cote Google Ads.

### 3.3 Anti-regression preservee

| Surface | Etat post-AS.15.1 |
|---|---|
| keybuzz-api PROD | v3.5.190-channels-tenantguard-prod (inchange, restart only) |
| keybuzz-client PROD | v3.5.197-channels-bff-userauth-prod (inchange) |
| keybuzz-admin-v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod (inchange) |
| keybuzz-backend PROD | v1.0.47-cross-env-guard-fix-prod (inchange) |
| AS.14.1 tenantGuard channels | preserved (logs CHANNELS-SAFETY init OK) |
| AS.13.x outbound + compat Amazon | preserved |
| AS.12.x AI + autopilot + notifications | preserved |
| Inbox + Brouillon IA + tenant switcher | preserved |

### 3.4 QA Ludovic Admin v2 PROD

| Verif | Resultat |
|---|---|
| /marketing/ad-accounts charge sans erreur | OK |
| Bandeau erreur Google disparu | OK |
| Compte affiche : 594-796-3982 KeyBuzz Google Ads | OK |
| Status active sans error | OK |
| last_sync_at recent | OK |
| Meta compte affiche OK | OK |
| Inbox / Brouillon IA / tenant switcher / escalation | OK |

---

## 4. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 fake spend / fake conversion / fake attribution
- 0 fake event GA4 / CAPI / TikTok / LinkedIn
- 0 token / refresh_token / access_token / client_secret affiche dans chat ou rapport
- 0 fichier persistant contenant le token (read -s + unset apres patch)
- 0 PII / payload provider sensible
- 1 unique mutation provider Google : sync controle declenche par Ludovic via Admin v2 (volontaire, audite, attendu)
- 0 mutation autre provider (Meta, TikTok, LinkedIn)
- 0 INSERT/UPDATE/DELETE DB hors le sync controle (UPDATE ad_platform_accounts.last_sync_at + last_error = null, 0 new ad_spend_tenant row)
- 0 Linear status change
- 0 build / docker push / kubectl apply manifest / GitOps commit deploy

---

## 5. ROLLBACK READY

Plan rollback (si necessaire dans le futur) :
1. **Revoke nouveau refresh_token** : si compromission suspectee, Ludovic peut revoke le token via myaccount.google.com/permissions
2. **Restore ancien token** : impossible (ancien token deja revoque/expire). Necessite generation d un nouveau refresh_token (meme procedure que cette phase).
3. **Rollback pod runtime** : `kubectl -n keybuzz-api-prod rollout undo deploy/keybuzz-api` ramene au ReplicaSet precedent (mais le secret reste patche, donc le sync Google fonctionnera tant que le nouveau token est valide).
4. **Rollback secret** : non applicable (1 seul cle modifiee, ancienne valeur non sauvegardee, mais ancien token deja invalide donc pas de regret).

Aucun rollback necessaire post-AS.15.1 : runtime stable, AS.14.1 protections preservees, anti-regression OK.

---

## 6. LINEAR (commentaire propose KEY-322)

```
PH-ADMIN-T8.12AS.15.1 P0 Google Ads OAuth recovery livre.

Diagnostic AS.15.0 confirme : refresh token revoque/invalide depuis 17 jours malgre OAuth app DEJA PUBLISHED en production. Cause exacte revocation non documentee (probable rotation Google policy ou revoke side-action par admin Google Workspace).

Procedure executee :
1. Verification OAuth app statut PUBLISHED dans Google Cloud Console (Ludovic, READ-ONLY)
2. Regeneration refresh token via Google OAuth 2.0 Playground avec scope https://www.googleapis.com/auth/adwords (Ludovic)
3. Patch atomique K8s secret keybuzz-google-ads cle GOOGLE_ADS_REFRESH_TOKEN via kubectl patch JSON, lecture read -s + unset, token jamais expose
4. Rollout restart keybuzz-api PROD, triple-egalite preservee (image v3.5.190-channels-tenantguard-prod inchange, AS.14.1 + AS.13.x protections preservees)
5. Test OAuth refresh isole non-mutationnel : HTTP 200, scope adwords, access_token 253 chars, expires_in 3599
6. Sync controle Google Ads via Admin v2 (clic Ludovic) : last_sync_at maj 2026-05-15T08:25:16, last_error null, 0 GOOGLE_OAUTH_ERROR logs, 0 5xx

Resultat business : 0 nouvelle row ad_spend_tenant Google car la campagne Google KeyBuzz Consulting (594-796-3982) est en pause volontaire jusqu a la livraison UGC/videos/statics par l agence. Etat attendu et normal, pas un bug technique. Le code source confirme une fenetre de sync de 30j (since=NOW-30j, until=NOW). Toutes depenses recentes auraient ete importees si elles existaient cote Google Ads.

QA Ludovic PROD confirmee :
- /marketing/ad-accounts charge sans erreur
- Bandeau erreur Google disparu
- Compte 594-796-3982 affiche active sans error
- last_sync_at recent visible
- Meta inchange (537.52 GBP cumule)
- Inbox + Brouillon IA + tenant switcher + escalation OK

Anti-regression PROD : 4 services inchanges sur images (api v3.5.190, client v3.5.197, admin v2.12.2, backend v1.0.47). DEV inchange.

Hygiene securite :
- 0 token (refresh ou access) affiche dans chat ou rapport
- 0 secret valeur exposee
- 0 fichier persistant contenant le token
- 0 event fake / spend fake / conversion fake
- 0 mutation provider hors sync controle (Meta inchange, TikTok/LinkedIn inchange)
- 0 Linear status change

Next check (gap a tracker) : a J+24h apres activation campagne par l agence, verifier sous 24h que ad_spend_tenant Google se remplit avec nouvelles rows et que Admin v2 les affiche. Si pas de spend remonte malgre activation : escalader audit campagnes Google Ads actives + customer_id + LOGIN_CUSTOMER_ID (env var absente du secret K8s).

KEY-322 reste Open. KEY-301 et KEY-313 restent Done. KEY-314 reste Open + pause AS.14.2.

Rapport : keybuzz-infra/docs/PH-ADMIN-T8.12AS.15.1-GOOGLE-ADS-REFRESH-TOKEN-RECOVERY-PROD-01.md
```

Aucun changement de statut Linear effectue par cette phase.

---

## 7. GAPS / FOLLOW-UP

| Gap | Statut | Action proposee |
|---|---|---|
| Pas de nouvelle row spend Google apres sync | EXPLAINED (campagne en pause volontaire, agence attend UGC/videos/statics) | Re-verifier sous 24h apres activation campagne |
| Cause exacte revocation initial token (pre-AS.15.1) | UNKNOWN | Surveillance future : si nouveau token re-revoque rapidement, investiguer Google Workspace policy ou audit logs Google Admin |
| Aucun CronJob spend sync periodique | KNOWN (decouvert AS.15.0) | AS.15.6 proposee dans plan AS.15.0 (P2) |
| GOOGLE_ADS_LOGIN_CUSTOMER_ID absent du secret K8s | KNOWN (AS.15.0) | AS.15.2 P0/P1 audit conditionnel (verifier si MCC requis ; pas necessaire si compte direct comme actuellement) |
| 0 delivery log CAPI 7j (Meta + TikTok + LinkedIn) | KNOWN (AS.15.0) | AS.15.3 P1 separe |
| fbclid + li_fat_id = 0 capture | KNOWN (AS.15.0) | AS.15.4 P1 separe |

---

## 8. PHRASE CIBLE FINALE

Google Ads OAuth recovery completee en PROD. Refresh token regenere par Ludovic via OAuth Playground, secret K8s patche atomiquement, pod restart, sync controle reussi sans GOOGLE_OAUTH_ERROR. Triple-egalite spec=last-applied=pod imageID=GHCR preservee (AS.14.1 v3.5.190 intact). 0 nouvelle row spend = etat business normal (campagne en pause volontaire). Bandeau erreur Admin v2 disparu, compte 594-796-3982 active sans error. Aucun token expose. Aucune mutation hors sync controle. Anti-regression Meta + AS.14.1 + AS.13.x + Inbox + Brouillon IA OK. KEY-322 reste Open. Aucun enchainement vers AS.15.3+ sans GO Ludovic explicite.

STOP
