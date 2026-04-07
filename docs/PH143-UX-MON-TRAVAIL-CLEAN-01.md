# PH143-UX-MON-TRAVAIL-CLEAN-01

**Date** : 1er mars 2026
**Type** : Amélioration UX non fonctionnelle
**Scope** : Client (AgentWorkbenchBar)
**Environnement** : DEV uniquement

---

## 1. Cause du scroll horizontal

Le composant `AgentWorkbenchBar.tsx` utilisait `overflow-x-auto` sur le container des chips de filtre, combiné avec `whitespace-nowrap` sur chaque chip. Quand les 5 filtres (Tous, À moi, À reprendre, Humain, IA) avec leurs compteurs dépassaient la largeur disponible, une barre de scroll horizontale apparaissait.

De plus, une ligne "Mon travail :" au-dessus des chips ajoutait de la hauteur verticale et dupliquait l'information déjà présente dans les compteurs.

**Fichier** : `src/features/inbox/components/AgentWorkbenchBar.tsx`
**Container incriminé** : `<div className="px-3 py-2 flex items-center gap-1.5 overflow-x-auto">`

---

## 2. Solution retenue

### Suppression de la ligne "Mon travail :"
La section résumé a été supprimée. Les compteurs intégrés aux chips remplissent déjà cette fonction.

### "Tous" toujours visible
Le chip "Tous" est **séparé structurellement** des autres filtres. Il est rendu en premier et **ne peut jamais basculer dans le overflow +N**. Cela garantit que l'utilisateur peut toujours annuler un filtre actif en cliquant sur "Tous".

### Overflow adaptatif avec ResizeObserver
- `overflow-x-auto` remplacé par `overflow-hidden`
- Un `ResizeObserver` mesure la largeur disponible (après "Tous")
- Les chips qui ne tiennent pas sont masquées dans un bouton `+N`
- Au clic sur `+N`, un dropdown sombre (`bg-gray-900`) liste les filtres cachés

### Priorisation visuelle
Le filtre actif (s'il n'est pas "Tous") est affiché en **deuxième position** après "Tous". Les filtres restants suivent un ordre de priorité :
1. À reprendre (urgence)
2. À moi (personnel)
3. Humain
4. IA

### Réduction padding
- `py-2 + pt-2` (8px + 8px) réduit à `py-1.5` (6px) — gain de hauteur

---

## 3. Comportement desktop

| Largeur | Comportement |
|---------|--------------|
| Large (>400px) | Tous + 4 chips visibles, pas de +N |
| Moyen (~350px) | Tous + 1-2 chips + bouton +N |
| Étroit (<300px) | Tous + 1 chip minimum + bouton +N |

"Tous" et le filtre actif restent **toujours visibles** quelle que soit la largeur.

---

## 4. Comportement responsive

- **Desktop large** : Tous + tous les filtres visibles, une seule ligne ✅
- **Desktop étroit** : Tous + filtre actif + surplus dans +N ✅
- **Aucune cassure visuelle** ✅
- **Aucun scroll horizontal** ✅
- Le dropdown +N se positionne en dessous et à droite, z-index 50

---

## 5. Résultats des tests navigateur

### Première passe (v3.5.213)

| Test | Résultat | Détails |
|------|----------|---------|
| A — Pas de scroll horizontal | ✅ OK | Aucune barre de scroll détectée |
| B — Apparence des chips | ✅ OK | Point couleur + label + compteur |
| C — Clic sur filtres | ✅ OK | Liste filtrée correctement |
| D — "Mon travail :" disparu | ✅ OK | Texte absent, interface épurée |
| E — Bouton +N | ✅ OK | +3 visible, dropdown sombre fonctionnel |

### Correction v3.5.214 — "Tous" toujours visible

| Test | Résultat | Détails |
|------|----------|---------|
| 1 — État initial | ✅ OK | "Tous 366" actif (fond gris foncé), toujours visible |
| 2 — Filtre "À reprendre" actif | ✅ OK | "Tous 366" reste visible, "À reprendre 10" actif en rouge |
| 3 — Filtre "À moi" actif | ✅ OK | "Tous 366" reste visible, "À moi" actif en bleu |
| 4 — Clic "Tous" pour annuler | ✅ OK | Toutes les 366 conversations reviennent, "Tous" actif |

---

## 6. Commits SHA

| Commit | Message | Branche |
|--------|---------|---------|
| `bc18024` | PH143 UX mon travail compact filters | `rebuild/ph143-client` |
| `df3aca9` | PH143 UX: Tous filter always visible (never in overflow) | `rebuild/ph143-client` |

### Image Docker finale
- Tag : `v3.5.214-ph143-tous-visible-dev`
- Registry : `ghcr.io/keybuzzio/keybuzz-client`

---

## 7. Fichiers modifiés

| Fichier | Description |
|---------|-------------|
| `src/features/inbox/components/AgentWorkbenchBar.tsx` | Refonte complète : "Tous" toujours visible, overflow adaptatif, priorité, +N dropdown |

---

## 8. Verdict

**MON TRAVAIL UX CLEAN — NO HORIZONTAL SCROLL — TOUS ALWAYS VISIBLE — FAST SCAN — PROFESSIONAL UI**

- ✅ Scroll horizontal éliminé
- ✅ "Tous" toujours visible (annulation possible depuis n'importe quel filtre)
- ✅ Hauteur réduite (suppression "Mon travail :" + padding réduit)
- ✅ Priorisation visuelle des filtres
- ✅ Overflow adaptatif avec +N dropdown
- ✅ Filtrage fonctionnel vérifié
- ✅ Design compact, propre, cohérent Metronic

**STOP pour validation humaine** — aucun push PROD.
