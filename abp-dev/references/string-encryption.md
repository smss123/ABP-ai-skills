# ABP: String Encryption

> 📖 Official docs: https://abp.io/docs/latest/framework/infrastructure/string-encryption
>
> Fetch this page for the latest API details before generating encryption code.

---

## `IStringEncryptionService`

ABP's built-in AES encryption service for encrypting/decrypting arbitrary strings.

```csharp
public class MyService : ITransientDependency
{
    private readonly IStringEncryptionService _encryptionService;

    public MyService(IStringEncryptionService encryptionService)
    {
        _encryptionService = encryptionService;
    }

    public string StoreApiKey(string rawKey)
        => _encryptionService.Encrypt(rawKey);

    public string ReadApiKey(string encryptedKey)
        => _encryptionService.Decrypt(encryptedKey);
}
```

---

## Custom Passphrase / Salt

Pass overrides per-call when you need different keys for different data:

```csharp
var encrypted = _encryptionService.Encrypt(value,
    passPhrase: "MyCustomPassPhrase",
    salt: Encoding.UTF8.GetBytes("MyCustomSalt"));

var decrypted = _encryptionService.Decrypt(value,
    passPhrase: "MyCustomPassPhrase",
    salt: Encoding.UTF8.GetBytes("MyCustomSalt"));
```

> **Encrypt and decrypt must use identical parameters.** Mismatched passphrase/salt = decryption failure.

---

## Global Configuration (`AbpStringEncryptionOptions`)

Set production defaults in module `ConfigureServices` (never hard-code in `appsettings.json`):

```csharp
Configure<AbpStringEncryptionOptions>(options =>
{
    options.DefaultPassPhrase = "change-this-strong-passphrase";
    options.DefaultSalt       = Encoding.UTF8.GetBytes("change-this-salt");
    options.InitVectorBytes   = Encoding.UTF8.GetBytes("16-byte-iv-value");
    options.Keysize           = 256;  // 128, 192, or 256
});
```

| Property | Default | Notes |
|---|---|---|
| `DefaultPassPhrase` | `gsKnGZ041HLL4IM8` | **Change in production** |
| `DefaultSalt` | ASCII `hgt!16kl` | **Change in production** |
| `InitVectorBytes` | ASCII `jkE49230Tf093b42` | Must be exactly `Keysize / 8` bytes |
| `Keysize` | `256` | AES key length in bits |

---

## Used by: Encrypted Settings

The `isEncrypted: true` flag on a `SettingDefinition` calls `IStringEncryptionService` automatically — no manual encryption code needed. See `abp-dev/references/settings.md` §5.

---

## Key Rules

- **DO** change all default values (`DefaultPassPhrase`, `DefaultSalt`, `InitVectorBytes`) before production deployment
- **DO** store the passphrase in environment variables or Azure Key Vault — never in source control
- **DO NOT** mix passphrases/salts between encrypt and decrypt calls — they must match exactly
- **DO** use `isEncrypted: true` on `SettingDefinition` for settings-based secrets — avoids manual encrypt/decrypt
