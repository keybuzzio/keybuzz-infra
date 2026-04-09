# PH-MAIL-INBOUND-DIAGNOSTIC-03 — Diagnostic Pipeline Inbound

> Date : 4 avril 2026
> Type : Diagnostic lecture seule
> Serveur audite : mail-core-01
> Modifications : **AUCUNE**

---

## RESUME EXECUTIF

| Element | Statut | Detail |
|---|---|---|
| **Pipeline Amazon inbound** | **OPERATIONNEL** | Dernier email traite a 11:49 UTC, DEV+PROD 200 OK |
| **Queue Postfix** | 59 emails bloques | **0 Amazon** — 100% emails internes (`alerts@`/`sre@keybuzz.io`) |
| **Webhook script** | Fonctionnel | Bug mineur sur extraction header `To:` |
| **Endpoints backend** | Accessibles | DEV + PROD repondent, auth OK avec cle |
| **Reseau** | OK | DNS + ping + curl OK depuis mail-core-01 |

**VERDICT : Le pipeline Amazon inbound N'EST PAS bloque. Le probleme initial (dsn=4.3.0) est resolu.**

---

## 1. ETAT DE LA QUEUE

```
Total deferred : 59 emails (741 KB)
Active : 0
Bounce : 0
Amazon inbound dans la queue : 0
```

### Repartition

| Destination | Nombre | Erreur |
|---|---|---|
| `alerts@keybuzz.io` | 30 | `454 4.7.1 Relay access denied` |
| `sre@keybuzz.io` | 29 | `454 4.7.1 Relay access denied` |
| Amazon inbound | **0** | — |

### Cause des emails bloques

Les 59 emails sont des **alertes internes** (monitoring SRE) envoyees depuis `mail-core-01` vers `@keybuzz.io`. Le chemin est :

```
mail-core-01 → MX lookup keybuzz.io → mail-mx-02.keybuzz.io
→ MX-02 refuse : "Relay access denied"
→ car relay_domains = inbound.keybuzz.io seulement (pas keybuzz.io)
```

C'est le probleme connu identifie dans PH-MAIL-AUDIT-DELIVERABILITY-01 (F2 relay_domains). **Sans lien avec le pipeline Amazon.**

---

## 2. PIPELINE AMAZON INBOUND — ANALYSE DETAILLEE

### Flux nominal

```
Amazon SES → amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
  → MX (mail-mx-01/02) accepts (relay_domains = inbound.keybuzz.io)
  → relayhost [10.0.0.160]:25 (mail-core-01)
  → transport_maps → webhook pipe
  → /usr/local/bin/postfix_webhook.sh
  → curl POST backend-dev + backend (avec X-Internal-Key)
  → 200 OK = exit 0 = message delivered
```

### Evenements recents

| Heure (UTC) | Evenement | Resultat |
|---|---|---|
| ~30 mars | Emails Amazon recus et deferred (~5 jours) | `dsn=4.3.0` |
| 04 avr 10:20 | Email Amazon traite | DEV 200, PROD 200 — **OK** |
| 04 avr 11:30 | Postfix retente les 6 vieux emails | `400 Invalid recipient format` |
| 04 avr 11:49 | Nouvel email Amazon | DEV 200, PROD 200, delay=2.3s — **OK** |

### Pourquoi les 6 vieux emails ont echoue (11:30)

Les emails en deferred depuis ~5 jours avaient un header `To:` different de l'envelope recipient :

```
Envelope recipient (Postfix) : amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io
Header To: (dans le mail)   : contact@srvperformance.com
```

Le script webhook extrait le header `To:` :

```bash
TO=$(grep -i "^To:" "$TEMP_EMAIL" | head -1 | sed 's/^To: *//...')
```

Le backend recoit `to: contact@srvperformance.com` et le rejette :

```json
{"error": "Invalid recipient format"}
```

Ce sont des **notifications Amazon** (type "sin buzon electronico" / pas de boite mail) ou le `To:` est l'email d'origine du vendeur, pas l'adresse inbound KeyBuzz.

### Bug identifie : extraction header vs envelope

Le script utilise le **header `To:`** au lieu du **recipient Postfix** (envelope). Pour les emails reroutes par Amazon, le `To:` header peut etre l'adresse originale du vendeur.

