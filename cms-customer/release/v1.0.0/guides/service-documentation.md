---
layout: default
title: "Customer Management Service"
---

# Customer Management Service

Spring Boot microservice for institution-scoped customer profiles, postal addresses, and external account relationships in the LPS CMS platform.

Customer Service owns customer and address PII. Downstream services such as CMS Core should store only the returned UUIDs (`customerReferenceId`, `addressReferenceId`, `externalAccountReferenceId`).

## Table of Contents

- [Overview](#overview)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Identifiers and JSON contract](#identifiers-and-json-contract)
- [API Endpoints (V2)](#api-endpoints-v2)
  - [Customer endpoints](#customer-endpoints)
  - [Address endpoints](#address-endpoints)
  - [Account endpoints](#account-endpoints)
  - [Customer–account link endpoints](#customeraccount-link-endpoints)
- [Enumerations](#enumerations)
- [Response envelopes and errors](#response-envelopes-and-errors)
- [Keycloak Configuration](#keycloak-configuration)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [API Summary](#api-summary)

---

## Overview

V2 provides RESTful, institution-scoped APIs for:

- **Customers** — onboard, resolve, list, update profile, and change lifecycle status
- **Addresses** — create, list, get, update details, and change status for a customer
- **External accounts** — register opaque credit-card or prepaid references (no PAN or balances)
- **Customer–account links** — create and close relationships between customers and accounts

Base path:

```text
/api/v2/institutions/{institutionId}/...
```

`{institutionId}` is a UUID and must match the tenant claim in the bearer token (unless `platform_access` is true).

Legacy V1 routes under `/api/v1/**` have been removed; this service exposes only the V2 contract.

---

## Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| Java | 25 | Language |
| Spring Boot | 4.1.1 | Application framework |
| Spring Security OAuth2 Resource Server | - | JWT validation |
| Spring Data JPA | - | Persistence |
| PostgreSQL | - | Database (`cms_v2` schema) |
| Flyway | - | Migrations |
| Springdoc OpenAPI | - | Swagger UI |
| Maven | - | Build |

---

## Project Structure

```text
src/main/java/com/lps/cms/customer/
├── CustomerServiceApplication.java
├── infra/config/                 # Security, OpenAPI
├── api/exception/                # Shared BadRequestException, ResourceNotFoundException
└── v2/
    ├── boundary/
    │   ├── controller/           # CustomerBoundaryV2Controller, AccountBoundaryV2Controller
    │   ├── service/              # BoundaryReferenceV2Service
    │   ├── dto/
    │   ├── entity/
    │   ├── model/                # Enums
    │   └── repository/
    ├── common/                   # Envelopes, filters, exception handler, idempotency
    └── security/                 # V2TenantAccess
```

---

## Identifiers and JSON contract

| Concept | Type in V2 | Example |
|---------|------------|---------|
| Institution | `UUID` | `11111111-1111-1111-1111-111111111111` |
| Customer reference | `UUID` | `22222222-2222-2222-2222-222222222222` |
| Address reference | `UUID` | `33333333-3333-3333-3333-333333333333` |
| External account reference | `UUID` | `44444444-4444-4444-4444-444444444444` |
| Customer–account link | `UUID` | `55555555-5555-5555-5555-555555555555` |

JSON property names are **camelCase** (`customerReferenceId`, `firstName`), matching the Java records.

Write operations (`POST` / `PUT`) require header `Idempotency-Key` (1–128 chars: `A-Za-z0-9._:-`). Optional `X-Request-Id` is echoed for correlation.

---

## API Endpoints (V2)

Unless noted, successful responses use:

```json
{
  "success": true,
  "data": { },
  "meta": {
    "requestId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "timestamp": "2026-01-28T10:30:00Z"
  }
}
```

Creates return HTTP `201`. Reads and updates return HTTP `200`.

### Customer endpoints

Base: `/api/v2/institutions/{institutionId}/customers`

#### Create customer

| Property | Value |
|----------|-------|
| **URL** | `POST /api/v2/institutions/{institutionId}/customers` |
| **Permission** | `cms:customer:manage` |
| **Body** | `CreateCustomerReferenceV2Request` |

**Request:**

```json
{
  "sourceSystem": "CORE_BANKING",
  "externalCustomerId": "CUST-100045",
  "customerType": "INDIVIDUAL",
  "title": "MR",
  "firstName": "Pavan",
  "middleName": "K",
  "lastName": "Kumar",
  "dateOfBirth": "1990-05-15",
  "mobileCountryCode": "+91",
  "mobileNumber": "9876543210",
  "email": "pavan@example.com",
  "status": "ACTIVE"
}
```

**Response `data`:**

```json
{
  "customerReferenceId": "22222222-2222-2222-2222-222222222222",
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "sourceSystem": "CORE_BANKING",
  "externalCustomerId": "CUST-100045",
  "customerType": "INDIVIDUAL",
  "title": "MR",
  "firstName": "Pavan",
  "middleName": "K",
  "lastName": "Kumar",
  "dateOfBirth": "1990-05-15",
  "mobileCountryCode": "+91",
  "mobileNumber": "9876543210",
  "email": "pavan@example.com",
  "customerStatus": "ACTIVE",
  "createdAt": "2026-01-28T10:30:00Z",
  "updatedAt": "2026-01-28T10:30:00Z",
  "createdBy": "user-42",
  "updatedBy": "user-42"
}
```

#### List customers

`GET .../customers?status=ACTIVE&page=1&limit=20`

`page` defaults to `1`, `limit` defaults to `20` (max `100`). Response `data` is a `PagedResponseV2` with `content`, `page`, `size`, `totalElements`, `totalPages`, `first`, `last`.

#### Resolve by external identity

`GET .../customers/resolve?sourceSystem=CORE_BANKING&externalCustomerId=CUST-100045`

#### Get by UUID

`GET .../customers/{customerReferenceId}`

#### Update status

`POST .../customers/{customerReferenceId}/actions/update-status`

```json
{ "status": "BLOCKED" }
```

Allowed transitions: `ACTIVE` → `INACTIVE` / `BLOCKED` / `CLOSED`; `INACTIVE` or `BLOCKED` → `ACTIVE` / `CLOSED`; `CLOSED` is terminal.

#### Update profile

`POST .../customers/{customerReferenceId}/actions/update-profile`

At least one mutable field required. Closed customers cannot be updated.

```json
{
  "title": "DR",
  "firstName": "Pavan",
  "email": "pavan.kumar@example.com"
}
```

---

### Address endpoints

Base: `/api/v2/institutions/{institutionId}/customers/{customerReferenceId}/addresses`

#### Create address

| Property | Value |
|----------|-------|
| **URL** | `POST .../addresses` |
| **Permission** | `cms:customer:manage` |

Customer must be `ACTIVE`.

```json
{
  "sourceSystem": "CUSTOMER_SERVICE",
  "externalAddressId": "ADDR-9000123",
  "addressType": "SHIPPING",
  "addressLine1": "12 MG Road",
  "addressLine2": "Indiranagar",
  "landmark": "Near metro",
  "city": "Bengaluru",
  "district": "Bengaluru Urban",
  "stateCode": "KA",
  "postalCode": "560038",
  "countryCode": "IND",
  "primary": true,
  "status": "ACTIVE"
}
```

**Response `data` (excerpt):**

```json
{
  "addressReferenceId": "33333333-3333-3333-3333-333333333333",
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "customerReferenceId": "22222222-2222-2222-2222-222222222222",
  "sourceSystem": "CUSTOMER_SERVICE",
  "externalAddressId": "ADDR-9000123",
  "addressType": "SHIPPING",
  "addressLine1": "12 MG Road",
  "city": "Bengaluru",
  "stateCode": "KA",
  "postalCode": "560038",
  "countryCode": "IND",
  "primary": true,
  "addressStatus": "ACTIVE",
  "createdAt": "2026-01-28T10:30:00Z",
  "updatedAt": "2026-01-28T10:30:00Z",
  "createdBy": "user-42",
  "updatedBy": "user-42"
}
```

#### List / get / update

| Method | Path | Notes |
|--------|------|-------|
| `GET` | `.../addresses` | Optional `status`, `page`, `limit` |
| `GET` | `.../addresses/{addressReferenceId}` | |
| `POST` | `.../addresses/{addressReferenceId}/actions/update-details` | At least one address field |
| `POST` | `.../addresses/{addressReferenceId}/actions/update-status` | Same status rules as customers |

---

### Account endpoints

Base: `/api/v2/institutions/{institutionId}/accounts`

| Method | Path | Permission |
|--------|------|------------|
| `POST` | `/accounts` | `cms:account:manage` |
| `GET` | `/accounts` | `cms:account:read` or `manage` |
| `GET` | `/accounts/resolve?sourceSystem=&externalAccountId=` | read or manage |
| `GET` | `/accounts/{externalAccountReferenceId}` | read or manage |
| `POST` | `/accounts/{externalAccountReferenceId}/actions/update-status` | manage |
| `GET` | `/accounts/{externalAccountReferenceId}/customers` | read or manage |

**Create request:**

```json
{
  "sourceSystem": "CORE_BANKING",
  "externalAccountId": "ACC-9000123",
  "accountType": "CREDIT_CARD_ACCOUNT",
  "status": "ACTIVE"
}
```

**Response `data`:**

```json
{
  "externalAccountReferenceId": "44444444-4444-4444-4444-444444444444",
  "institutionId": "11111111-1111-1111-1111-111111111111",
  "sourceSystem": "CORE_BANKING",
  "externalAccountId": "ACC-9000123",
  "accountType": "CREDIT_CARD_ACCOUNT",
  "accountStatus": "ACTIVE",
  "createdAt": "2026-01-28T10:30:00Z",
  "updatedAt": "2026-01-28T10:30:00Z",
  "createdBy": "user-42",
  "updatedBy": "user-42"
}
```

`accountType` is `CREDIT_CARD_ACCOUNT` or `PREPAID_WALLET`. PAN, balances, and transaction history are not stored.

---

### Customer–account link endpoints

| Method | Path | Permission |
|--------|------|------------|
| `POST` | `.../customers/{customerReferenceId}/accounts` | `cms:customer:manage` |
| `GET` | `.../customers/{customerReferenceId}/accounts` | `cms:customer:read` or `manage` |
| `POST` | `.../customers/{customerReferenceId}/accounts/{externalAccountReferenceId}/actions/update-status` | `cms:customer:manage` |

Both customer and account must be `ACTIVE` to link.

**Create request:**

```json
{
  "externalAccountReferenceId": "44444444-4444-4444-4444-444444444444",
  "relationshipType": "PRIMARY_HOLDER",
  "primary": true,
  "effectiveFrom": "2026-01-28T10:30:00Z"
}
```

Valid `relationshipType` values:

| Account type | Allowed relationships |
|--------------|------------------------|
| `CREDIT_CARD_ACCOUNT` | `PRIMARY_HOLDER`, `SUPPLEMENTARY_HOLDER`, `AUTHORIZED_USER` |
| `PREPAID_WALLET` | `PREPAID_OWNER`, `AUTHORIZED_USER` |

**Close / deactivate link:**

```json
{
  "status": "CLOSED",
  "effectiveTo": "2026-06-01T00:00:00Z"
}
```

`effectiveTo` must be after `effectiveFrom` (defaults to now when omitted). Requesting `ACTIVE` is a no-op that returns the current active link.

---

## Enumerations

| Enum | Values |
|------|--------|
| `ReferenceStatus` / link-style statuses on references | `ACTIVE`, `INACTIVE`, `BLOCKED`, `CLOSED` |
| `LinkStatus` | `ACTIVE`, `INACTIVE`, `CLOSED` |
| `CustomerTypeV2` | `INDIVIDUAL`, `BUSINESS` |
| `AddressTypeV2` | `SHIPPING`, `BILLING`, `HOME`, `OFFICE`, `OTHER` |
| `AccountType` | `CREDIT_CARD_ACCOUNT`, `PREPAID_WALLET` |
| `CustomerAccountRelationshipType` | `PRIMARY_HOLDER`, `SUPPLEMENTARY_HOLDER`, `PREPAID_OWNER`, `AUTHORIZED_USER` |

---

## Response envelopes and errors

Success: `ApiSuccessEnvelopeV2` — `success`, `data`, `meta.requestId`, `meta.timestamp`.

Error: `ApiErrorEnvelopeV2` — `success: false`, `error.code`, `error.message`, optional `error.details`, plus `meta`.

| HTTP | Code (typical) | Meaning |
|------|----------------|---------|
| `400` | `BAD_REQUEST` / `VALIDATION_ERROR` / `IDEMPOTENCY_KEY_REQUIRED` | Invalid input or missing idempotency key |
| `401` | `UNAUTHENTICATED` | Missing or invalid bearer token |
| `403` | `ACCESS_DENIED` | Permission or institution mismatch |
| `404` | `NOT_FOUND` | Tenant-scoped reference missing |
| `409` | `CONFLICT` / `IDEMPOTENCY_*` | Duplicate or idempotency conflict |
| `413` | `REQUEST_BODY_TOO_LARGE` | Body exceeds idempotency cache limit |
| `422` | `BUSINESS_RULE_VIOLATION` | Illegal status transition or relationship |
| `500` | `INTERNAL_ERROR` | Unexpected failure |

---

## Keycloak Configuration

V2 APIs (`/api/v2/**`) require a Keycloak-issued bearer JWT. Swagger UI, OpenAPI docs, and actuator health are currently open.

### Expected Keycloak setup

| Item | Value | Notes |
|------|-------|-------|
| Realm | `cms` | Default issuer: `http://localhost:9000/realms/cms` |
| Client | Client that obtains tokens for audience `cms-api` | Client id is environment-specific |
| Audience | `cms-api` | Must appear in the token `aud` claim |
| Token type | Access token (Bearer JWT) | `Authorization: Bearer <token>` |

| Variable | Default |
|----------|---------|
| `KEYCLOAK_ISSUER_URI` | `http://localhost:9000/realms/cms` |
| `KEYCLOAK_JWK_SET_URI` | `http://localhost:9000/realms/cms/protocol/openid-connect/certs` |
| `KEYCLOAK_AUDIENCE` | `cms-api` |

### Required JWT claims

| Claim | Required | Purpose |
|-------|----------|---------|
| `sub` | Yes | Actor for audit and idempotency |
| `aud` | Yes | Must include `cms-api` |
| `permissions` | Yes for V2 authz | Array of permission strings |
| `institution_id` | Yes for tenant callers | UUID matching path `{institutionId}` |
| `institution-id` | Fallback | Used if `institution_id` is missing/blank |
| `platform_access` | Optional | Boolean `true` allows any institution |

The service maps each `permissions` entry to a Spring authority with prefix `PERM_`.  
Token value `cms:customer:read` → authority `PERM_cms:customer:read`.

### Permissions

| Permission in token | Authority | Grants |
|---------------------|-----------|--------|
| `cms:customer:read` | `PERM_cms:customer:read` | Read customers, addresses, customer-side links |
| `cms:customer:manage` | `PERM_cms:customer:manage` | Customer/address/link writes; also allows reads |
| `cms:account:read` | `PERM_cms:account:read` | Read accounts and account-side links |
| `cms:account:manage` | `PERM_cms:account:manage` | Account writes; also allows account reads |

| Route | Methods | Required permission |
|-------|---------|---------------------|
| `.../customers/**` | `GET` | `cms:customer:read` or `cms:customer:manage` |
| `.../customers/**` | non-GET | `cms:customer:manage` |
| `.../accounts/**` | `GET` | `cms:account:read` or `cms:account:manage` |
| `.../accounts/**` | non-GET | `cms:account:manage` |

Suggested role bundles:

| Example role | Permissions |
|--------------|-------------|
| `cms-customer-reader` | `cms:customer:read` |
| `cms-customer-manager` | `cms:customer:manage` |
| `cms-account-reader` | `cms:account:read` |
| `cms-account-manager` | `cms:account:manage` |
| `cms-customer-service-operator` | `cms:customer:manage`, `cms:account:manage` |

### Tenant enforcement

After permission checks, `V2TenantAccess` requires a JWT principal. With `platform_access: true`, any `{institutionId}` is allowed; otherwise `institution_id` / `institution-id` must equal the path UUID.

### Example access token

```json
{
  "sub": "user-42",
  "aud": "cms-api",
  "iss": "http://localhost:9000/realms/cms",
  "institution_id": "11111111-1111-1111-1111-111111111111",
  "platform_access": false,
  "permissions": [
    "cms:customer:manage",
    "cms:account:read"
  ]
}
```

### Swagger

1. Get a token for realm `cms`, audience `cms-api`, with the permissions above.
2. Open `http://localhost:9801/swagger-ui.html` (default port from `application.yml`; override with `SERVER_PORT`).
3. **Authorize** → `bearerAuth` → paste the access token (no `Bearer ` prefix).
4. Call `/api/v2/institutions/{institutionId}/...` with `Idempotency-Key` on writes.

---

## Configuration

Defaults from `application.yml` (override with env vars):

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_PORT` | `9801` | HTTP port |
| `DATASOURCE_URL` | `jdbc:postgresql://localhost:5432/cmsv2?...` | PostgreSQL URL |
| `DATASOURCE_USERNAME` | `postgres` | DB user |
| `DATASOURCE_PASSWORD` | `admin` | DB password |
| `DB_SCHEMA` | `cms_v2` | Hibernate + Flyway + JDBC search path |
| `KEYCLOAK_ISSUER_URI` | `http://localhost:9000/realms/cms` | JWT issuer |
| `KEYCLOAK_JWK_SET_URI` | `.../protocol/openid-connect/certs` | JWKS |
| `KEYCLOAK_AUDIENCE` | `cms-api` | Expected audience |
| `IDEMPOTENCY_RETENTION_HOURS` | `24` | Idempotency record TTL |
| `IDEMPOTENCY_MAX_BODY_BYTES` | `2097152` | Max cached request body |

Flyway for this service uses table `customer_service_schema_history` in schema `cms_v2` so it does not conflict with the shared platform `flyway_schema_history`.

---

## Running the Application

### Prerequisites

- JDK 25 (`JAVA_HOME` aligned for Maven and the IDE)
- PostgreSQL with database `cmsv2` and schema `cms_v2`
- Keycloak realm `cms` configured as above
- Maven 3.8+

### Steps

```bash
git clone <repository-url>
cd cms_customer
mvn clean verify
mvn spring-boot:run
```

Or:

```bash
java -jar target/customer-service-1.0.0.jar
```

- API base: `http://localhost:9801/api/v2`
- Swagger: `http://localhost:9801/swagger-ui.html`
- Example: `GET http://localhost:9801/api/v2/institutions/11111111-1111-1111-1111-111111111111/customers/22222222-2222-2222-2222-222222222222`

### Docker (optional)

```bash
docker build -t customer-service:1.0.0 .
docker run -p 8080:8080 \
  -e DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/cmsv2 \
  -e DATASOURCE_USERNAME=postgres \
  -e DATASOURCE_PASSWORD=admin \
  -e KEYCLOAK_ISSUER_URI=http://host.docker.internal:9000/realms/cms \
  customer-service:1.0.0
```

---

## API Summary

`{institutionId}`, `{customerReferenceId}`, `{addressReferenceId}`, and `{externalAccountReferenceId}` are UUIDs.

| Method | Endpoint |
|--------|----------|
| `POST` | `/api/v2/institutions/{institutionId}/customers` |
| `GET` | `/api/v2/institutions/{institutionId}/customers` |
| `GET` | `/api/v2/institutions/{institutionId}/customers/resolve` |
| `GET` | `/api/v2/institutions/{institutionId}/customers/{customerReferenceId}` |
| `POST` | `/api/v2/institutions/{institutionId}/customers/{customerReferenceId}/actions/update-status` |
| `POST` | `/api/v2/institutions/{institutionId}/customers/{customerReferenceId}/actions/update-profile` |
| `POST` | `/api/v2/institutions/{institutionId}/customers/{customerReferenceId}/addresses` |
| `GET` | `/api/v2/institutions/{institutionId}/customers/{customerReferenceId}/addresses` |
| `GET` | `/api/v2/institutions/{institutionId}/customers/{customerReferenceId}/addresses/{addressReferenceId}` |
| `POST` | `.../addresses/{addressReferenceId}/actions/update-details` |
| `POST` | `.../addresses/{addressReferenceId}/actions/update-status` |
| `POST` | `/api/v2/institutions/{institutionId}/customers/{customerReferenceId}/accounts` |
| `GET` | `/api/v2/institutions/{institutionId}/customers/{customerReferenceId}/accounts` |
| `POST` | `.../accounts/{externalAccountReferenceId}/actions/update-status` |
| `POST` | `/api/v2/institutions/{institutionId}/accounts` |
| `GET` | `/api/v2/institutions/{institutionId}/accounts` |
| `GET` | `/api/v2/institutions/{institutionId}/accounts/resolve` |
| `GET` | `/api/v2/institutions/{institutionId}/accounts/{externalAccountReferenceId}` |
| `POST` | `.../accounts/{externalAccountReferenceId}/actions/update-status` |
| `GET` | `.../accounts/{externalAccountReferenceId}/customers` |

---

## License

Proprietary - LPS CMS
