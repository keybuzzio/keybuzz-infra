# PH-SAAS-T8.12AS.6.1-SMOKE-HARNESS-OPERATING-RULES-01

> Date : 2026-05-11
> Linear : KEY-310 (commentaire poste cf section 5)
> Phase : T8.12 AS.6.1 - operating rules smoke harness V1
> Environnement : docs-only ; runtime DEV read-only smoke run effectue ; runtime PROD inchange

---

## 1. VERDICT

GO SMOKE OPERATING RULES READY

Les regles operatoires du smoke harness V1 (livre en AS.6) sont definies ci-dessous.

- AS.6 V1 confirme reproductible sur bastion install-v3 : PASS=18 WARN=0 FAIL=0 SKIP=1 RESULT=PASS exit=0.
- Aucun build, aucun deploy, aucun docker push, aucun kubectl apply/set/patch/edit, aucune mutation runtime, aucune mutation DB.
- Linear KEY-310 commentaire court poste (cf section 5). Statut Linear suggere : In Review ou Done selon validation AS.6.1 Ludovic.
- Rapport docs-only : commit direct selon nouvelle regle (PH-docs autorisee sans GO intermediaire si aucun manifest / aucun code applicatif / aucun secret).

Les fichiers source-of-truth a mettre a jour ulterieurement pour propager la regle (recommandation, NON modifies dans AS.6.1) :
- `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md`
- `keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md` (section Etat courant)

Le fichier `CLAUDE.md` projet (`C:\DEV\KeyBuzz\CLAUDE.md`) sera mis a jour separement par Ludovic ou via une phase dediee si necessaire. AS.6.1 ne le modifie pas.

---

## 2. Preflight

| Check | Valeur | Statut |
|---|---|---|
| keybuzz-client branche | ph148/onboarding-activation-replay | OK |
| keybuzz-client HEAD | 7a8a2fb (test(smoke): add read-only DEV smoke harness KEY-310) | OK |
| keybuzz-client sync origin | 0 / 0 | OK |
| keybuzz-infra branche | main | OK |
| keybuzz-infra HEAD | ac720c0 (docs(qa): readonly smoke automation foundation KEY-310) | OK |
| keybuzz-infra sync origin | 0 / 0 | OK |
| API DEV runtime | v3.5.168-escalation-notifications-dev | OK inchange |
| Client DEV runtime | v3.5.179-as1-1-build-args-fix-dev | OK inchange |
| PROD | inchange | OK |
| scripts/smoke/ present | readonly-smoke-dev.sh (14359 bytes 0755) + README.md (6232 bytes) | OK |

Aucun drift detecte. Aucun runtime PROD touche entre AS.6 et AS.6.1.

---

## 3. Harness V1 -- recap fonctionnel

### 3.1 Variables d entree

Required (sinon FATAL fail-safe, exit 1) :
- `SMOKE_API_BASE_URL`
- `SMOKE_BASE_URL`
- `SMOKE_TENANT_ID`

Optional (degradent en WARN si absentes) :
- `SMOKE_USER_EMAIL` (BFF pattern x-user-email)
- `SMOKE_CONVERSATION_ID` (active la probe section E /autopilot/draft)
- `SMOKE_KUBE_NAMESPACE_API_DEV` (default keybuzz-api-dev)
- `SMOKE_KUBE_NAMESPACE_CLIENT_DEV` (default keybuzz-client-dev)
- `SMOKE_EXPECTED_API_IMAGE` (asserte runtime image)
- `SMOKE_EXPECTED_CLIENT_IMAGE` (asserte runtime image)

### 3.2 Sections couvertes

| Section | Domaine | Probes |
|---|---|---|
| A | Runtime / GitOps | API + Client : image runtime, manifest=last-applied, pod ready |
| B | Bundle guard | image Client extraite via docker create+cp : sentinel absent, api-dev inline, PROD URL absent, labels Brouillon IA + Valider et envoyer |
| C | API DEV read-only | /health, /messages/conversations, /stats/conversations, /notifications escalation pending |
| D | Client / BFF read-only | /, /inbox, /api/auth/session |
| E | Optional autopilot draft | /autopilot/draft hasDraft + actionType + confidence + draftText_len (jamais draftText) |

