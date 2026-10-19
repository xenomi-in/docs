---
layout: default
title: "Keycloak configuration for CMS services"
---

# Keycloak configuration for CMS services

This guide defines the Keycloak contract used by the CMS API Gateway, CMS Core,
CMS Customer, and CMS Embossing/Vendor services. It describes the configuration
that the current source code expects; it is not a generic Keycloak tutorial.

## 1. Security architecture

```text
Browser / API client
        |
        | Authorization: Bearer <JWT>
        v
CMS API Gateway
  - verifies signature, issuer, time claims and audience
  - maps permissions[] to PERM_* authorities
  - removes caller-supplied identity headers
        |
        | forwards the original bearer token
        v
CMS Core / Customer / Embossing
  - independently verifies the JWT
  - maps permissions[] to PERM_* authorities
  - enforces endpoint permissions
  - enforces institution_id against the institution in the URL
```

The gateway is the public ingress. Backend services should be reachable only on
the private application network. Backend JWT validation is retained as defense
in depth and must not be used as a reason to expose backend ports publicly.

## 2. Realm and audience model

Create one realm:

| Setting | Value |
|---|---|
| Realm name | `cms` |
| Local issuer | `http://localhost:9000/realms/cms` |
| Required API audience | `cms-api` |
| Signing algorithm | `RS256` or an organization-approved asymmetric algorithm |
| Access-token lifetime | Short-lived; commonly 5–15 minutes |
| TLS | Required outside local development |

Every service expects the same issuer and audience. The access token must contain
`cms-api` in its `aud` array. A token can be correctly signed and still be rejected
with HTTP 401 if its audience does not contain `cms-api`.

Do not use the Keycloak realm name as the audience. The realm is the token issuer;
`cms-api` identifies the intended resource server.

## 3. Clients

Create the following clients in the `cms` realm.

### 3.1 `cms-api`

This client represents the CMS resource server and owns the CMS client roles.

| Setting | Value |
|---|---|
| Client ID | `cms-api` |
| Client authentication | On for service-account use; otherwise this may be a resource-only client |
| Standard flow | Off unless this client is also intentionally used interactively |
| Direct access grants | Off by default |
| Service accounts | Enable only if a CMS workload uses this client directly |
| Full scope allowed | Off in production |

### 3.2 Interactive UI client

Use a separate public client for a web application or Swagger OAuth flow, for
example `cms-web`.

| Setting | Value |
|---|---|
| Client type | Public |
| Standard flow | On |
| PKCE | `S256` required |
| Client authentication | Off |
| Direct access grants | Off |
| Valid redirect URIs (local) | Exact application callbacks only |
| Web origins | Exact allowed origins only |

Avoid wildcard production redirect URIs or web origins.

The current Swagger configuration accepts a bearer token through the **Authorize**
dialog; it does not perform the authorization-code flow itself. Obtain a token
from the application login flow or another approved OAuth client and paste only
the token value into Swagger.

### 3.3 Machine clients

Create a confidential client per calling workload rather than sharing one secret:

- `cms-notification-publisher`
- `cms-switch-sync`
- operations or batch clients as required

For each machine client:

| Setting | Value |
|---|---|
| Client authentication | On |
| Service accounts | On |
| Standard flow | Off |
| Direct access grants | Off |
| Full scope allowed | Off |

Assign only the required `cms-api` client roles to the service account. Store
client secrets in a secrets manager, never in source control.

## 4. Client scope and token mappers

Create a client scope named `cms-api-claims` and attach it as a **default client
scope** to every client that calls CMS. Configure the following protocol mappers.

### 4.1 Audience mapper

Create an Audience mapper:

| Mapper setting | Value |
|---|---|
| Included client audience | `cms-api` |
| Add to access token | On |
| Add to ID token | Off unless the UI explicitly needs it |

Expected output:

```json
"aud": ["cms-api"]
```

### 4.2 Permissions mapper

The Java services do **not** read `realm_access.roles` or
`resource_access.cms-api.roles`. They read a top-level, multivalued claim named
`permissions` and prefix every value with `PERM_` inside Spring Security.

