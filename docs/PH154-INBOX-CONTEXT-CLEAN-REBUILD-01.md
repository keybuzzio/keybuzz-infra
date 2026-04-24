# PH154 — INBOX CONTEXT CLEAN REBUILD

> Date : 1 mars 2026 (execute 15 avril 2026)
> Phase : PH154-INBOX-CONTEXT-CLEAN-REBUILD-01
> Type : reconstruction controlee du panneau Contexte Inbox
> Environnement : DEV uniquement

---

## OBJECTIF

Reconstruire proprement le panneau lateral "Contexte" de l'Inbox avec :

- Differenciation des messages Amazon automatiques
- Meilleure lisibilite du contexte commande
- Mise en evidence des elements importants
- Aucun impact sur les autres fonctionnalites

---

## BASE


| Element         | Valeur                                                         |
| --------------- | -------------------------------------------------------------- |
| Branche source  | `consolidation/client-v3.5.63-inbox-m1-candidate` (PH153.10.2) |
| Branche PH154   | `ph154/inbox-context-rebuild`                                  |
| Commit          | `f20d48e`                                                      |
| Image DEV avant | `v3.5.63-ph151.2-case-summary-clean-dev`                       |
| Image PROD      | `v3.5.63-ph151.2-case-summary-clean-prod` (INCHANGEE)          |


---

## MODIFICATIONS EFFECTUEES

### Fichier unique modifie : `app/inbox/InboxTripane.tsx`


| #   | Modification                     | Lignes | Description                                                                                                                                                                                                        |
| --- | -------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | `isAmazonAutoMessage()` helper   | +14    | Fonction utilitaire de detection des messages auto-Amazon. Detecte via `isSystemNotification`, `conversationType === 'SYSTEM_NOTIFICATION'`, et patterns de contenu (notification automatique, do not reply, etc.) |
| 2   | Style bulle auto-Amazon          | +3     | Les messages inbound auto-Amazon ont un fond gris clair (`bg-gray-100`), bordure pointillee (`border-dashed`), au lieu du blanc classique                                                                          |
| 3   | Badge "Notification auto"        | +5     | Badge gris avec icone `Mail` affiche dans l'en-tete de chaque message auto-Amazon detecte                                                                                                                          |
| 4   | Couleur expediteur attenuee      | +2     | Le nom de l'expediteur est affiche en gris plus clair (`text-gray-400`) pour les messages auto-Amazon                                                                                                              |
| 5   | Badges header conversation       | +10    | Badge "Notification systeme" (gris, rond) si `isSystemNotification === true`. Badge "Demande de retour" (ambre, rond) si `conversationType === 'RETURN_REQUEST'`                                                   |
| 6   | Section Contexte titree          | +4     | Ajout d'un separateur horizontal et d'un titre "CONTEXTE" (micro-texte uppercase) au-dessus des liens contextuels                                                                                                  |
| 7   | Micro-badges liste conversations | +6     | Badge `auto` (gris) pour notifications systeme et `retour` (ambre) pour demandes de retour, visibles dans la liste de conversations (colonne gauche)                                                               |


**Total : 50 insertions, 2 suppressions — 1 seul fichier touche**

---

## COMPOSANTS TOUCHES


| Composant                    | Modifie ? | Raison                                      |
| ---------------------------- | --------- | ------------------------------------------- |
| `app/inbox/InboxTripane.tsx` | **OUI**   | Toutes les 7 modifications ci-dessus        |
| `TreatmentStatusPanel.tsx`   | NON       | Deja ameliore en PH153.10.2 (REASON_LABELS) |
| `OrderSidePanel.tsx`         | NON       | Pas de changement necessaire                |
| `SupplierPanel.tsx`          | NON       | Pas de changement necessaire                |
| `AISuggestionsPanel.tsx`     | NON       | Pas de changement necessaire                |
| Routes API                   | NON       | Aucune modification backend                 |


---

## PERIMETRES NON TOUCHES (confirmations)


