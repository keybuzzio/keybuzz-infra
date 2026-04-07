# PH143-UX-MON-TRAVAIL-CLEAN-01

**Date** : 1er mars 2026
**Type** : Amélioration UX non fonctionnelle
**Scope** : Client (AgentWorkbenchBar)
**Environnement** : DEV uniquement

---

## 1. Cause du scroll horizontal

Le composant `AgentWorkbenchBar.tsx` utilisait `overflow-x-auto` sur le container des chips de filtre, combiné avec `whitespace-nowrap` sur chaque chip. Quand les 5 filtres (Tous, À moi, À reprendre, Humain, IA) avec leurs compteurs dépassaient la largeur disponible, une barre de scroll horizontale apparaissait.

De plus, une ligne "Mon travail :" au-dessus des chips ajoutait de la hauteur verticale et dupliquait l'information déjà présente dans les compteurs des chips.

**Fichier** : `src/features/inbox/components/AgentWorkbenchBar.tsx`
**Container incriminé** : `<div className="px-3 py-2 flex items-center gap-1.5 overflow-x-auto">`

---

## 2. Solution retenue

### Suppression de la ligne "Mon travail :"
La section `{/* PH125: Mon travail summary */}` a été supprimée. Les compteurs intégrés aux chips de filtre remplissent déjà cette fonction.

### Overflow adaptatif avec ResizeObserver
- `overflow-x-auto` remplacé par `overflow-hidden`
- Un `ResizeObserver` mesure en continu la largeur disponible
- Les chips qui ne tiennent pas sont masquées et remplacées par un bouton `+N`
- Au clic sur `+N`, un dropdown sombre (`bg-gray-900`) liste les filtres cachés

### Priorisation visuelle
Le filtre actif est **toujours affiché en premier**. Les filtres restants suivent un ordre de priorité :
1. À reprendre (urgence)
2. À moi (personnel)
3. Humain
4. IA
5. Tous

### Réduction padding
- `py-2 + pt-2` (8px + 8px) réduit à `py-1.5` (6px) — gain de hauteur

---

## 3. Comportement desktop

| Largeur | Comportement |
|---------|--------------|
| Large (>400px) | 5 chips visibles sur une ligne, pas de +N |
| Moyen (~350px) | 2-3 chips + bouton +N |
| Étroit (<300px) | 2 chips minimum + bouton +N |

Le filtre actif reste **toujours visible** quelle que soit la largeur.

---

## 4. Comportement responsive

- **Desktop large** : tous les filtres visibles, une seule ligne ✅
- **Desktop étroit** : les filtres les moins prioritaires passent dans +N ✅
- **Aucune cassure visuelle** ✅
- **Aucun scroll horizontal** ✅
- Le dropdown +N se positionne en dessous et à droite, avec z-index 50

---

## 5. Résultats des tests navigateur

| Test | Résultat | Détails |
|------|----------|---------|
| A — Pas de scroll horizontal | ✅ OK | Aucune barre de scroll détectée |
| B — Apparence des chips | ✅ OK | Point couleur + label + compteur, filtre actif en surbrillance |
| C — Clic sur filtres | ✅ OK | La liste se filtre correctement à chaque clic |
| D — "Mon travail :" disparu | ✅ OK | Texte "Mon travail" absent, interface épurée |
| E — Bouton +N | ✅ OK | +3 visible, dropdown sombre avec filtres cachés (À moi, Humain, IA) |

### Détails des observations
- État initial : **Tous 365** (actif), **À reprendre 10**, **+3**
- Clic "À moi" : filtre bleu actif, liste filtrée (0 conv), dropdown montre les autres filtres
- Clic "À reprendre" : filtre rouge actif, conversations escaladées affichées
- Dropdown +N : fond `bg-gray-900`, filtres avec labels et compteurs, fermeture au clic extérieur

---

## 6. Commit SHA

| Commit | Message | Branche |
|--------|---------|---------|
| `bc18024` | PH143 UX mon travail compact filters | `rebuild/ph143-client` |

### Image Docker
- Tag : `v3.5.213-ph143-ux-mon-travail-clean-dev`
- Registry : `ghcr.io/keybuzzio/keybuzz-client`

---

## 7. Fichiers modifiés

| Fichier | Lignes | Description |
|---------|--------|-------------|
| `src/features/inbox/components/AgentWorkbenchBar.tsx` | +107 -31 | Refonte complète : overflow adaptatif, priorité, +N dropdown |

---

## 8. Verdict

**MON TRAVAIL UX CLEAN — NO HORIZONTAL SCROLL — FAST SCAN — PROFESSIONAL UI**

- ✅ Scroll horizontal éliminé
- ✅ Hauteur réduite (suppression "Mon travail :" + padding réduit)
- ✅ Priorisation visuelle des filtres
- ✅ Overflow adaptatif avec +N dropdown
- ✅ Filtrage fonctionnel vérifié
- ✅ Design compact, propre, cohérent Metronic

**STOP pour validation humaine** — aucun push PROD.
