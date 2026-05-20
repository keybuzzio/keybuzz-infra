# PH-SAAS-T8.12AS.19.7-REGISTER-STATE-PERSISTENCE-TRAIN-PROD-01

> Date : 2026-05-20
> Linear : KEY-335 follow-up ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.7-REGISTER-STATE-PERSISTENCE-TRAIN-PROD (build PROD + push GHCR + apply PROD consolide)
> Environnement : PROD GitOps train integre (apres validation QA DEV)

## VERDICT

GO TRAIN PROD REGISTER STATE PERSISTENCE READY PH-SAAS-T8.12AS.19.7

- keybuzz-infra HEAD avant TRAIN PROD : `d5944a3` -> apres : `a926ee7` (apply PROD `ops(client-prod): promote v3.5.199-register-state-persistence-prod`)
- Client PROD runtime : `v3.5.199-register-state-persistence-prod` digest `sha256:dbeb9d53966d71949f723a1eac1266e56dd557e6dab6df16916c29e46651720a` (pod 72tbd Ready 1/1, 0 restart)
- Smoke /register PROD HTTP 200, API PROD /health HTTP 200
- DEV preserve (Client DEV `v3.5.205`, API DEV `v3.5.251`)
- API PROD + Website PROD inchange
- AUCUN kubectl set/patch/edit (GitOps strict)

## CONTENU DU BUNDLE PROD (PH-19.3 a PH-19.7 consolide)

Promotion PROD bundle complet register CRO accumule sur commits source :
- PH-19.3 lead-first tunnel (commit `397687a` deja en DEV historique)
- PH-19.4 QA fix selection plan + invalid_marketing_owner_tenant_id fallback (commit `d363c38`)
- PH-19.5 autopilot trial copy (commit `fc4a43e`)
- PH-19.6 CGU state fix + copy F.9 custom 0 EUR (commit `bae77de`)
- PH-19.7 state persistence draft sessionStorage (commit `8553bad`)

Le commit source PROD = `8553bad` (tete de chaine). Tous les patches anterieurs sont inclus.

## PIPELINE TRAIN PROD

| Etape | Resultat |
|---|---|
| Baseline PROD pre-promotion | `v3.5.198-debug-env-disabled-prod` (digest `sha256:0b96435cdc2b5d56e42c3fbce8da65901956d09275688885b4bf9c72e70c2faa`, revision `f61763a`) |
| Inventaire baseline PROD | GA4 / Meta / TikTok / SGTM tous omis (0 occurrence chunk live) ; Clarity 0 |
| GHCR collision check pre-build | tag FREE (manifest unknown x2) |
| Worktree detach PROD | `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.7-PROD/keybuzz-client` HEAD = `8553bad` clean |
| Docker build PROD | Image ID `sha256:6da61383ce9e8b0186ed78428950f185711558e2c3a4e2ba325feb374aa3984f` 280 MB |
| Build args PROD | NEXT_PUBLIC_APP_ENV=**production**, NEXT_PUBLIC_API_URL=**https://api.keybuzz.io**, NEXT_PUBLIC_API_BASE_URL=**https://api.keybuzz.io**, LINKEDIN=9969977, marketing IDs omis (iso baseline v3.5.198) |
| OCI labels KEY-308 | 5/5 (revision `8553bad`, created `2026-05-20T20:23:29Z`) |
| Bundle PROD isolation KEY-263 | 87 `api.keybuzz.io` / **0** `api-dev.keybuzz.io` |
| Pattern PH-19.7 nouveau | `kb_signup_form_draft_v1` 2 (SSR + chunk) |
| Patterns PH-19.6 preserves | `kb_signup_cgu_accepted` 2, `register-cgu-accepted-note` 2, `register-cgu-plan-checkbox` 2, `0 EUR pendant 14 jours` 4, `Carte demandee a l` 2, `Voir les CGU` 2 |
| Non-regression PH-19.3+19.4 | register-lead-shell/reassurance-panel/confirm-plan/autopilot-trial-note 2/2/2/2, data-selected 2, aria-pressed 2, invalid_marketing_owner_tenant_id 2, "Le plus populaire" 7, Autopilot 127 |
| `data-clarity-mask` | 26 PII preserves |
| Clarity (clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx) | 0 / 0 / 0 |
| AW- direct | 0 |
| GA4 G-XXXX / Meta fbq / TikTok ttq / SGTM | 0 / 0 / 0 / 0 (iso baseline v3.5.198) |
| `plan_selected` | 4 refs bundle (1 source unique) |
| Vieux patterns supprimes ("tout le monde teste Autopilot" / "CB requise a cette etape") | 0 / 0 |
| Docker push GHCR | exit 0 |
| Manifest digest GHCR | `sha256:dbeb9d53966d71949f723a1eac1266e56dd557e6dab6df16916c29e46651720a` (size 2631) |
| Config digest match Image ID local | OK `sha256:6da61383ce9e...` |
| Repo digest pulled-back | `ghcr.io/keybuzzio/keybuzz-client@sha256:dbeb9d53966d...` |
| Layers | 11 (5 nouveaux + 6 reutilises) |
| Bump manifest k8s/keybuzz-client-prod/deployment.yaml (l.76) | 1 ligne (v3.5.198 -> v3.5.199) |
| Dry-run server PROD | OK (deployment.apps/keybuzz-client configured server dry run) |
| Infra commit | `a926ee7` (`ops(client-prod): promote v3.5.199-register-state-persistence-prod`) |
| Infra push | `d5944a3..a926ee7 main -> main` |
| kubectl apply PROD | OK (deployment.apps/keybuzz-client configured) |
| Rollout PROD | successfully rolled out |
| Pod PROD | `keybuzz-client-7b5f69dbfd-72tbd` Ready 1/1, 0 restart |
| Runtime digest pod PROD | `sha256:dbeb9d53966d71949f723a1eac1266e56dd557e6dab6df16916c29e46651720a` (match GHCR) |
| Smoke /register PROD | HTTP 200 (9188 bytes) sur `https://client.keybuzz.io/register?plan=pro&cycle=monthly` |
| Smoke API PROD /health | HTTP 200 |
| Rollback tag PROD | `v3.5.198-debug-env-disabled-prod` digest `sha256:0b96435cdc2b5d56e42c3fbce8da65901956d09275688885b4bf9c72e70c2faa` |

