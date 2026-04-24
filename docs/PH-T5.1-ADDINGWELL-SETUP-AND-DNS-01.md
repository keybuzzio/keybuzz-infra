# PH-T5.1-ADDINGWELL-SETUP-AND-DNS-01 — TERMINÉ

> Date : 2026-04-17 (mis à jour 2026-04-17)
> Type : setup externe (Addingwell) + préparation DNS
> Aucune modification code/infra effectuée

---

## Verdict : ADDINGWELL INFRA READY — 2 domaines configurés

---

## 1. Compte Addingwell


| Paramètre      | Valeur                                                          |
| -------------- | --------------------------------------------------------------- |
| URL            | `https://app.addingwell.com`                                    |
| Email          | `ludovic@keybuzz.pro`                                           |
| Auth           | email + mot de passe                                            |
| Méthode signup | Google OAuth (`keybuzz.pro@gmail.com`) puis mot de passe ajouté |


---

## 2. Container sGTM


| Paramètre        | Valeur                                                                         |
| ---------------- | ------------------------------------------------------------------------------ |
| Container name   | `KeyBuzz`                                                                      |
| Container ID     | `GTM-NTPDQ7N7`                                                                 |
| Container config | `aWQ9R1RNLU5UUERRN043JmVudj0yJmF1dGg9eTRhX0VDQWczSzFpbFdqZFllVXFzZw==`         |
| Timezone         | `Europe/Paris`                                                                 |
| Plan             | **Pay as you Go** (2M requests/mois — ~107€/mois)                              |
| Région           | Europe                                                                         |
| URL admin        | `https://app.addingwell.com/containers/keybuzz/tagging-server/getting-started` |


---

## 3. Custom Domains

### 3.1 Domaine 1 : `t.keybuzz.pro` — ACTIF


| Paramètre         | Valeur          |
| ----------------- | --------------- |
| Domain            | `keybuzz.pro`   |
| Subdomain         | `t`             |
| FQDN              | `t.keybuzz.pro` |
| Statut Addingwell | **Active**      |
| Créé le           | 17 avril 2026   |
| Validé le         | 17 avril 2026   |
| Rôle              | Primary domain  |


### 3.2 Domaine 2 : `t.keybuzz.io` — ACTIF


| Paramètre         | Valeur         |
| ----------------- | -------------- |
| Domain            | `keybuzz.io`   |
| Subdomain         | `t`            |
| FQDN              | `t.keybuzz.io` |
| Statut Addingwell | **Active**     |
| Créé le           | 17 avril 2026  |
| Validé le         | 17 avril 2026  |


---

## 4. Configuration DNS requise

### 4.1 DNS pour `t.keybuzz.pro` (fourni par Addingwell)


| Record Type | Host            | Value                | Obligatoire                         |
| ----------- | --------------- | -------------------- | ----------------------------------- |
| **A**       | `t.keybuzz.pro` | `34.120.158.38`      | OUI                                 |
| **AAAA**    | `t.keybuzz.pro` | `2600:1901:0:bba6::` | Recommandé (améliore Facebook CAPI) |


### 4.2 DNS pour `t.keybuzz.io` (fourni par Addingwell)


| Record Type | Host           | Value                | Obligatoire                         |
| ----------- | -------------- | -------------------- | ----------------------------------- |
| **A**       | `t.keybuzz.io` | `34.120.158.38`      | OUI                                 |
| **AAAA**    | `t.keybuzz.io` | `2600:1901:0:bba6::` | Recommandé (améliore Facebook CAPI) |


### 4.3 Où configurer le DNS


| Domaine       | Registrar / DNS Provider            | Action                                |
| ------------- | ----------------------------------- | ------------------------------------- |
| `keybuzz.pro` | Hetzner DNS ou registrar du domaine | Ajouter A + AAAA pour `t.keybuzz.pro` |
| `keybuzz.io`  | Hetzner DNS ou registrar du domaine | Ajouter A + AAAA pour `t.keybuzz.io`  |


**ATTENTION** : Ne PAS appliquer les DNS sans validation humaine. Addingwell vérifiera automatiquement la propagation DNS (5 min à 1h).

---

