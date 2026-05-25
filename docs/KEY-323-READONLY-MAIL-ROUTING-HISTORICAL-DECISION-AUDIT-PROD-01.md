# KEY-323-READONLY-MAIL-ROUTING-HISTORICAL-DECISION-AUDIT-PROD-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14 / PH-20.14A / PH-20.13B suspended / KEY-231
> Phase : READONLY MAIL ROUTING HISTORICAL DECISION AUDIT PROD KEY-323
> Environnement : PROD INFRA MAIL (READ-ONLY STRICT ; aucune mutation)

## 1. Verdict

GO READONLY MAIL ROUTING HISTORICAL DECISION AUDIT PROD READY KEY-323

Decision claire et historiquement ancree. L incident actuel est la RECURRENCE du probleme #2 documente le 2026-04-04 (PH-MAIL-AUDIT-DELIVERABILITY-01) : les MX rejettent @keybuzz.io (454 Relay access denied) -> boucle de reessai -> file qui sature et 421 too many connections. Cause : le mail systeme interne vers alerts@keybuzz.io / sre@keybuzz.io n a pas de destination valide (keybuzz.io ni local sur core, ni dans relay_domains MX), et la correction F2 (relay_domains += keybuzz.io) n a jamais ete re-appliquee apres la reinstallation mail AS.17.1B (ou a ete perdue). Le fix naif (relay_domains += keybuzz.io OU 49.13.35.167 dans mynetworks MX) SANS livraison locale keybuzz.io sur core creerait une BOUCLE core<->MX (relayhost MX = [10.0.0.160]) - risque deja signale historiquement par PH-MAIL-PRE-FIX-VALIDATION-02A.

Decision recommandee : Option A (livraison LOCALE de keybuzz.io sur mail-core-01 + aliases alerts/sre, qui casse la boucle) AVANT toute extension relay_domains MX, puis nettoyage cible du backlog alerts@/sre@ (precedent SAFE PH-MAIL-CLEANUP-QUEUE-04), Amazon validation en phase separee. AUCUNE mutation executee dans cette phase.

PH-20.13B push Client reste SUSPENDU.

## 2. Sources relues

- AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH, CE_PROMPTING_STANDARD (reference).
- Incident courant : PH-20.14, PH-20.14A, KEY-323-FIX, KEY-323-ESCALATE.
- Historique mail : PH-MAIL-AUDIT-DELIVERABILITY-01, PH-MAIL-PRE-FIX-VALIDATION-02A, PH-MAIL-FIX-DELIVERABILITY-02A, PH-MAIL-INBOUND-DIAGNOSTIC-03, PH-MAIL-CLEANUP-QUEUE-04, PH-MAIL-WEBHOOK-FIX-05, PH-MAIL-OBSERVE-07, PH-WEBSITE-AS.17.1B.
- Amazon : PH-AMAZON-OUTBOUND-TRUTH-03, AMAZON-OUTBOUND-SOURCE-OF-TRUTH, PH15-AMAZON-INBOUND-ADDRESS-01.

## 3. Timeline historique

| Rapport | Date | Constat mail | Fix propose | Applique | Risque signale | Pertinence actuelle |
|---|---|---|---|---|---|---|
| PH-MAIL-AUDIT-DELIVERABILITY-01 | 2026-04-04 | MX rejettent @keybuzz.io (454), boucle reessai, 9183 deferred ; myorigin mismatch | F2 relay_domains += keybuzz.io (MX) ; F4 myorigin=keybuzz.io | F4 OUI / F2 cf 02A | F2 = RISQUE | RECURRENCE exacte aujourd hui |
| PH-MAIL-PRE-FIX-VALIDATION-02A | 2026-04 | Validation pre-fix | F4 SAFE ; F2 RISQUE MOYEN | doc | F2 necessite config SUPP. sur core (sinon boucle) | confirme le risque boucle |
| PH-MAIL-FIX-DELIVERABILITY-02A | 2026-04 | Application fixes deliverability | F1 TLS, F3/F4 myorigin | OUI | - | base config |
| PH-MAIL-INBOUND-DIAGNOSTIC-03 | 2026-04 | Pipeline Amazon inbound OK ; queue interne alerts@/sre@ separee | separer Amazon vs interne | doc | ne pas toucher Amazon | confirme separation |
| PH-MAIL-CLEANUP-QUEUE-04 | 2026-04-04 | Queue 59 msgs (alerts@ 89, sre@ 58), 0 Amazon | postsuper -d des deferred apres verif 0 Amazon | OUI (59 suppr) | preserver Amazon | precedent SAFE cleanup |
| PH-MAIL-WEBHOOK-FIX-05 | 2026-04 | Webhook inbound | fix webhook | OUI | - | inbound OK |
| PH-MAIL-OBSERVE-07 | 2026-04 | Sortant externe valide SPF/DKIM/DMARC/TLS OK | observation | OUI | - | sortant externe architecturalement OK |
| PH-AMAZON-OUTBOUND-TRUTH-03 | - | Amazon exige From = adresse inbound tenant @inbound.keybuzz.io | doctrine | OUI | ne pas bypasser guard | guard outbound legitime |

