---
layout: default
title: "CMS API Gateway — v1.0.0"
---

# CMS API Gateway — v1.0.0

**Version:** 1.0.0 — initial delivery baseline; the current POM is `1.0.0-SNAPSHOT`.  
**Planned tag:** `1.0.0`; final tagged source identity is **Not confirmed**.  
**Release Date:** Not confirmed  
**Release Type:** Major — initial baseline  
**Environment:** Not confirmed  
**Scope:** CMS API routing, token validation, request context, Redis rate limiting, and shared API documentation.  
**Notes updated:** 19 October 2026

## Deployment summary

| Item | Status |
| --- | --- |
| Source baseline | `0d8c646c936818411edc561cf37888fd3f762450` plus local test/coverage and documentation changes |
| Application artifact | Current POM: `com.xenomi.cms:cms-api-gateway:1.0.0-SNAPSHOT`; align to 1.0.0 before final publication |
| Release identity | Planned tag `1.0.0` / `refs/tags/1.0.0`; no local tag verified; tagged SHA, creation date, and tagger not confirmed |
| Routing compatibility | Dedicated Embossing predicates do not match the current institution-scoped Embossing API |
| Database | No relational schema or Flyway migrations; Redis required for rate limiting |

No tag was created. No previous release tag is used for comparison; capabilities describe the supplied baseline. The final release commit must include the selected local changes and the approved version alignment.

## Overview

CMS API Gateway provides a reactive entry point for CMS services. It validates bearer tokens, forwards requests to configured private destinations, applies request limits, and exposes a shared Swagger UI. Fine-grained business authorization and institution ownership checks remain with downstream services.

## Features

- **Service routing:** Routes configured Core, Customer, Notification, and Embossing/Vendor path groups to environment-specific destinations, preserving business request paths.
- **Shared documentation:** Proxies Core, Customer, and Embossing OpenAPI definitions into one Swagger UI.
- **Request correlation:** Validates or generates `X-Request-Id` and returns it in the response.
- **Rate limiting:** Uses Redis-backed limits keyed by authenticated subject, with remote-IP and unknown-client fallbacks.
- **Operational visibility:** Logs request/completion information and exposes configured health, information, metrics, and gateway management endpoints.

## Security

- Validates JWT signatures, time claims, exact issuer, and the required audience (`cms-api` by default); forwards the original bearer token downstream.
- Maps the `permissions` claim to `PERM_*` authorities. Internal routes require `cms:internal:access`; metrics and gateway management require `cms:gateway:admin`.
- Removes caller-supplied `X-Actor-Id`, `X-Institution-Id`, and `X-User-Id` headers.
- Supplies JSON authentication/authorization errors and configurable CORS origins. Documentation, health, and information endpoints are public under the current rules.

## Reliability and maintenance

- **Read retries:** GET/HEAD requests can be retried three times for BAD_GATEWAY or SERVICE_UNAVAILABLE, with exponential backoff. Writes are not automatically retried.
- **Configured request limits:** Customer replenishment/burst values are 100/200; other business routes use 1,000/2,000. Each request consumes one token.
- **Automated verification:** Tests cover request IDs, identity-header removal, filter behavior, rate-limit keys, permission mapping, CORS, security responses, and signed-JWT acceptance/rejection.
- **Coverage checks:** `mvn verify` enforces 90% line and 80% branch coverage. No throughput or latency improvement is claimed.

## Pre-release corrections and bug fixes

The verified development history includes these compatibility corrections:

- **Framework configuration:** Gateway routes and default filters were moved to the WebFlux gateway-server configuration structure used by the upgraded stack. Deployment overrides must use that structure.
- **Security response serialization:** Security error handling uses the Jackson 3 API required by Spring Boot 4.
- **Documentation availability:** The unavailable Ops Copilot documentation route and Swagger selector entry are disabled. Its APIs remain outside this gateway's business routing.

Embossing/Vendor path predicates were changed from V1 to V2 during development; this is a routing-contract change, not evidence that the current institution-scoped Embossing integration works. The mismatch remains a known limitation below.

## JUnit test results

The verified **16 October 2026** run completed using `mvn clean verify`:

| Tests reported | Passed | Failures | Errors | Skipped |
| --- | --- | --- | --- | --- |
| 41 | 41 | 0 | 0 | 0 |

Five suites completed successfully. Signed-JWT tests use a temporary loopback JWKS server and require permission to bind localhost. No running Redis, Keycloak, or backend service is used by this suite. These are existing results, not a new run on 19 October.

## Measured code coverage

| Metric | Measured result |
| --- | --- |
| Line coverage | 98.08% — 102 / 104 lines |
| Branch coverage | 95.00% — 19 / 20 branches |
| Enforced minimums | 90% lines; 80% branches |

