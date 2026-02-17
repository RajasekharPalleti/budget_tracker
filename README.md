# Flutter Budget Tracker

## How to Run in Android Studio

1.  **Open Android Studio**.
2.  Select **Open** (or **File > Open**).
3.  Navigate to and select the project folder: `d:\budget_tracker`.
4.  **Wait for Sync**: Android Studio will detect the `pubspec.yaml` file and automatically run `flutter pub get`.
    *   If it doesn't, open `pubspec.yaml` and click **Pub get** in the top right corner of the editor window.
    *   Alternatively, open the **Terminal** tab at the bottom and run: `flutter pub get`.
5.  **Set up a Device**:
    *   Click on the **Device Manager** (phone icon in the toolbar).
    *   Create a virtual device (emulator) if you don't have one, or connect your physical Android device via USB (ensure USB Debugging is on).
6.  **Run the App**:
    *   Select your device in the toolbar dropdown.
    *   Click the green **Run** (Play) button (or press `Shift + F10`).

## Troubleshooting

*   **"Dart SDK is not configured"**: Go to **File > Settings > Languages & Frameworks > Dart** and set the path to your Dart SDK (usually inside the Flutter SDK folder).
*   **"Flutter SDK is not configured"**: Go to **File > Settings > Languages & Frameworks > Flutter** and set the path to your Flutter SDK.
*   **"Target of URI doesn't exist"**: Run `flutter pub get` again to download dependencies.

## How to Build APK (Android Package)
You can build a release APK using either the **Terminal** or the **Android Studio Menu**.

### Option 1: Using Terminal (Recommended)
1.  Open the **Terminal** tab at the bottom of Android Studio.
2.  Run the following command:
    ```bash
    flutter build apk --release
    ```
3.  The APK file will be generated at:
    `build/app/outputs/flutter-apk/app-release.apk`

### Option 2: Using Android Studio Menu
1.  Go to the top menu: **Build > Flutter > Build APK**.
2.  Wait for the build process to complete.
3.  A notification will appear with a "Locate" link to find the APK file.
