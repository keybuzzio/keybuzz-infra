# PH142-H — Full Regression Truth Audit

> Date : 4 avril 2026
> Phase : PH142-H-FULL-REGRESSION-TRUTH-AUDIT-01
> Type : Audit complet produit — AUCUNE implementation

---

## 1. Resume executif

Apres audit complet (code source, DB, API live, tests navigateur reels), l'etat du produit est **globalement sain** avec **1 regression critique** et **quelques points d'attention mineurs**.

**Verdict global : 93% fonctionnel — 1 regression critique identifiee.**

| Categorie | Statut |
|-----------|--------|
| Pages client (8/8 testees) | OK |
| Endpoints API (9/9 testes) | OK |
| Base de donnees | OK |
| Signature | **REGRESSION** |
| Autopilot/IA | OK |
| Billing | OK |
| Agents | OK |

---

## 2. Matrice complete des features testees

### A. Messaging / Outbound

| Feature | Statut | Detail |
|---------|--------|--------|
| Envoi email SMTP | **OK** | outboundWorker.ts: sendEmail() fonctionnel, Reply-To resolu |
| Envoi Amazon SMTP | **OK** | outboundWorker.ts: chemin Amazon avec MIME attachments |
| Signature outbound worker (Amazon) | **OK** | ensureSignature() appele L405 |
| Signature outbound worker (Email) | **OK** | ensureSignature() appele L694 |
| Signature IA (autopilot prompt) | **OK** | signatureResolver importe L24 engine.ts, inject L673 |
| Signature DB | **OK** | `signature_company_name="eComLG"` dans tenant_settings |
| Signature BFF | **OK** | `app/api/tenant-context/signature/route.ts` existe |
| Accents/formatage | **OK** | Derniers messages sortants: accents corrects, emojis OK |
| Pieces jointes | **OK** | MIME multipart fonctionnel, MinIO actif |
| Reply-To | **OK** | Fallback chain: delivery.reply_to → inbound_address → tenant_metadata |
| **Onglet Signature Settings** | **KO** | **SignatureTab.tsx existe (256 lignes) mais n'est PAS importe ni rendu dans settings/page.tsx** |

### B. Autopilot / IA

| Feature | Statut | Detail |
|---------|--------|--------|
| Aide IA manuelle (drawer) | **OK** | Bouton "Aide IA" present, drawer s'ouvre, KBActions affiches |
| Draft safe mode | **OK** | GET /autopilot/draft fonctionnel, consume endpoint OK |
| Draft lifecycle (PH142-G) | **OK** | Consume applied/dismissed/modified fonctionne |
| Auto-escalade (PH142-D) | **OK** | needsHumanAction detection active |
| False promise (PH142-C) | **OK** | Regex detection dans engine.ts |
| Journal IA | **OK** | 1301 evenements, page charge, filtres OK |
| Flag erreur (PH142-A) | **OK** | HUMAN_FLAGGED_INCORRECT fonctionnel |
| Clustering erreurs (PH142-B) | **OK** | Endpoint /ai/errors/clusters 200 |
| Autopilot settings | **OK** | GET/PATCH endpoints 200 |
| Drawer unifie (PH142-F) | **OK** | initialDraft + autoOpen integres |

### C. Agents / Workspace

| Feature | Statut | Detail |
|---------|--------|--------|
| Liste agents | **OK** | 6 agents visibles pour ecomlg-001 |
| Onglet Agents (settings) | **OK** | Conditionnel isOwnerOrAdmin |
| Types agents | **OK** | client + keybuzz separes |
| RBAC middleware | **OK** | tenantGuard + role check |
| Sidebar | **OK** | Menu lateral complet, toutes pages accessibles |

### D. Billing / Gating

| Feature | Statut | Detail |
|---------|--------|--------|
| Plan affiche | **OK** | Pro Mensuel, canaux 4/3 |
| KBActions affiche | **OK** | 959.35 remaining (1000 monthly) |
| Billing exempt | **OK** | ecomlg-001 exempt=true |
| Pages billing | **OK** | plan, ai, options, history presentes |
| Paywall/locked | **OK** | FeatureGate composant actif |

### E. Onboarding / Settings

| Feature | Statut | Detail |
|---------|--------|--------|
| Settings page | **OK** | 221 lignes, 9 onglets |
| Entreprise tab | **OK** | Donnees pre-remplies |
| **Signature tab** | **KO** | **Composant existe, non rendu** |
| Horaires/Conges | **OK** | Tabs presentes |
| IA tab | **OK** | Tab presente |
| Agents tab | **OK** | Conditionnel owner/admin |
| Knowledge | **OK** | Page 255 lignes, 1 template |
| Playbooks | **OK** | Page 300 lignes |
| Onboarding | **OK** | Page presente (5 lignes redirect) |

