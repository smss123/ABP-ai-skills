# ABP: UI Theming & Customization

> 📖 Official docs:
> - UI Themes Overview: https://abp.io/docs/latest/ui-themes
> - MVC/Razor Pages Theming: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/theming
> - LeptonX Theme: https://abp.io/docs/latest/ui-themes/lepton-x
> - Basic Theme: https://abp.io/docs/latest/ui-themes/basic-theme
>
> Fetch these pages for the latest API details before generating theme or layout code.

---

## Available Themes

| Theme | Package | Notes |
|---|---|---|
| **LeptonX** (commercial) | `Volo.Abp.AspNetCore.Mvc.UI.Theme.LeptonX` | Default for new solutions; modern, full-featured |
| **LeptonX Lite** (free) | `Volo.Abp.AspNetCore.Mvc.UI.Theme.LeptonXLite` | Free version of LeptonX |
| **Basic** | `Volo.Abp.AspNetCore.Mvc.UI.Theme.Basic` | Minimal Bootstrap — ideal as a custom theme base |

---

## Theme Architecture

Every theme implements `ITheme` and maps layout names to Razor view paths.

```csharp
[ThemeName("MyTheme")]
public class MyTheme : ITheme, ITransientDependency
{
    public const string Name = "MyTheme";

    public virtual string GetLayout(string name, bool fallbackToDefault = true)
    {
        return name switch
        {
            StandardLayouts.Application => "~/Themes/MyTheme/Layouts/Application.cshtml",
            StandardLayouts.Account     => "~/Themes/MyTheme/Layouts/Account.cshtml",
            StandardLayouts.Empty       => "~/Themes/MyTheme/Layouts/Empty.cshtml",
            _ => fallbackToDefault
                    ? "~/Themes/MyTheme/Layouts/Application.cshtml"
                    : null
        };
    }
}
```

---

## Registering a Theme

```csharp
Configure<AbpThemingOptions>(options =>
{
    options.Themes.Add<MyTheme>();
    options.DefaultThemeName = MyTheme.Name; // set as active theme
});
```

---

## Theme Folder Structure

```
src/Acme.BookStore.Web/
└── Themes/
    └── MyTheme/
        ├── Layouts/
        │   ├── Application.cshtml   ← main app pages
        │   ├── Account.cshtml       ← login / register
        │   └── Empty.cshtml         ← minimal, no chrome
        ├── Components/
        │   ├── Menu/
        │   │   └── Default.cshtml
        │   ├── Toolbar/
        │   │   └── Default.cshtml
        │   └── Brand/
        │       └── Default.cshtml
        ├── wwwroot/
        │   ├── themes/mytheme/
        │   │   ├── layout.css
        │   │   └── layout.js
```

---

## Required Layout Sections (Application.cshtml template)

```html
@using Volo.Abp.AspNetCore.Mvc.UI.Layout
@inject IPageLayout PageLayout

<!DOCTYPE html>
<html lang="@CultureInfo.CurrentUICulture.Name"
      dir="@(CultureInfo.CurrentUICulture.TextInfo.IsRightToLeft ? "rtl" : "ltr")">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@(PageLayout.Content.Title != null ? PageLayout.Content.Title + " | " : "")@BrandingProvider.AppName</title>

    @await Component.InvokeLayoutHookAsync(LayoutHooks.Head.First, StandardLayouts.Application)

    <abp-style-bundle name="@MyThemeBundles.Styles.Global" />

    @await Component.InvokeAsync(typeof(WidgetStylesViewComponent))
    @await RenderSectionAsync("styles", required: false)

    @await Component.InvokeLayoutHookAsync(LayoutHooks.Head.Last, StandardLayouts.Application)
</head>
<body class="abp-application-layout">

    @await Component.InvokeLayoutHookAsync(LayoutHooks.Body.First, StandardLayouts.Application)

    @* Navigation / sidebar *@
    @await Component.InvokeAsync(typeof(MainNavbarMenuViewComponent))

    @* Toolbar (user menu, language switcher, etc.) *@
    @await Component.InvokeAsync(typeof(MainNavbarToolbarViewComponent))

    @* Alerts *@
    @await Component.InvokeAsync(typeof(AlertsViewComponent))

    @* Page content *@
    <div id="AbpContentToolbar">
        @RenderSection("content_toolbar", false)
    </div>
    @RenderBody()

    @await Component.InvokeLayoutHookAsync(LayoutHooks.Body.Last, StandardLayouts.Application)

    @* ABP required scripts *@
    <script src="~/Abp/ApplicationConfigurationScript"></script>
    <script src="~/Abp/ServiceProxyScript"></script>

    <abp-script-bundle name="@MyThemeBundles.Scripts.Global" />
    @await Component.InvokeAsync(typeof(WidgetScriptsViewComponent))
    @await RenderSectionAsync("scripts", required: false)

</body>
</html>
```

---

## Bundling Configuration

```csharp
public class MyThemeBundles
{
    public static class Styles
    {
        public const string Global = "MyTheme.Global";
    }
    public static class Scripts
    {
        public const string Global = "MyTheme.Global";
    }
}
```

