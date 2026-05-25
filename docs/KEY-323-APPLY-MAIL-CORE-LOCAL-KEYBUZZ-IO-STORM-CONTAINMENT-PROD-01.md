# KEY-323-APPLY-MAIL-CORE-LOCAL-KEYBUZZ-IO-STORM-CONTAINMENT-PROD-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14 / PH-20.14A / PH-20.13B suspended
> Phase : APPLY MAIL CORE LOCAL KEYBUZZ.IO STORM CONTAINMENT PROD KEY-323
> Environnement : PROD INFRA MAIL (mutation core-only, reversible ; MX intacts ; Amazon preserve)

## 1. Verdict

GO APPLY MAIL CORE LOCAL KEYBUZZ.IO STORM CONTAINMENT PROD READY KEY-323

Correction minimale et reversible appliquee sur mail-core-01 UNIQUEMENT. keybuzz.io est desormais livrable localement (mydestination += keybuzz.io) ; alerts@ et sre@keybuzz.io sont aliases vers root (mailbox locale /var/mail/root = sink controle). Resultat : les messages @keybuzz.io ne repartent plus vers les MX (relay=local, status=sent), le storm est STOPPE (0 nouveau 454/421 vers les MX), aucune boucle possible. Les MX mail-mx-01/02 sont strictement INCHANGES. Le transport inbound.keybuzz.io -> webhook est PRESERVE. Le backlog se draine de lui-meme vers le sink local (aucun postsuper -d execute : plus sur que la suppression, zero perte, zero risque Amazon). Contrat Amazon outbound (From = adresse inbound tenant) inchange.

PH-20.13B push Client reste SUSPENDU. Aucune validation Amazon, aucun retry delivery.

## 2. Sources relues

PH-20.14, PH-20.14A, KEY-323-FIX, KEY-323-ESCALATE, KEY-323-READONLY-AUDIT (decision Option A) ; PH-MAIL-AUDIT-DELIVERABILITY-01, PH-MAIL-PRE-FIX-VALIDATION-02A, PH-MAIL-CLEANUP-QUEUE-04 (precedent) ; PH-AMAZON-OUTBOUND-TRUTH-03 (contrat From) ; AI_MEMORY RULES_AND_RISKS.

## 3. Preflight

| Host | IP interne | Hostname | Role | Verdict |
|---|---|---|---|---|
| install-v3 | 46.62.171.61 | install-v3 | bastion | OK |
| mail-core-01 | 10.0.0.160 | mail-core-01 | MTA cible | OK |
| mail-mx-01 | 10.0.0.161 | mail-mx-01 | MX (NON touche) | OK |
| mail-mx-02 | 10.0.0.162 | mail-mx-02 | MX (NON touche) | OK |

Services core avant : postfix/opendkim/dovecot/rspamd actifs. parent_domain_matches_subdomains n inclut NI mydestination NI transport_maps -> ajout keybuzz.io a mydestination n affecte PAS inbound.keybuzz.io.

## 4. Before state

| Param | Valeur avant |
|---|---|
| mydestination | mail-core-01, localhost.localdomain, localhost |
| myorigin | keybuzz.io |
| transport_maps | inbound.keybuzz.io -> webhook: |
| /etc/aliases | postmaster: root (pas alerts/sre) |
| Queue | 1910 requests / 4822 Ko ; ~3844 @keybuzz.io (alerts 1948 + sre 1914), 1 @inbound, 1 @amazonses |
| Storm | core -> MX 454 Relay access denied + 421 too many connections |

## 5. Backups (mail-core-01)

Repertoire : /root/key323-backup-20260525-131950/ (avant mutation).

