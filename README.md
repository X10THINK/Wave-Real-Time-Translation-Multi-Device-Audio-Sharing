<div align="center">

# Wave

### Real-Time Translation & Multi-Device Audio Sharing

**Connect people through shared audio and language.**

An Android-first project by **ZAEROX**.

![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android&logoColor=white)
![Framework](https://img.shields.io/badge/Framework-Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Language](https://img.shields.io/badge/Language-Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Status](https://img.shields.io/badge/Status-In%20Development-6B7280?style=flat-square)

[Project Overview](#about-wave) · [Features](#core-features) · [Documentation](#documentation) · [Getting Started](#getting-started) · [Contributing](#contributing)

</div>

---

## About Wave

**Wave — Real-Time Translation & Multi-Device Audio Sharing** is an Android-focused application project designed to help groups listen and communicate more easily. It brings two complementary experiences into one product:

- **Audio Share:** distribute a host device's selected audio to multiple nearby listener devices.
- **Live Translation:** make group communication more accessible through translated speech and captions in each participant's chosen language.

Wave is being developed for classrooms, seminars, guided tours, presentations, and other situations in which many people need access to the same audio or conversation.

> **Project status:** Wave is under active development. This repository is being populated incrementally with existing source modules and engineering documentation. The presence of a feature in the product plan does **not** mean it has been fully integrated, validated, or released from this repository.

## Core Features

### 1. Audio Share

Wave's Audio Share experience is designed around a **Host** who creates a session and **Receivers** who join to listen.

**Product capabilities and goals:**

- Share audio with multiple nearby Android devices.
- Use supported local transport methods such as **the same Wi-Fi network** or a **mobile hotspot** without requiring an internet connection for the local audio connection.
- Explore **Bluetooth-based relay/mesh connectivity** for expanded coverage, subject to Android hardware, bandwidth, and compatibility constraints.
- Select supported audio sources, including an in-app music player and supported device playback audio.
- Join using a session code, QR code, or supported nearby-session discovery.
- Control session admission through optional host approval.
- Monitor session participants, connection health, and reconnection states.
- Improve synchronized playback and minimize end-to-end latency across receivers.

**Important:** Bluetooth multi-hop relaying, large-group capacity, and low-latency synchronization are engineering objectives—not universal compatibility or performance guarantees.

### 2. Live Translation

Live Translation is designed to help people participate in multilingual sessions with **translated voice and captions**.

**Product capabilities and goals:**

- Host-led, one-to-many translated sessions.
- Individual language selection for listeners.
- Speaker-request and host-approval workflows for structured Q&A.
- Efficient translation processing that avoids unnecessary duplicate translation work.
- Account-based participation for both hosts and receivers.
- Usage-aware paid translation with support for host-funded or participant-shared costs.
- Keep a session connected when paid translation is paused or credits are exhausted, where supported by the implementation.

**Important:** Translation is a separate service from local audio transport. Depending on the selected speech/translation provider and deployment, translation processing may require internet access and may incur usage charges. Offline local audio sharing does not imply offline AI translation.

## How Wave Is Designed to Work

The intended session journey is:

1. Open **Audio Share** or **Live Translation**.
2. Choose a connection method: **Wi-Fi**, **Bluetooth**, or **Mobile Hotspot** (where supported).
3. Choose a role: **Host** or **Receiver**.
4. The host creates a session; receivers find or join it.
5. The host manages participants and starts the experience.
6. Participants access audio or translation according to their selected feature and connection capabilities.

Live Translation additionally requires account sign-in and any applicable payment/entitlement checks. Actual screens, permissions, and supported paths should be confirmed against the integrated source and the latest approved UX specification.

## Technology Overview

| Area | Technology / direction |
| --- | --- |
| Target platform | Android |
| App framework | Flutter |
| Primary application language | Dart |
| Device integration | Android native platform interfaces where required |
| Local audio transport | Wi-Fi LAN and mobile hotspot; Bluetooth paths under development/research |
| Media | Local/device media playback and supported Android playback capture |
| Translation | Speech recognition, translation, and speech synthesis through selected service/model integrations |
| Collaboration | Git, GitHub branches, pull requests, and documentation |

The table summarizes the product's technology direction; it is **not** a complete audited dependency list for the current repository snapshot.

## Repository Structure

The repository currently includes the following top-level areas:

```text
Wave-Real-Time-Translation-Multi-Device-Audio-Sharing/
├── Documents/
│   ├── BRD/                  # Business requirements
│   ├── PRD/                  # Product requirements
│   ├── SRS/                  # Software requirements
│   ├── FRD/                  # Functional requirements
│   ├── TRD/                  # Technical requirements and design
│   ├── Other_Documents/      # Architecture, UI/UX, tests, APIs, deployment, etc.
│   ├── Second_Brain/        # Project knowledge and reference material
│   └── README.md            # Documentation index
└── WAVE_Flutter/
    └── lib/
        ├── core/
        │   └── media/        # Shared media playback code
        └── features/
            └── audio/
                └── presentation/ # Audio feature presentation code
```

**Note:** This tree reflects the repository at the time of README preparation. Additional modules and files will be integrated progressively. It is not intended to show the eventual complete Flutter project structure.

## Getting Started

### Prerequisites

For working with the Android/Flutter application **once the full runnable project is integrated**:

- Flutter SDK and Dart (versions compatible with the project's eventual `pubspec.yaml`).
- Android Studio or another supported Android development environment.
- Android SDK and a physical Android device or emulator.
- Git.

### Clone the repository

```bash
git clone https://github.com/X10THINK/Wave-Real-Time-Translation-Multi-Device-Audio-Sharing.git
cd Wave-Real-Time-Translation-Multi-Device-Audio-Sharing
```

### Run the Flutter app — after full application integration

```bash
cd WAVE_Flutter
flutter pub get
flutter run
```

To produce a debug APK once the Android project files are present:

```bash
flutter build apk --debug
```

> **Current limitation:** The checked repository snapshot contains an **in-progress source integration** rather than a complete, stand-alone Flutter application: the project manifest (`pubspec.yaml`) and Android project files are not yet present under `WAVE_Flutter/`. The run/build commands above are for the completed project structure and should **not** be expected to work on the current snapshot. Do not initialize a new Flutter project on top of the integration just to make these commands run.

## Documentation

The project documentation is maintained separately from feature code. Start with the **[Documentation Index](Documents/README.md)**.

| Document | Purpose |
| --- | --- |
| [BRD](Documents/BRD/README.md) | Business needs, goals, and constraints |
| [PRD](Documents/PRD/README.md) | Product scope and expected experiences |
| [SRS](Documents/SRS/README.md) | Software requirements |
| [FRD](Documents/FRD/README.md) | Functional behavior and use cases |
| [TRD](Documents/TRD/README.md) | Technical requirements and design decisions |
| [Architecture and engineering documents](Documents/Other_Documents/) | High/low-level design, architecture decisions, UI/UX, API, testing, and deployment plans |
| [Second Brain](Documents/SECOND_BRAIN.md) | Navigational entry point to project knowledge |

Documentation captures requirements and proposed designs; it is **not, by itself, evidence that a feature has been implemented or passed testing**.

## Development Approach

Wave follows two coordinated workstreams:

1. **Application development and device testing:** the existing working source is developed, built, evaluated on Android devices, and improved through successive versions.
2. **GitHub integration and engineering history:** approved source is brought into this repository in small, coherent, dependency-aware commits, alongside technical documentation and review.

The GitHub integration process does not require rewriting already working application code simply to create a commit history. Changes and fixes should be traceable, reviewed, and separately verified where appropriate.

### Contributing

For team contributions:

1. Synchronize with the repository's `MAIN` branch.
2. Create a focused feature or integration branch.
3. Commit one logical change or source-integration slice at a time.
4. Open a pull request describing the scope, dependencies, and any verification performed.
5. Review and merge according to the team's agreed workflow.

**Example:**

```bash
git checkout MAIN
git pull origin MAIN
git checkout -b feature/your-change
```

Avoid committing secrets, API keys, signing credentials, build outputs, or personal data. Do not report tests as passed unless they were actually executed for the stated version and environment.

## Engineering Considerations

- **Android permissions and capture rules:** capturing audio from other applications is subject to Android playback-capture policies and the source app's permissions/settings.
- **Transport variability:** Wi-Fi, hotspot, Bluetooth, and background execution can differ across phones and Android versions.
- **Latency and synchronization:** receiver timing, buffering, reconnect behavior, and group capacity require real-device measurement.
- **Privacy and payments:** account information, translation content, and paid usage need appropriate security controls and policy-compliant payment integration.
- **Accessibility:** translated captions and clear session states are important product goals.

## Project Identity

| Item | Name |
| --- | --- |
| Full project title | **Wave — Real-Time Translation & Multi-Device Audio Sharing** |
| Android app name | **Wave** |
| Brand | **ZAEROX** |
| Repository | `Wave-Real-Time-Translation-Multi-Device-Audio-Sharing` |

## Release and License

Wave is **in development**; no general-availability release or public download is declared here. Check the repository's Releases page and verified project announcements for actual release artifacts.

No open-source license is asserted by this README. Unless and until the repository owner adds an explicit license, do not assume permission to reuse or redistribute its source code.

---

<div align="center">

**Wave · By ZAEROX**  
*One experience. Shared audio. More accessible communication.*

</div>
