# Fine — Personal Budgeting App

Fine is a personal finance and budgeting app for Android, inspired by Money+. It helps you track income and expenses, manage multiple accounts (cash, bank, e-wallet, investment), set budgets, plan recurring bills and commitments, and save toward goals — all stored locally on your device.

## Features

- **Transactions** — log income, expenses, and transfers between accounts, organized by category.
- **Wallet / Accounts** — manage multiple accounts: cash, bank accounts (with Malaysian bank picker — Maybank, CIMB, Public Bank, RHB, and more), e-wallets (Touch 'n Go, GrabPay, Boost, ShopeePay, etc.), and investment platforms (Moomoo, ASNB, crypto, etc.), each with notes and a running balance/net-worth chart.
- **Budgets** — set monthly spending limits per category and track progress.
- **Categories** — customizable income/expense categories with colors and icons.
- **Bills & Future Plan** — recurring bills and upcoming financial commitments, with reminders and a paid/unpaid toggle.
- **Goals** — savings goals with target amount, target date, notes, and progress tracking, with a celebration animation on completion.
- **Reports** — visual breakdowns and trends of spending/income (powered by interactive charts with touch tooltips).
- **Dashboard** — at-a-glance overview of balances, recent activity, and budget status.
- **Security** — optional biometric/PIN app lock.
- **Data & Backup** — export/import via CSV, share reports.
- **Currency** — defaults to Malaysian Ringgit (MYR), with light/dark theme support.

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `>=3.0.0 <4.0.0`)
- Android Studio (for Android SDK, platform tools, and an emulator) or a physical Android device with USB debugging enabled
- A configured Android emulator (e.g. via `Android Studio > Device Manager`) or a connected physical device

Check your setup with:

```bash
flutter doctor
```

## Getting Started

1. **Install dependencies**

   ```bash
   flutter pub get
   ```

2. **Generate database/code (Drift, Riverpod)**

   This project uses code generation for the local database (Drift) and providers (Riverpod). Run this whenever a `Table` or annotated provider changes:

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Run the app**

   List available devices/emulators:

   ```bash
   flutter devices
   ```

   Run on a specific device:

   ```bash
   flutter run -d <device-id>
   ```

   Or simply:

   ```bash
   flutter run
   ```

4. **Build a release APK** (optional)

   ```bash
   flutter build apk --release
   ```

   The output APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Project Structure

```text
lib/
├── core/            # Theming, shared widgets, utilities (currency/date formatting)
├── data/database/   # Drift database, tables, schema migrations
├── providers/        # Riverpod providers
└── features/
    ├── accounts/     # Account management, bank/e-wallet/investment pickers
    ├── bills/         # Recurring bills
    ├── budgets/       # Budget tracking
    ├── categories/    # Category management
    ├── dashboard/     # Home overview
    ├── future_plan/   # Upcoming commitments
    ├── goals/         # Savings goals
    ├── reports/       # Charts and insights
    ├── settings/      # App settings, security, backup
    ├── shell/          # Bottom navigation / app shell
    ├── transactions/  # Transaction list and entry
    └── wallet/        # Wallet overview, account detail, net worth chart
```

## Tech Stack

- **Flutter** — cross-platform UI
- **Drift** — local SQLite database with type-safe queries and schema migrations
- **Riverpod** — state management
- **fl_chart** — interactive charts (spending trends, net worth, money flow)
- **flutter_local_notifications** — bill/commitment reminders
- **local_auth** + **flutter_secure_storage** — biometric/PIN app lock
- **csv** + **share_plus** — data export/sharing

## Database Migrations

The local database schema is versioned (`schemaVersion` in `lib/data/database/app_database.dart`). When adding a new column or table:

1. Edit the relevant `Table` class.
2. Bump `schemaVersion`.
3. Add a new `if (from < N) { ... }` block inside `onUpgrade`.
4. Re-run `dart run build_runner build --delete-conflicting-outputs`.
