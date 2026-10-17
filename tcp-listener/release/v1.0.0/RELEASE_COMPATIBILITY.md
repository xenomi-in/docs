# Cross-service release compatibility

This is the shared release register for the listener integration. Entries describe observed evidence, not promised interoperability. Other service owners should link their release notes and fill in exact versions/commits and environment acceptance before promotion.

| Release set | TCP Listener | Switch Core | Other dependencies | Environment / evidence | Decision |
| --- | --- | --- | --- | --- | --- |
| Pre-correction review | Undistributed v1.0.0 (`a4c085c`); tests on `774c33a` | Reviewed source `a33b3a4`; compatible release unknown | Keycloak configuration and RuPay TLS endpoint not jointly verified | Local listener automated tests only; no jointly tested service combination recorded | Blocked: mandate-revocation gateway has no bearer token; TLS link confirmation pending |
| Corrected initial candidate | 1.0.0 working tree; existing pre-release tag still at `a4c085c` | Minimum release **TBD**, must attach listener token and satisfy its mTLS boundary | Keycloak issuer/client/audience/scopes; NPCI/Falcon-approved TLS endpoint | Fresh version-aligned verification recorded in the candidate verification report; committed CI, service integration, simulator and Falcon UAT checks pending | Not approved for Falcon UAT/production deployment |

References: [listener v1.0.0 candidate notes](RELEASE_NOTES_v1.0.0.md), [local verification](VERIFICATION_v1.0.0.md), [authentication](../KEYCLOAK_AUTHENTICATION.md), [deployment setup](../DEPLOYMENT_CONFIGURATION_SETUP.md), and [release process](RELEASE_PROCESS.md).

Switch Core release-note URL and the compatible release version are pending owner confirmation. No other service's release version or acceptance status is asserted here. Add each service's published notes and acceptance evidence rather than assuming matching version numbers imply compatibility.

For each accepted combination, record: immutable build identities; service-note links; environment and test date; simulator versus live scheme boundary; test results; configuration revision without secrets; known exceptions; approving owner; and rollback combination. Keep previous accepted combinations for rollback reference.
