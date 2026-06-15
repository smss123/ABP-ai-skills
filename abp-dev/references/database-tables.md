# ABP: Module Database Tables Reference

> 📖 Official docs: https://abp.io/docs/latest/modules/database-tables
>
> Fetch this page for a complete up-to-date list of all module tables.

---

## Table Prefix & Key Tables by Module

| Module | Prefix | Key Tables |
|---|---|---|
| **Audit Logging** | `Abp` | `AbpAuditLogs`, `AbpAuditLogActions`, `AbpEntityChanges`, `AbpEntityPropertyChanges` |
| **Background Jobs** | `Abp` | `AbpBackgroundJobs` |
| **Identity** | `Abp` | `AbpUsers`, `AbpRoles`, `AbpUserRoles`, `AbpUserClaims`, `AbpOrganizationUnits` |
| **Permission Management** | `Abp` | `AbpPermissions`, `AbpPermissionGroups`, `AbpPermissionGrants` |
| **OpenIddict** | `OpenIddict` | `OpenIddictApplications`, `OpenIddictAuthorizations`, `OpenIddictScopes`, `OpenIddictTokens` |
| **Tenant Management** | `Abp` | `AbpTenants`, `AbpTenantConnectionStrings` |
| **SaaS (Pro)** | `Saas` | `SaasTenants`, `SaasTenantConnectionStrings`, `SaasEditions` |
| **CMS Kit** | `Cms` | `CmsBlogs`, `CmsPages`, `CmsMenuItems`, `CmsTags`, `CmsRatings`, `CmsUserReactions` |
| **Blogging** | `Blg` | `BlgBlogs`, `BlgPosts`, `BlgComments`, `BlgTags`, `BlgPostTags`, `BlgUsers` |
| **Chat** | `Chat` | `ChatConversations`, `ChatMessages`, `ChatUserMessages`, `ChatUsers` |
| **Payment (Pro)** | `Pay` | `PayPaymentRequests`, `PayPlans`, `PayGatewayPlans` |

---

## Connection String Names

Each module uses a named connection string with a fallback to `Default`:

| Module | Connection String Name |
|---|---|
| Audit Logging | `AbpAuditLogging` |
| OpenIddict | `AbpOpenIddict` |
| CMS Kit | `CmsKit` |
| SaaS | `AbpSaas` |
| All others | `Default` |

To route a module to a dedicated database, add its named connection string to `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "Default":          "Server=...;Database=MainDb;...",
    "AbpAuditLogging":  "Server=...;Database=AuditDb;...",
    "AbpOpenIddict":    "Server=...;Database=AuthDb;..."
  }
}
```

---

## Table Prefix / Schema Customisation

Each module exposes a static `DbProperties` class. Override before migrations run:

```csharp
// Change prefix and schema for Audit Logging tables
AbpAuditLoggingDbProperties.DbTablePrefix = "App";
AbpAuditLoggingDbProperties.DbSchema = "audit";
// Results in: audit.AppAuditLogs, audit.AppAuditLogActions, ...
```

Set these in the `EntityFrameworkCore` project's static constructor or module `PreConfigureServices` — **before** `OnModelCreating` is called.

---

## Foreign Key & Tenancy Pattern

- Tenant-scoped tables carry a `TenantId` (`Guid?`) column — `NULL` = host record.
- Parent-child table relationships use `Id` columns (e.g. `AbpAuditLogs.Id` → `AbpAuditLogActions.AuditLogId`).
- No explicit SQL schema prefix by default — DBMS default (`dbo` on SQL Server).
