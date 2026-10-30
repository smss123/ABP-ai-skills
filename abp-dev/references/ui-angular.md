---
applies_to_abp: "10.x"
doc_verified_on: "2026-10-29"
docs:
  - https://abp.io/docs/latest/framework/ui/angular/overview
  - https://abp.io/docs/latest/framework/ui/angular/quick-start
  - https://abp.io/docs/latest/framework/ui/angular/service-proxies
  - https://abp.io/docs/latest/framework/ui/angular/config-state-service
  - https://abp.io/docs/latest/framework/ui/angular/authorization
  - https://abp.io/docs/latest/framework/ui/angular/current-user
---

# ABP: Angular UI

> 📖 Official docs (verified live against ABP 10.x):
> - Overview: https://abp.io/docs/latest/framework/ui/angular/overview
> - Quick start: https://abp.io/docs/latest/framework/ui/angular/quick-start
> - Service proxies: https://abp.io/docs/latest/framework/ui/angular/service-proxies
> - Config state service: https://abp.io/docs/latest/framework/ui/angular/config-state-service
> - Authorization: https://abp.io/docs/latest/framework/ui/angular/authorization
> - Current user: https://abp.io/docs/latest/framework/ui/angular/current-user
> - Localization: https://abp.io/docs/latest/framework/ui/angular/localization
> - HTTP requests: https://abp.io/docs/latest/framework/ui/angular/http-requests
> - HTTP error handling: https://abp.io/docs/latest/framework/ui/angular/http-error-handling
> - Modifying the menu: https://abp.io/docs/latest/framework/ui/angular/modifying-the-menu
> - Page component: https://abp.io/docs/latest/framework/ui/angular/page-component
> - Container strategy: https://abp.io/docs/latest/framework/ui/angular/container-strategy
> - Theme configurations: https://abp.io/docs/latest/framework/ui/angular/theme-configurations
> - Dynamic form module: https://abp.io/docs/latest/framework/ui/angular/dynamic-form-module
> - SSR configuration: https://abp.io/docs/latest/framework/ui/angular/ssr-configuration
> - PWA configuration: https://abp.io/docs/latest/framework/ui/angular/pwa-configuration
>
> **Always fetch the relevant page before generating Angular code.** The Angular stack moves with
> each major (standalone components, `provide*` APIs, Angular version bumps), and the startup
> template is the authoritative source for the ABP version in the user's `environment.ts`
> (`versions.abp`). When offline, use this file and say the answer is based on cached documentation.

---

## Shape of an ABP Angular solution

`-u angular` produces a **separate SPA folder** next to the .NET layers — there is no `*.Web` project:

```
Acme.MyApp/
├── angular/                       ← the SPA (its own package.json, node_modules)
│   ├── src/app/
│   │   ├── app.config.ts / app.module.ts   ← ABP core + theme + feature modules wired here
│   │   ├── app.routes.ts                   ← lazy routes + menu contribution (see below)
│   │   ├── proxy/                          ← generated from the backend (do not hand-edit)
│   │   ├── shared/                         ← project-wide components, guards, resolvers
│   │   └── books/                          ← one folder per feature
│   └── src/environments/environment.ts     ← backend host, OAuth client, theme
├── src/Acme.MyApp.HttpApi.Host/   ← serves the API the SPA calls
└── ... Domain / Application / EF Core layers (unchanged)
```

The **backend must run** for the SPA to work: `DbMigrator` once, then `HttpApi.Host`
(default `https://localhost:44305`). The dev server runs on `http://localhost:4200`.

```bash
# one-time
cd angular && npm install

# every session
dotnet run --project src/Acme.MyApp.HttpApi.Host   # terminal 1
cd angular && npm start                             # terminal 2
```

The Angular UI never touches repositories, EF Core, or domain entities — it only talks to
application-service endpoints over HTTP.

---

## Service proxies (`abp generate-proxy`)

Do not hand-write `HttpClient` calls. Generate typed services from the running backend's OpenAPI
metadata:

```bash
# run inside the angular/ folder, with HttpApi.Host up
abp generate-proxy -t ng

# common flags
abp generate-proxy -t ng \
  --module book \
  --url https://localhost:44305 \
  --api-name default \
  --template default        # or: compact
```

| Flag | Meaning |
|---|---|
| `-t ng` | target the Angular generator (required) |
| `-m`, `--module` | only generate for one application-services module (faster; keeps diffs small) |
| `--url` | backend address used to read the API definition |
| `-a`, `--api-name` | remote-service name from `environment.ts` (for multi-endpoint/microservice setups) |
| `--template` | `default` (per-service files) or `compact` |
| `--clean` | remove stale generated files first |

Output lands under `src/app/proxy/<area>/<module>/` as `models.ts` + `<name>.service.ts`, built on
`RestService` from `@abp/ng.core`. The generator adds the Angular `@abp/schematics`-style workspace
setup the first time it runs.

