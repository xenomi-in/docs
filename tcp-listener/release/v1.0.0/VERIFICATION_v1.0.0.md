# Local verification — v1.0.0 candidate

This is local working-tree evidence, not a refreshed tag or a successful GitHub CI run. The base commit is `a4c085cd968b1d511a87a0779f451971022d9662` with uncommitted pre-release corrections. The client has not received v1.0.0; the corrected candidate retains that version. Commit and refresh the undistributed tag before running release CI.

## Automated suite

- Command: `mvn -o --batch-mode clean verify`.
- Completed: 17 October 2026, 14:52:51 IST as recorded by Maven; 37.453 seconds.
- Environment: Maven 3.9.10, OpenJDK 25.0.2, macOS aarch64.
- Result: **BUILD SUCCESS**, 24 suites, **85 passed**, zero failures/errors/skips.
- JaCoCo 0.8.14: **80.00% line coverage** (2,280/2,850); **64.66% branch coverage** (463/716).

## Artifact and image identity

- JAR: `switch-1.0.0.jar`.
- JAR SHA-256: `d91bf2f15a0819a295d6b188fd4396c0502abf82dacad5f2c11a8102b2112f4b`.
- Local image: `tcp-listener:1.0.0-candidate`, Linux ARM64.
- Local image ID: `sha256:2216082954252c0c8ced51073ad566c10c74e8474efeba5dc545026b36f2be22`.
- Buildx image-index digest: `sha256:2216082954252c0c8ced51073ad566c10c74e8474efeba5dc545026b36f2be22`.
- Published registry digest: **none**; this image has not been pushed.

The image was built from the already verified JAR through the Dockerfile's `release` target. `scripts/verify-image.sh` confirmed that the embedded JAR has the exact Maven artifact SHA-256, then started a network-isolated, non-root container with a read-only root filesystem, writable temporary/log filesystems, and a 512 MB maximum heap within a 1 GB memory limit. The actual executable `/app/healthcheck.sh` successfully queried the running application.

The container used the `test` profile and `app.mode=server`. It did not contact RuPay, Switch Core, Keycloak, or Falcon. This is startup/health verification, not production TLS, integration, load, transaction, or audit acceptance.

## Evidence locations

Local generated evidence is under `target/release/`: `build-manifest.json`, `SHA256SUMS`, the JAR, `test-reports.tar.gz`, Maven output, image-build metadata, image-check output, image identity, and application smoke-test logs. It is ignored by Git and deleted by `mvn clean`; retain or upload it separately if needed. Earlier pre-correction evidence remains under ignored `release-assets/v1.0.0/` and must not be confused with this candidate's results.

The workflow bundles equivalent evidence with the committed revision and CI run URL, saves an image archive, and attaches successful tag builds to a draft GitHub Release. Its GitHub execution has not yet been verified. Review the [release process](RELEASE_PROCESS.md) and [compatibility register](RELEASE_COMPATIBILITY.md) before promotion.