## 4. Etat hosts

| Host | IP interne | Hostname | IPs detectees | SSH | Verdict |
|---|---|---|---|---|---|
| mail-core-01 | 10.0.0.160 | mail-core-01 | 49.13.35.167 / 37.27.251.162 / 10.0.0.160 | OK | identite OK |
| mail-mx-01 | 10.0.0.161 | mail-mx-01 | 91.99.66.6 / 10.0.0.161 | OK | identite OK |
| mail-mx-02 | 10.0.0.162 | mail-mx-02 | 91.99.87.76 / 10.0.0.162 | OK | identite OK |

## 5. Etat Postfix core / MX (read-only)

mail-core-01 :
| Param | Valeur | Attendu historique | Risque |
|---|---|---|---|
| myhostname | mail.keybuzz.io | mail.keybuzz.io | OK |
| myorigin | keybuzz.io | keybuzz.io (F4) | OK (bounces from @keybuzz.io) |
| mydestination | mail-core-01, localhost.localdomain, localhost | localhost | keybuzz.io NON local |
| local_recipient_maps | (vide) | - | accepte tout local (mais keybuzz.io pas local) |
| relayhost | (vide) | vide | delivery MX directe |
| smtp_bind_address | 49.13.35.167 | - | source hors mynetworks MX |
| transport_maps | hash:/etc/postfix/transport (inbound.keybuzz.io -> webhook:) | idem | validation Amazon LOCALE |
| alias_maps | hash:/etc/aliases (postmaster: root) | - | pas d alias alerts/sre |
| virtual_alias_maps | (absent) | - | pas de livraison virtuelle keybuzz.io |

mail-mx-01 / mail-mx-02 (identiques) :
| Param | Valeur | Attendu historique | Risque |
|---|---|---|---|
| myhostname | mail-mx-0X.keybuzz.io | - | OK |
| mydestination | (vide) | vide | OK |
| relay_domains | inbound.keybuzz.io | F2 voulait += keybuzz.io | keybuzz.io ABSENT -> 454 |
| relayhost | [10.0.0.160]:25 | - | MX -> core (risque boucle si core ne livre pas localement) |
| mynetworks | 127/8 [::1]/128 10.0.0.0/16 | - | 49.13.35.167 (source core) ABSENT |
| smtpd_recipient_restrictions | permit_mynetworks, reject_unauth_destination, permit | - | rejette @keybuzz.io de source publique |
| smtpd_client_connection_rate_limit | 50 | - | 421 sous storm |
| smtpd_client_message_rate_limit | 100 | - | - |

## 6. Queue classification (sans PII)

| Metric | Valeur | Commentaire |
|---|---|---|
| Total requests | 1873 | environ |
| Total KB | 4805 | environ |
| Recipients alerts@keybuzz.io | 1948 | monitoring/alerting interne |
| Recipients sre@keybuzz.io | 1914 | monitoring/SRE interne |
| Recipients noreply@keybuzz.io | 1 | negligeable |
| Recipients @inbound.keybuzz.io | 1 | A PRESERVER (Amazon) |
| Recipients @amazonses | 1 | A PRESERVER |
| Senders | MAILER-DAEMON + alerts/sre @keybuzz.io | bounces/DSN + notifications |
| Erreur dominante | 454 Relay access denied (mail-mx) + 421 too many connections | identique avril |

| Domaine recipient | Count | Nature | Action recommandee future | Risque |
|---|---|---|---|---|
| alerts@keybuzz.io | 1948 | notifications monitoring + bounces | livraison locale core OU stop source ; backlog cleanup cible | faible si Amazon preserve |
| sre@keybuzz.io | 1914 | notifications SRE + bounces | idem | faible |
| @inbound.keybuzz.io | 1 | Amazon validation | PRESERVER, ne jamais supprimer | eleve si touche |
| @amazonses | 1 | technique | PRESERVER | moyen |

## 7. Source probable des bounces

