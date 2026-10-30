---
applies_to_abp: "9.x - 10.x"
doc_verified_on: "2026-10-29"
docs:
  - https://abp.io/docs/latest/framework/api-development/swagger
---

# ABP: OpenAPI / Swagger Generation

> 📖 Official docs (verified live against ABP 10.x):
> - Swagger: https://abp.io/docs/latest/framework/api-development/swagger
> - Auto API controllers: https://abp.io/docs/latest/framework/api-development/auto-controllers
> - Dynamic C# HTTP API clients: https://abp.io/docs/latest/framework/api-development/dynamic-csharp-clients

---

## Names you need

| Name | Purpose |
|---|---|
| `Volo.Abp.Swashbuckle` | the ABP package that wires Swashbuckle into the module system |
| `AbpSwashbuckleModule` | module to depend on (`[DependsOn(typeof(AbpSwashbuckleModule))]`) |
| `AddAbpSwaggerGen(...)` | replaces `AddSwaggerGen`, takes an `SwaggerGenOptions` configurator |
| `AddAbpSwaggerGenWithOAuth(...)` | adds the OAuth2 security definition (token endpoint, flows) |
| `AddAbpSwaggerGenWithOidc(...)` | OIDC variant, configured with authority + client id/secret |
| `AbpSwaggerOidcFlows` | `AuthorizationCode`, `Implicit`, `Password`, `ClientCredentials` |
| `UseAbpSwaggerUI(...)` | serves the UI; must follow `UseRouting`/`UseAuthentication` |
| `HideAbpEndpoints()` | removes ABP's own endpoints (`/api/abp/application-localization`, `/api/abp/application-configuration`, …) so the document shows only your API |
| `UserFriendlyEnums()` | renders enum values by their display name instead of the number |
| `CustomAbpSchemaIds()` | disambiguates same-named DTOs across namespaces |
| `/swagger/v1/swagger.json` | the generated document path |

```csharp
public override void ConfigureServices(ServiceConfigurationContext context)
{
    context.Services.AddAbpSwaggerGenWithOAuth(
        configuration["AuthServer:Authority"],
        new Dictionary<string, string>
        {
            { "MyApp", "MyApp API" }
        },
        options =>
        {
            options.SwaggerDoc("v1", new OpenApiInfo { Title = "MyApp API", Version = "v1" });
            options.DocInclusionPredicate((_, _) => true);
            options.CustomSchemaIds(type => type.FullName);
            options.HideAbpEndpoints();
        });
}

public override void OnApplicationInitialization(ApplicationInitializationContext context)
{
    app.UseSwagger();
    app.UseAbpSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "MyApp API");
    });
}
```
For an OpenIddict/auth-server setup the client id/secret come from `appsettings` (`AuthServer:ClientId`,
`AuthServer:ClientSecret`) and the scopes must match the ones registered in the OpenIddict application
(see `openiddict.md`).

---

## Rules

1. **Never expose Swagger UI in production** without a deliberate decision — the ABP deployment guide
   calls this out. Gate it (`if (env.IsDevelopment())`), or protect it behind an authorization
   requirement, and keep `/swagger` out of load-balancer-reachable paths in prod.
2. The document is generated from **application services + DTOs** through auto API controllers. If a
   DTO is missing from the document, the fix is the app service contract/`[RemoteService]` attributes,
   not a hand-written OpenAPI fragment.
3. `DocInclusionPredicate((_, _) => true)` (or assembly scanning) is required when controllers live in
   other assemblies/modules — otherwise module APIs silently vanish from the document.
4. Schema IDs: use `CustomAbpSchemaIds()` / `type.FullName` as soon as two modules define same-named
   DTOs, or generation throws an ambiguity error.
5. Versioning, `[Authorize]` requirements and error payload shapes (`AbpErrorModel`) belong to the API
   chapter — keep the Swagger config and the versioning config in the same module so they do not drift.
6. Consumers: Angular uses `abp generate-proxy -t ng`, .NET clients use `abp generate-proxy -t csharp`
   or the dynamic C# clients — all three read the **same** generated document, so a broken document
   breaks every proxy. Regenerate proxies after changing the API surface.

## Phase 0 notes

Check which of `AddAbpSwaggerGen` / `…WithOAuth` / `…WithOidc` the project already calls, and whether
`UseAbpSwaggerUI` sits inside an environment condition, before changing anything here.
