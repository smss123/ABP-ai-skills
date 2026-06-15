# ABP: SignalR Real-Time Communication

> 📖 Official docs:
> - ABP SignalR Integration: https://abp.io/docs/latest/framework/real-time/signalr
> - Microsoft SignalR: https://docs.microsoft.com/en-us/aspnet/core/signalr/introduction
>
> Fetch these pages for the latest API details before generating SignalR code.

## Installation

```bash
# Server-side
abp add-package Volo.Abp.AspNetCore.SignalR

# Client-side (npm)
npm install @abp/signalr
```

Add the module dependency:

```csharp
[DependsOn(typeof(AbpAspNetCoreSignalRModule))]
public class BookStoreWebModule : AbpModule { }
```

---

## Defining a Hub

Derive from `AbpHub` (or `AbpHub<T>` for typed clients) to get ABP integration: `CurrentUser`, localization (`L`), logging, DI.

```csharp
// Web/Hubs/MessagingHub.cs
using Volo.Abp.AspNetCore.SignalR;

namespace Acme.BookStore.Web.Hubs;

public class MessagingHub : AbpHub
{
    public async Task SendMessage(string targetUserName, string message)
    {
        var senderName = CurrentUser.UserName;

        await Clients.All.SendAsync("ReceiveMessage", new
        {
            Sender  = senderName,
            Message = message,
            Time    = DateTime.UtcNow
        });
    }

    public async Task SendToUser(string targetConnectionId, string message)
    {
        await Clients.Client(targetConnectionId)
            .SendAsync("ReceiveMessage", new { Message = message });
    }
}
```

ABP auto-discovers hubs and maps them to `/signalr-hubs/{hub-name-kebab-case}`.
`MessagingHub` → `/signalr-hubs/messaging`

---

## Custom Hub Route

```csharp
[HubRoute("/my-custom-route")]
public class MessagingHub : AbpHub { }
```

---

## Manual Hub Configuration (full control)

```csharp
Configure<AbpSignalROptions>(options =>
{
    options.Hubs.AddOrUpdate(
        typeof(MessagingHub),
        config =>
        {
            config.RoutePattern = "/hubs/messaging";
            config.ConfigureActions.Add(hubOptions =>
            {
                hubOptions.ClientTimeoutInterval = TimeSpan.FromSeconds(60);
                hubOptions.KeepAliveInterval     = TimeSpan.FromSeconds(15);
            });
        }
    );
});
```

---

## Skipping Auto-Registration

```csharp
[DisableConventionalRegistration] // skip DI auto-register
[DisableAutoHubMap]               // skip auto endpoint mapping
public class ManualHub : AbpHub { }
```

---

## Client-Side Integration (MVC/Razor Pages)

### Include the SignalR script bundle

```html
@section scripts {
    <abp-script type="typeof(SignalRBrowserScriptContributor)" />
}
```

### Connect in JavaScript

```javascript
var connection = new signalR.HubConnectionBuilder()
    .withUrl('/signalr-hubs/messaging')
    .withAutomaticReconnect()
    .build();

connection.on('ReceiveMessage', function(payload) {
    console.log(payload.sender + ': ' + payload.message);
});

connection.start().catch(function(err) {
    console.error(err);
});

// Send
$('#sendBtn').on('click', function() {
    connection.invoke('SendMessage', 'targetUser', $('#message').val());
});
```

---

## Authorization on Hubs

```csharp
[Authorize]
public class MessagingHub : AbpHub
{
    [Authorize(MyPermissions.SendMessages)]
    public async Task SendMessage(string message) { }
}
```

---

## User Identity Integration

ABP automatically wires `ICurrentUser` via `AbpSignalRUserIdProvider`. Use `CurrentUser.Id`, `CurrentUser.UserName`, and `CurrentUser.IsAuthenticated` directly inside hub methods.

---

## Sending from Outside the Hub (Server Push)

```csharp
public class OrderAppService : ApplicationService
{
    private readonly IHubContext<MessagingHub> _hubContext;

    public OrderAppService(IHubContext<MessagingHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public async Task PlaceOrderAsync(CreateOrderDto input)
    {
        // ... create order ...

        // Push notification to all clients
        await _hubContext.Clients.All
            .SendAsync("OrderPlaced", new { OrderId = order.Id });
    }
}
```

---

## Key Rules

- **DO** derive from `AbpHub` — it provides `CurrentUser`, localization, and proper DI lifecycle
- **DO** use `withAutomaticReconnect()` on the client to handle transient disconnections
- **DO** resolve scoped services via constructor injection (hub lifetime is scoped per connection)
- **DO NOT** store long-lived state in hub fields — hubs are instantiated per request
- **DO NOT** call hub methods directly in domain services — use `IHubContext<T>` for server-push scenarios
