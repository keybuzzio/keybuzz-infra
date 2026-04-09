#!/bin/bash
NS=keybuzz-studio-api-prod
DB_URL=$(kubectl get secret keybuzz-studio-api-db -n $NS -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

kubectl run psql-cleanup --rm -i --restart=Never --image=postgres:17-alpine -n $NS \
    -- psql "$DB_URL" -c "DELETE FROM sessions WHERE id='0599145c-a027-4a70-9d1b-8c5f8b9f0d8c';" 2>&1 | grep -v "^pod\|^If you"
echo "Validation session cleaned"
