---
published: false
layout: default
title: "CMS Core Service — Code Coverage"
---

# Code Coverage Documentation

## Overview

This project uses **JaCoCo (Java Code Coverage)** to measure and report code coverage for the CMS Core Service application.

## Coverage Configuration

### Coverage Goal and Current Build Gates

The release-quality goal is **80% overall line coverage** for the V2 application and its supported shared runtime packages.

The current non-regression gates configured in `pom.xml` are:

- **Line coverage**: minimum 80%
- **Branch coverage**: minimum 25%

The overall line target is now enforced by the build. The branch floor remains a baseline and should be raised incrementally as validation, security, retry, and recovery paths gain coverage.

The coverage scope intentionally includes V2 and the shared components called directly by V2. Legacy V1 APIs and services are outside this release-quality gate.

## Generating Coverage Reports

### Option 1: Using the Script (Recommended)

```bash
# Generate full coverage report (clean, test, report, check)
./generate-coverage.sh

# Or run individual steps
./generate-coverage.sh clean    # Clean previous builds
./generate-coverage.sh report   # Generate report (after tests)
./generate-coverage.sh check    # Check coverage thresholds
```

### Option 2: Using Maven Commands

```bash
# Run tests with coverage
mvn clean test

# Generate HTML report
mvn jacoco:report

# Check coverage thresholds using the configured Maven execution
mvn jacoco:check@check
```

## Viewing Coverage Reports

After generating the report, open the HTML report:

```bash
# On macOS
open target/site/jacoco/index.html

# On Linux
xdg-open target/site/jacoco/index.html

# On Windows
start target/site/jacoco/index.html
```

## Report Locations

- **HTML Report**: `target/site/jacoco/index.html` - Interactive HTML report
- **XML Report**: `target/site/jacoco/jacoco.xml` - For CI/CD integration
- **CSV Report**: `target/site/jacoco/jacoco.csv` - For spreadsheet analysis

## Coverage Metrics

JaCoCo provides several coverage metrics:

1. **Line Coverage**: Percentage of lines executed
2. **Branch Coverage**: Percentage of branches (if/else) executed
3. **Method Coverage**: Percentage of methods executed
4. **Class Coverage**: Percentage of classes with at least one executed method
5. **Instruction Coverage**: Percentage of bytecode instructions executed

## Current Coverage Status

Latest verified Java 25 / Spring Boot 4.1.1 snapshot, generated on **2026-10-15**, from:

```bash
mvn -q clean -Dtest='*Test,!OutboxPostgresIntegrationTest' test
```

The PostgreSQL integration suite is excluded by the current test policy.

| Metric | Covered | Total | Coverage |
|---|---:|---:|---:|
| Instructions | 39,147 | 48,717 | **80.36%** |
| Lines | 7,355 | 8,986 | **81.85%** |
| Branches | 2,400 | 4,334 | **55.38%** |
| Methods | 1,281 | 1,625 | **78.83%** |
| Classes | 316 | 366 | **86.34%** |

Test execution status: **563 discovered tests**, **512 passed**, 0 failures, 0 errors, and 51 skipped. `OutboxPostgresIntegrationTest` remains excluded from this verification run.

The **80% overall line-coverage goal is achieved** and is now protected by the JaCoCo build gate.

### Current V2 Package Highlights

| Package | Lines covered | Line coverage | Branch coverage | Status |
|---|---:|---:|---:|---|
| `com.xenomi.cms.core.hms.service` | 237 / 264 | **89.77%** | 70.59% | Line target achieved |
| `com.xenomi.cms.core.v2.switchsync` | 191 / 237 | **80.59%** | 58.33% | Line target achieved |
| `com.xenomi.cms.core.v2.product.controller` | 86 / 86 | **100.00%** | n/a | Line target achieved |
| `com.xenomi.cms.core.v2.card.lifecycle.command` | 1,013 / 1,252 | **80.91%** | 64.44% | Line target achieved |
| `com.xenomi.cms.core.v2.card.pin.switchpin` | 264 / 319 | **82.76%** | 55.35% | Line target achieved |
| `com.xenomi.cms.core.v2.card.replacement.service` | 104 / 106 | **98.11%** | 84.62% | Line and branch targets achieved |
| `com.xenomi.cms.core.v2.product.service` | 834 / 1,016 | **82.09%** | 45.90% | Line target achieved |
| `com.xenomi.cms.core.v2.card.service` | 382 / 450 | **84.89%** | 38.98% | Line target achieved |
| `com.xenomi.cms.core.v2.hsm.service` | 517 / 642 | **80.53%** | 44.35% | Line target achieved |
| `com.xenomi.cms.core.v2.card.pin` | 188 / 208 | **90.38%** | 66.39% | Line target achieved |

### V2 Controller Coverage

