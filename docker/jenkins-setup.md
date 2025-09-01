# Jenkins Configuration Guide

## Después de iniciar Jenkins por primera vez:

### 1. Configuración Inicial de Seguridad
- Accede a http://localhost:8080
- Usa la contraseña inicial desde los logs: `docker logs jenkins`
- Instala los plugins sugeridos (ya están incluidos en la imagen)
- Crea tu usuario administrador

### 2. Configurar Credenciales

#### GitHub Token (Para acceso a repositorios y registry)
1. Ve a "Manage Jenkins" > "Manage Credentials"
2. Clic en "Global" > "Add Credentials"
3. Tipo: "Username with password"
4. Scope: Global
5. ID: `ghcr-token`
6. Username: tu-usuario-github
7. Password: tu-personal-access-token-de-github

#### Docker Hub (alternativo)
1. Ve a "Manage Jenkins" > "Manage Credentials"
2. Clic en "Global" > "Add Credentials"
3. Tipo: "Username with password"
4. Scope: Global
5. ID: `dockerhub-creds`
6. Username: tu-usuario-dockerhub
7. Password: tu-token-dockerhub

### 3. Crear Pipeline Job
1. Ve a "New Item"
2. Introduce el nombre: "reto-final-python"
3. Selecciona "Pipeline"
4. En la configuración del Pipeline:
   - Definition: "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: tu-repository-url
   - Branch: */main
   - Script Path: Jenkinsfile

### 4. Configuración de GitHub (opcional)
Para webhooks automáticos:
1. En tu repo GitHub ve a Settings > Webhooks
2. Add webhook:
   - Payload URL: http://tu-jenkins-url/github-webhook/
   - Content type: application/json
   - Events: Push events, Pull requests

### 5. Variables de Entorno (si necesitas cambiar)
En la configuración del job, añade variables de entorno:
- REGISTRY: ghcr.io (o docker.io para Docker Hub)
- NAMESPACE: tu-namespace
- APP_NAME: reto-final-python

### 6. Permisos Docker
El contenedor Jenkins ya está configurado con:
- Usuario jenkins en grupo docker
- Socket Docker montado
- Docker CLI instalado
- Permisos sudo para comandos docker

### 7. Plugins Incluidos
Los siguientes plugins están preinstalados:
- Docker Pipeline
- Blue Ocean
- AnsiColor
- Timestamper
- Git/GitHub
- Credentials
- Workspace Cleanup

## Troubleshooting

### Si Docker no funciona en Pipeline:
```bash
# Verificar permisos desde Jenkins container
docker logs jenkins
# Buscar errores relacionados con Docker socket
```

### Si faltan plugins:
```bash
# Reconstruir la imagen Jenkins
docker-compose down
docker-compose build --no-cache jenkins
docker-compose up -d jenkins
```

### Logs útiles:
```bash
# Jenkins logs
docker logs jenkins

# Pipeline logs específicos
# Revisar en la UI de Jenkins

# Docker compose logs
docker-compose logs jenkins
```
