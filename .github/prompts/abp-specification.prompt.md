---
mode: 'agent'
description: 'Scaffold an ABP Framework Specification class for domain query filtering'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold an **ABP Specification class** for the entity and criteria the user describes.

If no entity name or filtering criteria was provided, ask before proceeding.

## Before generating any code

Read `abp-dev/references/ddd-domain.md` and fetch https://docs.abp.io/en/abp/latest/Specifications for the latest API details.

ABP provides `Specification<T>` in the `Volo.Abp.Specifications` namespace (package: `Volo.Abp.Specifications`).

Replace every `<Entity>` placeholder with the PascalCase entity name and `<Criteria>` with a name describing the filter (e.g. `Active`, `ByCategory`, `PriceBelowThreshold`).

---

## File to create

### `src/Acme.BookStore.Domain/<Entity>s/<Criteria><Entity>Specification.cs`

```csharp
using System;
using System.Linq.Expressions;
using Volo.Abp.Specifications;

namespace Acme.BookStore.<Entity>s;

public class <Criteria><Entity>Specification : Specification<<Entity>>
{
    // Store constructor parameters for use in the expression
    private readonly /* criteria type */ _criteria;

    public <Criteria><Entity>Specification(/* criteria parameter */)
    {
        _criteria = /* parameter */;
    }

    public override Expression<Func<<Entity>, bool>> ToExpression()
    {
        // Return a lambda expression that encodes the filtering rule
        return entity => /* filtering condition using _criteria */;
    }
}
```

**Example — filtering active products below a price threshold:**
```csharp
public class AffordableActiveProductSpecification : Specification<Product>
{
    private readonly decimal _maxPrice;

    public AffordableActiveProductSpecification(decimal maxPrice)
    {
        _maxPrice = maxPrice;
    }

    public override Expression<Func<Product, bool>> ToExpression()
        => product => product.IsActive && product.Price <= _maxPrice;
}
```

### Using specifications in a repository

Specifications can be passed directly to `IReadOnlyRepository` methods:

```csharp
// In an application service or domain service:
var spec = new <Criteria><Entity>Specification(/* args */);

// Check in-memory
bool matches = spec.IsSatisfiedBy(entity);

// Use with repository (IReadOnlyRepository supports ISpecification<T>)
var items = await _<entity>Repository.GetListAsync(spec);
```

### Combining specifications

```csharp
var combined = spec1.And(spec2);     // both must match
var either   = spec1.Or(spec2);      // at least one must match
var negated  = spec1.Not();          // invert
```

---

## After generating

Ask the user:
1. Do you want to **register this specification for use inside the repository** (add a query method that accepts it)?
2. Should I create **more specifications** for other filtering scenarios for this entity?
