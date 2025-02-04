#!/bin/bash

set -e

API_URL="${DEFECTDOJO_URL}/api/v2"

#TOKEN
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

# Buscar producto type
echo "Buscando tipo de producto..."
ENCODED_NAME_PRODUCT_TYPE=$(echo -n "$PRODUCT_TYPE_NAME" | jq -sRr @uri)

PRODUCT_TYPE_RESPONSE=$(curl -s -X GET "${API_URL}/product_types/?name=${ENCODED_NAME_PRODUCT_TYPE}" \
    -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
    -H "accept: application/json" \
    -H "Content-Type: application/json")

PRODUCT_TYPE_ID=$(echo "$PRODUCT_TYPE_RESPONSE" | jq -r '.results[0].id' 2>/dev/null || echo "null")

# Si no existe, crear uno
if [ "$PRODUCT_TYPE_ID" == "null" ] || [ -z "$PRODUCT_TYPE_ID" ]; then
    echo "No se encontró el tipo de producto con el nombre: ${PRODUCT_TYPE_NAME}. Creando nuevo tipo de producto..."
    PRODUCT_TYPE_RESPONSE=$(curl -s -X POST "${API_URL}/product_types/" \
        -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
        -H "accept: application/json" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"${PRODUCT_TYPE_NAME}\"
        }")
            
    echo "Respuesta de DefectDojo: $PRODUCT_TYPE_RESPONSE"

    PRODUCT_TYPE_ID=$(echo "$PRODUCT_TYPE_RESPONSE" | jq -r '.id')
            
    if [ "$PRODUCT_TYPE_ID" == "null" ] || [ -z "$PRODUCT_TYPE_ID" ]; then
        echo "Error: No se pudo crear el producto."
        exit 1
    fi
    echo "Nuevo tipo de producto creado con ID: $PRODUCT_TYPE_ID"
else
    echo "Tipo de producto existente encontrado con ID: $PRODUCT_TYPE_ID"
fi


# Buscar producto
echo "Buscando producto..."
ENCODED_NAME_PRODUCT=$(echo -n "$PRODUCT_NAME" | jq -sRr @uri)

PRODUCT_RESPONSE=$(curl -s -X GET "${API_URL}/products/?name=${ENCODED_NAME_PRODUCT}" \
    -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
    -H "accept: application/json" \
    -H "Content-Type: application/json")

PRODUCT_ID=$(echo "$PRODUCT_RESPONSE" | jq -r '.results[0].id' 2>/dev/null || echo "null")

# Si no existe, crear uno
if [ "$PRODUCT_ID" == "null" ] || [ -z "$PRODUCT_ID" ]; then
    echo "No se encontró el product con el nombre: ${PRODUCT_NAME}. Creando nuevo producto..."
    PRODUCT_RESPONSE=$(curl -s -X POST "${API_URL}/products/" \
        -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
        -H "accept: application/json" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"${PRODUCT_NAME}\",
            \"description\": \"${PRODUCT_NAME}\",
            \"prod_type\": \"${PRODUCT_TYPE_ID}\"
        }")
            
    echo "Respuesta de DefectDojo: $PRODUCT_RESPONSE"

    PRODUCT_ID=$(echo "$PRODUCT_RESPONSE" | jq -r '.id')
            
    if [ "$PRODUCT_ID" == "null" ] || [ -z "$PRODUCT_ID" ]; then
        echo "Error: No se pudo crear el producto."
        exit 1
    fi
    echo "Nuevo producto creado con ID: $PRODUCT_ID"
else
    echo "Producto existente encontrado con ID: $PRODUCT_ID"
fi



# Buscar engagement
echo "Buscando engagement..."
ENCODED_NAME=$(echo -n "$ENGAGEMENT_NAME" | jq -sRr @uri)

RESPONSE=$(curl -s -X GET "${API_URL}/engagements/?product=${PRODUCT_ID}&name=${ENCODED_NAME}" \
    -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
    -H "accept: application/json" \
    -H "Content-Type: application/json")


ENGAGEMENT_ID=$(echo "$RESPONSE" | jq -r '.results[0].id' 2>/dev/null || echo "null")

# Si no existe, crear uno
if [ "$ENGAGEMENT_ID" == "null" ] || [ -z "$ENGAGEMENT_ID" ]; then
    echo "No se encontró engagement con el nombre: ${ENGAGEMENT_NAME}. Creando nuevo engagement..."
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
echo "-H "Content-Type: multipart/form-data" \
    -F "engagement=${ENGAGEMENT_ID}" \
    -F "scan_type=${SCAN_TYPE}" \
    -F "test_type=${SCAN_TYPE}" \
    -F "environment=${ENVIRONMENT}" \
    -F "file=@${REPORT}" \
    -F "test_title=${TITLE_SCAN}"
    
    
UPLOAD_RESPONSE=$(curl -s -X POST "${API_URL}/import-scan/" \
    -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
    -H "accept: application/json" \
    -H "Content-Type: multipart/form-data" \
    -F "engagement=${ENGAGEMENT_ID}" \
    -F "scan_type=${SCAN_TYPE}" \
    -F "version=${VERSION}" \
    -F "environment=${ENVIRONMENT}" \
    -F "file=@${REPORT}" \
    -F "title=${TITLE_SCAN}" )"



if echo "$UPLOAD_RESPONSE" | jq -e '.test_id' > /dev/null; then
    echo "Reporte subido correctamente."
else
    echo "Error al subir el reporte: $UPLOAD_RESPONSE"
    exit 1
fi
