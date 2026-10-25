# Keycloak en Render.com

Servidor central de autenticación (OIDC / SAML) para mis proyectos web.

- Servicio web `keycloak` (Docker, Frankfurt, plan Free) construido desde este `Dockerfile`.
- Base de datos `keycloak-db` (Postgres 17, Frankfurt, plan Free; caduca el 24/11/2026).
- Credenciales en las variables de entorno del servicio en Render, nunca en este repo.

## Variables de entorno

| Variable | Valor |
|---|---|
| `PORT` | `8080` |
| `KC_DB_URL_HOST` | host interno de `keycloak-db` |
| `KC_DB_URL_PORT` | `5432` |
| `KC_DB_URL_DATABASE` | nombre de la base de datos |
| `KC_DB_USERNAME` / `KC_DB_PASSWORD` | credenciales de `keycloak-db` |
| `KC_BOOTSTRAP_ADMIN_USERNAME` / `KC_BOOTSTRAP_ADMIN_PASSWORD` | admin temporal del primer arranque |
| `KC_HOSTNAME` | opcional, p. ej. `https://auth.tudominio.com` (por defecto la URL de onrender.com) |

## Tras el primer arranque

1. Entra en `https://<url>/admin`, crea un admin permanente en `master` y borra el temporal.
2. Crea un realm para los proyectos (no uses `master` para apps).
3. Un client OIDC por proyecto, con sus Valid redirect URIs y Web origins.
4. Issuer de cada app: `https://<url>/realms/<realm>`.

## Plan gratuito

El servicio se duerme tras 15 min sin tráfico y la base de datos gratuita se borra a los 30 días
(+14 de gracia). Para usuarios reales: servicio `starter` y Postgres `basic-256mb`.
Exporta el realm periódicamente (Realm settings → Action → Partial export).
