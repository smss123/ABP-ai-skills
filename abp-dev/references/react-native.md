# ABP: React Native Mobile UI

> 📖 Official docs: https://abp.io/docs/latest/framework/ui/react-native
>
> Fetch this page for the latest API details before generating React Native code.
>
> **License requirement:** Team tier or higher.

---

## Overview

ABP's React Native template is built on **Expo** and ships with authentication, multi-tenancy, localization, and permission wiring pre-configured. It targets the same ABP backend as the web UI.

---

## Prerequisites

- Node.js v20.11+
- Yarn v1 (`npm install -g yarn`)
- Expo CLI (bundled via `yarn`)
- Android Studio (Android emulator) or Xcode (iOS simulator) for device testing

---

## Project Creation

```bash
# CLI — MVC or Angular backend, with React Native mobile app
abp new MyCompanyName.MyProjectName -csf -u mvc -m react-native
# or
abp new MyCompanyName.MyProjectName -csf -u angular -m react-native
```

Or use **ABP Studio** (recommended) and tick the React Native option.

The mobile project is placed in the `react-native/` folder of the solution.

---

## Running the App

### Quick test — web browser

```bash
cd react-native
yarn
yarn web
```

Generate local SSL certificates first:
```bash
mkcert localhost
yarn create:local-proxy
```

### Emulator / simulator

```bash
yarn start   # launches Expo CLI
# press 'a' → Android Studio  |  scan QR → physical device
```

> **Replace `localhost`** with your machine's local IP address in `Environment.ts` when running on a device or emulator — `localhost` resolves to the device itself, not the host machine.

---

## Environment Configuration (`Environment.ts`)

```typescript
// react-native/src/environments/environment.ts
export const environment = {
  production: false,
  apiUrl: 'http://192.168.1.100:44323',   // your machine's IP
  issuer: 'http://192.168.1.100:44323',   // OpenIddict issuer
};
```

Also update `OpenIddict.Applications.MyApplication_Mobile.RootUrl` in `.DbMigrator/appsettings.json` to match.

---

## Backend Configuration for Emulator/Simulator

React Native does **not** trust auto-generated .NET HTTPS certificates. Use HTTP during development.

### Disable HTTPS requirement (DEBUG only)

```csharp
// HttpApiHostModule.cs
public override void PreConfigureServices(ServiceConfigurationContext context)
{
#if DEBUG
    PreConfigure<OpenIddictServerBuilder>(options =>
    {
        options.UseAspNetCore()
               .DisableTransportSecurityRequirement();
    });
#endif
}
```

### Expose HTTP endpoint (`appsettings.Development.json`)

```json
{
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:44323"
      }
    }
  }
}
```

---

## Authentication

The mobile client uses OpenIddict with a dedicated application entry. Ensure it is seeded in `.DbMigrator/appsettings.json`:

```json
{
  "OpenIddict": {
    "Applications": {
      "MyApplication_Mobile": {
        "ClientId": "MyApplication_Mobile",
        "RootUrl": "https://localhost"
      }
    }
  }
}
```

Default dev credentials: `admin` / `1q2w3E*`

---

## Key Rules

- **DO** use `http://` (not `https://`) for backend API calls in dev when testing on emulators/devices — React Native rejects self-signed .NET certs
- **DO** wrap the `DisableTransportSecurityRequirement()` call in `#if DEBUG` — never disable it in production
- **DO** set both `apiUrl` and `issuer` in `Environment.ts` to the same host IP when using a physical device or emulator
- **DO NOT** use `localhost` as the API URL in emulator/simulator builds — it resolves to the device, not the host machine
- **DO** update `RootUrl` in `.DbMigrator/appsettings.json` whenever the host IP changes
