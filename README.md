# Reto Final Python - Docker Setup

Este proyecto utiliza Docker para crear un entorno completo con PostgreSQL, Jenkins y una aplicación Flask.

## 🏗️ Estructura del Proyecto

```
reto_final_python/
├── docker/
│   ├── Dockerfile.postgres    # Imagen de PostgreSQL
│   ├── Dockerfile.jenkins     # Imagen de Jenkins
│   └── init-scripts/          # Scripts de inicialización de BD
├── app/                       # Aplicación Flask
├── Dockerfile                 # Imagen de la aplicación Python
├── docker-compose.yml         # Orquestación de servicios
├── docker-manage.sh           # Script de gestión
└── requirements.txt           # Dependencias Python
```

## 🚀 Inicio Rápido

### 1. Inicializar el proyecto completo:
```bash
./docker-manage.sh init
```

### 2. O paso a paso:
```bash
# Construir imágenes
docker-compose build

# Levantar servicios
docker-compose up -d

# Ver estado
docker-compose ps
```

## 🌐 Servicios Disponibles

- **Aplicación Web**: http://localhost:5001
- **Jenkins**: http://localhost:8080
- **PostgreSQL**: localhost:5432
  - Usuario: postgres
  - Contraseña: postgres123
  - Base de datos: reto_final_db

## 📋 Comandos Útiles

```bash
# Ver todos los comandos disponibles
./docker-manage.sh

# Ver logs de todos los servicios
./docker-manage.sh logs

# Ver logs de un servicio específico
./docker-manage.sh logs-web
./docker-manage.sh logs-postgres
./docker-manage.sh logs-jenkins

# Acceder al shell del contenedor web
./docker-manage.sh shell-web

# Acceder a PostgreSQL
./docker-manage.sh shell-postgres

# Reiniciar servicios
./docker-manage.sh restart

# Detener servicios
./docker-manage.sh down

# Limpiar recursos
./docker-manage.sh clean

# Reset completo (elimina datos)
./docker-manage.sh reset
```

## 🔧 Configuración

### Variables de Entorno

Copia `.env.example` a `.env` y modifica según necesites:

```bash
cp .env.example .env
```

### Base de Datos

La aplicación se conecta automáticamente a PostgreSQL usando:
- Host: postgres (nombre del servicio)
- Puerto: 5432
- Usuario: postgres
- Contraseña: postgres123
- Base de datos: reto_final_db

### Jenkins

Tras el primer inicio:
1. Ve a http://localhost:8080
2. Obtén la contraseña inicial: `docker-compose logs jenkins | grep -A 5 "Jenkins initial setup"`
3. Sigue el asistente de configuración

## 🌐 Endpoints de la API

- `GET /health` - Health check
- `GET /data` - Obtener todos los datos
- `POST /data` - Insertar datos
- `DELETE /data/<id>` - Eliminar datos

## 🐛 Solución de Problemas

### Los servicios no se levantan:
```bash
# Ver logs detallados
docker-compose logs

# Verificar que los puertos no estén ocupados
netstat -tulpn | grep -E ':(5000|5432|8080)'
```

### Error de conexión a la base de datos:
```bash
# Verificar que PostgreSQL esté funcionando
docker-compose exec postgres pg_isready -U postgres

# Verificar logs de PostgreSQL
./docker-manage.sh logs-postgres
```

### Reiniciar desde cero:
```bash
./docker-manage.sh reset
./docker-manage.sh init
```

## 📊 Health Checks

Los servicios incluyen health checks para verificar su estado:
- Web: `curl http://localhost:5000/health`
- PostgreSQL: Verificación interna de pg_isready

## 🔐 Seguridad

⚠️ **IMPORTANTE**: Este setup es para desarrollo. Para producción:
- Cambia todas las contraseñas por defecto
- Usa secretos de Docker o variables de entorno seguras
- Configura HTTPS
- Restringe acceso a los puertos
- Actualiza las imágenes base regularmente
