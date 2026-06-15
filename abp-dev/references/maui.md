# ABP: .NET MAUI Mobile UI

> 📖 Official docs: https://abp.io/docs/latest/framework/ui/maui
>
> Fetch this page for the latest API details before generating MAUI code.

---

## Overview

ABP's MAUI template is a native cross-platform app (.NET MAUI) that authenticates against an ABP backend via OIDC and calls APIs through generated C# client proxies. It targets Android, iOS, macOS Catalyst, and Windows from a single codebase.

Ships with four ready-made pages: **Homepage**, **Users** (CRUD), **Tenants** (multi-tenant management), and **Settings** (language, profile picture, password, theme).

---

## Prerequisites

- .NET 9 SDK
- Visual Studio 2022+ (Windows) or VS for Mac / Rider (macOS)
- Android SDK / Android emulator **or** Xcode + iOS Simulator
- A running ABP backend (`HttpApi.Host` or `Web`/`BlazorServer`)

---

## Project Creation

Use ABP Studio (recommended) or CLI and select MAUI as the mobile UI option. The MAUI project is placed alongside the backend solution.

---

## Running the App

```bash
# Android emulator
dotnet build -t:Run -f net9.0-android

# iOS simulator
dotnet build -t:Run -f net9.0-ios

# Windows
dotnet build -t:Run -f net9.0-windows10.0.19041.0
```

Or launch directly from Visual Studio / Rider with the MAUI project as startup.

---

## Configuration (`appsettings.json`)

The MAUI project's own `appsettings.json` drives connection to the backend:

```json
{
  "AuthServer": {
    "Authority": "https://localhost:44305",
    "ClientId": "MyApp_Maui",
    "Scope": "openid profile offline_access MyApp"
  },
  "RemoteServices": {
    "Default": {
      "BaseUrl": "https://localhost:44305/"
    }
  }
}
```

Update `Authority` and `BaseUrl` to your backend host when testing on a physical device (use the machine's LAN IP, not `localhost`).

---

## Android Emulator — Port Forwarding

Android emulators cannot reach the host machine via `localhost`. Use ADB port forwarding **after the emulator starts**:

```bash
adb reverse tcp:44305 tcp:44305
```

Replace `44305` with your backend port. For tiered/microservice setups proxy each port separately:

```bash
adb reverse tcp:44305 tcp:44305   # API host
adb reverse tcp:44306 tcp:44306   # Auth server (if separate)
```

---

## iOS Simulator

iOS simulators can reach the host via `localhost` directly — no extra steps needed. For a physical iOS device, use the machine's LAN IP in `appsettings.json`.

---

## Authentication

The template uses OIDC with **Secure Storage** to persist access and refresh tokens between sessions. The OpenIddict client entry (`MyApp_Maui`) must be seeded in the backend — it is included in the default ABP template seed data.

---

## API Calls via C# Client Proxies

Inject the application service interface directly — ABP routes calls to the backend over HTTP using the generated static C# proxy:

```csharp
public class UsersViewModel : AbpViewModelBase
{
    private readonly IIdentityUserAppService _userAppService;

    public UsersViewModel(IIdentityUserAppService userAppService)
    {
        _userAppService = userAppService;
    }

    public async Task LoadUsersAsync()
    {
        var result = await _userAppService.GetListAsync(new GetIdentityUsersInput());
        // bind result to UI
    }
}
```

No manual `HttpClient` configuration is needed — proxy handles auth headers, tenant ID, culture, and correlation ID automatically.

---

## MVVM & Validation

Pages follow MVVM: each page has a corresponding `ViewModel` that inherits `AbpViewModelBase`. Validation uses `ValidatableObject<T>` with attached rules:

```csharp
public ValidatableObject<string> Email { get; } = new();

private void AddValidations()
{
    Email.Validations.Add(new IsNotNullOrEmptyRule<string>
        { ValidationMessage = "Email is required." });
}

bool IsValid() => Email.Validate();
```

---

## Key Rules

- **DO** use `adb reverse` for Android emulator — `localhost` in the emulator resolves to the device, not the host
- **DO** use LAN IP (not `localhost`) in `appsettings.json` when deploying to a physical device
- **DO** inject app service interfaces — never build `HttpClient` manually; proxies handle all ABP cross-cutting concerns
- **DO NOT** store tokens outside Secure Storage in production — never write access tokens to `Preferences` or plain files
- **DO** update the `ClientId` and `Scope` in `appsettings.json` to match the OpenIddict application entry seeded in the backend
