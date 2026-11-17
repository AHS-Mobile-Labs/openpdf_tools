#!/usr/bin/env python3
import sys
import os

def generate_release_notes(version, artifact_dir="artifacts"):
    tag = f"v{version}" if not version.startswith("v") else version
    clean_version = version.lstrip("v")

    files = os.listdir(artifact_dir) if os.path.exists(artifact_dir) else []
    
    def find_file(ext):
        for f in files:
            if ext in f.lower():
                return f
        return None

    apk = find_file(".apk")
    aab = find_file(".aab")
    win = find_file("windows.zip") or find_file("win.zip")
    linux = find_file("linux.tar.gz")
    macos = find_file("macos.zip")
    ios = find_file("ios-unsigned.zip") or find_file("ios.zip")
    web = find_file("web.zip")

    notes = []
    notes.append(f"# OpenPDF Tools {tag}\n")
    notes.append("Welcome to the official multi-platform release of **OpenPDF Tools**.\n")
    notes.append("OpenPDF Tools is a high-performance, 100% offline, privacy-focused PDF suite for desktop, mobile, and web.\n")
    notes.append("### ✨ Key Features in this Release")
    notes.append("- **Continuous PDF Scrolling**: Seamless vertical document reading experience with synchronized page indicators.")
    notes.append("- **Multi-Platform Native Builds**: Standalone packages for Android, Windows, Linux, macOS, iOS, and Web.")
    notes.append("- **Complete PDF Toolkit**: Merge, split, compress, edit annotations, convert to/from PDF, cryptographic PKCS#7 signing, and repair damaged files.")
    notes.append("- **100% Client-Side**: No cloud servers, no trackers, zero data leakage.\n")

    notes.append("### 📦 Available Platform Packages\n")
    notes.append("| Platform | Format | Distribution Status | File Name |")
    notes.append("| :--- | :--- | :--- | :--- |")
    
    if apk:
        notes.append(f"| **Android** | Release APK | ✅ Sideload Ready | `{apk}` |")
    else:
        notes.append("| **Android** | Release APK | ❌ Unavailable | - |")

    if aab:
        notes.append(f"| **Android** | App Bundle (AAB) | 📦 Play Store Ready | `{aab}` |")

    if win:
        notes.append(f"| **Windows** | ZIP (Portable 64-bit) | ✅ Standalone Executable | `{win}` |")
    else:
        notes.append("| **Windows** | ZIP (64-bit) | ❌ Unavailable | - |")

    if linux:
        notes.append(f"| **Linux** | TAR.GZ (x86_64) | ✅ Portable Bundle | `{linux}` |")
    else:
        notes.append("| **Linux** | TAR.GZ | ❌ Unavailable | - |")

    if macos:
        notes.append(f"| **macOS** | ZIP App Bundle | ⚠️ Unnotarized App | `{macos}` |")
    else:
        notes.append("| **macOS** | App Bundle | ❌ Unavailable | - |")

    if ios:
        notes.append(f"| **iOS** | Archive (Unsigned) | ⚠️ Signing Required | `{ios}` |")
    else:
        notes.append("| **iOS** | Archive | ⚠️ Apple Certificate Required | - |")

    if web:
        notes.append(f"| **Web** | Static Web Build | 🌐 [Live Web App](https://ahs-mobile-labs.github.io/openpdf_tools/) | `{web}` |")
    else:
        notes.append("| **Web** | Web App | 🌐 [Live Web App](https://ahs-mobile-labs.github.io/openpdf_tools/) | - |")

    notes.append("\n### 🔐 Verification & Installation Notes")
    notes.append("- **Android**: Direct installation from APK requires granting browser/file manager permission to install unknown apps.")
    notes.append("- **macOS**: On first launch, macOS Gatekeeper may warn about unnotarized binaries. Right-click the `.app` bundle and click *Open*, or allow in *System Settings > Privacy & Security*.")
    notes.append("- **Linux**: Extract with `tar -xzf <archive>` and execute `./openpdf_tools`.")
    notes.append("- **iOS**: iOS builds are unsigned in CI and require Apple Developer signing or sideloading tools (AltStore/Sideloadly) for installation.")
    notes.append("- **Web**: Access directly at [https://ahs-mobile-labs.github.io/openpdf_tools/](https://ahs-mobile-labs.github.io/openpdf_tools/).")

    return "\n".join(notes)

if __name__ == "__main__":
    ver = sys.argv[1] if len(sys.argv) > 1 else "1.0.0"
    art_dir = sys.argv[2] if len(sys.argv) > 2 else "artifacts"
    output = generate_release_notes(ver, art_dir)
    print(output)
