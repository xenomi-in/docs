# Cross-service release compatibility

This is the shared release register for the listener integration. Entries describe observed evidence, not promised interoperability. Other service owners should link their release notes and fill in exact versions/commits and environment acceptance before promotion.

## Authentication directions

Both services validate incoming requests. Each caller must obtain and attach a token accepted by the receiving service; token handling in one direction does not provide authentication in the reverse direction.

| Direction | Purpose | Implementation and acceptance status |
| --- | --- | --- |
| **TCP Listener → Switch Core** | Forward financial transactions and configured DKE requests | The listener implements OAuth client credentials and bearer-token attachment. Switch Core requires a valid token. Correct deployment credentials, issuer/audience/scopes, and transport configuration are required; end-to-end acceptance is not established by the local listener tests. |
| **Switch Core → TCP Listener** | Send issuer-originated ISO8583 requests, including mandate revocation, for delivery to RuPay | In reviewed Switch Core source `a33b3a4`, `HttpIssuerActionMessageGateway` does not attach a bearer token. The **TCP Listener rejects the unauthenticated business API request**. This is the authentication gap blocking acceptance of that flow. |

The mandate-revocation blocker concerns **Switch Core as the caller**, not missing transaction-forwarding OAuth support in the listener. Listener business APIs require authentication in every profile; health endpoints remain public. Where direct mTLS is enforced, missing client transport credentials can cause rejection before token validation.

The **RuPay TLS confirmation is a separate requirement**: the listener's production profile requires a TLS/mTLS scheme endpoint. NPCI/Falcon must confirm that the deployed connection supports this requirement. Neither token implementation nor local container health checks confirm that link.

## Release combinations and decisions

| Release set | TCP Listener | Switch Core | Other dependencies | Environment / evidence | Decision |
| --- | --- | --- | --- | --- | --- |
| Pre-correction review | Undistributed v1.0.0 (`a4c085c`); tests on `774c33a` | Reviewed source `a33b3a4`; compatible release unknown | Keycloak configuration and RuPay TLS endpoint not jointly verified | Local listener automated tests only; no jointly tested service combination recorded | Blocked for complete integration acceptance: reviewed Switch Core → TCP Listener mandate-revocation calls lack a bearer token, so the listener rejects them. Separately, production RuPay TLS compatibility awaits NPCI/Falcon confirmation |
| Corrected initial candidate | 1.0.0 working tree; existing pre-release tag still at `a4c085c` | Minimum release **TBD**: Switch Core must attach a bearer token accepted by the listener to mandate-revocation calls and satisfy the listener's configured mTLS boundary | Keycloak issuer/client/audience/scopes; NPCI/Falcon-approved TLS endpoint | Fresh version-aligned verification recorded in the candidate verification report; committed CI, service integration, simulator and Falcon UAT checks pending | Not approved for Falcon UAT/production deployment: a compatible Switch Core caller release, joint integration evidence, and NPCI/Falcon RuPay TLS confirmation are pending |

References: [listener v1.0.0 candidate notes](RELEASE_NOTES_v1.0.0.md), [local verification](VERIFICATION_v1.0.0.md), [authentication](../KEYCLOAK_AUTHENTICATION.md), [deployment setup](../DEPLOYMENT_CONFIGURATION_SETUP.md), and [release process](RELEASE_PROCESS.md).

Switch Core release-note URL and the compatible release version are pending owner confirmation. No other service's release version or acceptance status is asserted here. Add each service's published notes and acceptance evidence rather than assuming matching version numbers imply compatibility.

For each accepted combination, record: immutable build identities; service-note links; environment and test date; simulator versus live scheme boundary; test results; configuration revision without secrets; known exceptions; approving owner; and rollback combination. Keep previous accepted combinations for rollback reference.
