# PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-APPLY-PROD-01

> Date : 2026-05-21
> Linear : KEY-343 (primary) ; KEY-342, KEY-345 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.5 BILLING TENANT_ID FALLBACK APPLY PROD
> Environnement : GitOps strict PROD / aucun build / aucun docker push / aucun test mutant

## VERDICT

GO APPLY API BILLING TENANT_ID FALLBACK PROD READY PH-SAAS-T8.12AS.20.5

- Manifest `k8s/keybuzz-api-prod/deployment.yaml` bumpe v3.5.250-ad-spend-sync-all-prod -> v3.5.251-billing-tenant-id-fallback-prod.
- Infra commit `23f6084` push origin/main.
- kubectl apply : `deployment.apps/keybuzz-api configured`.
- Rollout : `deployment "keybuzz-api" successfully rolled out`.
- Pod nouveau : `keybuzz-api-5fc84764-fnnqq` Ready, Running.
- Runtime digest PROD : `sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8` MATCH GHCR push.
- last-applied annotation = runtime = manifest = `v3.5.251-billing-tenant-id-fallback-prod`.
- Code patch present dans `/app/dist/modules/auth/tenant-context-routes.js` du pod PROD live.
- Logs startup : 0 erreur PH-20.5, aucun "Generated tenantId rejected by regex" deploy depuis (normal, aucun new register avec nom invalide).
- Runtime API DEV `v3.5.252-billing-tenant-id-fallback-dev` INCHANGE.
- Runtime Client + Website + Admin DEV+PROD INCHANGES.
- AUCUN test register PROD mutant. AUCUN checkout Stripe live. AUCUNE mutation DB.

**Cause racine KEY-343 corrigee en PROD**. Le bug Antoine est resolu live : un nouveau user avec name societe = caracteres non-alphanumeriques uniquement obtiendra desormais un tenantId valide `tenant-XXXX` (au lieu de `-XXXX` malforme).

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 18:14 |
| Uname | Linux install-v3 6.8.0-88-generic x86_64 |
| keybuzz-api branche/HEAD | ph147.4/source-of-truth / 6850427c (PH-20.5 source) |
| keybuzz-api dirty | 223 (dist/ deletions preexistant connu hors scope) |
| keybuzz-infra branche/HEAD avant | main / 02bd7f4 (rapport PUSH IMAGE PROD) |
| keybuzz-infra dirty | 0 |
| Runtime API DEV avant | v3.5.252-billing-tenant-id-fallback-dev |
| Runtime API PROD avant | v3.5.250-ad-spend-sync-all-prod |

## E1 GHCR IMAGE PROD VERIFY

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod |
| schemaVersion | 2 |
| config.digest | sha256:867ecc25a0bbf00430a0f24388625de0ef7aaf0b7f7a481afeaba13bb1603042 |
| layers count | 10 |
| Manifest digest attendu pull | sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8 |

## E2 BUMP MANIFEST + DRY-RUN

| Etape | Resultat |
|---|---|
| Substitution Python regex sur k8s/keybuzz-api-prod/deployment.yaml | count = 1 |
| diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image line (l.106) apres bump | `image: ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod` + annotation PH-20.5 |
| Annotation commentaire | commit api 6850427c, KEY-343 fix tenantId malforme, fallback + defense regex, cas Antoine prevenu, tsc 0 + 10/10 tests + E2E DEV OK, layers 10/10 reused, rollback v3.5.250, digest |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-api configured (server dry run)` |

## E3 COMMIT + PUSH INFRA

| Item | Valeur |
|---|---|
| Scope | k8s/keybuzz-api-prod/deployment.yaml (1 fichier) |
| Commit | 23f6084 ops(api-prod): deploy v3.5.251-billing-tenant-id-fallback-prod |
| Push | OK 02bd7f4..23f6084 main -> main |

## E4 KUBECTL APPLY + ROLLOUT

```
deployment.apps/keybuzz-api configured
Waiting for deployment "keybuzz-api" rollout to finish: 0 out of 1 new replicas have been updated...
Waiting for deployment "keybuzz-api" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-api" successfully rolled out
```

| Item | Valeur |
|---|---|
| kubectl apply | OK configured |
| Rollout duration | ~30-45s |
| Pod new | keybuzz-api-5fc84764-fnnqq |
| Pod ready | true |
| Pod status | Running |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8 |
| Match GHCR push digest | **OK** |
| Ancien pod (terminated) | keybuzz-api-6489854c9b-fkd96 (digest sha256:93cc663d... = v3.5.250 ancien) |

## E5 MANIFEST = LAST-APPLIED = RUNTIME

| Item | Valeur |
|---|---|
| Deployment spec.image | ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod |
| Last applied configuration image | ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod |
| Pod runtime imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8 |
| Triple match (manifest = last-applied = runtime) | **OK** |
| readyReplicas | 1 |
| updatedReplicas | 1 |
| replicas | 1 |

## E6 CODE PATCH VERIFY DANS POD RUNTIME

Audit `/app/dist/modules/auth/tenant-context-routes.js` dans le pod PROD live.

| Pattern | Resultat dans pod runtime | Verdict |
|---|---|---|
| Commentaires `PH-SAAS-T8.12AS.20.5` | 2 occurrences | OK |
| Fallback `\|\| 'tenant'` (slug) | 1 occurrence | OK |
| Fallback `\|\| \`tenant-` (autre route hors scope existant) | 1 occurrence | OK preexistant |
| Regex `[a-zA-Z0-9][a-zA-Z0-9_-]{2,49}` (defense + tenantSlug) | 2 occurrences | OK |
| Log `Generated tenantId rejected by regex` | 1 occurrence | OK |

Patch live dans pod PROD. Le fix Antoine est actif.

## E7 SMOKE NON-MUTANT + LOGS

