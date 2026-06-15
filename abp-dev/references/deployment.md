# ABP: Deployment

> 📖 Official docs:
> - SSL/HTTPS: https://abp.io/docs/latest/deployment/ssl
> - OpenIddict (Auth Server): https://abp.io/docs/latest/deployment/configuring-openiddict
> - Production Configuration: https://abp.io/docs/latest/deployment/configuring-production
> - Clustered Environment: https://abp.io/docs/latest/deployment/clustered-environment
>
> Fetch these pages for the latest deployment details before generating production configuration code.

---

## SSL / HTTPS

### Obtain a Certificate

Use a Certificate Authority (CA) — Let's Encrypt (free) is recommended:

```bash
# acme.sh via Cloudflare DNS
export CF_Token="your-cloudflare-api-token"
acme.sh --issue --dns dns_cf -d yourdomain.com
```

For IIS, convert the certificate to PFX:

```bash
openssl pkcs12 -export -in cert.cer -inkey cert.key -out cert.pfx
```

### Enforce HTTPS in ASP.NET Core

```csharp
// In OnApplicationInitialization
app.UseHsts();
app.UseHttpsRedirection();
```

### Common SSL Errors

| Error | Cause | Fix |
|---|---|---|
| `RemoteCertificateNameMismatch` | Domain mismatch or self-signed cert | Use a valid cert for the domain |
| `UntrustedRoot` | Cert chain not trusted by client | Install intermediate CA certificates |

---

## OpenIddict (Auth Server) Production Setup

### Development environment (default)

ABP auto-generates temporary signing/encryption certificates — **not suitable for production**.

### Production: use a real PFX certificate

```bash
# Generate a certificate (or use one from your CA)
dotnet dev-certs https -v -ep openiddict.pfx -p your-password
```

Place `openiddict.pfx` in the Auth Server project's content root, then configure:

```csharp
// AuthServer module PreConfigureServices
PreConfigure<OpenIddictServerBuilder>(serverBuilder =>
{
    serverBuilder.AddProductionEncryptionAndSigningCertificate(
        "openiddict.pfx",
        "your-password",
        X509KeyStorageFlags.MachineKeySet | X509KeyStorageFlags.EphemeralKeySet
    );
});
```

Disable the development certificate first:

```csharp
PreConfigure<AbpOpenIddictAspNetCoreOptions>(options =>
{
    options.AddDevelopmentEncryptionAndSigningCertificate = false;
});
```

> Use separate RSA certificates for encryption and signing in high-security scenarios.

---

## Production Configuration Checklist

### Distributed Cache Prefix (required when sharing cache servers)

```csharp
Configure<AbpDistributedCacheOptions>(options =>
{
    options.KeyPrefix = "MyCrmApp"; // isolates keys from other apps on same Redis
});
```

### Distributed Lock Prefix

```csharp
Configure<AbpDistributedLockOptions>(options =>
{
    options.KeyPrefix = "MyCrmApp";
});
```

### String Encryption Passphrase

```csharp
Configure<AbpStringEncryptionOptions>(options =>
{
    options.DefaultPassPhrase = "change-this-to-a-strong-random-value";
});
```

> Store secrets in environment variables or a secrets manager — **never** hard-code in `appsettings.json`.

### Email Sender

ABP logs emails to the console in development. Configure a real provider for production:

```json
// appsettings.Production.json
{
  "Settings": {
    "Abp.Mailing.Smtp.Host": "smtp.sendgrid.net",
    "Abp.Mailing.Smtp.Port": "587",
    "Abp.Mailing.Smtp.UserName": "apikey",
    "Abp.Mailing.Smtp.Password": "your-sendgrid-api-key",
    "Abp.Mailing.Smtp.EnableSsl": "true",
    "Abp.Mailing.DefaultFromAddress": "noreply@yourapp.com",
    "Abp.Mailing.DefaultFromDisplayName": "Your App"
  }
}
```

### BLOB Storage

The default **file system provider** is unsuitable for Docker/clustered deployments. Use:

- **Database provider** (easiest, pre-installed in templates): `Volo.Abp.BlobStoring.Database`
- **Azure Blob Storage**: `Volo.Abp.BlobStoring.Azure`
- **AWS S3**: `Volo.Abp.BlobStoring.Aws`

### Swagger in Production

Disable Swagger UI in production or restrict access:

```csharp
if (env.IsDevelopment())
{
    app.UseAbpSwaggerUI(); // only in dev
}
```

---

## Clustered / Multi-Instance Deployment

### Redis Distributed Cache (required for clustering)

```bash
abp add-package Volo.Abp.Caching.StackExchangeRedis
```

