# Caskly Windows Build Guide

This project cannot be built into a Windows `.exe` from macOS.
The Windows release build must be created on a Windows machine.

## 1. Install prerequisites on Windows

Install these first:

- Flutter SDK
- Visual Studio 2022

Inside Visual Studio Installer, enable:

- `Desktop development with C++`

Then verify setup:

```bash
flutter doctor
```

Make sure Flutter reports Windows desktop support as available.

## 2. Open the project

Open a terminal in the project root:

```bash
Ruts
```

## 3. Get packages

```bash
flutter pub get
```

## 4. Enable Windows desktop

```bash
flutter config --enable-windows-desktop
```

## 5. Build release app

```bash
flutter build windows --release
```

## 6. Find the build output

The Windows app will be created here:

```bash
build\windows\x64\runner\Release\
```

Important:

- Do not send only the `.exe`
- Send the full `Release` folder
- The `.exe` depends on the DLLs and files beside it

## 7. Run the app

Inside the `Release` folder, launch:

```bash
pos_app.exe
```

If the app name is updated later in Windows runner settings, the `.exe` name may change.

## 8. Offline testing notes

This app now seeds starter offline data on first run:

- starter suppliers
- starter materials
- starter inventory stock

So on first launch, the app should not open empty even without internet.

## 9. Recommended test flow

1. Launch the app fully offline.
2. Confirm Material Master has starter records.
3. Confirm Supplier Master has starter records.
4. Confirm Inventory shows stock on hand.
5. Create an offline sale.
6. Create an offline purchase.
7. Reopen the app and confirm local data is still there.

