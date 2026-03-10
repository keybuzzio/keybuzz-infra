# PH42D — SAV Dataset Fusion Report

> Date : 8 mars 2026
> Mode : READ ONLY — Transformation de donnees uniquement
> Aucune modification de code, aucun deploiement

---

## 1. Objectif

Fusionner les 3 datasets produits par PH42A/B/C en un dataset unifie pret pour
l'entrainement IA (PH43). Les sources :

| Source | Fichier | Volume |
|--------|---------|--------|
| Amazon Seller Central | `amazon-messages-cleaned.json` | 100 conversations, 623 messages |
| Trello SAV eComLG | `trello-sav-cleaned.json` | 207 dossiers SAV |
| Training PH42C | `keybuzz_sav_training_dataset.json` | 72 cas enrichis |

---

## 2. Strategie de matching

4 niveaux appliques sequentiellement :

| Niveau | Methode | Resultat |
|--------|---------|----------|
| L1 | Match exact `order_id` (Amazon format `\d{3}-\d{7}-\d{7}`) | **11 matchs** |
| L2 | Match `order_id` normalise (sans espaces/tirets) | **0 matchs supplementaires** |
| L3 | Proximite date (< 14j) + marketplace Amazon + mots cles communs | **0 matchs** |
| L4 | Non-apparie → conserve individuellement | **285 enregistrements** |

### Pourquoi le taux de matching est faible (3.7%)

1. **Periodes differentes** — L'extraction Amazon SC couvre jan-mars 2026 (~100 conversations).
   Le board Trello couvre une periode plus large avec 207 dossiers.
2. **49/100 conversations Amazon** ont un `order_id` extractible.
3. **82/207 cas Trello** ont un order_id au format Amazon.
4. Les 11 matchs representent les cas ou les memes commandes apparaissent
   dans les deux systemes simultanement.

Ce taux faible N'est PAS un probleme pour le training IA : les enregistrements
non-apparies restent individuellement exploitables.

---

## 3. Dataset fusionne — Volume

| Categorie | Count |
|-----------|-------|
| **Total enregistrements** | **296** |
| Matched high confidence (L1) | 11 |
| Matched medium confidence (L2/L3) | 0 |
| Unmatched (Amazon-only) | 89 |
| Unmatched (Trello-only) | 196 |

---

## 4. Qualite des donnees

### Score de qualite

Chaque enregistrement recoit un `data_quality_score` (0-1) pondere :

| Critere | Poids |
|---------|-------|
| Presence `order_id` | 0.15 |
| Messages client | 0.20 |
| Messages vendeur | 0.15 |
| Decision Trello connue | 0.15 |
| Workflow timeline | 0.10 |
| Marketplace identifiee | 0.05 |
| Type de probleme identifie | 0.05 |
| Confiance du match (high) | 0.15 |

### Distribution

| Seuil | Count | % |
|-------|-------|---|
| >= 0.70 (excellent) | 11 | 3.7% |
| >= 0.50 (exploitable) | 180 | 60.8% |
| >= 0.35 (correct) | 283 | 95.6% |
| >= 0.20 (partiel) | 296 | 100% |
| < 0.15 (inutilisable) | 0 | 0% |

### Couverture

| Metrique | Count |
|----------|-------|
| Avec messages client | 87 |
| Avec messages vendeur | 147 |
| Avec dialogue complet (client + vendeur) | 70 |
| Avec workflow SAV | 207 |
| Avec labels d'entrainement | 140 |

---

## 5. Repartition par marketplace

| Marketplace | Count |
|-------------|-------|
| Amazon | 176 |
| Cdiscount | 49 |
| Fnac | 36 |
| Darty | 14 |
| Rue du Commerce | 10 |
| Rakuten | 2 |
| Octopia | 2 |
| Unknown | 7 |

---

## 6. Repartition par type de decision

