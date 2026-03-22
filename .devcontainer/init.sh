#!/bin/bash
set -e

# Ejecutar siempre desde la raiz del workspace.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

# Ruta a los templates Docker
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

# Forzar modo no interactivo para Angular CLI en postCreate.
export NG_CLI_ANALYTICS=false
export NG_FORCE_AUTOCOMPLETE=false

# En Codespaces, el daemon remoto puede soportar una API menor que el cliente.
export DOCKER_API_VERSION=1.43

# ─── 1. PostgreSQL 18 ────────────────────────────────────────────────────────
echo ">>> Levantando PostgreSQL 18..."
if docker ps --format '{{.Names}}' | grep -q '^postgres-dev$'; then
  echo "    postgres-dev ya esta en ejecucion"
elif docker ps -a --format '{{.Names}}' | grep -q '^postgres-dev$'; then
  docker start postgres-dev >/dev/null
else
  docker run -d \
    --name postgres-dev \
    --restart unless-stopped \
    -e POSTGRES_USER=dev \
    -e POSTGRES_PASSWORD=dev \
    -e POSTGRES_DB=appdb \
    -p 5432:5432 \
    postgres:18
fi

# ─── 2. Angular CLI ──────────────────────────────────────────────────────────
echo ">>> Instalando Angular CLI..."
npm install -g @angular/cli@latest 2>&1

# El feature de Node instala en un prefix no estándar — lo resolvemos
# dinámicamente en lugar de asumir la ruta
export PATH="$(npm config get prefix)/bin:$PATH"
echo "    ng -> $(which ng 2>/dev/null || echo 'no encontrado en PATH, usando ruta directa')"
NG_BIN="$(npm config get prefix)/bin/ng"

# Marcar como mostrado el prompt de autocompletado de Angular CLI para evitar
# preguntas interactivas al correr `ng serve` en este entorno.
echo ">>> Configurando Angular CLI (sin prompt de autocompletado)..."
node << 'EOF'
const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.HOME || '/home/vscode', '.angular-config.json');
let config = {};

if (fs.existsSync(configPath)) {
  try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch {
    config = {};
  }
}

if (!config.cli) config.cli = {};
if (!config.cli.completion) config.cli.completion = {};
config.cli.completion.prompted = true;

// Angular CLI requiere `version` para considerar valido el archivo global.
if (typeof config.version !== 'number') config.version = 1;
if (!config.projects || typeof config.projects !== 'object' || Array.isArray(config.projects)) {
  config.projects = {};
}
if (typeof config.$schema !== 'string' || config.$schema.length === 0) {
  config.$schema = './node_modules/@angular/cli/lib/config/schema.json';
}

fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n', 'utf8');
EOF
echo "    ✓ ~/.angular-config.json actualizado (cli.completion.prompted=true)"

# ─── 3. Proyecto Spring Boot + Kotlin + Gradle (solo si no existe) ────────────
if [ ! -d "backend" ]; then
  echo ">>> Generando proyecto Spring Boot (Kotlin + Gradle)..."
  BOOT_VERSION="4.0.4"
  echo "    Usando Spring Boot ${BOOT_VERSION}"
  curl -sL "https://start.spring.io/starter.zip" \
    -d type=gradle-project-kotlin \
    -d language=kotlin \
    -d bootVersion=${BOOT_VERSION} \
    -d baseDir=backend \
    -d groupId=com.darssolutionscr \
    -d artifactId=backend \
    -d javaVersion=17 \
    -d dependencies=web,data-jpa,postgresql,devtools,validation,springdoc-openapi,actuator,lombok \
    -o backend.zip
  unzip -q backend.zip
  rm backend.zip
  echo "    Spring Boot (Kotlin + Gradle) generado en ./backend"
  
  # Hacer gradlew ejecutable
  chmod +x backend/gradlew
  
  # Configurar application.properties
  echo ">>> Configurando application.properties..."
  cat > backend/src/main/resources/application.properties << 'EOF'
# ─── Configuración general ───
spring.application.name=backend

