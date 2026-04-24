# PH-WEBSITE-SOCIALS-CONTACT-01 — Mise a jour reseaux sociaux + correction contact

> Date : 10 avril 2026
> Environnement : DEV + PROD
> Type : patch UI cible (footer + contact)
> Scope : keybuzz-website uniquement — zero impact SaaS

---

## Objectif

1. Mettre a jour les liens reseaux sociaux dans le footer du site vitrine
2. Supprimer le numero de telephone de la page contact
3. Corriger le lien LinkedIn sur la page contact

---

## Fichiers modifies

| Fichier | Modifications |
|---|---|
| `src/components/Footer.tsx` | Import + 5 liens sociaux + flex-wrap |
| `src/app/contact/page.tsx` | Import + suppression telephone + LinkedIn mis a jour |

Aucun autre fichier modifie. `pricing/page.tsx` non touche.

---

## Modifications detaillees

### Footer — Liens sociaux

| Reseau | Avant | Apres |
|---|---|---|
| Instagram | `instagram.com/keybuzz_consulting` | `instagram.com/ludo_keybuzz` |
| YouTube | (absent) | `youtube.com/@KeyBuzzConsulting` |
| TikTok | (absent) | `tiktok.com/@ludo_keybuzz` |
| LinkedIn | (absent) | `linkedin.com/in/ludovic-keybuzz` |
| Facebook | `href="#"` (placeholder) | `facebook.com/profile.php?id=61579202964773` |

Tous les liens ouvrent en `target="_blank"` avec `rel="noopener noreferrer"`.
Icones : lucide-react (Instagram, Youtube, Linkedin, Facebook) + SVG inline (TikTok).
Container passe en `flex-wrap` pour le responsive.

### Contact — Modifications

| Element | Avant | Apres |
|---|---|---|
| Telephone | `+33 7 83 34 89 99` | (supprime) |
| LinkedIn URL | `linkedin.com/company/keybuzz` | `linkedin.com/in/ludovic-keybuzz` |
| LinkedIn texte | `linkedin.com/company/keybuzz` | `linkedin.com/in/ludovic-keybuzz` |
| Import Phone | present | supprime |

---

## References Git

| Element | Valeur |
|---|---|
| SHA website | `6097e9cf06ed7a8752d9eb001caf67904698543d` |
| Commit message | `feat: update social links in footer + remove phone from contact` |
| SHA infra DEV | `77fbd87` |
| SHA infra PROD | `14b28d0` |

---

## Images deployees

| Env | Image | Digest | Rollback |
|---|---|---|---|
| **PROD** | `ghcr.io/keybuzzio/keybuzz-website:v0.6.1-socials-contact-prod` | `sha256:d36bde676c658ab08650d25fe6038a03717104c8a0d67112b6220c975737ea12` | `v0.6.0-fix-image-cache-prod` |
| DEV | `ghcr.io/keybuzzio/keybuzz-website:v0.6.1-socials-contact-dev` | `sha256:7eb719a2efdde4d61afa032216df54fea6c52d46fca8f116a375cdc8200c608a` | `v0.6.0-fix-image-cache-dev` |

---

## Validation DEV (preview.keybuzz.pro)

### Pod interne

| Test | Resultat |
|---|---|
| Logs pod | `Ready in 1010ms` — aucune erreur |
| EACCES | ZERO occurrence |
| Instagram ludo_keybuzz | OK |
| YouTube @KeyBuzzConsulting | OK |
| TikTok @ludo_keybuzz | OK |
| LinkedIn ludovic-keybuzz | OK |
| Facebook profile | OK |
| Ancien Instagram supprime | OK |
| Telephone supprime homepage | OK |

### Page contact

| Test | Resultat |
|---|---|
| HTTP status | 200 |
| Telephone supprime | OK |
| Ancien LinkedIn supprime | OK |
| Nouveau LinkedIn present | OK |

### Via preview.keybuzz.pro (curl -k)

| Test | Resultat |
|---|---|
| Homepage | HTTP 200, 89 586 bytes |
| 5 liens sociaux dans le HTML | Tous presents |
| Contact | HTTP 200, 37 539 bytes |
| Telephone sur /contact | Absent (OK) |
| LinkedIn sur /contact | `linkedin.com/in/ludovic-keybuzz` (OK) |

---

## Rollback DEV

```bash
# GitOps
sed -i 's/v0.6.1-socials-contact-dev/v0.6.0-fix-image-cache-dev/' \
  /opt/keybuzz/keybuzz-infra/k8s/website-dev/deployment.yaml
cd /opt/keybuzz/keybuzz-infra
git add k8s/website-dev/deployment.yaml
git commit -m "rollback: website-dev to v0.6.0-fix-image-cache-dev"
git push origin main
kubectl apply -f k8s/website-dev/deployment.yaml

# Urgence
kubectl set image deploy/keybuzz-website \
  keybuzz-website=ghcr.io/keybuzzio/keybuzz-website:v0.6.0-fix-image-cache-dev \
  -n keybuzz-website-dev
```

---

## Validation PROD (www.keybuzz.pro)

### Pod interne

| Test | Resultat |
|---|---|
| Logs pod | `Ready in 1217ms` — aucune erreur |
| EACCES | ZERO occurrence |
| Instagram ludo_keybuzz | OK |
| YouTube @KeyBuzzConsulting | OK |
| TikTok @ludo_keybuzz | OK |
| LinkedIn ludovic-keybuzz | OK |
| Facebook profile | OK |
| Ancien Instagram supprime | OK |

### Page contact PROD

| Test | Resultat |
|---|---|
| HTTP status | 200 |
| Telephone supprime | OK |
| Ancien LinkedIn supprime | OK |
| Nouveau LinkedIn present | OK |

### Via www.keybuzz.pro (public)

| Test | Resultat |
|---|---|
| Homepage | HTTP 200, 89 226 bytes |
| 5 liens sociaux dans le HTML | Tous presents |
| Contact | HTTP 200, 37 166 bytes |
| Telephone sur /contact | Absent (OK) |
| LinkedIn sur /contact | `linkedin.com/in/ludovic-keybuzz` (OK) |
| Replicas PROD | 2/2 Running (worker-01 + worker-05) |

---

## Rollback PROD

```bash
# GitOps
sed -i 's/v0.6.1-socials-contact-prod/v0.6.0-fix-image-cache-prod/' \
  /opt/keybuzz/keybuzz-infra/k8s/website-prod/deployment.yaml
cd /opt/keybuzz/keybuzz-infra
git add k8s/website-prod/deployment.yaml
git commit -m "rollback: website-prod to v0.6.0-fix-image-cache-prod"
git push origin main
kubectl apply -f k8s/website-prod/deployment.yaml

# Urgence
kubectl set image deploy/keybuzz-website \
  keybuzz-website=ghcr.io/keybuzzio/keybuzz-website:v0.6.0-fix-image-cache-prod \
  -n keybuzz-website-prod
```

---

## Scope verifie

| Verification | Resultat |
|---|---|
| Fichiers modifies | 2 fichiers UI uniquement (Footer.tsx + contact/page.tsx) |
| Namespaces touches | keybuzz-website-dev + keybuzz-website-prod |
| Impact Client/Studio/Admin/API | ZERO |
| Design global | Inchange (style existant conserve) |
| Responsive | flex-wrap ajoute pour 5 icones |
| Tags immuables | Oui (DEV et PROD distincts) |
| GitOps | Oui |

---

## Verdict

**SOCIAL LINKS UPDATED — CONTACT FIXED — NO REGRESSION — PROD SAFE**
