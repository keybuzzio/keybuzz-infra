# PH141-D — Final Polish Audit

> Phase : PH141-D-FINAL-POLISH-AUDIT-01
> Date : 3 avril 2026
> Type : audit produit complet (lecture seule)
> Environnement : DEV (tests navigateur reels) + PROD (health checks)

---

## Etat general

| Service | Env | Status |
|---|---|---|
| API DEV | `api-dev.keybuzz.io/health` | OK |
| API PROD | `api.keybuzz.io/health` | OK — `{"status":"ok"}` |
| Client DEV | `client-dev.keybuzz.io` | OK — HTTP 200 |
| Client PROD | `client.keybuzz.io` | OK — HTTP 200 |
| Website PROD | `www.keybuzz.pro` | OK |

**Images deployees :**
- Client : `v3.5.179-agent-limits-alignment-{dev,prod}`
- API : `v3.5.180-keybuzz-agent-lockdown-{dev,prod}`
- DEV et PROD alignes.

---

## TOP 10 — Frictions critiques

### 1. ACCENTS MANQUANTS SUR PLUSIEURS PAGES (Unicode non interprete)

**Severite : CRITIQUE (image professionnelle)**

Plusieurs pages affichent des textes sans accents a cause de scripts Python ayant utilise des raw strings (`r"""`) ou des `\u00e9` non interpretes.

| Page | Texte affiche | Texte attendu |
|---|---|---|
| `/no-access` | "Acces non autorise" | "Accès non autorisé" |
| `/no-access` | "reservee aux administrateurs" | "réservée aux administrateurs" |
| `/no-access` | "proprietaire" | "propriétaire" |
| `/billing/ai` | "Aujourdhui" | "Aujourd'hui" |
| `/billing/ai` | "utilisees" | "utilisées" |
| `/billing/ai` | "achetes" | "achetés" |
| `/billing/ai` | "Rafraichir" | "Rafraîchir" |
| `/settings` | "Identite entreprise" | "Identité entreprise" |
| `/settings` | "Telephone" | "Téléphone" |

**Impact :** Toute la credibilite SaaS est fragilisee par ces erreurs d'accents visibles par chaque utilisateur.

---

### 2. PAGE `/locked` (PAYWALL) NE FONCTIONNE PAS

**Severite : CRITIQUE (business)**

La navigation vers `/locked` redirige silencieusement vers `/inbox` au lieu d'afficher la page de blocage paywall. Le mecanisme d'upgrade/upsell pour les plans insuffisants est donc inoperant.

**Attendu :** Page avec message clair, plan actuel, et CTA "Passer au plan superieur".
**Observe :** Redirect silencieux vers `/inbox`.

---

### 3. SETTINGS IGNORE LE QUERY PARAM `?tab=`

**Severite : HAUTE**

`/settings?tab=agents` et `/settings?tab=signature` chargent toujours sur l'onglet "Entreprise". Le query param est ignore.

**Impact :** Les liens directs vers un onglet specifique (depuis les rapports, emails, ou autres pages) ne fonctionnent pas. L'utilisateur doit toujours cliquer manuellement.

---

### 4. SLA : 248 DEPASSES, 24% SANTE — AUCUNE ACTION PROPOSEE

**Severite : HAUTE (produit)**

Le dashboard affiche clairement "248 SLA depasses" et "Sante SLA 24%" mais ne propose aucune action. Pas de lien vers les conversations depassees, pas de bouton "Traiter les urgences", pas de recommandation.

**Impact :** L'utilisateur voit le probleme mais ne sait pas quoi faire. Information sans action = frustration.

---

### 5. SUPERVISION : 254 EN FILE, 245 URGENTES, 0 ASSIGNEES

**Severite : HAUTE (produit)**

Le panel Supervision montre un etat alarmant : 254 conversations en file, 245 urgentes, 0 assignees, 0 resolues en 24h. Aucun agent n'est assigne.

