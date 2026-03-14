---
mode: 'agent'
description: 'Scaffold ABP permission constants and permission definition provider for an entity'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold **ABP permission constants and a permission definition provider** for the entity or feature the user names.

If no entity or feature name was provided, ask for it before proceeding.

## Before generating any code

Read `abp-dev/references/authorization.md` and fetch https://docs.abp.io/en/abp/latest/Authorization for the latest API details.

Replace every `<Entity>` placeholder with the PascalCase entity name.

---

## Files to modify / create

### 1. Add to `src/Acme.BookStore.Application.Contracts/Permissions/BookStorePermissions.cs`

Add a nested static class for the new entity:

```csharp
public static class <Entity>s
{
    public const string Default = GroupName + ".<Entity>s";
    public const string Create  = Default + ".Create";
    public const string Edit    = Default + ".Edit";
    public const string Delete  = Default + ".Delete";
}
```

### 2. Add to `src/Acme.BookStore.Application.Contracts/Permissions/BookStorePermissionDefinitionProvider.cs`

Inside the `Define` method, add:

```csharp
var <entity>sPermission = bookStoreGroup.AddPermission(
    BookStorePermissions.<Entity>s.Default,
    L("Permission:<Entity>s")
);
<entity>sPermission.AddChild(BookStorePermissions.<Entity>s.Create, L("Permission:<Entity>s.Create"));
<entity>sPermission.AddChild(BookStorePermissions.<Entity>s.Edit,   L("Permission:<Entity>s.Edit"));
<entity>sPermission.AddChild(BookStorePermissions.<Entity>s.Delete, L("Permission:<Entity>s.Delete"));
```

If `BookStorePermissionDefinitionProvider` does not yet exist, create it:

```csharp
using Acme.BookStore.Localization;
using Volo.Abp.Authorization.Permissions;
using Volo.Abp.Localization;

namespace Acme.BookStore.Permissions;

public class BookStorePermissionDefinitionProvider : PermissionDefinitionProvider
{
    public override void Define(IPermissionDefinitionContext context)
    {
        var bookStoreGroup = context.AddGroup(
            BookStorePermissions.GroupName,
            L("Permission:BookStore")
        );

        // paste entity blocks here
    }

    private static LocalizableString L(string name)
        => LocalizableString.Create<BookStoreResource>(name);
}
```

### 3. Localization keys to add to `en.json`

Path: `src/Acme.BookStore.Domain.Shared/Localization/BookStore/en.json`

```json
"Permission:<Entity>s":        "<Entity> Management",
"Permission:<Entity>s.Create": "Creating new <entity>s",
"Permission:<Entity>s.Edit":   "Editing <entity>s",
"Permission:<Entity>s.Delete": "Deleting <entity>s"
```

---

## After generating

Remind the user that permissions defined here are automatically discovered by ABP — no module registration needed. The permissions will appear in the permissions management UI.