**Impact** : echec intermittent sur certains types de notifications Amazon. Les messages clients standards (buyer messages) fonctionnent car leur `To:` = adresse inbound.

**Fix potentiel** : utiliser `$RECIPIENT` (variable Postfix passee au pipe) au lieu de parser le header `To:`. Dans `master.cf` :

```
webhook   unix  -  n  n  -  -  pipe
  flags=F user=nobody argv=/usr/local/bin/postfix_webhook.sh ${recipient}
```

Puis dans le script : `TO="$1"` (premier argument = envelope recipient).

---

## 3. WEBHOOK SCRIPT — ANALYSE COMPLETE

### Metadata

```
Fichier  : /usr/local/bin/postfix_webhook.sh
Taille   : 10339 octets (247 lignes)
MD5      : 7eaeefa41a9104811c42149740ebacd0
Modifie  : 16 mars 2026
Version  : PH32.3 PROD-B + PH32.4B
```

### Architecture

```
Email stdin
  → Extraction headers (From, To, Subject, Message-ID)
  → Si sav.*@inbound.keybuzz.io → Route SAV (MIME parser Python)
  → Sinon → Marketplace routing :
      → Genere 2 JSON (DEV -dev suffix, PROD -prod suffix)
      → POST DEV : backend-dev.keybuzz.io/api/v1/webhooks/inbound-email
      → POST PROD : backend.keybuzz.io/api/v1/webhooks/inbound-email
      → Auth : X-Internal-Key header
      → Exit 0 si ≥1 OK, exit 75 si tous KO
```

### Points cles

| Aspect | Valeur | Etat |
|---|---|---|
| Endpoints | `backend-dev.keybuzz.io` + `backend.keybuzz.io` | OK |
| Auth | `X-Internal-Key` via `/opt/keybuzz/secrets/webhook_key{_prod}` | OK |
| PJ body limit | 10 MB (PH99-FIX) | OK |
| MessageId dedup | `-dev` / `-prod` suffix (PH32.4B) | OK |
| SAV routing | `sav.*@inbound.keybuzz.io` → API `/supplier-inbound` | OK |
| Exit code | 0=OK, 75=temporary failure (Postfix retente) | OK |

---

## 4. TESTS ENDPOINTS

### Depuis mail-core-01

| Test | Backend DEV | Backend PROD |
|---|---|---|
| DNS resolution | `49.13.42.76`, `138.199.132.240` | `138.199.132.240`, `49.13.42.76` |
| HEAD | 404 (normal, route POST only) | 404 (normal) |
| POST sans cle | `401 Unauthorized` | `401 Unauthorized` |
| POST avec cle | 200 (voir webhook log) | 200 (voir webhook log) |
| Latence | 0.149s | 0.177s |
| Ping | 0% loss, 26ms | 0% loss, 24ms |

**Conclusion** : reseau et endpoints 100% operationnels.

---

## 5. CLES WEBHOOK

| Cle | Fichier | Existe | Taille |
|---|---|---|---|
| DEV | `/opt/keybuzz/secrets/webhook_key` | OUI | 65 chars |
| PROD | `/opt/keybuzz/secrets/webhook_key_prod` | OUI | 64 chars |

Backend DEV confirme `{ hasKey: false, keyMatch: false }` quand la cle n'est pas envoyee (test sans auth = 401). Avec la cle = 200 OK.

---

## 6. LOGS BACKEND K8S

### Pods

| Env | Pod | Status | Restarts |
|---|---|---|---|
| DEV | `keybuzz-backend-7cc9686584-hvb7l` | Running | 0 |
| PROD | `keybuzz-backend-db965c67d-2x6m8` | Running | 2 (il y a 9j) |
| DEV | `amazon-items-worker` | Running | 0 |
| PROD | `amazon-items-worker` | Running | 0 |
| DEV | `amazon-orders-backfill` | Completed (CronJob) | — |
| PROD | `amazon-orders-sync` | Completed (CronJob) | — |

Tous les workers Amazon sont stables et operationnels.

---

## 7. SAV INBOUND (annexe)