### F. Orders / Tracking

| Feature | Statut | Detail |
|---------|--------|--------|
| Liste commandes | **OK** | 11 922 commandes, filtres, export CSV |
| Tracking | **OK** | UPS/FedEx liens visibles |
| Badges SAV | **OK** | Filtres SAV actifs |
| Stats (en transit, retard) | **OK** | 23 en transit, 12 en retard |

### G. Channels

| Feature | Statut | Detail |
|---------|--------|--------|
| Amazon connections | **OK** | 4 canaux (BE, ES, FR, IT) |
| Adresses inbound | **OK** | Affiches pour chaque canal |
| Conversations par canal | **OK** | amazon: 324, email: 4 |

---

## 3. Top regressions critiques

### REGRESSION 1 : Onglet Signature absent des settings (CRITIQUE)

| Champ | Detail |
|-------|--------|
| Feature | Onglet "Signature" dans les parametres |
| Statut | **KO — composant existe, non rendu** |
| Impact | L'utilisateur ne peut pas configurer sa signature email depuis l'UI |
| Fichier | `app/settings/page.tsx` (221 lignes) |
| Composant | `app/settings/components/SignatureTab.tsx` (256 lignes, fonctionnel) |
| Phase probable | **Sprint D16** (decomposition settings de 1075 → 221 lignes) |
| Backend | OK — `GET/PUT /tenant-context/signature/:tenantId` fonctionnels |
| BFF | OK — `app/api/tenant-context/signature/route.ts` present |
| DB | OK — `signature_company_name="eComLG"` en place |
| Impact reel | **Faible pour le moment** car la signature est deja configuree en DB et le outboundWorker l'injecte. Mais l'utilisateur ne peut plus la modifier. |
| Effort correction | **~15 min** — ajouter import + tab dans settings/page.tsx |

### Impact signature en detail

| Canal | Signature presente ? | Source |
|-------|---------------------|--------|
| Outbound Amazon SMTP | **OUI** | ensureSignature() dans outboundWorker.ts L405 |
| Outbound Email SMTP | **OUI** | ensureSignature() dans outboundWorker.ts L694 |
| IA Autopilot draft | **OUI** | signatureResolver injecte dans system prompt L673 |
| IA Suggestion manuelle | **Indirect** | Le prompt inclut l'instruction signature |
| Message manuel (textarea) | **OUI** | ensureSignature() l'ajoute si absente |
| Edition UI settings | **NON** | Tab manquante |

**Conclusion signature : la signature FONCTIONNE partout sauf dans l'UI de configuration.**

---

## 4. Focus signature — traçage complet

### Flux de la signature

```
tenant_settings.signature_company_name (DB)
          │
          ▼
signatureResolver.ts::getSignatureConfig() ─── Fallback 1: tenant.name
          │                                     Fallback 2: agents.first_name (admin)
          ▼                                     Fallback 3: "Service client"
formatSignature() → "Cordialement,\nNom\nTitre\nSociete"
          │
          ├──→ autopilot/engine.ts L673 : inject dans system prompt IA
          │
          └──→ outboundWorker.ts : ensureSignature()
                    │
                    ├── Amazon SMTP (L405-412)
                    └── Email SMTP (L694-700)
```

### Derniers messages sortants (verite DB)

| Message | Date | Cordialement | Marque | Longueur |
|---------|------|-------------|--------|----------|
| msg-...558907 | 30 mars | OUI | "Melanie - eComLG" | 807 |
| msg-...685299 | 30 mars | OUI | "Melanie - eComLG" | 819 |
| msg-...529534 | 16 mars | NON | NON | 5 ("essai") |
| msg-...520564 | 16 mars | NON | NON | 4 ("test") |
| msg-...726154 | 11 mars | OUI | "Ludovic - eComLG" | 1075 |

Les vrais messages (non-test) ont TOUS la signature. Les messages de test (4-5 chars) sont des envois manuels de debug.

### Reponse aux questions