| Zone                         | Modifie ? | Preuve                               |
| ---------------------------- | --------- | ------------------------------------ |
| `/start`                     | NON       | Aucun fichier app/start/* touche     |
| `/dashboard`                 | NON       | Aucun fichier app/dashboard/* touche |
| `/settings`                  | NON       | Aucun fichier app/settings/* touche  |
| `/billing`                   | NON       | Aucun fichier app/billing/* touche   |
| `src/features/tenant/`       | NON       | Aucun fichier tenant touche          |
| Auth / RBAC                  | NON       | Aucun fichier auth/middleware touche |
| Connecteurs (Amazon/Octopia) | NON       | Aucune route API modifiee            |


---

## BUILD ET DEPLOIEMENT


| Etape           | Resultat | Details                                                 |
| --------------- | -------- | ------------------------------------------------------- |
| Branch creation | OK       | `ph154/inbox-context-rebuild` depuis PH153.10.2         |
| Modifications   | OK       | 7/7 changements appliques, braces equilibrees (650/650) |
| Build Docker    | OK       | `v3.5.80-ph154-inbox-rebuild-dev` (279MB), `--no-cache` |
| Push GHCR       | OK       | Image poussee sur `ghcr.io/keybuzzio/keybuzz-client`    |
| Deploy DEV      | OK       | `kubectl set image` + rollout reussi                    |
| Pod Running     | OK       | 1/1 Running, demarrage 478ms                            |
| Logs propres    | OK       | Next.js 14.2.35, aucune erreur                          |
| PROD inchangee  | OK       | `v3.5.63-ph151.2-case-summary-clean-prod`               |


### Erreur corrigee pendant le build

Premier build echoue (erreur syntaxe JSX : `}` fermant manquant dans la modification #2). Corrige et re-build reussi au deuxieme essai.

---

## VALIDATION TECHNIQUE


| Critere                         | Resultat                                       |
| ------------------------------- | ---------------------------------------------- |
| Pod Running 1/1                 | OK                                             |
| Demarrage < 1s                  | OK (478ms)                                     |
| Aucune erreur console           | OK                                             |
| Image DEV correcte              | OK (`v3.5.80-ph154-inbox-rebuild-dev`)         |
| Image PROD inchangee            | OK (`v3.5.63-ph151.2-case-summary-clean-prod`) |
| Branche PH153.10.2 non modifiee | OK (nouvelle branche creee)                    |


---

## VALIDATION HUMAINE

**En attente de retour Ludovic.**

Checklist soumise :

- Inbox : panneau Contexte ameliore (titre + separateur)
- Inbox : differenciation messages auto-Amazon (fond gris, bordure pointillee, badge)
- Inbox : badges header (Notification systeme / Demande de retour)
- Inbox : micro-badges dans la liste conversations (`auto` / `retour`)
- `/start` : identique
- Dashboard : identique
- Settings : identique
- Billing : identique
- Suggestions IA : panneau lateral OK

---

## ROLLBACK (si necessaire)

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.63-ph151.2-case-summary-clean-dev \
  -n keybuzz-client-dev
```

---

## RESUME DES AMELIORATIONS VISUELLES

### Avant (v3.5.63)

- Tous les messages inbound : meme style blanc
- Aucune indication visuelle du type de conversation
- Section "Liens contextuels" sans titre ni separateur
- Liste conversations sans indication du type

### Apres (v3.5.80-ph154)

- Messages auto-Amazon : fond gris, bordure pointillee, badge "Notification auto", texte attenue
- Messages client : style blanc inchange (contraste renforce par differenciation)
- Header conversation : badges "Notification systeme" et "Demande de retour"
- Section Contexte : titre "CONTEXTE" + separateur horizontal
- Liste conversations : micro-badges `auto` (gris) et `retour` (ambre)

---

## VERDICT

**EN ATTENTE DE VALIDATION HUMAINE**

- Build : SUCCESS
- Deploy : SUCCESS
- Validation technique : SUCCESS
- Validation humaine : PENDING
- Non-regression : A CONFIRMER

---

## CONFIRMATION NO-TOUCH

- Aucune modification `/start`
- Aucune modification Dashboard
- Aucune modification Settings
- Aucune modification Billing
- Aucune modification Tenant/RBAC
- Aucune modification API backend
- Aucune modification connecteurs
- Aucun composant archive importe
- PROD inchangee