### 3.3 Exit policy
- 0 : PASS ou PASS_WITH_WARNINGS
- 1 : FAIL (au moins un check FAIL) ou env requise manquante

### 3.4 Garanties anti-mutation (4 couches)
1. Self-grep au demarrage (lignes non-commentaires) refuse `curl -X (POST|PATCH|PUT|DELETE)`, `--request mutation`, `-d`, `--data*`.
2. Toutes les requetes HTTP via `curl -G` (force GET).
3. kubectl uniquement `get` + `jsonpath`. Pas de `apply/set/patch/edit/exec/delete`.
4. Bodies API jamais affiches : seuls status code, sizes, presence de literaux UI, et summary parse local non-PII pour /autopilot/draft (hasDraft + actionType + confidence + draftText_len).

---

## 4. Operating rules (regles operatoires)

### 4.1 Regle de base

A partir d'AS.6.1, avant TOUTE prochaine phase qui implique un build ou un deploy DEV cote Client ou cote API, l ordre obligatoire est :

```
1. Verifier source/runtime truth (AS.5.5 baseline + AS.5.6A alignment).
2. Lancer `scripts/smoke/readonly-smoke-dev.sh` avec env DEV.
3. PASS requis pour aller plus loin.
4. WARN tolerable UNIQUEMENT si chaque warning est documente dans le prompt CE de la phase.
5. FAIL bloque toute action build/deploy.
6. Apres le build/deploy effectue (rollout termine, pods ready), relancer le smoke read-only une seconde fois pour confirmer le runtime post-mutation.
```

### 4.2 Variables canoniques DEV

A utiliser systematiquement dans toute phase DEV :

```
SMOKE_API_BASE_URL=https://api-dev.keybuzz.io
SMOKE_BASE_URL=https://client-dev.keybuzz.io
SMOKE_TENANT_ID=<tenant-id-AUTOPILOT-test>
SMOKE_USER_EMAIL=<authorized-email>
SMOKE_EXPECTED_API_IMAGE=ghcr.io/keybuzzio/keybuzz-api:<tag-attendu>-dev
SMOKE_EXPECTED_CLIENT_IMAGE=ghcr.io/keybuzzio/keybuzz-client:<tag-attendu>-dev
```

`SMOKE_EXPECTED_*_IMAGE` doit etre mis a jour par le prompt CE de chaque phase pour matcher le tag attendu apres build/deploy. Si le runtime ne correspond pas a cet attendu, le smoke FAIL.

### 4.3 Ce que le smoke remplace
- les verifications manuelles de drift GitOps (image / manifest / last-applied / pod ready).
- la verification bundle Client (sentinel, URL inline, labels UI) qui etait faite ad-hoc en AS.1.2.
- les probes API health + endpoints read-only critiques.

### 4.4 Ce que le smoke NE remplace PAS
- la QA Ludovic en navigateur loggue pour les parcours UX (cliquer un draft, ouvrir une conversation, voir le bandeau attendu).
- la verification visuelle de design / texte / position.
- les scenarios de bout en bout (envoi reel, reply reel, billing) -- volontairement HORS scope smoke.
- la securite (tenantGuard, isolation tenant) -- traitee separement par audit KEY-301 / KEY-304.

### 4.5 Ce que le smoke INTERDIT (defense-in-depth)
- creer / modifier / supprimer tenant, channel, supplier, agent, order, conversation, notification, draft.
- envoyer un message, cliquer Valider et envoyer, ack une notification.
- declencher Stripe / webhook / outbound side effect.
- ecrire en DB.
- effectuer un POST / PATCH / PUT / DELETE quelle que soit la cible.
- afficher PII, secrets, draftText, customer info, order id complet dans la sortie smoke commitable.

### 4.6 Mode PROD
NON implemente en V1. La regle est : aucune probe PROD profonde tant que le mode PROD-readonly n est pas implemente en V2 et valide separement.

Probes PROD autorisees en V1 (hors smoke script) : strictement `curl -s -o /dev/null -w '%{http_code}'` sur `/health` des services PROD, sans cookies, sans token, sans tentative d acces tenant-scope. Ces probes sont effectuees ad-hoc par CE quand un audit de non-regression PROD est demande.

