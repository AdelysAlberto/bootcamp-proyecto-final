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
          git --version
          git log --oneline -5
          echo "=== Docker Information ==="
          docker --version || echo "Docker not available"
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
            docker.io \
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
          def shortSha = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
          def branch = env.BRANCH_NAME ?: 'local'
          env.IMAGE_TAG = (env.TAG_NAME ?: "${branch}-${shortSha}").replaceAll('[^a-zA-Z0-9_.-]', '-')
          env.BUILD_DATE = sh(returnStdout: true, script: 'date -u +"%Y-%m-%dT%H:%M:%SZ"').trim()
        }

        sh '''
          echo "Building Docker image: ${IMAGE}:${IMAGE_TAG}"

          # Build the image with build args
          docker build \
            --build-arg BUILD_DATE="${BUILD_DATE}" \
            --build-arg VCS_REF="$(git rev-parse HEAD)" \
            --build-arg VERSION="${IMAGE_TAG}" \
            -t ${IMAGE}:${IMAGE_TAG} \
            -t ${IMAGE}:latest \
            .

          echo "Testing Docker image..."
          # Test that the image runs correctly
          docker run --rm -d --name test-container -p 5001:5000 ${IMAGE}:${IMAGE_TAG}

          # Wait for container to start
          sleep 10

          # Test health endpoint
          curl -f http://localhost:5001/health || (docker logs test-container && exit 1)

          # Clean up test container
          docker stop test-container || true

          echo "Docker image built and tested successfully!"
          docker images | grep ${APP_NAME}
        '''
      }
      post {
        always {
          sh 'docker stop test-container || true'
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
        sh '''
          echo "Running integration tests with Docker Compose..."

          # Start services
          docker-compose -f docker-compose.yml up -d postgres

          # Wait for PostgreSQL to be ready
          echo "Waiting for PostgreSQL to be ready..."
          for i in {1..30}; do
            if docker-compose exec -T postgres pg_isready -h localhost -p 5432; then
              echo "PostgreSQL is ready!"
              break
            fi
            echo "Waiting for PostgreSQL... ($i/30)"
            sleep 2
          done

          # Run integration tests against real database
          echo "Running integration tests..."
          FLASK_ENV=testing DATABASE_URL="postgresql://postgres:postgres@localhost:5432/postgres" \
            ./test.sh -i -v

          echo "Integration tests completed successfully!"
        '''
      }
      post {
        always {
          sh '''
            echo "Cleaning up Docker Compose services..."
            docker-compose down -v --remove-orphans || true
          '''
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
          if (env.REGISTRY == 'ghcr.io') {
            withCredentials([usernamePassword(credentialsId: 'ghcr-token', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
              sh '''
                echo "Logging into GitHub Container Registry..."
                echo "$REG_PASS" | docker login ${REGISTRY} -u "$REG_USER" --password-stdin
              '''
            }
          } else {
            withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
              sh '''
                echo "Logging into Docker Hub..."
                echo "$REG_PASS" | docker login ${REGISTRY} -u "$REG_USER" --password-stdin
              '''
            }
          }
        }

        sh '''
          echo "Pushing Docker images..."

          # Push the tagged image
          docker push ${IMAGE}:${IMAGE_TAG}
          echo "✓ Pushed ${IMAGE}:${IMAGE_TAG}"

          # Tag and push latest for main branch or tags
          if [ "${BRANCH_NAME}" = "main" ] || [ -n "${TAG_NAME}" ]; then
            echo "Tagging and pushing as latest..."
            docker tag ${IMAGE}:${IMAGE_TAG} ${IMAGE}:latest
            docker push ${IMAGE}:latest
            echo "✓ Pushed ${IMAGE}:latest"
          fi

          # Push branch-specific tag for develop
          if [ "${BRANCH_NAME}" = "develop" ]; then
            docker tag ${IMAGE}:${IMAGE_TAG} ${IMAGE}:develop
            docker push ${IMAGE}:develop
            echo "✓ Pushed ${IMAGE}:develop"
          fi

          echo "All images pushed successfully!"
        '''
      }
    }

    stage('Deployment Verification') {
      when {
        branch 'main'
      }
      steps {
        sh '''
          echo "Verifying deployment..."

          # Pull and test the pushed image
          docker pull ${IMAGE}:latest

          # Run a quick smoke test
          docker run --rm -d --name smoke-test -p 5002:5000 ${IMAGE}:latest
          sleep 15

          # Test endpoints
          curl -f http://localhost:5002/health

          # Cleanup
          docker stop smoke-test

          echo "✓ Deployment verification completed successfully!"
        '''
      }
      post {
        always {
          sh 'docker stop smoke-test || true'
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
      sh '''
        echo "Cleaning up Docker resources..."
        docker system prune -f --filter "until=24h" || true
        docker image prune -f || true
      '''

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
        if (env.BUILD_URL) {
          echo "📋 Check logs at: ${BUILD_URL}console"
        }

        // Additional cleanup on failure
        sh '''
          echo "Emergency cleanup..."
          docker stop $(docker ps -q) || true
          docker-compose down -v --remove-orphans || true
        '''
      }
    }

    unstable {
      echo "⚠️ Pipeline completed with warnings"
    }
  }
}
