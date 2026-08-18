# TecniForge — Weekly Capstone Mini App

A complete, multi-screen Flutter mobile app built end-to-end for TecniForge,
combining every feature developed across the internship into one working
application.

## Overview

TecniForge is a business-management style app for small business owners.
It opens with a branded splash screen, then a home menu from which every
feature below is reachable — one app, one codebase, fully navigable.

## Features

- **Splash screen** — branded intro on launch
- **Business Dashboard** — stats, activity feed, and Tasks/Profile tabs
  with bottom navigation
- **Clients (CRUD)** — full Create, Read, Update, Delete against a live
  REST API, with loading, success, and error states
- **New Client Form** — controlled inputs with per-field validation
  (name, email, phone, business, password)
- **Task List** — add/remove items with input validation and an empty
  state
- **Product List** — a long (120-item) list rendered efficiently, so
  scrolling stays smooth regardless of dataset size
- **Business Notes** — local persistence (data and a visit counter
  survive a full app restart)
- **Weather** — live weather fetched per city, with favorites saved
  locally, demonstrating navigation + API + persistence together
- **Notifications** — local notifications, sent immediately or after a
  scheduled delay
- **Component Library** — a live showcase of the app's reusable UI
  building blocks
- **Polished UX** — custom slide/fade page transitions, button press
  animations, staggered list entrance animations, and smooth cross-fades
  between loading/success/error states throughout

## Tech stack

- **Flutter / Dart**
- `http` — REST API calls
- `shared_preferences` — local key-value persistence
- `flutter_local_notifications` — local notifications
- No backend framework — uses free public APIs (JSONPlaceholder,
  Open-Meteo) for live data during development

## Architecture

- Single-file app (`lib/main.dart`) structured as:
  - `AppTheme` — centralized colors and design tokens
  - Reusable components — `AppButton`, `AppCard`, `AppBadge`,
    `AppTextField`, `AppTopBar`, `FadeSlideIn`
  - `HomeMenuScreen` — entry point listing every feature screen
  - One class per feature screen, each self-contained
- Navigation handled with `Navigator.push` / `pop`, using a custom
  `animatedRoute()` helper for consistent transitions app-wide

## Running the app

1. Open the project in Android Studio (with the Flutter/Dart plugins).
2. Run `flutter pub get`.
3. Connect an Android device or start an emulator.
4. Run `flutter run`.

## Author

Esha ArooJ — BSCS, COMSATS University Islamabad, Sahiwal Campus

