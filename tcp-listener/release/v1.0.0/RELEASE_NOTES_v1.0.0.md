---
layout: default
title: "ISO8583 TCP Listener — v1.0.0"
---

# ISO8583 TCP Listener — v1.0.0

**Version:** `1.0.0` — initial release candidate, not yet distributed to the client.
**Planned tag:** `v1.0.0`; the existing tag still points to `a4c085c` and must be refreshed after the reviewed changes are committed.  
**Notes updated:** 19 October 2026

## Deployment summary

| Item | Status |
| --- | --- |
| Version | Maven `1.0.0`; executable `switch-1.0.0.jar` |
| Build identity | Local candidate identity and results: [verification evidence](VERIFICATION_v1.0.0.html). |
| Switch Core requirement | Requires authenticated mandate-revocation calls; minimum compatible release is **not yet confirmed**. Reviewed source `a33b3a4` does not attach a token |
| RuPay requirement | Production requires a TLS/mTLS endpoint; NPCI/Falcon link confirmation remains outstanding (T-TCP-10) |
| UAT / production readiness | **Not approved by the available evidence**; complete service compatibility and environment acceptance remain open |

Health endpoints are public; business and management APIs require authentication in every profile. Switch Core at `a33b3a4` does not attach a bearer token in `HttpIssuerActionMessageGateway`, so mandate-revocation calls cannot succeed against the protected listener API as implemented. With direct mTLS enforced, missing transport credentials may cause rejection before token validation. Record the minimum compatible release in the [cross-service release list](RELEASE_COMPATIBILITY.html) after the fix and joint verification.

Production requires scheme TLS and validates certificate stores even in `server` mode. A plaintext-only leased line is incompatible with this production profile. Obtain NPCI/Falcon confirmation of the actual TLS termination point, hostname, trust anchors, and client-certificate requirements before rollout.

## Overview

v1.0.0 introduces the ISO8583 TCP Listener for connecting RuPay scheme traffic to Switch Core. It includes bidirectional message delivery, network-management operations, connection monitoring, virtual-thread processing, and security controls for service authentication, transport encryption, and production deployment.

This is the initial release candidate. The client has not received v1.0.0, so the release remains 1.0.0 while the pre-release corrections are completed.

## Features

- **RuPay connectivity:** Netty TCP client with two-byte binary length framing and ISO8583 packing/unpacking through jPOS and the bundled RuPay packager.
- **Switch Core integration:** Forward financial transactions and configured DKE messages to Switch Core HTTP APIs, including `site_id`, `listener_id`, and scheme-specific `connection_id` headers.
- **Outbound scheme messaging:** Accept Switch Core requests through `POST /api/v1/switch-core/iso8583` and `POST /api/v1/switch-core/{scheme}/iso8583`. Success acknowledges a socket write; it does not confirm a scheme response or transaction approval.
- **Network management:** Support sign-on, sign-off, echo, cutover, and configured key-management operations, with scheme-specific field 70 codes and REST APIs for connection management and ZPK/ZAK DKE initiation.
- **Connection lifecycle:** Track TCP connection and sign-on state, reconnect using a configurable delay, and close channels and executors during graceful shutdown.
- **Concurrent processing:** Use Java virtual threads for request processing and I/O work.
- **Observability:** Expose connection/status APIs, health checks, and Prometheus gauges for TCP connectivity, sign-on, and endpoint readiness.
- **Configuration:** Select the active scheme, endpoint, packager, timeouts, reconnect interval, and network-management codes through application configuration.

## Security

- Keycloak JWT validation checks signature, issuer, timestamps, audience, and the expected caller's `azp` claim. HTTP access uses scoped authorization and a default-deny policy.
- Listener calls to Switch Core support OAuth 2.0 client credentials, cached access tokens, and token renewal after expiry.
- Production startup validates authenticated TLS for the Switch Core and scheme connections, including HTTPS Switch Core URLs, client identities, and trust stores. These paths support TLS 1.2/1.3 and hostname verification, with separate credentials for each connection.
- Incoming listener APIs support enforcement of direct mutual TLS. Deployment configuration must enable and provision this boundary.
- Raw ISO8583, JSON, and TCP-frame logging is disabled by default; enabling raw-data logging with the `prod` profile prevents startup.
- The container runs as UID/GID `1001:1001`. The supplied Compose configuration applies a read-only root filesystem, dropped capabilities, disabled privilege escalation, and a restricted temporary filesystem. Base images are pinned by digest.

