#!/bin/bash
NS=keybuzz-studio-api-prod
DB_URL=$(kubectl get secret keybuzz-studio-api-db -n $NS -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

kubectl run psql-schema --rm -i --restart=Never --image=postgres:17-alpine -n $NS \
    -- psql "$DB_URL" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name='sessions' ORDER BY ordinal_position;" 2>&1 | grep -v "^pod\|^If you"
