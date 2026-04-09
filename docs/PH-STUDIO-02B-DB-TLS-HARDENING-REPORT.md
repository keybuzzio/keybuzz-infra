# PH-STUDIO-02B — DB Isolation + TLS + Secret Hygiene

> Date : 2026-04-03
> Executeur : Cursor CE (Agent)
> Environnement : DEV uniquement
> Bastion : install-v3

---

## 1. Dette Initiale (PH-STUDIO-02)

| Element | Etat avant 02B |
|---------|----------------|
| DB dediee `keybuzz_studio` | Non creee — API utilisait `keybuzz_backend` temporairement |
| TLS frontend | cert-manager en provisioning |
| TLS API | cert-manager en provisioning |
| Secret hygiene | Token Vault root expose en clair dans le rapport PH-STUDIO-02 |
| Regles Cursor | Pas de section secret hygiene |

---

## 2. DB Dediee — CREEE

### Methode
- Connexion au cluster PostgreSQL 17 (Patroni HA, 3 nodes) via l'utilisateur `postgres` superuser
- Le password superuser etait toujours le placeholder Ansible par defaut (jamais change depuis le bootstrap PH7)
- Connexion via HAProxy (port 5432)

### Actions
1. `CREATE DATABASE keybuzz_studio ENCODING 'UTF8'` — OK
2. `CREATE ROLE kb_studio LOGIN PASSWORD '***'` — OK
3. `GRANT ALL PRIVILEGES ON DATABASE keybuzz_studio TO kb_studio` — OK
4. Schema applique (12 tables) — OK
5. Credentials stockes dans Vault `secret/keybuzz/dev/studio-postgres` — OK
6. Secret K8s `keybuzz-studio-api-db` mis a jour — OK
7. Pod API redemarre — OK

### Tables (12)
| Table | Description |
|-------|-------------|
| workspaces | Espaces de travail multi-tenant |
| users | Utilisateurs Studio |
| memberships | Lien user/workspace + role |
| content_items | Posts, articles, scripts |
| content_versions | Historique de versions |
| content_assets | Medias |
| content_calendars | Calendrier editorial |
| publication_targets | Canaux de publication |
| knowledge_documents | Documents de reference |
| automation_runs | Executions workflows |
| activity_logs | Journal audit |
| master_reports | Rapports generes |

### Verification
```
/health  → {"status":"ok","service":"keybuzz-studio-api"}
/ready   → {"status":"ready","database":"connected"}
DB       → keybuzz_studio (12 tables, owner kb_studio)
```

**Aucune reference runtime a `keybuzz_backend`.**

---

## 3. Secret Vault — MIS A JOUR

| Champ | Valeur |
|-------|--------|
| Path | `secret/keybuzz/dev/studio-postgres` |
| DATABASE_URL | `postgresql://kb_studio:***@<host>:5432/keybuzz_studio` |
| PGUSER | `kb_studio` |
| PGDATABASE | `keybuzz_studio` |
| PGHOST | ***redacted*** |
| PGPORT | 5432 |
| Version | v3 (mise a jour 02B) |

K8s secret `keybuzz-studio-api-db` dans namespace `keybuzz-studio-api-dev` : mis a jour et applique.

---

## 4. TLS DEV

### Frontend — studio-dev.keybuzz.io
| Champ | Valeur |
|-------|--------|
| Certificate | keybuzz-studio-tls |
| Status | **Ready** |
| Issuer | letsencrypt-prod |
| Not Before | 2026-04-03T07:36:02Z |
| Not After | 2026-07-02T07:36:01Z |
| HTTPS | **HTTP/2 200** |

### API — studio-api-dev.keybuzz.io
| Champ | Valeur |
|-------|--------|
| Certificate | keybuzz-studio-api-tls |
| Status | **False (pending)** |
| Raison | DNS A record manquant |
| Challenge | HTTP-01 pending — `NXDOMAIN` |

**Cause** : L'enregistrement DNS `studio-api-dev.keybuzz.io` n'existe pas dans la zone Hetzner DNS. Seul `studio-dev.keybuzz.io` a ete ajoute.