| Source candidate | Evidence | Probability | Corrective action future | Risk |
|---|---|---|---|---|
| Systeme monitoring/SRE -> alerts@ / sre@keybuzz.io | 1948 alerts + 1914 sre, identique a PH-MAIL-AUDIT (avril, alerts@ 89 / sre@ 58) et CLEANUP-04 | HAUTE | identifier l emetteur (alertmanager/cron/healthcheck) + pointer vers une adresse livrable OU livrer localement | faible |
| MAILER-DAEMON backscatter (DSN) | senders MAILER-DAEMON@keybuzz.io (myorigin=keybuzz.io) sur mail non delivrable | HAUTE | livraison locale keybuzz.io casse le cycle DSN | faible |
| Effet reinstallation AS.17.1B | F2 (relay_domains += keybuzz.io) non re-applique ; volume passe de ~59 (avril) a ~3862 | HAUTE | re-appliquer routage keybuzz.io de facon SAFE | moyen |
| App/backend | non observe dans la queue (apps -> webhook/externe) | FAIBLE | - | - |
| Boucle deja active core<->MX | relayhost MX = core ; mais core ne rerelaie pas (pas local) -> actuellement defer, pas boucle infinie ; le fix naif LA creerait | MOYENNE | livraison locale d abord | ELEVE si fix naif |

## 8. Decision routage recommandee

| Option | Description | Corrige 454 | Corrige 421 | Risque boucle | Impact Amazon | Impact SaaS emails | Rollback | Recommandation |
|---|---|---|---|---|---|---|---|---|
| A | keybuzz.io LOCAL sur core (mydestination/virtual + aliases alerts/sre/root/MAILER-DAEMON) PUIS relay_domains += keybuzz.io MX | OUI | OUI (plus de retry storm) | NEUTRALISE (core livre local, ne re-relaie pas) | NUL (inbound = transport webhook local, independant) | debloque interne + reduit pression sortante | restaurer main.cf/aliases backup + reload | RECOMMANDEE |
| B | Garder MX = inbound.keybuzz.io ; corriger/arreter la SOURCE alerts@/sre@ + cleanup backlog | partiel (454 persiste pour entrants legitimes @keybuzz.io) | OUI (si source stoppee) | aucun | NUL | n adresse pas la reception @keybuzz.io | revert source config | COMPLEMENT de A (identifier emetteur) |
| C | Routage externe keybuzz.io (SES/Workspace/OVH) | OUI | OUI | aucun | NUL | impact DNS/produit large, pas immediat | revert DNS | NON court terme |
| D | Null route/discard cible des bounces techniques | partiel | OUI | aucun | NUL | perte notifications | revert alias | UNIQUEMENT pour backlog/discard cible, jamais global |

Recommandation reviewer : Option A (livraison locale keybuzz.io sur core qui casse la boucle) comme socle, completee par B (identifier et fiabiliser l emetteur alerts@/sre@) et un cleanup cible du backlog selon le precedent CLEANUP-04. Ne JAMAIS appliquer relay_domains += keybuzz.io MX ou 49.13.35.167 dans mynetworks MX AVANT que core livre keybuzz.io localement.

## 9. Options rejetees

- Ajout 49.13.35.167 a mynetworks MX seul : cree boucle core<->MX (relayhost MX = core). REJETE.
- relay_domains += keybuzz.io MX seul (sans local delivery core) : boucle. REJETE (confirme PRE-FIX-VALIDATION-02A).
- postsuper -d ALL / flush queue avant routage defini : relance le storm + risque suppression Amazon. REJETE.
- Bypass guard Amazon / flip DB VALIDATED / activer SP-API : hors sujet et interdit. REJETE.

## 10. Plan APPLY futur (ordre sur, NON execute)

| # | Host | Action conceptuelle | Risque | Rollback | Preuve attendue |
|---|---|---|---|---|---|
| 1 | core+MX | Backup main.cf/master.cf/transport/aliases + postconf -n > before | nul | - | fichiers .bak horodates |
| 2 | core | Rendre keybuzz.io livrable LOCALEMENT (mydestination += keybuzz.io OU virtual) + aliases alerts/sre/root vers mailbox reelle ou discard decide | moyen | revert main.cf/aliases + reload | postmap + postconf montrent keybuzz.io local |
| 3 | core | newaliases / postmap si maps modifiees | faible | revert + newaliases | maps a jour |
| 4 | core | postfix check | nul | - | check OK |
| 5 | core | systemctl reload postfix | faible | reload config backup | reload OK, pas d erreur |
| 6 | MX (si retenu) | relay_domains += keybuzz.io UNIQUEMENT apres que core livre localement | moyen | revert relay_domains + reload | postconf MX |
| 7 | MX | postfix check + reload | faible | revert | check OK |
| 8 | core | Test SMTP minimal local sans contenu client (EHLO/MAIL/RCPT/RSET/QUIT vers alerts@keybuzz.io) | faible | - | 250 accepted local, plus de 454 |
| 9 | core | Cleanup backlog CIBLE alerts@/sre@ deferred APRES verif 0 Amazon/inbound (precedent CLEANUP-04) ; jamais postsuper -d ALL | moyen | non reversible (mail perdu) -> verifier avant | queue alerts/sre = 0, @inbound preserve |
| 10 | - | Identifier et fiabiliser l emetteur alerts@/sre@ (alertmanager/cron) | faible | - | source pointe vers adresse livrable |
| 11 | phase separee | PH-20.14B re-trigger Amazon validation | - | - | PENDING -> VALIDATED legitime |
| 12 | phase separee | Retry outbound deliveries APRES validation | - | - | status=sent |

