#!/bin/bash

set -e

API_URL="${DEFECTDOJO_URL}/api/v2"
HEADERS="-H 'accept: application/json' -H 'Content-Type: application/json'"

echo "username=${DEFECTDOJO_USER}&password=${DEFECTDOJO_PASSWORD}"


# Obtener token de auth
echo "Obteniendo token de DefectDojo..."
TOKEN_RESPONSE=$(curl -s -X POST "${API_URL}/api-token-auth/" \
    -H "accept: application/json" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${DEFECTDOJO_USER}&password=${DEFECTDOJO_PASSWORD}")

TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
    echo "Error: No se pudo obtener el token de DefectDojo."
    exit 1
fi

HEADERS="-H 'Authorization: Token $TOKEN' -H 'Content-Type: application/json'"

# Buscar engagement
echo "Buscando engagement..."
ENGAGEMENT_ID=$(curl -s $HEADERS "${API_URL}/engagements/?product=${PRODUCT_ID}&name=${ENGAGEMENT_NAME}" | jq -r '.results[0].id')

# Si no existe, crear uno
if [ "$ENGAGEMENT_ID" == "null" ] || [ -z "$ENGAGEMENT_ID" ]; then
    echo "Creando nuevo engagement..."
    ENGAGEMENT_ID=$(curl -s -X POST $HEADERS \
        -d "{\"name\": \"${ENGAGEMENT_NAME}\", \"product\": \"${PRODUCT_ID}\", \"status\": \"In Progress\", \"target_start\": \"$(date +%Y-%m-%d)\", \"target_end\": \"$(date -d '+1 year' +%Y-%m-%d)\"}" \
        "${API_URL}/engagements/" | jq -r '.id')

    if [ "$ENGAGEMENT_ID" == "null" ] || [ -z "$ENGAGEMENT_ID" ]; then
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
