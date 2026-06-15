---
description: Change, customize, or create a UI theme for an ABP MVC/Razor Pages application
---

You are an expert ABP Framework UI developer. Help the user **change, customize, or create a UI theme** for their ABP MVC/Razor Pages application.

Read `abp-dev/references/theming.md` before generating any code.

If the user provides a theme folder path (e.g. `src/Acme.BookStore.Web`), use it as the base for all generated file paths.

---

## Step 1 — Identify the Goal

Determine which scenario applies from context or by asking:

| # | Goal | Action |
|---|---|---|
| A | Switch to a different built-in theme | Update `AbpThemingOptions.DefaultThemeName` only |
| B | Minor customizations (CSS, logo, footer) | Bundle contributor + `IBrandingProvider` + layout hooks |
| C | Override specific layout files | Virtual File System override of individual `.cshtml` files |
| D | Create a brand-new custom theme | Full scaffold: `ITheme` + layouts + bundles + branding |

---

## Step 2 — Theme Folder Structure

When a path is provided, scaffold files under:

```
<path>/Themes/<ThemeName>/
  Layouts/
    Application.cshtml
    Account.cshtml
    Empty.cshtml
  Components/
    Menu/Default.cshtml
    Toolbar/Default.cshtml
    Brand/Default.cshtml
  wwwroot/themes/<themename>/
    layout.css
    layout.js
```

Default path if none given: `src/Acme.BookStore.Web/Themes/MyTheme/`

---

## Scenario A — Switch Built-In Theme

Edit the Web module `ConfigureServices`:

```csharp
Configure<AbpThemingOptions>(options =>
{
    options.DefaultThemeName = LeptonXLiteTheme.Name;
    // alternatives: BasicTheme.Name, LeptonXTheme.Name
});
```

NuGet packages:
- LeptonX Lite (free): `Volo.Abp.AspNetCore.Mvc.UI.Theme.LeptonXLite`
- Basic: `Volo.Abp.AspNetCore.Mvc.UI.Theme.Basic`

---

## Scenario B — Minor Customizations

### CSS/JS via bundle contributor

```csharp
Configure<AbpBundlingOptions>(options =>
{
    options.StyleBundles.Configure(
        StandardBundles.Styles.Global,
        bundle => bundle.AddFiles("/themes/custom/overrides.css")
    );
});
```

### Branding (logo + name)

```csharp
[Dependency(ReplaceServices = true)]
public class MyBrandingProvider : DefaultBrandingProvider
{
    public override string AppName       => "My Application";
    public override string LogoUrl       => "/themes/custom/logo.png";
    public override string LogoReverseUrl => "/themes/custom/logo-white.png";
}
```

### Inject footer/header via layout hooks (no layout file editing required)

```csharp
Configure<AbpLayoutHookOptions>(options =>
{
    options.Add(LayoutHooks.Body.Last, typeof(MyFooterViewComponent));
});
```

---

## Scenario C — Override Layout Files

Place override files at the same virtual path as the theme:

```
src/Acme.BookStore.Web/Themes/LeptonXLite/Layouts/Application.cshtml
```

Physical files win over embedded NuGet resources — only override what you need.

Get theme source for reference:

```bash
abp add-package Volo.Abp.AspNetCore.Mvc.UI.Theme.Basic \
    --with-source-code \
    --add-to-solution-file
```

---

## Scenario D — Full Custom Theme Scaffold

### 1. Theme class

```csharp
[ThemeName(Name)]
public class MyTheme : ITheme, ITransientDependency
{
    public const string Name = "<ThemeName>";

    public virtual string GetLayout(string name, bool fallbackToDefault = true) =>
        name switch
        {
            StandardLayouts.Application => "~/Themes/<ThemeName>/Layouts/Application.cshtml",
            StandardLayouts.Account     => "~/Themes/<ThemeName>/Layouts/Account.cshtml",
            StandardLayouts.Empty       => "~/Themes/<ThemeName>/Layouts/Empty.cshtml",
            _ => fallbackToDefault ? "~/Themes/<ThemeName>/Layouts/Application.cshtml" : null
        };
}
```

### 2. Bundle constants

```csharp
public static class MyThemeBundles
{
    public static class Styles  { public const string Global = "<ThemeName>.Global"; }
    public static class Scripts { public const string Global = "<ThemeName>.Global"; }
}
```

### 3. Module registration

```csharp
Configure<AbpThemingOptions>(options =>
{
    options.Themes.Add<MyTheme>();
    options.DefaultThemeName = MyTheme.Name;
});

Configure<AbpBundlingOptions>(options =>
{
    options.StyleBundles.Add(MyThemeBundles.Styles.Global, b =>
    {
        b.AddBaseBundles(StandardBundles.Styles.Global)
         .AddContributors(typeof(MyThemeGlobalStyleContributor));
    });
    options.ScriptBundles.Add(MyThemeBundles.Scripts.Global, b =>
    {
        b.AddBaseBundles(StandardBundles.Scripts.Global)
         .AddContributors(typeof(MyThemeGlobalScriptContributor));
    });
});
```

### 4. Application layout — full template

See `abp-dev/references/theming.md` for the complete `Application.cshtml` template with all required sections and layout hooks.

---

## RTL Support

```html
<html dir="@(CultureInfo.CurrentUICulture.TextInfo.IsRightToLeft ? "rtl" : "ltr")">
```

Add RTL stylesheet in contributor:

```csharp
if (CultureInfo.CurrentUICulture.TextInfo.IsRightToLeft)
    context.Files.Add("/themes/<name>/layout-rtl.css");
```

---

## After Generating

- Run `abp bundle` to regenerate asset bundles
- Test all three layouts: Application, Account, Empty
- Never add Bootstrap/jQuery manually — they come via `StandardBundles`
- Check RTL rendering for Arabic/Hebrew cultures