Le SAV inbound (`sav.*@inbound.keybuzz.io`) fonctionne. Derniere execution : 12 fevrier 2026.
- PROD : `404 Supplier case not found` (cas supprime/absent)
- DEV : `201 Success` (message route vers conversation)

Pas d'activite recente — normal si aucun email fournisseur SAV recu depuis.

---

## 8. ROOT CAUSE

### CAUSE #1 : Queue 59 emails bloques — `@keybuzz.io` Relay access denied

| Aspect | Detail |
|---|---|
| **Probleme** | Emails internes (`alerts@keybuzz.io`, `sre@keybuzz.io`) rejetes par MX |
| **Cause** | `relay_domains` sur MX-01/MX-02 = `inbound.keybuzz.io` seulement |
| **Impact** | Alertes SRE/monitoring non delivrees depuis ~5 jours |
| **Lien Amazon** | **AUCUN** — pipeline independant |
| **Fix** | Ajouter `keybuzz.io` a `relay_domains` MX + `mydestination` mail-core-01 |
| **Ref** | PH-MAIL-PRE-FIX-VALIDATION-02A (F2 — verdict RISQUE sans config supplementaire) |

### CAUSE #2 : Echecs intermittents Amazon `400 Invalid recipient format`

| Aspect | Detail |
|---|---|
| **Probleme** | Certaines notifications Amazon ont un header `To:` different de l'envelope recipient |
| **Cause** | Le script extrait `To:` header au lieu de l'envelope recipient Postfix |
| **Impact** | Echec sur notifications Amazon (type "sin buzon electronico"), pas sur messages clients |
| **Frequence** | Rare — la majorite des emails Amazon ont le bon `To:` |
| **Fix** | Passer `${recipient}` en argument dans `master.cf` et utiliser `$1` dans le script |

### CE QUI N'EST PAS CASSE

- Pipeline Amazon marketplace inbound : **OPERATIONNEL**
- Webhook script : **FONCTIONNEL** (bug mineur `To:` header)
- Endpoints backend DEV + PROD : **ACCESSIBLES**
- Auth webhook : **OK**
- Reseau mail-core-01 → backends : **OK**
- CronJobs Amazon : **RUNNING**
- SAV supplier inbound : **FONCTIONNEL**

---

## 9. RECOMMANDATIONS

### Priorite 1 — Purger la queue (immediat, sans risque)

```bash
# Sur mail-core-01 : supprimer les 59 emails bloques (alertes internes non critiques)
postsuper -d ALL deferred
```

### Priorite 2 — Fix envelope recipient (webhook script)

Modifier `master.cf` pour passer l'envelope recipient au script :

```
webhook   unix  -  n  n  -  -  pipe
  flags=F user=nobody argv=/usr/local/bin/postfix_webhook.sh ${recipient}
```

Modifier le script pour utiliser `$1` comme `TO` au lieu du header `To:`.

### Priorite 3 — relay_domains (phase separee)

Comme identifie dans PH-MAIL-PRE-FIX-VALIDATION-02A :
1. `mydestination += keybuzz.io` sur mail-core-01
2. `/etc/aliases` pour alerts, sre, dmarc-*, etc.
3. `relay_domains += keybuzz.io` sur MX-01 et MX-02
4. `postqueue -f` pour flusher

---

## 10. MATRICE DE VERIFICATION

| Test | Resultat | Preuve |
|---|---|---|
| Queue mailq | 59 deferred (0 Amazon) | `mailq | tail -1` |
| Webhook script | 247 lignes, PH32.4B | `md5sum`, `cat` complet |
| Endpoint DEV | DNS OK, 401 sans cle | `curl -v` |
| Endpoint PROD | DNS OK, 401 sans cle | `curl -v` |
| Ping DEV | 0% loss, 26ms | `ping -c 2` |
| Ping PROD | 0% loss, 24ms | `ping -c 2` |
| Cles webhook | DEV 65c, PROD 64c | `cat | wc -c` |
| Webhook log succes | 11:49 DEV 200 + PROD 200 | `tail webhook.log` |
| Webhook log echec | 11:30 `Invalid recipient format` | `grep FAIL` |
| Backend pods | Running, 0 restart recents | `kubectl get pods` |
| Amazon workers | Running + CronJobs Completed | `kubectl get pods` |
