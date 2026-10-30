---
name: abp-test-runner
description: Write and run ABP tests — Phase 0 first (map the existing test projects and fixtures), then xunit unit tests, integration tests on ApplicationTestBase, and the dotnet commands to run them
---

# ABP Test Scaffold & Runner

A Windsurf Cascade workflow that adds tests to an ABP solution and runs them.

## Inputs

1. **What is under test** (entity, domain service, application service, EF Core query, controller)
2. **Behaviour** to prove (happy path, domain-rule violation, boundary, tenancy/concurrency)
3. Which test projects already exist in the solution

---

## Step 1 — Read reference files

- `abp-dev/references/context-intake.md` ← Phase 0: locate `*.Domain.Tests`, `*.Application.Tests`,
  `*.EntityFrameworkCore.Tests`, `*.HttpApi.Tests`; read the test module, the base class the project
  derives from, one existing fixture and one existing test, and reuse their style. No second base class,
  no mocking library the project does not already reference.
- `abp-dev/references/testing-troubleshooting.md`
- the reference file for the code under test (`ddd-domain.md`, `ddd-application.md`, `efcore.md`)

---

## Step 2 — Pick the layer

| Code under test | Test project | Fixture |
|---|---|---|
| Entity / value object rules | `*.Domain.Tests` | plain xunit, no host |
| `<Entity>Manager` domain service | `*.Domain.Tests` | `<App>DomainTestBase` |
| Application service | `*.Application.Tests` | `<App>ApplicationTestBase<TStartupModule>` |
| EF Core mapping & queries | `*.EntityFrameworkCore.Tests` | `<App>EntityFrameworkCoreTestBase` |
| HTTP behaviour | `*.HttpApi.Tests` | `ApplicationTestBase<TStartup>` + `GetTestClient()` |

---

## Step 3 — Write the tests

- names: `Should_<behaviour>` inside `<Class>_<Method>_Tests`, matching the project's convention
- arrange through the real graph: `GetRequiredService<I<Entity>AppService>()`; seed with
  `IDataSeedContributor` / `WithUnitOfWorkAsync`, never a hand-built `DbContext` (the ABP test host gives
  each test an isolated SQLite in-memory database and transaction)
- assert with `Shouldly` (`ShouldBe`, `ShouldNotBe`, `Should.ThrowAsync<BusinessException>`)
- substitute only what is external or expensive: `Substitute.For<IRepository<<Entity>, Guid>>()`
- cover happy path, boundary, domain-rule violation (assert the `BusinessException` code) and
  tenancy/concurrency where relevant
- one behaviour per test; never skip, delete or weaken a test to reach green — report the failure

---

## Step 4 — Run them

```bash
dotnet test src/<TestProject>/<TestProject>.csproj
dotnet test --filter "FullyQualifiedName~<Entity>AppService_Tests"
dotnet test --no-restore --nologo -v minimal
dotnet test --collect:"XPlat Code Coverage"
```

Report pass/fail counts. For each failure show the assertion message and the smallest fix.

---

## Step 5 — Confirm

Ask whether these tests should join CI and whether seed data for the entity belongs in the project's
`IDataSeedContributor`.
