# Workflows de GitHub Actions
Aquí podemos encontrar el listado de workflows y la documentación mínima que deben tener.

## Listado de Workflows

- [dojo-openshift.yml](.github/workflows/dojo-openshift.yml) - Trigger: jobs:
- [creating-readme.yml](.github/workflows/creating-readme.yml) - Trigger: jobs:
- [prueba-action.yaml](.github/workflows/prueba-action.yaml) - Trigger: jobs:

## Explicación de uso

1. Dirígete a la pestaña __Actions__, para ejecutar los workflows disponibles.
2. Selecciona el workflow que deseas ejecutar.
3. Configura los parámetros necesarios y ejecuta el workflow.
4. Monitorea la ejecución y revisa los logs en la pestaña de Actions.

## Documentación mínima para workflows

```yaml
# Nombre del Workflow

Pequeña descripción de lo que hace

## Ejemplo de uso

on:
  push:
    branches:
      - main

jobs:
  example_job:
    runs-on: ubuntu-latest
    steps:
      - name: Example step
        run: echo 'Hello, world!'
```