| Item | Resultat | Verdict |
|---|---|---|
| Deploy status | 1/1 UP-TO-DATE AVAILABLE 121d | OK |
| Logs startup 5m - erreurs PH-20.5 | aucune | OK |
| Logs startup 5m - 1 warning | `[AIJournal] Could not ensure table` "must be owner of table ai_journal_events" | OK preexistant (historique connu, sans rapport PH-20.5) |
| Logs startup 5m - cron | `[OCTOPIA-SYNC] Completed: tenants=0 imported=0 skipped=0 errors=0` | OK |
| Logs `Generated tenantId rejected by regex` | aucun depuis deploy | OK (normal : aucun new register avec nom invalide depuis ~10 min) |

AUCUN test register PROD execute. AUCUN appel create-signup PROD. AUCUN appel checkout-session PROD. AUCUN appel Stripe.

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | **v3.5.251-billing-tenant-id-fallback-prod** | **NOUVEAU PROD** |
| keybuzz-api-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | INCHANGE (worker separe, hors scope PH-20.5) |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api-outbound-worker | keybuzz-api-dev | v3.5.165-escalation-flow-dev | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.19-cta-tracking-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-media-buyer-lp-domain-qa-* | INCHANGE |

## NO FAKE METRICS / NO FAKE EVENTS

- AUCUN test register PROD mutant execute.
- AUCUN appel create-signup PROD via curl ou navigateur.
- AUCUN appel checkout-session PROD.
- AUCUN appel Stripe API.
- AUCUN event Lead/Purchase/StartTrial/CompletePayment fabrique.
- AUCUN pixel Meta/TikTok/LinkedIn touche.
- AUCUNE mutation tracking GA4/CAPI.
- AUCUNE mutation DB PROD.

Validation fonctionnelle full-path = DEV E2E (deja valide PH-20.5 APPLY DEV). PROD = digest match + code patch visible runtime + health non-mutant.

## CONFIRMATIONS SECURITE

- AUCUN docker build supplementaire (image deja construite en BUILD PROD + push en PUSH IMAGE PROD).
- AUCUN DEV touche (Website + Client + Admin + API DEV INCHANGES).
- AUCUN `kubectl set image / set env / patch / edit` (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUNE mutation DB PROD.
- AUCUN ticket Linear cree, ferme, ou statut modifie.
- Tenant orphan PROD `-mpfmgx09` Antoine NON TOUCHE (cleanup PH-20.7 separe avec GO explicite + confirmation Antoine).
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK GitOps STRICT PROD

Si regression observee :

1. Editer `k8s/keybuzz-api-prod/deployment.yaml` -> image `v3.5.250-ad-spend-sync-all-prod`.
2. `git add + commit -m "ops(api-prod): ROLLBACK PH-20.5 to v3.5.250"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-api-prod deploy/keybuzz-api --timeout=300s`.
6. Verify runtime digest = ancien.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. Branche `existingPending` (UPDATE tenant existant en `pending_payment`) reste non patchee dans le code. Les tenantId malformes deja en DB PROD orphan ne sont pas mutes. Concretement : si Antoine retente register sans cleanup, son `existingPending` `-mpfmgx09` sera reuse -> checkout-session retournera toujours 400. Mitigation = cleanup PH-20.7 separe avec GO destructif explicite + confirmation Antoine.
2. Tenant orphan PROD `-mpfmgx09` reste en DB status `pending_payment`. Pas bloquant pour les nouveaux users.
3. PROD validation E2E (create-signup + checkout-session avec name=@@@) non executee par decision : aucun test register mutant en PROD. La validation E2E PROD attend QA navigateur Ludovic OU prochaine inscription naturelle avec nom societe invalide (les logs montreront alors le succes du fix).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY API BILLING TENANT_ID FALLBACK PROD READY PH-SAAS-T8.12AS.20.5 |
| keybuzz-infra HEAD apres apply | 23f6084 (ops manifest PROD) |
| API PROD runtime tag | v3.5.251-billing-tenant-id-fallback-prod |
| API PROD runtime digest | sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8 |
| Pod | keybuzz-api-5fc84764-fnnqq Ready 1/1 |
| Source commit API | 6850427c |
| Code patch visible runtime | OK (2 commentaires + fallback + regex defense + log) |
| Triple match manifest=last-applied=runtime | OK |
| Logs startup erreurs PH-20.5 | aucune |
| API DEV runtime | v3.5.252-billing-tenant-id-fallback-dev INCHANGE |
| Client+Website+Admin DEV+PROD | INCHANGES |
| GitOps strict | OK (commit -> push -> apply -f -> rollout, NO kubectl set/patch/edit) |
| Rollback tag PROD | v3.5.250-ad-spend-sync-all-prod |
| Tenant orphan PROD `-mpfmgx09` | NON TOUCHE (PH-20.7) |
| Cause racine KEY-343 | **CORRIGEE LIVE PROD** |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-APPLY-PROD-01.md` |

### Prochaine phase (apres validation Ludovic separee)

Phases possibles autorisees par GO Ludovic separes :

- `GO PATCH REGISTER ACCENTS + 0EUR + UX BILLING ERROR SOURCE PH-SAAS-T8.12AS.20.6` (Client polish bundle KEY-342 + KEY-345 + KEY-343 C4 UX)
- `GO CLEANUP TENANT_ID ORPHAN PROD PH-SAAS-T8.12AS.20.7` (uniquement avec GO destructif explicite + confirmation Antoine ; necessaire pour qu Antoine puisse re-inscrire et obtenir un nouveau tenantId valide)
- `GO QA REGISTER BILLING PROD PH-SAAS-T8.12AS.20.5` (QA navigateur Ludovic Stripe LIVE test, prudence requise)

STOP.
