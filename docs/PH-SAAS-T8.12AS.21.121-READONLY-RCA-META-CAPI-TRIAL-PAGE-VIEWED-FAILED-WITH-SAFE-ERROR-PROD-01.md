# PH-SAAS-T8.12AS.21.121 - Readonly RCA Meta CAPI trial_page_viewed failed with safe error PROD

Date UTC: 2026-06-25
Mode: READONLY RCA META CAPI PROD
Scope: Meta CAPI `trial_page_viewed` PH-21.119 failed delivery, safe error only.

## Verdict

Verdict: `READY_ACTION_REQUIRED_META_CONFIG`

Cause probable: `META_TOKEN_OR_PIXEL_REJECTED_BY_PROVIDER`

Confiance: HIGH

Raison courte:

- la delivery PH-21.119 est retrouvee: `trial_page_viewed`, failed, HTTP 400, retryable false;
- la classification safe est `META_INVALID_PIXEL_OR_TOKEN`;
- le provider code safe est `190`, provider subcode present;
- le routing owner est OK vers `keybuzz-consulting-mo9zndlk`;
- la destination Meta CAPI KBC est active;
- le pixel metadata est present et coherent entre `platform_pixel_id` et endpoint Graph;
- le token ref metadata est present, long/encrypted-or-long, sans lecture de valeur;
- le code source utilise bien pixel/token depuis la destination, sans override event-specific;
- la classification `META_MISSING_USER_DATA` est separee de `META_INVALID_PIXEL_OR_TOKEN`.

Conclusion: pas de preuve de bug source ni de mauvais routage. La prochaine action doit etre une verification/correction hors code de la configuration Meta KBC: token CAPI, permissions token/dataset/pixel, token expire/revoque, et coherence Pixel/Dataset dans Meta Business.

## Sources relues

| Source | Resultat |
| --- | --- |
| AI_MEMORY/CURRENT_STATE.md | relu |
| AI_MEMORY/RULES_AND_RISKS.md | relu |
| AI_MEMORY/DOCUMENT_MAP.md | relu |
| AI_MEMORY/CE_PROMPTING_STANDARD.md | relu |
| PH-21.103 return/report | relu |
| PH-21.104 return/report | relu |
| PH-21.105 return | relu |
| PH-21.106 return/report | relu |
| PH-21.107 return/report | relu |
| PH-21.112 return | relu |
| PH-21.118 return/report | relu |
| PH-21.119 return/report | relu |

## Preflight bastion

| Controle | Resultat |
| --- | --- |
| hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite | 51.159.99.247 absente |
| date UTC audit | 2026-06-25T20:09:15Z |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223 dist tracked preexistants, non-dist 0 | read-only OK |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca | d9631ca | 0/0 | 1 preexistant | read-only OK |
| keybuzz-infra | main | bbbfa41 | bbbfa41 | 0/0 | 0 avant rapport | docs-only OK |

## Runtime precheck

| Service | Attendu | Resultat |
| --- | --- | --- |
| API PROD image | v3.5.265-meta-capi-error-observability-prod | OK |
| API PROD digest | sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384 | OK |
| API PROD equality | manifest=last-applied=spec=pod | OK |
| API PROD ready/restarts | 1/1, 0 | OK |
| API PROD health | status ok | OK |
| Client PROD image | v3.5.260-onboarding-register-started-owner-payload-prod | OK |
| Client PROD digest | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | OK |
| Client PROD ready/restarts | 1/1, 0 | OK |
| latest hash | expected PH-21.118/119 value | unchanged |

## Delivery failed PH-21.119

Fenetre observee: 2026-06-25T15:07:00Z -> 2026-06-25T15:37:00Z.

| Delivery PH-21.119 | Attendu | Resultat |
| --- | --- | --- |
| delivery trouvee | oui | oui |
| delivery id safe | 26e674...d3e5 | 26e674...d3e5 |
| event | trial_page_viewed | trial_page_viewed |
| event id safe | tpv_97...6c13 | tpv_97...6c13 |
| status | failed | failed |
| http_status | 400 | 400 |
| retryable | false | false |
| attempt | 3 | 3 |
| error_message safe | OK | OK |
| classification | META_INVALID_PIXEL_OR_TOKEN | META_INVALID_PIXEL_OR_TOKEN |
| provider code/subcode safe | present si disponible | code 190, subcode present |
| created_at UTC | 2026-06-25T15:27:35.565Z | OK |
| secret/PII exposure | 0 | 0 |

## Destination Meta associee metadata-only

