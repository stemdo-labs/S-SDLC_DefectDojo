#!/bin/bash

set -e

API_URL="${DEFECTDOJO_URL}/api/v2"
HEADERS=(
  -H "Authorization: Token ${DEFECTDOJO_TOKEN}"
  -H "accept: application/json"
  -H "Content-Type: application/json"
)

echo "API_URL=${API_URL}"
echo "Token recibido (primeros 5 caracteres): ${DEFECTDOJO_TOKEN:0:5}"

# Buscar engagement
echo "Buscando engagement..."
engagement=$(curl -X GET "$API_URL/engagements/?name=$ENGAGEMENT_NAME&product=$PRODUCT_ID" -H "Authorization: Token $DEFECTDOJO_TOKEN" -H "accept: application/json" -H "Content-Type: application/json" | jq -r '.results' | jq -r '.[0].id')

echo "engagement=${engagement}"
