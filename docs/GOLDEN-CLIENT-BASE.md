# GOLDEN CLIENT BASE

**⚠️ CETTE IMAGE EST LA RÉFÉRENCE. NE PAS MODIFIER SANS VALIDATION.**

---

## Image de Référence

| Attribut | Valeur |
|----------|--------|
| **Tag** | `ghcr.io/keybuzzio/keybuzz-client:golden-ph28.25b-2026-02-03` |
| **Digest** | `sha256:687dd975ed926e74a838f8f7980c79383b1549ccf0376ac10855b679d6040d35` |
| **Version UI** | v0.5.10-channels-polish (sha: ef961c8) |
| **Date** | 2026-02-03 |
| **Référence** | PH28.25B - PROD Readiness Checklist PASS |

---

## Labels Menu (État GOLDEN)

```json
"nav": {
  "onboarding": "Démarrage",
  "dashboard": "Dashboard",
  "inbox": "Inbox",
  "orders": "Commandes",
  "channels": "Canaux",
  "suppliers": "Fournisseurs",
  "knowledge": "Mémoire IA",
  "playbooks": "Playbooks IA",
  "ai_journal": "Journal IA",
  "settings": "Paramètres",
  "billing": "Facturation"
}
```

---

## Déploiements

| Env | Namespace | Status |
|-----|-----------|--------|
| DEV | keybuzz-client-dev | ✅ Déployé |
| PROD | keybuzz-client-prod | ✅ Déployé |

---

## Règles

1. **Tout nouveau patch DOIT partir de cette base**
2. **Ne jamais écraser ce tag dans le registry**
3. **Toute modification de labels menu FR requiert un nouveau PH**

---

## Historique

| Date | Action | Référence |
|------|--------|-----------|
| 2026-02-03 | Image créée | PH28.25B |
| 2026-02-03 | PH28.26 annulé, rollback effectué | PH28.26B |

---

**Dernière mise à jour:** 2026-02-03  
**Responsable:** Cursor Executor (CE)