| Destination Meta | Attendu | Resultat |
| --- | --- | --- |
| destination associee | trouvee | trouvee |
| destination id safe | tronque | 87f8dc...1192 |
| owner/tenant routing | keybuzz-consulting-mo9zndlk | OK, keybuz...ndlk |
| platform/type | Meta CAPI | meta_capi |
| enabled/status | actif | active true, deleted_at absent |
| endpoint Graph | present | present, Graph v21, pixel path masque |
| platform_account_id | present si configure | present, masque |
| pixel id present | oui | oui, masque 123...748 |
| pixel endpoint coherence | pixel id = endpoint path | OK metadata-only |
| token present metadata-only | oui | oui |
| token encrypted/masked | oui/non/N/A | present, long/encrypted-or-long |
| token brut lu/affiche | interdit | 0 |
| routage owner vs fallback | owner/fallback/KO | owner OK |

Interpretation:

- `DESTINATION_RESOLUTION_BUG`: non retenu, destination trouvee.
- `OWNER_ROUTING_DESTINATION_MISMATCH`: non retenu, owner KBC OK.
- `META_PIXEL_CONFIG_INVALID`: non prouve, pixel present et endpoint coherent metadata-only.
- `META_TOKEN_MISSING_OR_UNSYNCED`: non retenu comme cause principale, token ref present metadata-only.
- `META_TOKEN_OR_PIXEL_REJECTED_BY_PROVIDER`: retenu, car Meta renvoie 400 + `META_INVALID_PIXEL_OR_TOKEN` + code safe 190.

## Historique Meta CAPI safe

| Historique Meta CAPI | Resultat |
| --- | --- |
| total deliveries | 22 |
| success/delivered total | 15 (success=5, delivered=10) |
| failed total | 7 |
| failed trial_page_viewed | 3 |
| success events | PageView, StartTrial, ViewContent, Purchase selon historiques success/delivered |
| failed events | PageView, trial_page_viewed, ViewContent |
| classifications failed | META_INVALID_PIXEL_OR_TOKEN=1, legacy safe unparsed=6 |
| dernier success Meta meme destination | oui historique: PageView success et StartTrial/Purchase delivered sur destination 87f8dc...1192 |
| destination fail vs success | same destination deja prouvee historiquement, puis fail recent |

Interpretation:

- la destination KBC a deja eu des succes historiques;
- l'echec recent n'est pas explique par une absence de destination ou de pixel;
- la regression la plus plausible est un token Meta devenu invalide/expire/revoque, une permission/dataset/pixel modifiee cote Meta, ou une incoherence Meta Business invisible sans console Meta/token brut.

## Source audit read-only

Source API: branche `ph147.4/source-of-truth`, HEAD `547648fd`, non-dist dirty 0.

| Source audit | Attendu | Resultat |
| --- | --- | --- |
| event_name trial_page_viewed | custom attendu | OK, `trial_page_viewed` mappe vers `trial_page_viewed` |
| pixel id source | destination config | OK, `dest.platform_pixel_id` |
| token source | destination config/secret, jamais hardcode | OK, `dest.platform_token_ref` decrypte pour provider |
| click id absent handling | acceptable direct manual | OK, fbc/fbp/fbclid optionnels; direct manual coherent |
| event_source_url | http/https requis | OK, source canonical ou landing_url valide |
| missing user_data classification | separee | OK, classification dediee `META_MISSING_USER_DATA` |
| invalid pixel/token classification | coherente | OK, classification dediee `META_INVALID_PIXEL_OR_TOKEN` |
| event-specific token/pixel override | absent | OK, pas d'override specifique trial_page_viewed |

Lignes source observees en lecture seule:

- `src/modules/outbound-conversions/adapters/meta-capi.ts`: mapping `trial_page_viewed`, user_data, fbc/fbp, event_source_url.
- `src/modules/outbound-conversions/emitter.ts`: lookup destination, `platform_pixel_id`, `platform_token_ref`, decrypt token, `sendToMetaCapi`.
- `src/modules/outbound-conversions/lib/provider-error-normalizer.ts`: classification invalid pixel/token separee de missing user_data.
- Tests PH-21.79 et PH-21.107 presents pour non-regression mapping et redaction.

Decision source: pas de source patch prouve pour cette RCA.

## Logs safe

| Logs API PROD | Attendu | Resultat |
| --- | --- | --- |
| crash/panic/fatal | 0 | 0 |
| strong secret pattern | 0 | 0 |
| raw provider body expose | 0 | 0 |
| trial_page_viewed markers | count safe | 0 dans logs fenetre lues |
| Meta CAPI markers | count safe | 0 dans logs fenetre lues |
| provider error normalized | count safe | 0 dans logs fenetre lues |
| retry/replay | 0 | 0 |

Note: la preuve principale de delivery vient de la table de delivery logs, pas des logs runtime conserves.

## Pollution check / No fake metrics

| Controle | Attendu | Resultat |
| --- | --- | --- |
| POST /funnel/event CE | 0 | 0 |
| retry/replay CAPI | 0 | 0 |
| CAPI test endpoint | 0 | 0 |
| formulaire /register | 0 | 0 |
| checkout Stripe | 0 | 0 |
| StartTrial window | 0 | 0 |
| Purchase window | 0 | 0 |
| CompletePayment window | 0 | 0 |
| DB mutation volontaire | 0 | 0 |

