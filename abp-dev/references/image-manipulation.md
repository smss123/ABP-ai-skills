# ABP: Image Manipulation

> 📖 Official docs: https://abp.io/docs/latest/framework/infrastructure/image-manipulation
>
> Fetch this page for the latest API details before generating image processing code.

---

## Overview

ABP provides provider-agnostic image compression and resizing via `IImageCompressor` and `IImageResizer`. Swap the underlying library (ImageSharp, Magick.NET, SkiaSharp) without changing application code.

---

## Install a Provider

```bash
# Choose one:
abp add-package Volo.Abp.Imaging.ImageSharp    # recommended for most apps
abp add-package Volo.Abp.Imaging.MagickNet
abp add-package Volo.Abp.Imaging.SkiaSharp
```

Add the corresponding module to `[DependsOn]` in your web/application module.

---

## Compressing Images

```csharp
public class ProductAppService : ApplicationService
{
    private readonly IImageCompressor _imageCompressor;

    public ProductAppService(IImageCompressor imageCompressor)
    {
        _imageCompressor = imageCompressor;
    }

    public async Task UploadAsync(IFormFile file)
    {
        await using var stream = file.OpenReadStream();

        var result = await _imageCompressor.CompressAsync(stream, file.ContentType);

        if (result.State == ImageProcessState.Done)
        {
            // use result.Result (Stream) — compressed image
        }
    }
}
```

`ImageProcessState` values: `Done`, `Canceled`, `Unsupported`.

---

## Resizing Images

```csharp
var resizeArgs = new ImageResizeArgs
{
    Width  = 800,
    Height = 600,
    Mode   = ImageResizeMode.Crop  // Crop | Pad | Stretch | None
};

var result = await _imageResizer.ResizeAsync(stream, resizeArgs, mimeType: "image/jpeg");

if (result.State == ImageProcessState.Done)
{
    // use result.Result (Stream) — resized image
}
```

Both `IImageCompressor` and `IImageResizer` accept either `Stream` or `byte[]` input.

> **Always check `result.State` before using `result.Result`** — stream may be incomplete on `Canceled` or `Unsupported`.

---

## ASP.NET Core Action Attributes

Automatically compress or resize files uploaded via controller actions:

```csharp
[HttpPost]
[CompressImage]
public async Task<IActionResult> Upload(IFormFile file) { /* ... */ }

[HttpPost]
[ResizeImage(Width = 1200, Height = 800)]
public async Task<IActionResult> UploadBanner(IFormFile file) { /* ... */ }
```

Works with `IFormFile` and stream parameters.

---

## Provider Configuration

### ImageSharp

```csharp
Configure<AbpImageSharpCompressOptions>(options =>
{
    options.DefaultQuality = 80; // 0-100, default 75
});
```

### Magick.NET

```csharp
Configure<AbpMagickNetCompressOptions>(options =>
{
    options.OptimalCompression     = true;
    options.IgnoreUnsupportedFormats = true;
    options.Lossless               = false;
});
```

### SkiaSharp

```csharp
Configure<AbpSkiaSharpCompressOptions>(options =>
{
    options.Quality = 85; // 0-100, default 75
});
```

---

## Key Rules

- **DO** check `result.State == ImageProcessState.Done` before consuming the result stream
- **DO** use `[CompressImage]` / `[ResizeImage]` attributes on upload endpoints to keep app service code clean
- **DO NOT** assume all image formats are supported — use `IgnoreUnsupportedFormats` (Magick.NET) or handle `Unsupported` state
- **DO** dispose streams after use — `result.Result` is a `Stream` that must be disposed
