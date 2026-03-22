# ─── Stage 1: Build ───────────────────────────────────────────────────────
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /build

# Copiar Gradle wrapper y archivos de configuración
COPY gradlew .
COPY gradle ./gradle
COPY build.gradle.kts settings.gradle.kts ./
COPY src ./src

# Dar permisos al wrapper y construir
RUN chmod +x gradlew && ./gradlew bootJar -x test -q

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copiar JAR desde stage anterior
COPY --from=builder /build/build/libs/*.jar app.jar

# Metadata
EXPOSE 8080
ENV PORT=8080

# Comando de inicio
ENTRYPOINT ["java", "-jar", "app.jar"]
CMD ["--server.port=${PORT}"]
