# Keycloak para Render.com
# Fase 1: build optimizado con PostgreSQL y health checks activados
FROM quay.io/keycloak/keycloak:26.7.2 AS builder

ENV KC_DB=postgres
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=false

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
# Ajuste de memoria para instancias pequeñas (512 MB)
ENV JAVA_OPTS_KC_HEAP="-XX:MaxRAMPercentage=65 -XX:InitialRAMPercentage=40"

EXPOSE 8080

# Si no defines KC_HOSTNAME, usa la URL pública que Render inyecta (RENDER_EXTERNAL_URL)
ENTRYPOINT ["/bin/bash", "-c", "export KC_HOSTNAME=\"${KC_HOSTNAME:-$RENDER_EXTERNAL_URL}\"; exec /opt/keycloak/bin/kc.sh start --optimized"]
