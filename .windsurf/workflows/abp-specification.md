---
name: abp-specification
description: Scaffold an ABP Framework Specification class for domain query filtering
---

# ABP Specification Scaffold

A Windsurf Cascade workflow that creates a `Specification<T>` class for filtering entities.

## Inputs

Before starting, ask the user:
1. **Entity name** (PascalCase, e.g. `Product`)
2. **Criteria / filter name** (e.g. `Active`, `ByCategoryId`, `PriceBelowThreshold`)
3. **Filter condition** — what does the specification test? (e.g. `IsActive == true && Price <= maxPrice`)
4. **Constructor parameters** — what values are passed in to parameterize the specification?

---

## Step 1 — Read reference file

Read `abp-dev/references/ddd-domain.md` and fetch https://docs.abp.io/en/abp/latest/Specifications.

---

## Step 2 — Create `src/Acme.BookStore.Domain/<Entity>s/<Criteria><Entity>Specification.cs`

```csharp
using System;
using System.Linq.Expressions;
using Volo.Abp.Specifications;

namespace Acme.BookStore.<Entity>s;

public class <Criteria><Entity>Specification : Specification<<Entity>>
{
    private readonly /* criteria type */ _criteria;

    public <Criteria><Entity>Specification(/* criteria parameter */)
        => _criteria = /* parameter */;

    public override Expression<Func<<Entity>, bool>> ToExpression()
        => entity => /* condition using _criteria */;
}
```

---

## Step 3 — Show usage examples

```csharp
// In-memory check
var spec = new <Criteria><Entity>Specification(/* args */);
bool matches = spec.IsSatisfiedBy(entity);

// Via repository
var items = await _<entity>Repository.GetListAsync(spec);

// Combining
var combined = spec1.And(spec2);
var either   = spec1.Or(spec2);
var negated  = spec1.Not();
```

---

## Step 4 — Confirm

Ask the user if they need additional specifications for this entity or a repository query method that accepts `ISpecification<T>`.
