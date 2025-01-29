# S-SDLC-devsecops
DevSecOps Stemdo S-SDLC

# Despliegue de DefectDojo en OpenShift con GitHub Actions

Este documento describe el proceso de despliegue de **DefectDojo** en **OpenShift** utilizando **GitHub Actions**. Se proporciona un workflow para la automatización del proceso y la configuración de los recursos necesarios.

## Requisitos Previos

- **Cuenta en IBM Cloud** con permisos para gestionar clústeres en OpenShift.
- **GitHub Actions** configurado con los siguientes secretos:
  - `API_KEY_IBM`: Clave API para autenticación en IBM Cloud.
- **Helm** instalado para la gestión del chart de DefectDojo.


### Jobs del workflow

#### 1. Instalación de herramientas necesarias

- **IBM CLI**: Se instala la CLI de IBM para interactuar con OpenShift.
- **Plugin OC para IBM CLI**: Se instala el plugin necesario para manejar OpenShift desde IBM Cloud CLI.
- **Kubectl**: Se instala la herramienta de línea de comandos de Kubernetes.
- **Helm**: Se instala Helm para gestionar el chart de DefectDojo.

#### 2. Autenticación en IBM Cloud y Configuración del Clúster

- Se inicia sesión en IBM Cloud con el API Key.
- Se configura el acceso al clúster de OpenShift especificado.

#### 3. Creación del Namespace

Se verifica si el namespace `dojo` existe, y en caso contrario, se crea.

#### 4. Obtención del Dominio de OpenShift

Se obtiene el dominio de Ingress del clúster para ser usado en la configuración del chart de Helm.

#### 5. Despliegue de DefectDojo con Helm

- Se agrega el repositorio de Helm de DefectDojo.
- Se instala o actualiza DefectDojo en el namespace `dojo`, configurando el host de OpenShift.
- Se aplica el `Route` en OpenShift para exponer la aplicación.

## Configuración del archivo `values.yaml`

### Archivo base `values.yaml`


```yaml
#createSecret: true
#createRedisSecret: true
#createPostgresqlSecret: true
#createPostgresqlHaSecret: true
#createPostgresqlHaPgpoolSecret: true

alternativeHosts:
- dojo-dojo.ez-ibm-openshift-vpc.example.com

imagePullPolicy: IfNotPresent
imagePullSecrets: ibmcloud-registry-secret

cloudsql:
image:
    repository: icr.io/acajas-cr/defectdojo/defectdojo-django
    tag: 2.42.2
    imagePullPolicy: IfNotPresent

postgresql:
primary:
    podSecurityContext:
    enabled: false
    containerSecurityContext:
    enabled: false

securityContext:
enabled: false

django:
ingress:
    enables: false
mediaPersistentVolume:
    enabled: false

postgresqlha:
postgresql:
    securityContext:
    enabled: false
```


### Importante

- **Primera instalación**: Descomente las siguientes líneas si es el primer despliegue:
  ```yaml
        createSecret: true
        createRedisSecret: true
        createPostgresqlSecret: true
        createPostgresqlHaSecret: true
        createPostgresqlHaPgpoolSecret: true
  ```
  Si estas líneas permanecen comentadas en la primera instalación, el despliegue no funcionará correctamente.

- **Instalaciones posteriores**: Mantenga estas líneas comentadas para evitar recrear secretos que ya existen en el clúster.


## Creación de un `Route` en OpenShift

Una vez que se haya desplegado el chart, cree un recurso `Route` para acceder a DefectDojo desde el exterior del clúster. Utilice el siguiente archivo `route.yaml` como referencia:

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: dojo
  namespace: dojo
spec:
  to:
    kind: Service
    name: my-dojo-defectdojo-django
  tls:
      insecureEdgeTerminationPolicy: Redirect
      termination: edge
  port:
    targetPort: http
```

### Aplicar el `Route`

```bash
oc apply -f route.yaml
```

## Despliegue con Helm

```bash
helm upgrade --install my-dojo defectdojo/defectdojo -f values.yml --set OpenShift.route.host="sonar-default.ez-ibm-openshift-vpc.example.com" -n dojo
```

## Acceso a DefectDojo

Una vez que el `Route` esté creado, podrá acceder a DefectDojo utilizando la URL generada. Puede verificar la URL del `Route` ejecutando el siguiente comando:

```bash
    oc get route dojo -n dojo
```

La salida mostrará la URL pública que puede utilizar en su navegador para acceder a la aplicación.

## Referencias

- [DefectDojo Helm Chart](https://github.com/DefectDojo/django-DefectDojo/tree/master/helm/defectdojo)
- [OpenShift Route Documentation](https://docs.openshift.com)
