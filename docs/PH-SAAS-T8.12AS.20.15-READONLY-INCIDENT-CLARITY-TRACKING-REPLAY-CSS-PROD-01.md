# PH-SAAS-T8.12AS.20.15-READONLY-INCIDENT-CLARITY-TRACKING-REPLAY-CSS-PROD-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; reference KEY-322 (Clarity website activation) / KEY-323 (Amazon restored) / KEY-325 (Clarity client deferred)
> Phase : PH-SAAS-T8.12AS.20.15 (READONLY INCIDENT CLARITY TRACKING + REPLAY CSS)
> Environnement : PROD (lecture seule ; aucun patch, build, deploy, header/CSP/DNS change)

## 1. Verdict

GO READONLY INCIDENT CLARITY TRACKING REPLAY CSS PROD READY PH-SAAS-T8.12AS.20.15

Root cause identifiee avec preuve : le build website PROD v0.6.21-pricing-action-recover (PH-20.10B, deploye 2026-05-22 16:23 UTC) a ete construit avec NEXT_PUBLIC_CLARITY_PROJECT_ID = (vide). Le bundle compile a donc dead-code-elimine l'injection Clarity (ClarityProvider retourne null si l'ID est vide). Resultat : depuis le 2026-05-22, Microsoft Clarity n'est plus injecte sur keybuzz.pro / www.keybuzz.pro -> 0 nouvelle donnee. Le build precedent v0.6.19-cta-tracking (deploye 2026-05-21) contenait encore Clarity (wrff07upjx, 2 occurrences bundle). Le symptome "replay sans CSS" est secondaire : les seuls recordings disponibles sont anterieurs au 05-22 et referencent des assets CSS hashes immutables qui renvoient desormais 404 apres le redeploy (rotation de hash), comportement inherent a Clarity. client.keybuzz.io n'a jamais eu Clarity active (KEY-325 differe) : zero donnee par design, pas une regression. Fix minimal = rebuild + redeploy website PROD AVEC le build-arg Clarity. Source intacte, aucun patch code requis.

## 2. Preflight (E0)

Bastion install-v3 / 46.62.171.61 confirme ; date UTC 2026-05-26 18:58.

| Repo/service | branch/runtime | HEAD/image | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-infra | main | c0d21db = origin | clean | OK |
| keybuzz-website | main | 907689b = origin | clean | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ef239e8 = origin | tsconfig.tsbuildinfo (artefact build, benin) | OK |
| keybuzz-website PROD runtime | v0.6.21-pricing-action-recover-prod | 2/2 ready | - | suspect (voir RCA) |
| keybuzz-client PROD runtime | v3.5.215-ai-draft-blocked-reason-prod | 1/1 ready | - | OK (pas de Clarity attendu) |

## 3. Source Clarity (E1)

| Source | occurrence | interpretation | verdict |
|---|---|---|---|
| keybuzz-website src/components/ClarityProvider.tsx | injection clarity.ms/tag/${ID}, strategy afterInteractive | inject keybuzz.pro uniquement, gate consent opt-in + ID build-time | OK source |
| ClarityProvider : if (!CLARITY_PROJECT_ID) return null | ID vide => no-op total | si build sans ID -> Clarity dead-code-elimine | cause racine |
| keybuzz-website Dockerfile L28/L41 | ARG NEXT_PUBLIC_CLARITY_PROJECT_ID= (defaut vide) + ENV | build-arg obligatoire, defaut vide silencieux | footgun connu |
| keybuzz-website src/app/cookies/page.tsx | "Clarity jamais charge sur client.keybuzz.io / admin" | Clarity = website public seulement | OK design |
| keybuzz-client src/components/tracking/SaaSAnalytics.tsx | Clarity route-gated funnel-only (PH-20.2 KEY-339) | activable seulement si NEXT_PUBLIC_CLARITY_PROJECT_ID build client | client non active (KEY-325) |
| keybuzz-client manifest env | aucune var CLARITY | confirme client non instrumente | OK design |
| CSP / script-src / connect-src custom | aucune trouvee (website + headers live) | pas de CSP bloquant Clarity | ecarte |

## 4. Live HTML keybuzz.pro (E2)

| Check | expected | actual | verdict |
|---|---|---|---|
| GET https://keybuzz.pro/ | 200 | HTTP/2 200, content-type text/html | OK |
| GET https://www.keybuzz.pro/ | 200 | HTTP/2 200 (sert direct) | OK |
| Header Content-Security-Policy | absent ou autorise clarity | ABSENT (aucune CSP) | pas de blocage CSP |
| Header X-Frame-Options / CORP / COEP / COOP | absent ou compatible | ABSENT sur HTML | pas de blocage |
| Cache-Control HTML | court | s-maxage=31536000 (cache edge) | note : HTML cache long (CDN) |
| snippet clarity.ms/tag dans bundle JS | present si actif | ABSENT (13 chunks echantillonnes, 0 ref) | Clarity NON injecte |
| Project ID wrff07upjx dans bundle | present si actif | ABSENT | Clarity NON injecte |

