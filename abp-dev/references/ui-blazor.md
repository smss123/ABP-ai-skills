---
applies_to_abp: "9.x - 10.x"
doc_verified_on: "2026-10-29"
docs:
  - https://abp.io/docs/latest/framework/ui/blazor/overall
  - https://abp.io/docs/latest/framework/ui/blazor/theming
---

# ABP: Blazor UI (WebAssembly / Server / WebApp)

> 📖 Official docs (verified live against ABP 10.x):
> - Overall: https://abp.io/docs/latest/framework/ui/blazor/overall
> - Theming: https://abp.io/docs/latest/framework/ui/blazor/theming
> - Navigation & menu: https://abp.io/docs/latest/framework/ui/blazor/navigation-menu
> - Forms & validation: https://abp.io/docs/latest/framework/ui/blazor/forms-validation
> - Authorization: https://abp.io/docs/latest/framework/ui/blazor/authorization
> - Current user / tenant: https://abp.io/docs/latest/framework/ui/blazor/current-user
>   · https://abp.io/docs/latest/framework/ui/blazor/current-tenant
> - Toolbars: https://abp.io/docs/latest/framework/ui/blazor/toolbars
> - Page alerts / progress / block-busy: https://abp.io/docs/latest/framework/ui/blazor/page-alerts
> - Error handling: https://abp.io/docs/latest/framework/ui/blazor/error-handling
> - Routing: https://abp.io/docs/latest/framework/ui/blazor/routing
>
> Fetch these before generating Blazor code — the ABP Blazor chapter has ~30 sub-pages and the
> component APIs move between releases.

> **Detect first.** Only write Blazor code when the solution actually has a Blazor project
> (`*.Blazor/`, `*.Web.Public/` with `App.razor` / `_Imports.razor`, or a `Microsoft.AspNetCore.Components*`
> `PackageReference`). `Pages/**/*.cshtml` → `ui-razorpages.md` · `Controllers/` + `Views/` → `ui-mvc.md` ·
> `angular/package.json` → `ui-angular.md` · MAUI/RN → `maui.md` / `react-native.md`. Never emit `.razor`
> into a Razor Pages solution or `.cshtml` into a Blazor one.

---

## The three hosting models

| Model | What it is | Theme/bundling package family |
|---|---|---|
| **Blazor WebAssembly (WASM)** | client-side .NET in the browser; the ABP backend is reached over HTTP like Angular | `Volo.Abp.AspNetCore.Components.WebAssembly.Theming`, `Volo.Abp.AspNetCore.Components.WebAssembly.BasicTheme` |
| **Blazor Server** | server-rendered with SignalR circuit; ABP services inject directly | `Volo.Abp.AspNetCore.Components.Server.Theming` |
| **Blazor WebApp** | hybrid of the two (per-page render mode) | the Server + WebAssembly theming packages, chosen per render mode |

All three share `Volo.Abp.AspNetCore.Components.*` abstractions: the same menu/toolbar/branding/alert
model as the MVC layer, so a feature's permission names and localization keys stay identical across UIs.

---

## ABP's Blazor building blocks (verbatim names)

| Name | Purpose |
|---|---|
| `IBrandingProvider` | app name + logo URL used by the theme layout |
| `IMenuManager` | `GetAsync(StandardMenus.Main)` returns the navigation items to render |
| `IToolbarManager` | `GetAsync(StandardToolbars.Main)` returns toolbar components (user menu, language switch) |
| `IAlertManager` | current page alerts displayed by the layout |
| `ILanguageProvider` | available cultures for the language dropdown |
| `ICurrentUser` | logged-in user details in a view |
| `ICurrentTenant` | tenancy info in a view (multi-tenant apps) |
| `IBundleContributor` | adds global styles/scripts inside `ConfigureBundle` |
| `StandardMenus.Main` / `StandardMenus.User` | menu collection identifiers |
| `StandardToolbars.Main` | toolbar collection identifier |
| `BlazorWebAssemblyStandardBundles.Styles.Global` | global style bundle target (WASM) |
| `Abp.SelectedLanguage` | localStorage key holding the chosen culture |

