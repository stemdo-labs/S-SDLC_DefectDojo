#!/bin/bash

set -e

API_URL="${DEFECTDOJO_URL}/api/v2"
HEADERS=(
  -H "Authorization: Token ${DEFECTDOJO_TOKEN}"
  -H "accept: application/json"
  -H "Content-Type: application/json"
)

echo "API_URL=${API_URL}"
echo "Token recibido (primeros 5 caracteres): ${DEFECTDOJO_TOKEN:0:5}*****"

# Buscar engagement
echo "Buscando engagement..."
ENGAGEMENT_ID=$(curl -s -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
     "${API_URL}/engagements/?product=${PRODUCT_ID}&name=${ENGAGEMENT_NAME}" | jq -r '.results[0].id')

# Si no existe, crear uno
if [ "$ENGAGEMENT_ID" == "null" ] || [ -z "$ENGAGEMENT_ID" ]; then
    echo "Creando nuevo engagement..."
       ENGAGEMENT_RESPONSE=$(curl -s -X POST "${API_URL}/engagements/" \
        -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
        -H "accept: application/json" \
        -H "Content-Type: application/json" \
        -d "{
                \"name\": \"${ENGAGEMENT_NAME}\",
                \"product\": \"${PRODUCT_ID}\",
                \"status\": \"In Progress\",
                \"target_start\": \"$(date +%Y-%m-%d)\",
                \"target_end\": \"$(date -d '+1 year' +%Y-%m-%d)\"
            }")
            
    if [ "$ENGAGEMENT_ID" == "null" ] || [ -z "$ENGAGEMENT_ID" ]; then
        echo "Error: No se pudo crear el engagement."
        exit 1
    fi

    echo "Nuevo engagement creado con ID: $ENGAGEMENT_ID"
else
    echo "Engagement existente encontrado con ID: $ENGAGEMENT_ID"
fi
