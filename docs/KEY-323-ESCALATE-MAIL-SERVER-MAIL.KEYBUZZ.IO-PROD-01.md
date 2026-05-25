# KEY-323-ESCALATE-MAIL-SERVER-MAIL.KEYBUZZ.IO-PROD-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14 / PH-20.14A / KEY-231
> Phase : KEY-323-ESCALATE-MAIL-SERVER-MAIL.KEYBUZZ.IO-PROD
> Environnement : PROD INFRA MAIL (acces interne bastion ; read-only first ; AUCUNE mutation executee)

## 1. Verdict

GO ESCALATE MAIL SERVER MAIL.KEYBUZZ.IO PROD BLOCKED KEY-323 : cause racine identifiee au niveau config, mais le correctif suggere (ajouter l IP publique a mynetworks MX) creerait une BOUCLE mail et l hypothese initiale est falsifiee. Aucune mutation MX/core executee (decision de securite). Remediation deliberee requise (decision routing keybuzz.io + traitement backlog).

Acces interne confirme aux 3 hosts (identites verifiees). Diagnostic complet read-only. Le blocage n est PAS un simple "MX qui n autorise pas core dans mynetworks" : c est un probleme de routage de domaine + backlog de bounces non delivrables qui sature les MX.

PH-20.13B push Client reste SUSPENDU.

## 2. Resume executif

Architecture observee (read-only) :
- mail-core-01 (10.0.0.160 ; smtp_bind_address = 49.13.35.167 = IP publique flottante) : relayhost VIDE -> delivery directe via MX lookup. transport_maps : inbound.keybuzz.io -> webhook: (validation traitee localement par core, PAS via MX). mydestination = mail-core-01/localhost (PAS keybuzz.io).
- mail-mx-01 (10.0.0.161 / 91.99.66.6) et mail-mx-02 (10.0.0.162 / 91.99.87.76) : passerelles ENTRANTES. relay_domains = inbound.keybuzz.io ; mynetworks = 127/8 [::1]/128 10.0.0.0/16 ; relayhost = [10.0.0.160]:25 (les MX relaient vers core) ; smtpd_client_connection_rate_limit = 50 ; smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination, permit.

Cause racine (chaine) :
1. La file mail-core-01 est saturee de 3844 messages a destination de @keybuzz.io (vs 1 @inbound.keybuzz.io, 1 @amazonses). Ce sont en majorite des bounces/notifications MAILER-DAEMON (expediteur et destinataire @keybuzz.io).
2. keybuzz.io n est destination NI sur core (mydestination) NI sur MX (relay_domains = inbound.keybuzz.io uniquement). Donc core fait un MX lookup pour keybuzz.io -> MX mail-mx-01/02, et leur envoie ces messages depuis la source 49.13.35.167.
3. 49.13.35.167 (IP publique de core) n est PAS dans mynetworks des MX (qui ne contient que 10.0.0.0/16). Donc permit_mynetworks echoue -> reject_unauth_destination -> 454 Relay access denied pour @keybuzz.io.
4. Le volume de retries (3844, depuis 2026-05-24) depasse 50 connexions/60s -> 421 too many connections from 49.13.35.167.
5. Ce storm sature aussi le canal et degrade le service (smtpd en mode stress, pas de banniere rapide).

Hypothese du prompt FALSIFIEE : les MX ne "manquent" pas core dans mynetworks pour le reseau interne (10.0.0.0/16 present, couvre 10.0.0.160). Le vrai probleme est (a) core sort par l IP publique 49.13.35.167 (smtp_bind_address) qui n est pas dans mynetworks MX, ET (b) keybuzz.io n est routable nulle part, generant un backlog massif.

RISQUE du fix naif (ajouter 49.13.35.167 a mynetworks MX) : les MX accepteraient alors les messages @keybuzz.io et, via leur relayhost = [10.0.0.160]:25, les renverraient a core -> core re-tente -> BOUCLE mail core<->MX sur 3844 messages. Refuse.

## 3. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| Date UTC | 2026-05-25 12:16 | OK |
| Infra HEAD | main 4c8e1fe | OK |

## 4. Hosts

| Host | IP interne | IPs | Access | Verdict |
|---|---|---|---|---|
| mail-core-01 | 10.0.0.160 | 49.13.35.167 / 37.27.251.162 | SSH OK | identite OK |
| mail-mx-01 | 10.0.0.161 | 91.99.66.6 | SSH OK | identite OK |
| mail-mx-02 | 10.0.0.162 | 91.99.87.76 | SSH OK | identite OK |

## 5. Before state (read-only)

mail-core-01 :
| Param | Valeur |
|---|---|
| myhostname | mail.keybuzz.io |
| mydestination | mail-core-01, localhost.localdomain, localhost |
| relayhost | (vide) |
| smtp_bind_address | 49.13.35.167 |
| transport_maps | hash:/etc/postfix/transport (inbound.keybuzz.io -> webhook:) |
| Queue | 1873 requests / 4805 Ko ; deferred 58249 / expired 965 / sent 14 (cumul) |
| Queue recipients | @keybuzz.io 3844 ; @inbound.keybuzz.io 1 ; @amazonses 1 |
| Nature backlog | bounces/notifications MAILER-DAEMON @keybuzz.io |

