# Contrat Tracking LP Externes — Media Buyers & Agences

> Version : 1.0
> Date : 2026-05-09
> Ticket : KEY-285 / KEY-284
> Phase : PH-WEBSITE-T8.12AQ.4.1

---

## Règle fondamentale

**Le pixel Meta seul ne suffit pas pour l'attribution KeyBuzz complète.** Il peut rester pour le retargeting Meta, mais les liens CTA doivent obligatoirement transmettre les paramètres KeyBuzz.

Le vrai mécanisme d'attribution est le **contrat URL des CTA**, pas le pixel.

---

## 1. CTA obligatoire — Template register direct

```
https://client.keybuzz.io/register?plan={PLAN}&cycle={CYCLE}&utm_source={SOURCE}&utm_medium={MEDIUM}&utm_campaign={CAMPAIGN}&utm_content={CONTENT}&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

### Paramètres obligatoires

| Paramètre | Obligatoire | Valeurs | Exemple |
|---|---|---|---|
| `plan` | OUI | `starter`, `pro`, `autopilot` | `autopilot` |
| `cycle` | OUI | `monthly`, `yearly` | `monthly` |
| `utm_source` | OUI | `meta`, `google`, `tiktok`, `linkedin` | `meta` |
| `utm_medium` | OUI | `cpc`, `cpm`, `social`, `display`, `video` | `cpc` |
| `utm_campaign` | OUI | Convention : `{actor}-{nom}` | `mb-meta-lead-fr-q2` |
| `utm_content` | RECOMMANDÉ | Identifiant créa/variante | `hero-v2-cta-blue` |
| `marketing_owner_tenant_id` | RECOMMANDÉ | ID tenant marketing owner | `keybuzz-consulting-mo9zndlk` |

### Paramètres optionnels

| Paramètre | Usage | Exemple |
|---|---|---|
| `utm_term` | Mot-clé ciblé | `sav-marketplace` |
| `promo` | Code promo Stripe | `LAUNCH50` |
| `_gl` | GA4 cross-domain linker | Ajouté automatiquement si GA4 est sur la LP |

### Paramètres automatiques (ajoutés par les plateformes)

| Paramètre | Plateforme | Action media buyer |
|---|---|---|
| `gclid` | Google Ads | Ne rien faire, auto-tag |
| `fbclid` | Meta Ads | Ne rien faire, auto-tag |
| `ttclid` | TikTok Ads | Ne rien faire, auto-tag |
| `li_fat_id` | LinkedIn Ads | Ne rien faire, auto-tag |

---

## 2. CTA alternatif — Via pricing

```
https://www.keybuzz.pro/pricing?utm_source={SOURCE}&utm_medium={MEDIUM}&utm_campaign={CAMPAIGN}&utm_content={CONTENT}&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

La page `/pricing` forward automatiquement tous les UTM et click IDs vers le formulaire d'inscription.

---

## 3. Forwarding click IDs sur les LP externes (Webflow)

Les plateformes publicitaires ajoutent automatiquement un click ID à l'URL de la LP (`fbclid`, `gclid`, etc.). Pour que ce click ID arrive jusqu'au `/register`, la LP doit **forwarder les paramètres URL dans les liens CTA**.

### Script Webflow recommandé

Ajouter dans les Custom Code de la page Webflow (avant `</body>`) :

```html
<script>
(function() {
  var params = window.location.search;
  if (!params) return;
  document.querySelectorAll('a[href*="client.keybuzz.io"], a[href*="keybuzz.pro"]').forEach(function(a) {
    var href = a.getAttribute('href');
    if (!href) return;
    var sep = href.indexOf('?') >= 0 ? '&' : '?';
    a.setAttribute('href', href + sep + params.substring(1));
  });
})();
</script>
```