| Controller package | Lines covered | Line coverage | Branch coverage |
|---|---:|---:|---:|
| `com.xenomi.cms.core.v2.card.controller` | 13 / 13 | **100.00%** | n/a |
| `com.xenomi.cms.core.v2.card.replacement.controller` | 27 / 27 | **100.00%** | 81.25% |
| `com.xenomi.cms.core.v2.institution.controller` | 28 / 28 | **100.00%** | n/a |
| `com.xenomi.cms.core.v2.cardcontrol.controller` | 5 / 5 | **100.00%** | n/a |
| `com.xenomi.cms.core.v2.product.controller` | 86 / 86 | **100.00%** | n/a |
| `com.xenomi.cms.core.v2.card.lifecycle.controller` | 38 / 38 | **100.00%** | 83.33% |
| `com.xenomi.cms.core.v2.hsm.controller` | 34 / 34 | **100.00%** | 75.00% |
| `com.xenomi.cms.core.v2.bin.controller` | 29 / 29 | **100.00%** | n/a |

Controller coverage includes response-status contracts, one-based pagination and sorting delegation, lifecycle command envelopes, authority-derived caller types, asynchronous issuance/replacement routing, HSM import replay behavior, and unauthorized caller rejection.

`CardReplacementV2Service` now contains only its active compatibility responsibilities: request lookup, idempotent replay, replacement eligibility validation, PAN-strategy resolution, and the explicit lifecycle-command boundary. The unreachable duplicate successor-card orchestration was removed because supported renewal and security-replacement execution is owned by the V2 lifecycle-command APIs.

`NettyHsmService` now exposes only the HSM operations used by V2: protected-key exchange, protected PIN-block processing, random PIN offset generation, CVV generation, protected MAC/data operations, health checks, and client delegation. Unreferenced legacy clear-PIN and permanently-null local key lookup paths were removed. Switch synchronization coverage includes registration/update preparation, authenticated transport, receipt lookup, retry classification, pagination-independent queue processing, and Spring Boot 4 JSON compatibility.

The latest tranche covers card issuance draft finalization, BIN HSM-key assignment creation and reads, HSM replacement-key activation rollover, and PIN audit-history/controller behavior. Local PIN mutations were removed from `PinManagementV2Service` because supported V2 initialize/change/reset operations are owned by `SwitchPinService`; the service now contains only its active CMS audit-history responsibility.

To check current coverage:

```bash
# Run tests and generate report
mvn clean test jacoco:report

# View summary in console or open HTML report
```

## Improving Coverage

### Areas to Focus On

1. **Controllers**: Test all REST endpoints
2. **Services**: Test business logic and edge cases
3. **Repositories**: Test custom queries
4. **Mappers**: Test entity-DTO conversions
5. **Exception Handlers**: Test error scenarios

### Test Structure

Tests should be organized in `src/test/java` mirroring the main source structure:

```
src/test/java/
└── com/xenomi/cms/core/
    ├── institution/
    │   ├── controller/
    │   ├── service/
    │   └── repository/
    ├── product/
    ├── card/
    ├── bin/
    └── cardcontrols/
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Code Coverage

on: [push, pull_request]

jobs:
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up JDK 25
        uses: actions/setup-java@v4
        with:
          java-version: '25'
          distribution: 'temurin'
      - name: Run tests with coverage
        run: mvn clean test jacoco:report
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: target/site/jacoco/jacoco.xml
```

## Coverage Goals

### Target

- **Overall line coverage**: 80%+
- **Critical V2 business services**: 80%+ where the code is active and unit-testable
- **Branch coverage**: increase alongside line coverage, with emphasis on rejection, security, validation, retry, and recovery paths
- **Regression policy**: do not lower existing coverage or exclude production code solely to improve the reported percentage

The 80% goal applies to the configured V2 and supported shared-runtime scope. PostgreSQL integration coverage should be reported separately when those suites are enabled.

## Excluding Code from Coverage

To exclude specific classes or packages from coverage:

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <configuration>
        <excludes>
            <exclude>**/dto/**</exclude>
            <exclude>**/entity/**</exclude>
            <exclude>**/config/**</exclude>
        </excludes>
    </configuration>
</plugin>
```

## Troubleshooting

### Report Not Generated

1. Ensure tests are run first: `mvn test`
2. Check for compilation errors: `mvn clean compile`
3. Verify JaCoCo plugin is configured in `pom.xml`

### Coverage Shows 0%

1. Ensure tests are actually executing: Check test output
2. Verify test classes follow naming convention: `*Test.java` or `*Tests.java`
3. Check that tests are in `src/test/java` directory

### Threshold Check Failing

1. Review coverage report to identify low-coverage areas
2. Add tests for uncovered code
3. Adjust thresholds if needed (temporarily) in `pom.xml`

## Best Practices

1. **Run coverage regularly**: Before committing code
2. **Aim for meaningful coverage**: Focus on business logic, not just numbers
3. **Review coverage reports**: Identify untested edge cases
4. **Maintain test quality**: Good tests are more important than high coverage
5. **Update thresholds gradually**: Increase as coverage improves

## Resources

- [JaCoCo Documentation](https://www.jacoco.org/jacoco/trunk/doc/)
- [JaCoCo Maven Plugin](https://www.jacoco.org/jacoco/trunk/doc/maven.html)
- [Spring Boot Testing Guide](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.testing)

## Bundled verification reports — 15 October 2026

- [JUnit test results](test-report/JUnit_Test_Report.html)
- [JaCoCo coverage report](test-report/coverage/index.html)
- [JUnit XML results](test-report/junit-results.xml)
- [Test suites CSV](test-report/test-suites.csv)
- [Test cases CSV](test-report/test-cases.csv)
