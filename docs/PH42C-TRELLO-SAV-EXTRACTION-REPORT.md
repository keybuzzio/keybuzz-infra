# PH42C — Trello SAV Extraction Report

> Date : 2026-03-08
> Auteur : Cursor Agent (PH42C)
> Mode : READ ONLY — Extraction uniquement
> Aucune modification code, aucun deploiement

---

## 1. OBJECTIF

Extraire l'integralite du SAV historique eComLG depuis le board Trello SAV afin de creer un dataset d'apprentissage pour l'IA conversationnelle KeyBuzz.

---

## 2. SOURCE

| Attribut | Valeur |
|---|---|
| Board | SAV |
| URL | `https://trello.com/b/o4yb5J9S/sav` |
| Board ID | `o4yb5J9S` (internal: `6835aacbe09c78e323c5f3f8`) |
| Workspace | eComLG |
| Membres | Ludovic GONTHIER, Melanie |
| Export | JSON natif Trello |

---

## 3. STRUCTURE DU BOARD

### Listes (10 actives, 6 archivees)

| Liste | Cartes | Statut |
|---|---|---|
| ⚠️ RETOURS | 10 | Active |
| ✅ A traiter | 2 | Active |
| En attente de reponse client | 7 | Active |
| 📦 Problemes de livraison UPS | 0 | Active |
| 🔄 en attente de dossier DS (mail fait) | 1 | Active |
| ⏰ DS OUVERT - PRODUIT NON ENVOYE | 3 | Active |
| 🛠️ DS OUVERT - EN COURS DE TRAITEMENT | 2 | Active |
| ✔️ Resolu / Clos | 152 | Active |
| ✅ DS CLOTURE | 7 | Active |
| 🔁 Retractation en cours | 4 | Active |
| NOTICE | 5 | Archivee |
| Fraude / Arnaque | 2 | Archivee |
| ds ancien | 12 | Archivee |

### Custom Fields

| Champ | Type | Valeurs |
|---|---|---|
| Market place | Liste | Fnac, Darty, Cdiscount, Amazon, Rue du commerce, Rakuten |
| Priority | Liste | Highest, High, Medium, Low, Lowest, Not sure |
| ✅ A faire | Liste | Remboursement, A reexpedier, Echange anticipe, En attente, A surveiller |
| PEC | Liste | Garantie externe, Garantie Terra, Avoir Terra |
| Recue chez Terra | Liste | OUI, NON |

### Labels

| Couleur | Label |
|---|---|
| purple_light | AMAZON |
| orange | OCTOPIA |
| sky | FNAC |
| lime_light | DARTY |
| red | Priorite |

---

## 4. DONNEES EXTRAITES

### Volume

| Metrique | Valeur |
|---|---|
| Cartes totales | **207** |
| Avec commentaires | **72** |
| Avec pieces jointes | **62** |
| Avec checklists | **81** |
| Actions (comments + moves + updates) | **1000** |
| Commentaires SAV | **187** |
| Mouvements de cartes | **134** |
| Pieces jointes | **99** |

### Distribution par marketplace

| Marketplace | Cartes | % |
|---|---|---|
| Amazon | 87 | 42.0% |
| Cdiscount | 49 | 23.7% |
| Fnac | 36 | 17.4% |
| Darty | 14 | 6.8% |
| Rue du Commerce | 10 | 4.8% |
| Unknown | 7 | 3.4% |
| Octopia | 2 | 1.0% |
| Rakuten | 2 | 1.0% |

### Distribution par type de decision

| Decision | Cartes | % |
|---|---|---|
| refund | 77 | 37.2% |
| unknown | 55 | 26.6% |
| replace | 30 | 14.5% |
| warranty_claim | 24 | 11.6% |
| shipping_investigation | 12 | 5.8% |
| ask_info | 7 | 3.4% |
| fraud | 2 | 1.0% |

---

## 5. CROISEMENT AMAZON

| Metrique | Valeur |
|---|---|
| Conversations Amazon PH42B | 100 |
| Cartes Trello Amazon | 87 |
| **Correspondances exactes** | **11** |

Les 11 correspondances sont basees sur le match exact `order_id` entre les noms de cartes Trello et les `extracted_order_id` du dataset Amazon.

Les 76 cartes Amazon sans correspondance s'expliquent par :
- Conversations Amazon anterieures a la periode d'extraction SC (jan-mars 2026)
- Order IDs non presents dans les 100 conversations extraites
- Differences de format (tirets, espaces)

---

## 6. DATASET D'ENTRAINEMENT

### Structure

Le fichier `keybuzz_sav_training_dataset.json` contient **72 cas utilisables** avec :

```
case_id             — identifiant unique (trello-NNN)
order_id            — numero de commande
marketplace         — marketplace detectee
issue_type          — type de probleme (return, delivery_issue, warranty_*, etc.)
decision_type       — decision SAV detectee (refund, replace, ask_info, etc.)
priority            — priorite si definie
status              — open / closed
refund_detected     — boolean
ds_numbers          — numeros de dossier SAV (DS17XXXXX)
description         — description de la carte
support_responses   — reponses du support (texte, auteur, date)
client_context      — contexte Amazon si correspondance trouvee
checklist_summary   — resume des items de checklist
workflow            — historique des mouvements entre listes
```

