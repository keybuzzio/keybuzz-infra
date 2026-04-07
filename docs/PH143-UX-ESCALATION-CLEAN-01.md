# PH143-UX-ESCALATION-CLEAN-01

> Date : 2026-04-07
> Phase : PH143-UX — Amélioration UX escalade (non fonctionnelle)
> Verdict : **ESCALATION UX CLEAN — COMPACT — NON INTRUSIVE — PROFESSIONAL UI**

---

## 1. Objectif

Remplacer le bloc d'escalade volumineux (bordered card multi-lignes) par un affichage compact inline avec tooltip au clic, aligné avec le design Metronic existant.

---

## 2. Avant / Après

### Avant

```
┌──────────────────────────────────────┐
│ 🔴 Escaladé                          │
│                                      │
│ Raison : Promesse d'action détectée  │
│ dans la réponse: je vais vérifier... │
│                                      │
│ Cible : [Votre équipe]              │
│                                      │
│ [Retirer escalade]                   │
└──────────────────────────────────────┘
```

- Bloc `rounded-lg border p-3` prenant 4-5 lignes verticales
- Raison en texte plein avec ":" mal placé
- Cible avec badge séparé
- Boutons en rangée
- Doublonne avec TreatmentStatusPanel qui affichait aussi l'escalade

### Après

```
[Open ▾] [SAV ▾] Mode IA | Assign. Non assignée  🔴 Escaladé ⓘ  [amazon] Client
                                                          │
                                                    clic sur ⓘ
                                                          ▼
                                                ┌─────────────────────┐
                                                │ RAISON              │
                                                │ Promesse d'action   │
                                                │ détectée...         │
                                                │                     │
                                                │ CIBLE               │
                                                │ [Votre équipe]      │
                                                │                     │
                                                │ [Retirer l'escalade]│
                                                └─────────────────────┘
```

- Pill badge inline `text-[11px]` avec dot rouge
- Icône info (ⓘ) circulaire cliquable
- Tooltip sombre (`bg-gray-900`) au clic avec raison, cible, action
- TreatmentStatusPanel compact (Mode + Assign seulement)
- Tout aligné horizontalement dans le flex-wrap header

---

## 3. Composants modifiés

### `EscalationPanel.tsx` — réécriture complète

**État `none`** : bouton subtil "Escalader" avec chevrons doubles, pill border léger gris, hover rouge.

**État `escalated` / `recommended`** :
- Pill badge inline rouge (ou ambre) avec dot coloré + label
- Icône info SVG (cercle + "i") w-5 h-5, 14px
- Clic → tooltip sombre positionné en absolute :
  - Raison (label uppercase tracking-wider + texte)
  - Cible (badge bleu translucide)
  - Bouton "Retirer l'escalade" (emerald translucide, full-width)
- Clic extérieur ferme le tooltip

**Picker d'escalade manuelle** : dropdown raison dans tooltip sombre (même design), boutons Confirmer/Annuler.

### `TreatmentStatusPanel.tsx` — simplification

- Suppression de l'affichage escalade (doublon avec EscalationPanel)
- Rendu inline-flex compact : `Mode IA | Assign. Non assignée`
- Bordure fine, padding réduit (`px-2 py-1`)

### `InboxTripane.tsx` — layout

- Ajout `flex-wrap` sur le container header conversation pour le responsive
- Aucun changement logique

---

## 4. Tests navigateur

| Test | Résultat |
|------|----------|
| Badge rouge "Escaladé" compact avec dot | Visible, inline avec les autres badges |
| Icône info (ⓘ) cliquable | Visible (w-5 h-5), title "Détails de l'escalade" |
| Tooltip sombre au clic | Apparaît avec raison + cible + bouton action |
| Bouton "Retirer l'escalade" dans tooltip | Présent, style emerald |
| Conversation non-escaladée : bouton "Escalader" | Visible, chevrons doubles, hover rouge |
| TreatmentStatusPanel compact | Inline Mode + Assign, pas de duplication escalade |
| Layout global sans gros blocs | Confirmé, tout horizontal |
| Pas de décalage / scroll inutile | Confirmé |

---

## 5. Aucune modification backend

- Aucun changement API
- Aucun changement logique d'escalade
- Aucun changement DB
- Uniquement UI/UX côté client

---

## 6. Commits

| SHA | Message |
|-----|---------|
| `2d7d686` | PH143 UX escalation compact + tooltip |
| `8424b5b` | UX escalation: bigger info icon (w-5 h-5, 14px svg) |

Branche : `rebuild/ph143-client`

---

## 7. Image DEV

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.212-ph143-ux-escalation-clean-dev
```

---

## 8. Fichiers modifiés

```
src/features/inbox/components/EscalationPanel.tsx     — réécriture complète (compact + tooltip)
src/features/inbox/components/TreatmentStatusPanel.tsx — simplifié (Mode + Assign only)
app/inbox/InboxTripane.tsx                             — flex-wrap header
```

---

## 9. Verdict

### **ESCALATION UX CLEAN — COMPACT — NON INTRUSIVE — PROFESSIONAL UI**

L'escalade est désormais un badge discret avec détails au clic, aligné avec le reste de l'interface. Aucune modification fonctionnelle. Prêt pour validation humaine sur DEV.
