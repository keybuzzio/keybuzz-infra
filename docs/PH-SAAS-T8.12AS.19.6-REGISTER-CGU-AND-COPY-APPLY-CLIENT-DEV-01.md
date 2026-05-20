# PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-APPLY-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-APPLY-CLIENT-DEV
> Environnement : DEV GitOps apply only

## VERDICT

GO APPLY CLIENT REGISTER CGU + COPY F.9 DEV READY PH-SAAS-T8.12AS.19.6

- keybuzz-infra HEAD : `b1e98d1` (ops(client-dev): deploy v3.5.204-register-cgu-and-copy-dev)
- Client DEV runtime : `v3.5.204-register-cgu-and-copy-dev` digest `sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3` (pod fpcxj Ready 1/1, 0 restart)
- API DEV runtime : `v3.5.251-register-cro-dev` (INCHANGE, candidate preserve)
- Smoke /register HTTP 200, API /health HTTP 200
- PROD inchange (3/3 deployments)
- NO BUILD, NO DOCKER PUSH, NO kubectl set/patch/edit

Prochaine phrase GO attendue : GO QA REGISTER CGU + COPY F.9 DEV PH-SAAS-T8.12AS.19.6

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| keybuzz-infra HEAD pre | 2a7626d | OK |
| 2 rapports PH-19.6 untracked attendus | BUILD + PUSH-IMAGE | OK |
| GHCR config digest verify | sha256:256f2d822338... | OK match expected |

## RUNTIME AVANT APPLY

| Service | DEV image avant | PROD image | Verdict |
|---|---|---|---|
| keybuzz-client | v3.5.203-register-autopilot-trial-copy-dev | v3.5.198-debug-env-disabled-prod | OK |
| keybuzz-api | v3.5.251-register-cro-dev | v3.5.250-ad-spend-sync-all-prod | preserve |
| keybuzz-website | v0.6.18-ga4-cleanup-dev | v0.6.18-ga4-cleanup-prod | preserve |

## MANIFEST MODIFIE

| Fichier | Avant | Apres | Diff |
|---|---|---|---|
| k8s/keybuzz-client-dev/deployment.yaml (l.77) | image v3.5.203-register-autopilot-trial-copy-dev | image v3.5.204-register-cgu-and-copy-dev | 1 ligne (image + commentaire PH-19.6 + rollback + digest) |

Commentaire manifest :
- phase PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-APPLY-CLIENT-DEV (2026-05-20)
- commit Client bae77de
- KEY-335 CGU persist sessionStorage + restore au mount + encart CGU step plan (accepte OU checkbox) + bouton Confirmer disabled si !acceptCgu
- KEY-335 copy F.9 custom : titre bloc 0 EUR pendant 14 jours (vert) + phrase principale + microcopy CTA + variante laterale
- KEY-334 tunnel lead-first preserve
- KEY-329 + KEY-333 benchmark signup preserve (factuel SaaS pro)
- KEY-325 data-clarity-mask preserve (Clarity NON activee)
- KEY-331 plan_selected unique preserve
- KEY-330 no fake events ; no fake reviews/logos/chiffres
- attribution UTM/click IDs/_gl/promo preservee + fallback safe marketing_owner_tenant_id preserve
- rollback v3.5.203-register-autopilot-trial-copy-dev (digest sha256:7e471e7489a4...)
- new digest sha256:17a31829c644...

## ROLLBACK DIGEST PRE-PATCH

| Tag | Manifest digest GHCR |
|---|---|
| v3.5.203-register-autopilot-trial-copy-dev (rollback) | sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9 |
| v3.5.204-register-cgu-and-copy-dev (new) | sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3 |

## DRY-RUN SERVER

| Manifest | Resultat |
|---|---|
| k8s/keybuzz-client-dev/deployment.yaml | deployment.apps/keybuzz-client configured (server dry run) |

## COMMIT INFRA + PUSH

| Etape | Valeur |
|---|---|
| files staged (3) | k8s/keybuzz-client-dev/deployment.yaml (M), docs/PH-19.6-BUILD-CLIENT-DEV-01.md (A), docs/PH-19.6-PUSH-IMAGE-CLIENT-DEV-01.md (A) |
| commit hash | b1e98d1 |
| commit title | ops(client-dev): deploy v3.5.204-register-cgu-and-copy-dev |
| insertions/deletions | +481 / -1 |
| push exit | 0 |
| origin HEAD post-push | b1e98d1 (2a7626d -> b1e98d1 main -> main) |

