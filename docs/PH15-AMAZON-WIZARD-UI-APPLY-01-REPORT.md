# PH15-AMAZON-WIZARD-UI-APPLY-01 — Rapport

**Date** : 2026-01-07  
**Statut** : ✅ TERMINÉ

---

## Résumé

Finalisation de l'UI wizard Amazon avec status réel depuis le backend et boutons de déconnexion.

---

## 1. Modifications apportées

### Fichier modifié
`src/features/onboarding/components/OnboardingWizard.tsx`

### Changements clés

1. **Props StepChannels** : Ajout de `tenantId: string`

2. **State realStatus** : 
```typescript
const [realStatus, setRealStatus] = useState({ 
  connected: amazonState.connected, 
  displayName: amazonState.sellerId || "", 
  loading: false 
});
```

3. **useEffect fetch status** :
```typescript
useEffect(() => { 
  if (data.amazon && tenantId) { 
    setRealStatus(s => ({ ...s, loading: true })); 
    fetch("/api/amazon/status?tenant_id=" + encodeURIComponent(tenantId))
      .then(r => r.json())
      .then(d => setRealStatus({ 
        connected: !!d.connected, 
        displayName: d.displayName || "", 
        loading: false 
      }))
      .catch(() => setRealStatus(s => ({ ...s, loading: false }))); 
  } 
}, [data.amazon, tenantId]);
```

4. **handleDisconnect** :
```typescript
const handleDisconnect = () => { 
  setRealStatus(s => ({ ...s, loading: true })); 
  fetch("/api/amazon/disconnect", { 
    method: "POST", 
    headers: {"Content-Type":"application/json"}, 
    body: JSON.stringify({tenantId}) 
  })
    .then(() => setRealStatus({ connected: false, displayName: "", loading: false }))
    .catch(() => setRealStatus(s => ({ ...s, loading: false }))); 
};
```

5. **JSX** : Utilisation de `realStatus.connected` au lieu de `amazonState.connected`

---

## 2. Comportement UI

### Étape "Vos canaux" — Amazon coché

| Status | Affichage |
|--------|-----------|
| `loading: true` | "Chargement..." |
| `connected: true` | Badge "Connecté" + bouton Reconnecter + bouton Déconnecter |
| `connected: false` | Bouton "Connecter Amazon" |

### Actions

- **Connecter** : Redirect vers `/api/amazon/oauth/start` → Amazon Seller Central
- **Déconnecter** : POST `/api/amazon/disconnect` → refresh status
- **Reconnecter** : Même flow que Connecter

---

## 3. Tests E2E

### Test status réel
```bash
curl -sk -H "X-User-Email: demo@keybuzz.io" -H "X-Tenant-Id: tenant_test_dev" \
  https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/status
```
```json
{"connected":true,"status":"CONNECTED","displayName":"Amazon Seller A12BCIS2R7HD4D",...}
```

### Test client déployé
```bash
curl -sk https://client-dev.keybuzz.io/debug/version
```
```json
{"app":"app","version":"0.2.38","gitSha":"unknown","buildDate":"2026-01-07T23:23:06.790980Z"}
```

---

## 4. Versions

| Service | Version | Digest |
|---------|---------|--------|
| keybuzz-client | v0.2.38-dev | `sha256:f5f691669cf47ef33f21816eaddd4c28f5216bc4e34aa4a55d940941a7d25cad` |
| keybuzz-backend | v0.1.9-dev | `sha256:2956b9440bcd678982a31fa49aba521e8266d43f975e0a8269dd8d925ee3e255` |

---

## 5. Git

```bash
# keybuzz-client
git commit -m "feat(PH15): Real Amazon status in StepChannels wizard"
# -> 185304b
```

---

## 6. Fonctionnalités opérationnelles

✅ Status Amazon réel (depuis DB via backend)  
✅ Bouton Connecter Amazon (redirect OAuth)  
✅ Bouton Déconnecter (POST /api/amazon/disconnect)  
✅ Bouton Reconnecter (relance OAuth)  
✅ Loader pendant fetch  
✅ Pas de hardcode connected  

---

**Fin du rapport PH15-AMAZON-WIZARD-UI-APPLY-01**