These are implemented security controls, not a statement of PCI DSS certification or independent compliance validation.

## Reliability and maintenance

- Improved reconnect, timeout, connection shutdown, and executor shutdown handling.
- Improved sign-on/sign-off status tracking, downstream API error diagnostics, and response mapping.
- Separated ISO response mapping and network-message processing from the RuPay client handler. Legacy `RuPayClientChannel`, `ISOClientChannel`, and `TestClient` classes remain outside the active connector path.
- Expanded automated coverage for message mapping, channel framing, security configuration, transport validation, connector lifecycle, routing, and error paths.


## JUnit test results

Candidate results, exact artifact SHA-256, and local image identity are recorded in the [local verification report](VERIFICATION_v1.0.0.html). CI identity is assigned only after a successful workflow run on the committed candidate.

The original review used source `774c33a12e1d9c7e959f6e12d46784f2f79f9042`: 24 suites, 85 tests passed, zero failures/errors/skips, completed on 17 October 2026 at 06:31:37 IST using Maven 3.9.10 and OpenJDK 25.0.2 on macOS aarch64. The existing `v1.0.0` tag points to `a4c085c`, two documentation/report-only commits later. Those original results apply to that source baseline; they do not identify the corrected candidate's binary.

These are local automated unit/component tests using mocks and embedded channels. No completed RuPay simulator session, Falcon UAT acceptance, production TLS validation, load/soak test, or external service integration is claimed. The container smoke test uses the test profile and does not contact those services.

