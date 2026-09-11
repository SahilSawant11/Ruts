# Caskly Windows Build & Distribution Guide

This guide explains how to build a **100% portable, zero-install Windows ZIP** that runs on any Windows machine without requiring the client to install Visual Studio or C++ runtimes, and how taskbar pinning works.

---

## Why Did the Client Need to Install Visual Studio / C++ Before?

Flutter Windows applications are compiled with Microsoft Visual C++ (MSVC). By default:
- The compiled executable (`pos_app.exe`) dynamically links to the **Microsoft Visual C++ Redistributable runtime DLLs** (`vcruntime140.dll`, `msvcp140.dll`, etc.).
- If a client's computer doesn't already have the Visual C++ Redistributable installed, Windows blocks the app with:
  > *"The code execution cannot proceed because VCRUNTIME140.dll was not found."*

### How We Fixed It:
Windows searches the local folder of the executable **first** before checking system folders.
Our build system and packager now bundle the required Microsoft C++ runtime DLLs (`vcruntime140.dll`, `vcruntime140_1.dll`, `msvcp140.dll`, etc.) **directly beside `pos_app.exe`**.
When your client unzips the folder and runs the app, Windows loads the bundled DLLs locally. **The client does not need to install anything!**

---

## 1. Prerequisites (On Windows Build Machine Only)

To build the project, you need a Windows machine with:
- **Flutter SDK**
- **Visual Studio 2022** with the **"Desktop development with C++"** workload checked

Verify with:
```powershell
flutter doctor
```
Ensure Windows desktop development is marked as ready.

---

## 2. One-Command Build & Package (Recommended)

Open PowerShell as Administrator or regular user, navigate to the `Ruts` directory, and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\package_windows.ps1
```

### What this script does automatically:
1. Runs `flutter build windows --release`.
2. Verifies and bundles all Microsoft Visual C++ Runtime DLLs (`msvcp140.dll`, `vcruntime140.dll`, etc.) directly into the release folder.
3. Adds a helper `Create_Desktop_Shortcut.bat` inside the release.
4. Packages everything into a ready-to-share portable ZIP:
   ```text
   build\dist\Caskly_POS_v0.1.0_Windows_Portable.zip
   ```
5. If [Inno Setup](https://jrsoftware.org/isdl.php) is installed, it also automatically creates a single-file setup installer:
   ```text
   build\windows\installer\Caskly_POS_Setup_v0.1.0.exe
   ```

---

## 3. How to Share with the Client

Simply send the generated ZIP:
```text
build\dist\Caskly_POS_v0.1.0_Windows_Portable.zip
```

### Instructions for the Client:
1. **Extract** the ZIP to any folder (e.g. `C:\Caskly POS` or Desktop).
2. Double-click **`pos_app.exe`** to run the app immediately.
   *(Or double-click `Create_Desktop_Shortcut.bat` to place a shortcut on their desktop).*
3. **Pin to Taskbar**:
   - While the app is running, **right-click the Caskly app icon on the Windows taskbar** at the bottom of the screen.
   - Click **"Pin to taskbar"**.
   - The icon is now permanently pinned to the taskbar and will always launch Caskly POS directly with the custom icon!

---

## 4. Manual Build (If not using the script)

If you prefer to build manually:

1. Enable Windows desktop:
   ```powershell
   flutter config --enable-windows-desktop
   ```
2. Get packages:
   ```powershell
   flutter pub get
   ```
3. Build release:
   ```powershell
   flutter build windows --release
   ```
4. Copy the MSVC CRT DLLs (`vcruntime140.dll`, `vcruntime140_1.dll`, `msvcp140.dll`, `msvcp140_1.dll`, `msvcp140_2.dll`) from:
   `C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Redist\MSVC\<version>\x64\Microsoft.VC143.CRT\`
   into:
   `build\windows\x64\runner\Release\`
5. Zip the entire `Release` folder.

---

## 5. Offline Testing Notes

This app seeds starter offline data on first run:
- starter suppliers
- starter materials
- starter inventory stock

So on first launch, the app should not open empty even without internet.

### Recommended test flow:
1. Launch the app fully offline.
2. Confirm Material Master has starter records.
3. Confirm Supplier Master has starter records.
4. Confirm Inventory shows stock on hand.
5. Create an offline sale.
6. Create an offline purchase.
7. Reopen the app and confirm local data is still there.
