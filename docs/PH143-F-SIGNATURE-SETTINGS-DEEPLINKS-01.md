# PH143-F — Signature / Settings / Deep-links Rebuild

**Phase** : PH143-F-SIGNATURE-SETTINGS-DEEPLINKS-REBUILD-01
**Date** : 5 avril 2026
**Branches** : `rebuild/ph143-client` / `rebuild/ph143-api`
**Environnement** : DEV uniquement

---

## 1. Resume executif

Reconstruction complete du bloc Signature / Settings / Deep-links sur la ligne rebuild PH143.

Resultats :
- Signature save + load via API : **FONCTIONNEL**
- Onglet Signature dans Settings : **FONCTIONNEL**
- Deep-links `?tab=` : **FONCTIONNEL** (signature, ai, agents, profile...)
- Sauvegarde UI end-to-end : **VALIDEE** (modification + persistance DB verifiee)
- signatureResolver avec priorite : **PRESENT** (settings > agent > tenant > fallback)

---

## 2. Fichiers restaures / modifies

### API (`rebuild/ph143-api`)
| Fichier | Action |
|---------|--------|
| `src/lib/signatureResolver.ts` | Deja present (depuis PH143-D) |
| `src/modules/auth/tenant-context-routes.ts` | Import `getSignatureConfig` + `formatSignature` ajoute, helper `formatSignaturePreview` ajoute, endpoints GET/PUT `/signature/:tenantId` ajoutes (97 lignes) |

### Client (`rebuild/ph143-client`)
| Fichier | Action |
|---------|--------|
| `app/api/tenant-context/signature/route.ts` | Cree (BFF GET + PUT proxy) |
| `app/settings/components/SignatureTab.tsx` | Porte depuis main, import `useTenantId` corrige |
| `app/settings/page.tsx` | Porte depuis main (deep-links + SignatureTab + icone Pen) |
| `app/settings/page.tsx.bak` | Supprime (nettoyage) |

---

## 3. Bug corrige en cours de phase

**Probleme** : Le `SignatureTab.tsx` importait `useTenantId` depuis `@/src/features/tenant/useTenantId` (qui utilise `useSession()` de NextAuth — le `tenantId` n'est pas toujours dans le token JWT). Consequence : aucun appel reseau a l'API signature.

**Fix** : Import change vers `@/src/features/tenant` (qui utilise le TenantProvider context, coherent avec le reste de la page settings).

**Commit fix** : `ea84a3a` — `PH143-F fix SignatureTab useTenantId import`

---

## 4. Tests API

| Test | Resultat |
|------|----------|
| `GET /health` | 200 — `{"status":"ok"}` |
| `GET /tenant-context/signature/switaa-sasu-mnc1x4eq` | 200 — config + preview + resolvedPreview |
| `PUT /tenant-context/signature/switaa-sasu-mnc1x4eq` | 200 — `{"success":true,"preview":"..."}` |
| `GET` apres `PUT` | Donnees persistees correctement |

Reponse GET typique :
```json
{
  "signature": {
    "companyName": "SWITAA SASU",
    "senderName": "Ludovic PH143F",
    "senderTitle": "Service Client"
  },
  "preview": "Cordialement,\nLudovic PH143F\nService Client\nSWITAA SASU",
  "resolvedPreview": "Cordialement,\nLudovic PH143F\nService Client\nSWITAA SASU"
}
```

---

## 5. Tests UI reels (navigateur)

### Deep-links
| URL | Resultat |
|-----|----------|
| `/settings?tab=signature` | Onglet Signature ouvert directement |
| `/settings?tab=ai` | Onglet IA ouvert directement |
| `/settings?tab=agents` | Onglet Agents ouvert directement |
| `/settings` (sans param) | Onglet Entreprise par defaut |

### SignatureTab
| Test | Resultat |
|------|----------|
| Chargement donnees depuis API | OK — champs pre-remplis |
| Modification champ | Bouton "Enregistrer" actif + "Annuler" visible |
| Clic "Enregistrer" | "Enregistrement..." affiche |
| Apres sauvegarde | Bouton disabled, "Annuler" disparu |
| Persistance DB | Verifiee via API — valeurs mises a jour |
| Apercu signature | "Signature active (avec fallback agent) :" visible |

### Settings (10 onglets)
| Onglet | Visible |
|--------|---------|
| Entreprise | Oui |
| Horaires | Oui |
| Conges | Oui |
| Messages auto | Oui |
| Notifications | Oui |
| Intelligence Artificielle | Oui |
| **Signature** | **Oui (nouveau)** |
| Espaces | Oui |
| Agents | Oui (owner/admin) |
| Avance | Oui |

---

## 6. Non-regression

| Feature | Statut |
|---------|--------|
| Inbox | OK (23 conversations) |
| Login OTP | OK |
| Sidebar complete | OK (13 liens) |
| Billing | OK (API 200) |
| Agents | OK (onglet visible) |
| IA Assist | OK (PH143-E.1) |
| Autopilot settings | OK (PH143-E) |

---

## 7. Commits SHA

| Repo | SHA | Message |
|------|-----|---------|
| keybuzz-api | `e8f2c06` | PH143-F rebuild signature settings deep-links |
| keybuzz-client | `909a9e8` | PH143-F rebuild signature settings deep-links |
| keybuzz-client | `ea84a3a` | PH143-F fix SignatureTab useTenantId import |

---

## 8. Images DEV

| Service | Tag |
|---------|-----|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.199-ph143-signature-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.199b-ph143-signature-fix-dev` |

---

## 9. Verdict

**GO pour PH143-G (Dashboard / Supervision / SLA)**

Signature, Settings et Deep-links sont pleinement fonctionnels sur la ligne rebuild.