The page-level base class and the `<abp-*>` components ship from the theme package: prefer the ABP
components (`AbpCard`, `AbpButton`, `AbpDataTable`, `AbpModal`, `AbpSubmitButton`, `AbpPageAlert`,
`AbpProgressBar`, `AbpBlockUi`) over raw markup — they are what the theme styles.

---

## Service calls: generated proxies, not hand-written HttpClient

```bash
abp generate-proxy -t csharp
```
Generates C# client proxies from the application services (`Volo.Abp.Http.Client` +
`[RemoteService]`). A Blazor Server app may inject the application service directly; a WASM/Hybrid app
must use the proxy, because the browser process has no access to the domain layer.

---

## Registration patterns

```csharp
// Module: theme + bundling
[DependsOn(typeof(AbpAspNetCoreComponentsWebAssemblyThemingBundlingModule))]
public class MyBlazorWebAssemblyBundlingModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        Configure<AbpBundlingOptions>(options =>
        {
            options.StyleBundles
                .Get(BlazorWebAssemblyStandardBundles.Styles.Global)
                .AddContributors(typeof(MyThemeBundleContributor));
        });
    }
}

public class MyThemeBundleContributor : BundleContributor
{
    public override void ConfigureBundle(BundleConfigurationContext context)
    {
        context.Files.AddIfNotContains("_content/MyTheme/styles.css");
    }
}
```

```csharp
// Menu contributor — never a hardcoded nav list
public class MyMainMenuItemContributor : IMenuItemContributor, ITransientDependency
{
    public async Task ConfigureMenuAsync(MenuConfigurationContext context)
    {
        if (context.Menu.Name != StandardMenus.Main) return;

        context.Menu.AddItem(new ApplicationMenuItem(
            "MyApp.Books", l["Menu:Books"], "/books", icon: "fas fa-book"));
    }
}
```

```razor
@page "/books"
@attribute [Authorize(MyAppPermissions.Books.Default)]
@inherits MyComponentBase

<AbpCard>
    <AbpCardHeader Title="@L["Books"]" />
    <AbpCardBody>
        <AbpDataTable TItem="BookDto" Rows="@books" />
    </AbpCardBody>
</AbpCard>
```
Localization in Blazor comes from the app's resource: `@L["Key"]` / `ILocalizer`, the same keys as the
server-side UI — do not duplicate strings per component.

Language switching reads/writes the `Abp.SelectedLanguage` localStorage key through `IJSRuntime` and
then reloads:
```csharp
var culture = await JsRuntime.InvokeAsync<string>("localStorage.getItem", "Abp.SelectedLanguage");
// … set CultureInfo …
await JsRuntime.InvokeVoidAsync("location.reload");
```

---

## Phase 0 notes specific to Blazor

1. Read one existing page component + the module that registers the theme, and copy its structure,
   bundle names and menu keys.
2. Confirm which hosting model the project uses before choosing between injecting an app service
   (Server) and generating a C# proxy (WASM/Hybrid).
3. UI source of truth: ask whether the **Stitch MCP** is connected; if not, reuse the theme the app
   already ships (`BasicTheme`, LeptonX / LeptonX Lite for Blazor — `/ui-themes/lepton-x/blazor`,
   `/ui-themes/lepton-x-lite/blazor`) and do not add a CSS framework.

## Do / Don't

- **Do** use ABP components and the theme's bundles; **don't** hand-write Bootstrap markup.
- **Do** guard pages with `[Authorize]` + permission constants from `Application.Contracts`; **don't**
  rely on the menu entry being hidden.
- **Do** run `abp generate-proxy -t csharp` after changing an app service; **don't** hand-write the DTO
  mirror.
- **Do** keep one `en.json`/resource set shared by all UIs; **don't** localize per framework.