## APPLY CLIENT DEV

| Etape | Resultat |
|---|---|
| kubectl apply client-dev | deployment.apps/keybuzz-client configured |
| rollout status client-dev | successfully rolled out (timeout 300s) |
| kubectl set / patch / edit | NON utilise (GitOps strict) |

## RUNTIME APRES APPLY

| Service | Manifest tag | Runtime tag | Runtime digest pod | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-client DEV | v3.5.204-register-cgu-and-copy-dev | v3.5.204-register-cgu-and-copy-dev | sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3 | 1/1 (fpcxj) | 0 | OK manifest = tag = digest |

## SMOKE DEV /REGISTER

| Endpoint | Methode | Resultat | Verdict |
|---|---|---|---|
| https://client-dev.keybuzz.io/register?plan=pro&cycle=monthly&promo=TEST&utm_source=smoke&_gl=test&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk | GET | HTTP 200, 9188 bytes (shell client Next.js use-client hydration) | OK |
| https://api-dev.keybuzz.io/health | GET | HTTP 200 | OK |

Note SSR : page /register est rendue via use client hydration cote browser - shell HTML 9188 bytes contient `<!DOCTYPE html>` + Next.js precompiled CSS + script preload. Le bloc 0 EUR + encart CGU + nouveau copy F.9 + persist CGU sessionStorage sont dans les chunks JS lazy hydrates apres charge. Tous deja verifies bundle pre-deploy (phase BUILD-CLIENT-DEV-01). QA browser Ludovic confirmera visuellement post-apply.

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

Verifie source PH-19.6 + bundle BUILD-CLIENT-DEV-01 :

- plan_selected emit unique preserve dans handleSelectPlan (KEY-331) : 1 source emit, 4 refs bundle
- PH-19.6 ne modifie aucune mecanique tracking : uniquement CGU persist + copy
- Pas d event par bouton ajoute, data-cta-id preserves
- Clarity client NON activee (clarity.ms=0, NEXT_PUBLIC_CLARITY=0, wrff07upjx=0)
- Aucune fake review / fake metric / fake chiffre / fake logo
- Events ads existants tracking.ts inchanges

## PROMESSE PRODUIT (factualite copy F.9 custom)

Copy live DEV decrit le mecanisme d'essai en wording factuel SaaS pro :
- Bloc principal "0 EUR pendant 14 jours" + "Carte demandee a l'activation. Aucun debit avant la fin de l'essai. Pendant 14 jours, vous testez KeyBuzz avec les capacites Autopilot." -> signal financier fort, sans superlatif.
- Microcopy CTA "A la fin de l'essai, le plan selectionne devient actif si vous continuez. Vous pouvez changer de plan ou annuler avant cette date." -> rassurance post-essai + droit utilisateur.
- Variante laterale "0 EUR pendant 14 jours. Essai active avec Autopilot, puis votre plan prend le relais." -> miroir compact.
- Encart CGU step plan : "CGU et Politique de confidentialite acceptees." + lien "Voir les CGU" si acceptees, OU checkbox accessible si pas encore acceptees -> resout bug invisible CGU + clarte UX.

Aucun chiffre/ratio non prouve, aucune fausse review, aucun faux logo, aucune promesse "zero intervention humaine". Promesses verifiables en QA fonctionnel pre-promotion PROD.

## LINEAR BROUILLONS (NON postes, token hors-chat ; reauth Codex 401)

> **KEY-335 (primary)** : PH-19.6 DEV applied. Client DEV runtime = v3.5.204-register-cgu-and-copy-dev, digest sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3. Pod fpcxj Ready 1/1, 0 restart. Infra commit b1e98d1. (1) Bug CGU corrige : persist sessionStorage kb_signup_cgu_accepted + restore au mount + encart CGU step plan (note acceptee avec lien Voir CGU OR checkbox accessible si pas acceptee) + bouton Confirmer disabled si !acceptCgu. (2) Copy F.9 custom Ludovic live : bloc 0 EUR vert "0 EUR pendant 14 jours" + phrase "Carte demandee a l'activation. Aucun debit avant la fin de l'essai. Pendant 14 jours, vous testez KeyBuzz avec les capacites Autopilot." + microcopy CTA + variante laterale. Tunnel lead-first + QA fix preserves. Smoke /register HTTP 200 + API /health 200. PROD unchanged. STOP avant QA navigateur Ludovic.