## AI feature parity / anti-regression

| Surface IA | Attendu | Resultat |
| --- | --- | --- |
| PROVIDER_CREDIT_EXHAUSTED | present runtime | non modifie |
| llm-provider-errors | present runtime | non modifie |
| dist/tests | absent runtime selon chaine precedente | non modifie |
| appel LLM | 0 | 0 |
| ai_usage window | 0 mutation | 0 |
| ai_actions_ledger window | 0 mutation | 0 |
| provider_credit_exhausted total | pas de nouveau signal | 0 |
| regression IA visible | 0 | 0 |

## Non-regression services

| Service | Runtime observe | Resultat |
| --- | --- | --- |
| API PROD | v3.5.265, digest ca11a4..., ready 1/1, restarts 0 | inchange |
| API DEV | v3.5.265 dev, digest a19fbf..., ready 1/1, restarts 0 | inchange |
| Client PROD | v3.5.260 prod, digest c24457..., ready 1/1, restarts 0 | inchange |
| Client DEV | v3.5.260 dev, digest 0e8675..., ready 1/1, restarts 0 | inchange |
| Website PROD | v0.7.2 visual hero parity, ready 2/2 | inchange |
| Website DEV | v0.7.1 hero copy prod body parity, ready 1/1 | inchange |
| Admin PROD/DEV | runtimes observes, ready 1/1 | inchange |
| Backend PROD/DEV | runtimes observes, ready 1/1 | inchange |

## Cause probable

| Cause | Confiance | Preuves | Contre-preuves | Prochaine action |
| --- | --- | --- | --- | --- |
| META_TOKEN_OR_PIXEL_REJECTED_BY_PROVIDER | HIGH | HTTP 400, classification `META_INVALID_PIXEL_OR_TOKEN`, provider code safe 190, pixel/token metadata presents, owner routing OK, source utilise destination config | Pas de lecture token brut ni console Meta, donc sous-cause exacte non prouvable par CE | ACTION_REQUIRED_META_CONFIG |
| META_TOKEN_MISSING_OR_UNSYNCED | LOW | token metadata only a verifier hors code | token ref present, long/encrypted-or-long | non retenu sauf si Ops confirme secret/token non valide |
| META_PIXEL_CONFIG_INVALID | LOW/MEDIUM | possible cote Meta si pixel/dataset inactive ou permission retiree | pixel present et endpoint coherent metadata-only | verifier Pixel/Dataset dans Meta |
| OWNER_ROUTING_DESTINATION_MISMATCH | LOW | aucune | owner KBC OK | non retenu |
| DESTINATION_RESOLUTION_BUG | LOW | aucune | destination trouvee via delivery | non retenu |
| TRIAL_PAGE_VIEWED_PAYLOAD_MAPPING_BUG | LOW | aucune preuve | source mapping OK, classification missing user_data separee | non retenu |
| META_MISSING_USER_DATA_DESPITE_CLASSIFICATION | LOW | direct manual sans click id | provider code/classification pointe pixel/token, pas user_data | non retenu |
| RCA_INSUFFICIENT_NEEDS_OPS_META_CHECK | LOW/MEDIUM | sous-cause exacte Meta necessite console/token | cause generale provider config suffisante | seulement si Ops exige preuve Meta console |

## Prochaine action

Action recommandee: `ACTION_REQUIRED_META_CONFIG`.

Procedure attendue hors CE:

1. Ludovic/Ops/Antoine verifie dans Meta Business que le Pixel/Dataset masque `123...748` est le bon pour `keybuzz-consulting-mo9zndlk`.
2. Verifier que le token CAPI associe a la destination KBC est actif, non expire/revoque, et autorise sur ce pixel/dataset.
3. Si doute, regenerer/remplacer le token via le flux officiel deja utilise pour `platform_token_ref`, sans afficher le secret.
4. Apres correction config, refaire un vrai trafic humain avec owner/UTM et relancer une phase read-only observe.

Prochain GO recommande:

`ACTION_REQUIRED_META_CONFIG`, puis apres correction config:

`GO READONLY OBSERVE META CAPI TRIAL_PAGE_VIEWED REAL TRAFFIC PROD AFTER META CONFIG FIX PH-SAAS-T8.12AS.21.122`

## Controle final

| Controle | Resultat |
| --- | --- |
| secret/token brut affiche | 0 |
| payload provider brut affiche | 0 |
| PII affichee | 0 |
| POST /funnel/event | 0 |
| retry/replay delivery | 0 |
| CAPI test | 0 |
| DB mutation | 0 |
| build/docker push/deploy/apply | 0 |
| Linear mutation | 0 |
