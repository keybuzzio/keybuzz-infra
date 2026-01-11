# PH18-INVITES-EMAIL-DELIVERY-01 - Invitations envoyees via la stack mail existante (Postfix)

## Date: 2026-01-11

## Objectif
Faire en sorte que les invitations soient reellement envoyees par email via la stack Postfix existante et validee (DKIM 10/10).

---

## Probleme identifie

Le pod keybuzz-api n'avait **pas les variables SMTP configurees**, utilisant les valeurs par defaut (localhost) qui echouaient silencieusement.

### Variables SMTP manquantes:
- SMTP_HOST
- SMTP_PORT
- SMTP_SECURE
- SMTP_TLS_REJECT_UNAUTHORIZED
- SMTP_FROM

---

## Solution implementee

### 1. Ajout des variables SMTP au deployment keybuzz-api

\\\yaml
# PH18: SMTP config for email invites
- name: SMTP_HOST
  value: '49.13.35.167'
- name: SMTP_PORT
  value: '25'
- name: SMTP_SECURE
  value: 'false'
- name: SMTP_TLS_REJECT_UNAUTHORIZED
  value: 'false'
- name: SMTP_FROM
  value: 'noreply@keybuzz.io'
\\\

Fichier modifie: \keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml\

### 2. Build et Deploy de l'API v0.1.94

\\\
keybuzz-api:0.1.94
\\\

---

## Preuves E2E

### A) Logs Postfix - mail-core-01

#### Invitation 1: ludo.gonthier+invite@gmail.com
\\\
2026-01-11T20:18:04.084191+00:00 mail-core-01 postfix/smtp[1687015]: 2DE1F3EC81:
to=<ludo.gonthier+invite@gmail.com>,
relay=gmail-smtp-in.l.google.com[64.233.165.27]:25,
delay=0.93,
dsn=2.0.0,
status=sent (250 2.0.0 OK 1768162684 38308e7fff4ca-383032ab7adsi47572251fa.56 - gsmtp)
\\\

#### Invitation 2: ludo.gonthier+test2@gmail.com (via UI)
\\\
2026-01-11T20:19:24.401483+00:00 mail-core-01 postfix/smtp[1687015]: CB2483EC81:
to=<ludo.gonthier+test2@gmail.com>,
relay=gmail-smtp-in.l.google.com[64.233.165.27]:25,
delay=0.59,
dsn=2.0.0,
status=sent (250 2.0.0 OK 1768162764 38308e7fff4ca-382eee6e03dsi55412291fa.323 - gsmtp)
\\\

### B) Base de donnees - space_invites

\\\sql
id                                  | tenant_id  | email                           | role  | created_at                  | token_prefix
------------------------------------+------------+---------------------------------+-------+-----------------------------+--------------
9b35f820-cc4e-43b5-859e-e46915c2eebd | kbz-001    | ludo.gonthier+invite@gmail.com | agent | 2026-01-11 20:18:02.59996  | ebe180a4
\\\

### C) API Response

\\\json
{ success:true,message:Invitation sent,inviteId:ebe180a4}
\\\

---

## Configuration SMTP (sans secrets)

| Variable | Valeur |
|----------|--------|
| SMTP_HOST | 49.13.35.167 (mail-core-01) |
| SMTP_PORT | 25 |
| SMTP_SECURE | false |
| SMTP_TLS_REJECT_UNAUTHORIZED | false |
| SMTP_FROM | noreply@keybuzz.io |
| DKIM | Valide (configure cote Postfix) |

---

## Commits Git

### keybuzz-api
\\\
commit ca5728a
PH18-INVITES-EMAIL-DELIVERY-01: Bump to 0.1.94 with SMTP email invites working
\\\

### keybuzz-infra
\\\
commit 0ec6a1d
PH18-INVITES-EMAIL-DELIVERY-01: Add SMTP config to keybuzz-api deployment, bump to 0.1.94
\\\

---

## Resume

| Element | Statut |
|---------|--------|
| Variables SMTP dans deployment | OK |
| API v0.1.94 deployee | OK |
| Envoi via SMTP | OK |
| Logs Postfix status=sent | OK |
| Invitations en DB | OK |
| UI fonctionnelle | OK |

---

## Conclusion

Les invitations sont maintenant envoyees reellement par email via la stack Postfix existante et validee.
Les deux tests (curl et UI) ont confirme la reception par Gmail avec status=sent et dsn=2.0.0.
