# PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-BUILD-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-BUILD-CLIENT-DEV
> Environnement : DEV build only / aucun docker push / aucun deploy

## VERDICT

GO BUILD CLIENT REGISTER CGU STATE + COPY F.9 DEV READY PH-SAAS-T8.12AS.19.6

- Image locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.204-register-cgu-and-copy-dev` construite from-git depuis `bae77de`
- Image ID local : `sha256:256f2d822338ff63aad7b471f8c530fd24ad8361dd2af24f0d2622d7e27561c3`
- Size 280 MB
- 5/5 OCI labels KEY-308 presents (revision bae77de, created 2026-05-20T18:49:31Z)
- Bundle DEV verifie : 87 `api-dev.keybuzz.io`, **0** `api.keybuzz.io` (KEY-263 OK)
- PH-19.6 nouveaux patterns live dans bundle (CGU persist + encart accepte + checkbox plan + copy F.9 custom complet)
- Non-regression PH-19.3 + PH-19.4 + PH-19.5 preservee
- Vieux patterns supprimes confirmes (0 occurrence)
- Clarity 0/0/0, AW- 0, plan_selected 4 (1 emit source unique x SSR + chunks)
- Runtime DEV/PROD inchange (6/6)
- AUCUN docker push, AUCUN deploy, AUCUN kubectl

Prochaine phrase GO attendue : GO PUSH IMAGE CLIENT REGISTER CGU + COPY F.9 DEV PH-SAAS-T8.12AS.19.6

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| Client branche | ph148/onboarding-activation-replay | OK |
| Client HEAD local = origin | bae77de | OK |
| Client dirty | tsconfig.tsbuildinfo (preexistant) | OK hors scope |
| Infra HEAD = origin | 2a7626d | OK |
| GHCR collision pre-build (try 1) | manifest unknown | tag FREE |
| GHCR collision pre-build (try 2) | manifest unknown | confirmation tag FREE |

## SOURCE COMMIT VERIFY

| Element | Valeur |
|---|---|
| commit hash | bae77de |
| commit title | fix(register): persiste CGU et clarifie copy 0 EUR pendant 14 jours |
| files (1) | app/register/page.tsx |
| diff stats | +51 / -8 |
| initialAcceptCgu (source) | 3 occurrences |
| kb_signup_cgu_accepted (source) | 2 |
| register-cgu-accepted-note (source) | 1 |
| register-cgu-plan-checkbox (source) | 1 |
| 0 EUR pendant 14 jours (source) | 2 (variante laterale + titre bloc) |
| Aucun debit avant la fin de l (source) | 1 |
| capacites Autopilot (source) | 1 |
| le plan selectionne devient actif (source) | 1 |
| votre plan prend le relais (source) | 1 |
| Vieux patterns disparus | 0 (tout le monde teste Autopilot + CB requise a cette etape uniquement) |
| Non-regression PH-19.3+19.4 source | tous preserves |

## WORKTREE BUILD

| Element | Valeur |
|---|---|
| path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.6/keybuzz-client |
| HEAD detached | bae77de5b064c7edb7f6cb98440fd7710697f8e0 |
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
| GIT_COMMIT_SHA | bae77de5b064c7edb7f6cb98440fd7710697f8e0 |
| BUILD_TIME | 2026-05-20T18:49:31Z |
| IMAGE_REVISION | bae77de5b064c7edb7f6cb98440fd7710697f8e0 |
| IMAGE_CREATED | 2026-05-20T18:49:31Z |
| IMAGE_VERSION | v3.5.204-register-cgu-and-copy-dev |

NB : Clarity (NEXT_PUBLIC_CLARITY*) non passe en build arg (KEY-325 non activation client.keybuzz.io).

## OCI LABELS KEY-308 (5/5 presents)

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | bae77de5b064c7edb7f6cb98440fd7710697f8e0 |
| org.opencontainers.image.created | 2026-05-20T18:49:31Z |
| org.opencontainers.image.version | v3.5.204-register-cgu-and-copy-dev |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client |
| org.opencontainers.image.title | keybuzz-client |

## IMAGE LOCALE

| Element | Valeur |
|---|---|
| Repository tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.204-register-cgu-and-copy-dev |
| Image ID | sha256:256f2d822338ff63aad7b471f8c530fd24ad8361dd2af24f0d2622d7e27561c3 |
| Size | 280001769 bytes (280 MB) |
| Architecture | amd64 |
| OS | linux |
| Created | 2026-05-20T18:52:19Z |
| Source commit | bae77de |

Aucun push GHCR effectue (NO docker push).

## BUNDLE DEV VERIFICATION

Bundle extrait depuis /app/.next dans /tmp/bundle-v3.5.204 (9.9 MB), shred apres verification.

### Isolation DEV/PROD (KEY-263)

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| api-dev.keybuzz.io | 87 | > 0 (DEV isolation) | OK |
| api.keybuzz.io (sans -dev) | 0 | 0 (pas de PROD leak) | OK |
| client-dev.keybuzz.io | 3 | DEV cookie/origin | OK |

### Nouveaux patterns PH-19.6 (CGU persist + encart + copy F.9 custom)

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| kb_signup_cgu_accepted (sessionStorage key) | 2 | SSR + chunk | OK |
| register-cgu-accepted-note (data-testid encart accepte) | 2 | SSR + chunk | OK |
| register-cgu-plan-checkbox (data-testid checkbox plan) | 2 | SSR + chunk | OK |
| 0 EUR pendant 14 jours (titre bloc + variante laterale) | 4 | 2 sources x SSR + chunk | OK |
| Aucun debit avant la fin de l (phrase principale) | 2 | SSR + chunk | OK |
| Carte demandee a l (phrase principale) | 2 | SSR + chunk | OK |
| capacites Autopilot (phrase principale) | 2 | SSR + chunk | OK |
| le plan selectionne devient actif (microcopy CTA) | 2 | SSR + chunk | OK |
| votre plan prend le relais (variante laterale) | 2 | SSR + chunk | OK |
| CGU et Politique de confidentialite acceptees (encart accepte) | 2 | SSR + chunk | OK |
| Voir les CGU (lien encart) | 2 | SSR + chunk | OK |

### Vieux patterns supprimes confirmes

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| tout le monde teste Autopilot | 0 | 0 (PH-19.5 wording amateur supprime) | OK |
| CB requise a cette etape uniquement | 0 | 0 (PH-19.5 microcopy supprime) | OK |

### Tunnel lead-first PH-19.3 preserve

| Pattern | Occurrences | Verdict |
|---|---|---|
| register-lead-shell | 2 | OK |
| register-reassurance-panel | 2 | OK |
| register-confirm-plan | 2 | OK |
| register-autopilot-trial-note (data-testid preserve, contenu PH-19.6 nouveau) | 2 | OK |

### Fix PH-19.4 QA preserve

| Pattern | Occurrences | Verdict |
|---|---|---|
| data-selected | 2 | OK |
| aria-pressed | 2 | OK |
| invalid_marketing_owner_tenant_id | 2 | OK |
| Le plus populaire (sur Autopilot) | 7 | OK |
| Autopilot (id + nom) | 127 | OK |

### PII / Analytics / Clarity

| Pattern | Occurrences | Attendu | Verdict |
|---|---|---|---|
| data-clarity-mask | 26 | 13 source x 2 (SSR + chunk) | OK PII preserves |
| clarity.ms | 0 | 0 | OK Clarity non activee |
| NEXT_PUBLIC_CLARITY | 0 | 0 | OK |
| wrff07upjx | 0 | 0 | OK |
| AW-XXXXXXXXXX direct | 0 | 0 | OK no fake Google Ads tag |
| plan_selected | 4 | 1 emit source x (SSR + chunks refs) | OK unique canonique preserve |

## NO FAKE METRICS / NO FAKE EVENTS

- plan_selected reste emis uniquement dans handleSelectPlan (1 occurrence source, KEY-331). 4 refs bundle = SSR + chunks.
- Aucun nouvel event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout ajoute.
- Aucun tag AW-XXXXXXXXXX direct.
- Aucun event par bouton ajoute. data-cta-id register_confirm_plan_and_checkout + register_continue_to_plan + register_plan_select_* preserves.
- PH-19.6 ne modifie aucune mecanique tracking : uniquement CGU persist + copy.
- data-clarity-mask + data-cta-id + data-plan + data-cycle + data-promo-state + data-selected + aria-pressed preserves.
- Clarity client toujours non activee.

## PROMESSE PRODUIT (factualite copy F.9 custom)

Le copy PH-19.6 decrit le mecanisme d essai en wording factuel SaaS pro (style Stripe/Atlassian) :

- Bloc principal "0 EUR pendant 14 jours" + "Carte demandee a l'activation. Aucun debit avant la fin de l'essai. Pendant 14 jours, vous testez KeyBuzz avec les capacites Autopilot." -> signal financier fort, factuel, sans superlatif.
- Microcopy CTA "A la fin de l'essai, le plan selectionne devient actif si vous continuez. Vous pouvez changer de plan ou annuler avant cette date." -> rassurance post-essai + droit utilisateur.
- Variante laterale "0 EUR pendant 14 jours. Essai active avec Autopilot, puis votre plan prend le relais." -> miroir compact du bloc principal.
- Encart CGU step plan : "CGU et Politique de confidentialite acceptees." + lien "Voir les CGU" si acceptees, OU checkbox accessible si pas encore acceptees -> resout bug invisible CGU + clarte UX.

Aucun chiffre/ratio non prouve, aucune fausse review, aucun faux logo. Promesses verifiables en QA fonctionnel pre-promotion PROD (Stripe trial_period_days=14, absence capture pre-trial, UI Facturation pour changer/annuler).

## RUNTIME PRESERVE READ-ONLY

| Service | Image runtime | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-dev | v3.5.203-register-autopilot-trial-copy-dev | 1/1 | INCHANGE |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | 1/1 | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |

Aucun apply, aucun rollout, aucun manifest infra modifie.

## CONFIRMATIONS NO PUSH / NO DEPLOY

- AUCUN docker push (image locale uniquement, tag GHCR cible reste libre jusqu a la phase PUSH-IMAGE)
- AUCUN nouveau tag autre que `v3.5.204-register-cgu-and-copy-dev`
- AUCUN kubectl apply / set / patch / edit
- AUCUN deploy DEV / PROD
- AUCUN changement manifest infra
- AUCUN changement source applicatif (commit bae77de deja pousse phase PUSH-SOURCE)
- AUCUN commit applicatif
- AUCUN secret expose dans logs / labels
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN changement Admin / Backend / Studio / Website / Stripe / Vault / ESO
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- Bastion install-v3 (46.62.171.61) uniquement
- Build-from-git (worktree detache propre, pas runtime/pod/dist)

## LINEAR BROUILLONS (NON postes, token hors-chat ; reauth Codex 401)

> **KEY-335 (primary)** : Image Client DEV v3.5.204-register-cgu-and-copy-dev construite from-git bae77de. Image ID sha256:256f2d822338... 280 MB. OCI labels 5/5 (revision bae77de, created 2026-05-20T18:49:31Z). Bundle PH-19.6 verifie : (1) CGU persist live (kb_signup_cgu_accepted 2, register-cgu-accepted-note 2, register-cgu-plan-checkbox 2, "Voir les CGU" 2), (2) Copy F.9 custom live (0 EUR pendant 14 jours 4, "Aucun debit avant la fin de l" 2, "Carte demandee a l" 2, "capacites Autopilot" 2, "le plan selectionne devient actif" 2, "votre plan prend le relais" 2), (3) Vieux patterns supprimes confirmes (tout le monde teste Autopilot = 0, CB requise a cette etape uniquement = 0). Non-regression PH-19.3+19.4+19.5 preserves. Clarity non activee. STOP avant docker push GHCR.

> **KEY-334** : Tunnel lead-first preserve apres PH-19.6 (register-lead-shell 2, register-reassurance-panel 2, register-confirm-plan 2, register-autopilot-trial-note 2 avec nouveau contenu 0 EUR).

> **KEY-329** : Copy CRO post-PH-19.6 desormais factuel SaaS pro (style Stripe/Atlassian). Aucun fake review / fake logo / fake chiffre.

> **KEY-331** : plan_selected reste unique cote source (1 emit canonique).

> **KEY-330** : No fake events ajoutes par PH-19.6. AW- direct = 0.

> **KEY-325** : Clarity client toujours non activee. 26 data-clarity-mask PII preserves.

## GAPS

1. Tag `v3.5.204-register-cgu-and-copy-dev` reste libre cote GHCR jusqu a la phase PUSH-IMAGE. Image existe uniquement en local docker daemon sur install-v3.
2. Bloc 3 etapes l.644 "Votre choix fixe le plan apres l essai. Pendant 14 jours, vous testez Autopilot pour voir toute la valeur." NON modifie dans le patch (hors scope wording Ludovic). Ton acceptable mais pourrait etre rendu plus pro en PH-19.7 (ex: "Pendant 14 jours, vous accedez aux capacites Autopilot.").
3. Comportement produit "0 EUR pendant 14 jours" + "le plan selectionne devient actif" : a valider cote Stripe (`trial_period_days=14`, aucune capture pre-trial) + API (`tenants.trial_entitlement_plan -> tenants.plan` switch a J+14) en QA fonctionnel pre-promotion PROD.
4. Email logo template magic-link `client.keybuzz.io/branding/keybuzz-icon.png` toujours present (preexistant hors scope KEY-263).
5. Worktree `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.6/keybuzz-client` reste sur disque pour eventuelle phase PROD ulterieure ; cleanup possible post-PROD.
6. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build DEV (iso baseline v3.5.203 matching).
7. Clarity activation client.keybuzz.io reste decision post-QA.
8. Cleanup sessionStorage `kb_signup_cgu_accepted` apres success Stripe : NON ajoute (low risk, sessionStorage expire a la fermeture du tab). Si Ludovic veut cleanup explicite, PH-19.7.

## ROLLBACK PREP

Si la phase APPLY ulterieure echoue ou est annulee :
- Tag rollback Client DEV : `v3.5.203-register-autopilot-trial-copy-dev`
- Digest rollback : `sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9`

Aucun rollback necessaire a ce stade (aucun runtime touche).

## VERDICT FINAL

GO BUILD CLIENT REGISTER CGU STATE + COPY F.9 DEV READY PH-SAAS-T8.12AS.19.6

| Indicateur | Valeur |
|---|---|
| Image locale tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.204-register-cgu-and-copy-dev |
| Image ID local | sha256:256f2d822338ff63aad7b471f8c530fd24ad8361dd2af24f0d2622d7e27561c3 |
| Size | 280 MB |
| Source commit | bae77de |
| OCI labels KEY-308 | 5/5 OK |
| Bundle DEV isolation | OK (87 api-dev / 0 api.keybuzz.io) |
| Patterns PH-19.6 nouveaux (CGU + copy F.9) | OK (11 patterns verifies, tous a 2 ou 4 SSR + chunks) |
| Vieux patterns supprimes | OK (0 occurrence) |
| Non-regression PH-19.3 + 19.4 + 19.5 | OK |
| Clarity | non activee (0/0/0) |
| AW- direct | 0 |
| plan_selected | 1 emit source unique |
| Runtime | 6/6 INCHANGE |
| NO docker push | OK |
| NO deploy | OK |
| NO kubectl | OK |
| Rapport local | keybuzz-infra/docs/PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-BUILD-CLIENT-DEV-01.md (untracked attendu) |

Prochaine phrase GO attendue :

GO PUSH IMAGE CLIENT REGISTER CGU + COPY F.9 DEV PH-SAAS-T8.12AS.19.6

STOP.
