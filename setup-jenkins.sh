#!/bin/bash

# Script para configurar y reconstruir Jenkins con soporte Docker Pipeline
set -e

echo "🚀 Configurando Jenkins con Docker Pipeline..."

# Detener servicios si están ejecutándose
echo "📍 Deteniendo servicios existentes..."
docker-compose down || true

# Limpiar imagen anterior de Jenkins si existe
echo "🧹 Limpiando imagen anterior de Jenkins..."
docker rmi reto_final_python-jenkins:latest || true

# Construir imagen Jenkins con plugins
echo "🔨 Construyendo nueva imagen Jenkins..."
docker-compose build --no-cache jenkins

# Iniciar servicios
echo "🚀 Iniciando servicios..."
docker-compose up -d postgres
echo "⏳ Esperando a que PostgreSQL esté listo..."
sleep 10

docker-compose up -d jenkins
echo "⏳ Esperando a que Jenkins esté listo..."
sleep 30

# Mostrar información útil
echo ""
echo "✅ Jenkins configurado exitosamente!"
echo ""
echo "📋 Información de acceso:"
echo "   Jenkins UI: http://localhost:8080"
echo "   PostgreSQL: localhost:5432"
echo ""
echo "🔑 Para obtener la contraseña inicial de Jenkins:"
echo "   docker logs jenkins | grep -A 5 -B 5 'password'"
echo ""
echo "📚 Guía de configuración: docker/jenkins-setup.md"
echo ""
echo "🔧 Verificar que Jenkins puede usar Docker:"
docker-compose exec jenkins docker --version || echo "⚠️  Problema con Docker CLI en Jenkins"
echo ""
echo "📊 Estado de contenedores:"
docker-compose ps

echo ""
echo "🎉 ¡Configuración completada! Ahora puedes:"
echo "   1. Acceder a Jenkins en http://localhost:8080"
echo "   2. Configurar credenciales según jenkins-setup.md"
echo "   3. Crear tu pipeline con el Jenkinsfile existente"
