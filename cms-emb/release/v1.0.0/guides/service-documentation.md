---
layout: default
title: "Embossing service"
---

# Embossing service

Personalisation service for LPS CMS. It claims eligible `cms_v2.card_production_request` rows, reserves them into personalisation batches, writes an ASCII-armored OpenPGP file for each reserved batch, and uploads files whose configuration uses SFTP. Vendor and courier reports are accepted on the tenant API and written to the shared outbox.

The runtime scans `com.lps.cms.embossing.perso` only. Card PAN, CVV, and track data are not decrypted in this service. A production deployment supplies them through the cms-core secure-data export. The local fixture provider is for development.

## Requirements

- Java 25
- Maven
- PostgreSQL database `cmsv2` with schema `cms_v2` already present. Flyway does not create the schema.
- CMS access-token issuer (local default: `http://localhost:9000/realms/cms`)

Core CMS tables, including production requests, cards, waybills, and batch configuration, are owned by cms-core. This service migrates only its own tables: `production_attempt`, `reconciliation_exception`, `vendor_pgp_encryption_key`, and `provider_inbox_event`.

## Run

```bash
mvn spring-boot:run
```

The `dev` profile registers with Eureka. The `prod` profile requires datasource settings and leaves fixture card data, startup pipeline runs, and SFTP off unless they are set explicitly.

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=dev
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

Local defaults listen on port **9803**. Override with `SERVER_PORT` when needed.

Tests:

```bash
mvn test
```

## Keycloak audience and roles

This service is an OAuth2 resource server. It validates access tokens from the CMS Keycloak realm and authorises callers from the token claims below. Infra must configure Keycloak so those claims are present on every token used against this API.

### Audience

| Setting | Value |
| --- | --- |
| Resource-server audience | `cms-api` |
| Env override | `CMS_AUTH_AUDIENCE` |
| Issuer (local) | `http://localhost:9000/realms/cms` |

The Keycloak client that issues tokens for CMS APIs must include `cms-api` in the token `aud` claim. Tokens without that audience are rejected.

### Roles and permissions

Authorisation is driven by the token `permissions` claim, not by Keycloak realm-role names alone. The service prefixes each permission with `PERM_` and checks the authorities below.

| Permission value in JWT | Spring authority | Purpose |
| --- | --- | --- |
| `cms:embossing:read` | `PERM_cms:embossing:read` | Read personalisation batches and files |
| `cms:embossing:manage` | `PERM_cms:embossing:manage` | Post vendor results and courier events; also satisfies read routes |

Keycloak setup for this service:

1. Create client roles or realm roles that map onto those permission strings, typically named `cms:embossing:read` and `cms:embossing:manage`.
2. Assign them to the users, groups, or service accounts that call this API.
3. Configure a protocol mapper so assigned roles are emitted in a JWT claim named `permissions` as a JSON array of strings, for example:

```json
"permissions": ["cms:embossing:read", "cms:embossing:manage"]
```

A read-only operator needs only `cms:embossing:read`. A vendor/courier integration that posts fulfilment reports needs `cms:embossing:manage`.

### Tenant and platform claims

| Claim | Required | Purpose |
| --- | --- | --- |
| `sub` | Yes | Actor id; copied into trusted request context as `X-Actor-Id` |
| `institution_id` | Yes for tenant callers | Must match `{institutionId}` in the URL path |
| `platform_access` | Optional | When `true`, the caller may act across institutions without an `institution_id` match |
| `permissions` | Yes for protected routes | Embossing read/manage authorities |

Caller-supplied `X-Institution-Id` is rejected. Tenant scoping comes only from the path and the token.

## Configuration

Shared defaults are in `src/main/resources/application.yml`. Override them with environment variables.

