# PH-SAAS-T8.12AS.2 -- Client Build Args Hardening

> Date : 2026-05-10
> Linear : KEY-302 (Infra) ; KEY-263 (incident parent)
> Phase : hardening source-only du process build keybuzz-client
> Environnement : SOURCE ONLY -- aucun runtime modifie -- PROD strictement intacte

## VERDICT

GO KEY-302 SOURCE HARDENING READY

CLIENT DOCKERFILE NO LONGER DEFAULTS SILENTLY TO PROD -- NO-ARGS BUILD FAILS -- DEV BUILD INLINE API DEV ONLY -- PROD LOCAL BUILD INLINE API PROD ONLY -- MISMATCH BUILD FAILS -- NO IMAGE PUSH -- NO DEPLOY -- PROD UNCHANGED

Un docker build keybuzz-client sans `--build-arg NEXT_PUBLIC_APP_ENV` / `NEXT_PUBLIC_API_URL` / `NEXT_PUBLIC_API_BASE_URL` echoue maintenant explicitement au step 36/52 (RUN guard), avant `npm run build`. Les valeurs par defaut Dockerfile sont des sentinelles `__MUST_BE_SET_BY_BUILD_ARG__` que le guard detecte et rejette. Une coherence env <-> URL est aussi verifiee : `development` exige `https://api-dev.keybuzz.io`, `production` exige `https://api.keybuzz.io`. Un script post-build `scripts/verify-client-bundle-api-url.sh` extrait `/app/.next/static` de l'image et prouve que seule l'URL attendue est inlinee.

---

## 0. Preflight

### Repos bastion install-v3

| Repo | Branche attendue | Branche reelle | HEAD avant | HEAD apres | Status | Sync origin |
|---|---|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | a69477a | f244a58 | clean (sauf tsconfig.tsbuildinfo artifact, exclu du commit) | 0/0 |
| keybuzz-infra | main | main | b4389d6 | (rapport AS.2 a venir dans cette phase) | clean | 0/0 |

Bastion : install-v3, IP 46.62.171.61.

---

## 1. Runtime read-only (avant et apres)

| Service | Image avant AS.2 | Image apres AS.2 | Verdict |
|---|---|---|---|
| Client DEV | v3.5.179-as1-1-build-args-fix-dev | v3.5.179-as1-1-build-args-fix-dev | INCHANGE (pod 67 min running) |
| API DEV | v3.5.168-escalation-notifications-dev | v3.5.168-escalation-notifications-dev | INCHANGE (pod 173 min running) |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| API PROD | v3.5.151-conversation-tone-metric-prod | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |

Aucun pod redemarre par cette phase. Aucun manifest GitOps modifie. Aucun appel `kubectl apply`.

### Bundle preuve image runtime DEV avant patch (v3.5.179)

| Image | api-dev present | api PROD absent | Verdict |
|---|---|---|---|
| v3.5.179-as1-1-build-args-fix-dev | OUI (2 occurrences) | OUI (0 occurrence) | OK |

---

## 2. Audit source build (avant patch)

| Fichier | Role | Risque | Action prise |
|---|---|---|---|
| Dockerfile L10-12 | ARG defauts pointant PROD `https://api.keybuzz.io` | un build sans `--build-arg` produit un bundle PROD silencieusement | remplaces par sentinelles + guard fail-fast |
| Dockerfile flow | `npm run build` lance sans validation env | bundle inline arbitraire selon ARG defaut | guard insere avant `npm run build` |
| package.json | `"build": "next build"` | OK, neutre | aucune modif |
| src/config/api.ts:2 | `baseUrl = process.env.NEXT_PUBLIC_API_BASE_URL OR NEXT_PUBLIC_API_URL OR ''` | OK, lit l'inline | aucune modif |
| src/services/auth.service.ts:9 | `process.env.NEXT_PUBLIC_API_URL` cote browser | OK | aucune modif |
| src/lib/api-url.ts:7 | BFF helper, priorite `API_URL_INTERNAL > API_URL > NEXT_PUBLIC_API_URL` | OK (BFF, pas browser) | aucune modif |
| scripts/ | 12 scripts utilitaires, aucun dedie au build args | manque guard et verify | 2 nouveaux scripts ajoutes |

Mecanisme : Next.js inline les `process.env.NEXT_PUBLIC_*` au moment du `next build` en valeur litterale dans le bundle JS browser. Le `||` fallback du source code disparait. Donc si le `--build-arg` manque, c'est le defaut Dockerfile qui est inline sans signal.

---

## 3. Patch (source only)

### Fichiers touches dans keybuzz-client

| Fichier | Type | Lignes |
|---|---|---|
| Dockerfile | EDIT | 21 ajouts / 4 suppressions |
| scripts/check-client-build-args.sh | NEW | 71 lignes, POSIX sh, executable |
| scripts/verify-client-bundle-api-url.sh | NEW | 85 lignes, bash, executable |
| docs/BUILD-ARGS.md | NEW | 96 lignes, ASCII strict |