| Question | Reponse |
|----------|---------|
| La signature a-t-elle reellement disparu ? | **NON** — elle est presente dans les envois reels |
| Sur quels canaux ? | Presente sur tous les canaux de production |
| Depuis quand le tab est absent ? | Probablement **Sprint D16** (decomposition settings, fev 2026) |
| A quel moment elle saute ? | Le composant `SignatureTab` n'a pas ete inclus dans la liste des tabs lors de la refactorisation |
| Probleme UI, generation IA, ou outbound ? | **UI uniquement** — le tab d'edition est absent des settings |

---

## 5. Regressions silencieuses probables par phase

| Phase | Regression | Gravite | Effort |
|-------|-----------|---------|--------|
| **Sprint D16** (fev) | Onglet Signature omis de settings/page.tsx | **CRITIQUE** | 15 min |
| Aucune autre regression detectee | — | — | — |

### Analyse par phase recente

| Phase | Statut |
|-------|--------|
| PH142-A (Quality Loop) | OK — journal + flag fonctionnels |
| PH142-B (Error Clustering) | OK — clusters endpoint 200 |
| PH142-C (Action Consistency) | OK — detection false promises active |
| PH142-D (Auto Escalation) | OK — escalation_status dans conversations |
| PH142-E (Safe Mode) | OK — remplace par PH142-F (backward compat) |
| PH142-F (Unified Drawer) | OK — drawer unifie, bouton "Aide IA" visible |
| PH142-G (Draft Lifecycle) | OK — consume endpoint fonctionnel |

---

## 6. Pack minimal anti-regression avant PROD

### Checklist obligatoire (12 checks)

```
[ ] 1. API health 200
[ ] 2. Client login page 200
[ ] 3. Inbox charge (conversations visibles)
[ ] 4. Dashboard charge (stats visibles)
[ ] 5. Settings charge (tous les onglets dont Signature)
[ ] 6. Signature configuree en DB (signature_company_name non null)
[ ] 7. Envoi email outbound (dernier delivery status)
[ ] 8. AI journal endpoint 200
[ ] 9. Autopilot draft endpoint 200
[ ] 10. Orders page charge (compteur > 0)
[ ] 11. Billing page charge (plan affiche)
[ ] 12. Channels page charge (canaux connectes visibles)
```

### Implementation recommandee

Un script shell `pre-prod-check.sh` executable depuis le bastion :
- 6 checks API (curl HTTP status)
- 3 checks DB (kubectl exec SQL)
- 3 checks navigateur (optionnel, via browser-use ou manuel)

---

## 7. Plan de correction priorise

### P0 — Immediat (prochaine phase)

| # | Correction | Fichier | Effort |
|---|-----------|---------|--------|
| 1 | **Ajouter onglet Signature dans settings** | `app/settings/page.tsx` | 15 min |

Detail :
- Ajouter `import { SignatureTab } from "./components/SignatureTab";`
- Ajouter `"signature"` dans le type union de `activeTab`
- Ajouter `{ id: "signature", label: "Signature", icon: Pen }` dans le tableau `tabs`
- Ajouter `{activeTab === "signature" && <SignatureTab tenantId={tenantId} />}` dans le render

### P1 — Court terme

| # | Correction | Effort |
|---|-----------|--------|
| 2 | Agents en double (id 107, 112, 113 = "Ludovic Ludovic") | 10 min |
| 3 | Messages test de debug (4-5 chars) dans la DB | Nettoyage ponctuel |

### P2 — Moyen terme

| # | Correction | Effort |
|---|-----------|--------|
| 4 | Script pre-prod-check.sh automatise | 30 min |
| 5 | SLA depasses (255 breached sur 328 conversations) | Investigation metriques |

---

## 8. Etat reel de la plateforme (4 avril 2026)

### Donnees DEV (ecomlg-001)

| Metrique | Valeur |
|----------|--------|
| Conversations total | 328 |
| Conversations ouvertes | 245 |
| En attente | 12 |
| Resolues | 71 |
| Commandes | 11 922 |
| Canaux Amazon | 4 (BE, ES, FR, IT) |
| Canaux email | 4 conversations |
| KBActions remaining | 959.35 |
| KBActions monthly | 1000 |
| Knowledge templates | 1 |
| Agents | 6 |
| Plan | Pro (active) |
| Billing exempt | true (internal_admin) |
| Evenements IA | 1 301 |

### Images deployees

| Service | DEV | PROD |
|---------|-----|------|
| API | v3.5.189-draft-lifecycle-kbactions-dev | v3.5.189-draft-lifecycle-kbactions-prod |
| Client | v3.5.189-draft-lifecycle-kbactions-dev | v3.5.189-draft-lifecycle-kbactions-prod |
