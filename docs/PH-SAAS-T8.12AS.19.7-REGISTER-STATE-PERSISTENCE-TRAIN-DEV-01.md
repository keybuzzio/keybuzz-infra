# PH-SAAS-T8.12AS.19.7-REGISTER-STATE-PERSISTENCE-TRAIN-DEV-01

> Date : 2026-05-20
> Linear : KEY-335 follow-up ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.7-REGISTER-STATE-PERSISTENCE-TRAIN-DEV (build + push GHCR + apply DEV consolide)
> Environnement : DEV GitOps train integre

## VERDICT

GO TRAIN DEV REGISTER STATE PERSISTENCE READY PH-SAAS-T8.12AS.19.7

- keybuzz-infra HEAD avant TRAIN : `4b2c679` -> apres : `d5944a3` (apply DEV `ops(client-dev): deploy v3.5.205-register-state-persistence-dev`)
- Client DEV runtime : `v3.5.205-register-state-persistence-dev` digest `sha256:be24d91500c21ee752b15d260a1ad16a24b67973918453bc17fed80ce1b23621` (pod zlkhv Ready 1/1, 0 restart)
- API DEV runtime : `v3.5.251-register-cro-dev` INCHANGE
- Smoke /register HTTP 200, API /health HTTP 200
- PROD inchange a ce stade (3/3 deployments)
- AUCUN kubectl set/patch/edit (GitOps strict)

## PIPELINE TRAIN DEV

| Etape | Resultat |
|---|---|
| GHCR collision check pre-build | tag FREE (manifest unknown x2) |
| Worktree detach | `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.7/keybuzz-client` HEAD = `8553bad` clean |
| Docker build DEV | Image ID `sha256:c4d7bf6b035d769a778ffa295ecdb41ee9c1c6e1edde3fc5c0549ab7f9871e22` 280 MB |
| Build args | NEXT_PUBLIC_APP_ENV=development, NEXT_PUBLIC_API_URL=api-dev.keybuzz.io, marketing IDs omis (iso baseline) |
| OCI labels KEY-308 | 5/5 (revision `8553bad`, created `2026-05-20T20:00:35Z`) |
| Bundle DEV isolation KEY-263 | 87 `api-dev.keybuzz.io` / **0** `api.keybuzz.io` |
| Pattern PH-19.7 nouveau | `kb_signup_form_draft_v1` 2 (SSR + chunk) |
| Patterns PH-19.6 preserves | `kb_signup_cgu_accepted` 2, `register-cgu-accepted-note` 2, `register-cgu-plan-checkbox` 2, `0 EUR pendant 14 jours` 4, `Carte demandee a l` 2, `Voir les CGU` 2 |
| Non-regression PH-19.3+19.4 | register-lead-shell/reassurance-panel/confirm-plan/autopilot-trial-note 2/2/2/2, data-selected 2, aria-pressed 2, invalid_marketing_owner_tenant_id 2, "Le plus populaire" 7 |
| `data-clarity-mask` | 26 PII preserves |
| Clarity (clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx) | 0 / 0 / 0 |
| AW- direct | 0 |
| `plan_selected` | 4 refs bundle (1 source unique) |
| Docker push GHCR | exit 0 |
| Manifest digest GHCR | `sha256:be24d91500c21ee752b15d260a1ad16a24b67973918453bc17fed80ce1b23621` (size 2631) |
| Config digest match Image ID local | OK `sha256:c4d7bf6b035d...` |
| Repo digest pulled-back | `ghcr.io/keybuzzio/keybuzz-client@sha256:be24d91500c2...` |
| Layers | 11 |
| Bump manifest k8s/keybuzz-client-dev/deployment.yaml | 1 ligne (v3.5.204 -> v3.5.205) |
| Dry-run server | OK (deployment.apps/keybuzz-client configured server dry run) |
| Infra commit | `d5944a3` (`ops(client-dev): deploy v3.5.205-register-state-persistence-dev`) |
| Infra push | `4b2c679..d5944a3 main -> main` |
| kubectl apply DEV | OK (deployment.apps/keybuzz-client configured) |
| Rollout DEV | successfully rolled out |
| Pod DEV | `keybuzz-client-7dfc6cf6c8-zlkhv` Ready 1/1, 0 restart |
| Runtime digest pod DEV | `sha256:be24d91500c21ee752b15d260a1ad16a24b67973918453bc17fed80ce1b23621` (match GHCR) |
| Smoke /register DEV | HTTP 200 (9188 bytes) |
| Smoke API DEV /health | HTTP 200 |
| Rollback tag DEV | `v3.5.204-register-cgu-and-copy-dev` digest `sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3` |

