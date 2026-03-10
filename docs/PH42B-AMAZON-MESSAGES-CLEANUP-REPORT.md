# PH42B — Amazon Messages Cleanup Report

> Date: 2026-03-08
> Source: `sc-messages-ecomlg-2026-03-08-01.json`
> Pipeline: PH42B-v1

---

## 1. Vue d'ensemble

| Metrique | Valeur |
|---|---|
| Conversations totales | 100 |
| Messages totaux | 623 |
| Messages propres | 477 |
| Messages pollues (UI/HTML) | 146 |
| Messages dupliques | 57 |
| Messages reclassifies (sender) | 142 |
| Pieces jointes | 104 |

---

## 2. Extraction buyer_name

| Metrique | Valeur |
|---|---|
| Noms extraits | 100 / 100 |
| Taux de succes | 100% |
| Non trouves | 0 |
| Confiance | 0.95 (regex sur subject) |

**Methode** : extraction via regex `^(.+?)(\d{1,2}\s*(Jan|Feb|Mar)\s*\d{4})` sur le champ `subject`.
Le nom du client est la partie avant la date concatenee dans le sujet de la sidebar Amazon.

### Exemples de noms extraits
| Subject (debut) | Nom extrait |
|---|---|
| `Daniel7 Mar 2026Demande...` | Daniel |
| `D'AGOSTINO5 Mar 2026...` | D'AGOSTINO |
| `Jean-Pierre27 Feb 2026...` | Jean-Pierre |
| `BitColossEnterprise12 Feb...` | BitColossEnterprise |
| `CONFIGBIT,6 Mar 2026...` | CONFIGBIT |

---

## 3. Extraction order_id

| Metrique | Valeur |
|---|---|
| Order IDs extraits | 49 / 100 |
| Taux de succes | 49% |
| Depuis messages Amazon | 31 (confiance 0.99) |
| Depuis subject | 18 (confiance 0.80-0.90) |
| Non trouves | 51 |

**Methode** :
1. **Priorite 1** : messages Amazon systeme contenant "Numero de commande : XXX-XXXXXXX-XXXXXXX" — confiance **0.99**
2. **Priorite 2** : regex order ID unique dans le corps des messages — confiance **0.85**
3. **Priorite 3** : extraction depuis le subject "(Commande : XXX-...)" — confiance **0.80-0.90**

**Bug original** : le champ `original_order_id` du JSON brut etait identique pour les 100 conversations
(`259-9447880-2637437`) a cause d'un bug dans le DOM scraper. Le champ `extracted_order_id` contient la valeur corrigee.

---

## 4. Detection de pollution

Messages parasites captures par l'extracteur (elements UI, panneau commande, boutons) :

| Type | Tag | Description |
|---|---|---|
| Labels UI | `ui_label` | "Purchase date", "Qty: N", "ID: BXXXXXXX" |
| Panneau commande | `order_panel_leak` | Infos produit du panneau lateral ("Batterie AGM...Qty: 2ID: B07HKD8LWQ") |
| Boutons UI | `ui_button` | "Refund Order" |
| Notices UI | `ui_notice` | "This order is currently not eligible for a refund." |
| Contenu court | `too_short` | Messages < 4 caracteres sans contenu exploitable |
| HTML | `html_fragment` | Fragments HTML captures |
| JS | `js_fragment` | Code JavaScript parasite |

Les messages pollues sont marques `is_polluted: true` et **conserves** dans le JSON pour tracabilite.
Ils doivent etre **filtres** avant ingestion dans la base de connaissances.

---

## 5. Reclassification sender_type

| Correction | Count |
|---|---|
| buyer → seller (signature eComLG detectee) | 137 |
| seller → buyer | 0 |
| * → amazon_system (template Amazon detecte) | 5 |
| amazon_system → * | 0 |
| **Total reclassifies** | **142** |

**Methode** :
- Signatures eComLG : "Melanie - eComLG", "Cordialement, Melanie", "Service Client eComLG" → `seller`
- Templates Amazon : "Cher Seller Amazon", "Merci de repondre dans les 48 heures" → `amazon_system`
- Position originale preservee comme fallback (confiance 0.80)
- Multi-langue : FR, ES, IT, EN, PT, NL, DE

---

## 6. Qualite par conversation

| Niveau | Count | % | Critere |
|---|---|---|---|
| Excellent (≥ 0.90) | 46 | 46% | Order + Name + messages propres |
| Bon (0.75-0.89) | 53 | 53% | 1 champ manquant ou quelques doublons |
| Moyen (0.50-0.74) | 1 | 1% | Plusieurs problemes |
| Faible (< 0.50) | 0 | 0% | Pollution massive ou vide |

---

## 7. Livrables

| Fichier | Description |
|---|---|
| `artifacts/amazon-messages-cleaned.json` | JSON nettoye avec champs enrichis |
| `artifacts/amazon-messages-cleanup-audit.csv` | Audit par conversation (CSV) |
| `keybuzz-infra/docs/PH42B-AMAZON-MESSAGES-CLEANUP-REPORT.md` | Ce rapport |

---

## 8. Structure du JSON nettoye

Chaque conversation contient les champs enrichis suivants :

```json
{
  "sc_conversation_id": "uuid",
  "original_buyer_name": "See all communication...",
  "extracted_buyer_name": "Daniel",
  "buyer_name_confidence": 0.95,
  "original_order_id": "259-9447880-2637437",
  "extracted_order_id": "405-4867060-5480332",
  "order_id_source": "amazon_message",
  "order_id_confidence": 0.99,
  "quality_score": 0.85,
  "quality_flags": ["missing_buyer_name"],
  "messages": [{
    "sender_type": "buyer",
    "normalized_sender_type": "seller",
    "sender_confidence": 0.95,
    "sender_corrections": ["buyer->seller"],
    "content": "...",
    "is_polluted": false,
    "is_duplicate": false,
    "data_quality_flags": []
  }]
}
```

---

## 9. Recommandations

1. **Filtrer `is_polluted: true`** avant ingestion dans la base de connaissances KeyBuzz
2. **Dedupliquer** les messages marques `is_duplicate: true` (garder la premiere occurrence)
3. **Utiliser `extracted_order_id`** au lieu de `original_order_id` (bug corrige)
4. **Utiliser `extracted_buyer_name`** au lieu de `original_buyer_name`
5. **Utiliser `normalized_sender_type`** au lieu de `sender_type`
6. **Verifier manuellement** les 51 conversations sans order_id
7. **Enrichir** avec le JSON Trello pour correspondance tickets/conversations
8. **Corriger le bug extracteur** pour les prochaines extractions (order_id + buyer_name)