Ce script :
- Détecte les paramètres URL actuels (UTM + click IDs ajoutés par la plateforme)
- Les ajoute aux liens CTA qui pointent vers `client.keybuzz.io` ou `keybuzz.pro`
- Fonctionne automatiquement, pas besoin de mise à jour pour chaque campagne

---

## 4. Pixels autorisés sur LP externe

| Pixel | Autorisé | Condition |
|---|---|---|
| Meta Pixel (PageView, ViewContent) | OUI | Pixel du compte publicitaire |
| TikTok Pixel (PageView, ViewContent) | OUI | ID pixel du compte TikTok |
| Google tag (gtag pageview) | OUI | ID Google du compte Google Ads |
| LinkedIn Insight Tag (pageview) | OUI | Partner ID du compte LinkedIn |

---

## 5. Events INTERDITS sur LP externe

| Event | Interdit | Raison |
|---|---|---|
| `Purchase` | OUI | Server-side only, déclenché par l'API après paiement réel |
| `CompletePayment` | OUI | Server-side only, déclenché par l'API après paiement réel |
| `Lead` avec données fictives | OUI | Fausse conversion |
| `InitiateCheckout` avec montant fictif | OUI | Fausse conversion |
| `Subscribe` | OUI | Server-side only |
| Tout event de conversion avec données inventées | OUI | Pollution du funnel |

### Events AUTORISÉS sur LP externe

| Event | Autorisé | Quand |
|---|---|---|
| `PageView` | OUI | Chargement de la LP |
| `ViewContent` | OUI | Scroll ou engagement |
| Custom event engagement (ex: `ButtonClick`) | OUI | Clic CTA (pour audiences) |

---

## 6. Checklist avant mise en ligne

- [ ] La page charge correctement
- [ ] Les CTA pointent vers `client.keybuzz.io/register?plan=...&cycle=...&utm_source=...`
- [ ] OU vers `www.keybuzz.pro/pricing?utm_source=...`
- [ ] Les paramètres UTM sont présents dans les CTA
- [ ] `marketing_owner_tenant_id` est présent
- [ ] Le script de forwarding click IDs est installé (si LP Webflow)
- [ ] Aucun event Purchase/CompletePayment/Lead fictif
- [ ] Aucun lien vers `client-dev.keybuzz.io` ou `api-dev.keybuzz.io`
- [ ] Aucun paramètre supprimé des CTA
- [ ] URL testée dans Campaign QA > Event Lab

---

## 7. Convention nommage campagnes

Format : `{actor}-{nom-campagne}`

| Acteur | Préfixe | Usage |
|---|---|---|
| Media buyer freelance | `mb-` | `mb-meta-lead-fr-q2` |
| Agence partenaire | `ag-` | `ag-google-retarget-fr-q2` |
| Interne KeyBuzz | `kb-` | `kb-linkedin-awareness-fr-q2` |

---

## 8. Domaines LP autorisés

Campaign QA accepte automatiquement :
- `*.keybuzz.io` (tout sous-domaine)
- `*.keybuzz.pro` (tout sous-domaine)

Domaines externes rejetés. Pas besoin d'intervention pour ajouter un nouveau sous-domaine.

---

## 9. Autonomie media buyer

| Action | Autonome ? | Condition |
|---|---|---|
| Créer une nouvelle LP | OUI | Respecter contrat URL CTA |
| Créer une nouvelle variation créa | OUI | Utiliser `utm_content` différent |
| Changer le copywriting / design | OUI | Ne pas modifier les URLs CTA |
| Ajouter un pixel (Meta, TikTok, Google, LinkedIn) | OUI | PageView/ViewContent uniquement |
| Modifier les CTA | OUI | Garder TOUS les params obligatoires |
| Ajouter une promo | OUI | `&promo=CODE` dans l'URL |
| Lancer une campagne | OUI | URLs conformes |
| Créer un nouveau sous-domaine keybuzz.io | OUI | DNS + CTA conformes |

### Config unique initiale (1 fois, par KeyBuzz)

