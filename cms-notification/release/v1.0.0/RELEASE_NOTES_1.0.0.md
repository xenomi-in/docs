---
layout: default
title: "CMS Notification — v1.0.0"
---

# CMS Notification — v1.0.0

**Version:** 1.0.0 — planned delivery label; current POM version is `0.0.1-SNAPSHOT`.  
**Planned tag:** `1.0.0`.  
**Release Type:** Major — initial capability baseline  
**Environment:** Not confirmed  **Scope:** Notification-intent ingestion and source-isolated Avro event publishing to Kafka.  
**Notes updated:** 19 October 2026

## Deployment summary

| Item | Status |
| --- | --- |
| Source baseline | `e2f4ad84bb2df59f6ba78a6b62374136e9b8275f` |
| Source repository | `cms_notification` |
| Current artifact | `com.lps:cms-notification:0.0.1-SNAPSHOT`; align release metadata before publishing 1.0.0 |
| Release identity | Intended `refs/tags/1.0.0`; tagged SHA, creation date, and tagger not confirmed |
| Previous release | No previous tag comparison performed; capability baseline only |
| Delivery responsibility | Kafka publication only; downstream consumers perform email/SMS or other delivery |
| Gateway compatibility | Current gateway path and trusted-institution-header behavior do not match this service |
| Verification | 109 / 109 tests passed on 19 October 2026; verify-phase coverage gates passed |

## Overview

CMS Notification accepts notification intents from CMS and Switch, validates their identity and payload, enriches a canonical event, and publishes Avro records to source-specific Kafka topics. A successful HTTP response records publication or replay of a completed event; it does not confirm delivery to a customer.

## Features

- **Event ingress:** `POST /notifications/publish` accepts validated notification requests.
- **Source isolation:** CMS and SWITCH select separate configured Kafka event topics.
- **Canonical events:** Adds event time, event version, trace metadata, channel defaults, and default priority while retaining caller-supplied event identity.
- **Ordering keys:** Tenant-prefixed customer, aggregate, or tenant partition keys support ordering within the selected key.
- **Observability:** Trace/event headers, publish metrics, health probes, and Prometheus exposure support operations.

## Security

The required `X-Institution-Id` must match body `tenantId`. That comparison is not token authentication. No application JWT security filter or Spring Security dependency is present in the inspected module. Enforce the intended authentication and trusted-header boundary before exposing ingress, and provision Kafka/Schema Registry/Redis transport credentials through the environment.

The current gateway removes caller identity headers but does not supply this service's required trusted institution header. Its Notification path predicate is `/api/v1/notifications/**`, which also differs from `/notifications/publish`. Resolve both contracts before gateway integration. No security certification is asserted.

## Reliability and maintenance

- **HTTP deduplication:** Redis-backed claims use institution, source, and eventId. Completed keys replay acceptance without a second application send; in-progress requests wait within the configured interval before a conflict.
- **Broker settings:** Producer idempotence and `acks=all` are enabled. Legitimate application retries still require downstream deduplication.
- **Per-source resilience:** Independent bulkheads and circuit breakers bound concurrency and fail fast for sustained publication failures.
- **Bounded publication:** Default delivery timeout is 3 seconds with a 1-second application await buffer; configure coherent broker request/linger settings.
- **Payload control:** Default serialized payload limit is 256 KB. No measured throughput or latency gain is claimed.

Idempotency is keyed by identity, not a payload hash. A completed eventId replay does not establish that a changed payload was accepted or republished. Consumers must deduplicate before side effects.

## Pre-release corrections and bug fixes

Verified development corrections include:

- **Generated Avro compatibility:** Build configuration registers generated Avro sources and normalizes generated-code declarations/annotations for compilation.
- **Runtime migration:** Source and dependencies were migrated to Java 25/Spring Boot 4.1.1, including the corresponding MVC/Kafka/test stack.

Channel values are trimmed in the current enricher, but the commit titled metadata channel normalization does not demonstrate a new channel-trimming behavior in its Java diff; it is not presented as a newly fixed defect. No issue-closure or production defect-resolution claim is made.

## JUnit test results

A fresh **19 October 2026** run completed successfully with `mvn clean verify` in an isolated copy of the selected source:

| Tests reported | Passed | Failures | Errors | Skipped |
| --- | --- | --- | --- | --- |
| 109 | 109 | 0 | 0 | 0 |

Eighteen suites reported an aggregate duration of 3.521 seconds. The source POM and all source/test files were checked byte-for-byte against the repository. The evidence records source commit `e2f4ad84bb2df59f6ba78a6b62374136e9b8275f` and SHA-256 source fingerprints.

The first run in the normal checkout encountered unresolved-compilation bytecode in the producer class. The isolated Maven build passed without application or test-source changes and is the authoritative report linked here. The former partial reports do not represent this successful run.

These tests use mocks and test configuration; they do not establish live Kafka, Schema Registry, Redis, consumer delivery, or deployment acceptance.