Original report evidence is retained locally in the source repository under ignored `release-assets/v1.0.0/` and bundled here as [pre-correction reports](#bundled-pre-correction-reports). Candidate reports will be attached to the draft release by a successful tag workflow. **Release asset upload is pending.** Do not replace the candidate evidence with the earlier archive.

## Measured code coverage

The local verification report records candidate JaCoCo metrics. The original reviewed source measured **80.00% line coverage** and **64.66% branch coverage** with JaCoCo 0.8.14; those metrics are historical comparison evidence, not an enforced quality gate.

Generate fresh reports for this candidate with `mvn clean verify`. Surefire XML is under `target/surefire-reports/`; JaCoCo HTML/XML/CSV is under `target/site/jacoco/`. See the [release process](RELEASE_PROCESS.html) for CI artifacts and build identity.

## Requirements and compatibility

| Component | Requirement / behavior |
| --- | --- |
| Java | Java 25; earlier Java runtimes are unsupported by this build |
| Build | Maven 3.6+ as documented in the README; container builder uses Maven 3.9.16 |
| Framework | Spring Boot 4.1.1 |
| ISO8583 library | jPOS 3.0.1 |
| HTTP port | `9700` by default |
| Scheme support | RuPay; one active scheme per application instance |
| External services | Scheme endpoint, Switch Core transaction/DKE APIs, and Keycloak for authenticated flows |

### Deployment prerequisites

1. Upgrade the build and runtime environment to Java 25 and account for the Spring Boot 4.1.1 platform migration.
2. Configure Keycloak issuer, JWK endpoint, expected caller, audience, and scopes. Previously unauthenticated API clients must supply valid bearer tokens.
3. Provision Switch Core OAuth client credentials and token endpoint through deployment secrets.
4. For production, configure HTTPS Switch Core URLs and separate `SWITCH_CORE_TLS_*` and `SCHEME_TLS_*` client key/trust stores. Both remote endpoints must accept the configured TLS/mTLS connections.
5. Set `KEYCLOAK_REQUIRE_MTLS=true` for direct incoming API mTLS enforcement and configure the listener's HTTPS/client-certificate boundary. Compose defaults this flag to true; direct JAR deployments must set it explicitly. See the [deployment, configuration, and setup guide](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/docs/DEPLOYMENT_CONFIGURATION_SETUP.md) for HTTPS and certificate settings.
6. Review scheme-specific field 70 codes, `site_id`, `listener_id`, and `connection_id` against downstream configuration.
7. For hardened container deployments, provide a log directory writable by UID/GID `1001:1001` and mount certificates/configuration read-only. Disable raw-data logging in production.

## Build and deployment

After committing the corrections and refreshing the undistributed tag, build the tagged source in a clean checkout:

```bash
git checkout --detach v1.0.0
mvn clean verify
```

The corrected Maven version is `1.0.0`; the generated artifact is `target/switch-1.0.0.jar`. Record the committed source revision and the artifact/image identity from the same verified build.

To build a version-labeled container:

```bash
docker build -f dockerfile -t iso8583-switch:1.0.0 .
```

The default Docker build runs Maven verification. CI packages the exact JAR from its successful test/build job using the Dockerfile release target. Configure environment values, secrets, certificates, and profile settings using the [README](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/README.md), [production usage guide](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/docs/CHANNEL_CLIENT_USAGE.md), and supplied `docker-compose.yml` before deployment.

### Deployment verification

- Confirm `/actuator/health` responds successfully, then check authenticated connection/status and metrics endpoints using their required scopes.
- In client mode, verify TCP connection, sign-on, echo, transaction forwarding, outbound socket writes, and DKE using approved test data and the intended endpoints.
- Verify reconnect and graceful shutdown behavior, rejection of unauthorized requests, and production startup rejection of invalid transport configuration.
- Validate the complete Switch Core → listener authentication flow before enabling that traffic; the integration limitation below must be resolved in the calling service.

## Known limitations

- **Silent connection loss is not promptly detected by default (T-TCP-12).** RuPay read and idle timeouts are zero, so their timeout handlers are absent. The 30-second check examines local socket/channel state. Silent peer/network loss may remain undetected until socket I/O fails or OS keepalive detects it; timing depends on host settings. Idle-triggered echo code exists but is disabled by the zero idle timeout. There is no independent periodic echo scheduler.
- **No listener-level duplicate or out-of-order detection (T-TCP-13).** Requests are not protected by a persistent deduplication or sequencing mechanism.
- **No attributable management audit trail (T-TCP-3).** Sign-on, sign-off, and key-exchange APIs do not record the authenticated initiating identity in a dedicated audit record. Operational logging is not an equivalent audit trail.
- **Legacy classes remain (T-TCP-15).** `RuPayClientChannel`, `ISOClientChannel`, and `TestClient` are still in production sources outside the active connector path.
- **Memory/load acceptance remains pending.** Compose now leaves nominal non-heap headroom; validate the 2 GB heap within its 4 GB limit under representative traffic.
- **Untested audit paths.** End-to-end key exchange (T-TCP-16) and Switch Core outage/message disposition (T-TCP-5) have not been established by the available release evidence and require focused integration tests.

- Only RuPay has a registered connector/handler. Visa and MasterCard configuration entries are placeholders and do not provide working connectors.
- One application instance supports one active scheme. `app.mode=server` starts the Spring context without opening the outbound scheme connection; it is not an inbound scheme TCP server implementation.
- Measured line coverage is 80.00% and branch coverage is 64.66%. The build does not enforce a coverage threshold; these metrics do not establish production certification or complete business-scenario coverage.

## Rollback

No earlier client deployment is confirmed. Retain the accepted artifact/image and its compatible configuration for recovery. If replacing an actual untagged deployment, record and retain that exact combination before rollout. If rollback is needed, stop the new instance cleanly, restore the retained deployment and its compatible configuration, and verify connectivity and sign-on before resuming traffic. Coordinate in-flight transaction handling with Switch Core and the scheme; do not blindly replay requests.

## References

Implementation guides below are maintained on the source repository’s `refactor` branch and may change independently of this candidate. Access requires permission to that repository.

- [Candidate verification and build identity](VERIFICATION_v1.0.0.html)
- [Deployment, configuration, and setup](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/docs/DEPLOYMENT_CONFIGURATION_SETUP.md)
- [Cross-service release compatibility](RELEASE_COMPATIBILITY.html)
- [Release build and evidence](RELEASE_PROCESS.html)
- [Setup, configuration, and API scopes](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/README.md)
- [Keycloak service authentication and pending integration](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/docs/KEYCLOAK_AUTHENTICATION.md)
- [Production implementation guide](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/docs/CHANNEL_CLIENT_USAGE.md)
- [Tester guide](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/docs/testing.md)
- [Architecture](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/docs/architecture.md)
- [Channel implementation](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/docs/CHANNEL_IMPLEMENTATION.md)
- [Virtual-thread migration](https://github.com/lps-pavangutha/tcp-listner/blob/refactor/docs/VIRTUAL_THREAD_MIGRATION.md)

### Bundled pre-correction reports

These reports apply to source `774c33a`, not the corrected candidate binary.

- [JUnit test results](test-report/junit/index.html)
- [JaCoCo coverage report](test-report/jacoco/index.html)
- [Maven build log](test-report/build.log)
- [Surefire XML and text reports](test-report/surefire-reports/)
- [Download original test reports](test-report/v1.0.0-test-reports.zip)
