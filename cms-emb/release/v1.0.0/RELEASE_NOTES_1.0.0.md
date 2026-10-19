---
layout: default
title: "CMS Embossing and Vendor — v1.0.0"
---

# CMS Embossing and Vendor — v1.0.0

**Version:** 1.0.0 — initial delivery baseline.  
**Planned tag:** `1.0.0`
**Release Type:** Major — initial baseline  
**Scope:** Tenant-scoped personalisation batches, encrypted vendor files, SFTP transmission, and fulfilment callbacks.  
**Notes updated:** 19 October 2026

## Deployment summary

| Item | Status |
| --- | --- |
| Source baseline | `e2bf9361704c0b036b995f253def861ada40828f` |
| Artifact | `com.lps:embossing-service:1.0.0` |
| Source module | `cms_emb_vendor_service` |
| Release identity | Intended `refs/tags/1.0.0`; tag commit, creation date, and tagger not confirmed |
| Previous release | No previous tag used; initial capability baseline, not a tag comparison |
| Production card data | Requires an approved secure-data provider; missing provider blocks file generation |
| Gateway compatibility | Current gateway predicates do not route the institution-scoped Embossing API to this service |
| Deployment readiness | Live database/SFTP integration, final release identity, and environment acceptance not confirmed |

## Overview

The service reserves eligible CMS production requests into personalisation batches, generates encrypted vendor files, and transmits configured files by SFTP. Vendor and courier callbacks are recorded and converted into shared CMS fulfilment commands. CMS Core continues to own card data and core production tables.

## Features

- **Batch processing:** Groups reserved requests by institution, vendor, configuration, product, and request type, applying the configured batch-size limit.
- **Waybill assignment:** Pairs eligible requests with available waybills; requests without an available pairing remain eligible.
- **Encrypted files:** Writes ASCII-armored OpenPGP files with institution/vendor encryption keys and cleartext/ciphertext SHA-256 checksums.
- **Vendor transmission:** Uploads ready files configured for SFTP; a failed upload does not prevent other uploads.
- **Fulfilment reporting:** Accepts vendor results and courier events, deduplicates callbacks, and publishes commands through the shared CMS outbox.
- **Reconciliation:** Records unresolved fulfilment mismatches for operational follow-up.

## Security

- Bearer tokens must satisfy configured issuer and audience validation; default audience is `cms-api`.
- `cms:embossing:read` permits reads; `cms:embossing:manage` permits callbacks and also reads.
- Institution-scoped callers must match the path using `institution_id`; `platform_access=true` supports approved cross-institution access. Caller-supplied `X-Institution-Id` is rejected.
- The service does not decrypt CMS card envelopes. Production generation requires the scoped secure-data export provider.
- Configure SFTP host-key verification before enabling transmission; strict checking defaults to false. No security certification is asserted.

## Reliability and maintenance

- Scheduled and optional startup runs support a configurable claim limit and cron schedule.
- Fulfilment callbacks compare repeated provider event identities and payload hashes; conflicting reuse is rejected.
- Status advancement checks the expected request status before recording a command.
- Tests cover pipeline, batching, file formatting/encryption/transmission, callback handling, outbox behavior, API/security, and reconciliation. No measured performance improvement is claimed.

## Pre-release corrections and bug fixes

Verified development changes included in this baseline:

- **API authentication documentation:** Added the OpenAPI bearer scheme and security requirement so consumers can identify the token contract.
- **Listener configuration:** Removed the misplaced nested server-port setting and the development port override; shared configuration now uses 9803. The production profile independently defaults to 8080, so deployment ports must be aligned.
- **Java/Spring compatibility:** Updated entity-scanning imports and Jackson APIs for Java 25/Spring Boot 4, including fulfilment-command and outbox serialization.

These are development corrections included in the initial delivery, not fixes compared with a previously delivered tagged release. Target-environment operation remains to be validated.

## JUnit test results

The verified **19 October 2026** run used `mvn clean test org.jacoco:jacoco-maven-plugin:0.8.15:report`:

