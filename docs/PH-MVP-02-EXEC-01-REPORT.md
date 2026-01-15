# PH-MVP-02-EXEC-01 — Rapport Fix 3 Bugs MVP

**Date** : 2026-01-15  
**Version** : 0.2.105-mvp-fixes-v2  
**Statut** : ✅ TERMINÉ

---

## Résumé

Correction de 3 bugs MVP identifiés :
1. **Décodage sujets MIME** (RFC 2047) : sujets `=?UTF-8?Q?...?=` maintenant lisibles
2. **Logo KeyBuzz + redirect** : logo officiel + redirection `/dashboard` (owner) ou `/inbox` (agent)
3. **URL rbac=restricted** : remplacé par toast "Accès restreint" sans query param

---

## FIX #1 — Décodage Sujets MIME (RFC 2047)

### Problème

Les sujets d'emails forwardés Amazon contenaient du MIME encodé non décodé :
```
=?UTF-8?Q?Notifications_Amazon_Seller_Central_=28Ne_pas_r=C3=A9pondre=29?=
```

### Solution

Création d'un décodeur MIME RFC 2047 supportant :
- **Quoted-printable (Q)** : `=XX` hex, `_` → espace
- **Base64 (B)** : décodage standard
- **Charsets** : UTF-8, ISO-8859-1/Latin1

### Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `src/lib/mime-decode.ts` | ✅ Nouveau - Fonction `decodeMimeSubject()` |
| `app/inbox/InboxTripane.tsx` | ✅ Import + application au `subject` et `customerName` |

### Avant / Après

| Avant | Après |
|-------|-------|
| `=?UTF-8?Q?Notifications_Amazon_Seller_Central_=28Ne_pas_r=C3=A9pondre=29?=` | `Notifications Amazon Seller Central (Ne pas répondre)` |

### Preuve

![Inbox avec sujets décodés](inbox-owner-mime-decoded.png)

---

## FIX #2 — Logo KeyBuzz + Redirect

### Problème

- Logo : icône générique "K" au lieu du logo officiel
- Clic logo → `/inbox` pour tout le monde (même owner)

### Solution

| Rôle | Destination Logo |
|------|------------------|
| Owner/Admin | `/dashboard` |
| Agent | `/inbox` |

### Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `public/keybuzz-icon.png` | ✅ Nouveau - Logo officiel |
| `src/components/layout/ClientLayout.tsx` | ✅ `<img src="/keybuzz-icon.png">` + `href={isAgent ? "/inbox" : "/dashboard"}` |

### Code

```tsx
<Link href={isAgent ? "/inbox" : "/dashboard"} className="flex items-center gap-2">
  <img 
    src="/keybuzz-icon.png" 
    alt="KeyBuzz" 
    className="h-8 w-8 rounded-lg"
  />
  <span className="text-lg font-bold text-white">KeyBuzz</span>
</Link>
```

### Preuve

- Owner connecté : clic logo → `/dashboard` ✅
- Version dans sidebar : `KeyBuzz Client v0.2.105`

---

## FIX #3 — Cacher `?rbac=restricted` dans URL

### Problème

Agent redirigé vers `/inbox?rbac=restricted` exposant un query param technique.

### Solution

1. Redirection clean vers `/inbox` (sans query param)
2. Toast visuel "Accès restreint" affiché

### Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `src/features/tenant/TenantProvider.tsx` | ✅ `showRbacToast` state + redirect `/inbox` clean |
| `app/inbox/InboxTripane.tsx` | ✅ Toast UI "Accès restreint" |

### Code Toast

```tsx
{/* PH-MVP-02-EXEC-01: RBAC restricted toast */}
{showRbacToast && (
  <div className="fixed top-4 left-1/2 transform -translate-x-1/2 z-50 bg-amber-50 ...">
    <AlertTriangle className="h-5 w-5 text-amber-600" />
    <span>Accès restreint : cette page est réservée aux propriétaires et administrateurs.</span>
    <button onClick={() => setShowRbacToast(false)}>
      <X className="h-4 w-4" />
    </button>
  </div>
)}
```

### Comportement

| Action | Avant | Après |
|--------|-------|-------|
| Agent tente `/settings` | Redirigé vers `/inbox?rbac=restricted` | Redirigé vers `/inbox` + toast |
| URL exposée | `?rbac=restricted` visible | URL clean `/inbox` |

---

## Tests E2E

### Owner (ludo.gonthier)

| Test | Résultat |
|------|----------|
| Logo → `/dashboard` | ✅ |
| Inbox sujets décodés | ✅ |
| Accès `/settings` | ✅ |
| Version `0.2.105` | ✅ |

### Agent

| Test | Attendu |
|------|---------|
| Logo → `/inbox` | ✅ (code vérifié) |
| Tente `/settings` → `/inbox` + toast | ✅ (code vérifié) |
| URL clean (pas de `?rbac=`) | ✅ (code vérifié) |

---

## Déploiement

### Build & Push

```bash
# Version bump
npm version patch  # 0.2.104 → 0.2.105

# Build
npm run build

# Docker
docker build -t ghcr.io/keybuzzio/keybuzz-client:0.2.105-mvp-fixes-v2 .
docker push ghcr.io/keybuzzio/keybuzz-client:0.2.105-mvp-fixes-v2

# Deploy
kubectl -n keybuzz-client-dev set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:0.2.105-mvp-fixes-v2
```

### Vérification

```bash
curl -s https://client-dev.keybuzz.io/debug/version
# {"app":"app","version":"0.2.105","gitSha":"25e1e62","buildDate":"2026-01-15T10:11:48.070853Z"}
```

---

## Fichiers Créés/Modifiés

| Fichier | Type | Description |
|---------|------|-------------|
| `src/lib/mime-decode.ts` | Nouveau | Décodeur MIME RFC 2047 |
| `public/keybuzz-icon.png` | Nouveau | Logo officiel KeyBuzz |
| `src/components/layout/ClientLayout.tsx` | Modifié | Logo + redirect selon rôle |
| `src/features/tenant/TenantProvider.tsx` | Modifié | RBAC toast state |
| `app/inbox/InboxTripane.tsx` | Modifié | MIME decode + RBAC toast UI |

---

## Non-régression

- ✅ SLA badges fonctionnels
- ✅ KPI cards fonctionnels
- ✅ Navigation intacte
- ✅ Filtres inbox OK
- ✅ Messages affichés correctement

---

## Conclusion

| Bug | Statut |
|-----|--------|
| Décodage MIME | ✅ Corrigé |
| Logo + redirect | ✅ Corrigé |
| URL rbac= | ✅ Corrigé |

**Zéro nouvelle feature ajoutée** — Corrections ciblées uniquement.

---

**Fin du rapport PH-MVP-02-EXEC-01**
