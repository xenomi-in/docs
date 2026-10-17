# Release build and evidence

## Release policy

The release owner confirmed that v1.0.0 has not been distributed to the client. Keep this corrected initial release at Maven version `1.0.0`. The existing tag points to the pre-correction commit `a4c085c`; it has not been changed by these working-tree updates. After review and commit, refresh the local/remote v1.0.0 tag to the approved commit so CI verifies that exact source. Record both old and new tag targets when replacing the pre-release tag. Keep tags immutable after client distribution; subsequent shipped changes require a new version.

Use the same release-note structure for every service: Falcon summary, version/build identity, required service versions, UAT/production status and blockers, exact test scope, known limitations, deployment configuration, and rollback. Include migration instructions only when an earlier deployed version is confirmed. Record tested combinations in the [release compatibility list](RELEASE_COMPATIBILITY.md).

## Automated build

`.github/workflows/release.yml` runs for pull requests, manual dispatch, and `v*` tags:

1. Run `mvn --batch-mode clean verify` under Java 25. JaCoCo runs with the tests and produces its report during `verify`.
2. Copy the resulting executable JAR into an isolated named Docker build context. The `release` Dockerfile target packages that JAR without recompiling or running a second Maven build.
3. Verify that `/app/app.jar` inside the image has the exact SHA-256 of the Maven output.
4. Start the image with its non-root user, a read-only root, restricted capabilities, a bounded heap, and the test profile. Execute its HTTP health-check script until it passes or times out.
5. Save the JAR, container-image archive, build metadata, smoke-test log, test/coverage archive, build manifest, and `SHA256SUMS` as a workflow artifact.
6. On successful tag runs, attach the deliverables to a **draft** GitHub Release. The tag must match `pom.xml`. Existing published releases are not updated by this workflow.

The default local Docker target separately runs Maven verification. Release CI uses `--target release --build-context release-artifact=./release-input` so the distributed image contains the JAR from that job's successful test/build run. Named contexts require Docker Buildx/BuildKit.

The workflow has been added to source; a successful GitHub run is required before claiming CI verification. The container test is an isolated startup/health smoke test, not evidence of RuPay TLS, Keycloak interoperability, financial processing, performance, or Falcon acceptance.

## Build identity

`build-manifest.json` records the source commit, workflow URL, JAR SHA-256, local image ID, and Buildx image digest where available. `SHA256SUMS` covers the downloadable deliverables. The image is distributed as a compressed Docker archive, not pushed to a registry by this workflow. A local image ID or Buildx digest must not be described as a published registry digest. If promoting to a registry, record its actual immutable repository digest and verify artifact identity during promotion.

After downloading assets into one directory:

```bash
sha256sum -c SHA256SUMS
gzip -dc iso8583-switch-1.0.0.tar.gz | docker load
```

On macOS use `shasum -a 256` to inspect individual checksums. Match the loaded image ID with the manifest, and deploy only the verified artifact. Retain its corresponding configuration and previous deployment for rollback.

## Original pre-correction evidence

In the source repository, generated reports have been removed from `docs/` and a local ignored archive remains at `release-assets/v1.0.0/v1.0.0-test-reports.zip`. This documentation repository includes a [copy of the original archive](test-report/v1.0.0-test-reports.zip), [JUnit results](test-report/junit/index.html), [coverage report](test-report/jacoco/index.html), and [build log](test-report/build.log) as pre-correction evidence. Removing generated files from the source tree does not erase earlier Git history.

The historical test run was on `774c33a`, while tag v1.0.0 is `a4c085c`; the difference is documentation/reports only. The historical archive is not evidence for a new JAR or image. No release upload has been performed by this repository change. If retaining it in the release, label the original archive as pre-correction evidence and distinguish it from the candidate reports. Do not use this pre-correction evidence as proof of the corrected release binary; publish fresh candidate evidence from CI.

## Falcon acceptance gates

Before publishing or deploying the draft candidate:

- Confirm the exact Switch Core release providing authenticated mandate-revocation calls, and test the combination.
- Confirm the NPCI/Falcon TLS boundary, client authentication, certificate chains, hostnames, and routing (T-TCP-10).
- Validate sign-on, sign-off, echo, transactions, and DKE against the intended simulator/environment.
- Exercise silent peer loss (T-TCP-12), duplicate/order behavior (T-TCP-13), audit requirements (T-TCP-3), key-exchange outcomes (T-TCP-16), and message disposition during Switch Core outages (T-TCP-5).
- Complete representative load/memory testing and graceful drain/rollback checks.
- Record actual environment/date, tested service versions, configuration revision, evidence links, owner, and acceptance decision in the release compatibility list.

Do not infer UAT or production acceptance from unit-test coverage or container health. Keep the PCI disclaimer and the distinction between socket write acknowledgement and transaction approval in each applicable service's notes.
