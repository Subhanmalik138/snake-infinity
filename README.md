# Snake Infinity: 3D Adventure

A complete, fully functional Android Snake game. Portrait 9:16, offline, no ads, no unnecessary permissions.

**App ID:** `com.snakeinfinity.snake_infinity` — **Version:** 1.0.0+1

## Features
- **4 modes:** Classic, Adventure (unlimited procedural levels), Endless, Time Attack (90s)
- **Unlimited levels:** procedurally generated per level — new themes, obstacles, speed and objectives. Every level is checked for reachability (BFS) so it stays fair and completable. Objectives rotate: eat X foods / reach X score / survive X seconds.
- **Foods:** Apple 10, Banana 15, Cherry 20, Grape 25, timed Coin 50, timed Star 100
- **Power-ups:** Speed Boost, Slow Motion, Shield (blocks one collision), Magnet, Double Score, Ghost Mode (passes through walls + obstacles)
- **Controls:** Swipe (default), on-screen D-Pad, virtual joystick — switchable in-game and on Home. Reverse-direction input is ignored, so you can never accidentally reverse into yourself.
- **Animations:** interpolated smooth snake movement, glowing 3D-style body, head with eyes, pulsing foods, particle bursts on eating, power-up halos, level/game-over celebrations.
- **Sound:** background music loop + eat / bonus / power-up / level-complete / game-over sounds. Music and SFX can be muted independently. Vibration toggle.
- **Saving:** best scores per mode, unlocked adventure level, total games/foods/score, longest snake — saved automatically with SharedPreferences.
- **Pause / restart / resume, level selection screen, game-over and level-complete screens.**

## Install the APK on your phone
1. Download the APK from the GitHub release (link in chat).
2. Tap the downloaded file. If Android asks about installing from an unknown source, allow it for your browser/Files app — this is normal for apps outside the Play Store.
3. Tap Install, then Open. No account, no internet needed.

## Build a new APK from source
Requirements: Flutter 3.24.5, Java 17, Android SDK.

```bash
flutter pub get
flutter analyze
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

Or push to `main` — GitHub Actions builds and publishes the APK as a release automatically (see `.github/workflows/build-apk.yml`).

## Project layout
- `lib/main.dart` — app entry, portrait lock, immersive fullscreen
- `lib/models.dart` — modes, foods, power-ups, themes, level specs
- `lib/engine.dart` — pure game logic: movement, collisions, obstacles, objectives, fairness check
- `lib/painter.dart` — Canvas rendering: glowing snake, arena, particles, foods
- `lib/screens.dart` — Home, Level Selection, Game screen, controls, overlays
- `lib/sound.dart` — music + SFX (just_audio, generated WAVs in `assets/sounds/`)
- `lib/storage.dart` — SharedPreferences save data