Create a User Client Role mapper for roles from `cms-api`:

| Mapper setting | Value |
|---|---|
| Client ID | `cms-api` |
| Token claim name | `permissions` |
| Multivalued | On |
| Claim JSON type | String |
| Add to access token | On |
| Add to ID token | Off |
| Add to userinfo | Optional |

Expected output:

```json
"permissions": [
  "cms:institution:read",
  "cms:product:read",
  "cms:card:read"
]
```

Spring converts these to:

```text
PERM_cms:institution:read
PERM_cms:product:read
PERM_cms:card:read
```

Do not put the `PERM_` prefix into Keycloak roles; the applications add it.

### 4.3 Institution mapper

Tenant-scoped callers require a top-level `institution_id` claim containing the
institution UUID. Store the UUID as a user or service-account attribute and map it:

| Mapper setting | Value |
|---|---|
| User attribute | `institution_id` |
| Token claim name | `institution_id` |
| Claim JSON type | String |
| Add to access token | On |
| Multivalued | Off |

Example:

```json
"institution_id": "01a05875-78c8-7ea7-b7cb-164479f1f412"
```

CMS Customer temporarily also accepts `institution-id`, but all new tokens must
use `institution_id`. CMS Embossing accepts only `institution_id`.

### 4.4 Platform access mapper

Platform operators that legitimately work across institutions may receive:

```json
"platform_access": true
```

Create this as a boolean claim. Assign it only through a tightly controlled
platform-administrator group or service account. Do not set this claim for normal
institution users. When it is absent or false, the institution UUID in the URL
must exactly match `institution_id`.

### 4.5 Subject

The standard `sub` claim is required. Services use it as the authenticated actor
identifier and for audit context. Do not allow clients to choose or override it.

## 5. OAuth scopes versus CMS permissions

OAuth `scope` and CMS `permissions` are separate concepts:

- `scope` records the scopes granted to an OAuth client/request.
- `permissions` is the application authorization claim actually consumed by the
  gateway and services.
- `realm_access.roles` is not used by these services.
- `resource_access.*.roles` is not read directly; the permissions mapper copies
  the `cms-api` client roles into the expected top-level claim.

An OAuth scope by itself does not authorize a CMS endpoint. The matching value
must be present in `permissions`.

## 6. CMS API client roles

Create these client roles under `cms-api`.

### Gateway roles

| Client role | Purpose |
|---|---|
| `cms:gateway:admin` | Read protected gateway metrics and route actuator endpoints |
| `cms:internal:access` | Access gateway paths under `/internal/**` |

### CMS Core roles

| Client role | Access |
|---|---|
| `cms:institution:read` | Read institution APIs |
| `cms:institution:manage` | Create/update institution APIs |
| `cms:institution-policy:read` | Read operational, security and data-key policies |
| `cms:institution-policy:manage` | Change operational, security and data-key policies |
| `cms:bin:read` | Read BIN configuration |
| `cms:bin:manage` | Change BIN configuration |
| `cms:product:read` | Read products and card designs |
| `cms:product:manage` | Change products and card designs |
| `cms:hsm-key:read` | Read HSM key metadata and assignments |
| `cms:hsm-key:manage` | Generate/import/change HSM key metadata and assignments |
| `cms:card:read` | Read cards |
| `cms:card:manage` | General card lifecycle management |
| `cms:card:issue` | Issue cards and inspect issuance operations |
| `cms:card-control:read` | Read card controls |
| `cms:card-control:manage` | Change card controls |
| `cms:card-hotlist:customer` | Customer-channel hotlist action |
| `cms:card-hotlist:operations` | Operations-channel hotlist action |
| `cms:card-replace:customer` | Customer-channel replacement request |
| `cms:card-replace:operations` | Operations-channel replacement request |
| `cms:pin:read` | Read PIN status/history metadata |
| `cms:pin:change` | Initialize or change PIN |
| `cms:pin:reset` | Reset PIN state |

### CMS Customer roles

