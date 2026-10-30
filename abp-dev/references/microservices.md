---
applies_to_abp: "9.x - 10.x"
doc_verified_on: "2026-10-29"
docs:
  - https://abp.io/docs/latest/framework/architecture/microservices
  - https://abp.io/docs/latest/solution-templates/microservice
  - https://abp.io/docs/latest/get-started/microservice
  - https://abp.io/docs/latest/deployment/distributed-microservice
---

# ABP: Microservice Solution Architecture

> 📖 Official docs (verified live against ABP 10.x):
> - Architecture: https://abp.io/docs/latest/framework/architecture/microservices
> - Solution template: https://abp.io/docs/latest/solution-templates/microservice
> - Get started: https://abp.io/docs/latest/get-started/microservice
> - Deployment: https://abp.io/docs/latest/deployment/distributed-microservice
> - Related chapters: modularity basics
>   https://abp.io/docs/latest/framework/architecture/modularity/basics · module-architecture best
>   practices https://abp.io/docs/latest/framework/architecture/best-practices/module-architecture ·
>   auto API controllers https://abp.io/docs/latest/framework/api-development/auto-controllers ·
>   dynamic C# clients https://abp.io/docs/latest/framework/api-development/dynamic-csharp-clients ·
>   distributed event bus https://abp.io/docs/latest/framework/infrastructure/event-bus

---

## When this applies

The monolith template (`abp new Acme.MyApp`) already contains the layering and the module boundaries a
microservice solution needs. Move to the microservice template when **independent deployment**,
**per-service scaling**, or **per-service databases** are actual requirements — not as a default. ABP
makes the step cheap because the domain/application layers are shared unchanged; what changes is
hosting, communication and data ownership.

Detect it in a target project by: a `services/` + `gateway/` folder layout, `*.WebGateway/*`,
`*.DbMigrator` per service, `RabbitMQ`/`YARP` `PackageReference`s, `etc/` scripts and docker
`compose`/`helm` files.

```bash
# The microservice solution is created through ABP Studio's "Microservice Solution" template
# (docs: https://abp.io/docs/latest/solution-templates/microservice and
# https://abp.io/docs/latest/get-started/microservice). Do not guess a CLI flag for it: check the
# current page or use Studio. `abp new Acme.MyApp` without a template argument creates the monolith.
```

---

## Shape of the ABP microservice template

Confirmed top-level folders: **`apps`**, **`gateways`**, **`services`** (plus `etc/` for local
infrastructure scripts and a `DbMigrator`).

| Piece | Role |
|---|---|
| `services/<name>` | one host per bounded context; internal layering identical to the monolith (`Domain`, `Application`, `EntityFrameworkCore`, `HttpApi`) |
| `apps` | the ASP.NET Core hosts: the auth server (OpenIddict) and application hosts that aggregate application services of several back-end services for one UI |
| `gateways` | **YARP** reverse proxy / BFF: one public origin, cookie & token handling, aggregates the services' APIs |
| `DbMigrator` | runs EF Core migrations + seed for every service database from one entry point |
| `etc/scripts` | local infrastructure bootstrap (RabbitMQ, Redis, the database) |
| Distributed event bus | RabbitMQ (+ outbox/inbox) for eventual consistency between services |
| Dynamic C# HTTP API clients / `abp generate-proxy -t csharp` | service-to-service and UI-to-API calls; never hand-written `HttpClient` |
| ABP Studio | run profiles ("Solution Runner"), monitoring, Kubernetes deployment panels |

## Communication rules

1. **Synchronous** calls go through the auto-generated API surface (auto API controllers + C# client
   proxies or dynamic C# clients), addressed via the gateway, with the token forwarded — never by
   reaching into another service's database or repositories.
2. **Asynchronous** cross-service effects go on the **distributed event bus** (RabbitMQ). Use
   `ITransientDependency`-style ETOs published with `IDistributedEventBus.PublishAsync(...,
   transactional: true)` so the event commits with the transaction; enable the **outbox/inbox**
   providers when you need at-least-once delivery and de-duplication.
3. Every service owns its schema. Shared tables are a design failure, not a shortcut — expose the data
   through the owning service's application layer instead.
4. One OpenIddict authority; every service validates the same access token. `RemoteServices`
   configuration in `appsettings.json` is where the base addresses and client credentials live.
5. Correlation id, distributed tracing and centralized logging stop being optional: cross-service calls
   need `correlation-id.md` plus a log store, or a bug cannot be traced.

## Operational rules

- **Deployment**: containers per service, Helm/K8s manifests from the template; `AbpBackgroundWorkerOptions.IsEnabled`
  and worker queue prefixes per service so only one instance runs each recurring job (see
  `background-workers.md`).
- **Migrations**: run through `DbMigrator` (or a dedicated job), never at boot inside each service —
  parallel pods racing on the same migration is a known failure mode.
- **Versioning**: an API change is a contract change. Keep DTOs backwards compatible, or version the
  endpoint; `openapi-swagger.md` documents the per-service documents consumers generate proxies from.
- **Testing**: each service has its own test project, plus contract tests for any endpoint other
  services depend on.

## Phase 0 notes

Before generating anything in a microservice solution: identify **which service owns the data**, whether
the change needs a synchronous call or a domain event, and whether the gateway/BFF layer must expose it.
A feature that crosses three services is usually a sign the aggregate boundary is in the wrong place —
raise it instead of writing the third hop.