| Decision | Count |
|----------|-------|
| Refund (remboursement) | 77 |
| Unknown (non classifie) | 55 |
| Replace (remplacement) | 30 |
| Warranty claim (garantie) | 24 |
| Shipping investigation (enquete livraison) | 12 |
| Ask info (demande d'information) | 7 |
| Fraud (fraude) | 2 |

---

## 7. Labels d'entrainement

Chaque enregistrement possede des `training_labels` booleens :

| Label | Detecte |
|-------|---------|
| `refund_detected` | 77 cas |
| `replacement_detected` | 30 cas |
| `warranty_claim_detected` | 24 cas |
| `ask_info_detected` | 7 cas |
| `fraud_detected` | 2 cas |
| `good_outcome` (cloture reussie) | variable |

---

## 8. Les 11 cas haute confiance

Ces cas ont un score de qualite de **1.0** — ils contiennent :
- Le dialogue complet client/vendeur (Amazon SC)
- Le dossier SAV Trello (decision, workflow, commentaires)
- L'`order_id` verifie dans les deux systemes

| Case ID | Order ID | Decision | Client msgs | Seller msgs |
|---------|----------|----------|-------------|-------------|
| trello-237 | 405-7439266-2606700 | refund | 5 | 4 |
| trello-236 | 404-1853823-8660364 | refund | 2 | 3 |
| trello-238 | 171-2919390-9288327 | refund | 5 | 3 |
| trello-234 | 404-6955363-1987535 | refund | 1 | 4 |
| trello-222 | 171-9083409-7504352 | warranty_claim | 4 | 6 |
| trello-166 | 171-9818805-2516327 | warranty_claim | 3 | 7 |
| trello-232 | 171-8730680-4604312 | refund | 2 | 2 |
| trello-228 | 404-6579870-0180365 | refund | 3 | 5 |
| trello-231 | 407-9841500-4607547 | warranty_claim | 5 | 4 |
| trello-235 | 405-5896794-6973164 | refund | 3 | 3 |
| trello-229 | 408-0793090-4682753 | warranty_claim | 3 | 3 |

---

## 9. Securite et anonymisation

| Verification | Resultat |
|-------------|----------|
| Emails dans les textes | **0 detecte** |
| Numeros de telephone | **0 detecte** |
| Noms clients anonymises | Oui (initiales uniquement) |
| Order IDs | Conserves (necessaires pour le matching) |

---

## 10. Schema du dataset

```json
{
  "case_id": "trello-237",
  "marketplace": "amazon",
  "order_id": "405-7439266-2606700",
  "conversation_id": "conv-xxx",
  "buyer_name": "A.B.",
  "issue_type": "return",
  "customer_messages": [
    { "date": "...", "text": "...", "source": "amazon_sc" }
  ],
  "seller_messages": [
    { "date": "...", "text": "...", "source": "amazon_sc" },
    { "date": "...", "text": "...", "author": "support", "source": "trello" }
  ],
  "trello_decision_type": "refund",
  "workflow_timeline": [
    { "date": "...", "type": "created", "detail": "..." }
  ],
  "attachments": [],
  "order_context": {
    "order_value": 0,
    "currency": "EUR",
    "product_title": "",
    "tracking": "",
    "status": "closed"
  },
  "training_labels": {
    "refund_detected": true,
    "replacement_detected": false,
    "warranty_claim_detected": false,
    "ask_info_detected": false,
    "fraud_detected": false,
    "good_outcome": true
  },
  "match_confidence": "high",
  "match_level": 1,
  "match_detail": "exact_order_id:405-7439266-2606700",
  "data_quality_score": 1.0,
  "data_sources": ["amazon_sc", "trello"]
}
```

---

## 11. Cas exploitables pour PH43

Pour le training IA, les sous-ensembles recommandes :

| Usage | Critere | Count |
|-------|---------|-------|
| **Fine-tuning reponses IA** | Score >= 0.50 + dialogue complet | 28 |
| **Policy extraction** | Score >= 0.50 + labels training | 137 |
| **Decision classification** | Decision connue (non-unknown) | 152 |
| **Workflow learning** | Avec timeline SAV | 207 |
| **Gold standard** | Match L1 (score 1.0) | 11 |

---

## 12. Fichiers produits

| Fichier | Taille | Description |
|---------|--------|-------------|
| `artifacts/keybuzz_sav_fused_dataset.json` | 586 KB | Dataset complet (296 records) |
| `artifacts/keybuzz_sav_fused_dataset_high_confidence.json` | 62 KB | Haute confiance uniquement (11 records) |
| `artifacts/keybuzz_sav_fusion_audit.csv` | 36 KB | Audit CSV (toutes les lignes avec metriques) |
| `keybuzz-infra/docs/PH42D-SAV-DATASET-FUSION-REPORT.md` | ce fichier | Rapport de fusion |

---

## 13. Recommandations pour PH43

1. **Priorite 1** — Utiliser les 11 cas haute confiance comme "gold standard" pour valider
   les policies IA generees.
2. **Priorite 2** — Les 137 cas avec labels (refund/replace/warranty) sont directement
   exploitables pour entrainer la classification de decisions SAV.
3. **Priorite 3** — Les 55 cas "unknown" necessitent une revue manuelle pour classifier
   la decision (potentiel d'enrichissement).
4. **Enrichissement futur** — Augmenter le volume de conversations Amazon extraites
   (actuellement 100) pour ameliorer le taux de matching.
5. **Cross-marketplace** — Les 120 cas non-Amazon (Cdiscount, Fnac, Darty) sont precieux
   pour entrainer l'IA sur du multi-marketplace.

---

## STOP POINT

Aucune modification de code. Aucun deploiement.
Attente validation Ludovic avant PH43.
