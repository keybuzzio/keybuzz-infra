### Prompt 1 : Persona complet basé sur data + insights réels

```
OBJECTIF
Produire des personas actionnables (B2C/B2B) qui relient besoins réels, déclencheurs, peurs et attentes à des leviers créatifs Meta/Google.

INPUTS
- Marque: [Nom] — Site: [URL] — Catégorie: [XX]
- Concurrents directs: [Marque1, Marque2, Marque3]
- Marchés: [FR/EU, US] (si pertinents)

MÉTHODE (imposée)
1) Collecte: Explore site, FAQ, PLP/PDP, blog, pricing, USP; concurrents; reviews (Trustpilot, G2, Amazon, Avis Google), Reddit/forums, réseaux sociaux.
2) Extraction: Récupère ≥12 verbatims clients **datés** (≤24 mois) avec lien source + pays.
3) Modélisation: Croise avec frameworks psycho: JTBD (progress souhaité, contraintes), Cialdini/édition 2021+, biais (loss aversion, status quo, effort heuristic), anxiétés (Demand-Side Sales).
4) Distinction Acheteur vs Utilisateur final (si différent) et contexte (cadeau, pro, parent/enfant…).
5) Compliance: Note les limites (claims, health/finance, policy Meta).

OUTPUTS
A) Tableau PERSONA (1 ligne/persona, 3–5 personas max):
- Nom persona (mnémotechnique) / FR vs US (si applicable)
- Âge | Genre | Situation familiale
- Rôle: Acheteur / Utilisateur (ou les deux)
- Situation pro & revenu (ou ordre de grandeur)
- Contexte d’achat (occasion, timing, device, lieu)
- JTBD (job fonctionnel / job émotionnel / job social)
- Déclencheurs & Category Entry Points (moments, lieux, personnes, saisons)
- Valeurs & motivations (classement top 5)
- Freins / objections (avec verbatim source)
- Expériences passées négatives → attentes spécifiques
- Sensibilité prix & repères d’ancrage (prix de référence, bundle vs unit.)
- Habitudes d’achat (online/offline, canaux d’influence, KOLs)
- Produits recherchés/prioritaires
- Indices de LTV (propension réachat / cross-sell)
- Message à tester (accroche 1 phrase)
- Preuve attendue (type de preuve: UGC expert, note, label, essai…)
- Format créa favori (UGC facecam, statique premium, demo, before/after)
- **Score Priorité Media** (0–100) = Potentiel ROAS x Taille x Facilité d’accès

B) Section “EVIDENCE PACK”
- ≥12 verbatims (FR/US tag), lien, date, insight associé (1 ligne/verbatim).

C) “GAPS & TODO”
- 5 données manquantes critiques + comment les collecter (sondage, LP, pixel).

```

---

### Prompt 2 : Segments de clientèle & correspondance produit

```
OBJECTIF
Identifier 4–6 segments à plus forte rentabilité (court et long terme) et relier chaque segment à un produit, un message, une créa et un canal d’acquisition.

INPUTS
- Marque/URL, concurrents, pays (FR/EU vs US), catalogue (top SKUs si possible)

MÉTHODE
1) Analyse croisée: offres, prix, bundles, reviews + reviews concurrents (forces/faiblesses).
2) Détecte différences FR/EU vs US (usage, normes, pricing, attentes de preuve).
3) Estime LTV proxy par segment (signaux: consommation récurrente, accessoires, obsolescence).

OUTPUT (tableau, 4–6 segments):
- Segment (nom clair) + Marché (FR/EU/US)
- Description détaillée (contexte, rôle: acheteur/utilisateur)
- Motivations & attentes clés (classement)
- Freins / peurs / mauvaises expériences typiques (avec 1 verbatim sourcé)
- Produit le plus adapté (+ prix psychologique / offre / bundle)
- Message marketing (promesse + mécanique de preuve)
- Angle psycho principal (ex: réassurance, appartenance, gain de statut, réduction effort)
- Format créatif recommandé (UGC demo, social proof carrousel, statique premium, DPA…)
- Canal & audience (Meta: INT / LAL / Broad; Google: P-Max/Brand/Non-Brand)
- KPI cible (CPA/ROAS/AOV, CTR attendu) + fenêtre de conversion
- Risques/limites (saturation créa, claims, supply)
- **Score “Go-To-Market”** (0–100)
- **Actions test Semaine 1** (3 tests concrets)

```

---

### Prompt 3 : Angles marketing puissants

