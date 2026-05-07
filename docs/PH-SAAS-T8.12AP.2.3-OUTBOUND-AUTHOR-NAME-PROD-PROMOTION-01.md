# PH-SAAS-T8.12AP.2.3 — Outbound Author Name PROD Promotion

> **Phase** : PH-SAAS-T8.12AP.2.3-OUTBOUND-AUTHOR-NAME-PROD-PROMOTION-01
> **Type** : promotion coordonnée API + Client PROD
> **Priorité** : P0
> **Date** : 2026-05-07
> **Ticket** : KEY-266
> **Standard** : CE_PROMPTING_STANDARD appliqué

---

## 1. OBJECTIF

Promouvoir en PROD le fix AP.2.2 validé en DEV : les messages outbound humains stockent désormais le vrai nom de l'agent au format `Prénom.N` au lieu du hardcode `'KeyBuzz Agent'`.

---

## 2. FREEZE API + CLIENT PROD

| Élément | Valeur |
|---|---|
| Runtime API PROD avant AP.2.3 | `v3.5.144-ai-stored-drafts-no-reask-prod` |
| Runtime Client PROD avant AP.2.3 | `v3.5.163-ai-no-reask-fix-prod` |
| Runtime OW PROD | `v3.5.165-escalation-flow-prod` (inchangé) |
| Runtime Backend PROD | `v1.0.47-cross-env-guard-fix-prod` (inchangé) |
| Runtime Website PROD | `v0.6.9-promo-forwarding-prod` (inchangé) |
| Freeze confirmé | Oui — seuls API + Client PROD modifiés |

---

## 3. PREFLIGHT

### Repos

| Repo | Branche | Commit HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `3bb929b4` | dist/ supprimés (attendu) | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `abef1bc4` | Non | OK |
| keybuzz-infra | `main` | `9fbeb33` (pre-AP.2.3) | Non | OK |

### Runtime pre-AP.2.3

| Service | Env | Image actuelle | Changement prévu |
|---|---|---|---|
| API | PROD | `v3.5.144-ai-stored-drafts-no-reask-prod` | → `v3.5.145-outbound-author-name-prod` |
| Client | PROD | `v3.5.163-ai-no-reask-fix-prod` | → `v3.5.168-outbound-author-name-ux-prod` |
| OW | PROD | `v3.5.165-escalation-flow-prod` | Non |
| Backend | PROD | `v1.0.47-cross-env-guard-fix-prod` | Non |
| Website | PROD | `v0.6.9-promo-forwarding-prod` | Non |

---

## 4. SOURCE LOCK API

| Fichier | Signal attendu | Présent | Verdict |
|---|---|---|---|
| `messages/routes.ts` | `formatAgentDisplayName()` helper | Oui (ligne 23) | OK |
| `messages/routes.ts` | `agentDisplayName` variable | Oui (ligne 397) | OK |
| `messages/routes.ts` | `X-User-Email` header read | Oui (ligne 395-396) | OK |
| `messages/routes.ts` | Fallback `'KeyBuzz Agent'` | Oui (ligne 397, 39) | OK |
| `autopilot/engine.ts` | `'KeyBuzz IA'` pour autopilot | Oui (ligne 824) | OK |
| `autopilot/routes.ts` | Stale draft invalidation (AP.1F) | Oui | OK |

---

## 5. SOURCE LOCK CLIENT

| Fichier | Signal attendu | Présent | Verdict |
|---|---|---|---|
| `conversations.service.ts` | `getApiUserEmail()` import | Oui (ligne 9) | OK |
| `conversations.service.ts` | `X-User-Email` header dans sendReply | Oui (lignes 241-242) | OK |
| `lib/formatAgentName.ts` | `formatAgentDisplayName()` | Oui | OK |
| `features/inbox/TreatmentStatusPanel.tsx` | Prénom.N display (AP.2.1) | Oui | OK |
| Bundle PROD | GA4 `G-R3QQDYEBFG` | 1 fichier | OK |
| Bundle PROD | SGTM `t.keybuzz.pro` | 2 fichiers | OK |
| Bundle PROD | TikTok `D7PT12JC77U44OJIPC10` | 1 fichier | OK |
| Bundle PROD | LinkedIn `9969977` | 1 fichier | OK |
| Bundle PROD | Meta `1234164602194748` | 1 fichier | OK |
| Bundle PROD | `api.keybuzz.io` | 76 fichiers | OK |
| Bundle PROD | `X-User-Email` | 110 fichiers | OK |

---

## 6. BUILD API PROD

