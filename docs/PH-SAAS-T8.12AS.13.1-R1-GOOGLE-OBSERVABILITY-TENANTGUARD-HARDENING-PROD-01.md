# PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-14
> Linear : KEY-313 (R1 outbound+compat surfaces tenantGuard extension)
> Parent historique : KEY-301 Done
> Phase : PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-PROD-01
> Environnement : PROD (API uniquement). Aucun build/deploy Client, Admin v2, worker outbound ou autre service.

---

## 1. VERDICT

GO GOOGLE OBSERVABILITY TENANTGUARD PROD READY

Le correctif AS.13.1 (KEY-313) est en runtime PROD via `ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-prod` (digest `sha256:93a8f7758f340da4807a5e008daf85728dbb04a3d62a71ae920fb39f2e83b619`, OCI revision `1c8b6b18efad67a7b4795351b55f2ce37bdd2d9c`). Le leak signup_attribution global du endpoint google-observability est ferme :
- sans headers => 400 ;
- role non autorise (ex. ops_admin) => 403 ;
- role admin marketing (super_admin / account_manager / media_buyer) => 200, scope filtre par tenantId (preuve : fake tenantId => counts a 0, last_gclid null, last_conversion null).

DB inchangee (signup_attribution total/gclids/conv = 8/2/3 avant=apres). 0 5xx API PROD sur 5-10 minutes. Client PROD inchange, Admin v2 PROD inchange, worker outbound inchange. QA navigateur Ludovic confirmee sur Admin PROD et Client PROD (Inbox, Brouillon IA, switcher, escalation, playbooks). KEY-313 reste Open ; KEY-301 reste Done.

---

## 2. SCOPE

