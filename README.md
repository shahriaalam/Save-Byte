# SaveBite 🍽️

> **Surplus Food Discovery Platform**  
> Empowering restaurants to reduce food waste while helping consumers discover safe, high-quality, and affordable meals before daily closing times.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.x-blue?style=for-the-badge)](https://riverpod.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

---

## 📌 Table of Contents

- [About the Project](#-about-the-project)
- [Key Features by Role](#-key-features-by-role)
  - [Customer](#1-customer)
  - [Restaurant Partner](#2-restaurant-partner)
  - [Admin Moderator](#3-admin-moderator)
- [Tech Stack](#-tech-stack)
- [Architecture & Design Pattern](#-architecture--design-pattern)
- [Folder Structure](#-folder-structure)
- [Database & Storage Schema](#-database--storage-schema)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Supabase Configuration](#supabase-configuration)
  - [Running the App](#running-the-app)
- [Testing & Quality Assurance](#-testing--quality-assurance)
- [Core Business Rules](#-core-business-rules)
- [Scope & Roadmap](#-scope--roadmap)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 About the Project

**SaveBite** addresses the critical issue of food waste in the food & beverage industry. Every day, restaurants prepare delicious, fresh food that remains unsold at the end of the day. 

SaveBite provides a lightweight, real-time discovery marketplace where:
- **Restaurants** can post surplus, freshly prepared meals at discounted prices before closing.
- **Customers** can browse nearby surplus deals, search by category, view pickup windows, and save money.
- **Admins** moderate incoming restaurant registrations, verify platform integrity, and manage active listings.

> **V1 Scope Focus:**  
> The V1 release focuses purely on validating the core loop: **Discovery and Publication**. It intentionally eliminates unnecessary overhead such as in-app cart, payment gateways, or delivery logistics to provide a stable, zero-friction discovery experience.

---

## 👥 Key Features by Role

### 1. Customer
- **Authentication & Persistence:** Secure email/password login, registration, password recovery, and persistent session management.
- **Bottom Navigation Shell:** Seamless navigation across Home, Search, and Profile with state preservation using `StatefulShellRoute`.
- **Discovery Feed:** Browse active food offers from approved restaurants, featuring real-time pickup countdowns and discount percentages.
- **Category Filtering:** Quick-filter offers across 8 curated categories (*Rice, Burger, Pizza, Bakery, Snacks, Drinks, Dessert, Other*).
- **Search & Filter:** Real-time query search across offer titles, categories, and restaurant names.
- **Offer & Restaurant Details:** Detailed view of food portions, pickup hours, pricing breakdown, restaurant location, and all active offers from that restaurant.
- **User Profile Management:** View personal account details, edit name and phone number, and upload/change custom profile avatars with monogram fallbacks.

### 2. Restaurant Partner
- **Partner Registration:** Dedicated registration flow capturing restaurant name, cuisine type, address, contact phone, and operating hours.
- **Approval Workflow:** Clear status visibility (`pending` ➔ `approved`, `rejected`, or `suspended`) with administrative safeguards.
- **Partner Portal / Dashboard:** Management console to monitor restaurant status and manage surplus food offers.
- **Offer Lifecycle:** Create, edit, activate/deactivate, and delete food offers with custom images, pickup windows, and discounted pricing.

### 3. Admin Moderator
- **Moderation Console:** Secure oversight console accessible only to accounts with the `admin` role.
- **Partner Approvals:** Review new restaurant partner applications, verify details, and approve or reject submissions.
- **User Management:** Oversee registered users and toggle account statuses to protect community safety.
- **Offer Moderation:** Monitor active listings across all restaurants with ability to deactivate or remove non-compliant offers.

---

## 🛠️ Tech Stack

| Technology | Purpose |
| :--- | :--- |
| **[Flutter](https://flutter.dev)** (Dart 3.x) | Cross-platform UI toolkit targeting Mobile (Android & iOS), Web, and Desktop |
| **[Material Design 3](https://m3.material.io)** | Modern UI framework with custom Crimson Red (`#D32F2F`) & Deep Charcoal design system |
| **[Flutter Riverpod](https://riverpod.dev)** (`v3.4.3`) | Robust, compile-safe, and reactive state management and dependency injection |
| **[GoRouter](https://pub.dev/packages/go_router)** (`v18.0.2`) | Declarative URL routing, role-based guards, redirection, and tab state preservation |
| **[Supabase Flutter](https://supabase.com)** (`v2.17.2`) | Backend-as-a-Service powering PostgreSQL database, Auth, and Storage |
| **[Shared Preferences](https://pub.dev/packages/shared_preferences)** | Local key-value storage for cached preferences and offline flags |
| **[Image Picker](https://pub.dev/packages/image_picker)** | Cross-platform image selection for avatar and menu media uploads |

---

## 🏛️ Architecture & Design Pattern

SaveBite follows a **Feature-First Architecture** with a strict unidirectional flow of data and clear separation of concerns:

```
┌────────────────────────────────────────────────────────┐
│                   Presentation Layer                   │
│   (Screens, Stateful Shell, Dialogs, Modals, Theme)   │
└───────────────────────────┬────────────────────────────┘
                            │ listens to / notifies
┌───────────────────────────▼────────────────────────────┐
│                    Controller Layer                    │
│        (Riverpod StateNotifiers / AutoDispose Async)    │
└───────────────────────────┬────────────────────────────┘
                            │ delegates business logic
┌───────────────────────────▼────────────────────────────┐
│                    Repository Layer                    │
│   (Data Abstraction, Fallback Caching, Error Mapping)  │
└───────────────────────────┬────────────────────────────┘
                            │ executes queries / requests
┌───────────────────────────▼────────────────────────────┐
│                   Data Source Layer                    │
│          (Supabase Auth, PostgreSQL, Storage)          │
└────────────────────────────────────────────────────────┘
```

- **UI Layer** does not query the database directly.
- **Controllers** maintain application state and manage view models.
- **Repositories** interface with Supabase client APIs and provide safe offline fallback demo models for resilient testing.
- **Route Guards** dynamically evaluate the user's role on state changes to protect customer, restaurant, and admin spaces.

---

## 📂 Folder Structure

```
lib/
├── core/
│   ├── constants/        # Global app constants, color palette, Supabase keys
│   ├── errors/           # Custom exception models and failure handlers
│   ├── router/           # GoRouter config, route paths, auth route guards
│   ├── supabase/         # Supabase client initializers and service setup
│   ├── theme/            # Material 3 theme config, typography, component styles
│   ├── utils/            # Validators, price/discount calculators, file pickers
│   └── widgets/          # Reusable UI widgets (cards, badges, avatars, dialogs)
│
├── features/
│   ├── admin/            # Admin console, moderation flows, user oversight
│   ├── auth/             # Login, registration (customer/restaurant), forgot password
│   ├── customer/         # Discovery home, search, offer details, profile
│   ├── restaurant/       # Partner dashboard, offer publishing, restaurant profile
│   └── shared/           # Splash screen, cross-feature shared models and widgets
│
└── main.dart             # Application root entry point with ProviderScope
```

---

## 🗄️ Database & Storage Schema

The PostgreSQL database is hosted on Supabase and protected with Row Level Security (RLS):

### 1. `profiles` Table
Stores user account profiles tied to Supabase Auth UUIDs.
- `id` (UUID, Primary Key, references `auth.users.id`)
- `email` (TEXT)
- `full_name` (TEXT)
- `phone` (TEXT)
- `role` (TEXT: `customer` | `restaurant` | `admin`)
- `avatar_url` (TEXT)
- `is_active` (BOOLEAN, default: `true`)
- `created_at` / `updated_at` (TIMESTAMP)

### 2. `restaurants` Table
Stores restaurant partner metadata and moderation status.
- `id` (UUID, Primary Key)
- `owner_id` (UUID, references `profiles.id`)
- `name` (TEXT)
- `description` (TEXT)
- `phone` (TEXT)
- `address` (TEXT)
- `image_url` (TEXT)
- `cuisine_type` (TEXT)
- `opening_time` / `closing_time` (TIME)
- `status` (TEXT: `pending` | `approved` | `rejected` | `suspended`)
- `created_at` / `updated_at` (TIMESTAMP)

### 3. `offers` Table
Stores surplus food listings published by approved restaurants.
- `id` (UUID, Primary Key)
- `restaurant_id` (UUID, references `restaurants.id`)
- `title` (TEXT)
- `description` (TEXT)
- `image_url` (TEXT)
- `category` (TEXT)
- `original_price` (NUMERIC)
- `discounted_price` (NUMERIC)
- `quantity` (INTEGER)
- `available_from` / `available_until` (TIMESTAMP)
- `is_active` (BOOLEAN, default: `true`)
- `created_at` / `updated_at` (TIMESTAMP)

### Supabase Storage Buckets
- `avatars`: User profile photos.
- `restaurant-images`: Restaurant storefront and cover imagery.
- `offer-images`: Food item photos for surplus listings.

---

## 🚀 Getting Started

### Prerequisites

Ensure you have installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.4` or later)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / Xcode / Google Chrome (for your desired target platform)
- [Git](https://git-scm.com/)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/shahriaalam/Save-Byte.git
   cd Save-Byte
   ```

2. **Install project dependencies:**
   ```bash
   flutter pub get
   ```

### Supabase Configuration

SaveBite connects to Supabase using public environment variables. You can pass them at build/run time via `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
```

> ⚠️ **Security Notice:**  
> Never include the Supabase `service_role` key in Flutter client code or check it into version control. Only use the public `anon` key.

### Running the App

- **On Android Emulator / Device:**
  ```bash
  flutter run
  ```
  *(Windows developers can also execute `run_app_on_emulator.bat` to launch the configured Android emulator and start the app automatically.)*

- **On Chrome (Web):**
  ```bash
  flutter run -d chrome
  ```

- **On Windows Desktop:**
  ```bash
  flutter run -d windows
  ```

---

## 🧪 Testing & Quality Assurance

SaveBite enforces strong automated test coverage across domain logic, repositories, and widget interactions.

### Run Unit & Widget Tests
```bash
flutter test
```
*Current test suite: **51 automated tests** covering price calculators, profile role getters, input validation, repository query filters, and UI widget flows.*

### Run Static Analysis
```bash
flutter analyze
```

### Format Codebase
```bash
dart format .
```

---

## 📏 Core Business Rules

1. **Offer Visibility Criteria:**
   An offer is visible to customers **only if**:
   - `restaurant.status == 'approved'`
   - `offer.is_active == true`
   - `currentTime < offer.available_until`
2. **Pricing Integrity:**
   - `original_price > 0` and `discounted_price > 0`
   - `discounted_price <= original_price`
   - Savings percentage is dynamically computed:
     $$\text{Discount} = \left(\frac{\text{original\_price} - \text{discounted\_price}}{\text{original\_price}}\right) \times 100$$
3. **Currency & Localization:**
   - Displayed prices are formatted in Bangladeshi Taka (`৳` BDT).
4. **Data Fallback Resiliency:**
   - When running against fresh backends or demo environments without populated live offers, repositories automatically provide high-quality fallback demo records to ensure seamless manual and visual testing.

---

## 🗺️ Scope & Roadmap

### ✅ V1 Scope (Completed)
- [x] Email & password authentication with persistent sessions
- [x] Customer discovery feed with category chips and search
- [x] Food offer details & restaurant profile screens
- [x] Customer profile editing and avatar image upload
- [x] Restaurant partner onboarding flow (`pending` status)
- [x] Admin console with access-guarded routes
- [x] Material 3 design system with responsive layouts

### 🔮 Future Roadmap (V2+)
- [ ] In-app ordering and reserve-ahead functionality
- [ ] Digital payment gateway integration (bKash, Nagad, Cards)
- [ ] QR code generation and pickup validation scanner
- [ ] Live map view with geolocation-based proximity sorting
- [ ] Customer reviews, ratings, and favorite restaurants
- [ ] Push notifications for flash surplus drops
- [ ] Restaurant analytics and revenue dashboards

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
