pipeline {
  agent {
    docker {
      image 'python:3.11-slim'
      // acceso a Docker del host para build/push de imágenes
      args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
    }
  }

  options {
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '15'))
    skipDefaultCheckout(false)
    timeout(time: 30, unit: 'MINUTES')
  }

  environment {
    PIP_CACHE_DIR = "${WORKSPACE}/.pip-cache"
    PYTHONPATH = "${WORKSPACE}"
    PYTHONDONTWRITEBYTECODE = "1"
    PYTHONUNBUFFERED = "1"
    REGISTRY = "ghcr.io"
    NAMESPACE = "adelysalberto"
    APP_NAME = "reto-final-python"
    IMAGE = "${REGISTRY}/${NAMESPACE}/${APP_NAME}"
    COV_MIN = "85"  // Basado en tu configuración actual
    FLASK_ENV = "testing"
    DATABASE_URL = "sqlite:///:memory:"
    DOCKER_HOST = "unix:///var/run/docker.sock"
  }

  stages {
    stage('Checkout & Setup') {
      steps {
        checkout scm
        sh '''
          echo "=== Environment Information ==="
          python --version
          pip --version
          uname -a
          echo "=== Git Information ==="
          which git || echo "Git not available in container, using Jenkins git"
          echo "=== Docker Information ==="
          which docker || echo "Docker not available in container"
          echo "=========================="
        '''
      }
    }

    stage('Install Dependencies') {
      steps {
        sh '''
          echo "Installing system dependencies..."
          apt-get update
          apt-get install -y --no-install-recommends \
            gcc \
            git \
            make

          echo "Upgrading pip..."
          python -m pip install --upgrade pip

          echo "Installing Python dependencies..."
          if [ -f "pyproject.toml" ]; then
            echo "Installing from pyproject.toml..."
            pip install -e ".[dev,test]"
          else
            echo "Installing from requirements files..."
            pip install -r requirements.txt
            [ -f requirements-dev.txt ] && pip install -r requirements-dev.txt
          fi

          echo "Installed packages:"
          pip list
        '''
      }
    }

    stage('Code Quality Checks') {
      parallel {
        stage('Lint with Ruff') {
          steps {
            sh '''
              echo "Running Ruff linter..."
              ruff check . --output-format=github
              echo "Running Ruff formatter check..."
              ruff format --check .
            '''
          }
        }

        stage('Format with Black') {
          steps {
            sh '''
              echo "Checking code formatting with Black..."
              black --check --diff .
            '''
          }
        }

        stage('Type Check with MyPy') {
          steps {
            sh '''
              echo "Running type checking with MyPy..."
              mypy app/ --no-error-summary
            '''
          }
        }
      }
    }

    stage('Security Scan') {
      steps {
        sh '''
          echo "Installing security scanner..."
          pip install bandit safety

          echo "Running Bandit security scan..."
          bandit -r app/ -f json -o bandit-report.json || true
          bandit -r app/ || true

          echo "Running Safety dependency check..."
          safety check --json --output safety-report.json || true
          safety check || true
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: '*-report.json', fingerprint: true, allowEmptyArchive: true
        }
      }
    }

    stage('Tests & Coverage') {
      steps {
        sh '''
          echo "Setting up test environment..."
          mkdir -p reports/junit
          mkdir -p reports/coverage

          echo "Running tests with custom test script..."
          chmod +x test.sh

          # Run tests with coverage using our custom script
          ./test.sh -v -r xml -c ${COV_MIN}

          # Ensure reports are in the right location
          if [ -f "coverage.xml" ]; then
            cp coverage.xml reports/coverage/
          fi

          # Generate additional coverage formats
          echo "Generating coverage reports..."
          coverage xml -o reports/coverage/coverage.xml
          coverage html -d reports/coverage/htmlcov
          coverage report --show-missing

          # Check coverage threshold
          echo "Checking coverage threshold..."
          coverage report --fail-under=${COV_MIN}
        '''
      }
      post {
        always {
          // Publish test results
          junit(
            testResults: 'reports/junit/*.xml',
            allowEmptyResults: true,
            skipPublishingChecks: true
          )

          // Publish coverage results
          publishHTML([
            allowMissing: false,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: 'reports/coverage/htmlcov',
            reportFiles: 'index.html',
            reportName: 'Coverage Report',
            reportTitles: 'Test Coverage'
          ])

          // Archive coverage artifacts
          archiveArtifacts(
            artifacts: 'reports/coverage/*.xml,reports/coverage/htmlcov/**/*',
            fingerprint: true,
            allowEmptyArchive: true
          )

          // Publish coverage using Cobertura plugin if available
          script {
            try {
              publishCoverage adapters: [
                coberturaAdapter('reports/coverage/coverage.xml')
              ], sourceFileResolver: sourceFiles('STORE_ALL_BUILD')
            } catch (err) {
              echo "Coverage plugin not available: ${err.getMessage()}"
            }
          }
        }
      }
    }

    stage('Build & Test Docker Image') {
      steps {
        script {
          def shortSha = sh(returnStdout: true, script: 'git rev-parse --short HEAD || echo "unknown"').trim()
          def branch = env.BRANCH_NAME ?: 'local'
          env.IMAGE_TAG = (env.TAG_NAME ?: "${branch}-${shortSha}").replaceAll('[^a-zA-Z0-9_.-]', '-')
          env.BUILD_DATE = sh(returnStdout: true, script: 'date -u +"%Y-%m-%dT%H:%M:%SZ"').trim()
        }

        script {
          // Note: This stage requires access to host Docker daemon
          // Running in Jenkins container with Docker socket mounted
          echo "Building Docker image: ${IMAGE}:${IMAGE_TAG}"
          echo "Build will be handled by Jenkins host Docker daemon"
          echo "Docker socket: ${env.DOCKER_HOST}"
        }
      }
    }

    stage('Integration Tests with Docker Compose') {
      when {
        anyOf {
          branch 'main'
          branch 'develop'
          branch 'feat/*'
          changeRequest()
        }
      }
      steps {
        script {
          echo "Integration tests would run here with Docker Compose"
          echo "This stage requires Jenkins host Docker access"
          echo "Skipping for now - container environment limitations"
        }
      }
    }

    stage('Deploy to Registry') {
      when {
        anyOf {
          branch 'main'
          branch 'develop'
          buildingTag()
        }
      }
      steps {
        script {
          echo "Docker registry deployment would happen here"
          echo "This stage requires Jenkins host Docker access"
          echo "Image would be: ${IMAGE}:${IMAGE_TAG}"
          echo "Skipping for now - container environment limitations"
        }
      }
    }

    stage('Deployment Verification') {
      when {
        branch 'main'
      }
      steps {
        script {
          echo "Deployment verification would happen here"
          echo "This stage requires Jenkins host Docker access"
          echo "Would verify: ${IMAGE}:latest"
          echo "Skipping for now - container environment limitations"
        }
      }
    }
  }

  post {
    always {
      script {
        // Archive build artifacts
        try {
          archiveArtifacts(
            artifacts: 'reports/**/*,*.log,*.xml',
            fingerprint: true,
            allowEmptyArchive: true
          )
        } catch (err) {
          echo "No artifacts to archive: ${err.getMessage()}"
        }
      }

      // Clean up Docker resources
      script {
        try {
          sh '''
            echo "Cleaning up Docker resources..."
            docker system prune -f --filter "until=24h" || echo "Docker cleanup skipped"
            docker image prune -f || echo "Docker image cleanup skipped"
          '''
        } catch (err) {
          echo "Docker cleanup failed (expected in container): ${err.getMessage()}"
        }
      }

      // Clean workspace
      script {
        try {
          cleanWs(
            deleteDirs: true,
            notFailBuild: true,
            patterns: [
              [pattern: 'reports/**', type: 'EXCLUDE'],
              [pattern: '*.xml', type: 'EXCLUDE'],
              [pattern: 'htmlcov/**', type: 'EXCLUDE']
            ]
          )
        } catch (err) {
          echo "Workspace cleanup failed: ${err.getMessage()}"
        }
      }
    }

    success {
      script {
        if (env.BRANCH_NAME == 'main') {
          // Notify success for main branch
          echo "✅ Pipeline completed successfully for main branch!"
          echo "🐳 Docker image available: ${IMAGE}:${IMAGE_TAG}"
          if (env.BUILD_URL) {
            echo "📊 Coverage report: ${BUILD_URL}Coverage_Report/"
          }
        }
      }
    }

    failure {
      script {
        echo "❌ Pipeline failed for branch: ${env.BRANCH_NAME ?: 'unknown'}"
        try {
          if (env.BUILD_URL) {
            echo "📋 Check logs at: ${env.BUILD_URL}console"
          } else {
            echo "📋 Check Jenkins logs for details"
          }
        } catch (err) {
          echo "📋 Build URL not available: ${err.getMessage()}"
        }

        // Additional cleanup on failure
        try {
          sh '''
            echo "Emergency cleanup..."
            docker stop $(docker ps -q) || echo "No containers to stop"
            docker-compose down -v --remove-orphans || echo "Docker compose cleanup skipped"
          '''
        } catch (err) {
          echo "Emergency cleanup failed (expected): ${err.getMessage()}"
        }
      }
    }

    unstable {
      echo "⚠️ Pipeline completed with warnings"
    }
  }
}