| Variable | Purpose | Local default |
| --- | --- | --- |
| `SPRING_DATASOURCE_URL` | JDBC URL | `jdbc:postgresql://localhost:5432/cmsv2` |
| `SPRING_DATASOURCE_USERNAME` | Database user | `postgres` |
| `SPRING_DATASOURCE_PASSWORD` | Database password | set this locally |
| `CMS_AUTH_ISSUER_URI` | JWT issuer | `http://localhost:9000/realms/cms` |
| `CMS_AUTH_JWK_SET_URI` | JWKS endpoint | issuer certs URL |
| `CMS_AUTH_AUDIENCE` | Expected audience | `cms-api` |
| `EMBOSSING_V2_CLAIM_LIMIT` | Requests claimed per run | `500` |
| `EMBOSSING_V2_FIXTURE_CARD_DATA` | Use the local test PAN provider | `true` (`false` in `prod`) |
| `EMBOSSING_SCHEDULE_CRON` | Pipeline schedule | `0 0 0 * * *` |
| `EMBOSSING_V2_ENABLED` | Enable the schedule | `true` |
| `EMBOSSING_RUN_ON_STARTUP` | Run once after startup | `true` (`false` in `prod`) |
| `EMBOSSING_SFTP_ENABLED` | Upload generated files | `true` (`false` in `prod`) |
| `EMBOSSING_SFTP_HOST` | SFTP host | `localhost` |
| `EMBOSSING_SFTP_PORT` | SFTP port | `2222` |
| `EMBOSSING_SFTP_USERNAME` | SFTP user | `embossing` |
| `EMBOSSING_SFTP_PASSWORD` | SFTP password | `embossing` |
| `EMBOSSING_SFTP_REMOTE_PATH` | Remote drop directory | `/upload` |

Encrypted files are written under `embossing.output-path` (`./embossing-output`). Each institution and vendor needs exactly one `ACTIVE` row in `cms_v2.vendor_pgp_encryption_key`.

Leave `EMBOSSING_V2_FIXTURE_CARD_DATA` false outside local development. With it false and no secure-data provider on the classpath, file generation fails closed.

## Pipeline

Each run, when the schedule or startup trigger fires:

1. Lock eligible production requests and reserve them.
2. Group them by institution, vendor, configuration, product, and request type, then split each group at the configuration's maximum batch size.
3. Pair each item with an available waybill. Requests that cannot be paired stay eligible.
4. Write one `.gpg` file per reserved batch and record cleartext and ciphertext SHA-256 checksums.
5. Upload files that are ready for SFTP. One failed upload does not stop the others.

A separate reconciliation job records unresolved fulfilment mismatches. Vendor and courier callbacks are deduplicated in `provider_inbox_event` and published as CMS fulfilment commands.

## HTTP API

All routes are under `/cms/api/v2` and require a bearer access token configured as described in [Keycloak audience and roles](#keycloak-audience-and-roles). List endpoints use a 1-based `page` and a `limit` of at most 100.

| Method | Path | Permission |
| --- | --- | --- |
| `GET` | `/cms/api/v2/institutions/{institutionId}/personalisation-batches` | `cms:embossing:read` |
| `GET` | `/cms/api/v2/institutions/{institutionId}/personalisation-batches/{batchId}` | `cms:embossing:read` |
| `GET` | `/cms/api/v2/institutions/{institutionId}/personalisation-batches/{batchId}/files` | `cms:embossing:read` |
| `GET` | `/cms/api/v2/institutions/{institutionId}/personalisation-files/{fileId}` | `cms:embossing:read` |
| `POST` | `/cms/api/v2/institutions/{institutionId}/vendor-results` | `cms:embossing:manage` |
| `POST` | `/cms/api/v2/institutions/{institutionId}/courier-events` | `cms:embossing:manage` |

Batch list accepts an optional `status` query parameter. Vendor `result` is one of `ACCEPTED`, `PERSONALIZED`, `FILE_COMMITTED`, `FAILED`. Courier `eventType` is one of `DISPATCHED`, `DELIVERED`, `RETURNED`, `REDISPATCHED`.

OpenAPI docs are at `/swagger-ui.html` and `/api-docs`.

## Local SFTP

`vendor-sftp-test` runs a Docker SFTP drop on `localhost:2222`. See [vendor-sftp-test/README.md](vendor-sftp-test.html).

To inspect a generated file:

```text
DecryptGpgUtil <file.gpg> <priv-key.asc> [passphrase] [output-file]
```

Run it from `com.lps.cms.embossing.tools.DecryptGpgUtil`. An omitted passphrase, or `-`, unlocks an unprotected key only.