> **KEY-334** : Tunnel lead-first preserve apres CGU fix + copy F.9 custom.

> **KEY-329** : Copy CRO factuel SaaS pro live DEV. Aucun fake review/logo/chiffre.

> **KEY-325** : Clarity client toujours absent live DEV. 26 data-clarity-mask PII preserves.

> **KEY-330 / KEY-331** : No fake events ajoutes. plan_selected preserve unique. Events ads browser-side tracking.ts inchanges.

## CONFIRMATIONS NO BUILD / NO DOCKER PUSH

- AUCUN docker build
- AUCUN docker push (tag GHCR v3.5.204 deja pousse phase PUSH-IMAGE-CLIENT-DEV-01)
- AUCUN deploy PROD
- AUCUN kubectl set image / set env / patch / edit
- AUCUN apply API DEV (manifest API DEV inchange)
- AUCUN apply Website
- AUCUN changement source Client/API (commit bae77de deja pousse)
- AUCUN changement Admin / Backend / Studio / Stripe / Vault / ESO
- AUCUN secret expose dans logs
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN Linear ticket close
- Bastion install-v3 (46.62.171.61) uniquement

## ROLLBACK GitOps STRICT

Si necessaire, rollback strict GitOps :

1. Editer k8s/keybuzz-client-dev/deployment.yaml -> image v3.5.203-register-autopilot-trial-copy-dev (digest sha256:7e471e7489a4...)
2. git add + commit -m "ops(client-dev): ROLLBACK PH-19.6 to v3.5.203"
3. git push origin main
4. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
5. kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s
6. Verifier runtime digest = sha256:7e471e7489a4...

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. HTML SSR /register reste vide en checks bruts (Next.js use client hydration) - QA visuelle browser Ludovic requise pour confirmer : (a) bloc 0 EUR vert visible sur step plan, (b) microcopy CTA F.9 affiche, (c) variante laterale ReassurancePanel updated, (d) encart CGU acceptees + lien Voir CGU si deja acceptees, (e) checkbox CGU orange accessible sur step plan si pas accepte (reproductible via F5 sur step plan apres avoir progresse), (f) bouton Confirmer disabled tant que CGU pas cochee, (g) plus de "tout le monde teste Autopilot" / "CB requise a cette etape uniquement".
2. Comportement "0 EUR pendant 14 jours" + "le plan selectionne devient actif" : a valider cote Stripe (trial_period_days=14, aucune capture pre-trial) + API (`tenants.trial_entitlement_plan -> tenants.plan` switch a J+14) en QA fonctionnel pre-promotion PROD.
3. UI Facturation pour "changer de plan ou annuler avant cette date" : a confirmer accessible et fonctionnel cote Settings/Billing.
4. Bloc 3 etapes l.644 "Votre choix fixe le plan apres l essai. Pendant 14 jours, vous testez Autopilot pour voir toute la valeur." NON modifie (hors scope wording Ludovic). Pourrait etre simplifie en PH-19.7 pour coherence totale.
5. Email logo template magic-link `client.keybuzz.io/branding/...` preexistant hors scope.
6. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build DEV (iso baseline v3.5.203 matching).
7. Worktree `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.6/keybuzz-client` reste sur disque : cleanup possible post-PROD.

## VERDICT FINAL

GO APPLY CLIENT REGISTER CGU + COPY F.9 DEV READY PH-SAAS-T8.12AS.19.6

| Indicateur | Valeur |
|---|---|
| keybuzz-infra HEAD | b1e98d1 |
| Client DEV runtime tag | v3.5.204-register-cgu-and-copy-dev |
| Client DEV runtime digest | sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3 |
| Smoke /register | HTTP 200 |
| Smoke API /health | HTTP 200 |
| API DEV | v3.5.251-register-cro-dev INCHANGE |
| PROD | 3/3 INCHANGE |
| NO BUILD | OK |
| NO DOCKER PUSH | OK |
| NO kubectl set/patch/edit | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-APPLY-CLIENT-DEV-01.md (untracked) |

Prochaine phrase GO attendue :

GO QA REGISTER CGU + COPY F.9 DEV PH-SAAS-T8.12AS.19.6

STOP.