```
OBJECTIF
Extraire des angles publicitaires puissants à partir d’insights clients réels, les classer par levier psychologique, et livrer des hooks prêtes à tourner.

MÉTHODE
1) Review mining: Reddit/avis/forums/vidéos concurrents → extrais 15 verbatims clés (lien+date).
2) Clusterise par levier psycho: preuve sociale, autorité, urgence, effort ↓, identité, perte évitée, nouveauté, assurance, réassurance post-achat.
3) Mappe chaque angle à un format créa (Meta best practices 2024/2025).

OUTPUT (tableau):
- **Angle** (nom clair) + **Levier psycho** (biais/heuristique)
- Promesse clé (spécifique, mesurable quand possible)
- Émotion ciblée (espoir, soulagement, fierté, FOMO, sécurité…)
- Exemple d’accroche (≤12 mots) + variante “loss aversion”
- Preuve/asset requis (note, label, UGC expert, test labo, comparatif)
- Format recommandé (UGC facecam, demo, before/after, statique de preuve, DPA)
- Hook créatif (première phrase/3s) + call-to-value (CTA orienté valeur)
- Risque/limite (policy, scepticisme, green/health claims)
- **Segment prioritaire** (du Prompt 2)
- **Priorité test** (Haute/Moyenne/Basse) + métrique à surveiller (CTR, CVR, ROAS)

EVIDENCE (à part)
- Liste des 15 verbatims sourcés (liens, date, FR/US)

```

---

### Prompt 4 : Parcours d’achat & contenus à déployer

```
OBJECTIF
Cartographier deux parcours: 1) “Fast lane” impulsif (48–72h), 2) “Considered lane” (1–4 semaines), et prescrire les contenus/placements/CTAs par étape.

INPUTS
- Produit/service: [description], panier moyen, contraintes (stock, délais), promesses
- Marchés: FR/EU vs US (si différences)

MÉTHODE
1) Étaye avec données: reviews/verbatims, délais de décision du marché, complexité perçue.
2) Intègre Category Entry Points (moments, lieux, personnes) & déclencheurs.
3) Pour chaque étape, recommander plateforme, format, preuve, CTA, et event de mesure.

OUTPUT (tableau par parcours: Découverte → Considération → Décision → Onboarding → Fidélisation):
- Étape
- Pensées/émotions dominantes
- Freins spécifiques (avec 1 verbatim court)
- Contenu recommandé (ex: UGC “my first 7 days”, statique social proof, LP module comparatif)
- Preuve exigée (quel type de preuve et où l’afficher)
- Canal/placement (Meta: Reels/IG Stories/FB Feed; Google: P-Max/Search/YouTube)
- **CTA optimal** (par niveau d’engagement) + micro-offre (échantillon, essai, bundle)
- Event & KPI (ViewContent, ATC, IC, Purchase; CTR, CVR, AOV, Time on page)
- Fenêtre de retargeting (délai, exclu, cap frequency)
- **Signal de bascule** (ex: 2× PDP viewed, sortie pricing, comparatif consulté)

À livrer en plus:
- **Checklist LP** (10 points): above-the-fold, preuve proche CTA, garanties, FAQ objections, comparatif, “first use story”, modularité mobile, vitesse, trust badges, sticky CTA.

```

---

### 🎯 Prompt 5 : Insights “Growth marketing” exploitables

```
OBJECTIF
Synthétiser les 12 insights les plus actionnables pour scaler Meta & Google, avec opportunités, formats, KPI cibles, et plan d’expérimentation.

MÉTHODE
1) Triangule: datas clients visibles (site/prix/offre), review mining, concurrence, signaux de demande (Search), tendances créa.
2) Qualifie chaque insight par Impact potentiel (ROAS/CPA/AOV) x Facilité (ressources/risque).
3) Propose tests concrets Semaine 1 & Semaine 2 (budget, audience, créa, succès).

OUTPUT (tableau 12 lignes):
- Insight (clair, sourcé si possible) 
- Opportunité publicitaire (angle, audience, canal/placement)
- Format recommandé (UGC, storytelling, statique premium, DPA, carousel preuve…)
- Asset requis (preuve, tournage, motion, landing module)
- KPI principal attendu (et valeur cible réaliste)
- Exemple d’activation (brief créa + setup campagne: obj, opti, attribution)
- Risques & mitigation (policy, cannibalisation, capping, learning)
- **Score Priorité** (Impact x Facilité, 0–100)

PLAN D’EXÉCUTION
- Semaine 1: 3 tests flagships (budget/jour, audiences, créas, métriques de go/no-go)
- Semaine 2: itérations (dupliquer gagnants, 3 nouvelles variations de hook/angle)
- **Post-mortem template** (quoi garder/arrêter/itérer)

```

---

### Prompt 6 — **Creative Mining & Hook Bank**

```
Objectif: Construire une banque de 30 hooks et 10 scripts UGC basés sur verbatims + angles du Prompt 3.
Output: 
- 30 hooks ≤10 mots (avec levier psycho taggé)
- 10 scripts UGC (structure: Hook 3s → Conflit → Preuve → CTA)
- 6 statiques “preuve” (layout + éléments)
- 1 grille de variation (Hook × Angle × Format × Segment)
```

---

### Prompt 7 — **Offer Engineering & Bundles**

```
Objectif: Proposer 5 offres (pricing/bundles/essai/garantie) alignées aux freins détectés.
Output: 5 offres + cible/segment + métrique attendue (AOV, CVR) + risques.
```