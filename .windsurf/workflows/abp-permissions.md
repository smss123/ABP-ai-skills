---
name: abp-permissions
description: Scaffold ABP permission constants and PermissionDefinitionProvider for an entity
---

# ABP Permissions Scaffold

A Windsurf Cascade workflow that adds permission constants and registers them in the permission definition provider.

## Inputs

Before starting, ask the user:
1. **Entity or feature name** (PascalCase, e.g. `Product`, `OrderManagement`)
2. **Operations needed** — default is Create / Edit / Delete; are any different operations required?
3. Does `BookStorePermissions.cs` and `BookStorePermissionDefinitionProvider.cs` already exist?

---

## Step 1 — Read reference file

Read `abp-dev/references/authorization.md`.

---

## Step 2 — Add constants to `BookStorePermissions.cs`

File: `src/Acme.BookStore.Application.Contracts/Permissions/BookStorePermissions.cs`

Add:
```csharp
public static class <Entity>s
{
    public const string Default = GroupName + ".<Entity>s";
    public const string Create  = Default + ".Create";
    public const string Edit    = Default + ".Edit";
    public const string Delete  = Default + ".Delete";
}
```

---

## Step 3 — Add to `BookStorePermissionDefinitionProvider.Define()`

File: `src/Acme.BookStore.Application.Contracts/Permissions/BookStorePermissionDefinitionProvider.cs`

Add inside the `Define` method:
```csharp
var <entity>sPermission = bookStoreGroup.AddPermission(
    BookStorePermissions.<Entity>s.Default, L("Permission:<Entity>s"));
<entity>sPermission.AddChild(BookStorePermissions.<Entity>s.Create, L("Permission:<Entity>s.Create"));
<entity>sPermission.AddChild(BookStorePermissions.<Entity>s.Edit,   L("Permission:<Entity>s.Edit"));
<entity>sPermission.AddChild(BookStorePermissions.<Entity>s.Delete, L("Permission:<Entity>s.Delete"));
```

If the provider class doesn't exist yet, create it using the template in `abp-dev/references/authorization.md`.

---

## Step 4 — Add localization keys

File: `src/Acme.BookStore.Domain.Shared/Localization/BookStore/en.json`

```json
"Permission:<Entity>s":        "<Entity> Management",
"Permission:<Entity>s.Create": "Creating new <entity>s",
"Permission:<Entity>s.Edit":   "Editing <entity>s",
"Permission:<Entity>s.Delete": "Deleting <entity>s"
```

---

## Step 5 — Confirm

Permissions are auto-discovered by ABP — no module registration needed. They will appear immediately in the permission management UI.