## QA AUTOMATISABLE PROD (post-apply)

| Indicateur | Valeur |
|---|---|
| Pod PROD age | 7m34s Ready 1/1, 0 restart, node k8s-worker-01 |
| Smoke /register?plan=starter | HTTP 200 |
| Smoke /register?plan=pro | HTTP 200 |
| Smoke /register?plan=autopilot | HTTP 200 |
| Smoke API PROD /health | HTTP 200 |
| Chunk register page live PROD | `/_next/static/chunks/app/register/page-f7808baeb00480d2.js` (75112 bytes, identique au DEV chunk hash = build deterministe iso commit `8553bad`) |
| PH-19.7 chunk live PROD `kb_signup_form_draft_v1` | 1 |
| PH-19.6 chunk live PROD (kb_signup_cgu_accepted, register-cgu-accepted-note, register-cgu-plan-checkbox, 0 EUR, Carte demandee, Voir les CGU) | tous 1 |
| Non-regression chunk live PROD (register-lead-shell, register-confirm-plan, data-selected, aria-pressed, invalid_marketing_owner_tenant_id) | tous 1 |
| Clarity (clarity.ms / NEXT_PUBLIC_CLARITY / AW-) | 0 / 0 / 0 |

## NON-REGRESSION POST-APPLY PROD

| Service | Image | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-prod | **v3.5.199-register-state-persistence-prod** (nouveau) | 1/1 | OK promotion appliquee |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |
| keybuzz-client-dev | v3.5.205-register-state-persistence-dev | 1/1 | DEV preserve |
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | DEV preserve |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | 1/1 | DEV preserve |

## CONFIRMATIONS

- AUCUN kubectl set image / set env / patch / edit (GitOps strict)
- AUCUN changement source API/Backend/Admin/Studio/Website/Stripe/Vault/ESO
- AUCUN secret expose
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN Linear ticket close
- Bastion install-v3 (46.62.171.61) uniquement
- Build-from-git worktree detache propre

## PROMESSES BILLING/STRIPE A VALIDER QA FONCTIONNEL PROD

| Promesse copy F.9 | Verification requise | Statut |
|---|---|---|
| "0 EUR pendant 14 jours" | Stripe checkout-session `trial_period_days=14`, absence capture pre-trial | A confirmer Stripe Dashboard PROD apres signup test |
| "Aucun debit avant la fin de l essai" | Idem | A confirmer |
| "le plan selectionne devient actif si vous continuez" | API `tenants.trial_entitlement_plan -> tenants.plan` switch a J+14 via Stripe webhook | A confirmer logs API PROD apres trial J+14 simule |
| "Vous pouvez changer de plan ou annuler avant cette date" | UI Facturation client.keybuzz.io/settings/billing accessible + endpoint update/cancel pendant trial | A confirmer Settings/Billing operationnel |

