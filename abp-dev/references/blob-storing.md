---
applies_to_abp: "9.x - 10.x"
doc_verified_on: "2026-10-29"
docs:
  - https://abp.io/docs/latest/framework/infrastructure/blob-storing
---

# ABP: Blob Storing

> 📖 Official docs (verified live against ABP 10.x):
> - Blob storing: https://abp.io/docs/latest/framework/infrastructure/blob-storing
>
> The provider chapters (Azure / AWS-S3 / Minio / Google / Aliyun / Bunny / Database / File System /
> Memory) are sub-pages of the same URL — fetch it for the provider's exact option names before
> configuring one.

ABP's abstraction over object storage: your code depends on `IBlobContainer`, the provider (files,
database, Azure, S3-compatible, GCS, …) is a configuration decision.

```bash
abp add-package Volo.Abp.BlobStoring
```

---

## Core API

| Name | Purpose |
|---|---|
| `IBlobContainer` | default container: save/read/delete BLOBs |
| `IBlobContainer<T>` | typed container, so each storage unit gets its own configuration |
| `IBlobContainerFactory` | create a container by name (`Create("profile-pictures")`) or type |
| `IBlobProviderSelector` | resolves the provider for a container name |
| `IBlobProvider` | implemented by a storage backend |
| `IBlobContainerConfigurationProvider` | supplies per-container configuration |
| `AbpBlobStoringOptions` | configure containers in `ConfigureServices` |
| `AbpBlobStoringEncryptionOptions` / `DefaultPassPhrase` | at-rest encryption key derivation |
| `[BlobContainerName("name")]` | stable name for a typed container |

Methods: `SaveAsync(name, streamOrBytes)`, `GetAsync(name)` (throws when missing, returns a disposable
`Stream`), `GetOrNullAsync(name)`, `GetAllBytesAsync(name)`, `GetAllBytesOrNullAsync(name)`,
`DeleteAsync(name)` (returns `bool`, never throws), `ExistsAsync(name)`.

```csharp
public class ProfileAppService : ApplicationService
{
    private readonly IBlobContainer<ProfilePictureContainer> _blobContainer;

    public ProfileAppService(IBlobContainer<ProfilePictureContainer> blobContainer)
        => _blobContainer = blobContainer;

    public async Task SaveAsync(byte[] bytes)
        => await _blobContainer.SaveAsync("current", bytes, overrideExisting: true);

    public async Task<byte[]> GetAsync()
        => await _blobContainer.GetAllBytesOrNullAsync("current") ?? Array.Empty<byte>();
}
```

## Configuration

```csharp
Configure<AbpBlobStoringOptions>(options =>
{
    options.Containers.Configure<ProfilePictureContainer>(container =>
    {
        container.UseAzure(azure =>
        {
            azure.ConnectionString = configuration["AzureFiles:ConnectionString"];
            azure.ContainerName = configuration["AzureFiles:ContainerName"];
            azure.CreateContainerIfNotExists = true;
        });
        // container.IsMultiTenant = false;  // share blobs across tenants
        // container.UseEncryption();        // transparent at-rest encryption
        // container.PipelineContributors.Add(new GzipPipelineContributor());
    });
});
```

Providers available out of the box: **File System**, **Database**, **Azure**, **Aws** (S3 and
S3-compatible — `ServiceURL` points at MinIO/Cloudflare R2, `DisablePayloadSigning` for endpoints that
reject chunked signing), **Minio**, **Google**, **Aliyun**, **Bunny**, **Memory** (tests).

---

## Rules

1. **Never store a BLOB in a database column by hand** when `container.UseDatabase()` (or the File
   System provider) already does it with the same interface.
2. **BLOB names are not entity ids.** Reference stored content from the entity by a stable name or a
   metadata row; the entity stays the source of truth, the container is storage.
3. Multi-tenancy is on by default for containers — set `container.IsMultiTenant = false` deliberately,
   never accidentally.
4. Encryption passphrases come from configuration/secrets, not source. Changing `DefaultPassPhrase`
   makes existing encrypted BLOBs unreadable.
5. Stream disposal is your job: `await using var stream = await container.GetAsync(name)`.
6. In tests use the **Memory** provider — no emulator, no files, and behaviour matches the interface.
7. Provider secrets belong in user secrets / environment variables, never in `appsettings.json`
   committed to the repo.

## Phase 0 notes

Check whether the project already has a typed container (`IBlobContainer<TX>`) and a provider
configured before adding a second one; extend the existing configuration row instead.
