# Keycloak para Render.com — ajustado para el plan Free (512 MB RAM, 0.1 CPU)

# Fase 1: build optimizado
FROM quay.io/keycloak/keycloak:26.7.2 AS builder

ENV KC_DB=postgres
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=false
# Una sola instancia: caché local, sin clúster (ahorra memoria y el arranque de JGroups/Infinispan distribuido)
ENV KC_CACHE=local

WORKDIR /opt/keycloak
RUN /opt/keycloak/bin/kc.sh build

# Fase 2: imagen final
FROM quay.io/keycloak/keycloak:26.7.2
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Render termina el TLS en su proxy y reenvía HTTP al contenedor
ENV KC_DB=postgres
ENV KC_HTTP_ENABLED=true
ENV KC_HTTP_PORT=8080
ENV KC_PROXY_HEADERS=xforwarded

# --- Ahorro de memoria ---
# JVM: heap limitado, GC ligero, sin compilador C2, pilas y caché de código pequeñas
ENV JAVA_OPTS_KC_HEAP="-XX:MaxRAMPercentage=45 -XX:InitialRAMPercentage=25 -XX:MaxMetaspaceSize=200m -XX:ReservedCodeCacheSize=48m -Xss512k -XX:+UseSerialGC -XX:TieredStopAtLevel=1 -XX:+ExitOnOutOfMemoryError"
# Memoria nativa: menos arenas de malloc (glibc reserva mucha memoria por hilo)
ENV MALLOC_ARENA_MAX=2
# Pool de conexiones a la base de datos pequeño (la Postgres free admite pocas conexiones)
ENV KC_DB_POOL_INITIAL_SIZE=1
ENV KC_DB_POOL_MIN_SIZE=1
ENV KC_DB_POOL_MAX_SIZE=5
# Menos hilos HTTP de trabajo
ENV KC_HTTP_POOL_MAX_THREADS=16
# Cachés en memoria más pequeñas (por defecto 10000 entradas cada una)
ENV KC_CACHE_EMBEDDED_REALMS_MAX_COUNT=500
ENV KC_CACHE_EMBEDDED_USERS_MAX_COUNT=1000
ENV KC_CACHE_EMBEDDED_AUTHORIZATION_MAX_COUNT=500
ENV KC_CACHE_EMBEDDED_KEYS_MAX_COUNT=200

EXPOSE 8080

# Si no defines KC_HOSTNAME, usa la URL pública que Render inyecta (RENDER_EXTERNAL_URL)
ENTRYPOINT ["/bin/bash", "-c", "export KC_HOSTNAME=\"${KC_HOSTNAME:-$RENDER_EXTERNAL_URL}\"; exec /opt/keycloak/bin/kc.sh start --optimized"]
