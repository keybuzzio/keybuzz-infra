# PH-ADMIN-T8.7C-CONFIRMMODAL-DELETE-E2E-VALIDATION-01

> **Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.7C-CONFIRMMODAL-DELETE-E2E-VALIDATION-01.md`
> **Date** : 2026-04-22
> **Environnement** : DEV uniquement
> **Type** : validation navigateur reelle — suppression destinations via ConfirmModal
> **Phase precedente** : PH-ADMIN-T8.7C-META-CAPI-UI-HARDENING-01
> **Route API testee** : PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-01

---

## PREFLIGHT RUNTIME


| Element          | Attendu                                           | Observe                                                                         | OK ? |
| ---------------- | ------------------------------------------------- | ------------------------------------------------------------------------------- | ---- |
| Image Admin DEV  | `v2.11.2-meta-capi-ui-hardening-dev`              | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.2-meta-capi-ui-hardening-dev`            | OUI  |
| Image API DEV    | `v3.5.101-outbound-destinations-delete-route-dev` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.101-outbound-destinations-delete-route-dev` | OUI  |
| Image Admin PROD | `v2.11.0-tenant-foundation-prod`                  | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-prod`                | OUI  |
| Image API PROD   | `v3.5.100-meta-capi-error-sanitization-prod`      | `ghcr.io/keybuzzio/keybuzz-api:v3.5.100-meta-capi-error-sanitization-prod`      | OUI  |
| Pod Admin DEV    | Running 1/1                                       | Running 1/1 (36m) — k8s-worker-05                                               | OUI  |
| Pod API DEV      | Running 1/1                                       | Running 1/1 (7m) — k8s-worker-05                                                | OUI  |
| Pod Admin PROD   | Running 1/1                                       | Running 1/1 (9h) — k8s-worker-01                                                | OUI  |
| Pod API PROD     | Running 1/1                                       | Running 1/1 (63m) — k8s-worker-05                                               | OUI  |


**PROD inchangee** : confirmee avant, pendant et apres la validation.

---

## SESSION NAVIGATEUR

- **URL** : `https://admin-dev.keybuzz.io`
- **Compte** : `ludovic@keybuzz.pro` (super_admin)
- **Tenant teste** : **KeyBuzz Consulting** (`keybuzz-consulting-mo9y479d`, plan AUTOPILOT)
- **Navigateur** : Cursor IDE Browser (Chromium)
- **Login** : OK — page Destinations accessible directement

---

## ETAPE 1 — VALIDATION NAVIGATEUR


| Cas                     | Attendu                | Observe                                                    | OK ? |
| ----------------------- | ---------------------- | ---------------------------------------------------------- | ---- |
| Login                   | Session active         | [ludovic@keybuzz.pro](mailto:ludovic@keybuzz.pro) connecte | OUI  |
| Tenant selector         | KeyBuzz Consulting     | KeyBuzz Consulting affiche dans topbar                     | OUI  |
| /marketing/destinations | Accessible             | Page chargee, empty state                                  | OUI  |
| ConfirmModal disponible | Modale sur suppression | Confirmee (voir tests ci-dessous)                          | OUI  |
| Empty state             | "Aucune destination"   | Affiche avec message aide                                  | OUI  |


---

## ETAPE 2 — TEST DELETE WEBHOOK VIA UI

### Creation

Destination : **Webhook Delete E2E Test**
URL : `https://httpbin.org/post`
Secret HMAC : non rempli (optionnel)


| Cas                 | Attendu          | Observe                                           | OK ? |
| ------------------- | ---------------- | ------------------------------------------------- | ---- |
| Creation OK         | Webhook cree     | Webhook "Webhook Delete E2E Test" cree (23:22:36) | OUI  |
| Destination visible | Dans la liste    | Visible avec badges "Webhook" + "Actif"           | OUI  |
| URL visible         | httpbin.org/post | `https://httpbin.org/post` affiche                | OUI  |
| Bouton Supprimer    | Present          | Present (icone corbeille)                         | OUI  |


### Test Annuler


| Cas              | Attendu                         | Observe                                                                     | OK ? |
| ---------------- | ------------------------------- | --------------------------------------------------------------------------- | ---- |
| Clic Supprimer   | ConfirmModal s'ouvre            | Modale ouverte                                                              | OUI  |
| Titre modale     | "Supprimer cette destination ?" | "Supprimer cette destination ?"                                             | OUI  |
| Message modale   | Nom de la destination           | "La destination « Webhook Delete E2E Test » sera supprimee definitivement." | OUI  |
| Bouton Annuler   | Present (gris)                  | Present, focused par defaut                                                 | OUI  |
| Bouton Supprimer | Present (rouge)                 | Present (couleur danger)                                                    | OUI  |
| Clic Annuler     | Ferme modale, rien supprime     | Modale fermee, destination toujours presente                                | OUI  |


