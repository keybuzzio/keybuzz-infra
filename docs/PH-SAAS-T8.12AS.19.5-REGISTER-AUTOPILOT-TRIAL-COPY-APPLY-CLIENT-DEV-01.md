# PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-APPLY-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-APPLY-CLIENT-DEV
> Environnement : DEV GitOps apply only

## VERDICT

GO APPLY CLIENT REGISTER AUTOPILOT TRIAL COPY DEV READY PH-SAAS-T8.12AS.19.5

- keybuzz-infra HEAD : `ee20acf` (ops(client-dev): deploy v3.5.203-register-autopilot-trial-copy-dev)
- Client DEV runtime : `v3.5.203-register-autopilot-trial-copy-dev` digest `sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9` (pod 8gwtc Ready 1/1, 0 restart)
- API DEV runtime : `v3.5.251-register-cro-dev` (INCHANGE, candidate preserve)
- Smoke /register HTTP 200, API /health HTTP 200
- PROD inchange (3/3 deployments)
- NO BUILD, NO DOCKER PUSH, NO kubectl set/patch/edit

Prochaine phrase GO attendue : GO QA REGISTER AUTOPILOT TRIAL COPY DEV PH-SAAS-T8.12AS.19.5

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-infra HEAD pre | dfb5e94 (origin=local) | OK |
| 2 rapports PH-19.5 untracked attendus | BUILD + PUSH-IMAGE | OK |
| GHCR config digest verify | sha256:faa09d39e47d... | OK match expected |

## RUNTIME AVANT APPLY

| Service | DEV image avant | PROD image | Verdict |
|---|---|---|---|
| keybuzz-client | v3.5.202-register-qa-fix-dev | v3.5.198-debug-env-disabled-prod | OK |
| keybuzz-api | v3.5.251-register-cro-dev | v3.5.250-ad-spend-sync-all-prod | preserve |
| keybuzz-website | v0.6.18-ga4-cleanup-dev | v0.6.18-ga4-cleanup-prod | preserve |

## MANIFEST MODIFIE

| Fichier | Avant | Apres | Diff |
|---|---|---|---|
| k8s/keybuzz-client-dev/deployment.yaml (l.77) | image v3.5.202-register-qa-fix-dev | image v3.5.203-register-autopilot-trial-copy-dev | 1 ligne (image + commentaire PH-19.5 + rollback + digest) |

Commentaire manifest :
- phase PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-APPLY-CLIENT-DEV (2026-05-20)
- commit Client fc4a43e
- KEY-335 copy clarifie l essai sur Autopilot (panneau lateral + bloc 3 etapes + titre + encart principal + CTA footer)
- copy concrets : "Essai 14 jours sur Autopilot, puis bascule sur le plan choisi" + "14 jours d essai gratuit sur Autopilot - puis bascule sur le plan choisi" + "Pendant l essai, tout le monde teste Autopilot" + "Vous pouvez changer ou resilier pendant l essai"
- KEY-334 tunnel lead-first preserve (register-lead-shell + register-reassurance-panel + register-confirm-plan)
- KEY-329 + KEY-333 benchmark signup preserve sans copie
- KEY-325 data-clarity-mask preserve (Clarity NON activee)
- KEY-331 plan_selected unique preserve
- KEY-330 no fake events ; no fake reviews/logos/chiffres
- attribution UTM/click IDs/_gl/promo preservee + fallback safe marketing_owner_tenant_id preserve
- rollback v3.5.202-register-qa-fix-dev (digest sha256:b2bc34a2f6c6...)
- new digest sha256:7e471e7489a4...

## ROLLBACK DIGEST PRE-PATCH

| Tag | Manifest digest GHCR |
|---|---|
| v3.5.202-register-qa-fix-dev (rollback) | sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40 |
| v3.5.203-register-autopilot-trial-copy-dev (new) | sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9 |

## DRY-RUN SERVER

| Manifest | Resultat |
|---|---|
| k8s/keybuzz-client-dev/deployment.yaml | deployment.apps/keybuzz-client configured (server dry run) |

## COMMIT INFRA + PUSH

| Etape | Valeur |
|---|---|
| files staged (3) | k8s/keybuzz-client-dev/deployment.yaml (M), docs/PH-19.5-BUILD-CLIENT-DEV-01.md (A), docs/PH-19.5-PUSH-IMAGE-CLIENT-DEV-01.md (A) |
| commit hash | ee20acf |
| commit title | ops(client-dev): deploy v3.5.203-register-autopilot-trial-copy-dev |
| insertions/deletions | +449 / -1 |
| push exit | 0 |
| origin HEAD post-push | ee20acf (dfb5e94 -> ee20acf main -> main) |

## APPLY CLIENT DEV

