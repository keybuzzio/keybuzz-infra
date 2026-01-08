# PH15-AMAZON-OAUTH-REDIRECT-FIX-02 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Correction du flow OAuth Amazon pour éviter tout refresh de page et afficher des erreurs explicites.

---

## 1. Problème

### Avant (v0.2.40)

```typescript
// Client faisait navigation directe
window.location.href = "/api/amazon/oauth/start?..."

// Route Next.js faisait redirection HTTP
return NextResponse.redirect(data.authUrl);
```

**Problème** : La navigation vers la route API puis la redirection HTTP causait un comportement de "page reload" visible.

---

## 2. Solution Implémentée

### Nouveau Flow (v0.2.41)

```
┌─────────────────────────────────────────────────────────────┐
│  1. Clic "Connecter Amazon"                                 │
│     → e.preventDefault() + e.stopPropagation()              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  2. fetch('/api/amazon/oauth/start', { method: 'POST' })    │
│     → Pas de navigation browser                             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Route Next.js retourne JSON                             │
│     { authUrl: "https://sellercentral.amazon.com/..." }     │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Client: window.location.assign(authUrl)                 │
│     → Navigation propre vers Amazon                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Fichiers Modifiés

### `app/api/amazon/oauth/start/route.ts`

```typescript
// POST handler - retourne JSON
export async function POST(request: Request) {
  // ... appel backend ...
  return NextResponse.json({ 
    authUrl: data.authUrl,
    state: data.state
  });
}

// GET handler - legacy redirect (compatibilité)
export async function GET(request: Request) {
  // ... 
  return NextResponse.redirect(data.authUrl);
}
```

### `src/features/onboarding/components/OnboardingWizard.tsx`

```typescript
const [amazonLoading, setAmazonLoading] = useState(false);

const connectAmazon = async () => {
  setAmazonLoading(true);
  try {
    const res = await fetch('/api/amazon/oauth/start', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tenant_id: tenantId }),
    });
    
    const text = await res.text();
    let data;
    try { data = JSON.parse(text); } catch { data = null; }
    
    if (!res.ok) {
      alert('Erreur OAuth Amazon: ' + (data?.error || text.substring(0, 120)));
      setAmazonLoading(false);
      return;
    }
    
    if (!data?.authUrl) {
      alert('Erreur: authUrl manquant');
      setAmazonLoading(false);
      return;
    }
    
    // Success - redirect sans reload
    window.location.assign(data.authUrl);
    
  } catch (err) {
    alert('Erreur réseau OAuth: ' + err.message);
    setAmazonLoading(false);
  }
};
```

---

## 4. Gestion des Erreurs

| Cas | Message Affiché |
|-----|-----------------|
| Pas de session | `Erreur OAuth Amazon: Not authenticated` |
| Backend down | `Erreur réseau OAuth: fetch failed` |
| Backend erreur | `Erreur OAuth Amazon: <message backend>` |
| authUrl manquant | `Erreur: authUrl manquant dans la réponse` |

---

## 5. Version Déployée

```
keybuzz-client: v0.2.41-dev
digest: sha256:55b0412e73aa47860472ba6b740098ddb0f08c253f3a492884c30d041d55e683
```

---

## 6. Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-client | `da8cfba` | fix(PH15): OAuth flow - fetch then redirect, no reload |
| keybuzz-infra | `17948d2` | feat(PH15): update client to v0.2.41-dev |

---

## 7. Comportement Attendu

| Action | Résultat |
|--------|----------|
| Clic "Connecter Amazon" | ❌ Pas de page reload |
| Clic "Connecter Amazon" | ✅ Loader affiché |
| Réponse OK | ✅ Navigation vers Amazon |
| Erreur backend | ✅ Alert explicite |
| Erreur réseau | ✅ Alert avec message |

---

**Fin du rapport PH15-AMAZON-OAUTH-REDIRECT-FIX-02**
