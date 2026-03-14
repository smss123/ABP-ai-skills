You are an expert ABP Framework developer. Scaffold **ABP permission constants and a permission definition provider** for the entity named: $ARGUMENTS

If no entity or feature name was provided, ask for it before proceeding.

Read `abp-dev/references/authorization.md` before generating any code.

## What to generate

### 1. Add to `src/Acme.BookStore.Application.Contracts/Permissions/BookStorePermissions.cs`

```csharp
public static class <Entity>s
{
    public const string Default = GroupName + ".<Entity>s";
    public const string Create  = Default + ".Create";
    public const string Edit    = Default + ".Edit";
    public const string Delete  = Default + ".Delete";
}
```

### 2. Add to `BookStorePermissionDefinitionProvider.Define()`

```csharp
var <entity>sPermission = bookStoreGroup.AddPermission(
    BookStorePermissions.<Entity>s.Default,
    L("Permission:<Entity>s")
);
<entity>sPermission.AddChild(BookStorePermissions.<Entity>s.Create, L("Permission:<Entity>s.Create"));
<entity>sPermission.AddChild(BookStorePermissions.<Entity>s.Edit,   L("Permission:<Entity>s.Edit"));
<entity>sPermission.AddChild(BookStorePermissions.<Entity>s.Delete, L("Permission:<Entity>s.Delete"));
```

If `BookStorePermissionDefinitionProvider` does not yet exist, create it (see `abp-dev/references/authorization.md` for the full class template).

### 3. Add localization keys to `en.json`

Path: `src/Acme.BookStore.Domain.Shared/Localization/BookStore/en.json`

```json
"Permission:<Entity>s":        "<Entity> Management",
"Permission:<Entity>s.Create": "Creating new <entity>s",
"Permission:<Entity>s.Edit":   "Editing <entity>s",
"Permission:<Entity>s.Delete": "Deleting <entity>s"
```

## After generating

Remind the user that ABP auto-discovers `PermissionDefinitionProvider` classes — no module registration needed. Permissions will appear immediately in the permission management UI.