| Fichier | sha256 original (capture) |
|---|---|
| /etc/postfix/main.cf | e41ea4f6f67f385b91a9b0fcc4fbec7a38f76fb2d3a0eb61863299a20deefcbe |
| /etc/aliases | 5acece4532eb1da22d175ea0d17baa34c137857cd6d778876a792c3677c23387 |
| /etc/postfix/transport | 6600b55b1eeaea26b57d2078beaeaba1036e014af1e7a07d66e5cc677dce63d5 |
| /etc/postfix/master.cf | adc7cb5033f594f5eb6cdc93d7ecaa56d5d34446c754673264503d8c2f88d4ac |

## 6. Design local delivery (core only)

| Adresse | Destination locale | Pourquoi | Risque | Rollback |
|---|---|---|---|---|
| alerts@keybuzz.io | alias -> root (/var/mail/root) | sink local controle, stoppe le relais MX | mailbox root grossit | restaurer /etc/aliases + newaliases |
| sre@keybuzz.io | alias -> root | idem | idem | idem |
| autres @keybuzz.io | local (mydestination) | contient localement, pas de relais MX | bounce local (contenu) | restaurer mydestination |
| @inbound.keybuzz.io | transport webhook (INCHANGE) | Amazon validation preservee | aucun | n/a (non modifie) |

Aucun forward externe. Aucun relais MX. Aucun discard aveugle.

## 7. Diff exact core

| Fichier | Changement | Risque | Rollback |
|---|---|---|---|
| main.cf | mydestination = mail-core-01, localhost.localdomain, localhost, **keybuzz.io** | keybuzz.io livre local | restaurer main.cf backup + reload |
| /etc/aliases | ajout **alerts: root** et **sre: root** | livraison sink root | restaurer aliases backup + newaliases |

Inchange : transport_maps (inbound.keybuzz.io -> webhook), relayhost (vide), smtp_bind_address, myorigin, MX (aucun acces ecriture).

## 8. Postfix check / reload

- newaliases : OK
- postfix check : OK (aucune erreur)
- postfix reload : OK ("refreshing the Postfix mail system")
- systemctl is-active postfix : active

## 9. Tests local delivery (sendmail -bv, sans envoi reel)

| Test | Attendu | Resultat (maillog) | Verdict |
|---|---|---|---|
| alerts@keybuzz.io | local, pas MX | relay=local, status=sent (delivered to mailbox) | OK |
| sre@keybuzz.io | local, pas MX | relay=local, status=sent/deliverable (mailbox) | OK |
| amazon...@inbound.keybuzz.io | webhook | relay=webhook, delivers to /usr/local/bin/postfix_webhook.sh | OK (preserve) |

Aucun email reel externe envoye. Aucun send-validation. Aucun message marketplace.

## 10. Queue classification

| Categorie | Count (apres reload) | Incluse cleanup ? | Raison |
|---|---|---|---|
| @keybuzz.io (alerts/sre) | 3613 (drainage en cours) | NON | se livre desormais en local (relay=local sent) -> drainage naturel, suppression inutile |
| @inbound.keybuzz.io | 1 | NON | Amazon, PRESERVER |
| @amazonses | 1 | NON | technique, PRESERVER |

Queue totale : 1910 -> 1755 requests (drainage en cours via local delivery sur retry).

## 11. Cleanup cible : NON execute (par decision)

Aucun postsuper -d execute. Justification : apres la correction, les messages alerts@/sre@ se livrent LOCALEMENT (status=sent vers mailbox root) au fil des retries Postfix. La suppression est donc INUTILE et MOINS SURE (perte de mail, risque de toucher un message non classe). Le backlog se draine de lui-meme vers le sink local. postqueue -f est interdit par le prompt -> drainage naturel sur le calendrier de retry Postfix. Plan de cleanup separe non necessaire ; si un drainage plus rapide est souhaite, une phase dediee pourra evaluer postqueue -f (hors scope ici).

## 12. Verifications post-apply