Total : 269 insertions, 4 suppressions, 4 fichiers.

### Dockerfile : sentinelles + guard

```
ARG NEXT_PUBLIC_APP_ENV=__MUST_BE_SET_BY_BUILD_ARG__
ARG NEXT_PUBLIC_API_URL=__MUST_BE_SET_BY_BUILD_ARG__
ARG NEXT_PUBLIC_API_BASE_URL=__MUST_BE_SET_BY_BUILD_ARG__
```

Et avant `RUN npm run build` :

```
COPY scripts/check-client-build-args.sh ./scripts/
RUN sh ./scripts/check-client-build-args.sh
```

### Guard `scripts/check-client-build-args.sh`

POSIX sh (compatible avec /bin/sh d'alpine, pas bash). Valide en sequence :

1. Aucune des 3 vars n'est vide.
2. Aucune des 3 vars ne contient encore la sentinelle `__MUST_BE_SET_BY_BUILD_ARG__`.
3. `NEXT_PUBLIC_APP_ENV` est exactement `development` ou `production`.
4. `NEXT_PUBLIC_API_URL` et `NEXT_PUBLIC_API_BASE_URL` sont identiques.
5. Coherence env <-> URL :
   - `development` exige `https://api-dev.keybuzz.io`
   - `production` exige `https://api.keybuzz.io`

Sortie sur succes : `[CLIENT-BUILD-ARGS-GUARD] OK: APP_ENV=... API_URL=... API_BASE_URL=...`
Sortie sur echec : message detaille indiquant la cause + rappel des `--build-arg` requis + reference vers `docs/BUILD-ARGS.md`.

### Script post-build `scripts/verify-client-bundle-api-url.sh`

Bash script destine a etre lance sur le host (bastion) apres le `docker build`, avant tout `docker push`. Usage :

```
scripts/verify-client-bundle-api-url.sh <image> <development|production>
```

Mecanisme :

1. `docker create --name <temp> <image>`
2. `docker cp <temp>:/app/.next/static <tmpdir>`
3. `grep -rohE 'https://api-dev\.keybuzz\.io'` (compte DEV)
4. `grep -rohE 'https://api\.keybuzz\.io'` (compte PROD ; le regex strict ne matche pas `api-dev.`)
5. Cleanup container et tmpdir via trap (meme en cas d'erreur).
6. Verdict :
   - DEV : exige >=1 occurrence DEV ET 0 occurrence PROD
   - PROD : exige >=1 occurrence PROD ET 0 occurrence DEV

Exit codes : 0 = OK, 1 = bundle KO ou usage error, 2 = extraction failure.

Note technique : les `grep ... 2>/dev/null | wc -l` sont enveloppes dans `(... || true)` sous-shell pour absorber l'exit 1 de grep quand il ne trouve rien (sinon `set -euo pipefail` tue le script silencieusement avant d'afficher le verdict).

### Documentation `docs/BUILD-ARGS.md`

Documente :
- pourquoi le guard existe (resume incident KEY-263)
- comment le guard fonctionne (3 etapes)
- commandes exactes DEV et PROD requises
- ce que le guard ne couvre PAS (analytics IDs, runtime env vars, push/deploy)
- table de symptomes / causes / fix

---

## 4. Tests

Tous les tests executes en local sur bastion. Aucun `docker push`. Aucune mutation runtime.

| # | Test | Commande | Attendu | Resultat | Verdict |
|---|---|---|---|---|---|
| E7 | no args | `docker build -t local/keybuzz-client:key302-noargs-test .` | FAIL au guard | FAIL au step 36/52, exit 1, message "NEXT_PUBLIC_APP_ENV not overridden via --build-arg (sentinel still present)" | OK |
| E10 | mismatch env=development URL=PROD | `docker build --build-arg NEXT_PUBLIC_APP_ENV=development --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io ... .` | FAIL au guard | FAIL au step 36/52, exit 1, message "APP_ENV=development requires NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io (got: https://api.keybuzz.io)" | OK |
| E8 | DEV correct | `docker build --build-arg NEXT_PUBLIC_APP_ENV=development --build-arg ...api-dev... -t local/keybuzz-client:key302-dev-guard-test .` | SUCCESS + verify exit 0 | build SUCCESS image 8460bb42d825 ; verify-bundle : api-dev x2, api PROD x0, exit 0 | OK |
| E9 | PROD local correct | `docker build --build-arg NEXT_PUBLIC_APP_ENV=production --build-arg ...api.keybuzz... -t local/keybuzz-client:key302-prod-guard-test .` | SUCCESS + verify exit 0 | build SUCCESS image f709394a94a3 ; verify-bundle : api PROD x2, api-dev x0, exit 0 | OK |

Tags locaux uniquement. Aucun de ces tags n'a ete pousse.

---

## 5. Source checks

| Check | Commande | Resultat |
|---|---|---|
| POSIX sh syntax | `sh -n scripts/check-client-build-args.sh` | OK |
| Bash syntax | `bash -n scripts/verify-client-bundle-api-url.sh` | OK |
| shellcheck | indisponible sur bastion | non execute, gap documente |
| TypeScript | non applicable (pas de modif TS dans cette phase) | non execute |
| Build Docker (test E8/E9) | execute via etapes 8 et 9 | OK |

---

## 6. Commits

### keybuzz-client

| Commit | Message | Files | Etat |
|---|---|---|---|
| f244a58 | fix(client-build): require explicit API build args for safe bundles (KEY-302) | Dockerfile, scripts/check-client-build-args.sh, scripts/verify-client-bundle-api-url.sh, docs/BUILD-ARGS.md | pousse sur origin |

`tsconfig.tsbuildinfo` est volontairement EXCLU du commit (artifact de build local resultant des tests Docker, non gitignored mais sans valeur metier).

### keybuzz-infra

Le seul commit infra de cette phase est ce rapport (commit pousse separement apres redaction).

---

## 7. Confirmation aucune mutation runtime

| Action engageante | Effectuee ? |
|---|---|
| docker push | NON |
| kubectl apply | NON |
| kubectl set image / patch / edit / set env | NON |
| modification d'un manifest GitOps | NON |
| restart d'un pod | NON |
| modification API DEV | NON |
| modification API PROD | NON |
| modification Client PROD | NON |
| modification Backend / Website / Admin / OW | NON |
| modification DB | NON |
| modification Stripe / billing / CAPI / tracking | NON |

---

## 8. Non-regression runtime

Identique a la section 1. Tous services PROD inchanges, DEV Client/API inchanges, aucun pod redemarre par cette phase.

---

## 9. Gaps restants (documentes, non corriges dans cette phase)

1. KEY-301 reste ouvert : audit `tenantGuardPlugin` DEV/PROD requis avant toute promotion AS.1 PROD du badge escalation.
2. Badge escalation AS.1 non reactive dans cette phase.
3. Code Client AS.1 partiellement orphelin conserve (4 fichiers : BFF route notifications, service notifications, hook useEscalationNotifsCount, prop optionnelle escalationNotifCount dans AgentWorkbenchBar).
4. Aucune modification de runtime.
5. Eventuel besoin ulterieur d'un script de release global DEV/PROD plus complet (build + push + tag + manifest update + apply + verify) qui combinerait check-client-build-args.sh, docker build, docker push, et verify-client-bundle-api-url.sh dans un seul flux. Hors scope KEY-302.
6. shellcheck non installe sur bastion : validation statique des scripts shell limitee a `sh -n` / `bash -n`. A ajouter eventuellement.
7. Le guard ne couvre pas les autres `NEXT_PUBLIC_*` (analytics, pixels). Si un jour ces IDs deviennent env-specifiques, etendre le guard.
8. Image v3.5.177-escalation-notifications-ux-dev encore en cache local Docker bastion : peut etre extraite et son bundle inspecte pour confirmer empiriquement l'hypothese "v3.5.177 avait la meme cause build args" (innocenter le code AS.1 definitivement). Optionnel.

---

## 10. Rollback

Pas de rollback runtime applicable -- cette phase ne deploie rien.

Rollback source possible si le guard casse un workflow legitime :

```
ssh install-v3
cd /opt/keybuzz/keybuzz-client
git revert f244a58
git push origin ph148/onboarding-activation-replay
```

Aucun impact runtime tant qu'aucune image n'est buildee/poussee/deployee.

A executer uniquement sur GO Ludovic explicite. Documente, non execute.

---

## 11. Phrase cible finale

Le process de build keybuzz-client est durci au niveau source : un docker build sans `--build-arg` explicite pour `NEXT_PUBLIC_APP_ENV` / `NEXT_PUBLIC_API_URL` / `NEXT_PUBLIC_API_BASE_URL` echoue maintenant explicitement au guard `scripts/check-client-build-args.sh` avant `npm run build` ; la coherence env <-> URL est verifiee ; un script `scripts/verify-client-bundle-api-url.sh` permet de prouver post-build que seule l'URL attendue est inlinee dans le bundle browser ; les 4 tests (no-args FAIL, mismatch FAIL, DEV success, PROD local success) passent ; aucun docker push, aucun kubectl apply, runtime DEV et PROD strictement inchanges ; KEY-301 reste ouvert avant toute promotion AS.1 PROD.

STOP -- hardening source livre, en attente decisions sur KEY-301 et toute future ouverture d'un script de release global.