| Tests reported | Passed | Failures | Errors | Skipped |
| --- | --- | --- | --- | --- |
| 199 | 199 | 0 | 0 | 0 |

The aggregate suite duration was 3.795 seconds. This fresh run completed successfully on 19 October across 46 test suites. Mocked tests do not establish live PostgreSQL, SFTP, secure-data-provider, or deployed CMS integration readiness.

## Measured code coverage

| Metric | Result |
| --- | --- |
| Line coverage | 82.27% — 1,346 / 1,636 lines |
| Branch coverage | 70.45% — 360 / 511 branches |
| Instruction coverage | 83.42% — 7,427 / 8,903 instructions |

Coverage includes all compiled production Java classes without package exclusions. See the [JUnit report](test-report/junit/index.html), [JaCoCo report](test-report/jacoco/index.html), and [evidence bundle](test-report/cms-emb-vendor-test-and-coverage-reports.zip). Preserve generated evidence before `mvn clean`.

## Requirements and compatibility

| Component | Requirement / behavior |
| --- | --- |
| Java / framework | Java 25; Spring Boot 4.1.1 |
| Database | PostgreSQL with pre-existing `cms_v2` and compatible CMS Core tables |
| Shared listener | 9803; production profile uses `${SERVER_PORT:8080}` |
| Integrations | Identity provider, CMS secure-data export, shared outbox, vendor SFTP when enabled |
| Storage | Writable encrypted-file output directory |

All business routes use `/cms/api/v2/institutions/{institutionId}`:

| Method | Path after institution prefix | Purpose |
| --- | --- | --- |
| GET | `/personalisation-batches` | List batches |
| GET | `/personalisation-batches/{batchId}` | Retrieve a batch |
| GET | `/personalisation-batches/{batchId}/files` | List batch files |
| GET | `/personalisation-files/{fileId}` | Retrieve a file record |
| POST | `/vendor-results` | Record vendor fulfilment results |
| POST | `/courier-events` | Record courier fulfilment events |

List APIs use 1-based pages and a limit of at most 100. Vendor results include ACCEPTED, PERSONALIZED, FILE_COMMITTED, and FAILED. Courier events include DISPATCHED, DELIVERED, RETURNED, and REDISPATCHED. OpenAPI is `/api-docs`; Swagger UI is `/swagger-ui.html`.

## Deployment prerequisites

Service migrations create `production_attempt`, `reconciliation_exception`, and `vendor_pgp_encryption_key` (V1), and `provider_inbox_event` (V2). Flyway does not create `cms_v2`. CMS Core production-request, card, waybill, batch-configuration, and shared outbox structures must be compatible before processing starts.

| Configuration | Required setup |
| --- | --- |
| SPRING_PROFILES_ACTIVE | Set prod for production settings |
| SPRING_DATASOURCE_URL / USERNAME / PASSWORD | Supply approved datasource values using the full `SPRING_DATASOURCE_*` names |
| CMS_AUTH_ISSUER_URI / CMS_AUTH_JWK_SET_URI / CMS_AUTH_AUDIENCE | Trusted issuer, keys, and audience |
| SERVER_PORT | Align service and gateway ports |
| EMBOSSING_V2_FIXTURE_CARD_DATA | Keep false outside development; provision a real secure-data provider |
| EMBOSSING_V2_ENABLED / EMBOSSING_SCHEDULE_CRON | Control scheduled processing |
| EMBOSSING_RUN_ON_STARTUP | Production default false |
| EMBOSSING_SFTP_ENABLED | Production default false; enable only after vendor setup |
| EMBOSSING_SFTP_HOST / PORT / USERNAME / PASSWORD / REMOTE_PATH | Approved vendor connection settings, supplied securely |
| EMBOSSING_SFTP_STRICT_HOST_KEY_CHECKING | Configure host-key verification |

Provision an appropriate active PGP key for each institution/vendor pair. Configure `embossing.output-path` and retention. Confirm schema ownership, gateway routing, security claims, schedule, and vendor acceptance before production enablement.

