# ABP: JSON Serialization

> 📖 Official docs: https://abp.io/docs/latest/framework/infrastructure/json
>
> Fetch this page for the latest API details before generating JSON serialization code.

---

## `IJsonSerializer` — Provider-Agnostic Serialization

ABP wraps JSON libraries behind `IJsonSerializer` so application code stays library-independent.

```csharp
public class MyService : ITransientDependency
{
    private readonly IJsonSerializer _jsonSerializer;

    public MyService(IJsonSerializer jsonSerializer)
    {
        _jsonSerializer = jsonSerializer;
    }

    public string Serialize(MyDto dto)
        => _jsonSerializer.Serialize(dto, camelCase: true, indented: false);

    public MyDto Deserialize(string json)
        => _jsonSerializer.Deserialize<MyDto>(json);

    public object DeserializeToType(string json, Type targetType)
        => _jsonSerializer.Deserialize(targetType, json);
}
```

---

## Providers

ABP ships two implementations:

| Provider | Package | When to use |
|---|---|---|
| **System.Text.Json** (default) | `Volo.Abp.Json.SystemTextJson` | All new projects — faster, allocates less |
| **Newtonsoft.Json** | `Volo.Abp.Json.Newtonsoft` | Legacy projects or when Newtonsoft-specific features are needed |

### Switching to Newtonsoft.Json

```bash
abp add-package Volo.Abp.Json.Newtonsoft
```

```csharp
[DependsOn(typeof(AbpJsonNewtonsoftModule))]
public class MyAppModule : AbpModule { }
```

---

## Configuration

### Date formats (`AbpJsonOptions`)

```csharp
Configure<AbpJsonOptions>(options =>
{
    // Accept multiple input formats
    options.InputDateTimeFormats.Add("dd/MM/yyyy");
    options.InputDateTimeFormats.Add("MM-dd-yyyy");

    // Single canonical output format
    options.OutputDateTimeFormat = "yyyy-MM-dd";
});
```

### System.Text.Json options

```csharp
Configure<JsonSerializerOptions>(options =>
{
    options.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    options.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
});
```

### Newtonsoft.Json settings

```csharp
Configure<AbpNewtonsoftJsonSerializerOptions>(options =>
{
    options.JsonSerializerSettings.NullValueHandling = NullValueHandling.Ignore;
    options.JsonSerializerSettings.Formatting = Formatting.Indented;
});
```

---

## Critical Caveat

> **ABP's `IJsonSerializer` / `AbpJsonOptions` do NOT affect ASP.NET Core's HTTP JSON responses.**

ASP.NET Core uses its own `JsonOptions` / `MvcNewtonsoftJsonOptions`. Configure them separately:

```csharp
// In module ConfigureServices
context.Services.AddControllers()
    .AddJsonOptions(opts =>
    {
        opts.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    });
```

---

## Key Rules

- **DO** inject `IJsonSerializer` for application-internal serialization — avoids locking to a specific library
- **DO NOT** assume `AbpJsonOptions` date formats apply to API responses — configure `MvcJsonOptions` separately
- **DO** use System.Text.Json (default) for new projects; switch to Newtonsoft only when you have a specific dependency on it
