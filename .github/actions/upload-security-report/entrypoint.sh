#!/bin/bash

set -e

API_URL="${DEFECTDOJO_URL}/api/v2"
HEADERS=(
  -H "Authorization: Token ${DEFECTDOJO_TOKEN}"
  -H "accept: application/json"
  -H "Content-Type: application/json"
)

echo "API_URL=${API_URL}"
echo "Token recibido (primeros 5 caracteres): ${DEFECTDOJO_TOKEN}"

# Buscar engagement
echo "Buscando engagement..."
ENGAGEMENT_RESPONSE=$(curl -s "${API_URL}/engagements/?product=${PRODUCT_ID}&name=${ENGAGEMENT_NAME}" "${HEADERS[@]}")
ENGAGEMENT_ID=$(echo "$ENGAGEMENT_RESPONSE" | grep -o '"id":[0-9]*' | head -n 1 | sed 's/"id"://')

# Si no existe, crear uno
if [ -z "$ENGAGEMENT_ID" ]; then
    echo "Creando nuevo engagement..."
    
    ENGAGEMENT_RESPONSE=$(curl -s -X POST "${API_URL}/engagements/" \
        -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
        -H "accept: application/json" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"Engagement de Prueba\",
            \"product\": 1,
            \"status\": \"In Progress\",
            \"target_start\": \"2024-02-01\",
            \"target_end\": \"2025-02-01\"
            }")

    echo "response:$ENGAGEMENT_RESPONSE"
    ENGAGEMENT_ID=$(echo "$ENGAGEMENT_RESPONSE" | grep -o '"id":[0-9]*' | head -n 1 | sed 's/"id"://')
    echo "id: $ENGAGEMENT_RESPONSE"

    if [ -z "$ENGAGEMENT_ID" ]; then
        echo "Error: No se pudo crear el engagement."
        exit 1
    fi
    echo "Nuevo engagement creado con ID: $ENGAGEMENT_ID"
else
    echo "Engagement existente encontrado con ID: $ENGAGEMENT_ID"
fi

# Subir reporte
echo "Subiendo reporte de seguridad a DefectDojo..."
UPLOAD_RESPONSE=$(curl -s -X POST $HEADERS \
    -F "engagement=${ENGAGEMENT_ID}" \
    -F "scan_type=${SCAN_TYPE}" \
    -F "test_type=${SCAN_TYPE}" \
    -F "environment=${ENVIRONMENT}" \
    -F "file=@${REPORT}" \
    "${API_URL}/import-scan/")

if echo "$UPLOAD_RESPONSE" | grep -q '"id":'; then
    echo "Reporte subido correctamente."
else
    echo "Error al subir el reporte: $UPLOAD_RESPONSE"
    exit 1
fi