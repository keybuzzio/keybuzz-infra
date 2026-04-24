# PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01

> Date : 2026-04-21
> Type : Activation temporaire webhook.site en PROD
> Priorité : ÉLEVÉE
> Environnement : PROD
> Statut : **ACTIF — EN ATTENTE DE TEST EXTERNE**

---

## 1. OBJECTIF

Activer temporairement une destination webhook.site en PROD pour valider de bout en bout
la réception des événements outbound conversions (StartTrial, Purchase) par un endpoint
externe réel.

---

## 2. PRÉFLIGHT

| Élément | Valeur |
|---|---|
| Branche infra | `main` |
| HEAD avant | `3e4ada8` |
| Repo | Clean |
| Image PROD API | `v3.5.94-outbound-conversions-real-value-prod` (inchangée) |
| `OUTBOUND_CONVERSIONS_WEBHOOK_URL` avant | `""` (vide) |
| `OUTBOUND_CONVERSIONS_WEBHOOK_SECRET` avant | `""` (vide) |

---

## 3. MODIFICATION

### Manifest modifié

`keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`

### Diff exact

```diff
             - name: OUTBOUND_CONVERSIONS_WEBHOOK_URL
-              value: ""
+              value: "https://webhook.site/a6e85482-1ec8-4709-9bd3-ad484c2255f4"  # PH-T8.5.1 TEMPORARY TEST

             - name: OUTBOUND_CONVERSIONS_WEBHOOK_SECRET
-              value: ""
+              value: "k4Ay459iJ6cTTe"  # PH-T8.5.1 TEMPORARY TEST
```

### Ce qui n'a PAS été modifié

- Image API : inchangée (`v3.5.94-outbound-conversions-real-value-prod`)
- Code source : aucune modification
- DEV : aucune modification
- Client SaaS : aucune modification
- Admin : aucune modification
- Tracking / metrics / autopilot / billing : aucune modification

---

## 4. COMMIT INFRA

| Élément | Valeur |
|---|---|
| Commit | `001c63d` |
| Message | `PH-T8.5.1: temporary webhook.site outbound conversions test in PROD` |
| Push | `main → origin/main` |

---

## 5. DEPLOY

| Élément | Valeur |
|---|---|
| Méthode | `kubectl apply -f` (GitOps) |
| Rollout | `deployment "keybuzz-api" successfully rolled out` |
| Pod | `keybuzz-api-659846bf74-p9dcq` |
| Restarts | 0 |
| Health | `{"status":"ok"}` |

---

## 6. VALIDATION TECHNIQUE

| Check | Résultat |
|---|---|
| Health API | ✅ HTTP 200 |
| Billing module | ✅ chargé |
| Metrics module | ✅ chargé |
| Pod restarts | ✅ 0 |
| Env URL présente | ✅ `https://webhook.site/a6e85482-1ec8-4709-9bd3-ad484c2255f4` |
| Env secret présent | ✅ 15 caractères |

---

## 7. ÉTAT ACTUEL

Le module outbound conversions PROD est maintenant configuré pour envoyer les événements
StartTrial et Purchase vers webhook.site.

**Le prochain vrai trial ou paiement Stripe déclenchera un webhook visible sur :**

`https://webhook.site/#!/a6e85482-1ec8-4709-9bd3-ad484c2255f4`

---

## 8. ROLLBACK

### Procédure

Quand Ludovic confirme la fin du test, exécuter le rollback GitOps suivant :

**1. Modifier le manifest :**

```yaml
            - name: OUTBOUND_CONVERSIONS_WEBHOOK_URL
              value: ""
            - name: OUTBOUND_CONVERSIONS_WEBHOOK_SECRET
              value: ""
```

**2. Commit + push :**

```bash
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-api-prod/deployment.yaml
git commit -m "PH-T8.5.1: rollback webhook.site test — disable outbound conversions destination"
git push origin main
```

**3. Apply :**

```bash
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod --timeout=120s
```

### Diff rollback attendu

```diff
             - name: OUTBOUND_CONVERSIONS_WEBHOOK_URL
-              value: "https://webhook.site/a6e85482-1ec8-4709-9bd3-ad484c2255f4"  # PH-T8.5.1 TEMPORARY TEST
+              value: ""

             - name: OUTBOUND_CONVERSIONS_WEBHOOK_SECRET
-              value: "k4Ay459iJ6cTTe"  # PH-T8.5.1 TEMPORARY TEST
+              value: ""
```

---

## VERDICT

**WEBHOOK.SITE PROD TEST ACTIVATED — TEMPORARY — GITOPS SAFE — ROLLBACK READY**