## Build and deployment

Use `mvn clean verify`; expected artifact: `target/embossing-service-1.0.0.jar`. Available evidence covers the test/report command above; final package identity and deployment approval are not confirmed. Restart after configuration changes.

Production defaults disable fixture data, startup processing, and SFTP; scheduled processing remains enabled unless explicitly disabled. Shared configuration disables Eureka; configure its endpoint if explicitly enabling registry integration.

## Deployment verification

- Verify authentication, permission boundaries, and institution isolation.
- Rehearse database migration and confirm CMS-owned table compatibility.
- Validate secure-data access, batch/waybill allocation, PGP decryption by the intended vendor, checksums, and SFTP receipt.
- Verify duplicate/conflicting callbacks, outbox commands, status transitions, and reconciliation.
- Correct gateway routing before exposing the institution-scoped APIs through it.

## Known limitations

- Missing secure-data export integration prevents production file generation when fixtures are disabled.
- The gateway's dedicated Embossing predicates do not match these APIs; its broad `/cms/api/v2/**` predicate currently selects CMS Core.
- SFTP strict host-key checking is disabled by default and requires deployment configuration.
- Live integrations, migration/recovery rehearsal, final tag identity, and deployment environment/date are not confirmed.

## Rollback

Disable scheduled/startup processing and SFTP, then stop active instances. Restore an earlier approved application only after confirming shared-schema compatibility; otherwise withdraw the initial installation. Preserve production reservations, files, inbox/outbox records, and vendor receipts for reconciliation. Reverting the application does not undo migrations or files already delivered.

## References

- [Service documentation](guides/service-documentation.html)
- [JUnit report](test-report/junit/index.html)
- [JaCoCo coverage](test-report/jacoco/index.html)
- [Test summary](test-report/report-summary.json)
- [Evidence bundle](test-report/cms-emb-vendor-test-and-coverage-reports.zip)


## Bundled release references

Guides and test evidence are included with this release for review without source-repository access. The reports preserve the recorded 19 October 2026 execution; no new tests were run for this reference update.

- [Coverage summary](test-report/coverage-summary.html)
- [Source identity and fingerprints](test-report/source-fingerprint.json)

## JUnit XML evidence

These XML files come from the matching evidence archive. Environment properties and embedded test output are omitted from the individual XML downloads.

