# OpenPDF Tools

Fast, open-source PDF management for all platforms. View, convert, compress, merge, split, and digitally sign PDFs.

**Flutter 3.10.7+ | Dart | 50+ formats | 6 platforms**

🌐 **Web Demo**: [https://ahs-mobile-labs.github.io/openpdf_tools/](https://ahs-mobile-labs.github.io/openpdf_tools/)

## Features

- 📄 **Viewer** - View & password-protected PDFs
- 📦 **Compress** - Reduce file size
- 🖼️ **Image to PDF** - JPG, PNG, WEBP, HEIC, TIFF, GIF, BMP
- 🔄 **Convert** - To 13+ formats
- ✏️ **Edit** - Add text & annotations
- 🔗 **Merge** - Combine PDFs
- ✂️ **Split** - Extract pages
- 🔐 **Sign** - Digital signatures
- 📋 **History** - Recent files & favorites

## Platforms

| Android | iOS | macOS | Linux | Windows | Web |
|---------|-----|-------|-------|---------|-----|
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Quick Start

```bash
git clone https://github.com/AHS-Mobile-Labs/openpdf_tools.git
cd openpdf_tools
flutter pub get
flutter run
```

### Build

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Desktop
flutter build linux --release
flutter build windows --release
flutter build macos --release

# Web (Local)
flutter build web --release

# Web (GitHub Pages release build)
flutter build web --release --base-href "/openpdf_tools/"
touch build/web/.nojekyll
cp build/web/index.html build/web/404.html
```

### GitHub Pages Deployment

The web app is configured with automated CI/CD via GitHub Actions:
- **Workflow**: Automated build and deployment on push to `main` via [.github/workflows/deploy-pages.yml](.github/workflows/deploy-pages.yml).
- **SPA Routing**: Automatically includes `404.html` fallback and `.nojekyll` bypass.
- **Fast Loader**: Lightweight CSS preloader in `web/index.html` with graceful handoff to Flutter.
- **Manual Deployment Script**: `./scripts/deploy_gh_pages.sh`


## Star History

<a href="https://www.star-history.com/?repos=AHS-Mobile-Labs%2Fopenpdf_tools&type=date&legend=bottom-right">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=AHS-Mobile-Labs/openpdf_tools&type=date&theme=dark&legend=bottom-right" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=AHS-Mobile-Labs/openpdf_tools&type=date&legend=bottom-right" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=AHS-Mobile-Labs/openpdf_tools&type=date&legend=bottom-right" />
 </picture>
</a>

## Contributing

Fork → Create branch → Commit → Push → Pull request

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)

## Author

[Ameer Hamza Saifi](https://github.com/ameerhamzasaifi)

© 2026 AHS Mobile Labs
