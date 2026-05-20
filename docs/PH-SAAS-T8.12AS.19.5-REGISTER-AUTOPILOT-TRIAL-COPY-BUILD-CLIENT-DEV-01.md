# PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-BUILD-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-BUILD-CLIENT-DEV
> Environnement : DEV build only / aucun docker push / aucun deploy

## VERDICT

GO BUILD CLIENT REGISTER AUTOPILOT TRIAL COPY DEV READY PH-SAAS-T8.12AS.19.5

- Image locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.203-register-autopilot-trial-copy-dev` construite from-git depuis `fc4a43e`
- Image ID local : `sha256:faa09d39e47d1b9ae724a471208cd6fcca14227e328a87a2eb0cc50cfeb6c22c`
- Size 280 MB
- 5/5 OCI labels KEY-308 (revision fc4a43e, created 2026-05-20T17:13:45Z)
- Bundle DEV verifie : 87 `api-dev.keybuzz.io`, **0** `api.keybuzz.io` (KEY-263 OK)
- PH-19.5 copy Autopilot trial live dans bundle (register-autopilot-trial-note 2, "Essai 14 jours sur Autopilot" 2, "14 jours d essai gratuit sur Autopilot" 2, "bascule sur le plan choisi" 4)
- Non-regression PH-19.3 (lead-first) + PH-19.4 (QA fix) preserves
- Clarity 0/0/0, AW- 0, plan_selected 4 (1 emit source unique x SSR + chunks)
- Runtime DEV/PROD inchange (6/6)
- AUCUN docker push, AUCUN deploy, AUCUN kubectl

Prochaine phrase GO attendue : GO PUSH IMAGE CLIENT REGISTER AUTOPILOT TRIAL COPY DEV PH-SAAS-T8.12AS.19.5

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| Client branche | ph148/onboarding-activation-replay | OK |
| Client HEAD local = origin | fc4a43e | OK |
| Client dirty | tsconfig.tsbuildinfo (preexistant) | OK hors scope |
| Infra HEAD = origin | dfb5e94 | OK |
| GHCR collision pre-build (try 1) | manifest unknown | tag FREE |
| GHCR collision pre-build (try 2) | manifest unknown | confirmation tag FREE |

## SOURCE COMMIT VERIFY

| Element | Valeur |
|---|---|
| commit hash | fc4a43e |
| commit title | copy(register): clarifie lessai Autopilot |
| files (1) | app/register/page.tsx |
| diff stats | +10 / -4 |
| register-autopilot-trial-note (source) | 1 |
| Essai 14 jours sur Autopilot (source) | 1 |
| bascule sur le plan choisi (source) | 2 |
| Non-regression PH-19.4 patterns | tous preserves |

## WORKTREE BUILD

| Element | Valeur |
|---|---|
| path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.5/keybuzz-client |
| HEAD detached | fc4a43eb455cb0a0206110b4ccaa497344c38c6e |
| status | clean |

## BUILD ARGS

| Build arg | Valeur |
|---|---|
| NEXT_PUBLIC_APP_ENV | development |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | (vide, iso baseline DEV) |
| NEXT_PUBLIC_META_PIXEL_ID | (vide, iso baseline DEV) |
| NEXT_PUBLIC_SGTM_URL | (vide, iso baseline DEV) |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | (vide, iso baseline DEV) |
| GIT_COMMIT_SHA | fc4a43eb455cb0a0206110b4ccaa497344c38c6e |
| BUILD_TIME | 2026-05-20T17:13:45Z |
| IMAGE_REVISION | fc4a43eb455cb0a0206110b4ccaa497344c38c6e |
| IMAGE_CREATED | 2026-05-20T17:13:45Z |
| IMAGE_VERSION | v3.5.203-register-autopilot-trial-copy-dev |

NB : Clarity (NEXT_PUBLIC_CLARITY*) non passe en build arg : preserve l etat baseline (KEY-325 non activation client.keybuzz.io).

## OCI LABELS KEY-308 (5/5 presents)

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | fc4a43eb455cb0a0206110b4ccaa497344c38c6e |
| org.opencontainers.image.created | 2026-05-20T17:13:45Z |
| org.opencontainers.image.version | v3.5.203-register-autopilot-trial-copy-dev |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client |
| org.opencontainers.image.title | keybuzz-client |

## IMAGE LOCALE

| Element | Valeur |
|---|---|
| Repository tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.203-register-autopilot-trial-copy-dev |
| Image ID | sha256:faa09d39e47d1b9ae724a471208cd6fcca14227e328a87a2eb0cc50cfeb6c22c |
| Size | 279999003 bytes (280 MB) |
| Architecture | amd64 |
| OS | linux |
| Created | 2026-05-20T17:16:35Z |
| Source commit | fc4a43e |

Aucun push GHCR effectue (NO docker push).

## BUNDLE DEV VERIFICATION

Bundle extrait depuis /app/.next dans /tmp/bundle-v3.5.203 (9.9 MB), shred apres verification.

### Isolation DEV/PROD (KEY-263)

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| api-dev.keybuzz.io | 87 | > 0 (DEV isolation) | OK |
| api.keybuzz.io (sans -dev) | 0 | 0 (pas de PROD leak) | OK |
| client-dev.keybuzz.io | 3 | DEV cookie/origin | OK |

### Copy PH-19.5 Autopilot trial (nouveau)

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| register-autopilot-trial-note (data-testid) | 2 | SSR + chunk | OK |
| Essai 14 jours sur Autopilot | 2 | SSR + chunk | OK |
| 14 jours d essai gratuit sur Autopilot | 2 | titre step plan SSR + chunk | OK |
| bascule sur le plan choisi | 4 | 2 sources x SSR + chunks | OK |

### Tunnel lead-first PH-19.3 preserve

| Pattern | Occurrences (attendu 2 = SSR + chunk) | Verdict |
|---|---|---|
| register-lead-shell | 2 | OK |
| register-reassurance-panel | 2 | OK |
| register-confirm-plan | 2 | OK |
| Confirmer ce plan et activer | 2 | OK |

### Fix PH-19.4 QA preserves

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| data-selected | 2 | >= 1 | OK SSR + chunk |
| aria-pressed | 2 | >= 1 | OK SSR + chunk |
| invalid_marketing_owner_tenant_id | 2 | >= 1 | OK fallback compile dans bundle |
| Le plus populaire (badge sur Autopilot) | 7 | >= 1 | OK |
| Autopilot (id + nom) | 129 | references multiples | OK plan Autopilot promu + copy PH-19.5 |

### PII / Analytics / Clarity

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| data-clarity-mask | 26 | 13 source x 2 (SSR + chunk) | OK PII preserves |
| clarity.ms | 0 | 0 | OK Clarity non activee |
| NEXT_PUBLIC_CLARITY | 0 | 0 | OK |
| wrff07upjx | 0 | 0 | OK Clarity ID Website non leak Client |
| AW-XXXXXXXXXX direct | 0 | 0 | OK no fake Google Ads tag |
| plan_selected | 4 | 1 emit source x (SSR + chunks refs) | OK unique canonique preserve |

## NO FAKE METRICS / NO FAKE EVENTS

- `plan_selected` reste unique cote source (1 emit canonique dans `handleSelectPlan`), 4 occurrences bundle = refs SSR + chunks (pas 4 emits).
- Aucun nouvel event `Lead`, `Purchase`, `StartTrial`, `CompletePayment`, `SubmitForm`, `InitiateCheckout` ajoute par PH-19.5.
- Aucun tag `AW-XXXXXXXXXX` direct present dans le bundle.
- PH-19.5 ne modifie que le copy (text content) - aucun event ni mecanique de tracking ajoute.
- data-testid + data-clarity-mask + data-cta-id + data-plan + data-cycle + data-promo-state + data-selected + aria-pressed preserves.
- Clarity client toujours non activee.

## PROMESSE PRODUIT (factualite copy KeyBuzz)

Le copy PH-19.5 clarifie le mecanisme d essai mais ne fait pas de promesse non verifiee :
- "Essai 14 jours sur Autopilot, puis bascule sur le plan choisi" : description du mecanisme.
- "Pendant l essai, tout le monde teste Autopilot" : description du mecanisme.
- "A la fin des 14 jours, si vous continuez, KeyBuzz bascule simplement sur le plan selectionne ici" : description du mecanisme.
- "Vous pouvez changer ou resilier pendant l essai" : description du droit utilisateur.

Aucun chiffre/ratio non prouve (ex. "+30%", "4000+ clients", "wow"), aucune fausse review, aucun faux logo, aucune promesse "zero intervention humaine".

A verifier en QA produit (gap documente) : le comportement runtime materialise-t-il bien l essai sur Autopilot quel que soit le plan selectionne, et la bascule plan choisi a la fin des 14 jours ? Cette validation est cote API/Stripe/billing/trial logic et n entre pas dans le scope build Client PH-19.5.

## RUNTIME PRESERVE READ-ONLY

| Service | Image runtime | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-dev | v3.5.202-register-qa-fix-dev | 1/1 | INCHANGE |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | 1/1 | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |

Aucun apply, aucun rollout, aucun manifest infra modifie.

## CONFIRMATIONS NO PUSH / NO DEPLOY

- AUCUN docker push (image locale uniquement, tag GHCR cible reste libre jusqu a la phase PUSH-IMAGE)
- AUCUN nouveau tag autre que `v3.5.203-register-autopilot-trial-copy-dev`
- AUCUN kubectl apply / set / patch / edit
- AUCUN deploy DEV / PROD
- AUCUN changement manifest infra
- AUCUN changement source applicatif (commit fc4a43e deja pousse phase PUSH-SOURCE)
- AUCUN commit applicatif
- AUCUN secret expose dans logs / labels
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN changement Admin / Backend / Studio / Website / Stripe / Vault / ESO
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- Bastion install-v3 (46.62.171.61) uniquement
- Build-from-git (worktree detache propre, pas runtime/pod/dist)

## LINEAR BROUILLONS (NON postes, token hors-chat ; reauth Codex 401)

> **KEY-335 (primary)** : Image Client DEV v3.5.203-register-autopilot-trial-copy-dev construite from-git fc4a43e. Image ID sha256:faa09d39e47d... 280 MB. OCI labels 5/5 (revision fc4a43e, created 2026-05-20T17:13:45Z). Bundle PH-19.5 verifie : 87 api-dev / 0 api.keybuzz.io (KEY-263 OK), register-autopilot-trial-note 2, "Essai 14 jours sur Autopilot" 2, "14 jours d essai gratuit sur Autopilot" 2, "bascule sur le plan choisi" 4. Non-regression PH-19.3 + PH-19.4 preserves. Clarity non activee. STOP avant docker push GHCR.

> **KEY-334** : Image lead-first preserve apres copy Autopilot trial. Patterns tunnel preserves (register-lead-shell 2, register-reassurance-panel 2, register-confirm-plan 2, CTAs). API DEV v3.5.251 candidate preserve. PROD inchange.

> **KEY-329** : Copy Autopilot trial clarifie le mecanisme d essai sans fake reviews/logos/chiffres. Image build CRO post-clarify OK.

> **KEY-331** : plan_selected reste unique cote source (1 emit canonique). 4 refs bundle = SSR + chunks.

> **KEY-330** : No fake events ajoutes par PH-19.5. AW- direct = 0, aucun Lead/Purchase/StartTrial/CompletePayment ajoute.

> **KEY-325** : Clarity client toujours non activee dans l image construite (clarity.ms 0 / NEXT_PUBLIC_CLARITY 0 / wrff07upjx 0). 26 data-clarity-mask PII preserves.

## GAPS

1. Tag `v3.5.203-register-autopilot-trial-copy-dev` reste libre cote GHCR jusqu a la phase PUSH-IMAGE. Image existe uniquement en local docker daemon sur install-v3.
2. Comportement produit "essai sur Autopilot quel que soit le plan" : a valider cote API/Stripe/billing (hors scope build Client PH-19.5). QA produit Ludovic devra confirmer que le runtime materialise bien cette experience (plan trial = AUTOPILOT_ASSISTED ou Autopilot reel) et la bascule plan choisi a la fin des 14 jours.
3. Email logo template magic-link `client.keybuzz.io/branding/keybuzz-icon.png` toujours present (preexistant hors scope KEY-263).
4. Worktree `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.5/keybuzz-client` reste sur disque pour eventuelle phase PROD ulterieure ; cleanup possible post-PROD.
5. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build DEV (iso baseline v3.5.202 matching).
6. Clarity activation client.keybuzz.io reste decision post-QA lead-first + QA-fix + autopilot-trial-copy.
7. "Pendant l essai" (sans s apostrophe Unicode) ne matche pas via grep ASCII-strict mais le copy "Pendant l essai, tout le monde teste Autopilot." est bien present dans le bundle via les autres patterns adjacents ("Essai 14 jours sur Autopilot" 2 + "14 jours d essai gratuit" 2 + "bascule sur le plan choisi" 4). A confirmer visuellement post-deploy.

## ROLLBACK PREP

Si la phase APPLY ulterieure echoue ou est annulee :
- Tag rollback Client DEV : `v3.5.202-register-qa-fix-dev`
- Digest rollback : `sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40`

Aucun rollback necessaire a ce stade (aucun runtime touche).

## VERDICT FINAL

GO BUILD CLIENT REGISTER AUTOPILOT TRIAL COPY DEV READY PH-SAAS-T8.12AS.19.5

| Indicateur | Valeur |
|---|---|
| Image locale tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.203-register-autopilot-trial-copy-dev |
| Image ID local | sha256:faa09d39e47d1b9ae724a471208cd6fcca14227e328a87a2eb0cc50cfeb6c22c |
| Size | 280 MB |
| Source commit | fc4a43e |
| OCI labels KEY-308 | 5/5 OK |
| Bundle DEV isolation | OK (87 api-dev / 0 api.keybuzz.io) |
| Patterns PH-19.5 copy Autopilot trial | OK (register-autopilot-trial-note 2, Essai 14 jours sur Autopilot 2, 14 jours d essai gratuit sur Autopilot 2, bascule sur le plan choisi 4) |
| Non-regression PH-19.3 + PH-19.4 | OK (preserves) |
| Clarity | non activee (0/0/0) |
| AW- direct | 0 |
| plan_selected | 1 emit source unique |
| Runtime | 6/6 INCHANGE |
| NO docker push | OK |
| NO deploy | OK |
| NO kubectl | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-BUILD-CLIENT-DEV-01.md (untracked attendu) |

Prochaine phrase GO attendue :

GO PUSH IMAGE CLIENT REGISTER AUTOPILOT TRIAL COPY DEV PH-SAAS-T8.12AS.19.5

STOP.