mail-mx-01 / mail-mx-02 (identiques) :
| Param | Valeur |
|---|---|
| myhostname | mail-mx-0X.keybuzz.io |
| mydestination | (vide) |
| relay_domains | inbound.keybuzz.io |
| mynetworks | 127.0.0.0/8 [::1]/128 10.0.0.0/16 |
| relayhost | [10.0.0.160]:25 |
| smtpd_client_connection_rate_limit | 50 |
| smtpd_client_message_rate_limit | 100 |
| smtpd_recipient_restrictions | permit_mynetworks, reject_unauth_destination, permit |

## 6. Config changes

AUCUN. Aucune modification appliquee sur core ni MX (decision de securite, voir Verdict + section 10).

## 7. MX reload/check

N/A - aucune modification, donc aucun reload/check execute.

## 8. Relay tests

N/A - aucun test SMTP actif execute en E (read-only state suffisant pour diagnostic). L erreur 454/421 est deja prouvee par les logs et la file.

## 9. Queue flush result

N/A - aucun flush. Un flush sans correction de routage relancerait le storm (421) et la boucle potentielle. NON execute.

## 10. Remaining risks

- Backlog de 3844 messages @keybuzz.io non delivrables continue de croitre et de retenter -> alimente le 421 et degrade le service mail global.
- 965 messages deja expires (perdus).
- Tant que keybuzz.io n a pas de destination definie, ces messages ne peuvent ni etre delivres ni etre nettoyes proprement sans decision.
- Risque de BOUCLE si on ajoute 49.13.35.167 a mynetworks MX (relayhost MX = core).
- La validation inbound Amazon (@inbound.keybuzz.io) passe par le transport webhook: LOCAL de core (pas par les MX) -> potentiellement deja fonctionnelle une fois le storm resorbe ; a re-verifier en PH-20.14B.
- Heritage probable de la reinstallation mail (AS.17.1B) : routage keybuzz.io et/ou rate-limit MX non reconfigures.

## 11. Next GO

GO ESCALATE MAIL SERVER MAIL.KEYBUZZ.IO PROD KEY-323 (decision infra/produit requise avant mutation).

Plan de remediation SUR propose (GO explicite requis pour chaque point, DEV/test d abord si possible) :
1. DECISION ROUTAGE keybuzz.io : definir ce que deviennent les emails @keybuzz.io (domaine local avec mailboxes ? alias ? rejet propre a la source applicative ? hold/drop controle du backlog ?). C est la cause primaire du storm.
2. SOURCE IP core : evaluer si core doit relayer vers les MX par son IP INTERNE 10.0.0.160 (deja dans mynetworks MX) plutot que par 49.13.35.167 (smtp_bind_address). Mais attention : pour l email EXTERNE legitime (clients), la source 49.13.35.167 est probablement requise (rDNS/SPF). Ne pas casser le sortant externe.
3. RATE-LIMIT MX : apres resorption du backlog, evaluer smtpd_client_connection_rate_limit pour 49.13.35.167 (relacher de facon ciblee, sans ouvrir aux abus).
4. BACKLOG : traiter les 3844 messages @keybuzz.io de facon controlee (hold/requeue/drop selon decision routage) - JAMAIS postsuper -d ALL aveugle.
5. Verifier qu aucun relais ouvert n est cree ; ne PAS ajouter une IP publique a mynetworks MX sans neutraliser le risque de boucle (relayhost MX).
6. Ensuite seulement : PH-20.14B re-trigger validation Amazon.

Recommandation : impliquer Ludovic pour la decision de routage keybuzz.io (point 1) car elle conditionne tout le reste et peut indiquer un bug applicatif (qui genere 3844 mails @keybuzz.io ?).

## 12. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| Mutation config MX / core | OUI | 0 (aucun postconf -e, aucun reload) |
| Backup/modif main.cf | OUI | 0 (pas de modif donc pas de backup necessaire) |
| Queue flush / postsuper -d / purge | OUI | 0 |
| DB / inbound_addresses / outbound_deliveries / retry / send-validation | OUI | 0 |
| Message marketplace | OUI | 0 |
| App patch / build / deploy / kubectl | OUI | 0 |
| DNS change / firewall flush / relais ouvert | OUI | 0 |
| Secret / private key / mailbox / env dump | OUI | 0 (config non-secrete uniquement, local-parts masques) |
| PII brute | OUI | recipients/senders masques |
| Linear statut / ticket | OUI | 0 / 0 |
| Push Client PH-20.13B | OUI | suspendu |
| Bastion install-v3 + IP internes attendues | OUI | verifie E1/E2 |

## 13. Rollback

N/A - aucune mutation executee. Aucun fichier modifie sur core ni MX. Seul artefact : ce rapport docs commit dans keybuzz-infra/main.

STOP.
