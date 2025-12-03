#!/bin/bash
# Script de test end-to-end PostgreSQL HA via Load Balancer

set -e

LB_IP="10.0.0.10"
POSTGRES_PORT=5432
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="${POSTGRES_SUPERUSER_PASSWORD:-CHANGE_ME_LATER_VIA_VAULT}"

TEST_DB="kb_test"
TEST_TABLE="t"

echo "=== PH7 - Test End-to-End PostgreSQL HA ==="
echo "LB IP: ${LB_IP}:${POSTGRES_PORT}"
echo ""

# Vérifier si le mot de passe est défini
if [ "$POSTGRES_PASSWORD" == "CHANGE_ME_LATER_VIA_VAULT" ]; then
    echo "⚠️  ATTENTION: Utilisation du mot de passe par défaut"
    echo "   Le mot de passe doit être migré vers Vault en PH7.x"
    echo ""
fi

# Fonction pour exécuter une commande psql
psql_cmd() {
    local sql=$1
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$LB_IP" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -c "$sql" 2>&1
}

# 1. Test de connexion
echo "1. Test de connexion..."
if psql_cmd "SELECT now();" | grep -q "now"; then
    echo "   ✅ Connexion réussie"
else
    echo "   ❌ Échec de connexion"
    exit 1
fi
echo ""

# 2. Création de la base de test
echo "2. Création de la base de test '${TEST_DB}'..."
if PGPASSWORD="$POSTGRES_PASSWORD" createdb -h "$LB_IP" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$TEST_DB" 2>&1 | grep -v "already exists"; then
    echo "   ✅ Base créée"
else
    echo "   ⚠️  Base peut-être déjà existante"
fi
echo ""

# 3. Création d'une table de test
echo "3. Création de la table de test..."
if psql_cmd "CREATE TABLE IF NOT EXISTS ${TEST_DB}.public.${TEST_TABLE} (id serial PRIMARY KEY, value text);" | grep -q "CREATE TABLE\|already exists"; then
    echo "   ✅ Table créée"
else
    echo "   ⚠️  Table peut-être déjà existante"
fi
echo ""

# 4. Insertion de données
echo "4. Insertion de données de test..."
if psql_cmd "INSERT INTO ${TEST_DB}.public.${TEST_TABLE} (value) VALUES ('OK PH7');" | grep -q "INSERT"; then
    echo "   ✅ Données insérées"
else
    echo "   ❌ Échec insertion"
    exit 1
fi
echo ""

# 5. Lecture des données
echo "5. Lecture des données..."
RESULT=$(psql_cmd "SELECT * FROM ${TEST_DB}.public.${TEST_TABLE};" | grep -c "OK PH7" || echo "0")
if [ "$RESULT" -gt 0 ]; then
    echo "   ✅ Données lues: $RESULT ligne(s)"
    psql_cmd "SELECT * FROM ${TEST_DB}.public.${TEST_TABLE};" | grep "OK PH7"
else
    echo "   ❌ Aucune donnée trouvée"
    exit 1
fi
echo ""

# 6. Nettoyage
echo "6. Nettoyage..."
if PGPASSWORD="$POSTGRES_PASSWORD" dropdb -h "$LB_IP" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$TEST_DB" 2>&1 | grep -v "does not exist"; then
    echo "   ✅ Base supprimée"
else
    echo "   ⚠️  Base peut-être déjà supprimée"
fi
echo ""

echo "=== ✅ Test end-to-end terminé avec succès ==="