- [TEST-com.lps.cms.embossing.perso.api.ApiResponseHelperTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.api.ApiResponseHelperTest.xml)
- [TEST-com.lps.cms.embossing.perso.api.PageableDefaultsTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.api.PageableDefaultsTest.xml)
- [TEST-com.lps.cms.embossing.perso.api.PagedResponseTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.api.PagedResponseTest.xml)
- [TEST-com.lps.cms.embossing.perso.api.RequestIdFilterTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.api.RequestIdFilterTest.xml)
- [TEST-com.lps.cms.embossing.perso.api.batch.PersonalisationBatchControllerTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.api.batch.PersonalisationBatchControllerTest.xml)
- [TEST-com.lps.cms.embossing.perso.api.batch.PersonalisationQueryServiceTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.api.batch.PersonalisationQueryServiceTest.xml)
- [TEST-com.lps.cms.embossing.perso.api.file.PersonalisationFileControllerTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.api.file.PersonalisationFileControllerTest.xml)
- [TEST-com.lps.cms.embossing.perso.api.security.EmbossingJwtRequestContextFilterTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.api.security.EmbossingJwtRequestContextFilterTest.xml)
- [TEST-com.lps.cms.embossing.perso.api.security.EmbossingSecurityConfigTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.api.security.EmbossingSecurityConfigTest.xml)
- [TEST-com.lps.cms.embossing.perso.cms.PgUuidArrayTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.cms.PgUuidArrayTest.xml)
- [TEST-com.lps.cms.embossing.perso.cms.batch.PersonalisationBatchStoreTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.cms.batch.PersonalisationBatchStoreTest.xml)
- [TEST-com.lps.cms.embossing.perso.cms.batch.PersonalisationReadStoreTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.cms.batch.PersonalisationReadStoreTest.xml)
- [TEST-com.lps.cms.embossing.perso.cms.card.CardFileStoreTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.cms.card.CardFileStoreTest.xml)
- [TEST-com.lps.cms.embossing.perso.cms.request.ProductionRequestStoreTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.cms.request.ProductionRequestStoreTest.xml)
- [TEST-com.lps.cms.embossing.perso.cms.waybill.WaybillStoreTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.cms.waybill.WaybillStoreTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.catalog.EmbossingEventSinkTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.catalog.EmbossingEventSinkTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.correlation.CorrelationIdResolverTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.correlation.CorrelationIdResolverTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.correlation.JobRunTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.correlation.JobRunTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.mapper.NotificationEnvelopeFactoryTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.mapper.NotificationEnvelopeFactoryTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.mapper.PayloadValuesTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.mapper.PayloadValuesTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.model.IdempotencyKeysTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.model.IdempotencyKeysTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.model.OutboxEventCommandTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.model.OutboxEventCommandTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.model.OutboxPublicationStatusTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.model.OutboxPublicationStatusTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.repository.OutboxEventRepositoryImplTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.repository.OutboxEventRepositoryImplTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.support.DatabaseUuidV7GeneratorTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.support.DatabaseUuidV7GeneratorTest.xml)
- [TEST-com.lps.cms.embossing.perso.event.writer.OutboxEventWriterTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.event.writer.OutboxEventWriterTest.xml)
- [TEST-com.lps.cms.embossing.perso.exception.EmbossingExceptionHandlerTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.exception.EmbossingExceptionHandlerTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.EmbossingDataFactoryTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.EmbossingDataFactoryTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.EncryptedFileWriterTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.EncryptedFileWriterTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.FileContentWriterTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.FileContentWriterTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.crypto.PgpPublicKeyResolverTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.crypto.PgpPublicKeyResolverTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.crypto.StreamingPgpEncryptorTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.crypto.StreamingPgpEncryptorTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.data.FixtureSensitiveCardDataProviderTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.data.FixtureSensitiveCardDataProviderTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.data.SecureDataExportRequiredProviderTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.data.SecureDataExportRequiredProviderTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.format.EmbossingDetailLineFormatterTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.format.EmbossingDetailLineFormatterTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.format.EmbossingFooterFormatterTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.format.EmbossingFooterFormatterTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.format.EmbossingHeaderFormatterTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.format.EmbossingHeaderFormatterTest.xml)
- [TEST-com.lps.cms.embossing.perso.file.transmit.FileTransmitterTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.file.transmit.FileTransmitterTest.xml)
- [TEST-com.lps.cms.embossing.perso.pipeline.EmbossingPipelineSchedulerTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.pipeline.EmbossingPipelineSchedulerTest.xml)
- [TEST-com.lps.cms.embossing.perso.pipeline.FulfilmentJobTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.pipeline.FulfilmentJobTest.xml)
- [TEST-com.lps.cms.embossing.perso.pipeline.PipelineTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.pipeline.PipelineTest.xml)
- [TEST-com.lps.cms.embossing.perso.reconciliation.FulfilmentMismatchQueryTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.reconciliation.FulfilmentMismatchQueryTest.xml)
- [TEST-com.lps.cms.embossing.perso.reconciliation.ReconciliationJobTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.reconciliation.ReconciliationJobTest.xml)
- [TEST-com.lps.cms.embossing.perso.report.FulfilmentReportServiceTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.perso.report.FulfilmentReportServiceTest.xml)
- [TEST-com.lps.cms.embossing.v2.file.transmit.FileTransmitterTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.v2.file.transmit.FileTransmitterTest.xml)
- [TEST-com.lps.cms.embossing.v2.pipeline.PipelineTest](test-report/surefire-reports/TEST-com.lps.cms.embossing.v2.pipeline.PipelineTest.xml)
