---
mode: 'agent'
description: 'Scaffold an Angular feature for an ABP backend — Phase 0 first (existing Angular app as the visual reference, or Stitch MCP design tokens), then service proxy, list + modal component, route, nav, permissions and localization'
tools: ['codebase', 'fetch', 'search', 'editFiles', 'runCommands']
---

You are an expert ABP Framework developer. Scaffold an **Angular feature** for the entity the user names
so it talks to the existing ABP application service over HTTP.

> **Stack check first.** `angular/package.json` → this prompt. `Pages/**/*.cshtml` or
> `Controllers/` + `Views/` → the project is server-side UI; use `abp-razor-page` or `abp-mvc-page` and
> generate **no** Angular code. Never emit `.cshtml` into an Angular solution or `.component.ts` into a
> Razor solution.

## Before generating any code

0. **Phase 0 — look at the real project first** (`abp-dev/references/context-intake.md`): read an
   existing `src/app/<feature>/*.component.{ts,html}` pair, the `app.config.ts`, `routes` config and
   `asset/internationalization/en.json`; reuse the ABP Angular libraries the app already depends on
   (`@abp/ng.components`, `@abp/ng.core`, `@abp/ng.theme.shared`), its page layout, and its styling.
   Confirm the backend app service, DTOs and permission names exist — the proxy is generated from them.
   For a new look, ask whether the **Stitch MCP** is connected; otherwise the existing app is the
   reference and you do not add a CSS framework the project does not use.
1. Read `abp-dev/references/ui-angular.md` and `abp-dev/references/api.md`.
2. Fetch the Angular documentation URLs `abp-dev/references/INDEX.md` lists for the Angular rows.
3. Only then write code.

## Files to create

### 1. Generated service proxy — never hand-written
Run the CLI against the **running** backend (or with `--url`):
```bash
abp generate-proxy -t ng -url https://localhost:44385
```
It writes `src/app/proxy/...` from the app service and its DTOs. Show the generated
`getlist` / `create` / `update` / `delete` signatures and use those exact names; if the backend is not
running, write the component against the expected proxy path and tell the user to run the command.

### 2. List component
`src/app/<entity>s/<entity>s.component.ts`
```typescript
import { Component, OnInit, inject } from '@angular/core';
import { ListService, PagedResultDto } from '@abp/ng.core';
import { EntityService, EntityDto } from '@proxy/<entity>s';

@Component({
  selector: 'app-<entity>s',
  templateUrl: './<entity>s.component.html',
  providers: [ListService],
})
export class <Entity>sComponent implements OnInit {
  readonly data = inject(ListService);
  <entity>s?: PagedResultDto<EntityDto>;

  ngOnInit() {
    this.data.list.pipe(switchMap((page) => this.service.getList({ ...page })))
      .subscribe((result) => (this.<entity>s = result));
  }
}
```
`<entity>s.component.html` uses the ABP components the app already ships:
`<abp-extensible-table>` (or `<abp-table>`), the `abpVisibility` directive with
`requiredPolicy="<permission name>"` for the New/Edit/Delete buttons, and `abpLocalization` for every
label.

### 3. Create/Edit modal
Use `BsModalService` (or `MatDialogService` — match whichever the project already uses) with a form
built from `FormBuilder`, `Validators.required` mirroring the DTO attributes, and
`AbpValidation.getValidationErrorMessage(err)` for server-side `BusinessException` messages.

### 4. Route + navigation — config-driven, no hardcoded menu
`src/app/routes.ts` (or the project's route file):
```typescript
{ path: '<entity>s', component: <Entity>sComponent,
  data: { requiredPolicy: '<App>.<Entity>s' } }
```
`src/app/config.ts` `nav` contributor: add a `<add-entity>` item with `name: '::Menu:<Entity>s'`,
`icon: 'fas fa-list'`, `requiredPolicy: '<App>.<Entity>s'`, `layout: eLayoutType.application`.

### 5. Localization
Add the keys used above to `src/assets/app.config/en.json` (or the served localization resource):
`Menu:<Entity>s`, `<Entity>`, `New<Entity>`, `<Entity>DeletionConfirmationMessage`, `SuccessfullyDeleted`.

### 6. Angular tests
`<entity>s.component.spec.ts` with `TestingModule` + `NO_ERRORS_SCHEMA` and the proxy service replaced
by a spy (see `abp-dev/references/testing-troubleshooting.md` for the backend-side fixtures).

## After generating

Ask whether to run `abp generate-proxy -t ng` now (needs the API running) or whether the user wants the
feature module lazy-loaded instead of eagerly registered.