## 5. Live HTML client.keybuzz.io (E3)

| Check | expected | actual | verdict |
|---|---|---|---|
| GET https://client.keybuzz.io/ | 200 ou redirect login | HTTP/2 307 -> /auth/signin | OK (login gate) |
| Clarity dans env manifest client-prod | 0 (KEY-325 differe) | aucune var CLARITY | OK design, jamais active |
| Clarity sur app authentifiee | 0 (interdit par design) | n/a | OK design |
| funnel pages (register) Clarity | conditionne a build ID client | non active (KEY-325) | pas une regression |

## 6. CSS / assets replay (E4)

| Asset | status | content-type | blocking header | verdict |
|---|---|---|---|---|
| keybuzz.pro /_next/static/chunks/e3da45de9eaef36b.css | 200 | text/css; charset=UTF-8 | aucun (pas de CORP/COEP/CORS) | asset sain |
| cache-control CSS | immutable | public, max-age=31536000, immutable | hash rotation au redeploy | cause replay no-CSS secondaire |

Interpretation : le CSS public est servi correctement (200, text/css, aucun header bloquant cross-origin). Le "replay sans CSS" n'est donc PAS un blocage CSP/CORP. C'est la consequence du hash immutable : les recordings anterieurs au redeploy v0.6.21 referencent d'anciens hash CSS qui renvoient 404 (asset rotate), donc le replay Clarity ne retrouve plus le style. Combine a l'arret d'injection (cause 1), seuls de vieux recordings sans CSS restent visibles.

## 7. CSP / headers (E6/E7)

| Config | value | risk | verdict |
|---|---|---|---|
| CSP keybuzz.pro | absente | aucun blocage script/connect clarity.ms | ecarte |
| CORP/COEP/COOP assets | absents | replay Clarity peut fetch CSS cross-origin | ecarte |
| robots/noindex | non pertinent (HTML 200) | - | ecarte |
| domaines Clarity (www/c/j.clarity.ms) | non charges car script absent | n/a tant que Clarity non injecte | depend de cause 1 |

## 8. Deploy correlation (E6)

| Commit/deploy | date UTC | image | impact | verdict |
|---|---|---|---|---|
| ff3a4d9 deploy website PROD | 2026-05-21 16:03 | v0.6.19-cta-tracking-prod | build-arg CLARITY = wrff07upjx (PH-20.3 : bundle Clarity 2 occ) | Clarity ACTIF |
| 576e977 deploy PH-20.8 CMP mobile | 2026-05-22 09:29 | v0.6.20 CMP | bandeau consent (KEY-344) | a verifier mais surclasse par v0.6.21 |
| 93d7e84 bump PH-20.10B pricing | 2026-05-22 16:23 | v0.6.21-pricing-action-recover-prod | build-arg CLARITY = (vide) (rapport PH-20.10B E3) | Clarity DROPPE = cause racine |

Fenetre incident : depuis 2026-05-22 16:23 UTC (~4 jours), coherent avec "2-3 jours" rapporte par Ludovic.

## 9. RCA et options de correction (E10)

Cause probable 1 (PRIMAIRE, confiance HAUTE) : le build website PROD v0.6.21 (PH-20.10B) a omis --build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID=wrff07upjx -> compile avec ID vide -> ClarityProvider no-op -> 0 injection Clarity sur keybuzz.pro depuis le 2026-05-22. Preuves : rapport build PH-20.10B E3 = "NEXT_PUBLIC_CLARITY_PROJECT_ID | (vide)" ; bundle live = 0 reference clarity.ms/tag / wrff07upjx ; v0.6.19 (precedent) avait 2 occurrences. Impact : keybuzz.pro audience/heatmap/replay aveugle depuis ~4 jours.

Cause probable 2 (SECONDAIRE, confiance MOYENNE) : "replay sans CSS" = recordings anterieurs au redeploy referencent des hash CSS immutables desormais 404 (rotation de hash au build v0.6.21) ; comportement inherent Clarity. L'asset CSS courant est sain (200, text/css, aucun header bloquant). Se resout de lui-meme des que de nouveaux recordings sont captures apres le fix.

