---
layout: default
title: "CMS API Gateway"
---

# CMS API Gateway

For the complete service topology, deployment order, environment configuration,
verification steps, and production checklist, see the
[CMS ecosystem deployment and configuration guide](CMS_ECOSYSTEM_DEPLOYMENT_GUIDE.html).

For realm, client, claim mapper, permission, tenant, service-account and
troubleshooting instructions, see
[Keycloak configuration](KEYCLOAK_CONFIGURATION.html).

The gateway validates the same Keycloak access token as CMS Core and forwards the
original bearer token to downstream services. CMS Core remains responsible for
fine-grained domain authorization and institution ownership checks.

## Runtime prerequisites

- An OIDC provider containing the `cms` realm
- CMS services reachable through private DNS or ECS Service Connect
- Redis on port `6379` for gateway rate limiting

Start Redis locally, for example:

```bash
docker run --name cms-redis -p 127.0.0.1:6379:6379 redis:7-alpine
```

## Run

```bash
CMS_AUTH_ISSUER_URI=http://localhost:9000/realms/cms \
CMS_AUTH_JWK_SET_URI=http://localhost:9000/realms/cms/protocol/openid-connect/certs \
CMS_AUTH_AUDIENCE=cms-api \
CMS_CORE_URI=http://localhost:8081 \
REDIS_HOST=localhost \
mvn spring-boot:run
```

The gateway listens on `http://localhost:9700` by default. Call CMS through the
gateway without changing the CMS path:

```bash
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:9700/cms/api/v2/institutions
```

## Swagger UI

The gateway hosts one Swagger UI for the downstream services that currently
publish OpenAPI contracts:

```text
http://localhost:9700/swagger-ui.html
```

Use the definition selector in Swagger UI to switch between CMS Core, CMS
Customer, CMS Embossing & Vendor, and Ops Copilot. Their proxied OpenAPI
documents are available below `/docs`. Documentation endpoints are public so
the UI can load; business API calls still require a bearer token.

## AWS ECS Service Connect

Local defaults use localhost and each service's development port. In production,
set the following variables to the ECS Service Connect-compatible short names:

- `cms-core-service:9701`
- `cms-customer-service:9702`
- `cms-notification-service:9703`
- `cms-emb-vendor-service:9704`

Override destinations with `CMS_CORE_URI`, `CUSTOMER_SERVICE_URI`,
`NOTIFICATION_SERVICE_URI`, or `EMB_VENDOR_SERVICE_URI`.

Enable Service Connect on the gateway as a client service and on every backend
as a client-server service in the same namespace. Eureka is not required. The
gateway container listens on `9700`; expose it through an HTTPS Application Load
Balancer, and keep the four backend services private.

The gateway preserves `/api/...` paths because the downstream controllers use
those complete paths. It does not route Ops Copilot, which should remain on a
separate administrative network endpoint.

## Security contract

- JWT issuer must equal `CMS_AUTH_ISSUER_URI`.
- JWT audience must contain `CMS_AUTH_AUDIENCE` (`cms-api` by default).
- The top-level `permissions` claim is mapped to `PERM_*` authorities.
- `/internal/**` requires `cms:internal:access`.
- Gateway metrics/routes require `cms:gateway:admin`.
- `X-Actor-Id`, `X-Institution-Id`, and `X-User-Id` supplied by callers are removed.
- `X-Request-Id` is validated or generated and returned in the response.
- Automatic retries apply only to `GET` and `HEAD`.

For production, terminate TLS at the Application Load Balancer, use a production
OIDC provider and managed Redis, store secrets in AWS Secrets Manager or SSM
Parameter Store, and configure an explicit CORS origin list.

## Tests and coverage

Use JDK 25 and Maven to run the JUnit Jupiter suite:

```bash
mvn clean verify
```

The suite covers request-ID validation and identity-header removal, logging-filter
chain behavior, principal/IP rate-limit keys, permission mapping, endpoint access
rules, JSON security errors, CORS settings, and signed JWT validation (issuer,
audience, expiration, and signature). Tests need no running Redis, Keycloak, or
backend services. JWT tests start a temporary JWKS server on a random loopback
port, so the test process must be allowed to bind to localhost.

JaCoCo generates reports during `mvn test`; `mvn verify` also enforces at least
90% line coverage and 80% branch coverage across the gateway. Only the application
bootstrap class is excluded. Reports are available at:

- HTML: `target/site/jacoco/index.html`
- XML (for CI ingestion): `target/site/jacoco/jacoco.xml`
- JUnit XML and text results: `target/surefire-reports/`

Coverage reports exercise Java behavior; they do not measure YAML route definitions
or replace end-to-end checks against deployed downstream services.
