# PH15-ORDERS-UI-DATA-SWAP-01 - Brancher Orders UI sur API reelle

## Date: 2026-01-12

## Objectif
Remplacer les donnees mock par les vraies commandes Amazon dans /orders.

---

## Fichiers modifies

### keybuzz-client/app/orders/page.tsx
- Ajoute \useEffect\ pour charger les commandes depuis l'API
- Ajoute etats: \orders\, \loading\, \error\
- Remplace \MOCK_ORDERS\ par \orders\ dans les calculs de stats
- Fallback vers mock si API echoue

### keybuzz-client/app/api/orders/route.ts (nouveau)
- Proxy vers \ackend-dev.keybuzz.io/api/v1/orders\
- Recupere le tenant courant via \/tenant-context/me\
- Authentification via \getServerSession(authOptions)\

---

## API Backend

### GET /api/v1/orders
- Renvoie les commandes pour le tenant courant
- Format compatible avec l'UI (ref, date, channel, customer, orderStatus, etc.)

---

## Resultat

| Metrique | Valeur |
|----------|--------|
| Commandes affichees | 94 |
| En transit | 78 |
| Annulees | 16 |
| Canal | Amazon |

---

## Preuve UI

\\\
Total: 94
En transit: 78
En retard: 0
SAV actifs: 0

Exemples de commandes:
- #149120 - 22 nov. 2025 - Client Amazon - Expediee - En transit
- #563521 - 21 nov. 2025 - Client Amazon - Expediee - En transit
- #038708 - 21 nov. 2025 - Client Amazon - Expediee - En transit
\\\

---

## Version deployee

\\\
keybuzz-client: v0.2.71-dev
\\\

---

## Git Commits

### keybuzz-client
- PH15: Connect Orders UI to real API data (94 Amazon orders)

### keybuzz-infra
- Add PH15-ORDERS-UI-DATA-SWAP-01 report

---

## Note

- Le design/UX n'a PAS ete modifie
- Les mocks restent disponibles en fallback si API echoue
- Les filtres existants fonctionnent toujours