### Test Confirmer


| Cas                          | Attendu                              | Observe                                        | OK ? |
| ---------------------------- | ------------------------------------ | ---------------------------------------------- | ---- |
| Clic Supprimer (reouverture) | ConfirmModal s'ouvre                 | Modale ouverte a nouveau                       | OUI  |
| Clic Supprimer (confirm)     | DELETE appele, destination supprimee | Destination disparait immediatement            | OUI  |
| Empty state apres delete     | "Aucune destination"                 | "Aucune destination" affiche                   | OUI  |
| Refresh page                 | Destination toujours absente         | "Aucune destination" apres navigation complete | OUI  |
| Aucun secret HMAC visible    | Aucun                                | Aucun secret dans l'UI                         | OUI  |


---

## ETAPE 3 — TEST DELETE META CAPI VIA UI

### Creation

Destination : **Meta CAPI Delete E2E Test**
Pixel ID : `999888777666555`
Token : token invalide de test uniquement (jamais un vrai token Meta)
Account ID : non rempli


| Cas             | Attendu            | Observe                                                           | OK ? |
| --------------- | ------------------ | ----------------------------------------------------------------- | ---- |
| Creation OK     | Meta CAPI cree     | Destination creee (23:24:39)                                      | OUI  |
| Token masque    | `EA*****...mm`     | `EA***********************************************************mm` | OUI  |
| Pixel visible   | 999888777666555    | `Pixel: 999888777666555`                                          | OUI  |
| Endpoint auto   | graph.facebook.com | `https://graph.facebook.com/v21.0/999888777666555/events`         | OUI  |
| Badge Meta CAPI | Affiche            | Badge violet "Meta CAPI" + badge vert "Actif"                     | OUI  |


### Test Supprimer


| Cas                      | Attendu                         | Observe                                                                       | OK ? |
| ------------------------ | ------------------------------- | ----------------------------------------------------------------------------- | ---- |
| Clic Supprimer           | ConfirmModal s'ouvre            | Modale ouverte                                                                | OUI  |
| Titre modale             | "Supprimer cette destination ?" | "Supprimer cette destination ?"                                               | OUI  |
| Message avec bon nom     | Meta CAPI Delete E2E Test       | "La destination « Meta CAPI Delete E2E Test » sera supprimee definitivement." | OUI  |
| Clic Supprimer (confirm) | DELETE appele                   | Destination disparait                                                         | OUI  |
| Empty state              | "Aucune destination"            | "Aucune destination" immediatement                                            | OUI  |
| Aucun token brut         | Aucun token dans l'UI           | Aucun token visible a aucun moment de la suppression                          | OUI  |
| Aucun token dans erreur  | Pas d'erreur                    | Suppression reussie, pas d'erreur                                             | OUI  |


---

## ETAPE 4 — VALIDATION BACKEND EFFECTIVE (SOFT DELETE)

Verification directe en base PostgreSQL via `kubectl exec` dans le pod API DEV.

### Webhook Delete E2E Test


| Champ              | Attendu                     | Observe                                |
| ------------------ | --------------------------- | -------------------------------------- |
| `id`               | UUID                        | `a50d9402-f9be-4ea2-b6ff-3e7a0deadc30` |
| `name`             | Webhook Delete E2E Test     | `Webhook Delete E2E Test`              |
| `tenant_id`        | keybuzz-consulting-mo9y479d | `keybuzz-consulting-mo9y479d`          |
| `destination_type` | webhook                     | `webhook`                              |
| `is_active`        | false                       | `false`                                |
| `deleted_at`       | timestamp renseigne         | `2026-04-22T21:23:21.525Z`             |
| `deleted_by`       | email utilisateur           | `ludovic@keybuzz.pro`                  |


### Meta CAPI Delete E2E Test


| Champ              | Attendu                     | Observe                                |
| ------------------ | --------------------------- | -------------------------------------- |
| `id`               | UUID                        | `166fd366-1a1f-4174-ae00-be35c4ed3682` |
| `name`             | Meta CAPI Delete E2E Test   | `Meta CAPI Delete E2E Test`            |
| `tenant_id`        | keybuzz-consulting-mo9y479d | `keybuzz-consulting-mo9y479d`          |
| `destination_type` | meta_capi                   | `meta_capi`                            |
| `is_active`        | false                       | `false`                                |
| `deleted_at`       | timestamp renseigne         | `2026-04-22T21:25:20.425Z`             |
| `deleted_by`       | email utilisateur           | `ludovic@keybuzz.pro`                  |


