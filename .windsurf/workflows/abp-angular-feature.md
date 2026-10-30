---
name: abp-angular-feature
description: Scaffold an Angular feature for an ABP backend — Phase 0 first (existing Angular app as the reference, or Stitch MCP design tokens), then service proxy, list + modal component, route, nav, permissions and localization
---

# ABP Angular Feature Scaffold

A Windsurf Cascade workflow that adds a feature to an ABP **Angular** UI on top of an existing
application service.

> **Stack check first.** `angular/package.json` → this workflow · `Pages/**/*.cshtml` or
> `Controllers/` + `Views/` → server-side UI, run `abp-razor-page` / `abp-mvc-page` and generate **no**
> Angular code. Never emit `.cshtml` into an Angular solution or `.component.ts` into a Razor solution.

## Inputs

1. **Entity name** (PascalCase singular, e.g. `Product`)
2. **Columns** in the list, **fields** in the create/edit form
3. The **permission group** string used by the backend (e.g. `BookStore.Products`)
4. Is the ABP API running for `abp generate-proxy`? (default `https://localhost:44385`)

---

## Step 1 — Read reference files

- `abp-dev/references/context-intake.md` ← Phase 0: read an existing `src/app/<feature>` component pair,
  `app.config.ts`, routes/nav config and the localization resource; reuse the `@abp/ng.*` libraries,
  layout and styling already installed; confirm the backend app service/DTO/permission names exist
- `abp-dev/references/ui-angular.md`
- `abp-dev/references/api.md`

---

## Step 2 — Generate the service proxy (never hand-write it)

```bash
abp generate-proxy -t ng -url https://localhost:44385
```
Writes `src/app/proxy/...` from the app service and DTOs. Report the generated method names and use
exactly those. If the API is down, continue against the expected proxy path and tell the user to re-run
the command before building.

---

## Step 3 — List component

Create `src/app/<entity>s/<entity>s.component.ts`:
- `providers: [ListService]`, `readonly data = inject(ListService)`
- `PagedResultDto<<Entity>Dto>` + `switchMap(page => service.getList(page))`
- delete behind `ConfirmationService.warn()`

Create `src/app/<entity>s/<entity>s.component.html`:
- `<abp-extensible-table>` (or `<abp-table>`) with a column per DTO property
- `abpLocalization` on every label, `*abpVisibility` + `requiredPolicy` on the buttons
- `<abp-button iconClass="fa fa-plus">` for New — reuse what the app already uses

---

## Step 4 — Create/Edit modal form

Create `src/app/<entity>s/<entity>s-form.component.ts`:
- `FormBuilder` reactive form, `Validators.required` mirroring the DTO attributes
- save through the proxy; errors via `AbpValidation.getValidationErrorMessage(err)`
- opened with `BsModalService` or `MatDialogService` — whichever the project already depends on

---

## Step 5 — Route

```typescript
{ path: '<entity>s', component: <Entity>sComponent, data: { requiredPolicy: '<App>.<Entity>s' } }
```

---

## Step 6 — Navigation entry (config, not a hardcoded menu)

```typescript
{ name: '::Menu:<Entity>s', icon: 'fas fa-list', route: '/<entity>s',
  layout: eLayoutType.application, requiredPolicy: '<App>.<Entity>s' }
```

---

## Step 7 — Localization keys

Add `Menu:<Entity>s`, `<Entity>`, `New<Entity>`, `Edit<Entity>`,
`<Entity>DeletionConfirmationMessage` and one key per validation message to the resource the app serves.

---

## Step 8 — Spec file

`src/app/<entity>s/<entity>s.component.spec.ts` with `TestingModule` + `NO_ERRORS_SCHEMA` and the proxy
service spied.

---

## Step 9 — Confirm

Ask whether to run `abp generate-proxy -t ng` now and whether the feature should be lazy-loaded instead
of eagerly registered.
