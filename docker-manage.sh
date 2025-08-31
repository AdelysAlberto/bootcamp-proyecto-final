#!/bin/bash

# Script de comandos útiles para el proyecto Docker

echo "=== Comandos Docker para Reto Final ==="
echo ""

case "$1" in
    "build")
        echo "🏗️  Construyendo todos los servicios..."
        docker-compose build
        ;;
    "up")
        echo "🚀 Levantando todos los servicios..."
        docker-compose up -d
        ;;
    "down")
        echo "🛑 Deteniendo todos los servicios..."
        docker-compose down
        ;;
    "logs")
        echo "📋 Mostrando logs de todos los servicios..."
        docker-compose logs -f
        ;;
    "logs-web")
        echo "📋 Mostrando logs del servicio web..."
        docker-compose logs -f web
        ;;
    "logs-postgres")
        echo "📋 Mostrando logs de PostgreSQL..."
        docker-compose logs -f postgres
        ;;
    "logs-jenkins")
        echo "📋 Mostrando logs de Jenkins..."
        docker-compose logs -f jenkins
        ;;
    "restart")
        echo "🔄 Reiniciando todos los servicios..."
        docker-compose restart
        ;;
    "clean")
        echo "🧹 Limpiando contenedores, imágenes y volúmenes no utilizados..."
        docker-compose down -v
        docker system prune -f
        ;;
    "reset")
        echo "⚠️  ADVERTENCIA: Esto eliminará todos los datos. ¿Continuar? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            docker-compose down -v
            docker volume rm reto_final_python_postgres_data reto_final_python_jenkins_home 2>/dev/null || true
            echo "✅ Reset completo realizado"
        else
            echo "❌ Reset cancelado"
        fi
        ;;
    "status")
        echo "📊 Estado de los servicios..."
        docker-compose ps
        ;;
    "shell-web")
        echo "💻 Accediendo al shell del contenedor web..."
        docker-compose exec web /bin/bash
        ;;
    "shell-postgres")
        echo "💻 Accediendo a PostgreSQL..."
        docker-compose exec postgres psql -U postgres -d reto_final_db
        ;;
    "init")
        echo "🎯 Inicializando proyecto completo..."
        echo "1. Construyendo imágenes..."
        docker-compose build
        echo "2. Levantando servicios..."
        docker-compose up -d
        echo "3. Esperando que los servicios estén listos..."
        sleep 30
        echo "4. Verificando estado..."
        docker-compose ps
        echo ""
        echo "✅ Servicios disponibles:"
        echo "   🌐 Web: http://localhost:5001"
        echo "   🛠️  Jenkins: http://localhost:8080"
        echo "   🗄️  PostgreSQL: localhost:5432"
        ;;
    *)
        echo "Uso: $0 {build|up|down|logs|logs-web|logs-postgres|logs-jenkins|restart|clean|reset|status|shell-web|shell-postgres|init}"
        echo ""
        echo "Comandos disponibles:"
        echo "  build        - Construir todas las imágenes"
        echo "  up           - Levantar todos los servicios"
        echo "  down         - Detener todos los servicios"
        echo "  logs         - Ver logs de todos los servicios"
        echo "  logs-web     - Ver logs del servicio web"
        echo "  logs-postgres - Ver logs de PostgreSQL"
        echo "  logs-jenkins - Ver logs de Jenkins"
        echo "  restart      - Reiniciar todos los servicios"
        echo "  clean        - Limpiar recursos no utilizados"
        echo "  reset        - Reset completo (elimina datos)"
        echo "  status       - Ver estado de los servicios"
        echo "  shell-web    - Acceder al shell del contenedor web"
        echo "  shell-postgres - Acceder a PostgreSQL"
        echo "  init         - Inicializar proyecto completo"
        exit 1
        ;;
esac
