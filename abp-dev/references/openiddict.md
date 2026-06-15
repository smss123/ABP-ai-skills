# ABP: OpenIddict Module

> 📖 Official docs:
> - Module overview: https://abp.io/docs/latest/modules/openiddict
> - Production setup: https://abp.io/docs/latest/deployment/configuring-openiddict
>
> Fetch these pages for the latest API details before generating auth server code.

---

## Overview

ABP's OpenIddict module wraps the raw OpenIddict library and adds ABP-specific integration: database persistence for applications/scopes/tokens, seed data, multi-tenant support, and custom claims handling. It provides SSO, single log-out, and API access control via OAuth 2.0 / OpenID Connect.

---

## Domain Aggregates

| Aggregate | Purpose |
|---|---|
| `OpenIddictApplication` | Client apps requesting tokens — stores ClientId, secret, redirect URIs, consent type |
| `OpenIddictAuthorization` | Tracks allowed scopes and grant types per user/application |
| `OpenIddictScope` | Defines API resource scopes with descriptions and associated resources |
| `OpenIddictToken` | Persists issued tokens with creation/expiration dates, payload, and status |

Custom repositories: `IOpenIddictApplicationRepository`, `IOpenIddictAuthorizationRepository`, `IOpenIddictScopeRepository`, `IOpenIddictTokenRepository`.

---

## OAuth 2.0 / OIDC Endpoints

Built-in controllers expose standard endpoints:

| Endpoint | Purpose |
|---|---|
| `/connect/authorize` | Authorization code flow |
| `/connect/token` | Token issuance |
| `/connect/logout` | Single log-out |
| `/connect/userinfo` | User claims |

---

## Configuration in Module

```csharp
public override void PreConfigureServices(ServiceConfigurationContext context)
{
    PreConfigure<OpenIddictServerBuilder>(builder =>
    {
        // Token lifetimes
        builder.SetAuthorizationCodeLifetime(TimeSpan.FromMinutes(5));
        builder.SetAccessTokenLifetime(TimeSpan.FromHours(1));
        builder.SetIdentityTokenLifetime(TimeSpan.FromHours(1));
        builder.SetRefreshTokenLifetime(TimeSpan.FromDays(14));

        // Require PKCE for public clients
        builder.RequireProofKeyForCodeExchange();
    });

    PreConfigure<AbpOpenIddictAspNetCoreOptions>(options =>
    {
        options.AddDevelopmentEncryptionAndSigningCertificate = false; // prod: use real certs
    });
}
```

---

## Seed Data — Registering Client Applications

Define client applications in `.DbMigrator/appsettings.json`:

```json
{
  "OpenIddict": {
    "Applications": {
      "MyApp_Web": {
        "ClientId": "MyApp_Web",
        "ClientSecret": "secret",
        "RootUrl": "https://localhost:44302"
      },
      "MyApp_Swagger": {
        "ClientId": "MyApp_Swagger",
        "RootUrl": "https://localhost:44302"
      },
      "MyApp_Mobile": {
        "ClientId": "MyApp_Mobile",
        "RootUrl": "myapp://callback"
      }
    }
  }
}
```

The `OpenIddictDataSeedContributor` reads this configuration and creates/updates application entries on each `.DbMigrator` run.

---

## Custom Claims (`IAbpOpenIddictClaimsPrincipalHandler`)

Control which claims go into access tokens vs. identity tokens:

```csharp
public class MyClaimsHandler : IAbpOpenIddictClaimsPrincipalHandler, ITransientDependency
{
    public Task HandleAsync(AbpOpenIddictClaimsPrincipalHandlerContext context)
    {
        var principal = context.Principal;

        // Add a custom claim to the access token only
        var identity = principal.Identities.First();
        identity.AddClaim(new Claim("department", "Finance")
            .SetDestinations(OpenIddictConstants.Destinations.AccessToken));

        return Task.CompletedTask;
    }
}
```

**Default destinations:** `Name`, `Email`, `Role` → both access token and identity token. All other claims → access token only.

---

## Token Cleanup

Expired tokens and authorizations are pruned automatically:

```csharp
Configure<TokenCleanupOptions>(options =>
{
    options.CleanupPeriod = 3_600_000;     // ms — default 1 hour
    options.MinimumTokenLifespan = TimeSpan.FromDays(14);
    options.DisableTokenPruning = false;
    options.DisableAuthorizationPruning = false;
});
```

---

## Refresh Tokens

Applications must explicitly request the `offline_access` scope and the `refresh_token` grant type:

```json
{
  "OpenIddict": {
    "Applications": {
      "MyApp_Web": {
        "ClientId": "MyApp_Web",
        "Scopes": ["openid", "profile", "offline_access", "MyApp"],
        "GrantTypes": ["authorization_code", "refresh_token"]
      }
    }
  }
}
```

---

## Database

- **Connection string name:** `AbpOpenIddict` — falls back to `Default`
- **EF Core tables:** `OpenIddictApplications`, `OpenIddictAuthorizations`, `OpenIddictScopes`, `OpenIddictTokens`
- **MongoDB:** equivalent collections

---

## Key Rules

- **DO** use real signing/encryption certificates in production — never `AddDevelopmentEncryptionAndSigningCertificate` on live servers
- **DO** define all client applications via seed data in `.DbMigrator/appsettings.json` — not hardcoded in module code
- **DO** implement `IAbpOpenIddictClaimsPrincipalHandler` to propagate custom claims (e.g. `TenantId`, `department`) into tokens
- **DO** configure `SetRefreshTokenLifetime` and include `offline_access` scope for mobile/SPA clients that need refresh tokens
- **DO NOT** expose the `/connect/token` endpoint on a public network without HTTPS — tokens in transit must be encrypted