### Distribution decisions (training set)

| Decision | Cas | % |
|---|---|---|
| refund | 24 | 33.3% |
| warranty_claim | 24 | 33.3% |
| unknown | 13 | 18.1% |
| ask_info | 7 | 9.7% |
| replace | 3 | 4.2% |
| shipping_investigation | 1 | 1.4% |

### Distribution marketplace (training set)

| Marketplace | Cas | % |
|---|---|---|
| amazon | 57 | 79.2% |
| cdiscount | 9 | 12.5% |
| fnac | 3 | 4.2% |
| rue du commerce | 2 | 2.8% |
| darty | 1 | 1.4% |

---

## 7. ANONYMISATION

| Donnee | Traitement |
|---|---|
| Noms clients | Non presents dans les cartes Trello (OK) |
| Emails | Masques par `[EMAIL]` |
| Telephones | Masques par `[PHONE]` |
| Noms auteurs hors team | Anonymises (initiales) |
| Noms team (Melanie, Ludovic) | Conserves (support interne) |
| Order IDs | Conserves (necessaires pour le croisement) |
| Tracking numbers | Conserves (logistique, pas PII) |

Verification automatique :
- **0 email** detecte dans le dataset final
- **0 telephone** detecte dans le dataset final

---

## 8. WORKFLOW SAV DETECTE

L'analyse des mouvements de cartes revele le workflow SAV reel :

```
1. Carte creee dans "⚠️ RETOURS" ou "✅ A traiter"
2. Mouvement vers "En attente de reponse client" (info demandee)
3. Si garantie : "🔄 en attente de dossier DS"
4. Ouverture dossier : "⏰ DS OUVERT - PRODUIT NON ENVOYE"
5. Traitement : "🛠️ DS OUVERT - EN COURS"
6. Resolution : "✔️ Resolu / Clos" ou "✅ DS CLOTURE"
```

### Processus de garantie Terra (fournisseur)
1. Creation d'un dossier SAV (DS17XXXXX)
2. Envoi de la "feuille SAV" au fournisseur
3. Attente de validation/prise en charge
4. Retour produit chez Terra/Wortmann
5. Remplacement ou avoir
6. Reexpedition au client

### Patterns de decisions humaines cles
- **Demande de coordonnees** avant tout envoi d'etiquette retour
- **Demande de preuves** (photos) pour produits defectueux
- **Echange anticipe** quand le stock le permet
- **Remboursement** en dernier recours ou retractation legale
- **Tracking systematique** (FedEx, Mondial Relay, UPS)
- **Feuille SAV + etiquette** = processus standard de retour

---

## 9. FICHIERS PRODUITS

| Fichier | Taille | Description |
|---|---|---|
| `artifacts/trello-sav-raw.json` | 465 KB | 207 cas complets avec timeline, commentaires, PJ |
| `artifacts/trello-sav-cleaned.json` | 439 KB | 207 cas nettoyes (timeline filtree) |
| `artifacts/keybuzz_sav_training_dataset.json` | 106 KB | 72 cas d'entrainement IA |
| `scripts/trello-sav-extractor.py` | — | Script d'extraction Python |

### Source (NE PAS MODIFIER)

| Fichier | Emplacement |
|---|---|
| Export JSON Trello brut | `C:\Users\ludov\Downloads\Conversatoion\o4yb5J9S - sav.json` |

---

## 10. INSIGHTS POUR L'IA KEYBUZZ

### Observations cles

1. **Le remboursement n'est JAMAIS la premiere action** — le support demande toujours des infos d'abord
2. **Le processus de garantie (DS) est la voie privilegiee** pour les produits defectueux
3. **Les echanges anticipes sont rares** — reserves aux cas urgents
4. **Le tracking est systematiquement partage** avec le client
5. **Les dossiers UPS** sont geres separement (liste dediee)
6. **La fraude est rare** (2 cas sur 207) mais identifiee et traitee
7. **Multi-marketplace** — le meme processus SAV s'applique quelle que soit la marketplace

### Recommandations pour PH42D/PH43

1. **Fusionner** les datasets Amazon messages + Trello SAV pour avoir le contexte complet
2. **Enrichir les 11 correspondances** avec le dialogue complet client-support
3. **Utiliser les 72 cas d'entrainement** pour affiner les policies SAV (PH41)
4. **Les checklists** fournissent un workflow machine-readable pour les playbooks
5. **Les DS numbers** permettent de tracker les dossiers fournisseur
6. **Augmenter le corpus** avec de nouvelles extractions Amazon SC

---

## 11. STOP POINT

- Aucune modification de code
- Aucun deploiement
- Extraction uniquement
- Board Trello intact (aucune ecriture)

**Attente validation Ludovic avant PH42D — Fusion datasets.**
