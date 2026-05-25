# KEY-323-FIX-MAIL-SERVER-MAIL.KEYBUZZ.IO-PROD-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14 / PH-20.14A / KEY-231
> Phase : KEY-323-FIX-MAIL-SERVER-MAIL.KEYBUZZ.IO-PROD
> Environnement : PROD INFRA MAIL (read-only first ; aucune action corrective executee)

## 1. Verdict

GO FIX MAIL SERVER MAIL.KEYBUZZ.IO PROD BLOCKED KEY-323 : cause racine identifiee cote MX (mail-mx-01/02 refusent le relais depuis mail-core-01), hosts MX inaccessibles en SSH, fix hors perimetre minimal reversible.

Le service SMTP de mail-core-01 (49.13.35.167) est UP et fonctionne (postfix + dovecot + opendkim + rspamd actifs, smtpd ecoute sur 25/587). Le blocage du sortant n est PAS un service arrete/hung : mail-core-01 ne parvient pas a relayer vers les MX mail-mx-01.keybuzz.io (91.99.66.6) / mail-mx-02.keybuzz.io (91.99.87.76) qui repondent 421 4.7.0 "too many connections from 49.13.35.167" et 454 4.7.1 "Relay access denied". File d attente bloquee : 1873 messages / 4805 Ko ; 58249 deferred, 965 expired, 14 sent. Un restart de postfix mail-core-01 ne corrigerait rien et re-saturerait les MX. Le correctif requiert un acces config aux MX (rate-limit + relay access), indisponible (SSH mail-mx-01:22 timeout, alias non documente). Aucune action corrective tentee, conforme aux conditions STOP du prompt.

PH-20.13B push Client reste SUSPENDU.

## 2. Resume executif

- Architecture sortante : apps -> SMTP_HOST=mail.keybuzz.io = mail-core-01 (49.13.35.167) -> delivery directe via MX (relayhost vide, default_transport=smtp). Pour les destinataires @inbound.keybuzz.io (emails de validation self-test PH-20.14A) et au-dela, mail-core-01 livre vers les MX mail-mx-01/02.keybuzz.io.
- Les MX refusent les connexions de mail-core-01 :
  - 421 4.7.0 mail-mx-02.keybuzz.io "Error: too many connections from 49.13.35.167" (rate-limit / cap de connexions).
  - 454 4.7.1 "Relay access denied" sur RCPT TO (mail-core-01 / domaines non autorises a relayer cote MX).
- Consequence : 100 pourcent du sortant en status=deferred, file de 1873 messages, 58249 deferred / 965 expired / 14 sent seulement.
- L absence de banniere SMTP observee depuis le bastion s explique par postscreen (greet_wait 6s, action ignore) + smtpd en mode stress du a la saturation ; le service repond bien en interne (EHLO depuis 10.0.0.111 ok, commands=5).
- Cause racine probable : depuis la reinstallation/remplacement du serveur mail (cf AS.17.1B 2026-05-15, host key change), la configuration de relais cote MX (mynetworks / relay access pour 49.13.35.167 et le domaine inbound.keybuzz.io) et/ou les limites de connexion sont incorrectes, et la file accumulee cree une boucle de saturation.
- Acces : SSH mail-core-01 OK (alias documente, host key reconciliee). SSH MX mail-mx-01:22 = timeout -> hosts MX inaccessibles, non documentes.

## 3. PH-20.13B push still suspended

Confirme. Image Client DEV v3.5.216-kbactions-anxiety-ux-dev reste locale, NON pushee, NON deployee. Aucune action GHCR pendant cette phase.

## 4. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| Date UTC | 2026-05-25 12:01 | OK |
| Infra HEAD | main 044d9b2 dirty 0 | OK |
| Mail host SSH | alias mail-core-01 -> 10.0.0.160 (priv), 49.13.35.167 (floating), 37.27.251.162 (public), User root | OK (host key reconciliee post AS.17.1B) |
| MX hosts SSH | mail-mx-01.keybuzz.io:22 timeout | INACCESSIBLE |

## 5. KEY-323 context

- Statut Linear : Backlog, derniere mise a jour 2026-05-17. Cause initiale documentee : SMTP timeout 49.13.35.167:25, SES fallback non configure.
- AS.17.1B (2026-05-15) : NO GO, host key mail-core-01 change (reinstallation probable), floating IP 49.13.35.167 alors detachee (TCP timeout), acces SSH bloque sans GO.
- Evolution 2026-05-25 : floating IP 49.13.35.167 de nouveau routee (TCP 25/587 open), SSH mail-core-01 de nouveau accessible (host key reconciliee), services mail UP. Mais le relais sortant vers les MX est casse (nouveau symptome precis).

## 6. Network diagnostics

| Check | Before (AS.17.1B 2026-05-15) | Now (2026-05-25) | Verdict |
|---|---|---|---|
| mail.keybuzz.io A | 49.13.35.167 (floating detachee) | 49.13.35.167 (routee) | change |
| TCP 25 mail.keybuzz.io | TIMEOUT | OPEN (pas de banniere ext) | partiel |
| TCP 587 mail.keybuzz.io | TIMEOUT | OPEN (pas de banniere ext) | partiel |
| TCP 465 mail.keybuzz.io | TIMEOUT | CLOSED | - |
| Banniere SMTP localhost 25/587 | n/a | pas de greeting rapide (postscreen + stress) | service repond mais lent |
| SSH mail-mx-01:22 | n/a | TIMEOUT | MX inaccessible |