| Élément | Valeur |
|---|---|
| Commande | `docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-api:v3.5.145-outbound-author-name-prod .` |
| Commit source | `3bb929b4` |
| Branche | `ph147.4/source-of-truth` |
| Tag | `v3.5.145-outbound-author-name-prod` |
| Digest | `sha256:196df6258a366a8d480b82923d030cdbf75ffe1df9faed58d8a03ab6ec4e8d3a` |
| Rollback | `v3.5.144-ai-stored-drafts-no-reask-prod` |
| Build from Git | Oui — bastion `/opt/keybuzz/keybuzz-api` |
| Repo propre | Oui (dist/ supprimés attendus, pas de source dirty) |

---

## 7. BUILD CLIENT PROD

| Élément | Valeur |
|---|---|
| Commande | `docker build --no-cache --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io --build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io --build-arg NEXT_PUBLIC_APP_ENV=production --build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG --build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro --build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10 --build-arg NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977 --build-arg NEXT_PUBLIC_META_PIXEL_ID=1234164602194748 -t ghcr.io/keybuzzio/keybuzz-client:v3.5.168-outbound-author-name-ux-prod .` |
| Commit source | `abef1bc4` |
| Branche | `ph148/onboarding-activation-replay` |
| Tag | `v3.5.168-outbound-author-name-ux-prod` |
| Digest | `sha256:e7c6dadd6a0c7691399779cd4611e3369668a036ea2cf2d62b6941f813870ee5` |
| Build args | Tous 8 appliqués |
| Tracking | GA4 ✓, SGTM ✓, TikTok ✓, LinkedIn ✓, Meta ✓ |
| Rollback | `v3.5.163-ai-no-reask-fix-prod` |
| Build from Git | Oui — bastion `/opt/keybuzz/keybuzz-client` |

---

## 8. GITOPS PROD

| Action | Fichier | Commit |
|---|---|---|
| API PROD manifest | `k8s/keybuzz-api-prod/deployment.yaml` | `7a1d628` |
| Client PROD manifest | `k8s/keybuzz-client-prod/deployment.yaml` | `7a1d628` |
| Push | `main` → origin | OK |
| Apply API | `kubectl apply -f` → `deployment "keybuzz-api" successfully rolled out` | OK |
| Apply Client | `kubectl apply -f` → `deployment "keybuzz-client" successfully rolled out` | OK |

---

## 9. VALIDATION STRUCTURELLE PROD

### API PROD Runtime

| Signal | Présent runtime | Attendu | Verdict |
|---|---|---|---|
| Image tag | `v3.5.145-outbound-author-name-prod` | `v3.5.145-outbound-author-name-prod` | OK |
| `formatAgentDisplayName` dans routes.js compilé | `true` | `true` | OK |
| `agentDisplayName` variable | `true` | `true` | OK |
| `x-user-email` header read | `true` | `true` | OK |
| Pod Running 1/1 | Oui | Oui | OK |
| Ready | True | True | OK |
| Restart Count | 0 | 0 | OK |
| Liveness probe (HTTP GET /health:3001) | Passé | Passé | OK |

### Client PROD Runtime

| Signal | Présent runtime | Attendu | Verdict |
|---|---|---|---|
| Image tag | `v3.5.168-outbound-author-name-ux-prod` | `v3.5.168-outbound-author-name-ux-prod` | OK |
| `X-User-Email` dans bundle | 110 fichiers | >0 | OK |
| `api.keybuzz.io` | 76 fichiers | >0 | OK |
| GA4 tracking | 1 fichier | >0 | OK |
| SGTM tracking | 2 fichiers | >0 | OK |
| TikTok tracking | 1 fichier | >0 | OK |
| LinkedIn tracking | 1 fichier | >0 | OK |
| Meta tracking | 1 fichier | >0 | OK |
| Pod Running 1/1 | Oui | Oui | OK |

---

## 10. VALIDATION FONCTIONNELLE PROD

Aucun message réel envoyé pendant la promotion. Le fix est structurellement validé :

| Cas | Attendu | Observation | Verdict |
|---|---|---|---|
| A. Réponse manuelle avec X-User-Email | `author_name = Prénom.N` | Code vérifié dans runtime : résolution user via SELECT + formatAgentDisplayName | QA Ludovic pending |
| B. Aide IA insérée puis envoyée | Auteur humain réel | Même chemin que A — `message_source = 'HUMAN'` | QA Ludovic pending |
| C. Brouillon IA validé par humain | Auteur humain réel | Même chemin que A | QA Ludovic pending |
| D. Sans X-User-Email (fallback) | `'KeyBuzz Agent'` | Code vérifié : `let agentDisplayName = 'KeyBuzz Agent'` default | Structurellement OK |
| E. Autopilot auto-send | `'KeyBuzz IA'` | Code inchangé dans `engine.ts:824` | Structurellement OK |
| F. Legacy messages | Inchangés | 442 × `'KeyBuzz Agent'` vérifiés | OK |