## Measured code coverage

| Metric | Result |
| --- | --- |
| Line coverage | 97.74% — 390 / 399 lines |
| Branch coverage | 89.36% — 84 / 94 branches |
| Instruction coverage | 96.92% — 1,793 / 1,850 instructions |
| Verify-phase coverage gate | Passed — minimums 95% lines and 80% branches |

JaCoCo 0.8.14 measures the configured production Java scope, excluding generated Avro classes and `CmsNotificationApplication`. The verified isolated build completed tests, packaging, and coverage checks with exit code 0; this does not establish production readiness. See the [JUnit report](test-report/junit/index.html), [coverage summary](test-report/coverage-summary.html), [full JaCoCo report](test-report/jacoco/index.html), and [evidence bundle](test-report/cms-notification-test-and-coverage-reports.zip). Preserve generated evidence before cleaning the build directory.

## Requirements and compatibility

| Component | Requirement / behavior |
| --- | --- |
| Java / framework | Java 25; Spring Boot 4.1.1 |
| Event schema | Avro 1.12.0; Confluent serializer 8.3.1 |
| Resilience | Resilience4j 2.4.0 |
| Infrastructure | Kafka, Schema Registry, and Redis |
| Database | No relational migrations in this service |
| HTTP port | Dev profile 9802; production port must be explicitly selected |

Ingress returns 202 with `X-Event-Id`; completed retries add `X-Idempotent-Replay: true`. `X-Trace-Id` is echoed or generated. Required request fields include eventId, eventType, tenantId, eventSource (CMS/SWITCH), and payload; aggregate type/id must appear together.

| HTTP status | Meaning |
| --- | --- |
| 400 / 413 | Invalid request/institution context or oversized serialized payload |
| 409 | Event publication already in progress |
| 429 | Per-source concurrency limit reached |
| 503 | Publication failure/timeout or open circuit breaker |

Retryable responses include Retry-After. Retries must retain institution, source, and eventId. Default topics are `notifications.cms.events` and `notifications.switch.events`. Retry/DLQ topic names are configured for downstream consumers; this service has no Kafka consumer and does not execute downstream retries or send messages to end users.

## Deployment prerequisites

| Configuration | Required setup |
| --- | --- |
| SPRING_PROFILES_ACTIVE | Select the intended profile; shared configuration defaults to dev |
| KAFKA_BOOTSTRAP_SERVERS | Approved broker endpoints; override the dev example |
| SCHEMA_REGISTRY_URL / SCHEMA_AUTO_REGISTER | Configure registry; production registration requires an approved schema workflow |
| REDIS_HOST / REDIS_PORT / REDIS_PASSWORD | Approved shared deduplication store; prod forces Redis |
| NOTIF_TOPIC_CMS_EVENTS / NOTIF_TOPIC_SWITCH_EVENTS | Approved per-source event topics |
| NOTIF_IDEMPOTENCY_TTL | Cover the upstream retry window; default 24 hours |
| NOTIF_DELIVERY_TIMEOUT / NOTIF_AWAIT_BUFFER | Consistent publication and application wait budgets |
| NOTIF_MAX_PAYLOAD_SIZE | Default 256 KB |
| NOTIF_BULKHEAD_MAX_CONCURRENT | Default 50 concurrent publishes per source |
| SERVER_PORT | Explicit deployment listener, distinct from broker addresses |

The dev example uses localhost:9802 for Kafka and port 9802 for HTTP. Configure the actual broker endpoint; do not assume that example is a working single-host arrangement. Confirm partitions, retention, replication, ACLs, schema compatibility, and consumer deduplication for the target environment.

Client actions: agree authentication/trusted-header handling and gateway paths, configure infrastructure, align version/tag identity, validate schema registration, integrate consumers, and complete a successful final build and end-to-end acceptance test.

## Build and deployment

Run `mvn clean verify` on the final approved source to generate Avro types, execute tests, and evaluate coverage gates. The isolated 19 October build verified tests, packaging, and coverage for the current SNAPSHOT source. Final release-artifact identity remains to be approved. Align the POM to the approved 1.0.0 release label before final artifact publication; current metadata remains `0.0.1-SNAPSHOT`.

Deploy using approved broker, registry, Redis, topic, and access settings. Restart to load configuration changes. This documentation does not assert deployment success.

## Deployment verification

- Verify health/readiness and operational endpoint exposure.
- Publish approved CMS/SWITCH examples and inspect the correct topics, Avro schema, and tenant-prefixed keys.
- Test completed replay, in-progress conflict, publish failure, circuit-open and concurrency-limit responses.
- Verify payload validation, infrastructure access, consumer deduplication, and actual downstream delivery separately.
- Verify gateway path mapping and trusted-header issuance before exposing ingress.

## Known limitations