```ts
import { inject } from '@angular/core';
import { BookService } from '@proxy/books';

export class BookComponent {
  private readonly bookService = inject(BookService);

  async getBooks() {
    const result = await this.bookService.getList({ filter: 'ABP' }).toPromise();
    // result.items / result.totalCount  (PagedResultDto shape from Application.Contracts)
  }
}
```

**Regenerate after every app-service signature change** — stale proxies are the number-one cause of
"the backend has the method but Angular says it doesn't". Property names arrive camelCased from the
DTOs; DTO class names keep their C# spelling in `models.ts`.

---

## `environment.ts` — the single switch for the backend

Everything the SPA needs to reach the API is in `src/environments/environment.ts`. Diff against the
file the template generated for your ABP version rather than rewriting it from memory; the keys that
matter when moving host/tenant:

```ts
export const environment = {
  production: false,
  versions: { abp: '10.0.0' },            // trust this, not this reference file, for version facts
  apiNameHosts: ['default'],              // microservice setups list one entry per API name
  defaultTheme: 'lepton-x-light',
  oAuthConfig: {
    issuer: 'https://localhost:44305',    // authority = the backend, not the SPA
    clientId: 'MyApp_App',
    scope: 'offline_access MyApp roles email profile phone',
    response_type: 'code',
    requireHttps: false,
    strictDiscoveryDocumentValidation: false,
    redirectUrl: window.location.origin,
    postLogoutRedirectUri: window.location.origin,
  },
};
```

- Android/iOS/physical-device testing → replace `localhost` with the machine's LAN IP (see
  `references/maui.md` for the same problem on mobile).
- The `clientId` **must match** an OpenIddict application seeded in the backend; changing one side
  alone produces silent 401s. See `references/openiddict.md`.
- Certificate errors: the dev backend uses a localhost dev cert; trust it
  (`dotnet dev-certs https --trust`) instead of disabling TLS validation.

---

## App bootstrap

