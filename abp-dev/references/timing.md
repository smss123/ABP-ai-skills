# ABP: Timing & Clock

> 📖 Official docs: https://abp.io/docs/latest/framework/infrastructure/timing
>
> Fetch this page for the latest API details before generating time/timezone code.

---

## `IClock` — Always Use Instead of `DateTime.Now`

```csharp
public class MyService : ITransientDependency
{
    private readonly IClock _clock;

    public MyService(IClock clock)
    {
        _clock = clock;
    }

    public DateTime GetNow() => _clock.Now;          // respects configured Kind
    public bool IsUtc()      => _clock.Kind == DateTimeKind.Utc;
}
```

> **Never call `DateTime.Now` or `DateTime.UtcNow` directly** — use `IClock.Now` so behavior is consistent with the configured timezone strategy across the entire application.

`IClock` is also available as a base property on `ApplicationService`, `DomainService`, `AbpController`, and `AbpPageModel` — no injection needed in those classes.

---

## Configuration

```csharp
// Module ConfigureServices
Configure<AbpClockOptions>(options =>
{
    options.Kind = DateTimeKind.Utc;  // recommended for all multi-tenant / global apps
    // DateTimeKind.Local   — use server local time
    // DateTimeKind.Unspecified — default; effectively disables normalization
});
```

---

## DateTime Normalization

`IClock.Normalize(dateTime)` converts any `DateTime` to match the configured `Kind`:

```csharp
var normalized = _clock.Normalize(someDateTime);
// UTC system: converts Local/Unspecified → UTC via ToUniversalTime()
// Local system: converts UTC/Unspecified → Local via ToLocalTime()
```

ABP applies normalization **automatically** during:
- ASP.NET Core model binding
- EF Core read/write operations
- JSON deserialization

### Opt out of normalization

```csharp
[DisableDateTimeNormalization]
public class MyDto
{
    public DateTime CreatedAt { get; set; }           // normalized

    [DisableDateTimeNormalization]
    public DateTime ExternalTimestamp { get; set; }  // not normalized
}
```

---

## Multi-Timezone Support

Enable the timezone middleware to apply per-user/per-tenant timezone on every request:

```csharp
// In OnApplicationInitialization (before UseAuthorization)
app.UseAbpTimeZone();
```

Resolution order: **User timezone → Tenant timezone → App-level setting → Server default**

Anonymous requests can pass timezone via `__timezone` query string, header, or cookie.

### Convert times

```csharp
// UTC → user's configured timezone
var userLocalTime = _clock.ConvertToUserTime(utcDateTime);

// User's timezone → UTC
var utc = _clock.ConvertToUtc(userLocalTime);
```

### Setting the timezone (via ABP Settings)

The timezone setting key is `Abp.Timing.TimeZone`. Empty = server timezone. Set per-tenant or per-user through `ISettingManager`.

---

## Key Rules

- **DO** set `AbpClockOptions.Kind = DateTimeKind.Utc` in all production applications
- **DO** use `IClock.Now` instead of `DateTime.Now` / `DateTime.UtcNow`
- **DO** call `app.UseAbpTimeZone()` when your app has users in multiple timezones
- **DO NOT** store `DateTimeKind.Unspecified` values in the database — always normalize before saving
- **DO** use `[DisableDateTimeNormalization]` on DTO properties that represent external/third-party timestamps that must not be altered
