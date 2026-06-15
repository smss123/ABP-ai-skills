# ABP: Migrating from IdentityServer4 to OpenIddict

> 📖 Official docs: https://abp.io/docs/latest/release-info/migration-guides/openiddict-step-by-step
>
> Fetch this page for the latest step-by-step guidance before performing this migration.

---

## Overview

ABP v6.0 replaced IdentityServer4 with OpenIddict as the default auth server. This guide covers the backend migration. UI-specific steps (Angular, Blazor, MVC) require additional per-framework changes — see the official docs.

---

## 1. Package Replacements

Apply across all projects that reference IdentityServer packages:

| Layer | Remove | Add |
|---|---|---|
| Domain.Shared | `Volo.Abp.IdentityServer.Domain.Shared` | `Volo.Abp.OpenIddict.Domain.Shared` |
| Domain | `Volo.Abp.IdentityServer.Domain` | `Volo.Abp.OpenIddict.Domain` |
| Domain | `Volo.Abp.PermissionManagement.Domain.IdentityServer` | `Volo.Abp.PermissionManagement.Domain.OpenIddict` |
| EF Core | `Volo.Abp.IdentityServer.EntityFrameworkCore` | `Volo.Abp.OpenIddict.EntityFrameworkCore` |
| MongoDB | `Volo.Abp.IdentityServer.MongoDB` | `Volo.Abp.OpenIddict.MongoDB` |

Use the same version number (e.g. `6.0.*`) for all replacements.

---

## 2. Module `[DependsOn]` Changes

In each project's module class, swap the `[DependsOn]` entries to match:

| Layer | Remove | Add |
|---|---|---|
| Domain.Shared | `AbpIdentityServerDomainSharedModule` | `AbpOpenIddictDomainSharedModule` |
| Domain | `AbpIdentityServerDomainModule` | `AbpOpenIddictDomainModule` |
| Domain | `AbpPermissionManagementDomainIdentityServerModule` | `AbpPermissionManagementDomainOpenIddictModule` |
| EF Core | `AbpIdentityServerEntityFrameworkCoreModule` | `AbpOpenIddictEntityFrameworkCoreModule` |
| MongoDB | `AbpIdentityServerMongoDbModule` | `AbpOpenIddictMongoDbModule` |

---

## 3. DbContext — `OnModelCreating`

```csharp
// Remove:
builder.ConfigureIdentityServer();

// Add:
builder.ConfigureOpenIddict();
```

---

## 4. EF Core Migrations

Delete the existing `Migrations/` folder and regenerate:

```powershell
Add-Migration "OpenIddict_Initial"
```

Then run the `.DbMigrator` project to apply migrations to the database.

---

## 5. Seed Data — Replace Seed Contributor

1. Create an `OpenIddict/` folder in the **Domain** project.
2. Add `OpenIddictDataSeedContributor.cs` — copy the template from the ABP documentation or from a freshly generated v6+ project.
3. Delete the old `IdentityServer/` folder and its seed contributor.

---

## 6. DbMigrator Configuration (`appsettings.json`)

Replace IdentityServer client definitions with OpenIddict application entries:

```json
{
  "OpenIddict": {
    "Applications": {
      "MyApplication_Web": {
        "ClientId": "MyApplication_Web",
        "ClientSecret": "secret",
        "RootUrl": "https://localhost:44302"
      },
      "MyApplication_Swagger": {
        "ClientId": "MyApplication_Swagger",
        "RootUrl": "https://localhost:44302"
      }
    }
  }
}
```

---

## 7. Test Project Cleanup

In test module `PreConfigureServices`, remove:

```csharp
// Remove these:
using Volo.Abp.IdentityServer;

PreConfigure<AbpIdentityServerBuilderOptions>(options => { ... });
PreConfigure<IIdentityServerBuilder>(builder => { ... });
```

---

## 8. Ordered Migration Checklist

1. Run `abp update` to upgrade all packages to v6.0+
2. Replace NuGet packages (step 1)
3. Update `[DependsOn]` in all module classes (step 2)
4. Update `OnModelCreating` in DbContext (step 3)
5. Delete `Migrations/` folder and run `Add-Migration` (step 4)
6. Replace seed contributor class (step 5)
7. Update `.DbMigrator/appsettings.json` (step 6)
8. Clean test project configuration (step 7)
9. Follow UI-specific migration guide for your frontend (Angular / MVC / Blazor)

---

## Key Rules

- **DO** use identical package version numbers across all replaced packages
- **DO** delete the `Migrations/` folder before regenerating — old migrations reference IdentityServer tables
- **DO** update the `.DbMigrator/appsettings.json` — the old IdentityServer seed entries are not recognised by OpenIddict
- **DO** check for UI-specific migration steps in the official docs — the backend steps above are not sufficient for Angular or Blazor frontends