| Check | Avant | Apres | Verdict |
|---|---|---|---|
| core postfix actif | active | active | OK |
| postfix check | - | OK | OK |
| alerts/sre routing | MX (454) | relay=local sent | CORRIGE |
| inbound.keybuzz.io routing | webhook | webhook (inchange) | PRESERVE |
| core -> MX 454/421 (5 min) | storm | 0 | STORM STOPPE |
| MX-01 relay_domains/mynetworks | inbound.keybuzz.io / 10.0.0.0/16 | identique | INCHANGE |
| MX-02 relay_domains/mynetworks | inbound.keybuzz.io / 10.0.0.0/16 | identique | INCHANGE |
| Queue | 1910 | 1755 (drainage) | EN BAISSE |

## 13. Amazon feature parity / anti-regression

| Feature | Contrat | Change dans cette phase | Verdict |
|---|---|---|---|
| Amazon inbound @inbound.keybuzz.io -> webhook | transport webhook | NON | PRESERVE |
| Amazon inbound validation (self-test, transport local webhook) | independant des MX | NON | PRESERVE |
| Amazon outbound From | amazon.<tenant>.<country>.<token>@inbound.keybuzz.io | NON (jamais noreply/alerts/sre) | PRESERVE |
| Guard outbound validationStatus=VALIDATED | bloque si PENDING | NON | PRESERVE |
| AMAZON_SPAPI_MESSAGING_ENABLED=false fallback SMTP | inchange | NON | PRESERVE |
| PH-20.12B no-reply / PH-20.11C guardrail | code API inchange | NON | PRESERVE |
| Client PH-20.13B | suspendu | NON | SUSPENDU |

## 14. No fake metrics / events

| Signal | Source reelle autorisee | Fake interdit | Verdict |
|---|---|---|---|
| Routing alerts/sre | maillog relay=local reel | inventer | OK reel |
| inbound webhook | maillog relay=webhook reel | inventer | OK reel |
| Queue | postqueue -p reel | inventer | OK reel |
| storm 454/421 | grep maillog reel | inventer | OK reel |
| validation Amazon | aucune (non touchee) | fake VALIDATED | aucun |

## 15. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| Modification MX (mx-01/mx-02) | OUI | configs verifiees identiques apres apply |
| 49.13.35.167 dans mynetworks / keybuzz.io dans relay_domains MX | OUI | non fait |
| postqueue -f / postsuper -d / purge | OUI | 0 |
| DNS / firewall / DB / retry / send-validation / marketplace | OUI | 0 |
| build / push / deploy / kubectl | OUI | 0 |
| Lecture contenu mail / mailbox / secrets | OUI | 0 (sendmail -bv routing only, local-parts masques) |
| Boucle mail | OUI | local delivery, jamais re-relais MX |
| Push Client PH-20.13B | OUI | suspendu |
| Bastion install-v3 + IP internes | OUI | verifie E0 |

## 16. Rollback

| Element | Rollback | Reversible | Risque |
|---|---|---|---|
| mydestination | cp /root/key323-backup-20260525-131950/main.cf /etc/postfix/main.cf ; postfix check ; postfix reload | OUI | faible (retour storm) |
| /etc/aliases | cp backup/aliases /etc/aliases ; newaliases ; postfix reload | OUI | faible |
| Queue (messages livres en local) | non reversible (livres au sink root) | NON | nul (sink contenu, aucun Amazon) |

Procedure rollback complete : restaurer main.cf + /etc/aliases depuis /root/key323-backup-20260525-131950/, newaliases, postfix check, postfix reload, verifier postconf -n.

## 17. Prochaine phrase GO

GO RETRIGGER AMAZON INBOUND VALIDATION PROD PH-SAAS-T8.12AS.20.14B

Conditions remplies : Postfix core stable, storm neutralise (0 nouveau 454/421), inbound.keybuzz.io preserve, MX intacts, backlog en drainage local. Note : la validation inbound Amazon passe par le transport webhook LOCAL de core (independant des MX) ; PH-20.14B devra re-verifier le self-test et le passage PENDING -> VALIDATED de facon legitime, sans flip DB, sans bypass guard.

STOP.
