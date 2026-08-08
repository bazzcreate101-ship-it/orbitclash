# Install the current Android test build

Use this file when the phone still opens an old `ORBIT CLASH LOADING ARENA` screen.

## Current build

- Main APK: `orbit-clash-matchsim100-v103.apk`
- App name on Android: `Orbit Clash MatchSim 100`
- Package: `com.orbitclash.matchsim100`
- Version: `1.0.3-matchsim103`
- Version code: `103`
- Permanent in-game marker: `BUILD 103 | multi-package fixed build | v1.0.3`

## APKs included in the artifact

The GitHub Actions artifact `orbit-clash-matchsim100-v103-plus-legacy-replacements` contains three installable APKs:

1. `orbit-clash-matchsim100-v103.apk`
   - New clean package: `com.orbitclash.matchsim100`
   - Open app: `Orbit Clash MatchSim 100`
2. `orbit-clash-replace-com-orbitclash-game-v103.apk`
   - Replaces old package: `com.orbitclash.game`
   - Use this if the old app icon still opens the loading screen.
3. `orbit-clash-replace-com-orbitclash-direct-v103.apk`
   - Replaces old package: `com.orbitclash.direct`
   - Use this if the old direct-build app icon still opens the loading screen.

## Clean install steps

1. Download the latest successful GitHub Actions artifact named `orbit-clash-matchsim100-v103-plus-legacy-replacements`.
2. Extract the ZIP.
3. Install `orbit-clash-matchsim100-v103.apk`.
4. Open `Orbit Clash MatchSim 100`.
5. Confirm the screen shows `BUILD 103 | multi-package fixed build | v1.0.3`.

If Android still opens `ORBIT CLASH LOADING ARENA`, install the matching replacement APK:

- For old `com.orbitclash.game`, install `orbit-clash-replace-com-orbitclash-game-v103.apk`.
- For old `com.orbitclash.direct`, install `orbit-clash-replace-com-orbitclash-direct-v103.apk`.

## ADB cleanup, optional

If ADB is available and you want a completely clean install:

```sh
adb uninstall com.orbitclash.game
adb uninstall com.orbitclash.direct
adb uninstall com.orbitclash.matchsim100
adb install -r orbit-clash-matchsim100-v103.apk
```

If Android says one of the packages is not installed, that is fine.
