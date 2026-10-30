You are an expert ABP Framework developer. Scaffold an **Angular feature** for the entity named: $ARGUMENTS

If no entity name was provided, ask for it before proceeding.

Before that, run **Phase 0** (`abp-dev/references/context-intake.md`): read an existing
`src/app/<feature>/*.component.{ts,html}` pair, `app.config.ts`, the routes/nav config and
`assets/.../en.json`; reuse the `@abp/ng.*` libraries, layout and styling the app already depends on;
confirm the backend app service, DTOs and permission names exist (the proxy is generated from them); for
a new look, ask whether the **Stitch MCP** is connected, otherwise the existing app is the reference and
you add no CSS framework the project does not already use.

Read `abp-dev/references/ui-angular.md` and `abp-dev/references/api.md` before generating any code.

> **Stack check first.** `angular/package.json` → this command. `Pages/**/*.cshtml` or
> `Controllers/` + `Views/` → the project is server-side UI: use `abp-razor-page` / `abp-mvc-page` and
> generate **no** Angular code. Never emit `.cshtml` into an Angular solution or `.component.ts` into a
> Razor solution.

## What to generate

### 1. Service proxy — generated, never hand-written
```bash
abp generate-proxy -t ng -url https://localhost:44385
```
Writes `src/app/proxy/...` from the app service + DTOs. Use the exact generated method names
(`getList`, `get`, `create`, `update`, `delete`). If the backend is not running, write the component
against the expected proxy path and tell the user to run the command before building.

### 2. `src/app/<entity>s/<entity>s.component.ts`
- `providers: [ListService]`, `readonly data = inject(ListService)`
- `PagedResultDto<<Entity>Dto>` state, `switchMap` on `this.data.list` → `service.getList(...)`
- delete through `ConfirmationService.warn()` and the proxy's `delete`

### 3. `src/app/<entity>s/<entity>s.component.html`
- `<abp-extensible-table>` (or `<abp-table>`) with data columns for the DTO properties
- every label through `abpLocalization`; buttons guarded with `*abpVisibility` +
  `requiredPolicy="<App>.<Entity>s.Create"` etc.
- `<abp-button iconClass="fa fa-plus">` for New — reuse the app's existing ABP components

### 4. `src/app/<entity>s/<entity>s-form.component.ts` (create/edit modal content)
- reactive form via `FormBuilder`, `Validators.required` mirroring the DTO attributes
- save through the proxy, errors surfaced with `AbpValidation.getValidationErrorMessage(err)`
- opened with `BsModalService` (or `MatDialogService`) — match whichever the app already uses

### 5. Route
```typescript
{ path: '<entity>s', component: <Entity>sComponent, data: { requiredPolicy: '<App>.<Entity>s' } }
```

### 6. Navigation entry (config-driven, never a hardcoded menu)
```typescript
{ name: '::Menu:<Entity>s', icon: 'fas fa-list',
  route: '/<entity>s', layout: eLayoutType.application,
  requiredPolicy: '<App>.<Entity>s' }
```

### 7. Localization keys
`Menu:<Entity>s`, `<Entity>`, `New<Entity>`, `Edit<Entity>`, `<Entity>DeletionConfirmationMessage`,
plus one key per validation message — in the localization resource the app actually serves.

### 8. Component spec
`<entity>s.component.spec.ts` with `TestingModule` + `NO_ERRORS_SCHEMA` and the proxy service replaced
by a spy.

## After generating

Ask whether to run `abp generate-proxy -t ng` now (needs the API running) and whether the feature should
be lazy-loaded instead of eagerly registered.
