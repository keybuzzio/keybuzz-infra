# PH15-MAIL-OPENDKIM-SETUP-01 â€” Rapport Final

**Date** : 2026-01-09
**Objectif** : Activer DKIM rÃ©el sur mail-core-01 pour KeyBuzz
**Statut** : TERMINE

## 1. Resume

| Element | Valeur |
|---------|--------|
| Serveur | mail-core-01 (49.13.35.167) |
| Domain | keybuzz.io |
| Selector | default |
| DNS Record | default._domainkey.keybuzz.io |
| Milter | inet:localhost:8891 |

## 2. Problemes identifies et corriges

### 2.1 Milters Postfix vides
Probleme : Les milters etaient configures mais vides
Solution : smtpd_milters = inet:localhost:8891

### 2.2 IP API non dans TrustedHosts
Solution : Ajout de 91.99.164.62

### 2.3 SigningTable sans refile:
Solution : SigningTable refile:/etc/opendkim/SigningTable

## 3. Preuves

### Test DKIM
opendkim-testkey: key OK

### Log signature
2026-01-09T03:02:37 opendkim: DKIM-Signature field added (s=default, d=keybuzz.io)

## 4. Conclusion

DKIM actif et fonctionnel sur mail-core-01.
Tous les emails @keybuzz.io sont signes avec selector default.
