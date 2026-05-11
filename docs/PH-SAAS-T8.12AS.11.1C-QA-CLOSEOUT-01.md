# PH-SAAS-T8.12AS.11.1C-QA-CLOSEOUT-01

> Date : 2026-05-11
> Linear : KEY-304 (principal), KEY-301
> Phase : T8.12 AS.11.1C QA closeout / Linear/docs only / no code / no deploy
> Environnement : runtime read-only ; PROD inchange

---

## 1. VERDICT

GO MESSAGES DETAIL QA CLOSEOUT READY

QA Ludovic confirmee en DEV avec le compte business SWITAA `switaa26@gmail.com`. L Inbox SWITAA + l ouverture conversation detail + le Brouillon IA SWITAA AUTOPILOT sont fonctionnels post AS.11.1C. Aucune regression observee. PROD strictement inchange.

KEY-304 reste In Review (NE PAS Done) : seuls les endpoints LIST et DETAIL sont proteges. Les 4 routes restantes (reply, status, assign, sav-status) seront migrees aux sous-phases dediees AS.11.1d -> AS.11.1f.

KEY-301 reste Open : 2/6 endpoints `/messages` proteges runtime DEV.

Aucun patch source, aucun build, aucun deploy, aucun kubectl apply, aucune mutation DB realises dans cette phase. Smoke V1 reconfirme PASS=18 WARN=0 FAIL=0 SKIP=1 sur bastion install-v3.

---

## 2. Runtime

| Env | Service | Image | MATCH GitOps |
|---|---|---|---|
| DEV | keybuzz-api | v3.5.171-messages-detail-tenantguard-dev | yes |
| DEV | keybuzz-client | v3.5.185-messages-detail-bff-dev | yes |
| PROD | keybuzz-api | v3.5.151-conversation-tone-metric-prod | yes |
| PROD | keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod | yes |

Aucun drift GitOps post AS.11.1C. Smoke V1 PASS=18 WARN=0 FAIL=0 SKIP=1.

---

## 3. Ludovic QA

QA reportee par Ludovic (sans donnees client copiees) :

| Item | Resultat |
|---|---|
| Compte session NextAuth | `switaa26@gmail.com` (business SWITAA owner) |
| Tenant courant en navigateur | SWITAA (switaa-sasu-mnc1x4eq) |
| Inbox SWITAA -- liste conversations visible | OUI (LIST via BFF AS.11.1A-R2) |
| Conversation detail visible apres clic | OUI (DETAIL via BFF AS.11.1C, nouveau) |
| Brouillon IA -- visible automatiquement sur conv AUTOPILOT eligible | OUI |
| Bouton "Valider et envoyer" visible | OUI (NON clique) |
| Boutons "Modifier" / "Ignorer" visibles | OUI (NON cliques) |
| Aucune banniere "API indisponible" | OUI |
| Aucune erreur visible Inbox / channels / suppliers / catalogue / commande liee | OUI |
| Regression visible sur d autres surfaces | NON |

Conclusion QA : le pattern BFF list + detail + tenantGuard API actif sur GET `/messages/conversations` ET GET `/messages/conversations/:id` ne casse pas Inbox ni l ouverture de conversation pour un utilisateur legitimement membre du tenant. Le Brouillon IA reste fonctionnel grace au fix AS.11.0.6 (consolidated useEffect deterministe).

Aucune donnee client copiee dans ce rapport. Aucune capture ecran avec PII committee.

---

## 4. Linear updates

| Issue | Action | Commentaire URL | Statut |
|---|---|---|---|
| KEY-304 | commentaire QA closeout poste | section 4.1 | reste In Review (LIST+DETAIL OK, 4 endpoints futurs) |
| KEY-301 | commentaire progression poste | section 4.2 | reste Open/Todo (2/6 endpoints proteges runtime) |

### 4.1 KEY-304 commentaire

```
## AS.11.1C QA Ludovic OK

- LIST + DETAIL endpoints protected in DEV.
- Security validation 7/7 PASS (LIST 401 no-auth, DETAIL 401 no-auth, bogus 403, switaa26 owner 200, Ludovic personnel cross-tenant 403, reply GET 404 scope strict, /autopilot/draft inchange).
- Smoke V1 PASS=19 WARN=0 FAIL=0 SKIP=0.
- QA Ludovic with `switaa26@gmail.com` (business SWITAA owner) : Inbox list + conversation detail + Brouillon IA all functional, no regression observed.
- PROD strictly unchanged (6 services).
- Runtime DEV : API v3.5.171-messages-detail-tenantguard-dev + Client v3.5.185-messages-detail-bff-dev, MATCH=yes GitOps.

KEY-304 remains In Review because reply/status/assign/sav-status remain future phases AS.11.1d -> AS.11.1f. Do NOT mark Done until all 6 endpoints are migrated and validated.

Next phase AS.11.1d : `POST /messages/conversations/:id/reply` with matching Client BFF migration. Risk : mutation endpoint -- validation envoi message obligatoire (sans cliquer Valider).

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1C-QA-CLOSEOUT-01.md
```