### 4.7 Workflow par phase

Pour chaque phase future qui prevoit un build/deploy DEV :

| Etape | Action | Garde-fou |
|---|---|---|
| pre-1 | preflight repos + runtime | si drift = STOP |
| pre-2 | smoke V1 baseline run | PASS requis (sinon STOP) |
| pre-3 | documenter dans le prompt CE le tag attendu post-build (variables SMOKE_EXPECTED_*) | obligatoire |
| build | docker build avec build args explicites (KEY-302) | obligatoire pour Client |
| push | docker push tag immuable | obligatoire |
| apply | kubectl apply -f manifest depuis git, jamais kubectl set/patch/edit | obligatoire |
| rollout | kubectl rollout status, pods ready | obligatoire |
| post-1 | smoke V1 run avec SMOKE_EXPECTED_*_IMAGE updated | PASS requis (sinon rollback) |
| post-2 | QA Ludovic UI sur parcours critiques | confirme par utilisateur |
| rapport | rapport PH ASCII strict | obligatoire |

### 4.8 Regle PH-docs (introduite par AS.6.1)

Pour les rapports PH qui sont :
- docs-only
- ASCII strict
- dans `keybuzz-infra/docs/`
- sans manifest modifie
- sans code applicatif modifie
- sans secret
- sans CI deploy

Le CE peut creer le rapport directement au bon endroit puis commit + push DIRECTEMENT, et fournir les preuves apres coup.

STOP obligatoire et demande de GO si le rapport :
- touche `k8s/**` ou tout fichier manifest
- touche du code applicatif (app/, src/, ...)
- touche un fichier secret
- touche un fichier CI deploy
- modifie un runtime ou genere un side-effect

AS.6.1 et son commit appliquent eux-memes cette regle (rapport docs-only direct commit).

---

## 5. Linear KEY-310 -- commentaire poste

Commentaire court poste sur KEY-310 :
- URL : https://linear.app/keybuzz/issue/KEY-310/qa-automatiser-les-smoke-tests-read-only-dev-avant-builddeploy#comment-cfbd50c5
- Statut KEY-310 actuel : Todo (workflow KEY). Statut suggere apres AS.6.1 : In Review ou Done. Non modifie par AS.6.1 (operation conservative, attente confirmation Ludovic).

Resume du commentaire :
- V1 livre source-only (commits 7a8a2fb keybuzz-client + ac720c0 keybuzz-infra).
- 4 couches garanties anti-mutation.
- PASS=18 WARN=0 FAIL=0 SKIP=1 bastion install-v3.
- V2 propose : Playwright UI session dediee + mode PROD-readonly + integration CI + logs scrubbing.
- Aucun runtime touche, aucun build, aucun deploy, aucun docker push, aucun kubectl apply.

---

## 6. Smoke run trace AS.6.1 (reproductibilite confirmee)

Variables exportees pendant le run AS.6.1 :
- `SMOKE_API_BASE_URL=https://api-dev.keybuzz.io`
- `SMOKE_BASE_URL=https://client-dev.keybuzz.io`
- `SMOKE_TENANT_ID=switaa-sasu-mnc1x4eq`
- `SMOKE_USER_EMAIL=<email Ludovic, redacted in this report>`
- `SMOKE_EXPECTED_API_IMAGE=ghcr.io/keybuzzio/keybuzz-api:v3.5.168-escalation-notifications-dev`
- `SMOKE_EXPECTED_CLIENT_IMAGE=ghcr.io/keybuzzio/keybuzz-client:v3.5.179-as1-1-build-args-fix-dev`

Output :