| Etape | Resultat |
|---|---|
| kubectl apply client-dev | deployment.apps/keybuzz-client configured |
| rollout status client-dev | successfully rolled out (timeout 300s) |
| kubectl set / patch / edit | NON utilise (GitOps strict) |

## RUNTIME APRES APPLY

| Service | Manifest tag | Runtime tag | Runtime digest pod | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-client DEV | v3.5.203-register-autopilot-trial-copy-dev | v3.5.203-register-autopilot-trial-copy-dev | sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9 | 1/1 (8gwtc) | 0 | OK manifest = tag = digest |

## SMOKE DEV /REGISTER

| Endpoint | Methode | Resultat | Verdict |
|---|---|---|---|
| https://client-dev.keybuzz.io/register?plan=starter&cycle=monthly&promo=TEST&utm_source=smoke&_gl=test&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk | GET | HTTP 200, 9188 bytes (shell client Next.js use-client hydration) | OK |
| https://api-dev.keybuzz.io/health | GET | HTTP 200 | OK |

Note SSR : page /register est rendue via use client hydration cote browser - shell HTML 9188 bytes contient `<!DOCTYPE html>` + Next.js precompiled CSS + script preload. Le nouveau copy PH-19.5 ("Essai 14 jours sur Autopilot", "14 jours d essai gratuit sur Autopilot", "Pendant l essai, tout le monde teste Autopilot", "bascule sur le plan choisi") + data-testid `register-autopilot-trial-note` + tous les patterns PH-19.3 (lead-first) + PH-19.4 (QA fix) sont dans les chunks JS lazy hydrates apres charge. Tous deja verifies bundle pre-deploy (phase BUILD-CLIENT-DEV-01). QA browser Ludovic confirmera visuellement post-apply.

Smoke avec `plan=starter` choisi explicitement : permet de valider visuellement que le copy "Essai sur Autopilot quel que soit le plan" est bien affiche meme quand l URL force un autre plan que Autopilot.

## API DEV PRESERVE (read-only)

| Cluster | Image | Ready | Verdict |
|---|---|---|---|
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE (candidate preserve) |

Aucun apply API DEV.

## NON-REGRESSION PROD

| Service | Image PROD | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | 1/1 | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |

## NO FAKE METRICS / NO FAKE EVENTS

Verifie cote source PH-19.5 + bundle BUILD-CLIENT-DEV-01 :

- plan_selected emit unique preserve dans handleSelectPlan (KEY-331) : 1 source emit, 4 refs bundle = SSR + chunks
- PH-19.5 ne modifie que le copy (text content) - aucun event ni mecanique de tracking ajoute
- Pas d event par bouton (data-cta-id register_confirm_plan_and_checkout + register_plan_select_<plan> + register_cycle_toggle restent declaratifs)
- Boutons identifiables via data-cta-id + data-plan + data-cycle + data-promo-state + data-selected + aria-pressed preserves
- Clarity client NON activee (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0 bundle)
- Aucune fake review / fake metric / fake chiffre / fake logo
- Pas d event Lead/Purchase/StartTrial/CompletePayment ajoute par PH-19.5
- Events ads existants src/lib/tracking.ts inchanges

## PROMESSE PRODUIT (factualite copy KeyBuzz)

Le copy PH-19.5 live DEV decrit le mecanisme d essai sans promesse non verifiee :
- "Essai 14 jours sur Autopilot, puis bascule sur le plan choisi" : description du mecanisme.
- "Pendant l essai, tout le monde teste Autopilot" : description du mecanisme.
- "A la fin des 14 jours, si vous continuez, KeyBuzz bascule simplement sur le plan selectionne ici" : description du mecanisme.
- "Vous pouvez changer ou resilier pendant l essai" : description du droit utilisateur.
- "CB requise a cette etape uniquement. L essai se fait sur Autopilot ; le plan choisi prend le relais apres 14 jours si vous continuez." : description du flow paiement.

Aucun chiffre/ratio non prouve, aucune fausse review, aucun faux logo, aucune promesse "zero intervention humaine".

QA produit Ludovic devra valider en navigateur que le comportement runtime materialise bien le mecanisme decrit dans le copy : le pod sert le nouveau copy mais la logique trial Autopilot a J+0 + bascule plan choisi a J+14 est cote API/Stripe/billing/trial logic (preexistant, hors scope build/deploy Client PH-19.5).

## LINEAR BROUILLONS (NON postes, token hors-chat ; reauth Codex 401)

> **KEY-335 (primary)** : PH-19.5 DEV applied. Client DEV runtime = v3.5.203-register-autopilot-trial-copy-dev, digest sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9. Pod 8gwtc Ready 1/1, 0 restart. Infra commit ee20acf. Copy register Autopilot trial deployed : panneau lateral + bloc 3 etapes + titre step plan + encart principal + CTA footer. Tunnel lead-first + QA fix preserves. Smoke /register HTTP 200 + API /health 200. PROD unchanged. STOP avant QA navigateur Ludovic. QA produit : valider que le comportement runtime materialise bien le mecanisme "essai sur Autopilot quel que soit le plan + bascule plan choisi a J+14".