## 5. Statut actuel


| Élément                           | État                  | Détail                            |
| --------------------------------- | --------------------- | --------------------------------- |
| Compte Addingwell                 | CRÉÉ                  | `ludovic@keybuzz.pro`, connecté   |
| Workspace                         | CRÉÉ                  | `KeyBuzz`                         |
| Container sGTM                    | CRÉÉ                  | `GTM-NTPDQ7N7`                    |
| Container config                  | PRÉ-REMPLI            | Base64 config prête               |
| Plan                              | **Pay as you Go**     | 2M requests/mois — ~107€/mois     |
| Custom domain 1 (`t.keybuzz.pro`) | **ACTIF**             | DNS appliqué + validé 17/04/2026  |
| Custom domain 2 (`t.keybuzz.io`)  | **ACTIF**             | DNS appliqué + validé 17/04/2026  |
| DNS `t.keybuzz.pro`               | **APPLIQUÉ + VALIDÉ** | Active depuis 17/04/2026          |
| DNS `t.keybuzz.io`                | **APPLIQUÉ + VALIDÉ** | Active depuis 17/04/2026          |
| Région                            | europe-west10         | Berlin, Germany, Europe (Low CO2) |
| SLA                               | 100% uptime           | Avril 2026                        |


---

## 6. Prochaines actions

### Toutes les actions sont complétées

1. ~~Appliquer DNS `t.keybuzz.pro`~~ — FAIT, statut **Active**
2. ~~Upgrade vers Pay-as-you-go~~ — FAIT, plan actif (~107€/mois)
3. ~~Ajouter custom domain `t.keybuzz.io`~~ — FAIT
4. ~~Appliquer DNS `t.keybuzz.io`~~ — FAIT, statut **Active**
5. **PH-T5.2 peut commencer** — configuration des tags sGTM

---

## 7. Notes techniques

### Container config (base64)

La valeur `aWQ9R1RNLU5UUERRN043JmVudj0yJmF1dGg9eTRhX0VDQWczSzFpbFdqZFllVXFzZw==` est la configuration du container sGTM. Cette valeur est normalement récupérée depuis Google Tag Manager lors de la création d'un server container. Addingwell l'a pré-remplie lors de l'onboarding.

### Plan Sandbox vs Pay-as-you-go


| Feature              | Sandbox (Free) | Pay-as-you-go              |
| -------------------- | -------------- | -------------------------- |
| Requests             | 100K/mois      | 2M/mois                    |
| Custom domains       | 1              | 1 inclus + 10€/additionnel |
| Infrastructure       | Single-region  | Multi-region               |
| Tag monitoring       | Non            | Oui                        |
| Support              | Email 5j       | Email 2j                   |
| SDK JS proxification | Non            | Oui                        |
| Logs                 | Non            | Oui                        |


Le plan Sandbox est suffisant pour tester avec `t.keybuzz.pro` uniquement. L'upgrade sera nécessaire avant la mise en production.

### IP Addingwell

L'IP `34.120.158.38` est une IP Google Cloud (GCP) utilisée par Addingwell pour héberger les containers sGTM. L'enregistrement AAAA `2600:1901:0:bba6::` est la version IPv6 correspondante.

---

## 8. Conclusion

**ADDINGWELL INFRA READY** — 2 domaines configurés


| Composant                     | État                              |
| ----------------------------- | --------------------------------- |
| Compte Addingwell             | CRÉÉ (`ludovic@keybuzz.pro`)      |
| Plan                          | **Pay as you Go** (~107€/mois)    |
| Container sGTM `GTM-NTPDQ7N7` | CRÉÉ (Europe — Berlin)            |
| Custom domain `t.keybuzz.pro` | **ACTIF** — DNS appliqué + validé |
| Custom domain `t.keybuzz.io`  | **ACTIF** — DNS appliqué + validé |
| DNS `t.keybuzz.pro`           | APPLIQUÉ + VALIDÉ                 |
| DNS `t.keybuzz.io`            | APPLIQUÉ + VALIDÉ                 |


**PH-T5.1 est 100% terminé.** Prochaine étape : PH-T5.2 (configuration des tags sGTM dans le container Addingwell).