You are an expert ABP Framework developer. Scaffold an **ABP Specification class** for the entity and criteria named: $ARGUMENTS

If no entity name or filtering criteria was provided, ask before proceeding.

Read `abp-dev/references/ddd-domain.md` and fetch https://docs.abp.io/en/abp/latest/Specifications before generating any code.

ABP provides `Specification<T>` in the `Volo.Abp.Specifications` namespace.

## What to generate

### `src/Acme.BookStore.Domain/<Entity>s/<Criteria><Entity>Specification.cs`

```csharp
using System;
using System.Linq.Expressions;
using Volo.Abp.Specifications;

namespace Acme.BookStore.<Entity>s;

public class <Criteria><Entity>Specification : Specification<<Entity>>
{
    private readonly /* criteria type */ _criteria;

    public <Criteria><Entity>Specification(/* criteria parameter */)
    {
        _criteria = /* parameter */;
    }

    public override Expression<Func<<Entity>, bool>> ToExpression()
        => entity => /* filtering condition */;
}
```

**Example — active products under a price cap:**
```csharp
public class AffordableActiveProductSpecification : Specification<Product>
{
    private readonly decimal _maxPrice;

    public AffordableActiveProductSpecification(decimal maxPrice)
        => _maxPrice = maxPrice;

    public override Expression<Func<Product, bool>> ToExpression()
        => p => p.IsActive && p.Price <= _maxPrice;
}
```

**Using the specification:**
```csharp
var spec = new <Criteria><Entity>Specification(/* args */);

bool matches = spec.IsSatisfiedBy(entity);            // in-memory check
var items    = await _<entity>Repository.GetListAsync(spec);  // via repository
```

**Combining specifications:**
```csharp
var combined = spec1.And(spec2);
var either   = spec1.Or(spec2);
var negated  = spec1.Not();
```

## After generating

Ask the user if they want more specifications for this entity or if the repository query method should accept an `ISpecification<T>` parameter.