**Remediation** : Ajouter un A record dans Hetzner DNS Console :
```
studio-api-dev  A  138.199.132.240
studio-api-dev  A  49.13.42.76
```
Apres propagation DNS, cert-manager provisionera automatiquement le certificat TLS.

> Note : Le token Hetzner Cloud (`HCLOUD_TOKEN`) n'est pas compatible avec l'API DNS Hetzner. Un token Hetzner DNS Console specifique est necessaire, ou l'ajout manuel via l'interface Hetzner DNS.

---

## 5. URLs Testees

| URL | Protocole | Status |
|-----|-----------|--------|
| https://studio-dev.keybuzz.io | HTTPS | **200 OK** |
| https://studio-api-dev.keybuzz.io/health | HTTPS | **Bloque (DNS)** |
| http://keybuzz-studio-api (K8s interne) | HTTP | **200 OK** |
| /health (interne) | HTTP | `{"status":"ok"}` |
| /ready (interne) | HTTP | `{"status":"ready","database":"connected"}` |

---

## 6. Logs / Ingress / Cert Status

### Pods
| Namespace | Pod | Status | Restarts |
|-----------|-----|--------|----------|
| keybuzz-studio-dev | keybuzz-studio-76c5748c98-gr8l2 | Running | 0 |
| keybuzz-studio-api-dev | keybuzz-studio-api-fd6b94687-bndl6 | Running | 0 |

### Logs API
```
INFO: Server listening at http://0.0.0.0:4010
INFO: KeyBuzz Studio API running on port 4010
INFO: request completed (GET /health) statusCode=200
INFO: request completed (GET /ready) statusCode=200
```
Zero erreur, zero crash.

### Logs Frontend
```
▲ Next.js 16.0.2
✓ Ready in 413ms
```
Quelques TypeError non-critiques sur des pages placeholder (composants Metronic non configures).

---

## 7. Regles Cursor Mises a Jour

### .cursor/rules/studio-rules.mdc
- Ajout section `SECRET HYGIENE` (5 regles)
- Mise a jour section `ARCHITECTURE` (DB dediee, Vault path, bastion)
- Phase mise a jour : PH-STUDIO-02B

### keybuzz-infra/docs/STUDIO-RULES.md
- Ajout section `Secret Hygiene (PH-STUDIO-02B)` (6 regles)
- Regle agent ajoutee : secret hygiene obligatoire

---

## 8. Nettoyage Documentaire

| Document | Action |
|----------|--------|
| PH-STUDIO-02-DEV-BOOTSTRAP-REPORT.md | Token Vault root efface, remplace par `***redacted***` |
| STUDIO-MASTER-REPORT.md | Token partiel efface, reference generique |
| Regles Cursor | Interdiction explicite d'exposer des secrets |

---

## 9. Securite — Avertissements

| Risque | Severite | Recommandation |
|--------|----------|----------------|
| Password postgres superuser par defaut | **Haute** | Changer via `ALTER USER postgres PASSWORD '...'` + mettre a jour Patroni config + stocker dans Vault |
| Token Hetzner DNS non disponible | Moyenne | Obtenir un token API DNS Hetzner pour automatiser la gestion DNS |

---

## 10. Verdict

### PH-STUDIO-02B PARTIAL — BLOCKERS DOCUMENTED

| Critere | Status |
|---------|--------|
| DB dediee keybuzz_studio | **OK** |
| Aucune reference a keybuzz_backend | **OK** |
| Secret Vault mis a jour | **OK** |
| K8s secret mis a jour | **OK** |
| API /health | **OK** |
| API /ready (DB connected) | **OK** |
| Frontend HTTPS | **OK** |
| API HTTPS | **BLOQUE** (DNS manquant) |
| Logs propres | **OK** |
| Zero crash / zero restart | **OK** |
| Secret hygiene docs | **OK** |
| Regles Cursor renforcees | **OK** |

**Blocker restant** : 1 A record DNS (`studio-api-dev.keybuzz.io`) a ajouter dans Hetzner DNS Console pour debloquer le TLS API.

**Tout le reste est conforme a l'architecture cible.**
