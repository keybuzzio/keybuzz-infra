# PH-SAAS-T8.12AS.20.14C-TER-SOURCE-PATCH-OUTBOUNDEMAIL-SCHEMA-MAP-DEV-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.14C-TER (SOURCE PATCH ONLY : Prisma schema map)
> Environnement : DEV (source patch ; aucune migration, aucun build, aucun deploy, aucune mutation DB)

## 1. Verdict

GO SOURCE PATCH OUTBOUNDEMAIL SCHEMA MAP DEV READY PH-SAAS-T8.12AS.20.14C-TER

Le drift de schema Prisma<->DB sur OutboundEmail.toAddress est corrige en source par ajout de @map("to"). prisma generate OK, typecheck OK, tests 16/16 + 15/15 OK, mapping DMMF prouve (toAddress.dbName="to"). Patch scope strict (1 fichier, 1 ligne). Commit backend LOCAL 2a14258, NON pousse (STOP au gate push). Aucune migration, aucun ALTER, aucune mutation DB, aucun build, aucun deploy, aucun trigger. jobs-worker DEV inchange.

Prochaine phrase GO : GO PUSH SOURCE PATCH OUTBOUNDEMAIL SCHEMA MAP DEV PH-SAAS-T8.12AS.20.14C-TER (push backend 2a14258 + rapport infra + commentaires Linear), puis GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14D-TER (tag v1.0.50-amazon-validation-pipeline-dev).

## 2. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| keybuzz-backend branche | main | OK |
| keybuzz-backend HEAD avant patch | 71e66c9 = origin/main | OK (clean) |
| keybuzz-infra HEAD | 69c7431 | OK |
| jobs-worker DEV (keybuzz-backend-dev) | Running, image v1.0.49, restarts=0 | OK (non touche) |
| Repo backend dirty | non (hors .bak untracked anterieur) | OK |

## 3. Cause racine (rappel PH-20.14G)

Le trigger reel PH-20.14G (tenant_test_dev) a renvoye HTTP 500 "column toAddress does not exist in the current database". Cause : le champ Prisma OutboundEmail.toAddress n avait pas de @map, alors que la colonne reelle (DEV ET PROD) s appelle "to". Tout prisma.outboundEmail.create()/select() casse -> aucun OutboundEmail cree -> aucun job -> validation jamais aboutie. C est la cause de fond sous le gap (table OutboundEmail quasi-vide all-time).

## 4. Audit mapping (read-only DB, avant patch)

| Modele Prisma | Champ | Colonne DB reelle (DEV) | Colonne DB reelle (PROD) | Drift |
|---|---|---|---|---|
| OutboundEmail | toAddress | to | to | OUI (corrige) |
| OutboundEmail | autres champs (id,tenantId,ticketId,from,subject,body,provider,status,error,sentAt,createdAt,updatedAt) | identiques | identiques | NON |
| MarketplaceOutboundMessage | toAddress | toAddress | toAddress | NON (correct, pas de @map requis) |

Seul OutboundEmail.toAddress divergeait. MarketplaceOutboundMessage.toAddress est correctement mappe (colonne reelle = toAddress) : aucun patch requis, hors scope.

## 5. Patch (fichier / changement / risque)

| Fichier | Changement | Risque |
|---|---|---|
| keybuzz-backend/prisma/schema.prisma (model OutboundEmail, ligne 538) | `toAddress String` -> `toAddress String @map("to")` | Nul cote DB : @map ne change que le mapping colonne, conserve les donnees. Aucune migration. Le nom de champ TS reste toAddress (aucun call site a modifier). |

git diff : 1 file changed, 1 insertion(+), 1 deletion(-). Scope strict.

## 6. prisma generate + tests / typecheck

| Etape | Commande | Resultat |
|---|---|---|
| prisma generate | npx prisma generate | EXIT 0 (client genere, pas de migrate/db push) |
| Mapping DMMF | DMMF OutboundEmail.toAddress.dbName | "to" -> MAP_OK=true |
| Typecheck | npx tsc --noEmit -p tsconfig.json | TSC_OK |
| Tests PH-20.14C-BIS | tests/ph2014cbis-jobscope.test.ts | 16 passed, 0 failed |
| Tests PH-20.14C | tests/ph2014c-outboundEmail.test.ts | 15 passed, 0 failed |

