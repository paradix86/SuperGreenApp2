# SuperGreenLab App

The mobile and web app for management of [SuperGreenLab] builds.

## End-User Usage

This application is not yet ready for end-user usage.

## Developing

### Prerequisites

- [`flutter`] 3.7.12 (Dart 2.19.x)
- Android Studio + Android SDK (for Android builds)
- Xcode (for iOS builds on macOS)

This repository contains an `.fvmrc` file to pin the Flutter version.
If you use `fvm`, run commands with `fvm flutter ...`.

### First-time setup

1. Create local environment file:

```shell
cp .env.example .env
# Windows PowerShell alternative:
Copy-Item .env.example .env
```

2. Fill required values in `.env`:
- `RECAPTCHA_KEY`
- `SKIP_CAPTCHA_TOKEN`

3. Add Firebase config files (not committed):
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

4. Install dependencies and generate code:

```shell
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Bootstrap scripts

If you prefer, run:

- PowerShell: `./tools/bootstrap.ps1`
- Bash: `./tools/bootstrap.sh`

### Running the app on a connected mobile device

1. Plug in your device
    - Verify that flutter can find it by running `flutter devices`
    - The device ID may look something like `0GA36TEX9A`
2. Execute `flutter run`
    - You may need to run it like `flutter run -d 0GA36TEX9A`

### Running the app in a web browser (experimental)

From the root of this repository run the following command.

```shell
$ flutter run -d web-server # web-server is the (virtual) device's ID
```

This should (if not, please reach out to us on [Discord]) print something
similar to the following.

```
Launching lib/main.dart on Web Server in debug mode...
Building application for the web...                                 9.1s
lib/main.dart is being served at http://localhost:50901/

Warning: Flutter's support for web development is not stable yet and hasn't
been thoroughly tested in production environments.
For more information see https://flutter.dev/web
```

In a web browser navigate to `http://localhost:50901` (or whatever URL is printed).

You should now see the app.

[SuperGreenLab]: https://www.supergreenlab.com/
[`flutter`]: https://flutter.dev/
[Discord]: https://discord.gg/crdYzgy
