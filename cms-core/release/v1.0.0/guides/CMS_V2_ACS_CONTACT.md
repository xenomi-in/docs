---
published: false
layout: default
title: "CMS_V2_ACS_CONTACT"
---

# ACS cardholder contact lookup

`POST /cms/api/v2/acs/cardholder-contact` accepts a JSON body with `cardNumber` (12–19 digits, valid Luhn). It returns the standard success envelope with `data.mobile` and `data.email`. A missing channel is null; no available contact, unknown card or unknown range returns 404. Ambiguous institutions or PAN identities are rejected. The PAN is never echoed.

The caller must present a valid CMS bearer JWT with a subject listed in `cms.security.acs.allowed-subjects` (comma-separated), `platform_access: true`, and permission `cms:acs-contact:read`. Configure the allowlist to the identity provider's dedicated ACS service-account subject. Provision this permission only to that service account. Ordinary card-read/manage and platform access alone are insufficient. An empty allowlist denies all calls. Institution-only tokens cannot use this platform lookup.

This is a read-only POST. No Idempotency-Key is required and no idempotency response is stored. Successful responses use `Cache-Control: no-store`. Do not enable body logging at the gateway for this route.

Migration 038 adds nullable `registered_mobile`, `registered_email`, and `contact_updated_at` to `cms_v2.customer_reference`. Accounting is the source of these contacts; the transport/synchronization workflow is intentionally deferred pending the client agreement. Its eventual writer must update the correct institution-scoped customer and timestamp. No public contact-write API is introduced. Existing customers remain available for issuance; lookup returns 404 until contact data is populated.

Institution resolution uses full PAN intervals, including historical/closed ranges. The actual issued-card family is verified with effective PAN lookup HMAC identities, including legacy hashes and historical HMAC keys. Multiple same-PAN renewal/replacement rows must belong to one customer. This endpoint retrieves contact data; it does not authorize a payment or decide card eligibility.

Migration 038 also adds a PostgreSQL GiST exclusion constraint reserving non-overlapping PAN intervals across the platform, including six/eight-digit BIN prefix intersections. PAN lengths are treated separately. Closed ranges remain reserved because historical cards still need deterministic ownership. Existing overlaps must be resolved before migration; the migration does not delete/reassign data. Exact BIN uniqueness continues to be enforced by migration 034. Migration should be run through the existing V2 Liquibase changelog before deploying the new entity fields.
