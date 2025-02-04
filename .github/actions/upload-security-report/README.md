# Upload Security Report to DefectDojo GitHub Action

## Descripción

Esta acción de GitHub permite subir un reporte de seguridad a DefectDojo y asociarlo a un *engagement* dentro de un producto específico. Si el *product type*, *product* o *engagement* no existen en DefectDojo, la acción los creará automáticamente antes de la subida del reporte.

## Uso

Para utilizar esta acción en un workflow de GitHub Actions, agrega el siguiente código a tu flujo de trabajo:

```yaml
jobs:
  security_scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
      
      - name: Upload security report to DefectDojo
        uses: ./path-to-action
        with:
          defectdojo_url: "https://defectdojo.example.com"
          product_type_name: "Web Applications"
          product_name: "MyApp"
          release_name: "Release 1.0"
          scan_type: "ZAP Scan"
          enviroment: "Production"
          version: "1.0.0"
          title_scan: "ZAP Security Scan"
          report: "./path/to/security_report.xml"
        env:
          defectdojo_user: ${{ secrets.DEFECTDOJO_USER }}
          defectdojo_password: ${{ secrets.DEFECTDOJO_PASSWORD }}

```

## Entradas (*Inputs*)

| Nombre                | Descripción                                             | Obligatorio |
|-----------------------|---------------------------------------------------------|-------------|
| `defectdojo_url`      | URL de DefectDojo                                      | ✅          |
| `product_type_name`   | Tipo de producto en DefectDojo                         | ✅          |
| `product_name`        | Nombre del producto en DefectDojo                      | ✅          |
| `release_name`        | Nombre del *engagement*                                |  ✅        |
| `scan_type`           | Tipo de escaneo (Ej. "ZAP Scan", "Nmap Scan", etc.)   | ✅          |
| `enviroment`          | Entorno donde se realizó el escaneo (Ej. "Development", "Production", etc.)                | ✅          |
| `version`           | Versión   | ✅          |
| `title_scan`        | Titulo del reporte (opcional)                              | ❌         |
| `report`              | Ruta del archivo del reporte a subir                   | ✅          |


## Manejo de Credenciales

Los valores de usuario y contraseña de DefecDojo se deben pasar como secretos de GitHub.

- `DEFECTDOJO_USER`: Usuario de DefectDojo.
- `DEFECTDOJO_PASSWORD`: Contraseña de DefectDojo.


## Requisitos

- Se requiere que `jq` esté instalado en el entorno donde se ejecuta la acción.
- El archivo de reporte debe existir en la ruta especificada.
- La API de DefectDojo debe estar accesible desde la acción.

## Funcionamiento Interno

1. Obtiene un *token* de autenticación en DefectDojo.
2. Busca el tipo de producto (`product_type_name`). Si no existe, lo crea.
3. Busca el producto (`product_name`). Si no existe, lo crea.
4. Busca el *engagement* (`release_name`). Si no existe, lo crea.
5. Sube el reporte de seguridad al *engagement* correspondiente en DefectDojo.
