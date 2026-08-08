# Orbit Clash MatchSim 100

Android-ready Godot 4 project for a vertical physics auto-battle game inspired by short-form "which fighter wins?" simulation videos.

Current Android test build:

- App label: `Orbit Clash MatchSim 100`
- Package: `com.orbitclash.matchsim100`
- Version: `1.0.2-matchsim102`
- Version code: `102`
- APK filename: `orbit-clash-matchsim100-v102.apk`
- On-screen marker: `BUILD 102 | com.orbitclash.matchsim100 | v1.0.2`

## Included
- 8 original fighters with different rule-changing mechanics.
- Physics movement, wall bounces, rotating melee weapons and knockback.
- Persistent gates, projectiles, AoE zones, scaling passives, crits, freeze, weapon growth and radial volleys.
- Live HP/stat/ability UI, countdown, pause, 1x/2x/4x speed, random matchup, rematch.
- Original synthesized SFX: hit, crit, wall, ability, freeze, gate, projectile, start and victory.
- Android export preset prepared for arm64, portrait, immersive mode.
- Fixed-step battle simulation for stable collisions at 1x, 2x and 4x speed.

## Open and test
1. Install Godot 4.2+.
2. Open this folder by selecting `project.godot`.
3. Press F6/F5 to test.

## Build APK
Godot still needs its Android export templates and Android SDK/JDK configured on the machine doing the build.
After that: Project > Export > Android Debug > Export Project.
The preset points to `builds/orbit-clash-matchsim100-v102.apk`.

CLI after Android tooling is configured:
`godot --headless --path . --export-debug "Android Debug" builds/orbit-clash-matchsim100-v102.apk`

## Download APK from GitHub Actions
Every push to `main` starts the **Build Android APK** workflow. You can also run it manually from the Actions tab using **Run workflow**.

1. Open the latest successful **Build Android APK** run.
2. Scroll to the **Artifacts** section.
3. Download `orbit-clash-matchsim100-v102-android-debug`.
4. Extract the ZIP.
5. Install `orbit-clash-matchsim100-v102.apk` on an Android device.
6. Open the app named `Orbit Clash MatchSim 100`.

The artifact ZIP also includes:

- `APK_BADGING.txt` — manifest proof from `aapt dump badging`.
- `SHA256SUMS.txt` — checksum for the APK.
- `INSTALL_THIS_APK.txt` — short install instructions.

If the screen says `ORBIT CLASH LOADING ARENA`, that is an old package/build. The current app must show the permanent marker `BUILD 102 | com.orbitclash.matchsim100 | v1.0.2`.

See [INSTALL_ANDROID.md](INSTALL_ANDROID.md) for clean-install steps and old package names to remove.

Android may ask you to allow installation from your browser or file manager. This artifact uses a debug signing key and is intended for testing only.

## Play Store
For Google Play, create a release Android preset using AAB, set your final package id/version, and sign it with your release keystore. Do not publish with a debug signing key.

## Note
Visuals, fighter names, audio and gameplay code here are original placeholder content intended to establish the engine and feel. Replace/polish art and balancing before a store release.
