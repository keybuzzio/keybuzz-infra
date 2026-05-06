# Standard prompts CE KeyBuzz

> Derniere mise a jour : 2026-04-29
> Source modele obligatoire : `C:\DEV\KeyBuzz\PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01`

## Regle centrale

Tous les prompts destines a Cursor Executor (CE) doivent suivre le format long KeyBuzz du modele `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01`.

Ce standard est obligatoire des qu'une phase touche au code, build, deploy, DB, GitOps, tracking, billing, SaaS, Admin, Website, Client, API, PROD, ou a une source de verite.

Ne pas envoyer de prompt CE court dans ces cas.

Pour les phases IA, Inbox, messaging, connecteurs, commandes, tracking colis, playbooks, escalades, Agent KeyBuzz ou autopilot, le prompt doit obligatoirement inclure une section "AI feature parity / anti-regression". Cette section force CE a rechercher les rapports PH pertinents dans `keybuzz-infra/docs`, a comparer les promesses documentees avec la source/runtime actuelle, et a noter dans Linear tout ecart confirme. Cette regle reste obligatoire apres resume/summarize de conversation : ne pas repartir d'une memoire courte sans relire les sources de verite.

## Structure obligatoire

Chaque prompt CE doit contenir au minimum :

1. En-tete
   - `Prompt CE - <PHASE>`
   - Role : Cursor Executor (CE)
   - Projet
   - Phase
   - Environnement
   - Type
   - Priorite

2. Objectif
   - objectif metier/technique clair
   - liste des briques incluses
   - resultat attendu observable
   - hors scope explicite

3. Sources de verite a relire
   - rapports PH recents
   - AI_MEMORY utile
   - process-lock / git-source-of-truth / RULES_AND_RISKS
   - tout rapport dont depend la phase

4. Contexte impose
   - repos/services concernes
   - branches obligatoires
   - HEAD attendu ou descendant direct
   - images DEV/PROD actuelles
   - verites deja prouvees
   - decision produit importante

5. Regles absolues
   - DEV avant PROD
   - PROD seulement si explicitement demande
   - GitOps strict
   - repo clean obligatoire
   - commit + push avant build
   - build-from-git obligatoire
   - clone temporaire propre si build
   - pre-build-check obligatoire
   - tags immuables
   - digest documente
   - rollback documente

6. Bastion / SSH
   - bastion obligatoire : `install-v3`
   - IP obligatoire : `46.62.171.61`
   - toute autre IP / bastion => STOP
   - ne jamais utiliser `51.159.99.247`

7. Interdit
   - `git reset --hard`
   - `git clean`
   - build depuis workspace dirty
   - build depuis runtime/pod/dist/SCP
   - `kubectl set image`
   - `kubectl set env`
   - `kubectl patch`
   - `kubectl edit`
   - secrets dans logs/rapport/bundle
   - hardcode tenant/URL/credentials/user/seller/marketplace/pays/email test
   - faux events tracking
   - masquer un echec de validation

8. Etapes numerotees
   - ETAPE 0 - PREFLIGHT
   - verification source
   - verification schema/DB si concerne
   - patch minimal
   - build safe si necessaire
   - GitOps si necessaire
   - deploy si necessaire
   - validation structurelle
   - validation runtime/navigateur
   - matrice AI feature parity / anti-regression si la phase touche IA, messages, connecteurs, commandes, tracking colis, playbooks ou escalades
   - preuves DB/API/logs
   - non-regression
   - gaps restants
   - rollback GitOps
   - rapport final

9. Tables attendues
   - repo / branche / HEAD / dirty / verdict
   - brique / point verifie / resultat
   - endpoint / attendu / resultat
   - fichier / changement / risque
   - image avant / image apres / rollback
   - test / attendu / resultat

10. Rapport final obligatoire
    - chemin complet `keybuzz-infra/docs/<PHASE>.md`
    - preflight
    - source
    - patch
    - build
    - GitOps
    - validation
    - preuves
    - non-regression
    - digests
    - rollback
    - gaps
    - PROD inchangee ou modifiee explicitement
    - chemin complet du rapport dans le resume CE

11. Verdict attendu
    - phrase finale normalisee
    - `STOP` en fin de prompt

## Verrous source-of-truth

Les branches ne doivent jamais etre supposees. Les rappeler explicitement par repo :

- `keybuzz-api` : `ph147.4/source-of-truth`
- `keybuzz-client` : `ph148/onboarding-activation-replay`
- `keybuzz-admin-v2` : `main`
- `keybuzz-website` : `main`
- `keybuzz-infra` : `main`

STOP si :

- branche incorrecte
- remote incorrect
- HEAD attendu absent
- repo dirty non compris
- fichiers untracked source non compris
- runtime != manifest
- build source impossible a prouver
- agent tente de corriger avec `git reset --hard` ou `git clean`

## GitOps strict

Promotion et rollback doivent passer par manifest GitOps :

1. modifier manifest
2. commit
3. push
4. `kubectl apply -f <manifest>`
5. `kubectl rollout status`
6. verifier manifest = runtime = annotation

Ne jamais documenter ni utiliser `kubectl set image` comme rollback ou deploy.
Un rapport de phase qui contient `kubectl set image`, `kubectl set env`, `kubectl patch` ou `kubectl edit` dans une procedure de deploy/rollback est non conforme, meme si la commande n'a pas ete executee. La phase suivante doit corriger le rapport avant toute promotion PROD.

## Tracking / billing

Pour les phases acquisition, trial, signup, billing ou SaaS :

- `signup_complete` = plan choisi au signup
- `purchase` = paiement reel uniquement
- aucun faux event CAPI/GA4
- aucun tag Google Ads AW direct sans decision explicite
- ne pas polluer `/metrics`
- ne pas confondre lifecycle/product events et conversions marketing

## Reflexe avant d'ecrire un prompt CE

1. Relire ce fichier.
2. Relire le modele local `C:\DEV\KeyBuzz\PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` si le prompt est sensible.
3. Relire les rapports PH les plus recents.
4. Si la phase touche l'IA, l'Inbox, les messages, les connecteurs, les commandes, le tracking colis, les playbooks ou les escalades : rechercher les rapports PH pertinents dans `keybuzz-infra/docs` et imposer une matrice anti-regression.
5. Identifier le bon agent CE : SaaS, Admin, Website, API, Studio, Infra.
6. Ecrire le prompt en format long, avec STOP conditions.
7. Ne pas livrer de prompt court par confort.
