# 🛠️ Desarrollo y Calidad de Código

Este proyecto utiliza un conjunto completo de herramientas para mantener la calidad del código y facilitar el desarrollo.

## 🔧 Herramientas Configuradas

### **Linting y Formateo:**
- **Ruff**: Linter rápido y moderno (reemplaza flake8, isort, etc.)
- **Black**: Formateador de código automático
- **MyPy**: Verificación de tipos estáticos

### **Control de Calidad:**
- **Pre-commit hooks**: Ejecuta verificaciones antes de cada commit
- **Bandit**: Análisis de seguridad
- **Hadolint**: Linting para Dockerfiles

## 🚀 Configuración Inicial

### **Opción 1: Desarrollo Local**
```bash
# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # En macOS/Linux
# o
venv\Scripts\activate     # En Windows

# Instalar dependencias
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Configurar pre-commit
pre-commit install
```

### **Opción 2: Desarrollo con Docker**
```bash
# Los contenedores ya incluyen las herramientas de desarrollo
docker-compose up -d
docker-compose exec python bash
```

## 📋 Comandos de Desarrollo

### **Script de Herramientas (Recomendado)**
```bash
# Configuración inicial
./dev-tools.sh setup

# Verificar código
./dev-tools.sh lint

# Formatear código
./dev-tools.sh format

# Verificar tipos
./dev-tools.sh type-check

# Ejecutar pre-commit
./dev-tools.sh pre-commit

# Ejecutar todas las verificaciones
./dev-tools.sh check-all

# Limpiar archivos de cache
./dev-tools.sh clean
```

### **Comandos Individuales**
```bash
# Ruff - Linting y auto-fixes
ruff check .                    # Verificar
ruff check --fix .              # Fix automático
ruff format .                   # Formatear

# Black - Formateo
black .                         # Formatear
black --check .                 # Solo verificar

# MyPy - Tipos
mypy .                          # Verificar tipos

# Pre-commit
pre-commit run --all-files      # Ejecutar en todos los archivos
pre-commit run <hook-name>      # Ejecutar hook específico
```

## ⚙️ Configuración

### **pyproject.toml**
Configuración principal para todas las herramientas:
- Ruff: Reglas de linting, exclusiones
- Black: Longitud de línea, formato
- MyPy: Configuración de tipos

### **Pre-commit Hooks**
Verificaciones automáticas antes de cada commit:
- ✅ Trailing whitespace
- ✅ End of file fixer
- ✅ YAML/JSON validation
- ✅ Large files check
- ✅ Ruff linting
- ✅ Black formatting
- ✅ MyPy type checking
- ✅ Dockerfile linting
- ✅ Security checks (Bandit)

### **VS Code**
Configuración automática en `.vscode/`:
- Formateo automático al guardar
- Linting en tiempo real
- Extensiones recomendadas

## 🎯 Flujo de Trabajo

### **1. Desarrollo Normal**
```bash
# Hacer cambios en el código
vim app/routes.py

# Formatear y verificar
./dev-tools.sh format
./dev-tools.sh lint

# Commit (pre-commit se ejecuta automáticamente)
git add .
git commit -m "Add new feature"
```

### **2. Verificación Completa**
```bash
# Antes de push o PR
./dev-tools.sh check-all
```

### **3. Resolución de Errores**
```bash
# Si ruff encuentra errores
ruff check --fix .

# Si black encuentra problemas de formato
black .

# Si mypy encuentra errores de tipos
# Revisar y corregir manualmente
```

## 📊 Estándares de Código

### **Estilo:**
- **Longitud de línea**: 88 caracteres (Black standard)
- **Quotes**: Dobles por defecto
- **Imports**: Organizados automáticamente
- **Trailing commas**: Sí en estructuras multilinea

### **Tipos:**
- **Type hints**: Obligatorios en funciones públicas
- **Strict mode**: Habilitado en MyPy
- **Return types**: Siempre especificados

### **Estructura:**
- **Docstrings**: Estilo Google/Numpy
- **Imports**: `from __future__ import annotations`
- **Error handling**: Específico y documentado

## 🐛 Solución de Problemas

### **Pre-commit falla:**
```bash
# Ver detalles del error
pre-commit run --all-files --verbose

# Saltarse pre-commit (solo en emergencias)
git commit --no-verify -m "Emergency commit"
```

### **MyPy errores:**
```bash
# Ignorar tipo específico
# type: ignore[error-code]

# Ver todos los códigos de error
mypy --show-error-codes .
```

### **Ruff conflictos:**
```bash
# Ver reglas aplicadas
ruff check --statistics .

# Deshabilitar regla específica
# ruff: noqa: E501
```

## 🔗 Integración Continua

En CI/CD (GitHub Actions, Jenkins), ejecutar:
```bash
# Verificaciones de calidad
./dev-tools.sh check-all

# O comandos específicos
ruff check .
black --check .
mypy .
```

## 📈 Métricas

Métricas que se verifican automáticamente:
- **Complejidad ciclomática**: Máx 10 (ruff)
- **Cobertura de tipos**: 100% en funciones públicas
- **Seguridad**: Sin vulnerabilidades conocidas (bandit)
- **Estilo**: 100% conforme con Black y Ruff
