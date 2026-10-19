---
layout: default
title: "CMS Customer — v1.0.0"
---

# CMS Customer — v1.0.0

**Version:** 1.0.0 — initial client delivery.  
**Planned tag:** `1.0.0`; no existing release tag has been verified.  
**Release Type:** Major — initial baseline  
**Scope:** Institution-scoped customer profiles, postal addresses, external account references, and customer-account relationships.  
**Notes updated:** 19 October 2026

## Deployment summary

| Item | Status |
| --- | --- |
| Source baseline | `8ff58b107cf98be6b7979865acc4f3a4b525e476` — confirmed release source |
| Application artifact | `com.lps.cms:customer-service:1.0.0` |
| Release identity | Intended tag `1.0.0` / `refs/tags/1.0.0`; tag commit, tag creation date, and tagger not confirmed |
| Previous release | Not applicable — initial release |
| API compatibility | V2 only; development-era V1 consumers must migrate |
| Database | Validate the shared schema and version-12 Flyway baseline before startup |
| Deployment readiness | Target-environment acceptance and actual deployment not confirmed |

No tag was created for these notes. The source commit is confirmed independently of the planned tag; no tag-to-tag comparison is claimed.

## Overview

CMS Customer 1.0.0 provides a common service for maintaining customer and address data and linking customers to external account references within an institution. Other CMS services use returned UUIDs rather than duplicating customer profile data. The capabilities below describe the initial delivery, not changes from a previous client release.

## Features

- **Customer management:** Create, list, resolve by external identity, retrieve, update profiles, and manage lifecycle status.
- **Postal addresses:** Maintain customer addresses, address types, primary-address designation, details, and status.
- **External account references:** Register credit-card account and prepaid-wallet references. PAN, balances, and transaction history are outside this contract.
- **Customer-account relationships:** Create and query relationships, update their status, and validate relationship types against the account type.
- **API documentation:** Swagger UI and a grouped V2 OpenAPI definition support consumer integration.

## Security

- Protected resources require bearer tokens satisfying the configured issuer and audience; the default audience is `cms-api`.
- Customer operations use `cms:customer:read` / `cms:customer:manage`; account operations use `cms:account:read` / `cms:account:manage`. Manage permissions also permit the respective reads.
- Institution path UUIDs must match `institution_id`, or supported fallback `institution-id`, unless `platform_access=true`.
- OpenAPI, Swagger UI, and health endpoints are public under the current security configuration. No security certification or vulnerability-remediation outcome is asserted.

## Reliability and maintenance

- **Controlled retries:** V2 POST/PUT requests require an idempotency key. Matching completed requests replay recorded responses; conflicting key reuse or concurrent processing returns a conflict.
- **Business validation:** Closed customer/address records cannot be updated; customer-account linking requires active references and a valid relationship type.
- **Consistent responses:** Structured success/error envelopes include request IDs and timestamps. Pagination is 1-based, with a default limit of 20 and maximum of 100.
- **Automated verification:** Tests cover business rules, API contracts, tenant access, idempotency, response handling, and application-context/MVC behavior. No measured performance improvement is claimed.

## Pre-release corrections and bug fixes

The initial delivery includes these verified corrections made during development:

- **Permission mapping:** Customer/account endpoint checks now use the documented `cms:*` permission names, allowing correctly configured tokens to match authorization rules. Identity-provider mappings must supply those permissions.
- **Institution claim compatibility:** Tenant checks accept `institution-id` when `institution_id` is missing or blank. The institution must still match; new integrations should use `institution_id`.
- **Schema alignment:** Migrations add missing shared customer/address details, audit fields, and the customer-account relationship table where needed. V13 supplies missing legacy audit fields on affected tables when present.
- **Migration isolation:** A dedicated Customer Service migration-history table separates its tracking from platform history; an explicit database search path targets the configured schema.
- **Swagger authentication:** The root OpenAPI definition includes the bearer security scheme and requirement for protected operations.

Schema corrections require validation of the migration path. The version-12 baseline does not execute V9–V12 on an existing nonempty schema without service history; their structures must already exist or be supplied through an approved alignment plan.

## JUnit test results

The verified **16 October 2026** run used `mvn clean test org.jacoco:jacoco-maven-plugin:0.8.15:report`:

| Tests reported | Passed | Failures | Errors | Skipped |
| --- | --- | --- | --- | --- |
| 202 | 202 | 0 | 0 | 0 |

Fourteen suites reported an aggregate duration of 5.203 seconds. These are the existing execution results, not a new run on 19 October. The tests use mocks and an application context; live PostgreSQL migrations, identity-provider integration, and client-environment acceptance are not established.

## Measured code coverage

| Metric | Measured result |
| --- | --- |
| Line coverage | 99.13% — 570 / 575 lines |
| Branch coverage | 90.65% — 223 / 246 branches |
| Instruction coverage | 99.40% — 3,979 / 4,003 instructions |

The explicit JaCoCo report goal produced full-service Java coverage. The POM's default report execution includes V2 packages only. See the [JUnit report](test-report/junit/index.html), [JaCoCo report](test-report/jacoco/index.html), and [evidence bundle](test-report/cms-customer-test-and-coverage-reports.zip). Preserve generated evidence before `mvn clean`.

## Requirements and compatibility

| Component | Requirement / behavior |
| --- | --- |
| Java | Java 25 |
| Framework | Spring Boot 4.1.1; Jackson 3 with Jackson 2 serialization defaults |
| Database | PostgreSQL with compatible schema and migration history |
| HTTP port | YAML default 9801; container default 8080; configurable |
| External dependencies | Identity provider and signing-key endpoint; gateway where used |
| API generation | V2; OpenAPI metadata version 2.0.0 is separate from application version 1.0.0 |

Business APIs use `/api/v2/institutions/{institutionId}` with UUID identifiers and camelCase JSON:

| Interface | Purpose |
| --- | --- |
| POST / GET `.../customers` | Create and list customers |
| GET `.../customers/resolve` and `.../customers/{customerReferenceId}` | Resolve external identity and retrieve a customer |
| POST `.../customers/{customerReferenceId}/actions/update-profile` or `/actions/update-status` | Update customer profile or status |
| `.../customers/{customerReferenceId}/addresses` | Create/list addresses; retrieve and update through address-specific routes |
| `.../accounts` | Create/list/resolve/get account references and update status |
| `.../customers/{customerReferenceId}/accounts` | Create/list links and update relationship status |
| GET `.../accounts/{externalAccountReferenceId}/customers` | Query account-side relationships |

V1 routes have been removed. Consumers must adopt V2 paths, UUIDs, response envelopes, and idempotency keys of 1–128 characters from `A-Za-z0-9._:-`. Reuse the same key and content for a retry.

## Deployment prerequisites

Flyway migrations V1–V13 include legacy schema history, V2 reference tables, relationships, idempotency records, and schema/audit alignment. Tracking uses `customer_service_schema_history` in `DB_SCHEMA` (default `cms_v2`). Schema creation is enabled; nonempty schemas without service history are configured to baseline at V12. Rehearse the applicable migration path and confirm prerequisites before deployment.

| Configuration | Required setup |
| --- | --- |
| DATASOURCE_URL / DATASOURCE_USERNAME / DATASOURCE_PASSWORD | Supply approved environment-specific database settings |
| DB_SCHEMA / FLYWAY_ENABLED | Confirm schema, migration ownership, history, and baseline suitability |
| KEYCLOAK_ISSUER_URI / KEYCLOAK_JWK_SET_URI / KEYCLOAK_AUDIENCE | Configure token validation and required audience |
| SERVER_PORT | Align service port, gateway destination, and health checks |
| IDEMPOTENCY_RETENTION_HOURS | Default 24 hours |
| IDEMPOTENCY_MAX_BODY_BYTES | Default 2,097,152 bytes |

Client/deployment actions: confirm environment and release date; provision identity claims and permissions; back up and validate shared data; update consumers; complete migration, tenant-isolation, business-rule, and retry acceptance tests. Keep Hibernate bind-value logging disabled for customer/address PII.

## Build and deployment

Build the final selected source with `mvn clean verify`; the expected package is `target/customer-service-1.0.0.jar`. The available evidence covers the test/report command above; a final release-package checksum and deployment approval are not confirmed. The Dockerfile skips tests during packaging.

Deploy using the approved database and identity settings, align `CUSTOMER_SERVICE_URI` at the gateway, and restart after configuration changes. Do not distribute live credentials with delivery files.

## Deployment verification