Only `CmsApiGatewayApplication` is excluded from Java coverage. The verified run passed the verify-phase gate. Java coverage does not measure YAML routing or establish live Redis/backend interoperability. See the [JaCoCo report](test-report/jacoco/index.html) and [JUnit XML evidence](#junit-xml-evidence).

## Requirements and compatibility

| Component | Requirement / behavior |
| --- | --- |
| Java | Java 25 |
| Framework | Spring Boot 4.1.1; Spring Cloud BOM 2025.1.3; Springdoc 3.1.0 |
| Gateway | Reactive WebFlux gateway server |
| HTTP port | Active YAML default 8080; configurable |
| External dependencies | Redis, token issuer/JWKS, and configured CMS services |
| Database | No service-owned relational database |

Configured business route groups:

| Backend | Path predicates | Default destination |
| --- | --- | --- |
| CMS Core | `/cms/api/v1/**`, `/cms/api/v2/**` | localhost:9800 |
| Customer | `/api/v1/customers/**`, `/api/v1/addresses/**`, `/api/v2/institutions/{institutionId}/customers/**`, `/api/v2/institutions/{institutionId}/accounts/**` | localhost:9801 |
| Notification | `/api/v1/notifications/**` | localhost:9802 |
| Embossing/Vendor | `/api/v2/embossing/**`, `/api/v2/vendors/**` | localhost:9803 |

Swagger UI is `/swagger-ui.html`. Public proxies `/docs/core/api-docs`, `/docs/customer/api-docs`, and `/docs/embossing-vendor/api-docs` rewrite to `/api-docs` at the selected backend. Customer V1 predicates do not restore the removed Customer V1 APIs.

## Deployment prerequisites

No relational migration is supplied by this service. Provision Redis and reachable backend/identity endpoints before enabling business traffic.

| Configuration | Required setup |
| --- | --- |
| SERVER_PORT | Match gateway listener and infrastructure; YAML default 8080 |
| CMS_AUTH_ISSUER_URI / CMS_AUTH_JWK_SET_URI / CMS_AUTH_AUDIENCE | Trusted issuer, signing keys, and audience |
| CMS_CORE_URI / CUSTOMER_SERVICE_URI | Approved private Core and Customer destinations |
| NOTIFICATION_SERVICE_URI / EMB_VENDOR_SERVICE_URI | Approved private Notification and Embossing destinations |
| REDIS_HOST / REDIS_PORT | Redis endpoint; defaults cms-redis:6379 |
| CMS_ALLOWED_ORIGINS | Explicit approved browser origins |

Client/deployment actions: confirm environment and release date; align the gateway version and final source identity; configure issuer and permissions; resolve Embossing routing; provision Redis; align ports and service destinations; complete integration and access-boundary tests.

## Build and deployment

Build the final selected source using `mvn clean verify`. The current POM produces `target/cms-api-gateway-1.0.0-SNAPSHOT.jar`; update the approved release build metadata to 1.0.0 before publishing the final version. The final artifact checksum, deployment, and environment acceptance are not confirmed.

Configure the approved private backend addresses and expose the gateway through the target HTTPS entry point. Restart after configuration changes. Preserve the test evidence before cleaning the build directory.

## Deployment verification

- Verify public health and documentation, authenticated business calls, and 401/403 responses.
- Verify request-ID propagation, caller identity-header removal, permission mapping, and CORS.
- Verify Redis enforcement, route destinations, read retry behavior, and write handling.
- Confirm the current Customer V2 contract and resolve institution-scoped Embossing routes before enabling them through this gateway.

## Known limitations

- **Embossing routing:** Current Embossing APIs use `/cms/api/v2/institutions/{institutionId}/personalisation-*`, `/vendor-results`, and `/courier-events`. They miss the dedicated Embossing predicates and match the broad Core route instead. Align the route contract before exposing these flows.
- **Legacy predicates:** Customer V1 routes remain in gateway configuration, but the current Customer service exposes V2 only.
- **Documentation scope:** Ops Copilot routing and its Swagger entry are disabled.
- **Release identity:** The POM remains SNAPSHOT, local test/coverage changes are uncommitted, and the final tagged commit is not confirmed.
- **Integration readiness:** YAML routing, live Redis/backend behavior, and deployment approval are outside the automated Java test evidence.

## Rollback

Stop or withdraw the new gateway deployment if initial verification fails. If replacing an existing gateway, retain its exact approved artifact/configuration and confirm backend compatibility before restoration. Gateway rollback does not reverse business operations already processed downstream; coordinate traffic handling with backend owners.

## References

- [Service documentation](guides/service-documentation.html)
- [Keycloak configuration](guides/KEYCLOAK_CONFIGURATION.html)
- [CMS deployment guide](guides/CMS_ECOSYSTEM_DEPLOYMENT_GUIDE.html)
- [JUnit XML evidence](#junit-xml-evidence)
- [Full JaCoCo coverage](test-report/jacoco/index.html)


## Bundled release documentation

The linked guides are copied with this release for review without source-repository access. Reports preserve the existing verification evidence; no new tests were run for this documentation update.

- [JUnit test results](test-report/junit/index.html)
- [JaCoCo coverage report](test-report/jacoco/index.html)

## JUnit XML evidence

The copied XML excludes environment properties and embedded test output.

- [TEST-com.xenomi.cms.gateway.config.JwtDecoderTest](test-report/surefire-reports/TEST-com.xenomi.cms.gateway.config.JwtDecoderTest.xml)
- [TEST-com.xenomi.cms.gateway.config.RateLimiterConfigTest](test-report/surefire-reports/TEST-com.xenomi.cms.gateway.config.RateLimiterConfigTest.xml)
- [TEST-com.xenomi.cms.gateway.config.SecurityConfigTest](test-report/surefire-reports/TEST-com.xenomi.cms.gateway.config.SecurityConfigTest.xml)
- [TEST-com.xenomi.cms.gateway.filter.LoggingFilterTest](test-report/surefire-reports/TEST-com.xenomi.cms.gateway.filter.LoggingFilterTest.xml)
- [TEST-com.xenomi.cms.gateway.filter.RequestContextWebFilterTest](test-report/surefire-reports/TEST-com.xenomi.cms.gateway.filter.RequestContextWebFilterTest.xml)