### 4.2 KEY-301 commentaire

```
Partial runtime mitigation in DEV now covers /messages/conversations LIST + /messages/conversations/:id DETAIL. Cross-tenant access denied PROVEN for both endpoints (ecomlg-001 user attempting SWITAA -> 403 NOT_MEMBER).

Progression KEY-301 : 2/6 endpoints `/messages` proteges. Continue endpoint-by-endpoint sequence AS.11.1d -> AS.11.1f before considering PROD promotion (KEY-263 blocker).

KEY-301 stays Open. QA Ludovic confirmed Inbox + Brouillon IA still functional in DEV with switaa26@gmail.com.

Disclosure controle : pas de PoC, pas de details exploit.
```

---

## 5. Remaining endpoints (AS.11.1d -> AS.11.1f)

| Sous-phase | Endpoint | Method | Pattern matcher requis | Risque |
|---|---|---|---|---|
| AS.11.1d | `/messages/conversations/:id/reply` | POST | path startsWith `/messages/conversations/<id>/reply` + method POST | **mutation send message**. QA sans cliquer Valider. |
| AS.11.1e | `/messages/conversations/:id/status` | PATCH | path startsWith `/messages/conversations/<id>/status` + method PATCH | mutation status. QA sans changer statut. |
| AS.11.1f-1 | `/messages/conversations/:id/assign` | PATCH | idem assign | mutation assignation. QA sans assign. |
| AS.11.1f-2 | `/messages/conversations/:id/sav-status` | PATCH | idem sav-status | mutation SAV. QA sans changer SAV status. |
| AS.11.1g | promotion PROD coordonnee | n/a | post toutes sous-phases DEV valides | KEY-263 closure conditionnelle |

Pattern matcher pour les 4 endpoints suivants : tous ont le format `/messages/conversations/{id}/{action}` avec 2 segments apres `/messages/conversations/`. Un helper generique pourrait etre :

```typescript
function isMessagesConversationSubpathProtected(method, path): boolean {
  if (!path.startsWith('/messages/conversations/')) return false;
  const rest = path.substring('/messages/conversations/'.length);
  const segments = rest.split('/');
  if (segments.length !== 2 || !segments[0] || !segments[1]) return false;
  const [, action] = segments;
  // Define allowed (method, action) tuples
  const sub = (action: string, m: string): boolean => {
    if (m === 'POST'  && action === 'reply') return true;        // AS.11.1d
    if (m === 'PATCH' && action === 'status') return true;       // AS.11.1e
    if (m === 'PATCH' && action === 'assign') return true;       // AS.11.1f-1
    if (m === 'PATCH' && action === 'sav-status') return true;   // AS.11.1f-2
    return false;
  };
  return sub(action, method);
}
```

Cela permettrait d ajouter les 4 endpoints en une seule sous-phase si Ludovic prefere (au lieu de 4 sous-phases separees). A discuter au lancement AS.11.1d.

---

## 6. Next phase

**AS.11.1d proposition** : `POST /messages/conversations/:id/reply` + Client BFF reply route.

Prerequis :
- Adaptation `isProtected` pour matcher path + method POST sur sub-path `/reply`.
- Helper Client BFF reply route avec POST forward (body raw).
- Modification UNE seule entree `conversationReply` dans `src/config/api.ts`.
- Build API v3.5.172 + Client v3.5.186 (numero libre).
- KEY-302 + KEY-308 + KEY-309 obligatoires.
- QA gating critique : send reply UI doit fonctionner pour Ludovic en navigateur switaa26@gmail.com. **NE PAS cliquer Valider/envoyer pendant la QA** -- la presence du bouton et l absence de banniere d erreur suffisent a confirmer que le path BFF est joignable.

---

## 7. Compliance AS.11.1C-QA

| Verification | Statut |
|---|---|
| Aucun patch source | OK |
| Aucun build | OK |
| Aucun deploy | OK |
| Aucun kubectl apply/set/patch/edit | OK |
| Aucune mutation manifest (1 commit docs-only) | OK |
| Aucune mutation DB | OK |
| Aucun secret affiche | OK |
| Aucune PII | OK |
| KEY-304 ne pas Done | OK (reste In Review) |

---

### 7.bis Phrase cible finale

AS.11.1C QA closeout livre : Ludovic confirme en navigateur DEV avec `switaa26@gmail.com` que l Inbox SWITAA + l ouverture conversation detail + Brouillon IA visible auto fonctionnent post AS.11.1C ; runtime DEV MATCH=yes GitOps (API v3.5.171 + Client v3.5.185) ; PROD strictement inchange (6 services) ; smoke V1 PASS=18 WARN=0 ; KEY-304 reste In Review (LIST+DETAIL OK, 4 endpoints `/messages` restants : reply/status/assign/sav-status) ; KEY-301 reste Open (2/6 endpoints proteges runtime) ; aucun patch source, aucun build, aucun deploy, aucun kubectl apply, aucune mutation DB realises ; verdict AS.11.1C-QA GO MESSAGES DETAIL QA CLOSEOUT READY.

STOP
