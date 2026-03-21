# ─── Stage 1: Build ───────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /build

# Copiar archivos de dependencias
COPY package*.json ./
RUN npm ci

# Copiar fuentes
COPY . .

# Build Angular
RUN npm run build -- --configuration production

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────
FROM nginx:alpine

WORKDIR /usr/share/nginx/html

# Copiar archivos compilados desde stage anterior
COPY --from=builder /build/dist/frontend /usr/share/nginx/html/

# Copiar configuración de Nginx
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