**Impact :** En situation reelle, cela indiquerait un abandon total du support. Le systeme ne propose pas de mecanisme d'auto-assignation ou de recommandation.

**Suggestion :** Ajouter un CTA "Assigner automatiquement" ou "Distribuer aux agents" quand le backlog est critique.

---

### 6. LIMITE AGENTS : 5/2 AFFICHE MAIS AUCUNE ACTION DE NETTOYAGE

**Severite : HAUTE**

La page Agents affiche "5/2" (5 agents actifs pour une limite de 2 en plan PRO). Le systeme bloque correctement les nouvelles creations, mais ne propose pas de desactiver les agents en trop.

Observations specifiques :
- "KeyBuzz Support" est en statut "Invitation envoyee" (agent IA — pas clair pour l'utilisateur)
- "Test Agent" (test-agent@keybuzz.io) est en "Invitation envoyee" — agent de test oublie
- Aucun bouton "Desactiver" visible

**Suggestion :** Ajouter un bouton "Desactiver" par agent et un message explicite "Desactivez X agents pour revenir dans la limite de votre plan".

---

### 7. SIDEBAR : 13 ELEMENTS — SURCHARGE COGNITIVE

**Severite : MOYENNE-HAUTE**

La sidebar contient 13 liens :
1. Demarrage
2. Tableau de bord
3. Messages
4. Commandes
5. Canaux
6. Fournisseurs
7. Base de reponses
8. Automatisation IA
9. Journal IA
10. IA Performance
11. Parametres
12. Facturation

Plus : Mode Focus, tenant selector, langue, aide, theme, user menu.

**Impact :** Surcharge cognitive. Un nouvel utilisateur ne sait pas par ou commencer. Les items IA (3 liens : Automatisation IA, Journal IA, IA Performance) pourraient etre regroupes.

---

### 8. ONBOARDING (PAGE START) : CHECKLIST NON ACTUALISEE

**Severite : MOYENNE-HAUTE**

La page `/start` (Demarrage) affiche :
- "Creer votre espace" : OK (coche verte)
- "Completer vos informations entreprise" : Non fait (cercle vide)
- "Ajouter un canal (Amazon)" : Non fait
- "Verifier la reception des messages" : Non fait
- "Tester une reponse IA" : Optionnel, non fait

**Probleme :** L'utilisateur a deja connecte 4 canaux Amazon et a 325 conversations. Mais la checklist ne se met pas a jour automatiquement. L'impression est que l'onboarding est incomplet alors que le produit est utilise activement.

---

### 9. CONVERSATION DETAIL : COLONNE CENTRALE TROP ETROITE

**Severite : MOYENNE**

Dans l'inbox tri-panes, la colonne centrale (detail conversation) est tres etroite, en partie parce que les boutons d'action (Prendre en charge, Marquer resolu, Historique IA, Aide IA, Suggestion IA, Modeles) occupent trop de place verticalement.

Le titre de la conversation est coupe sur plusieurs lignes (ex: "Demande de renseignement concernant la livraison dune commande de").

**Impact :** Lisibilite reduite. L'utilisateur doit scroller pour voir le contenu du message.

---

### 10. ICONE NOTIFICATION (CLOCHE ROUGE) — JAMAIS CONSULTABLE

**Severite : MOYENNE**

La cloche dans la topbar affiche un badge rouge (notification non lue) mais ne semble pas ouvrir un panneau de notifications au clic.

**Impact :** Signal visuel permanent sans action possible = bruit visuel.

---

## Frictions moyennes

### M1. "Donnees API" badge en bas de sidebar

Le badge vert "Donnees API" en bas de la sidebar gauche de l'inbox est un artefact de debug. Il ne devrait pas etre visible en production.

### M2. "Client Amazon" generique pour tous les clients

Toutes les commandes affichent "Client Amazon" au lieu du nom reel de l'acheteur. Cela vient probablement d'une limitation SP-API (Amazon ne fournit pas toujours le nom), mais l'affichage devrait indiquer "Acheteur anonyme" ou le buyer-name quand disponible.

### M3. "SAV Ouvert" badge sur les commandes sans action visible

Les commandes avec "SAV Ouvert" n'ont pas de lien direct vers le dossier SAV ou la conversation associee.

### M4. Breadcrumb "Accueil > Facturation > Ai"

Le breadcrumb de la page KBActions affiche "Ai" au lieu de "KBActions" ou "Intelligence Artificielle". Inconsistance de nommage.

### M5. Canaux : "4/3" sans explication visuelle du surcoat

La page Canaux affiche "4/3 canaux utilises" avec une mention "1 canal supplementaire (+50EUR/mois)", mais il n'y a pas de distinction visuelle entre les canaux inclus et le canal payant.

### M6. Knowledge : bouton "Reinitialiser les modeles" dangereux

Le bouton "Reinitialiser les modeles" sur la page Knowledge est un bouton destructif place au meme niveau que "Nouvelle bibliotheque". Risque de clic accidentel.

### M7. Playbooks : 7 inactifs sans explication

7 playbooks sur 15 sont inactifs. Aucun message n'explique pourquoi ils sont desactives ou comment les activer.

### M8. Mode Focus sans feedback

Le bouton "Mode Focus" dans la sidebar n'a pas de feedback visuel clair quand il est actif. L'utilisateur ne sait pas s'il est en mode focus ou non.

### M9. Theme clair/sombre inconsistant

Le bouton "Mode clair" dans la topbar suggere que le mode sombre est possible, mais l'application est entierement en mode clair. Le toggle ne semble pas changer l'apparence.

### M10. Help page : liens documentation morts

La page Aide contient des liens "Guide de demarrage rapide", "Connecter Amazon Seller", etc. avec des icones de lien externe, mais ils pointent probablement vers des pages inexistantes.

---

## Frictions mineures

### m1. "Conges" sans accent dans les onglets Settings

L'onglet Settings affiche "Conges" au lieu de "Congés".

### m2. Signup page en dark mode, login en light mode

La page `/signup` utilise un fond sombre avec les plans tarifaires, tandis que `/login` est en fond clair. Inconsistance de theme.

### m3. Journal IA : "Evaluated 0 rules" en anglais

Le journal IA affiche des messages mixtes FR/EN : "Evaluated 0 rules" devrait etre "0 regles evaluees".

### m4. Commandes : "UPS FR (suivi indisponible)" frequent

Beaucoup de commandes affichent "UPS FR (suivi indisponible)" meme pour des commandes recentes. Le lien de tracking est parfois present, parfois non.

### m5. Fournisseurs : "<15j: Fournisseur paie • >15j: Client paie" 

Cette information est affichee pour chaque fournisseur mais la logique metier n'est pas expliquee. Un nouvel utilisateur ne comprendra pas.

### m6. "Copier ref" dans la barre d'action inbox

Le bouton "Copier ref" n'a pas de feedback visuel apres le clic (pas de toast "Copie !").

### m7. Commandes : colonne "ACTIO" tronquee

Le header "ACTIONS" est tronque en "ACTIO" sur la page commandes.

---

## Bugs confirmes

| # | Bug | Severite | Page |
|---|---|---|---|
| B1 | `/locked` redirige vers `/inbox` au lieu d'afficher le paywall | CRITIQUE | `/locked` |
| B2 | `/settings?tab=agents` ignore le query param, charge toujours "Entreprise" | HAUTE | `/settings` |
| B3 | Accents manquants sur `/no-access` ("Acces non autorise") | HAUTE | `/no-access` |
| B4 | Accents manquants sur `/billing/ai` ("Aujourdhui", "utilisees") | MOYENNE | `/billing/ai` |
| B5 | Accents manquants sur `/settings` ("Identite", "Telephone") | MOYENNE | `/settings` |
| B6 | Onboarding checklist non actualisee (canaux connectes non detectes) | MOYENNE | `/start` |
| B7 | Journal IA : messages en anglais ("Evaluated 0 rules") | FAIBLE | `/ai-journal` |
| B8 | Breadcrumb "Ai" au lieu de "KBActions" | FAIBLE | `/billing/ai` |
| B9 | Colonne "ACTIO" tronquee (header commandes) | FAIBLE | `/orders` |

---

## Suggestions produit

### S1. Regrouper les items IA dans la sidebar
Creer un sous-menu "Intelligence Artificielle" qui regroupe : Automatisation IA, Journal IA, IA Performance. Reduire la sidebar de 13 a ~10 items.

### S2. Dashboard : CTA actionnable sur les SLA depasses
Ajouter un bouton "Voir les conversations urgentes" qui filtre directement l'inbox sur les SLA depasses.

### S3. Supervision : bouton "Distribuer le backlog"
Quand 254 conversations sont en file sans assignation, proposer une action automatique.

### S4. Agents : bouton "Desactiver" par agent
Permettre de desactiver les agents directement depuis la liste pour revenir dans la limite du plan.

### S5. Onboarding dynamique
La checklist de demarrage devrait se mettre a jour automatiquement en detectant les canaux connectes et les conversations recues.

### S6. Inbox : resume IA automatique
Le dernier message est souvent tronque. Un resume IA de 1 ligne aiderait a trier sans ouvrir chaque conversation.

### S7. Commandes : lien direct vers le dossier SAV
Les commandes avec "SAV Ouvert" devraient avoir un lien cliquable vers le dossier correspondant.

### S8. Paywall fonctionnel
La page `/locked` doit afficher un message clair avec le plan actuel, les limitations atteintes, et un CTA Stripe pour upgrader.

### S9. Settings deep-link
Le query param `?tab=` doit fonctionner pour permettre les liens directs vers les onglets.

### S10. Correction Unicode globale
Auditer et corriger tous les textes avec accents manquants en une seule passe.

---

## Performance percue

| Page | Temps de chargement | Verdict |
|---|---|---|
| `/dashboard` | ~3s | Acceptable |
| `/inbox` | ~4-5s | Lent (325 conversations) |
| `/orders` | ~2s | Bon |
| `/knowledge` | ~4s | Acceptable |
| `/playbooks` | ~3s | Acceptable |
| `/billing` | ~3s | Acceptable |
| `/settings` | ~4s | Acceptable |
| `/ai-journal` | ~3s | Acceptable |
| `/help` | ~1s | Rapide |
| `/login` | ~2s | Acceptable |

**Observation :** L'inbox avec 325 conversations et le tri prioritaire est la page la plus lente. Un chargement progressif (lazy load, virtualisation) ameliorerait la perception.

---

## Verification PROD (lecture seule)

| Check | Resultat |
|---|---|
| API health `api.keybuzz.io/health` | `{"status":"ok","service":"keybuzz-api"}` |
| Client `client.keybuzz.io` | HTTP 200 |
| DEV/PROD alignes | Memes versions (client v3.5.179, API v3.5.180) |

---

## Verdict

**IDENTIFIED GAPS BEFORE SCALE**

Le produit est fonctionnel et utilisable pour un utilisateur averti. Les fonctionnalites core (inbox, commandes, IA, playbooks, billing, agents) fonctionnent correctement.

**Blockers avant scale :**
1. **Accents manquants** — Destructeur d'image professionnelle (correction estimee : 1h)
2. **Paywall `/locked` non fonctionnel** — Empeche le mecanisme d'upsell (correction estimee : 2h)
3. **Settings deep-link casse** — Casse les liens internes (correction estimee : 30min)

**Ameliorations prioritaires avant demo/lancement :**
4. Onboarding checklist dynamique
5. CTA actionnable sur le dashboard SLA
6. Sidebar simplifiee (regroupement IA)

**Le produit n'est PAS "PRODUCT READY" en l'etat a cause des accents manquants qui donnent une impression d'amateurisme.** La correction est simple et rapide.