Current templates are standalone-component based and wire ABP through `provide*` functions in
`app.config.ts` (older templates use `ConfigModule.forRoot({ environment })` in `AppModule` — check
which one the user's project has before adding providers):

```ts
import { provideAbpCore, withPlugins } from '@abp/ng.core';
import { provideAbpThemeShared } from '@abp/ng.theme.shared';
import { provideAbpAccount } from '@volo/abp.ng.account/public';
import { provideAbpIdentity } from '@volo/abp.ng.identity/public';
import { provideAbpLanguageManagement } from '@volo/abp.ng.language-management/public';

export const appConfig: ApplicationConfig = {
  providers: [
    provideAbpCore(
      { environment },
      withPlugins([
        { forRoot: provideAbpThemeShared, config: {} },
        { forRoot: provideAbpAccount, config: { layout: 'account' } },
        { forRoot: provideAbpIdentity, config: {} },
        { forRoot: provideAbpLanguageManagement, config: {} },
      ])
    ),
    provideRouter(routes),
  ],
};
```

Packages in play: `@abp/ng.core`, `@abp/ng.theme.shared` (framework), `@volo/abp.ng.*` (module UIs:
account, identity, tenant-management, language-management, openiddictconfig, audit-management,
text-template), `@volosoft/*` for LeptonX themes. Verify what is actually installed with
`npm ls --depth=0 | grep -E "abp|volo|lepton"` before importing anything.

---

## Routes double as the menu

ABP Angular builds the navigation from the route config — there is no separate menu contributor like
on the server-side UIs. Adding a page and putting it in the menu is one entry
(https://abp.io/docs/latest/framework/ui/angular/modifying-the-menu):

```ts
import { Routes } from '@angular/router';
import { eLayoutType } from '@abp/ng.core';
import { authGuard, permissionGuard } from '@abp/ng.core';
import { BookComponent } from './book.component';

export const APP_ROUTES: Routes = [
  {
    path: 'books',
    component: BookComponent,
    canActivate: [authGuard, permissionGuard],
    data: {
      requiredPolicy: 'MyApp.Books',          // permission constant from Application.Contracts
      route: {
        name: '::Menu:Books',                 // '::' = default localization resource
        url: '/books',
        iconClass: 'fa fa-book',
        layout: eLayoutType.application,
        order: 3,
      },
    },
  },
];
```

Full-page layout hooks (title, breadcrumbs, toolbar) come from the `abp-page` component:
https://abp.io/docs/latest/framework/ui/angular/page-component

---

## Permissions in templates

```html
<!-- structural directive: removes the element when not granted -->
<button *abpPermission="'MyApp.Books.Create'" (click)="create()">
  {{ '::NewBook' | abpLocalization }}
</button>
```

```ts
import { inject } from '@angular/core';
import { PermissionService } from '@abp/ng.core';

private readonly permissionService = inject(PermissionService);

get canEdit(): boolean {
  return this.permissionService.hasGranted('MyApp.Books.Edit');
}

// async/computed policies (e.g. feature-gated) — see the authorization doc page
async showBilling(): Promise<boolean> {
  return this.permissionService.executePolicyAsync('MyApp.Billing');
}
```

Server-side checks are still required — Angular permission code is UX only. Definition and enforcement
rules live in `references/authorization.md`.

---

## Localization

```ts
import { inject } from '@abp/ng.core';
import { LocalizationService } from '@abp/ng.core';

private readonly localization = inject(LocalizationService);

titleKey = this.localization.instant('::Menu:Books');
message  = this.localization.instant('MyApp::BookDeletionConfirmationMessage', row.name);
```

- `::Key` → the application's default resource; `ResourceName::Key` → a specific one.
- Template pipe: `{{ '::NewBook' | abpLocalization }}`, with parameters
  `{{ 'BookDeletionConfirmationMessage' | abpLocalization: row.name }}`.
- JSON translation files are served by the backend language manager; add keys in the
  `*.domain.Shared/Localization` JSON on the server first — see `references/localization.md`.
- Hybrid (compile-time + runtime) setup: https://abp.io/docs/latest/framework/ui/angular/hybrid-localization

---

## HTTP errors, toasts, confirmations

`RestService` maps backend `BusinessException` / validation errors to toast notifications
automatically; do not swallow it with a bare `catch`.

```ts
import { inject } from '@angular/core';
import { ConfirmationService, Confirmation, ToasterService } from '@abp/ng.theme.shared';

private readonly confirmation = inject(ConfirmationService);
private readonly toaster = inject(ToasterService);

delete(id: string) {
  this.confirmation.warn('BookStore::BookDeletionConfirmationMessage', '::AreYouSure').subscribe(status => {
    if (status === Confirmation.Status.confirm) {
      this.bookService.delete(id).subscribe({
        next: () => this.toaster.success('::SuccessfullyDeleted'),
        error: response => this.toaster.error(response?.error?.message ?? '::Failed'),
      });
    }
  });
}
```

Tune which endpoints should *not* auto-toast with the error-reporter config:
https://abp.io/docs/latest/framework/ui/angular/http-error-handling ·
request plumbing: https://abp.io/docs/latest/framework/ui/angular/http-requests

---

## Theming

LeptonX (free "lite" and commercial editions) is the current default Angular theme; the old Basic
theme pages still exist for older solutions.

- Theme switching / configuration: https://abp.io/docs/latest/framework/ui/angular/theme-configurations
- Bundling your own theme assets: https://abp.io/docs/latest/framework/ui/angular/basic-theme
- Layout containers (how content is inserted): https://abp.io/docs/latest/framework/ui/angular/container-strategy
- Replacing a framework component with your own:
  https://abp.io/docs/latest/framework/ui/angular/component-replacement
- Form UX helpers: https://abp.io/docs/latest/framework/ui/angular/dynamic-form-module ·
  https://abp.io/docs/latest/framework/ui/angular/dynamic-form-extensions ·
  https://abp.io/docs/latest/framework/ui/angular/data-table-column-extensions

---

## SSR & PWA

Both are opt-in template flags with dedicated pages; do not hand-roll the config:

- SSR: https://abp.io/docs/latest/framework/ui/angular/ssr-configuration
- PWA: https://abp.io/docs/latest/framework/ui/angular/pwa-configuration
- Deployment (SPA behind the .NET host or separate origin, rewrite rules, `Authority` for
  production): https://abp.io/docs/latest/deployment · `references/deployment.md`

---

## Key rules

- **DO** run the backend (`HttpApi.Host`) before `abp generate-proxy`; the generator reads the live
  API definition.
- **DO** regenerate proxies after changing any app-service signature; treat `src/app/proxy/` as
  generated code that is never hand-edited.
- **DO** read the project's own `environment.ts` (`versions.abp`) and `package.json` to determine the
  ABP + Angular versions in play, then fetch the matching doc page — do not assume this file's
  snippets match an older solution.
- **DO** mirror permission constants: the string in `requiredPolicy` / `*abpPermission` must be the
  same constant defined in `Application.Contracts` (see `references/authorization.md`).
- **DO** keep menu entries inside the route `data.route` object; a page that exists but is absent
  from route data is unreachable from navigation.
- **DO NOT** reach for `HttpClient` directly when a proxy can be generated; proxies carry the access
  token, `__tenant` header, culture, and correlation-id automatically.
- **DO NOT** duplicate server validation only in Angular — DTO data annotations on
  Application.Contracts drive both sides (`references/ddd-application.md`).
- **DO NOT** commit `node_modules`, and check that `.gitignore` still covers the `angular/` folder.
- **DO** remember CORS: separate origins (4200 → 44305) need the backend's CORS config
  (`references/options.md`, ABP `AbpAspNetCoreMvcOptions` / CORS section of the deployment doc).