```
=== A. Runtime / GitOps checks ===
PASS API DEV image matches expected (...:v3.5.168-escalation-notifications-dev)
PASS API DEV spec = last-applied (no GitOps drift)
PASS API DEV pod ready
PASS Client DEV image matches expected (...:v3.5.179-as1-1-build-args-fix-dev)
PASS Client DEV spec = last-applied (no GitOps drift)
PASS Client DEV pod ready

=== B. Bundle guard checks ===
PASS Bundle Client DEV has no build sentinel
PASS Bundle Client DEV inlines api-dev URL (expected)
PASS Bundle Client DEV does not contain PROD URL
PASS Bundle Client DEV contains label 'Brouillon IA'
PASS Bundle Client DEV contains label 'Valider et envoyer'

=== C. API DEV read-only checks ===
PASS API /health 200
PASS API /messages/conversations 200 size=1189
PASS API /stats/conversations 200 size=184
PASS API /notifications escalation pending 200 size=347

=== D. Client / BFF read-only checks ===
PASS Client / reachable status=200 (auth redirect expected without cookie)
PASS Client /inbox reachable status=200
PASS Client /api/auth/session 200 (NextAuth GET shape)

=== E. Optional /autopilot/draft probe ===
SKIP no SMOKE_CONVERSATION_ID provided

=== Summary ===
PASS=18 WARN=0 FAIL=0 SKIP=1
RESULT=PASS
exit=0
```

Resultat identique au run AS.6 (reproductibilite confirmee).

---

## 7. Recommandations pour les fichiers source-of-truth (non modifies par AS.6.1)

Les fichiers suivants devraient inclure ulterieurement une reference a la regle AS.6.1 (a planifier en phase doc dediee, cf KEY-311) :

| Fichier | Section recommendee | Contenu a ajouter |
|---|---|---|
| `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md` | nouvelle section "Smoke pre-build/pre-deploy" | regle 4.1 + variables canoniques 4.2 + workflow 4.7 |
| `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md` | section "Smoke obligatoire avant build/deploy DEV" | regle 4.1 + interdits 4.5 |
| `keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md` | section "Etat courant" | ajout AS.6 + AS.6.1 dans la chaine |
| `C:\DEV\KeyBuzz\CLAUDE.md` (projet) | section "Lecture obligatoire" + "Regles absolues" | reference au rapport AS.6.1 + regle PH-docs 4.8 |

Aucune de ces mises a jour n est realisee dans AS.6.1. Le ticket KEY-311 (Docs source-of-truth update) couvre deja ce perimetre. Le contenu actuel d AS.6 + AS.6.1 fournit le materiel a integrer dans KEY-311.

---

## 8. Gaps / V2 (rappel et nouveaux)

Heritage AS.6 :
1. Playwright UI session dediee (V2).
2. Mode PROD-readonly (V2).
3. Integration CI post-deploy (V2).
4. Logs scrubbing (V2).
5. Multi-tenant smoke (V3).
6. Integration OCI labels (V3, KEY-308).
7. Integration tag policy (V3, KEY-309).

Nouveaux AS.6.1 :
8. Adoption de la regle 4.1 dans tous les prompts CE futurs. Effectif a partir d AS.6.1.
9. Generaliser le pattern KEY-302 a admin-v2 (KEY-307) pour permettre l extension du smoke section B au bundle admin.
10. Adoption de la regle PH-docs 4.8 pour reduire le nombre de GO intermediaires sur les rapports purs.

---

## 9. Interdits respectes par AS.6.1

| Interdit | Statut |
|---|---|
| build | RESPECTE |
| deploy | RESPECTE |
| kubectl apply/set/patch/edit | RESPECTE |
| docker push | RESPECTE |
| mutation DB | RESPECTE |
| modification app/src/API | RESPECTE |
| Linear post sans GO explicite | GO explicite donne par le prompt CE (etape 5). Commentaire court conforme aux regles disclosure. |

---

### 9.bis Phrase cible finale

AS.6.1 definit les regles operatoires du smoke harness V1 (regle pre-build/pre-deploy 4.1, variables canoniques 4.2, ce que le smoke remplace / ne remplace pas / interdit, mode PROD non implemente V1, workflow par phase 4.7, regle PH-docs 4.8) ; smoke V1 reconfirme reproductible bastion install-v3 (PASS=18 WARN=0 FAIL=0 SKIP=1) ; commentaire court poste sur KEY-310 ; aucun fichier source-of-truth modifie dans AS.6.1 (KEY-311 a planifier pour propagation) ; aucun build, aucun deploy, aucun docker push, aucun kubectl apply/set/patch/edit, aucune mutation runtime ou DB ; verdict AS.6.1 GO SMOKE OPERATING RULES READY.

STOP