## ROLLBACK PROD GitOps STRICT

1. Editer `k8s/keybuzz-client-prod/deployment.yaml` -> image `v3.5.198-debug-env-disabled-prod` (digest `sha256:0b96435cdc2b...`)
2. `git add + commit -m "ops(client-prod): ROLLBACK PH-19.7 to v3.5.198"`
3. `git push origin main`
4. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`
5. `kubectl rollout status -n keybuzz-client-prod deploy/keybuzz-client --timeout=300s`
6. Verifier runtime digest = `sha256:0b96435cdc2b...`

INTERDIT : kubectl set image, git reset --hard, git clean.

## BROUILLONS LINEAR (NON postes ; reauth Codex 401)

> **KEY-335 (primary)** : PROMOTION PROD complete. Client PROD runtime = v3.5.199-register-state-persistence-prod, digest sha256:dbeb9d53966d71949f723a1eac1266e56dd557e6dab6df16916c29e46651720a. Pod 72tbd Ready 1/1. Bundle complet register CRO PH-19.3 a PH-19.7 (lead-first + selection plan QA fix + autopilot trial copy + CGU state fix + copy F.9 0 EUR + state persistence draft). Infra commit a926ee7. Smoke /register HTTP 200 + API /health 200. API PROD + Website PROD inchange. DEV preserve.

> **KEY-334 / KEY-329** : Tunnel lead-first + benchmark signup live PROD avec wording factuel SaaS pro.

> **KEY-325** : Clarity client toujours absent PROD (iso baseline v3.5.198 + decision KEY-325 preserve). 26 data-clarity-mask PII preserves.

> **KEY-330 / KEY-331** : No fake events. plan_selected unique. Marketing IDs GA4/Meta/TikTok/SGTM toujours omis (decision distincte si reactivation -> phase KEY-XXX-NEW).

## GAPS

1. Cleanup sessionStorage `kb_signup_form_draft_v1` post-success Stripe PROD non implemente. sessionStorage scope tab, expire a fermeture. A traiter en PH-19.x ulterieure si Ludovic veut cleanup explicite.
2. Lead draft server-side (RGPD + table signup_drafts + endpoint) : recommandation PH-19.8 documente dans rapport PH-19.7 SOURCE. NON applique.
3. Activation marketing IDs (GA4 G-R3QQDYEBFG, Meta 1234164602194748, TikTok D7PT12JC77U44OJIPC10, SGTM t.keybuzz.pro) reste decision distincte. Build PROD a OMIS (iso baseline v3.5.198 -> conserve l absence de tracking ads telle quelle).
4. QA visuelle Ludovic PROD requise pour valider visuellement le flow complet (scenarios A/B/C/D documentes dans la conversation).
5. Worktrees `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.7/keybuzz-client` (DEV) et `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.7-PROD/keybuzz-client` restent sur disque. Cleanup possible post-validation.

## VERDICT FINAL

GO TRAIN PROD REGISTER STATE PERSISTENCE READY PH-SAAS-T8.12AS.19.7

| Indicateur | Valeur |
|---|---|
| keybuzz-infra HEAD apres TRAIN PROD | a926ee7 |
| Client PROD runtime tag | v3.5.199-register-state-persistence-prod |
| Client PROD runtime digest | sha256:dbeb9d53966d71949f723a1eac1266e56dd557e6dab6df16916c29e46651720a |
| Source commit | 8553bad (bundle PH-19.3 a PH-19.7) |
| Smoke /register PROD | HTTP 200 (3 plans testes) |
| Smoke API PROD /health | HTTP 200 |
| API PROD | v3.5.250-ad-spend-sync-all-prod INCHANGE |
| Website PROD | v0.6.18-ga4-cleanup-prod 2/2 INCHANGE |
| DEV preserve | Client DEV v3.5.205 + API DEV v3.5.251 |
| NO kubectl set/patch/edit | OK |
| Marketing IDs reactivation | NON (decision distincte) |
| Rollback prep | tag v3.5.198-debug-env-disabled-prod digest sha256:0b96435cdc2b... |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.7-REGISTER-STATE-PERSISTENCE-TRAIN-PROD-01.md |

STOP.