| Client role | Access |
|---|---|
| `cms:customer:read` | Read customer profiles, addresses and customer links |
| `cms:customer:manage` | Create/update customer profiles, addresses and links |
| `cms:account:read` | Read external account references and relationships |
| `cms:account:manage` | Create/update external account references and relationships |

### CMS Embossing/Vendor roles

| Client role | Access |
|---|---|
| `cms:embossing:read` | Read personalisation batches and files |
| `cms:embossing:manage` | Submit vendor results/courier events and manage workflows |

Confirm the exact role strings against `EmbossingPermissions` when adding new
embossing endpoints; the application remains the source of truth.

## 7. Recommended composite roles and groups

Keep endpoint permissions granular and use composite roles for job functions.
Example composites:

| Composite role | Suggested child roles |
|---|---|
| `cms-reader` | Institution, policy, BIN, product, card, card-control, HSM-key, customer, account and embossing read roles |
| `cms-product-admin` | Institution read, BIN read/manage, product read/manage |
| `cms-card-operations` | Card read/manage, issue, controls, hotlist operations, replacement operations, PIN read/reset |
| `cms-customer-operations` | Customer/account read/manage and limited card read |
| `cms-key-custodian` | HSM-key read/manage and institution-policy read/manage |
| `cms-platform-admin` | Explicitly reviewed administrative permissions plus `platform_access=true` |

Assign composites to Keycloak groups, and users to groups. Do not automatically
give every user every permission. Separate key custody, customer support, card
operations and platform administration where operational policy requires it.

## 8. Expected token

A tenant user token should resemble:

```json
{
  "iss": "http://localhost:9000/realms/cms",
  "sub": "5dd763e6-a38c-42b6-97da-c81ba04c2c5a",
  "aud": ["cms-api"],
  "azp": "cms-web",
  "exp": 1790742000,
  "iat": 1790741400,
  "institution_id": "01a05875-78c8-7ea7-b7cb-164479f1f412",
  "platform_access": false,
  "permissions": [
    "cms:institution:read",
    "cms:institution-policy:read",
    "cms:product:read"
  ],
  "scope": "openid profile email"
}
```

Validate tokens by decoding them locally or using an approved token-inspection
tool. Never paste production tokens into public websites.

## 9. Service configuration

All services must use the same values:

```bash
CMS_AUTH_ISSUER_URI=http://localhost:9000/realms/cms
CMS_AUTH_JWK_SET_URI=http://localhost:9000/realms/cms/protocol/openid-connect/certs
CMS_AUTH_AUDIENCE=cms-api
```

CMS Customer currently uses these equivalent variable names:

```bash
KEYCLOAK_ISSUER_URI=http://localhost:9000/realms/cms
KEYCLOAK_JWK_SET_URI=http://localhost:9000/realms/cms/protocol/openid-connect/certs
KEYCLOAK_AUDIENCE=cms-api
```

| Service | Issuer variables | Audience | Permission claim |
|---|---|---|---|
| API Gateway | `CMS_AUTH_ISSUER_URI`, `CMS_AUTH_JWK_SET_URI` | `CMS_AUTH_AUDIENCE` | `permissions` |
| CMS Core | `CMS_AUTH_ISSUER_URI`, `CMS_AUTH_JWK_SET_URI` | `CMS_AUTH_AUDIENCE` | `permissions` |
| CMS Customer | `KEYCLOAK_ISSUER_URI`, `KEYCLOAK_JWK_SET_URI` | `KEYCLOAK_AUDIENCE` | `permissions` |
| CMS Embossing/Vendor | `CMS_AUTH_ISSUER_URI`, `CMS_AUTH_JWK_SET_URI` | `CMS_AUTH_AUDIENCE` | `permissions` |

The issuer must exactly match the token `iss`, including scheme, host, port and
realm path. In containers, do not change the issuer merely because Keycloak is
reached through a different internal hostname. Configure Keycloak hostname/front
channel settings so it emits the externally canonical issuer, while services can
still reach the configured JWKS URI.

## 10. Public and protected endpoints

At the gateway:

- `/swagger-ui.html`, `/swagger-ui/**`, `/webjars/**`, `/v3/api-docs/**` and
  `/docs/**` are public so documentation can load.
