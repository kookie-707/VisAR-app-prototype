# Quick Setup Guide

## Step 1: Verify Flutter Installation

Open a **new** terminal/PowerShell window and run:

```bash
flutter --version
```

If Flutter is not found, you may need to:
1. Restart your terminal/IDE after installing Flutter
2. Add Flutter to your system PATH
3. Verify Flutter installation: https://docs.flutter.dev/get-started/install/windows

## Step 2: Initialize Flutter Project

Once Flutter is available, navigate to this directory and run:

```bash
cd "c:\Users\HP\OneDrive\Desktop\VisAR app"
flutter create . --org com.visar --platforms android,ios
```

This will generate the Android and iOS platform folders.

## Step 3: Install Dependencies

```bash
flutter pub get
```

## Step 4: Run the App

### For Android:
```bash
flutter run
```
(Make sure you have an Android emulator running or a device connected)

### For iOS (Mac only):
```bash
flutter run
```
(Make sure you have Xcode installed and an iOS simulator/device)

## Troubleshooting

- **Flutter not found**: Restart your terminal or add Flutter to PATH
- **Platform folders missing**: Run `flutter create .` in the project directory
- **Dependencies error**: Run `flutter pub get` again
- **Build errors**: Run `flutter clean` then `flutter pub get`

## Next Steps

Once the app is running, you can:
- Test the connection toggle on the Home screen
- Customize HUD elements in the HUD screen
- View analytics in the Profile screen

For production, you'll need to:
- Add Bluetooth connectivity
- Implement real data streaming
- Add data persistence
- Configure app signing for release builds
