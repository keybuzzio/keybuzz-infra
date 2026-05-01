# Doctrine Seller-First — Refund Protection

> Derniere mise a jour : 2026-05-01
> Phase source : PH-SAAS-T8.12O
> Scope : toute surface visible (demo, playbooks, suggestions IA, templates)

---

## Principe fondamental

Le vendeur est le client KeyBuzz. Chaque message, suggestion IA, et sample visible doit proteger les interets economiques du vendeur : temps, argent, marge, reputation marketplace.

## Regles seller-first

### 1. Le remboursement est un DERNIER RECOURS

- Ne jamais proposer un remboursement comme premiere solution.
- Ne jamais ecrire "nous allons vous rembourser" en reponse automatique.
- Le remboursement n'intervient qu'apres : diagnostic, preuve, verification commande, et validation humaine si necessaire.

### 2. Empathie sans capitulation

- Toujours accuser reception et montrer de l'empathie.
- Ne jamais transformer l'empathie en promesse financiere.
- Formulations correctes : "nous comprenons", "nous prenons votre retour au serieux".
- Formulations interdites : "nous allons vous rembourser", "remplacement immediat sans frais", "vous n'aurez pas besoin de retourner".

### 3. Diagnostic avant compensation

Avant toute action corrective, toujours demander :
- Photo ou video du probleme
- Reference exacte du produit
- Numero de commande ou suivi
- Description precise du defaut

### 4. Solution proportionnee

| Situation | Solution proportionnee | Solution interdite |
|---|---|---|
| Couleur differente | Verifier reference, proposer echange si ecart confirme | Remboursement immediat |
| Produit defectueux | Demander preuve photo, analyser, proposer echange/avoir | Remplacement sans retour |
| Colis non recu | Verifier tracking, attendre delai, ouvrir enquete | Remboursement immediat |
| Avis negatif + defaut | Demander preuve, proposer solution apres analyse | Remplacement + remboursement au choix sans preuve |
| Client agressif | Escalade humaine | Ceder immediatement |

### 5. Escalade humaine obligatoire

Escalader a un humain dans ces cas :
- Commande haute valeur (> 100 EUR)
- Client agressif ou menacant
- Cas ambigu (preuve insuffisante)
- Risque A-to-Z ou litige marketplace
- Demande de remboursement repetee (pattern abusif)
- Promesse faite par erreur dans un echange precedent

### 6. Ne jamais dispenser de retour produit

- Un produit reclame comme defectueux doit etre retourne sauf exception validee humainement.
- "Vous n'aurez pas besoin de retourner" = perte seche pour le vendeur.
- Exception : produit < 10 EUR ou marchandise perissable.

## Differences marketplace vs boutique propre

| Aspect | Amazon / Octopia / Fnac | Boutique propre (Shopify, email) |
|---|---|---|
| Politique retour | Imposee par la marketplace | Definie par le vendeur |
| Risque A-to-Z / litige | Eleve (impacte metriques vendeur) | Faible |
| Delai de reponse | SLA marketplace (24-48h) | Flexible |
| Remboursement force | Amazon peut forcer le remboursement | Non |
| Bonus risque IA | Amazon +10, Octopia +5 (PH147) | 0 |

**Gap identifie** : le comportement IA ne distingue pas encore finement les regles par marketplace. Phase recommandee : `PH-SAAS-T8.12O.1-PLATFORM-AWARE-AI-BEHAVIOR`.

## Impact sur les surfaces visibles

### Sample Demo Wow (client-side)

Les messages sample visibles par les prospects doivent :
- Montrer l'IA comme un copilote intelligent, pas un distributeur de remboursements.
- Illustrer le diagnostic avant l'action.
- Ne jamais promettre de remboursement ou remplacement sans preuve.
- Montrer que KeyBuzz protege la marge du vendeur.

### Playbooks futurs

Les playbooks SAV doivent :
- Inclure une etape "demande de preuve" avant toute compensation.
- Ne jamais avoir "rembourser" comme action par defaut.
- Inclure une etape "escalade humaine" pour les cas a risque.

### Templates de reponse

Les templates pre-rediges doivent :
- Proposer des formulations seller-first.
- Ne pas contenir de promesse de remboursement.
- Inclure des variables pour le diagnostic (photo, reference, tracking).

## Exemples OK vs interdits

### OK

> "Nous comprenons votre deception. Pourriez-vous nous envoyer une photo du produit recu ? Cela nous permettra de verifier la situation et de vous proposer la solution la plus adaptee."

### INTERDIT

> "Nous sommes desoles, nous allons vous rembourser."

### OK

> "Nous prenons votre retour tres au serieux. Des reception de la preuve, nous analyserons la situation et vous proposerons un echange, un avoir ou une autre solution adaptee."

### INTERDIT

> "Nous vous proposons un remplacement immediat sans frais. Vous n'aurez pas besoin de retourner le produit defectueux."