Aucun OutboundEmail runtime cree (tests mockes). prisma generate ecrit dans node_modules (non versionne) : aucun bruit committable.

## 7. No side-effect runtime

| Check | Etat | Verdict |
|---|---|---|
| jobs-worker DEV redeploye | non (image v1.0.49, restarts=0, start 20:03:13Z) | OK |
| Mutation DB | aucune (pas de migrate/db push/ALTER/INSERT/UPDATE) | OK |
| OutboundEmail cree / email envoye | aucun | OK |
| Trigger send-validation | aucun | OK |
| Build / docker push / kubectl apply | aucun | OK |

## 8. Commit (backend)

| Element | Valeur |
|---|---|
| Commit LOCAL | 2a14258 fix(outbound): map OutboundEmail recipient column |
| Fichiers | prisma/schema.prisma (1 file, +1/-1) |
| HEAD avant | 71e66c9 |
| origin/main | 71e66c9 (NON avance ; push en attente de GO) |

## 9. Build / GitOps

N/A pour cette phase. SOURCE PATCH uniquement. Build = phase suivante PH-20.14D-TER (tag v1.0.50-amazon-validation-pipeline-dev).

## 10. Validation runtime

N/A. Aucun deploy. La validation reelle du mapping en runtime se fera apres rebuild+redeploy (API qui fait le create + jobs-worker) puis re-trigger PH-20.14G.

## 11. No fake metrics / events

Aucun flip DB, aucun fake OutboundEmail, aucun fake webhook, aucune metrique forgee. Mapping prouve par DMMF (lecture du client genere), pas par ecriture DB.

## 12. AI feature parity / anti-regression

Hors scope IA. Le patch ne touche que le mapping colonne d OutboundEmail. Aucun impact Inbox, messages, connecteurs, autopilot, dashboard. Les call sites (toAddress en TS) restent identiques.

## 13. Non-regression PROD

| Check | Avant | Apres | Verdict |
|---|---|---|---|
| PROD touche | non | non | OK |
| Schema PROD DB | colonne "to" | colonne "to" (inchange) | OK |
| jobs-worker DEV | v1.0.49 Running | v1.0.49 Running | OK |
| origin/main backend | 71e66c9 | 71e66c9 | OK |

## 14. Gaps restants

- Push backend 2a14258 : en attente de GO explicite.
- Rebuild image backend v1.0.50-amazon-validation-pipeline-dev (PH-20.14D-TER) puis redeploy API DEV (qui fait le create) ET jobs-worker DEV.
- Re-trigger PH-20.14G apres redeploy pour valider le mapping en runtime.
- Deliverabilite finale dependante de mail-core-01 (KEY-323, contenu/stable).
- jobsWorker PROD toujours absent (apres validation DEV complete).
- Fichier untracked src/modules/marketplaces/amazon/amazon.routes.ts.bak (date 5 mai, hors chaine) a nettoyer hors phase ; NON commite.

## 15. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| Migration SQL / prisma migrate deploy / db push / ALTER | OUI | seul prisma generate (genere le client) |
| Mutation DB | OUI | 0 INSERT/UPDATE/DELETE |
| Build / docker push / deploy / kubectl apply | OUI | 0 |
| Trigger validation / retry outbound | OUI | 0 |
| Mail-core / MX / DNS | OUI | non touche |
| PROD | OUI | non touche |
| git push (sans GO) | OUI | origin/main = 71e66c9 |
| Hardcode tenant/user/email | OUI | aucun |

## 16. Rollback

Trivial : le commit 2a14258 ne touche qu une ligne de schema.prisma (ajout @map). Revert = git revert 2a14258 (non pousse, donc reset local du HEAD a 71e66c9 suffit avant push). Aucun effet DB a annuler (aucune migration). jobs-worker DEV inchange.

Phrase cible : GO SOURCE PATCH OUTBOUNDEMAIL SCHEMA MAP DEV READY PH-SAAS-T8.12AS.20.14C-TER

STOP.
