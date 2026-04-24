# Regles et risques KeyBuzz

> Derniere mise a jour : 2026-04-21

## Regles absolues

- Repondre et documenter en francais.
- DEV avant PROD.
- PROD uniquement avec validation explicite de Ludovic.
- Patch minimal, pas de refonte opportuniste.
- Un build/deploy par phase si possible.
- Repo clean obligatoire avant build.
- Build depuis Git, jamais depuis runtime/pod/dist/SCP.
- Branche/source de build obligatoire et explicite par repo/service dans chaque prompt Cursor.
- Aucun build si la branche, le commit et le repo ne correspondent pas a la source validee de la phase.
- Pas de `:latest`.
- Pas de hardcode tenant, URL, credentials.
- Pas d'exposition des couts LLM au client, uniquement KBActions.
- Multi-tenant strict partout.
- Toujours documenter image avant/apres, commit, rollback, validation.
- Chaque retour CE doit inclure le chemin complet du rapport final cree, pour lecture locale directe.

## Source de verite

Ordre de confiance :

1. Rapport de phase recent avec validation reelle.
2. Code source Git propre correspondant a l'image.
3. Manifest GitOps.
4. DB/API logs/validation runtime.
5. Conversation exportee.
6. Vieux prompt de reprise.

Ne jamais supposer qu'un prompt de conversation est encore actuel. Toujours chercher un rapport posterieur.

## Risques majeurs connus

### Git/runtime drift

PH152 a prouve que certaines images avaient ete construites avec des fichiers non committe. Toute reconstruction doit passer par Git clean et pre-build check.

### Branche/source de build anti-regression

KeyBuzz n'est pas un projet conventionnel : beaucoup de regressions deviennent invisibles si une image est construite depuis une mauvaise branche, un vieux tag, un workspace dirty ou une source non alignee avec le fix DEV valide.

Tout prompt Cursor qui autorise un build doit donc verrouiller noir sur blanc, pour chaque repo/service concerne :

- le repo exact a builder;
- le remote Git attendu pour ce service;
- la branche autorisee;
- le commit de depart attendu;
- le commit de patch attendu apres modification;
- l'image runtime actuelle;
- l'image DEV validee quand il s'agit d'une promotion PROD;
- le tag cible immuable;
- le digest produit;
- le rollback image/manifest.

STOP obligatoire si :

- branche courante differente de la branche imposee;
- remote Git ne correspondant pas au service a builder;
- commit attendu absent de la branche;
- repo dirty ou fichiers source non-trackes non compris;
- build lance depuis un tag/checkout detache/worktree douteux;
- runtime et Git ne pointent pas vers la meme ligne de code;
- l'agent ne sait pas prouver quelle source exacte a ete buildusee.

Important : ne jamais appliquer automatiquement la branche d'un repo a un autre repo. Exemple connu : `keybuzz-api` utilise `ph147.4/source-of-truth` pour la ligne Autopilot API, mais `keybuzz-backend` est un repo distinct dont la source de verite observee est `main`. Un prompt multi-repo doit lister les branches par service.

### Tenant ID

Erreur recurrrente : utiliser localStorage ou display ID au lieu du canonical tenant ID.

Source fiable cote client :

```ts
const { currentTenantId } = useTenant();
```

### Plans et casse

`pro` vs `PRO` a deja provoque des incoherences. Les capabilities modernes attendent `STARTER`, `PRO`, `AUTOPILOT`.

### Autopilot gate

Pour PRO, l'etat documente est `maxMode='suggestion'`, donc l'autopilot ne doit pas generer de drafts. Modifier ce comportement pour tous les PRO est une decision produit, pas un bugfix technique banal.

### Dual DB

Ne pas confondre :

- `keybuzz_prod` : product/API DB.
- `keybuzz_backend_prod` : Prisma backend exclusif.

Amazon et certains flows peuvent toucher les deux.

### BFF incomplet

Beaucoup de features client dependent de routes BFF Next.js. Verifier :

- route presente;
- headers auth et `X-Tenant-Id`;
- URL interne correcte;
- mapping de reponse.

### K8s service port

Toujours appeler le port service K8s, pas le port container. Exemple documente :

- PROD API service : port 80, pas `:3001`.
- DEV API service : port 3001 si le service expose 3001.

### Inbox fragile

`InboxTripane.tsx` a ete reconstruit plusieurs fois et a connu des versions hybrides. Avant de modifier l'Inbox, lire PH152/PH153/PH154 et verifier la base actuelle.

### Marketing vs technique

Les docs marketing sont utiles pour le ton, les offres et l'acquisition. Elles ne doivent pas ecraser les rapports techniques.

## Stop conditions

Arreter et demander validation si :

- repo dirty non compris;
- divergence Git/runtime;
- PROD impliquee sans accord;
- changement de plan global;
- migration DB destructive;
- effet multi-tenant incertain;
- build necessite de recuperer du code depuis pod/runtime;
- le rapport le plus recent contredit le prompt initial.

## Checklist avant prompt Cursor

- Domaine exact identifie.
- Rapport recent lu.
- Etat DEV/PROD lu.
- Branche/source de build imposee si build possible.
- Risque multi-tenant formule.
- Scope interdit liste.
- Fichiers probables cites.
- Tests et rollback cites.
- STOP avant PROD explicite si necessaire.
- Chemin complet du rapport final demande explicitement dans le retour CE.