- Verify health, OpenAPI `/api-docs/customer-v2`, and Swagger UI `/swagger-ui.html`.
- Exercise valid and invalid permissions and institution boundaries.
- Verify customer/address/account operations, lifecycle transitions, and relationship constraints.
- Verify idempotent replay, key conflicts, body limits, and schema migration state.

## Known limitations

- Live database migration rehearsal, external integrations, and target-environment acceptance remain unconfirmed.
- CLOSED lifecycle states are terminal. New account relationships require active references.
- Account references do not supply PAN, balances, or transactions.
- Arbitrary browser origin patterns are allowed in the service's current CORS configuration; confirm the intended deployment access policy.
- The release tag, its creation date, deployment date, and deployment environment remain unconfirmed. No assertion that all defects are resolved is made.

## Rollback

For a failed initial installation, stop incoming writes and stop or remove the new deployment. A separately approved earlier artifact may be used only after schema compatibility is established. Application rollback does not undo Flyway migrations; coordinate backup restoration or forward repair with other services using the shared schema. Preserve customer and idempotency records.

## References

- [Service documentation](guides/service-documentation.html)
- [JUnit test report](test-report/junit/index.html)
- [JUnit XML evidence](#junit-xml-evidence)
- [Full JaCoCo coverage](test-report/jacoco/index.html)
- [Test and coverage summary](test-report/report-summary.json)
- [Report bundle](test-report/cms-customer-test-and-coverage-reports.zip)


## Bundled release documentation

The linked guides are copied with this release for review without source-repository access. Reports preserve the existing verification evidence; no new tests were run for this documentation update.

- [JUnit test results](test-report/junit/index.html)
- [JaCoCo coverage report](test-report/jacoco/index.html)

## JUnit XML evidence

The copied XML excludes environment properties and embedded test output.

- [TEST-com.lps.cms.customer.CustomerServiceApplicationTests](test-report/surefire-reports/TEST-com.lps.cms.customer.CustomerServiceApplicationTests.xml)
- [TEST-com.lps.cms.customer.v2.boundary.FalconContractV2Test](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.boundary.FalconContractV2Test.xml)
- [TEST-com.lps.cms.customer.v2.boundary.controller.AccountBoundaryV2ControllerTest](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.boundary.controller.AccountBoundaryV2ControllerTest.xml)
- [TEST-com.lps.cms.customer.v2.boundary.controller.CustomerBoundaryV2ControllerTest](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.boundary.controller.CustomerBoundaryV2ControllerTest.xml)
- [TEST-com.lps.cms.customer.v2.boundary.service.BoundaryReferenceV2AccountServiceTest](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.boundary.service.BoundaryReferenceV2AccountServiceTest.xml)
- [TEST-com.lps.cms.customer.v2.boundary.service.BoundaryReferenceV2AddressServiceTest](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.boundary.service.BoundaryReferenceV2AddressServiceTest.xml)
- [TEST-com.lps.cms.customer.v2.boundary.service.BoundaryReferenceV2CustomerServiceTest](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.boundary.service.BoundaryReferenceV2CustomerServiceTest.xml)
- [TEST-com.lps.cms.customer.v2.boundary.service.BoundaryReferenceV2LinkServiceTest](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.boundary.service.BoundaryReferenceV2LinkServiceTest.xml)
- [TEST-com.lps.cms.customer.v2.common.ApiResponseV2Test](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.common.ApiResponseV2Test.xml)
- [TEST-com.lps.cms.customer.v2.common.V2ExceptionHandlerTest](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.common.V2ExceptionHandlerTest.xml)
- [TEST-com.lps.cms.customer.v2.common.idempotency.CachedBodyRequestTest](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.common.idempotency.CachedBodyRequestTest.xml)
- [TEST-com.lps.cms.customer.v2.common.idempotency.IdempotencyFilterV2Test](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.common.idempotency.IdempotencyFilterV2Test.xml)
- [TEST-com.lps.cms.customer.v2.common.idempotency.IdempotencyRepositoryV2Test](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.common.idempotency.IdempotencyRepositoryV2Test.xml)
- [TEST-com.lps.cms.customer.v2.security.V2TenantAccessTest](test-report/surefire-reports/TEST-com.lps.cms.customer.v2.security.V2TenantAccessTest.xml)
