# 🎮 2048 Multiplayer & AI-Coached Capstone
### 🏆 Mobile Development Lab Final Exam Project

---

## 📝 Abstract
**2048 Multiplayer** is a feature-rich, low-latency, competitive adaptation of the classic 2048 puzzle game built with Flutter and backed by Firebase. This project turns a static, single-player mental puzzle into a fast-paced multiplayer arena. It features real-time grid and score synchronization, dynamic emote triggers, a custom matchmaking queue, and a private "Party Room" lobby system. Additionally, it integrates a context-aware **AI Coach** using the **Google Gemini SDK** to analyze the game board dynamically and guide the player toward the optimal swipe path.

---

## ✨ Key Features

* **🌐 Real-Time Multiplayer Mode:**
  * **Quick Match:** Join an active matchmaking queue and match against live opponents with options for custom durations (60s, 90s, 120s).
  * **Party Rooms:** Create private rooms, generate unique host codes, and invite friends to play in custom sessions.
  * **Local Match:** Split-screen mode allowing two players to compete head-to-head on the same local device.
  * **Dual-Board Streaming:** View your opponent's grid live through a scaled secondary display on your screen, syncing boards at under 50ms intervals.
* **🤖 Gemini AI Coach:** Scan your 4x4 matrix and receive live, strategic swipe tips and board analysis powered by Google's generative AI models.
* **🔑 Robust Security & Auth:** Secure email/password login and persistent sessions integrated with official **Google Sign-In**.
* **🛒 Cosmetic Custom Shop:** Spend in-game coins accumulated from match victories to unlock custom board skins, premium tile themes, and visual enhancements.
* **🏆 Social Systems:** Global leaderboards based on XP and high scores, combined with a **Friends List** showing active online statuses.
* **🎨 Premium UI/UX:** Stunning animated interfaces, vibration/sound settings, responsive screen layouts, and harmonious HSL tile color palettes.

---

## 🛠️ Tools & Technologies Used

* **Core Framework:** Flutter SDK (Cross-platform Dart compiling to native Android & iOS engines).
* **State Management:** Provider (Reactive, decoupled architecture keeping controllers separated from screens).
* **Database & Auth:** 
  * **Firebase Auth:** Google Sign-In & custom registration pipelines.
  * **Cloud Firestore:** Document storage for user metadata, social lists, levels, coins, and cosmetic inventories.
  * **Firebase Realtime Database:** High-speed JSON tree driving live matchmaking queues, emote payloads, and grid synchronization.
* **AI Engine:** Google Generative AI SDK (Gemini API integration for deep board analysis).
* **Device Integrations:** Flutter Vibration SDK (haptic feedback on tile combines) and Audioplayers (dynamic audio sounds).

---

## 📂 File Architecture

The codebase follows a structured, clean **Feature-First Architecture** for maximized code legibility and scalability:

```text
lib/
├── core/
│   ├── constants/         # Tile colors, match durations, rank tier metrics
│   ├── theme/             # Global material application themes
│   └── utils/             # Reusable formatting static utilities
├── features/
│   ├── ai/                # AI solver algorithms and states
│   ├── auth/              # Email register/login and Google Auth UI
│   ├── coach/             # AI Coach overlays and Gemini feedback views
│   ├── friends/           # Friends search, requests, and listings
│   ├── game/              # Single-player core gameplay mechanics and physics
│   ├── history/           # Past score logs and matches
│   ├── home/              # Main dashboard for game mode navigation
│   ├── leaderboard/       # Competitive global user standings
│   ├── multiplayer/       # Battle screens, live streaming, matchmaking controls
│   ├── notifications/     # Invites and alerts
│   ├── profile/           # Rank progression, level calculations, stats
│   ├── settings/          # Haptics and sound adjustments
│   ├── shell/             # Navigation bars and shell layouts
│   └── shop/              # Skin shop, purchases, coin monitors
├── services/
│   ├── ai/                # Gemini client setup
│   ├── ai_coach/          # AI prompt configurations
│   ├── firebase/          # Auth, Firestore, and Realtime DB connectors
│   └── vibration/         # Haptic vibration driver controls
└── main.dart              # MultiProvider registrations and app bootloader
```

---

## 🚀 Installation & Local Setup

### 📋 Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) installed locally (stable channel).
* [Java Development Kit (JDK 17)](https://www.oracle.com/java/technologies/downloads/) installed.
* [Firebase Project](https://console.firebase.google.com/) configured with Email/Password & Google Sign-In enabled.

---

### 🔑 Step 1: Configure Secret API Keys
Your API credentials are kept private and secure. A local template is included to guide your setup:

1. In the `keys/` directory, duplicate the template file `dart_defines.json.example` and rename the copy to `dart_defines.json`:
   ```bash
   cp keys/dart_defines.json.example keys/dart_defines.json
   ```
2. Open `keys/dart_defines.json` and insert your active **Google Gemini API Key**:
   ```json
   {
     "GEMINI_API_KEY": "YOUR_ACTUAL_GOOGLE_GEMINI_KEY_HERE"
   }
   ```
*(Note: `keys/dart_defines.json` is automatically ignored by Git to protect your credentials from accidental public pushes).*

---

### 🔗 Step 2: Configure Firebase Services
To bind your app to Firebase:
1. Register your Android app package name `com.basitulebad.twozerofoureight` in your Firebase console.
2. Download your `google-services.json` config file.
3. Place `google-services.json` directly into your local directory:
   ```text
   android/app/google-services.json
   ```

---

### 🏃 Step 3: Run the Application
1. Fetch all dependencies and link libraries:
   ```bash
   flutter pub get
   ```
2. Launch the application on a physical device, virtual emulator, or browser, feeding in your secure config variables:
   ```bash
   flutter run --dart-define-from-file=keys/dart_defines.json
   ```

---

## 📦 How to Build the Production Release APK

To compile an optimized, standalone Release APK that you can share directly with evaluators:
```bash
flutter build apk --release --dart-define-from-file=keys/dart_defines.json
```
The compiled APK will be located at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 👩‍💻 Authors
* **Basit-ul-Ebad** — Lead Developer & Architect