Cause probable 3 (CONTEXTE, pas une regression) : client.keybuzz.io n'a jamais eu Clarity active (KEY-325 differe, NEXT_PUBLIC_CLARITY client = 0). Zero donnee par design. Le symptome "client.keybuzz.io" est une attente erronee, pas une panne.

Fix minimal : rebuild + push + GitOps redeploy website PROD depuis la source actuelle (HEAD 907689b, ClarityProvider + Dockerfile ARG/ENV intacts) AVEC --build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID=wrff07upjx (+ les autres build-args marketing iso baseline v0.6.19 : GA_ID, META_PIXEL_ID, SGTM_URL, TIKTOK_PIXEL_ID, LINKEDIN_PARTNER_ID). Aucun patch code. Risque : faible (re-active un comportement deja valide en v0.6.13-v0.6.19).

Durcissement (recommande) : ajouter NEXT_PUBLIC_CLARITY_PROJECT_ID au script/recette de build website standard pour que les futurs builds ne droppent plus silencieusement Clarity (le defaut vide du Dockerfile est un footgun ; meme classe que l'incident build-arg client).

Ordre de traitement : (1) rebuild+promote website PROD avec build-arg Clarity (restaure keybuzz.pro) ; (2) post-fix, QA Ludovic : avant consent 0 requete, apres consent requete clarity.ms/tag/wrff07upjx + nouveau recording AVEC CSS ; (3) durcir le script de build ; (4) decision produit separee KEY-325 si activation Clarity sur funnel client souhaitee.

Prochaines phases possibles :
- GO BUILD/PROMOTE WEBSITE CLARITY FIX PROD PH-SAAS-T8.12AS.20.15B (rebuild website avec build-arg Clarity).
- GO READONLY CLARITY MICROSOFT PROJECT CONFIG AUDIT PH-SAAS-T8.12AS.20.15B (handoff Ludovic dashboard wrff07upjx pour confirmer freshness + replay post-fix).

## 10. No fake metrics / no fake events (E11)

| Garantie | etat |
|---|---|
| fake Clarity event | 0 |
| fake pageview / session | 0 |
| synthetic conversion | 0 |
| mutation analytics | 0 |
| DB mutation | 0 |
| tracking backfill | 0 |
| script Clarity injecte manuellement | 0 |
| trafic artificiel | 0 (uniquement curl read-only ponctuel) |

## 11. AI feature parity / anti-regression (E12)

| Garantie | etat |
|---|---|
| Inbox / Amazon connector / AI suggestions / KBActions | non touches |
| outbound/inbound pipeline PH-20.14 runtime Amazon | non touche |
| KEY-323 ecomlg-001 FR (inbound VALIDATED + outbound delivered) | preserve |
| keybuzz-client / keybuzz-api / backend runtime | inchanges |
| Aucun build/deploy/kubectl/patch/DNS/CSP | confirme (phase read-only) |

## 12. Deferred Amazon duplicate (E9)

Hors scope de cette phase. A noter : messages Amazon dupliques observes depuis environ 15h52 (sujet probable : dedup inbound / tokens 4xfub8 vs 3jcpvk / conversations dupliquees - deja documente PH-20.14V/AD). NE PAS corriger maintenant. Prochain audit recommande apres Clarity : GO READONLY AMAZON INBOUND DUPLICATE MESSAGES PROD PH-SAAS-T8.12AS.20.16. P0 Amazon ecomlg-001 FR reste restaure (ne pas rouvrir).

## 13. Clarity data freshness (E8)

| Evidence | source | verdict |
|---|---|---|
| capture utilisateur (page HTML brute sans CSS) | Ludovic | coherent avec cause 1 + cause 2 |
| dashboard Clarity wrff07upjx freshness / dernier event | Microsoft Clarity (login requis) | NON verifiable sans login - handoff Ludovic |
| bundle live keybuzz.pro | curl read-only | 0 injection Clarity (preuve cote serveur) |

Limitation : la confirmation du dernier event recu cote projet Microsoft Clarity wrff07upjx exige un login Microsoft (non realise, conforme aux regles). Handoff Ludovic recommande pour confirmer la date du dernier event (devrait correspondre a ~2026-05-22) et valider le replay post-fix.

## 14. Prochaine phase (E15)

GO BUILD/PROMOTE WEBSITE CLARITY FIX PROD PH-SAAS-T8.12AS.20.15B : rebuild + push + GitOps website PROD depuis HEAD 907689b avec --build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID=wrff07upjx (+ build-args marketing iso v0.6.19), puis QA consent + recording. Durcir ensuite le script de build website.

## 15. Phrase cible

GO READONLY INCIDENT CLARITY TRACKING REPLAY CSS PROD READY PH-SAAS-T8.12AS.20.15

STOP.