- Création du `marketing_owner_tenant_id`
- Création des codes promo Stripe (si applicable)

### Interdit

- Modifier l'URL du CTA pour supprimer des paramètres
- Déclencher des events Purchase/CompletePayment/Subscribe
- Hardcoder des click IDs manuellement
- Créer un formulaire d'inscription sur la LP (bypass du register)

---

## 10. Directives Antoine — prêt à copier-coller

### Ce que tu dois installer sur ta LP

- Ton Meta Pixel (le nôtre est déjà sur keybuzz.pro, pas besoin de le dupliquer)
- Tu peux ajouter ton TikTok Pixel, Google tag, LinkedIn tag si tu fais du multi-canal
- Events autorisés : PageView, ViewContent uniquement
- Le script de forwarding ci-dessous (dans Custom Code Webflow, avant `</body>`) :

```html
<script>
(function() {
  var params = window.location.search;
  if (!params) return;
  document.querySelectorAll('a[href*="client.keybuzz.io"], a[href*="keybuzz.pro"]').forEach(function(a) {
    var href = a.getAttribute('href');
    if (!href) return;
    var sep = href.indexOf('?') >= 0 ? '&' : '?';
    a.setAttribute('href', href + sep + params.substring(1));
  });
})();
</script>
```

### Ce que tu ne dois PAS installer

- Aucun event Purchase, CompletePayment, ou Lead avec données fictives
- Pas de formulaire d'inscription sur la LP

### Comment construire les liens CTA

Tous tes boutons CTA doivent pointer vers :

```
https://client.keybuzz.io/register?plan=autopilot&cycle=monthly&utm_source=meta&utm_medium=cpc&utm_campaign=mb-meta-lead-fr-q2&utm_content=ta-variante&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

Remplace :
- `plan=autopilot` par le plan ciblé (`starter`, `pro`, ou `autopilot`)
- `cycle=monthly` par `yearly` si tu pousses l'annuel
- `utm_campaign=mb-meta-lead-fr-q2` par le vrai nom de ta campagne
- `utm_content=ta-variante` par l'identifiant de ta créa/variante

### Ce qu'il ne faut JAMAIS supprimer de l'URL

- `utm_source`, `utm_medium`, `utm_campaign` — c'est notre attribution
- `marketing_owner_tenant_id` — c'est le routing media buyer
- `plan` et `cycle` — c'est la pré-sélection du plan

### Les click IDs sont automatiques

Les `fbclid`, `gclid`, `ttclid`, `li_fat_id` sont ajoutés automatiquement par les plateformes publicitaires. Ne les ajoute JAMAIS manuellement. Le script de forwarding les transmet automatiquement vers le lien d'inscription.

### Si tu as un code promo

Ajoute `&promo=TON_CODE` à l'URL CTA.

### Comment tester avant mise en ligne

1. Ouvre ta LP dans un navigateur
2. Ajoute `?utm_source=meta&utm_medium=cpc&utm_campaign=mb-test&fbclid=test123` à l'URL
3. Clique sur le CTA
4. Vérifie que l'URL de destination contient bien TOUS les paramètres (utm_source, utm_medium, utm_campaign, fbclid, plan, cycle, marketing_owner_tenant_id)
5. Envoie l'URL à Ludovic pour vérification dans Campaign QA

### Exemple CTA correct

```
https://client.keybuzz.io/register?plan=autopilot&cycle=monthly&utm_source=meta&utm_medium=cpc&utm_campaign=mb-meta-lead-fr-q2&utm_content=hero-v2&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk
```

### Exemple CTA incorrect

```
https://www.keybuzz.pro/
```

(manque tous les paramètres, attribution perdue)

---

**Le pixel Meta seul ne suffit pas pour l'attribution KeyBuzz complète. Il peut rester pour le retargeting Meta, mais les liens CTA doivent obligatoirement transmettre les paramètres KeyBuzz.**
