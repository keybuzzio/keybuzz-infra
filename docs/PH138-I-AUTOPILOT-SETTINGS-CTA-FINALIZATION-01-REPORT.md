# PH138-I — Autopilot Settings CTA Finalization

> Date : 2026-04-01
> Statut : **DEV + PROD VALIDE**
> Auteur : Agent Cursor

---

## 1. Objectif

Finaliser la page Parametres IA pour que tous les CTA soient reellement cliquables, chaque carte verrouillee mene au bon flow, et l'UI soit coherente apres upgrade/addon.

## 2. Audit CTA complet

### Tous les elements interactifs audites

| Zone | Element | Visible | Cliquable avant | Cliquable apres | Handler |
|------|---------|---------|-----------------|-----------------|---------|
| Mode Suggestions | Carte | Oui | Oui | Oui | `save({mode:'off'})` |
| Mode Supervise | Carte | Oui | Oui (PRO+) | Oui (PRO+) | `save({mode:'supervised'})` |
| Mode Supervise | CTA "Passer au Pro" | Oui | **NON** | **OUI** | `upgradePlan('PRO')` |
| Mode Autonome | Carte | Oui | Non (lock) | Non (lock) | - |
| Mode Autonome | CTA "Passer au plan Autopilot" | Oui (PRO) | **NON** | **OUI** | `upgradePlan('AUTOPILOT')` |
| Escalade Votre equipe | Carte | Oui | Oui | Oui | `save({escalation_target:'client'})` |
| Escalade KeyBuzz | Carte | Oui | Non (addon) | Non (addon) | - |
| Escalade KeyBuzz | CTA "Activer Agent KeyBuzz" | Oui (AUTOPILOT) | **NON** | **OUI** | `activateAddon()` |
| Escalade Les deux | CTA "Activer Agent KeyBuzz" | Oui (AUTOPILOT) | **NON** | **OUI** | `activateAddon()` |
| Auto reply | CTA "Passer au plan Autopilot" | Oui (PRO) | Oui (div) | Oui (div) | `upgradePlan('AUTOPILOT')` |
| Auto assign | Toggle | Oui | Oui (PRO+) | Oui (PRO+) | `save(...)` |
| Auto escalade | Toggle | Oui | Oui (PRO+) | Oui (PRO+) | `save(...)` |
| Banner STARTER | "Passer au Pro" | Oui (STARTER) | Oui | Oui | `upgradePlan('PRO')` |
| Banner STARTER | "Passer a Autopilot" | Oui (STARTER) | Oui | Oui | `upgradePlan('AUTOPILOT')` |
| Banner Addon | "Activer Agent KeyBuzz" | Oui (AUTOPILOT) | Oui | Oui | `activateAddon()` |
| Safe mode | Toggle | Oui | Oui | Oui | `save({safe_mode:...})` |
| Enable/Disable | Toggle | Oui | Oui | Oui | `save({is_enabled:...})` |

## 3. Bug identifie et corrige

### BUG A (CRITIQUE) : CTA non cliquables dans les cartes verrouilees

**Cause racine** : Les cartes Mode et Escalade utilisaient `<button disabled={locked}>`. En HTML, un `<button disabled>` bloque **TOUS** les evenements click, y compris sur les elements enfants. Les CTA `<span onClick={upgradePlan}>` et `<span onClick={activateAddon}>` a l'interieur etaient donc totalement inoperants.

**Impact** :
- PRO : impossible de cliquer "Passer au plan Autopilot" sur la carte Mode Autonome
- AUTOPILOT sans addon : impossible de cliquer "Activer Agent KeyBuzz" sur les cartes KeyBuzz/Les deux
- Les Auto Actions (div) n'etaient PAS affectees car elles n'utilisaient pas de `<button>`

**Correction** : Remplacement de `<button disabled={locked}>` par `<div role="button" tabIndex={locked ? -1 : 0}>` avec guard onClick :

```tsx
// AVANT (CTA enfants bloques)
<button disabled={locked || readonly || isSaving} onClick={...}>
  <span onClick={upgradePlan}>...</span>  // BLOQUE !
</button>

// APRES (CTA enfants cliquables)
<div role="button" tabIndex={locked ? -1 : 0} onClick={() => {
  if (locked || readonly || isSaving) return;
  save(...);
}}>
  <span onClick={(e) => { e.stopPropagation(); upgradePlan(); }}>...</span>  // FONCTIONNE
</div>
```

### Cleanup auto-mode useEffect

- Suppression variable `prevPlan` inutilisee
- Simplification `modeToSet = defaultMode` (etait `planChanged ? defaultMode : defaultMode`)

## 4. Tests DEV

### Images deployees
| Service | Image |
|---------|-------|
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.159-autopilot-settings-cta-final-dev` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.159-autopilot-settings-cta-final-prod` |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.157-real-stripe-upgrade-e2e-dev` (inchange) |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.157-real-stripe-upgrade-e2e-prod` (inchange) |

### Resultats DEV

| Test | Resultat |
|------|----------|
| Health API | ok |
| Client pages | Toutes 200 |
| billing/current (4 tenants Stripe + 1 exempt) | Corrects |
| PH138-C checkout enforcement | checkout_required |
| Settings tab=ai&stripe=success | 200 |
| API logs | Clean |

### Resultats PROD (2026-04-01)

| Test | Resultat |
|------|----------|
| Health API | ok |
| Client pages (login, settings, billing, inbox, dashboard, orders) | Toutes 200 |
| API logs | Clean |
| Pod keybuzz-client | Running 1/1 |

## 5. Non-regressions

| Composant | Statut |
|-----------|--------|
| PH138-G (Stripe E2E) | OK |
| PH138-H (source unique addon) | OK |
| PH138-C (checkout enforcement) | OK |
| Billing/current | OK |
| Inbox / Dashboard / Orders | OK |

## 6. Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.158-final-billing-ux-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.158-final-billing-ux-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

## 7. GitOps

| Fichier | Ancien tag | Nouveau tag |
|---------|-----------|-------------|
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.158-final-billing-ux-dev` | `v3.5.159-autopilot-settings-cta-final-dev` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.158-final-billing-ux-prod` | `v3.5.159-autopilot-settings-cta-final-prod` |

## 8. Fichier modifie

| Fichier (bastion) | Modifications |
|-------------------|---------------|
| `keybuzz-client/src/features/ai-ui/AutopilotSection.tsx` | Mode cards: `<button disabled>` -> `<div role="button">`, Escalation cards: idem, cleanup prevPlan, simplify modeToSet |
