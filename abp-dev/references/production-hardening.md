---
applies_to_abp: "9.x - 10.x"
doc_verified_on: "2026-10-29"
docs:
  - https://abp.io/docs/latest/deployment/configuring-production
  - https://abp.io/docs/latest/deployment
---

# ABP: Production Configuration Hardening

> 📖 Official docs (verified live against ABP 10.x):
> - Configuring for production: https://abp.io/docs/latest/deployment/configuring-production
> - Deployment overview: https://abp.io/docs/latest/deployment
> - SSL/HTTPS: https://abp.io/docs/latest/deployment/ssl
> - OpenIddict for production: https://abp.io/docs/latest/deployment/configuring-openiddict
> - Clustered environment: https://abp.io/docs/latest/deployment/clustered-environment
>
> The production page is short and concrete — read it, then read the clustered-environment page before
> any multi-instance deployment. Verify each option name against the current docs; ABP renames
> configuration keys between major versions.

---

## What ABP asks you to change before production

| Area | Setting | Why |
|---|---|---|
| Cache isolation | `AbpDistributedCacheOptions.KeyPrefix` | two applications sharing Redis must not read each other's cache entries |
| Lock isolation | `AbpDistributedLockOptions.KeyPrefix` | same reason for `IDistributedLock` names |
| String encryption | `AbpStringEncryptionOptions.DefaultPassPhrase` | the development passphrase must never reach production; changing it makes existing ciphertext unreadable |
| BLOB storage | provider switch (Database / File System / Azure / S3) | local disk paths and in-repo connection strings do not survive a container redeploy |
| Email | real SMTP settings | the default no-op/dev sender silently drops notifications |
| SMS | implement `ISmsSender` | same, for two-factor and alert flows |
| Logging | file → centralized (Elasticsearch, seq, DB) | the doc suggests replacing file-based logging; ephemeral containers lose local files |
| Swagger | disable or protect `/swagger` | the production page explicitly cautions against exposing it |

## The rest of the checklist (ASP.NET Core level, ABP-aware)

1. **Secrets**: user secrets in development, environment variables or a key vault in production. No
   connection strings, `AuthServer:ClientSecret` or passphrases committed to the repository — this is
   the failure mode `install.sh`-style boilerplate templates hit most often.
2. **Data protection keys**: with more than one instance, `PersistKeysToStackExchangeRedis(...)` (or
   Azure/DB persistence) is mandatory, otherwise every pod generates its own key ring and auth cookies
   break intermittently. Keys must not live in `Program.cs`-relative temp folders.
3. **Forwarded headers** behind a proxy/load balancer: `UseForwardedHeaders` +
   `KnownProxies`/`KnownNetworks`, or redirects, cookie `Secure` flags and client IPs are wrong.
4. **HTTPS**: `UseHttpsRedirection` + HSTS (`UseHsts`) after the certificate is valid; set
   `RequireHttpsMetadata=true` for the authority in production (it is frequently left off for local
   development — that must not ship).
5. **ASP.NET Core environment**: `ASPNETCORE_ENVIRONMENT=Production`, `ASPNETCORE_FORWARDEDHEADERS_ENABLED=true`
   on Linux hosts, and explicit `urls`/Kestrel bind + port rather than the launch profile.
6. **Database**: migrations through the `DbMigrator` project (or a release step), never
   `Database.Migrate()` at boot on multiple instances; enable connection resiliency (`EnableRetryOnFailure`)
   where the provider supports it.
7. **Background work in a cluster**: `AbpBackgroundWorkerOptions.IsEnabled`, unique queue prefixes and a
   distributed lock so only one instance runs each recurring worker (see `background-workers.md`).
8. **Error surface**: `Microsoft.AspNetCore.Diagnostics` developer exception page off; ABP's
   `AbpErrorModel` returns a correlation id — make sure the correlation id is logged (see
   `correlation-id.md`) so a user report maps to a server record.
9. **Compression & bundling**: `UseResponseCompression`, `abp bundle` output committed or generated at
   build, minification on.
10. **Module/permission surface**: the admin UIs (audit logging, tenant management, feature management,
    permission management) are permission-guarded — verify the production role assignments, and consider
    removing the administration UI routes from the public gateway entirely.
11. **Rate limiting / WAF**: ABP ships `AbpRateLimiting`-style options via ASP.NET Core
    `AddRateLimiter`; put it at the gateway for multi-service deployments.
12. **Observability**: health-check endpoint exposed to the orchestrator (`/healthstatus`) and kept out
    of audit logs and Swagger (see `audit-logging.md`, `openapi-swagger.md`).

## Phase 0 notes

Diff the target project's `appsettings.json` against `appsettings.Production.json` (and the deployment's
environment variables) before advising: most "production bugs" in ABP projects are a development value
that silently survived the copy. Never print or commit the real values — report the key names that are
missing or still at their development defaults, and let the user fill them in.