| Item | Detail |
|---|---|
| Cible patch | `keybuzz-api/src/modules/outbound-conversions/google-observability.ts` |
| Endpoint affecte | GET `/outbound-conversions/google-observability` (1 endpoint) |
| Service runtime affecte | keybuzz-api uniquement (namespace keybuzz-api-prod) |
| Hors scope (strict) | keybuzz-client, keybuzz-admin-v2, keybuzz-outbound-worker, keybuzz-backend, keybuzz-website, keybuzz-studio, autres modules outbound-conversions/* |
| Type de protection | checkAccess local au module (ALLOWED_ROLES owner/admin + ADMIN_BYPASS_ROLES super_admin/account_manager/media_buyer), pas tenantGuard global |
| Source de la decision (alignment Admin v2) | `keybuzz-admin-v2/src/app/api/admin/marketing/proxy.ts` MARKETING_ROLES = ADMIN_BYPASS_ROLES API |

---

## 3. PREFLIGHT

### 3.1 Repos

| Repo | Branche | HEAD attendu | Sync | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 1c8b6b18 | OK fetch origin | dist/ deleted en worktree (cosmetique, build-api-from-git.sh fait fresh clone) | OK pour build |
| keybuzz-infra | main | ee857b2 (avant), 2899e9e (apres apply) | OK | clean | OK |

### 3.2 Runtime avant promotion

| Service | DEV | PROD |
|---|---|---|
| keybuzz-api | v3.5.187-google-observability-tenantguard-dev | v3.5.186-ai-rules-mut-tenantguard-prod |
| keybuzz-outbound-worker (image keybuzz-api) | v3.5.165-escalation-flow-dev | v3.5.165-escalation-flow-prod |
| keybuzz-client | v3.5.196-ai-rules-bff-dev | v3.5.196-ai-rules-bff-prod |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | v2.12.2-media-buyer-lp-domain-qa-prod |

### 3.3 KEY-309 verification

```
docker manifest inspect ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-prod
=> manifest unknown
```

Tag immuable libre avant push : OK.

---

## 4. BUILD EVIDENCE

Commande :
```
/opt/keybuzz/keybuzz-infra/scripts/build-api-from-git.sh prod v3.5.187-google-observability-tenantguard-prod ph147.4/source-of-truth
```

Sequence :
- fresh clone github.com/keybuzzio/keybuzz-api branche ph147.4/source-of-truth dans /tmp/keybuzz-api-build-$$ ;
- verification clone clean (`git status --porcelain` vide) ;
- docker build --no-cache avec ARGs IMAGE_REVISION, IMAGE_CREATED, IMAGE_VERSION.

KEY-308 OCI labels :

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | 1c8b6b18efad67a7b4795351b55f2ce37bdd2d9c (SHA full) |
| org.opencontainers.image.created | 2026-05-14T08:19:34Z |
| org.opencontainers.image.version | v3.5.187-google-observability-tenantguard-prod |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api |
| org.opencontainers.image.title | keybuzz-api |

Image locale ID : `sha256:b1fd67a4d3d523a0f99ea3062183a505cc642fe6a57f642ba6271a66f66cb524`.

---

## 5. PUSH DIGEST

Commande :
```
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-prod
```

| Item | Valeur |
|---|---|
| Image | ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-prod |
| Manifest digest GHCR | sha256:93a8f7758f340da4807a5e008daf85728dbb04a3d62a71ae920fb39f2e83b619 |
| Manifest size | 2416 |
| Config digest (= image ID local) | sha256:b1fd67a4d3d523a0f99ea3062183a505cc642fe6a57f642ba6271a66f66cb524 |

Aucun push d autre tag. KEY-309 respecte (tag unique immuable).

---

## 6. GITOPS EVIDENCE

### 6.1 Manifest patch (1 fichier)

```
M k8s/keybuzz-api-prod/deployment.yaml
```

Diff (2 insertions, 1 deletion) :
```
-          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.186-ai-rules-mut-tenantguard-prod  # PH-SAAS-T8.12AS.12.2C-5B-PROD KEY-301 (2026-05-13) ...
+          # PREVIOUS: v3.5.186-ai-rules-mut-tenantguard-prod  # PH-SAAS-T8.12AS.12.2C-5B-PROD KEY-301 (2026-05-13)
+          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-prod  # PH-SAAS-T8.12AS.13.1-PROD KEY-313 (2026-05-14): extend tenantGuard to google-observability endpoint (1 endpoint, API-only, marketing observability leak fix) ; rollback: v3.5.186-ai-rules-mut-tenantguard-prod ; digest: sha256:93a8f7758f340da4807a5e008daf85728dbb04a3d62a71ae920fb39f2e83b619
```

### 6.2 Commit + push

- Commit : `2899e9e deploy(prod): protect google observability tenant scope (KEY-313)` sur main
- Push : `ee857b2..2899e9e  main -> main` push origin main OK
- Scope : 1 fichier, +2 lignes, -1 ligne

### 6.3 Apply + rollout

```
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
=> deployment.apps/keybuzz-api configured
kubectl rollout status deploy/keybuzz-api -n keybuzz-api-prod --timeout=240s
=> deployment "keybuzz-api" successfully rolled out
```

### 6.4 spec = lastApplied = podImageID = digest GHCR

| Item | Valeur |
|---|---|
| deploy.spec.image | ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-prod |
| annotations.kubectl/last-applied | ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-prod |
| pod tqpcl status.containerStatuses[0].image | ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-prod |
| pod tqpcl status.containerStatuses[0].imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:93a8f7758f340da4807a5e008daf85728dbb04a3d62a71ae920fb39f2e83b619 |
| deployment.status | replicas=1 ready=1 available=1 updated=1 |

Identite spec = lastApplied = podImageID = digest GHCR : CONFIRMEE.

---

## 7. RUNTIME VALIDATION

URL : `https://api.keybuzz.io/outbound-conversions/google-observability?scope=owner` (path correct sans prefix /api/v3).

| Probe | Headers | Verdict attendu | HTTP observe |
|---|---|---|---|
| P1 sans headers | aucun | 400 | 400 (`Missing x-user-email or x-tenant-id`) |
| P2 sans headers + scope=owner | aucun | 400 | 400 |
| P3 fake email + fake tenant + bogus role | x-user-email=probe@invalid, x-tenant-id=00000000..., x-admin-role=foo | 403 | 403 |
| P4 ops_admin (NOT in bypass) | x-admin-role=ops_admin | 403 | 403 |
| P5 super_admin bypass + fake tenantId | x-admin-role=super_admin | 200 + payload vide | 200, counts=0, last_gclid=null, last_conversion_sent=null |
| P6 account_manager bypass | x-admin-role=account_manager | 200 | 200 |
| P7 media_buyer bypass | x-admin-role=media_buyer | 200 | 200 |

Sample body P5 (preuve absence de leak, no PII) :
```
{
  "google_observability": {
    "gclid_count": 0,
    "google_utm_count": 0,
    "conversions_sent": 0,
    "total_signups": 0,
    "last_gclid": null,
    "last_conversion_sent": null,
    "transport": "addingwell_sgtm",
    "data_source": "signup_attribution"
  }
}
```

Le tenantId filter `WHERE (marketing_owner_tenant_id = $1 OR tenant_id = $1)` est applique : un tenantId fictif retourne zero ligne, donc aucune donnee globale n est exposee meme aux roles bypass. Comparaison qualitative pre-patch (documentee dans AS.13.0) : sans headers le handler renvoyait counts agreges + last_gclid avec gclid_prefix reel et tenant_id. Cette fuite est desormais fermee.

---

## 8. DB NO-MUTATION

| Counter signup_attribution | Avant probes | Apres probes | Delta |
|---|---|---|---|
| total | 8 | 8 | 0 |
| gclids | 2 | 2 | 0 |
| conversion_sent_at | 3 | 3 | 0 |

Aucune ligne creee, aucune ligne modifiee, aucune conversion envoyee a un provider externe par les probes. Conforme `no fake metrics / no fake events / no fake conversion`.

---

## 9. ADMIN QA (PROD)

URL : `https://admin.keybuzz.io/marketing/google-tracking`

Confirmation Ludovic dans la conversation courante :
> "OK : QA Admin PROD validee sur https://admin.keybuzz.io/marketing/google-tracking. Page charge avec role autorise. Pas de 403/500. Stats visibles ou vides selon donnees PROD. Aucune action mutationnelle effectuee."

Lecture : la chain Admin v2 PROD -> BFF -> API PROD v3.5.187 fonctionne pour les roles d injection prevus (super_admin / account_manager / media_buyer). Le consumer legitime du dashboard marketing reste operationnel.

---

## 10. CLIENT QA (PROD)

URL : `https://client.keybuzz.io`

Confirmation Ludovic dans la conversation courante :
> "OK : QA Client PROD validee sur https://client.keybuzz.io. Inbox OK, Brouillon IA OK sur les cas attendus, tenant switcher OK, escalation OK, playbooks read-only OK. Aucune regression visible. Aucune action mutationnelle effectuee."

Lecture : aucune regression observable sur les flux nominaux du Client PROD. Les protections KEY-301 (tenants, notifications, AI/autopilot, AI rules/playbooks read+mutations) restent actives et n ont pas ete affectees par l ajout du checkAccess local sur google-observability.

---

## 11. PROD SERVICES UNCHANGED

| Service | Namespace | Image avant | Image apres | Restart count |
|---|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.186-ai-rules-mut-tenantguard-prod | v3.5.187-google-observability-tenantguard-prod | 0 (nouveau pod) |
| keybuzz-outbound-worker (image keybuzz-api) | keybuzz-api-prod | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | 7 (dernier 2026-04-29, soit 15j avant apply, hors correlation) |
| keybuzz-client | keybuzz-client-prod | v3.5.196-ai-rules-bff-prod | v3.5.196-ai-rules-bff-prod | 0 |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | 0 |

Aucun autre manifest n a ete modifie ni applique. Aucun build d autre service. Aucun docker push d autre tag.

Logs API PROD 5 minutes : 0 5xx.
Pod API PROD `keybuzz-api-546cf77fbb-tqpcl` : ready=true, restart=0.

---

## 12. ROLLBACK

Procedure en cas de regression critique decouverte :

1. `cd /opt/keybuzz/keybuzz-infra && git revert 2899e9e --no-edit`
2. `git push origin main`
3. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
4. `kubectl rollout status deploy/keybuzz-api -n keybuzz-api-prod --timeout=240s`

Tag de rollback : `ghcr.io/keybuzzio/keybuzz-api:v3.5.186-ai-rules-mut-tenantguard-prod` (image stable PROD precedente, present sur GHCR).

Impact rollback : reouvre temporairement le leak signup_attribution global sur google-observability mais restaure le comportement runtime stable AS.12.2C-5B-PROD jusqu a correction.

Rollback NON declenche : verdict GO valide.

---

## 13. LINEAR

KEY-313 reste Open (R1 outbound+compat surfaces en cours). KEY-301 reste Done. Aucun changement de statut Linear sans GO Ludovic explicite.

Texte propose pour commentaire KEY-313 (disclosure-controlled, sans PoC, sans payload, sans PII, sans gclid reel) :

```
PH-SAAS-T8.12AS.13.1-R1 PROD livre.

Runtime API PROD : v3.5.187-google-observability-tenantguard-prod
Digest GHCR : sha256:93a8f7758f340da4807a5e008daf85728dbb04a3d62a71ae920fb39f2e83b619
OCI revision : 1c8b6b18efad67a7b4795351b55f2ce37bdd2d9c

Endpoint google-observability ne renvoie plus de data globale sans headers / sans tenantId :
- sans headers : 400
- role non bypass : 403
- role admin marketing : 200 scope par tenantId (fake tenantId => empty)

DB unchanged (signup_attribution counts avant=apres). 0 5xx API PROD 5 min.
Admin v2 PROD : consumer marketing/google-tracking reste fonctionnel.
Client PROD : non-regression confirmee (Inbox, Brouillon IA, switcher, escalation, playbooks).
KEY-301 protections preservees.

KEY-313 reste Open (R1 outbound+compat) : sous-phases restantes AS.13.2 outbound/deliveries, AS.13.3 compat, AS.13.4 destinations audit confirmatif.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 14. NEXT PHASES

| Phase | Scope | Statut |
|---|---|---|
| AS.13.2 | outbound/deliveries : 5 endpoints read + 3 mutations | Design audit a faire avant patch |
| AS.13.3 | compat module : 6 endpoints proxy legacy + X-Internal-Token | Design audit en attente |
| AS.13.4 | destinations confirmatif : pattern checkAccess deja en place | Audit a documenter (probable 0 patch) |
| KEY-314 a KEY-318 (R2-R6) | autres surfaces issues du closeout KEY-301 | Backlog Linear, non bloque PROD |

Aucun de ces enchainements ne sera lance sans GO Ludovic explicite et separe.

---

## 15. VERDICTS AUTORISES

- GO GOOGLE OBSERVABILITY TENANTGUARD PROD READY (verdict retenu)
- NO GO GOOGLE OBSERVABILITY PROD ROLLBACK DONE
- NO GO ADMIN CONSUMER REGRESSION FOUND
- NO GO SOURCE DIRTY / DRIFT

---

## 16. PHRASE CIBLE FINALE

GO GOOGLE OBSERVABILITY TENANTGUARD PROD READY. KEY-313 reste Open. Aucun enchainement vers AS.13.2 sans GO Ludovic.

STOP.