> **KEY-334** : Register lead-first preserve apres copy Autopilot trial. Bundle deja verifie phase BUILD-CLIENT-DEV-01 (register-lead-shell + register-reassurance-panel + register-confirm-plan + CTAs). API DEV v3.5.251 candidate preserve. PROD inchange.

> **KEY-329** : Copy Autopilot trial clarifie le mecanisme d essai sans fake reviews/logos/chiffres. Bundle CRO live DEV ne contient toujours aucun faux signal social.

> **KEY-325 (Clarity)** : Clarity client still absent live DEV (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0 bundle). 26 data-clarity-mask PII preserves bundle.

> **KEY-330 / KEY-331** : No fake events ajoutes. plan_selected preserve unique (1 emit source canonique). PH-19.5 ne touche que le copy, aucune mecanique tracking modifiee. Events ads browser-side preexistants tracking.ts inchanges.

## CONFIRMATIONS NO BUILD / NO DOCKER PUSH

- AUCUN docker build
- AUCUN docker push (tag GHCR v3.5.203 deja pousse phase PUSH-IMAGE-CLIENT-DEV-01)
- AUCUN deploy PROD
- AUCUN kubectl set image / set env / patch / edit
- AUCUN apply API DEV (manifest API DEV inchange)
- AUCUN apply Website
- AUCUN changement source Client/API (commit fc4a43e deja pousse)
- AUCUN changement Admin / Backend / Studio / Stripe / Vault / ESO
- AUCUN secret expose dans logs
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN Linear ticket close
- Bastion install-v3 (46.62.171.61) uniquement

## ROLLBACK GitOps STRICT

Si necessaire, rollback strict GitOps :

1. Editer k8s/keybuzz-client-dev/deployment.yaml -> image v3.5.202-register-qa-fix-dev (digest sha256:b2bc34a2f6c6...)
2. git add + commit -m "ops(client-dev): ROLLBACK PH-19.5 to v3.5.202"
3. git push origin main
4. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
5. kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s
6. Verifier runtime digest = sha256:b2bc34a2f6c6...

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. HTML SSR /register reste vide en checks bruts (Next.js use client hydration) - QA visuelle browser Ludovic requise pour confirmer (a) panneau lateral "Essai 14 jours sur Autopilot, puis bascule sur le plan choisi" visible first screen, (b) bloc 3 etapes mentionne "Pendant 14 jours, vous testez Autopilot", (c) titre step plan "14 jours d essai gratuit sur Autopilot - puis bascule sur le plan choisi.", (d) encart principal "Pendant l essai, tout le monde teste Autopilot" + paragraphe explicatif, (e) CTA footer "CB requise... L essai se fait sur Autopilot ; le plan choisi prend le relais apres 14 jours si vous continuez."
2. Comportement produit "essai sur Autopilot quel que soit le plan" + "bascule plan choisi a J+14" : a valider cote API/Stripe/billing/trial logic. Cette validation est hors scope build/deploy Client PH-19.5 (cote keybuzz-api + Stripe checkout-session + tenants.trial_entitlement_plan + signup_attribution).
3. Events ads browser-side preexistants - decision KEY-330/KEY-331 a confirmer.
4. Email logo template magic-link `client.keybuzz.io/branding/...` preexistant hors scope.
5. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build DEV (iso baseline v3.5.202 matching).
6. Clarity activation client.keybuzz.io reste decision post-QA.
7. Worktree build `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.5/keybuzz-client` reste sur disque : cleanup possible apres eventuelle phase PROD.

## VERDICT FINAL

GO APPLY CLIENT REGISTER AUTOPILOT TRIAL COPY DEV READY PH-SAAS-T8.12AS.19.5

| Indicateur | Valeur |
|---|---|
| keybuzz-infra HEAD | ee20acf |
| Client DEV runtime tag | v3.5.203-register-autopilot-trial-copy-dev |
| Client DEV runtime digest | sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9 |
| Smoke /register | HTTP 200 |
| Smoke API /health | HTTP 200 |
| API DEV | v3.5.251-register-cro-dev INCHANGE |
| PROD | 3/3 INCHANGE |
| NO BUILD | OK |
| NO DOCKER PUSH | OK |
| NO kubectl set/patch/edit | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-APPLY-CLIENT-DEV-01.md (untracked) |

Prochaine phrase GO attendue :

GO QA REGISTER AUTOPILOT TRIAL COPY DEV PH-SAAS-T8.12AS.19.5

STOP.
