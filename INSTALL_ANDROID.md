# Install the current Android test build

Use this file when the phone still opens an old `ORBIT CLASH LOADING ARENA` screen.

## Current build

- Install APK: `orbit-clash-matchsim100-v102.apk`
- App name on Android: `Orbit Clash MatchSim 100`
- Package: `com.orbitclash.matchsim100`
- Version: `1.0.2-matchsim102`
- Version code: `102`
- Permanent in-game marker: `BUILD 102 | com.orbitclash.matchsim100 | v1.0.2`

## Old packages to remove

If the phone still opens a loading screen, uninstall these older packages/apps if they exist:

- `com.orbitclash.game`
- `com.orbitclash.direct`

The current build is a different package:

- `com.orbitclash.matchsim100`

## Clean install steps

1. On Android, uninstall old Orbit Clash apps if visible.
2. Download the latest GitHub Actions artifact named `orbit-clash-matchsim100-v102-android-debug`.
3. Extract the ZIP.
4. Install exactly `orbit-clash-matchsim100-v102.apk`.
5. Open `Orbit Clash MatchSim 100`.
6. Confirm the screen shows `BUILD 102 | com.orbitclash.matchsim100 | v1.0.2`.

## ADB cleanup, optional

If ADB is available, run:

```sh
adb uninstall com.orbitclash.game
adb uninstall com.orbitclash.direct
adb install -r orbit-clash-matchsim100-v102.apk
```

If Android says one of the old packages is not installed, that is fine.
