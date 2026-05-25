# Agent Instructions

## Android APK build and upload

Use these steps when asked to compile the Android APK and make it downloadable.

1. Configure the Android SDK if this cloud machine does not already have one:
   - Download Android command-line tools from `https://developer.android.com/studio`.
   - Install them under `$HOME/android-sdk/cmdline-tools/latest`.
   - Install the Flutter-required SDK packages:
     - `platform-tools`
     - `platforms;android-36`
     - `build-tools;36.0.0`
     - `ndk;28.2.13676358`
     - `cmake;3.22.1`
   - Export:
     - `ANDROID_HOME=$HOME/android-sdk`
     - `ANDROID_SDK_ROOT=$HOME/android-sdk`
     - `PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH`
   - Run `yes | sdkmanager --licenses`.
   - Run `flutter config --android-sdk "$ANDROID_HOME"`.

2. Build the release APK from the repository root:
   - `flutter pub get`
   - `flutter build apk --release`

3. Copy the generated APK into Cursor artifacts:
   - `cp build/app/outputs/flutter-apk/app-release.apk /opt/cursor/artifacts/tuna-release-$(date +%Y%m%d).apk`

4. Upload the APK to a temporary external host when the user needs a public download URL:
   - `curl --fail --show-error --silent -F "file=@/opt/cursor/artifacts/<apk-name>.apk" "https://tmpfiles.org/api/v1/upload"`
   - Convert the returned URL from `https://tmpfiles.org/<id>/<apk-name>.apk` to `https://tmpfiles.org/dl/<id>/<apk-name>.apk`.
   - Verify the download URL with `curl --fail --show-error --silent --head "https://tmpfiles.org/dl/<id>/<apk-name>.apk"`.
   - Include the verified download URL and `sha256sum /opt/cursor/artifacts/<apk-name>.apk` in the response.

If `tmpfiles.org` is unavailable, use another temporary file host and verify the returned URL before sharing it.
