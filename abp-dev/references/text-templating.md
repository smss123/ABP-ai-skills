# ABP: Text Templating

> 📖 Official docs:
> - Scriban engine: https://abp.io/docs/latest/framework/infrastructure/text-templating/scriban
> - Razor engine: https://abp.io/docs/latest/framework/infrastructure/text-templating/razor
>
> Fetch these pages for the latest API details before generating templating code.

---

## Engine Comparison

| | Scriban | Razor |
|---|---|---|
| **Sandboxed** | Yes — safe for user-editable templates | No — full .NET trust |
| **Use case** | Emails, notifications, user-customizable content | Internal code-gen, complex logic templates |
| **Package** | `Volo.Abp.TextTemplating.Scriban` | `Volo.Abp.TextTemplating.Razor` |
| **Template extension** | `.tpl` | `.cshtml` |
| **Property naming** | PascalCase → snake_case (`UserName` → `user_name`) | PascalCase as-is |

> **Default choice: Scriban.** Use Razor only when you need full C# (DI, LINQ, repositories) inside the template and the template is internal (never user-edited).

---

## Install

```bash
abp add-package Volo.Abp.TextTemplating.Scriban   # recommended
# or
abp add-package Volo.Abp.TextTemplating.Razor
```

Add `AbpTextTemplatingScribanModule` (or `AbpTextTemplatingRazorModule`) to `[DependsOn]`.

---

## Defining Templates

```csharp
// Domain or Application project
public class MyTemplateDefinitionProvider : TemplateDefinitionProvider
{
    public override void Define(ITemplateDefinitionContext context)
    {
        // Scriban
        context.Add(
            new TemplateDefinition("WelcomeEmail")
                .WithVirtualFilePath("/Templates/WelcomeEmail.tpl", isInlineLocalized: true)
                .WithScribanEngine()
        );

        // Razor
        context.Add(
            new TemplateDefinition("InvoiceReport")
                .WithVirtualFilePath("/Templates/InvoiceReport.cshtml", isInlineLocalized: true)
                .WithRazorEngine()
        );
    }
}
```

Store template files as embedded resources in the Virtual File System. In `.csproj`:

```xml
<ItemGroup>
  <EmbeddedResource Include="Templates/**" />
</ItemGroup>
```

Register the virtual path in module:

```csharp
Configure<AbpVirtualFileSystemOptions>(options =>
{
    options.FileSets.AddEmbedded<MyModule>("MyNamespace");
});
```

---

## Rendering Templates

```csharp
public class NotificationService : ITransientDependency
{
    private readonly ITemplateRenderer _templateRenderer;

    public NotificationService(ITemplateRenderer templateRenderer)
    {
        _templateRenderer = templateRenderer;
    }

    public async Task<string> RenderWelcomeEmailAsync(string userName)
    {
        return await _templateRenderer.RenderAsync(
            "WelcomeEmail",
            model: new { UserName = userName }
        );
    }
}
```

---

## Scriban Syntax

```
Hello {{model.user_name}} :)

{{~ if model.is_premium ~}}
  You have premium access.
{{~ end ~}}
```

- Model properties are snake_case: `UserName` → `user_name`
- Localization: `{{L "MyKey"}}` or `{{L "Greeting" model.name}}`

### Pass extra variables

```csharp
await _templateRenderer.RenderAsync(
    "WelcomeEmail",
    model: new { UserName = "John" },
    globalContext: new Dictionary<string, object>
    {
        { "appUrl", "https://myapp.com" }
    }
);
```

### Layout templates

```
{{content}}
```

Register with `isLayout: true`:

```csharp
new TemplateDefinition("EmailLayout", isLayout: true)
    .WithVirtualFilePath("/Templates/EmailLayout.tpl", isInlineLocalized: true)
    .WithScribanEngine()
```

Child templates reference the layout:

```csharp
new TemplateDefinition("WelcomeEmail")
    .WithLayout("EmailLayout")
    .WithVirtualFilePath("/Templates/WelcomeEmail.tpl", isInlineLocalized: true)
    .WithScribanEngine()
```

---

## Razor Template Class

```csharp
// Templates/InvoiceReport.cshtml
@inherits RazorTemplatePageBase<InvoiceModel>

<h1>Invoice #@Model.InvoiceNumber</h1>
@foreach (var line in Model.Lines)
{
    <p>@line.Description — @line.Price.ToString("C")</p>
}
```

> **Security warning:** Razor templates compile to trusted .NET assemblies (`IsSandboxed = false`). Never allow untrusted users to edit Razor templates.

---

## Localization Strategies

| Strategy | When to use |
|---|---|
| **Inline** (`isInlineLocalized: true`) | Single template file, use `L["Key"]` / `{{L "Key"}}` inside |
| **Per-culture files** | Templates differ structurally by language (e.g. RTL layout) |

Per-culture files: `WelcomeEmail.en.tpl`, `WelcomeEmail.ar.tpl` — ABP picks by culture, falls back to default.

Explicit culture render:

```csharp
await _templateRenderer.RenderAsync("WelcomeEmail", model, cultureName: "ar");
```

---

## Overriding Module Templates

Replace a template from a module (e.g. ABP Account emails) by placing a file at the same virtual path in your application module. Physical files win over embedded resources.

---

## Scriban Security Limits

| Limit | Default |
|---|---|
| Max loop iterations | 1,000 |
| Max recursion depth | 100 |
| Max output string size | 1 MB |
| Regex timeout | 10 s |

Only public properties of the model are accessible — methods, fields, and reflection are blocked.

---

## Key Rules

- **DO** use Scriban for emails and user-facing notifications — it's sandboxed
- **DO** use Razor only for internal, developer-controlled templates requiring full C#
- **DO NOT** let untrusted users edit Razor templates — they have full .NET trust
- **DO** store templates as embedded resources via the Virtual File System
- **DO** use `isInlineLocalized: true` + `L["Key"]` for multilingual templates instead of per-culture files unless layout differs significantly
