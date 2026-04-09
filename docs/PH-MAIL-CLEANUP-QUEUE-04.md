# PH-MAIL-CLEANUP-QUEUE-04 — Nettoyage Queue Postfix

> Date : 4 avril 2026
> Serveur : mail-core-01
> Modifications : suppression queue deferred uniquement

---

## RESULTAT

| Action | Statut |
|---|---|
| Queue nettoyee | **59 emails supprimes** |
| Queue apres | **Mail queue is empty** |
| Postfix | Running (PID 755403) |
| Amazon inbound | **NON TOUCHE** (0 email Amazon dans la queue) |
| Webhook | Intact (md5 inchange) |
| Config Postfix | Inchangee |

---

## AVANT

```
741 Kbytes in 59 Requests
  alerts@keybuzz.io : 89 occurrences
  sre@keybuzz.io    : 58 occurrences
  Amazon inbound    : 0
```

## SUPPRESSION

```
postsuper: Deleted: 59 messages
```

## APRES

```
Mail queue is empty
Deferred : 0
Active   : 0
```

---

## NON-REGRESSION

| Element | Valeur | Statut |
|---|---|---|
| Webhook script | md5: `7eaeefa41a91...` | **Inchange** |
| `transport_maps` | `hash:/etc/postfix/transport` | **Inchange** |
| `relay_domains` | `inbound.keybuzz.io` | **Inchange** |
| `mydestination` | `localhost` | **Inchange** |
| `myorigin` | `keybuzz.io` | **Inchange** (fix F3) |
| TLS cert | Let's Encrypt `mail.keybuzz.io` | **Inchange** (fix F1) |
| Postfix | active, running | **OK** |
| Email test | Envoye a `ludovic@keybuzz.pro` | **OK** |