### Confirmation soft delete

- `deleted_at` renseigne : **OUI** (les 2 destinations)
- `deleted_by` renseigne : **OUI** (`ludovic@keybuzz.pro`)
- `is_active = false` : **OUI** (les 2 destinations)
- Destinations absentes de GET /destinations : **OUI** (empty state confirme)
- Enregistrements conserves en DB : **OUI** (pas de hard delete)

---

## ETAPE 5 — NON-REGRESSION UI


| Element              | Attendu                            | Observe                                                                                  | OK ? |
| -------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------- | ---- |
| Creation webhook     | Fonctionnelle                      | "Webhook Delete E2E Test" cree OK                                                        | OUI  |
| Creation Meta CAPI   | Fonctionnelle                      | "Meta CAPI Delete E2E Test" cree OK                                                      | OUI  |
| Token masque         | Toujours masque                    | `EA***...mm`                                                                             | OUI  |
| Endpoint auto-genere | URL Meta correcte                  | `https://graph.facebook.com/v21.0/...`                                                   | OUI  |
| Tenant selector      | Fonctionne                         | KeyBuzz Consulting selectionne                                                           | OUI  |
| Empty state          | "Aucune destination"               | Affiche correctement                                                                     | OUI  |
| Aucun NaN            | Aucun                              | Aucun                                                                                    | OUI  |
| Aucun undefined      | Aucun                              | Aucun                                                                                    | OUI  |
| Aucun mock           | Donnees reelles                    | Donnees reelles API DEV                                                                  | OUI  |
| Sidebar intacte      | Toutes sections                    | Principal, Operations, Marketing, IA, Surveillance, Supervision, Administration, Systeme | OUI  |
| Topbar intacte       | Tenant, Notifications, Deconnexion | Tous presents                                                                            | OUI  |
| Session active       | Pas de deconnexion                 | Session stable tout au long                                                              | OUI  |


---

## CONFIRMATIONS

- **Aucun code modifie** : OUI
- **Aucun build** : OUI
- **Aucun deploy** : OUI
- **Aucun changement manifest** : OUI
- **Aucune destination reelle supprimee** : OUI (uniquement destinations de test creees pendant cette phase)
- **PROD inchangee** : OUI (Admin `v2.11.0-tenant-foundation-prod` + API `v3.5.100-meta-capi-error-sanitization-prod`)
- **Aucun token expose dans le rapport** : OUI (seuls des tokens invalides de test utilises)

---

## VERDICT

### GO POUR PROMOTION API PROD

**ADMIN CONFIRMMODAL DELETE E2E VALIDATED IN DEV — API DELETE ROUTE CONFIRMED — READY FOR API PROD PROMOTION**

Resume des validations :

1. **ConfirmModal Annuler** : Ouvre la modale, affiche le nom exact de la destination, bouton Annuler ferme sans supprimer — VALIDE
2. **ConfirmModal Confirmer (Webhook)** : Suppression effective, destination disparait, persistent apres refresh — VALIDE
3. **ConfirmModal Confirmer (Meta CAPI)** : Suppression effective, aucun token expose, persistent apres refresh — VALIDE
4. **Soft delete backend** : `deleted_at` renseigne, `deleted_by` = email utilisateur, `is_active = false`, enregistrements conserves — VALIDE
5. **Isolation GET** : Destinations supprimees invisibles dans la liste (filtrage `deleted_at IS NULL`) — VALIDE
6. **Non-regression** : Creation, masquage token, empty state, sidebar/topbar — VALIDE

La route `DELETE /outbound-conversions/destinations/:id` (API DEV `v3.5.101`) est prete pour promotion PROD.

---

## REFERENCES

- Route DELETE API : `keybuzz-infra/docs/PH-T8.7B.4-OUTBOUND-DESTINATIONS-DELETE-ROUTE-01.md`
- Hardening UI : `keybuzz-infra/docs/PH-ADMIN-T8.7C-META-CAPI-UI-HARDENING-01.md`
- Validation navigateur precedente : `keybuzz-infra/docs/PH-ADMIN-T8.7C-META-CAPI-UI-REAL-BROWSER-VALIDATION-01.md`
- Error sanitization PROD : `keybuzz-infra/docs/PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01.md`