## 11. Amazon feature parity / anti-regression

| Flux | Source of truth | Etat attendu | Risque incident | Action future |
|---|---|---|---|---|
| Amazon inbound @inbound.keybuzz.io -> MX -> core -> webhook | PH-MAIL-WEBHOOK-FIX-05, PH-20.14A | fonctionne (webhook recoit) | ne pas casser relay_domains inbound.keybuzz.io | preserver |
| Validation inbound self-test | PH-20.14A | core transport webhook: LOCAL (independant des MX et de keybuzz.io) | ne pas confondre avec storm @keybuzz.io | re-verifier en PH-20.14B |
| Amazon outbound From = adresse inbound tenant VALIDATED | PH-AMAZON-OUTBOUND-TRUTH-03 | guard exige VALIDATED | ne pas bypasser | aucune |
| Guard outbound bloque si inbound PENDING | PH-20.14 | correct par design | ne pas contourner | aucune |
| AMAZON_SPAPI_MESSAGING_ENABLED=false fallback SMTP | PH-20.14 | inchange | ne pas activer SP-API | aucune |

Note : les 2 messages @inbound.keybuzz.io / @amazonses dans la queue doivent etre PRESERVES lors de tout cleanup.

## 12. No fake metrics / no fake events

| Signal | Source reelle autorisee | Fake interdit |
|---|---|---|
| Etat queue | postqueue -p reel | inventer un total |
| validationStatus | backend webhook reel (PENDING->VALIDATED) | flip DB manuel |
| Amazon delivered | worker outbound reel apres VALIDATED | fake delivered |
| Emails sent | logs Postfix status=sent reels | fake sent |
| Bounces source | classification queue reelle (alerts/sre) | inventer une source |

## 13. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| postconf -e / reload / restart / flush / postsuper | OUI | 0 (lecture seule : postconf -n, postqueue -p) |
| Ajout 49.13.35.167 mynetworks MX / keybuzz.io relay_domains | OUI | 0 (refuse, documente comme risque boucle) |
| Modif main.cf/master.cf/transport/aliases/virtual / newaliases / postmap | OUI | 0 |
| DNS / firewall / DB / retry / send-validation / message marketplace | OUI | 0 |
| Build / push / deploy / kubectl | OUI | 0 |
| Secret / private key / mailbox / env dump / PII brute | OUI | configs non-secretes, local-parts agreges (alerts/sre deja documentes) |
| Linear statut / ticket | OUI | commentaires seulement |
| Push Client PH-20.13B | OUI | suspendu |
| Bastion install-v3 + IP internes attendues | OUI | verifie E0 |

## 14. Rollback futur

Si une future phase APPLY echoue : restaurer les .bak horodates (main.cf/master.cf/transport/aliases) sur le host concerne, newaliases/postmap si besoin, postfix check, systemctl reload postfix, verifier postconf -n == before. Le cleanup backlog (etape 9) n est PAS reversible (mail supprime) -> n executer qu apres preuve 0 Amazon/inbound dans la queue, conformement au precedent PH-MAIL-CLEANUP-QUEUE-04.

## 15. Prochaine phrase GO

GO APPLY MAIL ROUTING KEYBUZZ.IO PROD KEY-323

Conditions remplies : routage core defini (Option A livraison locale), risque boucle neutralise (livraison locale avant relay_domains MX), backlog cleanup cible (precedent CLEANUP-04, preserver Amazon), Amazon validation en phase separee (PH-20.14B). Decision Ludovic requise sur la destination finale de alerts@/sre@keybuzz.io (mailbox reelle vs discard vs forward) avant l etape 2 du plan APPLY.

STOP.