# ─── Configuración de la base de datos PostgreSQL ───

spring.datasource.url=jdbc:postgresql://localhost:5432/appdb
spring.datasource.username=dev
spring.datasource.password=dev
spring.datasource.driver-class-name=org.postgresql.Driver

spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect

# ─── SpringDoc / Swagger UI ───
springdoc.swagger-ui.path=/
springdoc.swagger-ui.operations-sorter=alpha
springdoc.swagger-ui.display-request-duration=true
EOF
  echo "    ✓ application.properties creado"

  
  # Copiar archivos Docker desde templates
  echo ">>> Copiando archivos Docker para backend desde templates..."
  cp "${TEMPLATES_DIR}/backend/Dockerfile" backend/Dockerfile
  cp "${TEMPLATES_DIR}/backend/.dockerignore" backend/.dockerignore
  echo "    ✓ Dockerfile y .dockerignore copiados"
else
  echo ">>> Carpeta backend/ ya existe, omitiendo generación Spring Boot."
  echo "    Compilando backend para verificar dependencias..."
  cd backend
  ./gradlew classes -q 2>/dev/null && echo "    ✓ Backend compilado exitosamente" || echo "    ⚠ Advertencia: backend no compila"
  cd ..
fi

# ─── 4. Proyecto Angular (solo si no existe) ──────────────────────────────────
if [ ! -d "frontend" ]; then
  echo ">>> Generando proyecto Angular..."
  # Usar ruta absoluta del binario para evitar problemas de PATH
  # Incluir --interactive=false para modo no-interactivo (devcontainer)
  "$NG_BIN" new frontend \
    --routing \
    --style=scss \
    --skip-git \
    --no-ssr \
    --defaults \
    --interactive=false
  echo "    Angular generado en ./frontend"
  
  # Copiar archivos Docker desde templates
  echo ">>> Copiando archivos Docker para frontend desde templates..."
  cp "${TEMPLATES_DIR}/frontend/Dockerfile" frontend/Dockerfile
  cp "${TEMPLATES_DIR}/frontend/.dockerignore" frontend/.dockerignore
  cp "${TEMPLATES_DIR}/frontend/nginx.conf" frontend/nginx.conf
  echo "    ✓ Dockerfile, .dockerignore y nginx.conf copiados"
else
  echo ">>> Carpeta frontend/ ya existe, omitiendo generación Angular."
fi

# ─── 5. Docker Compose ───────────────────────────────────────────────────────
echo ">>> Copiando docker-compose.yml desde templates..."
cp "${TEMPLATES_DIR}/docker-compose.yml" docker-compose.yml
echo "    ✓ docker-compose.yml copiado"

# ─── 6. Verificación de versiones ────────────────────────────────────────────
echo ">>> Verificando versiones instaladas..."
java -version
gradle --version 2>/dev/null | head -3 || echo "    Gradle wrapper disponible en backend/gradlew"
node -v
npm -v
"$NG_BIN" version --skip-confirmation 2>/dev/null || "$NG_BIN" version
docker --version

echo ""
echo "=== Entorno listo! ==="
echo ""
echo "PostgreSQL"
echo "  localhost:5432  | user=dev | pass=dev | db=appdb"
echo ""
echo "Backend (Spring Boot + Kotlin)"
echo "  Desarrollo:     cd backend && ./gradlew bootRun --args='--server.port=8081'"
echo ""
echo "Frontend (Angular)"
echo "  Desarrollo:     cd frontend && ng serve --host 0.0.0.0 --poll 2000"
echo ""
echo "Docker (Producción)"
echo "  Build images:   docker compose build"
echo "  Iniciar stack:  docker compose up -d"
echo "  Ver logs:       docker compose logs -f"
echo "  Detener:        docker compose down"
echo ""
echo "URLs desarrollo:"
echo "  Frontend:       http://localhost:4200"
echo "  Backend:        http://localhost:8081"
echo ""
echo "URL producción (Docker):"
echo "  Frontend:       http://localhost:80"
echo "  Backend:        http://localhost:8080"
echo ""