- The service publishes intents; email/SMS delivery, Kafka consumption, and downstream retry/DLQ processing are external responsibilities.
- A completed identity replay is not payload-consistency validation or a guarantee of exactly-once downstream effects.
- Authentication/trusted-header integration with the current gateway remains unresolved.
- Final release-package identity, tag, deployment date, and environment are not confirmed.
- The authoritative test evidence comes from an isolated source build; normal-checkout build-output contamination should be resolved before relying on local IDE-generated classes.

## Rollback

Stop ingress and withdraw the new instance or restore a separately approved compatible artifact/configuration. Preserve Kafka records, Redis deduplication state, and schema compatibility. Application rollback does not retract events already published; coordinate consumer reconciliation and avoid blindly replaying notification events.

## References

- [Service documentation](guides/service-documentation.html)
- [Application configuration requirements](#deployment-prerequisites)
- [JUnit report](test-report/junit/index.html)
- [JUnit XML evidence](#junit-xml-evidence)
- [JaCoCo coverage](test-report/jacoco/index.html)
- [Test summary](test-report/report-summary.json)
- [Evidence bundle](test-report/cms-notification-test-and-coverage-reports.zip)


## Bundled release references

Guides and test evidence are included with this release for review without source-repository access. The reports preserve the recorded 19 October 2026 execution; no new tests were run for this reference update.

- [Coverage summary](test-report/coverage-summary.html)
- [Source identity and fingerprints](test-report/source-fingerprint.json)

## JUnit XML evidence

These XML files come from the matching evidence archive. Environment properties and embedded test output are omitted from the individual XML downloads.

- [TEST-com.lps.cms.notification.CmsNotificationApplicationTests](test-report/surefire-reports/TEST-com.lps.cms.notification.CmsNotificationApplicationTests.xml)
- [TEST-com.lps.cms.notification.config.KafkaProducerConfigTest](test-report/surefire-reports/TEST-com.lps.cms.notification.config.KafkaProducerConfigTest.xml)
- [TEST-com.lps.cms.notification.config.NotificationProducerPropertiesTest](test-report/surefire-reports/TEST-com.lps.cms.notification.config.NotificationProducerPropertiesTest.xml)
- [TEST-com.lps.cms.notification.config.NotificationTopicsPropertiesTest](test-report/surefire-reports/TEST-com.lps.cms.notification.config.NotificationTopicsPropertiesTest.xml)
- [TEST-com.lps.cms.notification.config.TraceIdFilterTest](test-report/surefire-reports/TEST-com.lps.cms.notification.config.TraceIdFilterTest.xml)
- [TEST-com.lps.cms.notification.controller.NotificationControllerTest](test-report/surefire-reports/TEST-com.lps.cms.notification.controller.NotificationControllerTest.xml)
- [TEST-com.lps.cms.notification.exception.ApiExceptionHandlerTest](test-report/surefire-reports/TEST-com.lps.cms.notification.exception.ApiExceptionHandlerTest.xml)
- [TEST-com.lps.cms.notification.idempotency.IdempotencyConfigTest](test-report/surefire-reports/TEST-com.lps.cms.notification.idempotency.IdempotencyConfigTest.xml)
- [TEST-com.lps.cms.notification.idempotency.IdempotencyKeyTest](test-report/surefire-reports/TEST-com.lps.cms.notification.idempotency.IdempotencyKeyTest.xml)
- [TEST-com.lps.cms.notification.idempotency.InMemoryIdempotencyStoreTest](test-report/surefire-reports/TEST-com.lps.cms.notification.idempotency.InMemoryIdempotencyStoreTest.xml)
- [TEST-com.lps.cms.notification.idempotency.RedisIdempotencyStoreTest](test-report/surefire-reports/TEST-com.lps.cms.notification.idempotency.RedisIdempotencyStoreTest.xml)
- [TEST-com.lps.cms.notification.model.EventSourceTest](test-report/surefire-reports/TEST-com.lps.cms.notification.model.EventSourceTest.xml)
- [TEST-com.lps.cms.notification.producer.NotificationEventAvroMapperTest](test-report/surefire-reports/TEST-com.lps.cms.notification.producer.NotificationEventAvroMapperTest.xml)
- [TEST-com.lps.cms.notification.producer.NotificationPartitionKeyTest](test-report/surefire-reports/TEST-com.lps.cms.notification.producer.NotificationPartitionKeyTest.xml)
- [TEST-com.lps.cms.notification.producer.NotificationProducerTest](test-report/surefire-reports/TEST-com.lps.cms.notification.producer.NotificationProducerTest.xml)
- [TEST-com.lps.cms.notification.service.EventValidatorTest](test-report/surefire-reports/TEST-com.lps.cms.notification.service.EventValidatorTest.xml)
- [TEST-com.lps.cms.notification.service.MetadataEnricherTest](test-report/surefire-reports/TEST-com.lps.cms.notification.service.MetadataEnricherTest.xml)
- [TEST-com.lps.cms.notification.service.NotificationServiceTest](test-report/surefire-reports/TEST-com.lps.cms.notification.service.NotificationServiceTest.xml)
