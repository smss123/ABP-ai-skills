---
applies_to_abp: "9.x - 10.x"
doc_verified_on: "2026-10-29"
docs:
  - https://abp.io/docs/latest/modules/audit-logging
  - https://abp.io/docs/latest/framework/infrastructure/audit-logging
---

# ABP: Audit Logging & Security Logs

> 📖 Official docs (verified live against ABP 10.x):
> - Audit Logging **module** (storage + admin UI): https://abp.io/docs/latest/modules/audit-logging
> - Audit Logging **infrastructure** (the pipeline that produces the records):
>   https://abp.io/docs/latest/framework/infrastructure/audit-logging
> - Commercial **Audit Logging Pro** (Excel export, per-field diff views):
>   https://abp.io/docs/latest/modules/audit-logging-pro
>
> Two layers, one feature: the *infrastructure* intercepts calls and builds `AuditLogInfo`; the
> *module* persists it and exposes the UI. Configure both, name the right one.

---

## Infrastructure side (what gets recorded)

| Name | Purpose |
|---|---|
| `AbpAuditingOptions` | global switches: `IsEnabled`, `IsGlobalEnabled`, `ApplicationName`, `UserIdField`, `UserNameField`, comments |
| `IgnoredUrls`, `IgnoredControllerActions`, `IgnoredServices`, `IgnoredMethods` | keep health checks and read-only noise out of the log |
| `AlwaysLogOnException` | record failed calls even when otherwise filtered |
| `EntityHistoryOptions` / `EntityHistoryHelper` | property-level before/after snapshots of entity changes |
| `IAuditLogStore` (`DefaultAuditLogStore`) | sink that turns `AuditLogInfo` into a persisted record |
| `AuditLogInfo` | the in-memory model: application name, userId/userName, tenant, url, statusCode, execution duration, `Actions`, `ExtraProperties` |

Security logs are the same pipeline with `AuditingStore`-recorded **authenticated / signed-out / failed
login** events (`Identity` module emits them) — filter the module UI by event type rather than building
a second log.

## Module side (storage + UI)

| Name | Purpose |
|---|---|
| `Volo.Abp.AuditLogging` | the module package |
| `AuditLog` | aggregate root for one audit record |
| `AuditLogAction` | per-call entries inside an `AuditLog` |
| `EntityChange` / `EntityPropertyChange` | changed entity + changed property rows |
| `IAuditLogRepository` | custom repository used by the module |
| `IAuditLogInfoToAuditLogConverter` | converts `AuditLogInfo` → `AuditLog` |
| `AbpAuditLoggingDbProperties` | table prefix / db schema / connection string overrides |
| `AuditLogConsts`, `AuditLogActionConsts.MaxParametersLength` (2 000 default), `EntityChangeConsts`, `EntityPropertyChangeConsts` | truncation limits — raise them deliberately, they bound row size |

Tables: `AbpAuditLogs`, `AbpAuditLogActions`, `AbpEntityChanges`, `AbpEntityPropertyChanges`
(+ `AbpAuditLogExcelFiles` for the Pro package).

---

## Adding your own fields

```csharp
ObjectExtensionManager.Instance.Modules()
    .ConfigureAuditLogging(auditLogging =>
    {
        auditLogging.ConfigureAuditLog(auditLog =>
        {
            auditLog.AddOrUpdateProperty<string>("ExternalId");
        });
    });
```
Fill it from an auditing contributor so the value is present before conversion, not patched afterwards.

Configure the pipeline:

```csharp
Configure<AbpAuditingOptions>(options =>
{
    options.ApplicationName = "MyApp";
    options.IgnoredUrls.Add("/healthstatus");
    options.IgnoredServices.AddIfExists("Volo.Abp.AspNetCore.Mvc.UI.Widgets.IWidgetManager");
    options.AlwaysLogOnException = true;
});
```

---

## Rules

1. **Never log secrets.** Parameters, request bodies and `ExtraProperties` end up readable in the admin
   UI — put login/2FA/token endpoints in `IgnoredControllerActions` / `IgnoredUrls`, and scrub before
   persisting.
2. **Audit volume is a capacity decision.** Every write action costs rows in four tables; ignore read
   endpoints you don't need, and archive or partition `AbpAuditLogs` on any system with real traffic.
3. Permissions: the audit-log UI is for `AuditLogging.Audits` (check the project's actual
   `ABP audit log permission` group). Do not expose it to ordinary users.
4. Multi-tenant apps: records carry the tenant id; the UI filters per tenant, so don't add your own
   tenancy column.
5. Keep truncation limits coherent with what you compare — a `MaxParametersLength` change is a schema
   decision, so it needs a migration.
6. `EntityHistory` (before/after values) is separate from `AuditLog` rows; if the requirement is "who
   changed this field", turn on entity history for that entity type rather than parsing logs.

## Phase 0 notes

Check whether the module is already installed (`Volo.Abp.AuditLogging` in
`*.EntityFrameworkCore`/`*.HttpApi`), whether `AbpAuditingOptions` is already configured somewhere, and
which permission group guards the UI, before adding a second sink or a custom interceptor.