## 7. Backend log evidence (rappel PH-20.14A)

| Signal | Evidence | Verdict |
|---|---|---|
| Inbound webhook | POST /api/v1/webhooks/inbound-email actifs, Amazon forward detected | ENTRANT OK |
| Validation self-test send | depend SMTP sortant mail-core-01 -> MX | bloque (deferred) |

## 8. Code/config evidence

| Item | Valeur | Verdict |
|---|---|---|
| Backend transport | nodemailer host=SMTP_HOST (mail.keybuzz.io) port 587 | confirme PH-20.14A |
| mail-core-01 relayhost | vide | delivery directe via MX |
| mail-core-01 default_transport | smtp | MX lookup |
| smtpd_client_connection_count_limit | 50 (inbound vers core-01) | non lie au sortant |
| MX refus | 421 too many connections + 454 Relay access denied | cause cote MX |

## 9. Mail host audit (mail-core-01, read-only)

| Service | Etat | Verdict |
|---|---|---|
| postfix@-.service | active running | UP |
| dovecot | active running | UP |
| opendkim | active running | UP |
| rspamd | active running | UP |
| smtpd listen 25/587 | LISTEN 0.0.0.0:25 + 0.0.0.0:587 | UP |
| Queue | 1873 requests / 4805 Ko | SATURE |
| status counts | deferred 58249 / expired 965 / sent 14 | sortant casse |
| Erreur dominante | 421 "too many connections from 49.13.35.167" (mail-mx-02) + 454 "Relay access denied" | relais MX refuse |

Aucun secret lu. Aucun contenu de mailbox lu. Adresses masquees dans les logs.

## 10. Action corrective executee

AUCUNE.

Justification (conditions STOP du prompt remplies) :
- Aucun service mail-core-01 n est arrete/hung (tous actifs) -> pas de restart/start/reload justifie.
- La cause est cote MX (mail-mx-01/02) : refus de relais + rate-limit, et ces hosts sont inaccessibles (SSH:22 timeout, non documentes).
- Le correctif (relay access + connection limit cote MX, et resorption de la file) n est ni minimal ni un simple redemarrage ; il requiert un acces et une config deliberee -> hors perimetre, GO separe requis.
- Un restart postfix mail-core-01 relancerait la boucle de saturation (re-flood des MX) sans corriger le refus.

## 11. Post-fix verification

N/A - aucune action. Etat inchange : sortant deferred, file 1873, MX refusent.

## 12. Remaining risks

- File de 1873 messages continue de croitre et de retenter -> alimente le 421 "too many connections" (boucle).
- 965 messages deja expires (perdus pour le destinataire).
- Tous les emails SaaS sortants (contact/billing/lifecycle/invitations) + validation inbound Amazon + outbound Amazon restent bloques tant que le relais MX n est pas repare.
- Risque securite : la reinstallation mail (AS.17.1B) a probablement laisse une config relais MX incorrecte ; verifier qu aucun relay ouvert n a ete cree par erreur (ne PAS ouvrir le relais au monde).

## 13. Next required GO

GO ESCALATE MAIL SERVER MAIL.KEYBUZZ.IO PROD KEY-323

Plan de remediation propose (requiert acces MX + GO Ludovic) :
1. Obtenir acces SSH documente aux MX mail-mx-01 (91.99.66.6) / mail-mx-02 (91.99.87.76) - actuellement port 22 timeout.
2. Cote MX : corriger relay access pour 49.13.35.167 / domaine inbound.keybuzz.io (mynetworks / relay_domains / smtpd_relay_restrictions) -> lever le 454 Relay access denied.
3. Cote MX : relever / adapter la limite de connexions par client pour 49.13.35.167 -> lever le 421 too many connections.
4. Cote mail-core-01 : apres correction MX, resorber la file proprement (postqueue -f controle), surveiller status=sent ; NE PAS purger.
5. Re-verifier banniere/envoi, puis seulement ensuite phase PH-20.14B (re-trigger validation Amazon).

Alternative si MX irreparables a court terme : configurer un relayhost/smarthost externe (ex SES/transactionnel) sur mail-core-01 (decision produit, GO separe).

## 14. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| Mutation DB / inbound_addresses / outbound_deliveries | OUI | 0 (aucune requete DB cette phase) |
| Retry deliveries / send-validation / message marketplace | OUI | 0 |
| App build / deploy / kubectl app mutation | OUI | 0 |
| GitOps manifest mutation | OUI | 0 |
| Action mail corrective (restart/reload/queue) | OUI | 0 (STOP avant action) |
| Mail queue purge / firewall flush / DNS change | OUI | 0 |
| Credential rotation / secret printing / env dump / mailbox dump | OUI | 0 |
| Private keys | OUI | 0 |
| PII brute (emails destinataires) | OUI | masquees dans logs et rapport |
| Linear statut / ticket | OUI | 0 / 0 |
| Push Client PH-20.13B | OUI | suspendu |
| Bastion install-v3 + mail host attendu (49.13.35.167) | OUI | verifie E1/E7 |

## 15. Rollback

N/A - aucune action corrective executee. Aucune mutation runtime/DB/manifest/Git applicative. Seul artefact : ce rapport docs commit dans keybuzz-infra/main.

STOP.
