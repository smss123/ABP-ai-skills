# ABP: CMS Kit Module

> 📖 Official docs: https://abp.io/docs/latest/modules/cms-kit
>
> Fetch this page for the latest API details before generating CMS Kit code.

---

## Overview

CMS Kit is a pre-built module providing ready-to-use content management features. Each feature can be independently enabled — disabled features disappear entirely from the application and database.

UI support: **MVC/Razor Pages** (Blazor Server compatible). No Angular support.

---

## Available Features

| Feature | What it provides |
|---|---|
| **Pages** | Dynamic pages with dynamic URLs |
| **Blogging** | Multi-blog support with post publishing |
| **Tags** | Resource tagging for any entity type |
| **Comments** | Comment threads on any resource |
| **Reactions** | Emoji/reaction system for content |
| **Ratings** | Star-rating system for resources |
| **Menus** | Dynamic public menu management |
| **Global Resources** | Dynamic CSS/JS injection into pages |
| **Dynamic Widgets** | Custom widgets for pages and posts |
| **Marked Items** | Favorites / bookmarks / flags on resources |

---

## Packages

| Package | Purpose |
|---|---|
| `Volo.CmsKit.*` | Unified (admin + public) |
| `Volo.CmsKit.Admin.*` | Back-office management layer |
| `Volo.CmsKit.Public.*` | Public-facing frontend features |

---

## Enabling Features

Features use the Global Features system. Configure in a module's `PreConfigureServices` using `OneTimeRunner`:

```csharp
public override void PreConfigureServices(ServiceConfigurationContext context)
{
    // Enable all features
    GlobalFeatureManager.Instance.Modules.CmsKit(cmsKit =>
    {
        cmsKit.EnableAll();
    });

    // Or enable individually
    GlobalFeatureManager.Instance.Modules.CmsKit(cmsKit =>
    {
        cmsKit.Tags.Enable();
        cmsKit.Comments.Enable();
        cmsKit.Blogging.Enable();
        cmsKit.Pages.Enable();
        cmsKit.Ratings.Enable();
        cmsKit.Reactions.Enable();
        cmsKit.Menus.Enable();
        cmsKit.MarkedItems.Enable();
        cmsKit.GlobalResources.Enable();
    });
}
```

> Disabled features generate no database tables and expose no API endpoints. Enable only what you need.

---

## Database

- **Table prefix:** `Cms` (configurable via `CmsKitDbProperties`)
- **Connection string name:** `CmsKit` — falls back to `Default`

---

## Dependencies

- **BlobStoring module** — required for media/image uploads in blogs and pages
- **Distributed cache** — Redis recommended for production CMS workloads

---

## User Lookup in Distributed Architectures

CMS Kit uses `ICmsUserLookupService` to fetch user information for comments, ratings, and blog authorship. In microservice/tiered deployments, configure the remote Identity endpoint:

```json
{
  "RemoteServices": {
    "AbpIdentity": {
      "BaseUrl": "https://your-identity-service/"
    }
  }
}
```

---

## Extending Blog / BlogPost Entities

Use `ConfigureCmsKit()` in `OnModelCreating` to add custom properties — changes propagate to API and UI automatically via ABP's Object Extension system:

```csharp
// In Domain.Shared module
ObjectExtensionManager.Instance.Modules()
    .ConfigureCmsKit(cmsKit =>
    {
        cmsKit.ConfigureBlogPost(blogPost =>
        {
            blogPost.AddOrUpdateProperty<string>("FeaturedImageAlt");
        });
    });
```

---

## Key Rules

- **DO** enable only the features you need — unused features still register routes and DI services even if their tables are absent
- **DO** configure `BlobStoring` before enabling Blogging or Pages with media upload
- **DO** use Redis (not in-memory cache) in production for CMS content caching
- **DO NOT** use CMS Kit with Angular UI — only MVC/Razor Pages is supported