## QA AUTOMATISABLE DEV (post-apply)

| Indicateur | Valeur |
|---|---|
| Smoke /register?plan=starter | HTTP 200 |
| Smoke /register?plan=pro | HTTP 200 |
| Smoke /register?plan=autopilot | HTTP 200 |
| Smoke API DEV /health | HTTP 200 |
| Chunk register page live | `/_next/static/chunks/app/register/page-f7808baeb00480d2.js` (75112 bytes) |
| PH-19.7 chunk live `kb_signup_form_draft_v1` | 1 |
| PH-19.6 chunk live (kb_signup_cgu_accepted, register-cgu-accepted-note, register-cgu-plan-checkbox, 0 EUR, Carte demandee, Voir les CGU) | tous 1 |
| Non-regression chunk live (register-lead-shell, register-confirm-plan, data-selected, aria-pressed, invalid_marketing_owner_tenant_id) | tous 1 |
| Clarity (clarity.ms / NEXT_PUBLIC_CLARITY / AW-) | 0 / 0 / 0 |

## NO FAKE METRICS / NO FAKE EVENTS

- plan_selected preserve unique cote source (1 emit canonique).
- Aucun nouvel event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout ajoute.
- Aucun tag AW-XXXXXXXXXX direct.
- PH-19.7 ne modifie aucune logique tracking (uniquement state persistence sessionStorage Client).
- Clarity client toujours non activee.
- Aucune PII envoyee a GA4/Meta/TikTok/Ads (trackSignupStep recoit uniquement plan + cycle).

## CONFIRMATIONS

- AUCUN docker push autre que v3.5.205-register-state-persistence-dev
- AUCUN deploy PROD a ce stade
- AUCUN kubectl set/patch/edit (GitOps strict)
- AUCUN changement source API/Backend/Admin/Studio/Website/Stripe/Vault/ESO
- AUCUN secret expose
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN Linear ticket close
- Bastion install-v3 (46.62.171.61) uniquement

## ROLLBACK GitOps STRICT DEV

1. Editer `k8s/keybuzz-client-dev/deployment.yaml` -> image `v3.5.204-register-cgu-and-copy-dev` (digest `sha256:17a31829c644...`)
2. `git add + commit -m "ops(client-dev): ROLLBACK PH-19.7 to v3.5.204"`
3. `git push origin main`
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`
5. `kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s`

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. Cleanup sessionStorage `kb_signup_form_draft_v1` post-success Stripe non implemente (sessionStorage scope tab, expire a fermeture). A traiter en PH-19.x ulterieure si Ludovic veut cleanup explicite.
2. Recommandation PH-19.8 lead draft server-side (RGPD + table signup_drafts + endpoint) documente dans `PH-SAAS-T8.12AS.19.7-REGISTER-STATE-PERSISTENCE-SOURCE-01.md`.
3. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis DEV (iso baseline v3.5.204).
4. Clarity activation client.keybuzz.io reste decision post-QA.

## VERDICT FINAL

GO TRAIN DEV REGISTER STATE PERSISTENCE READY PH-SAAS-T8.12AS.19.7

| Indicateur | Valeur |
|---|---|
| keybuzz-infra HEAD apres TRAIN | d5944a3 |
| Client DEV runtime tag | v3.5.205-register-state-persistence-dev |
| Client DEV runtime digest | sha256:be24d91500c21ee752b15d260a1ad16a24b67973918453bc17fed80ce1b23621 |
| Source commit | 8553bad |
| Smoke /register DEV | HTTP 200 (3 plans testes) |
| Smoke API DEV /health | HTTP 200 |
| API DEV | v3.5.251-register-cro-dev INCHANGE |
| PROD (a ce stade) | inchange (3/3) |
| NO kubectl set/patch/edit | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.7-REGISTER-STATE-PERSISTENCE-TRAIN-DEV-01.md |

STOP.
