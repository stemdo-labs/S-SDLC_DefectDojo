#!/bin/bash

set -e

API_URL="${DEFECTDOJO_URL}/api/v2"

echo " Obteniendo token de DefectDojo..."
TOKEN_RESPONSE=$(curl -s -X POST "${API_URL}/api-token-auth/" \
    -H "accept: application/json" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "username=${DEFECTDOJO_USER}" \
    --data-urlencode "password=${DEFECTDOJO_PASSWORD}")

    DEFECTDOJO_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token')
        
    if [ -z "$DEFECTDOJO_TOKEN" ] || [ "$DEFECTDOJO_TOKEN" == "null" ]; then
        echo "Error: No se pudo obtener el token de DefectDojo."
        exit 1
    fi
        

HEADERS=(
  -H "Authorization: Token ${DEFECTDOJO_TOKEN}"
  -H "accept: application/json"
  -H "Content-Type: application/json"
)

echo "API_URL=${API_URL}"
echo "Token recibido (primeros 5 caracteres): ${DEFECTDOJO_TOKEN:0:5}*****"

# Buscar engagement
echo "Buscando engagement..."

ENCODED_NAME=$(echo -n "$ENGAGEMENT_NAME" | jq -sRr @uri)

RESPONSE=$(curl -s -X GET "${API_URL}/engagements/?product=${PRODUCT_ID}&name=${ENCODED_NAME}" \
    -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
    -H "accept: application/json" \
    -H "Content-Type: application/json")


ENGAGEMENT_ID=$(echo "$RESPONSE" | jq -r '.results[0].id' 2>/dev/null || echo "null")

if [ "$ENGAGEMENT_ID" == "null" ] || [ -z "$ENGAGEMENT_ID" ]; then
    echo "No se encontró engagement con el nombre: ${ENGAGEMENT_NAME}. Creando nuevo engagement..."
else
    echo "Engagement existente encontrado con ID: $ENGAGEMENT_ID"
fi


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
            
            echo "Respuesta de DefectDojo: $ENGAGEMENT_RESPONSE"

            ENGAGEMENT_ID=$(echo "$ENGAGEMENT_RESPONSE" | jq -r '.id')
            
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
UPLOAD_RESPONSE=$(curl -v -X POST "${API_URL}/import-scan/" \
    -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
    -H "accept: application/json" \
    -H "Content-Type: multipart/form-data" \
    -F "engagement=${ENGAGEMENT_ID}" \
    -F "scan_type=${SCAN_TYPE}" \
    -F "test_type=${SCAN_TYPE}" \
    -F "environment=${ENVIRONMENT}" \
    -F "file=@${REPORT}")

if echo "$UPLOAD_RESPONSE" | jq -e '.test_id' > /dev/null; then
    echo "Reporte subido correctamente."
else
    echo "Error al subir el reporte: $UPLOAD_RESPONSE"
    exit 1
fi
