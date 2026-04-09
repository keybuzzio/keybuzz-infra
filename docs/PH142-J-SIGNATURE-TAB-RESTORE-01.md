# PH142-J — Signature Tab Restore

> Date : 1 mars 2026
> Statut : DEV + PROD deployes

---

## Objectif

Restaurer l'onglet "Signature" dans la page Settings du client.
Le composant `SignatureTab.tsx` existait (256 lignes) mais n'etait plus importe ni rendu dans `app/settings/page.tsx`.

## Cause racine

Regression introduite lors du Sprint D16 (decomposition settings, fevrier 2026).
Les 8 onglets decomposed ont ete importes, mais `SignatureTab` a ete oublie lors du refactoring.

## Impact

- L'utilisateur ne pouvait plus modifier sa signature depuis l'UI
- La signature restait fonctionnelle cote backend (injection outbound + IA) avec les valeurs existantes en DB
- Regression purement UI, aucune perte de donnees

## Corrections appliquees (6 modifications dans `app/settings/page.tsx`)

| # | Modification | Ligne |
|---|---|---|
| 1 | Ajout `Pen` dans les imports lucide-react | 4 |
| 2 | Import `SignatureTab` depuis `./components/SignatureTab` | 23 |
| 3 | Ajout `"signature"` dans le type union `activeTab` | 26 |
| 4 | Ajout `{ id: "signature", label: "Signature", icon: Pen }` dans le tableau `tabs` | 156 |
| 5 | Exclusion de l'onglet signature du bouton "Enregistrer" global (le composant a son propre bouton) | 179 |
| 6 | Ajout `{activeTab === "signature" && <SignatureTab />}` dans le rendu conditionnel | 217 |

## Tests realises

### Test UI (navigateur DEV)
- Navigation vers /settings : OK
- Onglet "Signature" visible dans la barre d'onglets : OK
- Clic sur "Signature" : formulaire affiche avec les 3 champs (entreprise, expediteur, fonction) : OK
- Bouton "Enregistrer" propre au composant : OK
- Note informative "Identique sur tous les canaux" : OK

### Non-regression
- Onglet "Entreprise" : OK (formulaire avec donnees pre-remplies)
- Onglet "Intelligence Artificielle" : OK
- Onglet "Agents" : OK
- Tous les autres onglets : fonctionnels
- Backend signature (injection outbound, IA) : non touche

## Image deployee

| Env | Image | Status |
|---|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.190-signature-tab-restore-dev` | Deploye |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.190-signature-tab-restore-prod` | Deploye |

## Rollback

```bash
# DEV
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.189-draft-lifecycle-kbactions-dev -n keybuzz-client-dev
# PROD
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.189-draft-lifecycle-kbactions-prod -n keybuzz-client-prod
```

## GitOps

- `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` mis a jour
- `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` mis a jour