```csharp
[DependsOn(typeof(AbpCachingStackExchangeRedisModule))]
public class BookStoreWebModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        Configure<RedisCacheOptions>(options =>
        {
            options.Configuration = configuration["Redis:Configuration"];
        });
    }
}
```

```json
{
  "Redis": {
    "Configuration": "localhost:6379"
  }
}
```

### Distributed Locking

The default in-process lock does not work across multiple instances. Add a real provider:

```bash
abp add-package Volo.Abp.DistributedLocking
```

Configure with Redis or another DistributedLock-compatible backend in `ConfigureServices`.

### SignalR Scale-Out

SignalR requires sticky sessions **or** a backplane when running on multiple servers:

```csharp
// Option A: Azure SignalR Service
builder.Services.AddSignalR().AddAzureSignalR(configuration["Azure:SignalR:ConnectionString"]);

// Option B: Redis backplane
builder.Services.AddSignalR().AddStackExchangeRedis(configuration["Redis:Configuration"]);
```

### Background Jobs in a Cluster

Choose one strategy:

| Strategy | How |
|---|---|
| Dedicated worker process | Deploy a separate console app with `IsJobExecutionEnabled = true`; set `false` on web nodes |
| External provider | Use Hangfire or Quartz — both have native clustering support |
| Distributed lock isolation | Use `ApplicationName` to partition job queues per instance |

```csharp
// Disable job execution on web nodes
Configure<AbpBackgroundJobOptions>(options =>
{
    options.IsJobExecutionEnabled = false;
});
```

### Background Workers in a Cluster

Workers run on all instances by default — leads to duplicate execution. Solutions:

1. Run workers only on a dedicated instance (set `AbpBackgroundWorkerOptions.IsEnabled = false` on others)
2. Guard work with a distributed lock inside `DoWorkAsync`
3. Deploy a dedicated worker service application

### Stateless Design Rules

- **DO NOT** store user/request state in static fields or singleton memory
- **DO** use distributed cache (`IDistributedCache`) for shared ephemeral state
- **DO** use distributed locks for coordinated operations across nodes
- **DO** use a cloud/database BLOB provider (never file system in clusters)
- **DO** configure Redis for both cache and SignalR backplane

---

## Forwarded Headers (Reverse Proxy)

When running behind Nginx, Apache, or a load balancer, ASP.NET Core needs to know the original client IP and protocol.

### Configure in module

```csharp
// Web/HttpApi module ConfigureServices
context.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders =
        ForwardedHeaders.XForwardedFor |
        ForwardedHeaders.XForwardedProto;

    // Trust your proxy server IPs (restrict to known proxies in production)
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});
```

### Register middleware (must be first, before UseHsts)

```csharp
public override void OnApplicationInitialization(ApplicationInitializationContext context)
{
    var app = context.GetApplicationBuilder();

    app.UseForwardedHeaders();  // FIRST — before any other middleware
    app.UseHsts();
    app.UseHttpsRedirection();
    // ...
}
```

| Header | Purpose |
|---|---|
| `X-Forwarded-For` | Original client IP address |
| `X-Forwarded-Proto` | Original protocol (http/https) |
| `X-Forwarded-Host` | Original hostname |
| `X-Forwarded-Port` | Original port |

---

## Production Performance Optimization

### Static asset caching

ABP's bundling system automatically adds a content-hash query string to CSS/JS bundles in production — browsers cache efficiently:

```
/bundles/global.min.css?v=a1b2c3d4
```

No manual versioning needed. ABP handles it when you run `abp bundle`.

### Enable bundling & minification in production

ABP automatically enables bundling in non-Development environments. Verify in your module:

```csharp
Configure<AbpBundlingOptions>(options =>
{
    options.Mode = BundlingMode.Bundle; // explicit if needed
    // BundlingMode.BundleAndMinify is default in Production
});
```

### Response compression

Add ASP.NET Core's built-in compression before ABP middleware:

```csharp
// ConfigureServices
context.Services.AddResponseCompression(opts =>
{
    opts.EnableForHttps = true;
    opts.Providers.Add<GzipCompressionProvider>();
    opts.Providers.Add<BrotliCompressionProvider>();
});

// OnApplicationInitialization (before UseStaticFiles)
app.UseResponseCompression();
```

### Background job performance

For high job volumes, switch from the default in-process manager to Hangfire:

```bash
abp add-package Volo.Abp.BackgroundJobs.HangFire
```

No application code changes required — just swap the module dependency.

---

## Key Rules

- **DO** set `KeyPrefix` on cache and lock options when multiple apps share infrastructure
- **DO** use production OpenIddict certificates — development certs fail on IIS/Azure App Service
- **DO** store all secrets in environment variables or Azure Key Vault
- **DO NOT** use the file system BLOB provider in containerized or multi-node deployments
- **DO NOT** enable Swagger UI in production without access controls