- `/actuator/health/**` and `/actuator/info` are public.
- `/actuator/metrics/**` and `/actuator/gateway/**` require
  `cms:gateway:admin`.
- `/internal/**` requires `cms:internal:access`.
- Every other gateway request requires an authenticated token.

The backend services have migration-era exceptions: Core V1, Customer V1, and
non-V2 Embossing paths include permit-all rules. This is safe only while backend
ingress is private and all public traffic passes through the authenticated
gateway. These exceptions should be removed or explicitly permission-protected
before production cut-over.

## 11. Tenant enforcement

For tenant-scoped V2 endpoints, the URL contains an institution UUID:

```text
/cms/api/v2/institutions/{institutionId}/...
/api/v2/institutions/{institutionId}/...
```

Authorization succeeds only when one of these conditions is true:

1. `institution_id` equals `{institutionId}`; or
2. `platform_access` is the boolean value `true`.

The string `"true"` is not equivalent to the boolean `true`. Normal institution
tokens must never receive `platform_access`.

The gateway removes caller-supplied `X-Actor-Id`, `X-Institution-Id` and
`X-User-Id` headers. Services derive identity from the signed token. Clients must
put the institution in the URL and must not attempt to establish identity using
headers.

## 12. Obtaining and using tokens

### Client credentials

For an approved confidential client:

```bash
curl -sS -X POST \
  'http://localhost:9000/realms/cms/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials' \
  -d 'client_id=cms-machine-client' \
  -d 'client_secret=REPLACE_FROM_SECRET_STORE'
```

Use the returned access token:

```bash
curl -sS \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  'http://localhost:8080/cms/api/v2/institutions?status=ACTIVE'
```

### Swagger UI

1. Open the gateway Swagger UI.
2. Select the required service definition.
3. Click **Authorize**.
4. Paste the raw access-token value. Do not duplicate the `Bearer` prefix if the
   dialog already describes an HTTP bearer scheme.
5. Execute the operation. Confirm the generated URL uses the gateway origin and
   does not contain `/webjars`.

## 13. Status-code troubleshooting

### HTTP 401

Check, in order:

1. The request contains `Authorization: Bearer <token>`.
2. The token has not expired.
3. `iss` exactly matches the configured issuer.
4. `aud` contains `cms-api`.
5. The token signature key exists in the configured JWKS.
6. Keycloak and service clocks are synchronized.
7. The gateway forwarded the original Authorization header.

### HTTP 403

The token is valid but authorization failed. Check:

1. The required value is present in top-level `permissions`.
2. The claim contains `cms:...`, not `PERM_cms:...`.
3. `institution_id` matches the institution UUID in the URL.
4. `platform_access` is a boolean and is granted only when intended.
5. The endpoint-specific permission matches the matrix above.

### Swagger has no Authorize button

The selected OpenAPI document must contain both:

```yaml
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
security:
  - bearerAuth: []
```

Inspect the exact proxied document selected by Swagger, for example
`/docs/core/api-docs`, rather than only the service's grouped documentation.

### Gateway returns 500/502

This is normally routing, Redis, DNS, or downstream availability—not Keycloak
authorization. Verify the downstream URI and health before changing roles.

## 14. Production checklist

- Use HTTPS for Keycloak, the gateway, and all non-private token exchanges.
- Keep backend services private and accept ingress only from the gateway or
  explicitly authorized workloads.
- Use short-lived access tokens and documented refresh/session policies.
- Require MFA for privileged interactive roles.
- Rotate signing keys and client secrets with overlap and rollback procedures.
- Disable direct-access grants unless there is a reviewed legacy requirement.
- Disable `Full Scope Allowed`; assign explicit client scopes and roles.
- Restrict redirect URIs and CORS origins to exact production values.
- Audit changes to roles, composites, groups, protocol mappers and service
  accounts.
- Review `platform_access` assignments regularly.
- Test negative cases: missing token, wrong audience, wrong issuer, expired token,
  missing permission and cross-institution access.
- Do not log access tokens, client secrets, authorization headers or sensitive
  token claims.

