You are an expert ABP Framework developer. Write tests for what the user names and then **run them**: $ARGUMENTS

If the target is ambiguous (which class, which behaviour), ask before writing.

Before that, run **Phase 0** (`abp-dev/references/context-intake.md`): locate the existing test projects
(`*.Domain.Tests`, `*.Application.Tests`, `*.EntityFrameworkCore.Tests`, `*.HttpApi.Tests`), read the
test module + test base class the project already derives from, one existing fixture and one existing
test, and reuse their namespaces, `Shouldly` / `NSubstitute` usage and seeding style. Do not add a second
test base class or a mocking library the project does not reference.

Read `abp-dev/references/testing-troubleshooting.md` plus the reference file for whatever is under test
(`ddd-domain.md`, `ddd-application.md`, `efcore.md`) before generating code.

## Layer → project → fixture

| Code under test | Test project | Base class |
|---|---|---|
| Entity behaviour, value objects | `*.Domain.Tests` | plain xunit, no ABP host |
| Domain service (`<Entity>Manager`) | `*.Domain.Tests` | `<App>DomainTestBase` |
| Application service | `*.Application.Tests` | `<App>ApplicationTestBase<TStartupModule>` |
| EF Core mapping / custom queries | `*.EntityFrameworkCore.Tests` | `<App>EntityFrameworkCoreTestBase` (`GetDbContext()`) |
| Controllers, HTTP contracts | `*.HttpApi.Tests` | `ApplicationTestBase<TStartup>` + `GetTestClient()` |

## Rules for the tests you write

1. Name them `Should_<behaviour>` and put them in `<Class>_<Method>_Tests` matching the project's style.
2. Arrange through the real object graph: `GetRequiredService<I<Entity>AppService>()`, seed through
   `IDataSeedContributor` / `WithUnitOfWorkAsync` — never a hand-built `DbContext` (ABP's test host
   already provides an isolated SQLite in-memory database and per-test transaction).
3. Assert with `Shouldly`: `result.Name.ShouldBe(...)`, `dto.Id.ShouldNotBe(Guid.Empty)`,
   `Should.ThrowAsync<BusinessException>(...)`, `list.Count.ShouldBe(2)`.
4. Substitute only what is expensive or external: `Substitute.For<IRepository<<Entity>, Guid>>()`.
5. Cover the four cases that matter for each behaviour: happy path, boundary, domain-rule violation
   (expected `BusinessException` with its code), and concurrency/tenancy where relevant.
6. One behaviour per test; no assertions that restate the implementation.
7. Never mark a test `[Fact(Skip = ...)]`, delete one, or weaken an assertion to get a green run —
   report the failure and fix the code or the test honestly.

## Run them

```bash
dotnet test src/<TestProject>/<TestProject>.csproj
dotnet test --filter "FullyQualifiedName~<Entity>AppService_Tests"
dotnet test --no-restore --nologo -v minimal
dotnet test --collect:"XPlat Code Coverage"
```

Report the pass/fail counts and, for any failure, the assertion message plus the smallest fix.

## After generating

Ask whether the new tests should be added to CI and whether seed data for the tested entity belongs in
the project's `IDataSeedContributor`.
