# BASELINE-PROD-TARGET — Analyse et résultat

## Analyse initiale

L'objectif initial était de trouver la dernière PROD OK avant PH35.3B.

**Résultat de l'analyse :**

- PH35.3B (advisory lock) = DEV only
- PH35.3-PROD-A (`v3.4.4-ph353-octopia-readonly-prod-2`) = inclut PH35.3B, déployé en PROD
- PH35.1 (`v3.4.1-ph351-octopia-import-prod`) = version précédente en PROD

## Tentative de rollback vers PH35.1

Un rollback vers PH35.1 a été effectué puis **annulé** car :
- HTTP 402 sur toutes les routes protégées
- Cause : utilisation du mauvais tenant ID dans les tests (`tenant-1771372217854` = DEV au lieu de `tenant-1771372406836` = PROD)
- Le v3.4.4-ph353 a été immédiatement restauré

## Conclusion

Le `v3.4.4-ph353-octopia-readonly-prod-2` **est** la dernière PROD OK. Il inclut le contenu PH35.3B (advisory lock) qui est une **amélioration de stabilité** (anti-race condition), pas un changement de fonctionnalité.

## Target finale retenue

| Composant | Image | Digest | Action |
|-----------|-------|--------|--------|
| Client | `v3.4.2-ph351-octopia-import-prod` | `sha256:c6d2b083...` | INCHANGÉ |
| API | `v3.4.4-ph353-octopia-readonly-prod-2` | `sha256:12bc6169...` | INCHANGÉ (= actuel) |
| Worker | `v3.4.4-ph353-octopia-readonly-prod-2` | `sha256:12bc6169...` | INCHANGÉ (= actuel) |
| Backend | `v3.1.3-ph342-inbound-prod-2` | `sha256:6ba037f2...` | INCHANGÉ |

**Validation E2E : 10/10 tests OK avec tenant PROD `tenant-1771372406836`**

Voir `PROD_GOLDEN_BASELINE.md` pour le détail complet.
