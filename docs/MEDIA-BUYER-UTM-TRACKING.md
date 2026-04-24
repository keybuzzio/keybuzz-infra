# UTM Tracking — keybuzz.pro/pricing

## Comment ça marche

Le site vitrine est configuré pour forwarder automatiquement les paramètres UTM vers la page d'inscription.

Tu pointes tes pubs vers l'URL pricing avec tes UTM classiques. Quand le visiteur clique sur un bouton "Structurer mon support" ou "Passer au système", les UTM sont automatiquement ajoutés à l'URL de destination (la page d'inscription `client.keybuzz.io/register`).

## URL de destination pour tes pubs

```
https://www.keybuzz.pro/pricing?utm_source=XXX&utm_medium=XXX&utm_campaign=XXX&utm_term=XXX&utm_content=XXX
```

## Paramètres supportés

Tous optionnels — mets ceux dont tu as besoin.


| Paramètre      | Usage              | Exemple                        |
| -------------- | ------------------ | ------------------------------ |
| `utm_source`   | Source du trafic   | `meta`, `google`, `tiktok`     |
| `utm_medium`   | Type de média      | `cpc`, `social`, `email`       |
| `utm_campaign` | Nom de la campagne | `launch_q2`, `retargeting_pro` |
| `utm_term`     | Mot-clé            | `support_marketplace`          |
| `utm_content`  | Variante pub       | `video_a`, `carousel_b`        |


## Exemples concrets

**Meta Ads :**

```
https://www.keybuzz.pro/pricing?utm_source=meta&utm_medium=cpc&utm_campaign=launch_q2&utm_content=video_a
```

**Google Ads :**

```
https://www.keybuzz.pro/pricing?utm_source=google&utm_medium=cpc&utm_campaign=brand&utm_term=support+marketplace
```

**TikTok Ads :**

```
https://www.keybuzz.pro/pricing?utm_source=tiktok&utm_medium=cpc&utm_campaign=awareness
```

## Parcours visiteur

1. Le visiteur arrive sur `keybuzz.pro/pricing?utm_source=meta&utm_campaign=launch`
2. Il voit la page tarifs normalement (les UTM sont invisibles pour lui)
3. Il clique sur un plan (Starter, Pro ou Autopilot)
4. Il est redirigé vers `client.keybuzz.io/register?plan=pro&cycle=monthly&utm_source=meta&utm_campaign=launch`

Les UTM sont préservés dans l'URL d'inscription, donc récupérables côté analytics et dans les événements de conversion.

## Points importants

- **Toujours pointer vers `/pricing`** — c'est la seule page qui forwarde les UTM (c'est là où sont les boutons d'inscription)
- Si tu pointes vers la homepage (`keybuzz.pro`), les UTM ne seront **pas** forwardés (le visiteur devra cliquer sur "Tarifs" et les UTM seront perdus)
- Le plan **Enterprise** renvoie vers `/contact`, pas vers l'inscription — les UTM ne s'appliquent pas dessus
- **Sans UTM** dans l'URL, les boutons fonctionnent normalement comme avant
- Les 3 plans concernés : **Starter**, **Pro**, **Autopilot**

