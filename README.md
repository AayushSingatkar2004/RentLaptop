# 🖥️ Laptop Rental Admin App

A Flutter mobile app for managing a laptop rental service — customers, rentals, dues, and payments — backed by Supabase (PostgreSQL + Auth + Edge Functions).

**Stack:** Flutter 3 · Dart · Supabase · Riverpod 2 · GoRouter

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Project Structure](#2-project-structure)
3. [Supabase Project Setup](#3-supabase-project-setup)
4. [Run the Database SQL](#4-run-the-database-sql)
5. [Create the Admin User](#5-create-the-admin-user)
6. [Deploy Edge Functions](#6-deploy-edge-functions)
7. [Add Your Keys to Flutter](#7-add-your-keys-to-flutter)
8. [Run the Flutter App](#8-run-the-flutter-app)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites

Make sure you have the following installed before starting:

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | 3.x or higher | https://flutter.dev/docs/get-started/install |
| Dart | Included with Flutter | — |
| Android Studio / Xcode | Latest | For emulator / simulator |
| A Supabase account | Free tier is fine | https://supabase.com |

Verify Flutter is working:
```bash
flutter doctor
```
All items should show a green checkmark (or at minimum, your target platform should be ready).

---

## 2. Project Structure

After unzipping the project, you will see this structure:

```
laptop_rental_admin/
├── lib/
│   ├── main.dart                    ← App entry point
│   ├── app.dart                     ← MaterialApp + Router
│   ├── supabase_config.dart         ← ⚠️  YOUR KEYS GO HERE
│   ├── core/
│   │   ├── constants/               ← Colors, strings
│   │   ├── router/app_router.dart   ← GoRouter navigation
│   │   ├── theme/                   ← App theme
│   │   └── widgets/                 ← Shared widgets
│   ├── data/
│   │   ├── models/                  ← Dart data classes
│   │   └── repositories/            ← All Supabase queries
│   ├── providers/                   ← Riverpod state providers
│   └── screens/
│       ├── auth/login_screen.dart
│       ├── dashboard/
│       ├── customers/
│       ├── laptops/
│       └── dues/
├── supabase/
│   └── functions/
│       ├── create_rental/index.ts   ← Edge Function
│       ├── complete_rental/index.ts ← Edge Function
│       └── record_payment/index.ts  ← Edge Function
├── supabase_setup.sql               ← Full database schema
└── pubspec.yaml
```

---

## 3. Supabase Project Setup

### Step 1 — Create a new Supabase project

1. Go to **https://supabase.com** and sign in
2. Click **"New project"**
3. Choose your organization
4. Fill in:
   - **Project name:** `laptop_rental` (or anything you like)
   - **Database password:** Set a strong password and save it
   - **Region:** Choose the region closest to you (e.g. `ap-south-1` for India)
5. Click **"Create new project"** and wait ~2 minutes for it to provision

### Step 2 — Get your Project URL and Anon Key

1. In your project, click **Settings** (gear icon in the left sidebar)
2. Click **API**
3. You will see:
   - **Project URL** — looks like `https://abcdefghijklmnop.supabase.co`
   - **Project API keys → anon / public** — a long string starting with `eyJ...`
4. Copy both — you will need them in [Step 7](#7-add-your-keys-to-flutter)

> ⚠️ **Never share or commit your `service_role` key.** Only the `anon` key goes in the Flutter app.

---

## 4. Run the Database SQL

The entire database schema is in `supabase_setup.sql`. You need to run this once.

1. In your Supabase project, click **SQL Editor** in the left sidebar
2. Click **"New query"**
3. Open `supabase_setup.sql` from the project folder on your computer
4. Copy the entire contents and paste into the SQL Editor
5. Click **"Run"** (or press `Ctrl+Enter`)

You should see **"Success. No rows returned"** at the bottom.

### What the SQL creates:

- **6 ENUM types** — `laptop_status`, `user_status`, `rental_type`, `rental_status`, `due_status`, `txn_type`
- **8 tables** — `admin_profile`, `laptops`, `customers`, `rentals`, `dues`, `payments`, `transactions`, `audit_logs`
- **Auto-update triggers** — keeps `updated_at` current automatically
- **Row Level Security (RLS)** — only authenticated admin can read/write data

### Verify tables were created:

Click **Table Editor** in the sidebar. You should see all 8 tables listed:

```
✅ admin_profile
✅ audit_logs
✅ customers
✅ dues
✅ laptops
✅ payments
✅ rentals
✅ transactions
```

---

## 5. Create the Admin User

The app has a single admin login. Create it once via the Supabase dashboard.

### Step 1 — Create the auth user

1. Click **Authentication** in the left sidebar
2. Click **Users** tab
3. Click **"Add user"** → **"Create new user"**
4. Enter:
   - **Email:** `admin@laptoprentals.com` (or any email you want)
   - **Password:** Choose a strong password
5. Click **"Create user"**
6. After creation, click on the user to see their **User UID** — copy it (looks like `ef253271-6a62-4278-...`)

### Step 2 — Seed the admin profile table

1. Go back to **SQL Editor** → New query
2. Paste and run this, replacing the UUID with the one you copied:

```sql
INSERT INTO admin_profile (auth_user_id, username, display_name)
VALUES (
  'PASTE-YOUR-USER-UUID-HERE',
  'admin',
  'Laptop Rental Admin'
);
```

Example:
```sql
INSERT INTO admin_profile (auth_user_id, username, display_name)
VALUES (
  'ef253271-6a62-4278-a53e-df10c95a10c7',
  'admin',
  'Laptop Rental Admin'
);
```

Click **Run**. You should see **"Success. 1 rows affected"**.

---

## 6. Deploy Edge Functions

The app uses 3 Edge Functions for atomic database operations. These run server-side on Supabase's infrastructure.

### What each function does:

| Function | Purpose |
|----------|---------|
| `create_rental` | Creates customer + rental + marks laptop as rented + generates due cycles + records deposit — all in one atomic operation |
| `complete_rental` | Marks rental as completed, frees the laptop, deactivates the customer, optionally records deposit return |
| `record_payment` | Records a full or partial payment, updates due status, inserts payment and transaction records |

---

### Option A — Deploy via Supabase Dashboard (No CLI needed) ✅ Recommended

#### Deploy `create_rental`

1. Click **Edge Functions** in the left sidebar
2. Click **"Create a new function"**
3. Name it exactly: **`create_rental`**
4. Click **"Create function"**
5. A code editor opens — **delete all existing code**
6. Open `supabase/functions/create_rental/index.ts` from your project folder
7. Copy the entire contents and paste into the editor
8. Click **"Deploy"**
9. Wait for status to show **Active** ✅

#### Deploy `complete_rental`

1. Go back to **Edge Functions** → **"Create a new function"**
2. Name it: **`complete_rental`**
3. Delete default code → paste contents of `supabase/functions/complete_rental/index.ts`
4. Click **"Deploy"** → wait for **Active** ✅

#### Deploy `record_payment`

1. Go back to **Edge Functions** → **"Create a new function"**
2. Name it: **`record_payment`**
3. Delete default code → paste contents of `supabase/functions/record_payment/index.ts`
4. Click **"Deploy"** → wait for **Active** ✅

#### Disable JWT Verification on all 3 functions

By default Supabase enforces JWT on Edge Functions. You need to turn this off so the Flutter app can call them with just the session token:

For **each** of the 3 functions:
1. Click the function name
2. Click the **"Details"** tab
3. Find **"JWT verification"** toggle → turn it **OFF**
4. Click **Save**

Repeat for all 3: `create_rental`, `complete_rental`, `record_payment`.

---

### Option B — Deploy via Supabase CLI

If you prefer the command line:

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project (get the ref from Settings → General)
cd path/to/laptop_rental_admin
supabase link --project-ref YOUR_PROJECT_REF_HERE

# Deploy all 3 functions
supabase functions deploy create_rental
supabase functions deploy complete_rental
supabase functions deploy record_payment
```

Then disable JWT via dashboard as described in Option A above.

---

## 7. Add Your Keys to Flutter

Open this file in the project:

```
lib/supabase_config.dart
```

It looks like this:

```dart
class SupabaseConfig {
  static const String url     = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String anonKey = 'YOUR_ANON_KEY_HERE';
}
```

Replace with your actual values from [Step 3](#step-2--get-your-project-url-and-anon-key):

```dart
class SupabaseConfig {
  static const String url     = 'https://abcdefghijklmnop.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.YOUR_FULL_ANON_KEY';
}
```

> 💡 Where to find these values: Supabase Dashboard → **Settings** → **API**

**That's the only file you need to edit.** Save it and continue.

---

## 8. Run the Flutter App

### Install dependencies

```bash
cd path/to/laptop_rental_admin
flutter pub get
```

### Run on Android emulator or device

```bash
flutter run
```

Or to target a specific device:

```bash
flutter devices           # list available devices
flutter run -d emulator-5554
```

### First login

Use the credentials you created in [Step 5](#5-create-the-admin-user):

- **Email:** `admin@laptoprentals.com` (or whatever you set)
- **Password:** the password you chose

---

## 9. Troubleshooting

### ❌ "Invalid login credentials"
- Double-check email and password in Supabase → Authentication → Users
- Make sure you are using the **anon key** (not service_role) in `supabase_config.dart`

### ❌ "Null is not a subtype of int" on Customers screen
- Your database tables exist but may have been created incorrectly
- Re-run `supabase_setup.sql` in a fresh project, or check the Table Editor to confirm all 8 tables exist

### ❌ 401 Unauthorized when creating a customer
- JWT verification is still ON for the Edge Functions
- Go to each function → Details tab → turn JWT verification **OFF** → Save

### ❌ Edge Function returns 400 "Laptop not available"
- The laptop you selected is already rented or damaged
- Only laptops with status `available` can be assigned

### ❌ `flutter pub get` fails
- Make sure Flutter SDK is 3.x: `flutter --version`
- Run `flutter clean` then `flutter pub get` again

### ❌ "No available laptops" on Add Customer Step 2
- You need to add at least one laptop first via the **Laptops** tab → `+` button
- Laptops added with status `Damaged` or `Under Repair` will not appear — only `Available` ones show

### ❌ Dues not updating after adding a customer
- Check that the `create_rental` Edge Function deployed successfully and is **Active**
- Check Edge Function logs: Supabase → Edge Functions → `create_rental` → Logs tab

---

## Security Notes

- The `anon` key in the Flutter app is safe to ship — all tables have **Row Level Security (RLS)** enabled, so unauthenticated requests return no data
- The `service_role` key is only used inside Edge Functions (server-side) and is never exposed to the app
- All customer data uses **soft deletes** — records are never permanently deleted, only hidden

---

## Default Admin Credentials (example)

| Field | Value |
|-------|-------|
| Email | `admin@laptoprentals.com` |
| Password | *(whatever you set in Supabase Auth)* |

> You set these yourself in Step 5. There is no hardcoded password in the app.