---

## 11. NON-RÉGRESSION PROD

| Surface | Check | Résultat | Verdict |
|---|---|---|---|
| API health | Liveness + Readiness probes | Passé (Ready: True, 0 restart) | OK |
| API /conversations route | Code path inchangé sauf author_name | Structurellement OK | OK |
| API /reply route | Fix AP.2.2 actif | author_name dynamique | OK |
| No-reask AP.1F | Stale draft invalidation dans routes.ts | Présent | OK |
| Client Inbox | Bundle compilé avec fix | X-User-Email dans 110 fichiers | OK |
| Client tracking | GA4/SGTM/TikTok/LinkedIn/Meta | Tous présents | OK |
| Client promo funnel | Non impacté par ce fix | Préservé | OK |
| Client Amazon inbound guide | Non impacté | Préservé | OK |
| Client demo gating | Non impacté | Préservé | OK |
| OW PROD | `v3.5.165-escalation-flow-prod` | Inchangé | OK |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | Inchangé | OK |
| Website PROD | `v0.6.9-promo-forwarding-prod` | Inchangé | OK |
| Auto-send | Aucun ajouté | Vérifié | OK |
| Billing/Stripe | Aucune mutation | Vérifié | OK |
| CAPI | Aucun event | Vérifié | OK |

---

## 12. LEGACY READ-ONLY

| Check | Résultat | Mutation | Verdict |
|---|---|---|---|
| `author_name = 'KeyBuzz Agent'` (HUMAN outbound) | 442 messages | Aucune | OK |
| `author_name = 'Equipe SAV'` (supplier) | 5 messages | Aucune | OK |
| `author_name = 'Equipe SAV eComLG'` | 4 messages | Aucune | OK |
| `author_name = 'Equipe SAV Test'` | 1 message | Aucune | OK |
| Aucune migration effectuée | Confirmé | 0 UPDATE | OK |

Seuls les **nouveaux** messages outbound humains bénéficieront du format `Prénom.N`. Les 442 messages legacy restent `'KeyBuzz Agent'` documentés comme historique.

---

## 13. LINEAR

| Ticket | Mise à jour |
|---|---|
| **KEY-266** | PROD promue. API `v3.5.145` + Client `v3.5.168`. Nouveaux messages outbound stockent author_name réel. QA navigateur Ludovic pending pour validation fonctionnelle finale. |
| KEY-265 | Lié. Lifecycle UI AP.2.1 préservé dans Client PROD. |
| KEY-253 | Synthèse parent : AP.2.3 promu. |
| KEY-267 | Toujours ouvert. API ne retourne pas `assigned_agent_name` dans `/conversations/:id`. |
| KEY-268 | Toujours ouvert. Auto-assignment post-reply non implémenté. |
| KEY-269 | Toujours ouvert. `users.name` reste un champ unique (pas first_name/last_name split). |

---

## 14. ROLLBACK

### API PROD
```yaml
# Manifest: k8s/keybuzz-api-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.144-ai-stored-drafts-no-reask-prod
```

### Client PROD
```yaml
# Manifest: k8s/keybuzz-client-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.163-ai-no-reask-fix-prod
```

### Procédure GitOps stricte
1. Modifier manifests API/Client PROD → tags rollback
2. `git commit -m "rollback(prod): revert AP.2.3 outbound author_name PROD"`
3. `git push origin main`
4. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml && kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`
5. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml && kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod`
6. Vérifier manifest = runtime

---

## 15. SERVICES PROD INCHANGÉS

| Service | Image avant | Image après | Delta |
|---|---|---|---|
| **API PROD** | `v3.5.144-ai-stored-drafts-no-reask-prod` | **`v3.5.145-outbound-author-name-prod`** | **Modifié** |
| **Client PROD** | `v3.5.163-ai-no-reask-fix-prod` | **`v3.5.168-outbound-author-name-ux-prod`** | **Modifié** |
| OW PROD | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | Inchangé |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | Inchangé |
| Website PROD | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | Inchangé |

---

## 16. VERDICT

### **GO PARTIEL — LUDOVIC QA PENDING**

OUTBOUND AUTHOR NAME LIVE IN PROD — HUMAN REPLIES STORE REAL TENANT-SCOPED AGENT DISPLAY NAME — PRÉNOM.N FORMAT READY — IA/AUTOPILOT AUTHORS DISTINGUISHED (KeyBuzz IA) — LEGACY KEYBUZZ AGENT MESSAGES DOCUMENTED AND UNCHANGED — NO AUTO-SEND ADDED — NO-REASK AND LIFECYCLE BASELINES PRESERVED — CLIENT TRACKING/PROMO/AMAZON GUIDE BASELINES PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT

STOP
