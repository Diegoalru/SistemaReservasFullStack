# Devcontainer: Spring Boot + Angular + PostgreSQL

Plantilla de desarrollo para levantar un entorno completo con:
- Java 17 (JDK Microsoft)
- Gradle y Maven disponibles en el contenedor
- Node.js 24 y Angular CLI
- PostgreSQL 18
- Docker y Docker Compose (docker-outside-of-docker)

## Flujo del repositorio

Al crear el Codespace, el postCreateCommand ejecuta .devcontainer/init.sh y automatiza:
1. Levantar PostgreSQL local en localhost:5432
2. Instalar Angular CLI globalmente
3. Generar backend Spring Boot (Kotlin + Gradle) en la carpeta backend si no existe
4. Generar frontend Angular en la carpeta frontend si no existe
5. Copiar Dockerfile/.dockerignore para backend y frontend
6. Copiar docker-compose.yml desde plantillas

Nota: si backend o frontend ya existen, el script no los regenera.

## URLs de desarrollo

- Frontend Angular: http://localhost:4200
- Backend Spring Boot: http://localhost:8081
- Swagger UI (inicio del backend): http://localhost:8081/
- OpenAPI JSON: http://localhost:8081/v3/api-docs

La configuración del backend deja Swagger en la raíz mediante:
- springdoc.swagger-ui.path=/

## Puertos expuestos del devcontainer

| Puerto | Uso |
|---|---|
| 8081 | Backend en modo desarrollo (gradlew bootRun) |
| 8080 | Backend en modo Docker |
| 4200 | Frontend en modo desarrollo (ng serve) |
| 80 | Frontend en modo Docker (nginx) |
| 5432 | PostgreSQL de desarrollo (auto en devcontainer) |
| 5433 | PostgreSQL de Docker Compose (entorno prod local) |

## Comandos útiles

### Desarrollo (sin Docker Compose)

```bash
# Backend
cd backend
./gradlew bootRun --args='--server.port=8081'

# Frontend (en otra terminal)
cd frontend
ng serve --host 0.0.0.0 --poll 2000
```

### Producción local con Docker Compose

```bash
docker compose build
docker compose up -d
docker compose logs -f
docker compose down
```

## Base de datos

### Entorno desarrollo (devcontainer)

- Host: localhost
- Puerto: 5432
- Base de datos: appdb
- Usuario: dev
- Password: dev

Cadena JDBC (desarrollo):

```text
jdbc:postgresql://localhost:5432/appdb
```

### Entorno prod local (docker compose)

- Host: localhost
- Puerto: 5433
- Base de datos: appdb
- Usuario: dev
- Password: dev

Cadena JDBC (acceso desde host/devcontainer):

```text
jdbc:postgresql://localhost:5433/appdb
```

Nota: dentro de la red interna de Docker Compose, el backend se conecta a PostgreSQL con el puerto 5432 del servicio `postgres`.

## Re-ejecutar bootstrap manualmente

Si necesitas regenerar o reaplicar configuración base:

```bash
bash .devcontainer/init.sh
```