```csharp
Configure<AbpBundlingOptions>(options =>
{
    options.StyleBundles.Add(MyThemeBundles.Styles.Global, bundle =>
    {
        bundle
            .AddBaseBundles(StandardBundles.Styles.Global) // inherit ABP base styles
            .AddContributors(typeof(MyThemeGlobalStyleContributor));
    });

    options.ScriptBundles.Add(MyThemeBundles.Scripts.Global, bundle =>
    {
        bundle
            .AddBaseBundles(StandardBundles.Scripts.Global)
            .AddContributors(typeof(MyThemeGlobalScriptContributor));
    });
});

// Contributor
public class MyThemeGlobalStyleContributor : BundleContributor
{
    public override void ConfigureBundle(BundleConfigurationContext context)
    {
        context.Files.Add("/themes/mytheme/layout.css");
    }
}
```

---

## Branding (App Name & Logo)

```csharp
// Web/MyThemeBrandingProvider.cs
[Dependency(ReplaceServices = true)]
public class MyThemeBrandingProvider : DefaultBrandingProvider
{
    public override string AppName => "My Application";
    public override string LogoUrl => "/themes/mytheme/images/logo.png";
    public override string LogoReverseUrl => "/themes/mytheme/images/logo-white.png";
}
```

---

## How to Change the Active Theme

### Option A — Switch the registered default

In your Web module:

```csharp
Configure<AbpThemingOptions>(options =>
{
    options.DefaultThemeName = LeptonXLiteTheme.Name; // or BasicTheme.Name
});
```

### Option B — Add the Basic Theme with source code for full customization

```bash
abp add-package Volo.Abp.AspNetCore.Mvc.UI.Theme.Basic \
    --with-source-code \
    --add-to-solution-file
```

This copies the full Basic theme source into `src/Acme.BookStore.Web/Themes/Basic/`. Edit layout files, CSS, and components directly.

### Option C — Create a brand-new theme from scratch

1. Create folder `src/Acme.BookStore.Web/Themes/MyTheme/`
2. Implement `ITheme` (see above)
3. Create `Application.cshtml`, `Account.cshtml`, `Empty.cshtml` under `Layouts/`
4. Configure bundling and register via `AbpThemingOptions`

---

## Customizing Layouts Without Creating a Full Theme

### Add CSS/JS to existing theme bundles

```csharp
Configure<AbpBundlingOptions>(options =>
{
    options.StyleBundles.Configure(
        StandardBundles.Styles.Global,
        bundle => bundle.AddFiles("/styles/my-overrides.css")
    );
});
```

### Override individual layout files (Virtual File System)

Replace any theme file by placing a file at the **same virtual path** in your Web project:

```
// Original theme file (in NuGet package):
/Themes/LeptonXLite/Layouts/Application.cshtml

// Your override (in Web project — same path wins):
src/Acme.BookStore.Web/Themes/LeptonXLite/Layouts/Application.cshtml
```

ABP's Virtual File System gives physical files priority over embedded resources.

### Use Layout Hooks to inject content without editing layouts

```csharp
// In a view component or tag helper contributor
Configure<AbpLayoutHookOptions>(options =>
{
    options.Add(
        LayoutHooks.Body.Last,   // injection point
        typeof(MyFooterViewComponent)
    );
});
```

---

## RTL Support

```html
<!-- In Application.cshtml <html> tag -->
<html dir="@(CultureInfo.CurrentUICulture.TextInfo.IsRightToLeft ? "rtl" : "ltr")">
```

Add RTL-specific stylesheet if needed:

```csharp
public class MyThemeGlobalStyleContributor : BundleContributor
{
    public override void ConfigureBundle(BundleConfigurationContext context)
    {
        context.Files.Add("/themes/mytheme/layout.css");

        if (CultureInfo.CurrentUICulture.TextInfo.IsRightToLeft)
        {
            context.Files.Add("/themes/mytheme/layout-rtl.css");
        }
    }
}
```

---

## Best Practices for UI & Theme Customization

| Practice | Reason |
|---|---|
| Prefer **layout hooks** over editing layout files | Survives theme upgrades without merge conflicts |
| Prefer **bundle contributors** over hard-coded `<link>`/`<script>` tags | Participates in ABP's bundling & minification pipeline |
| Use **Virtual File System overrides** for surgical changes to existing themes | Only replace what you need; inherit the rest |
| Keep custom CSS in `/wwwroot/themes/<name>/` | Clear separation from application code |
| Derive from `AbpViewComponent` for toolbar/menu items | Gets ABP services (`CurrentUser`, localization) automatically |
| Use `IBrandingProvider` replacement for app name/logo | Clean override point, no layout file change needed |
| Apply `[Dependency(ReplaceServices = true)]` on branding/provider replacements | Ensures ABP DI uses your version |
| Test all three layouts: `Application`, `Account`, `Empty` | Many themes break on the Account layout |
| Always add RTL support from the start | Far harder to retrofit later |

---

## Key Rules

- **DO** call `ConfigureByConvention()` on every entity in `OnModelCreating` — the theme system relies on convention-based ABP infrastructure
- **DO** register themes in `ConfigureServices`, not `OnApplicationInitialization`
- **DO** use `StandardBundles` as base bundles — never duplicate ABP's core dependencies (Bootstrap, jQuery)
- **DO NOT** modify theme NuGet package files directly — use Virtual File System overrides
- **DO NOT** inline styles/scripts in layout files — use contributors
- **DO NOT** forget `<script src="~/Abp/ApplicationConfigurationScript">` and `<script src="~/Abp/ServiceProxyScript">` — many ABP features break without them
