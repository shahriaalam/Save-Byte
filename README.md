# SaveBite 🍽️

> **Surplus Food Discovery & Rescue Platform**  
> Empowering restaurants to eliminate food waste while helping consumers discover safe, high-quality, and deeply discounted meals before daily closing times.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-3.x-blue?style=for-the-badge)](https://riverpod.dev)
[![Tests Passing](https://img.shields.io/badge/Tests-144%20Passed-brightgreen?style=for-the-badge&logo=checkmarx&logoColor=white)](test/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

---

## 📌 Table of Contents

- [About the Project](#-about-the-project)
- [Key Features by Role](#-key-features-by-role)
  - [1. Customer](#1-customer)
  - [2. Restaurant Partner](#2-restaurant-partner)
  - [3. Admin Moderator](#3-admin-moderator)
- [Instant Quick-Fill Demo Credentials](#-instant-quick-fill-demo-credentials)
- [Tech Stack](#-tech-stack)
- [Architecture & Design Pattern](#-architecture--design-pattern)
- [Route Guards & Security Matrix](#-route-guards--security-matrix)
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

**SaveBite** tackles the urgent economic and environmental crisis of food waste in the food and beverage industry. Every single day, restaurants and bakeries prepare fresh, delicious meals that go unsold at closing time and end up discarded.

SaveBite provides a lightweight, real-time discovery and pickup marketplace where:
- **Restaurants** publish surplus, freshly prepared meals at steep discounts (30% to 70%+ off) before closing, recovering operational costs and reducing waste.
- **Customers** browse nearby surplus deals, search by category and district, view pickup windows, and pick up fresh meals affordably.
- **Admins** oversee partner registrations, monitor active listings, analyze platform performance, and ensure food safety and community standards.

> **Zero-Friction Discovery Model:**  
> SaveBite focuses on direct merchant-to-customer food discovery with localized takeaway pickup, eliminating hefty third-party delivery commissions and complex delivery overhead.

---

## 👥 Key Features by Role

### 1. Customer
- **Authentication & Persistence:** Secure email/password login, Google Sign-In with official custom vector branding, password recovery, session persistence, and instant one-tap quick-fill demo credentials.
- **Stateful Shell Navigation:** Seamless navigation between Home, Search, Orders, and Profile using GoRouter `StatefulShellRoute` with preserved scroll and tab state.
- **Hero Promotional Banners:** Interactive, auto-rotating promotional banner carousel with curated campaigns (*Fresh Surplus*, *Payday Feast*, *Coffee Day*) and direct deal actions.
- **Category Quick-Filter:** 8 curated food categories (*Rice, Burger, Pizza, Bakery, Snacks, Drinks, Dessert, Other*) with real-time selection states.
- **Hot Deals Spotlight:** Dedicated hot deals screen highlighting surplus drops with **45%+ OFF** discount badges.
- **Geo-Location & District Filtering:** Dynamic division and area selectors (Dhaka: Dhanmondi, Gulshan, Banani, Mirpur, Uttara; Chittagong, Sylhet, etc.) with integrated device GPS location permission handling.
- **Search & Filter:** Instant debounced full-text search across meal titles, categories, division/area locations, and restaurant names.
- **Surplus Food Details:** Comprehensive meal view featuring quantity remaining, portion size, allergen disclosures, countdown timer to pickup deadline, original vs. discounted pricing breakdown with computed savings percentage.
- **Restaurant Profile & Active Menu:** View complete restaurant operating hours, address, phone contact, and all current surplus listings from the same kitchen.
- **Customer Orders & Live Pickup Sheet:** Track orders through a real-time status pipeline (`pending` ➔ `confirmed` ➔ `ready_for_pickup` ➔ `picked_up`), complete with pickup timers, digital receipts, and one-tap access to rate completed rescues.
- **Customer Reviews, Ratings & Verified Badges:** Following food pickup, customers can post a 1-to-5 star rating, written sentence review, and attached food photos (camera/gallery or preset foods). Reviews prominently feature a **Verified Rescue** badge tied directly to their completed takeaway order.
- **My Reviews & Ratings Portal:** Customers can view and manage all historical reviews and ratings submitted for each restaurant directly from their profile menu.
- **Community Transparency on Restaurant Profiles:** Other customers can see the restaurant's aggregate rating score, 5★-to-1★ distribution bars, total verified rescues count, and filter reviews ("All Reviews" vs "With Photos").
- **Favorites System:** One-tap bookmarking to save and revisit preferred restaurants and surplus items.
- **Profile & Monogram Avatars:** Manage personal account details, upload custom profile photos with monogram fallback initials, and safe account deletion with confirmation safeguards.

### 2. Restaurant Partner
- **Partner Registration & KYC:** Dedicated partner onboarding capturing business name, cuisine specialty, physical address, division/area, contact phone, operating hours, and storefront photos.
- **Approval Workflow:** Clear status lifecycle (`pending` ➔ `approved`, `rejected`, or `suspended`) with administrative safeguards preventing unapproved stores from publishing.
- **Partner Portal with Floating Nav Bar:** A modern 5-tab floating pill navigation bar:
  - 🏠 **Home:** Live operational overview, active listings counter, quick actions, pending pickup alerts, and live **Customer Reviews & Ratings** summary card.
  - 📊 **Café Intelligence:** Real-time business KPI analytics (Gross Revenue, Total Rescued Meals, Average Customer Rating, Active Orders), interactive **Top Sellers** breakdown, and a dedicated **Customer Reviews & Sentiment Intelligence** section.
  - 📝 **Posts:** Active surplus listings manager — edit meal titles, adjust available quantities in real time, or mark posts as "Done" with instant dashboard sync.
  - 🎁 **Offers:** Purchase admin promotional packages (Hero Banner for ৳2,000, 24h Offer Boost for ৳600) via an integrated **Payment Portal** sheet supporting bKash, Nagad, and Cards.
  - 👤 **Account & Owner Profile:** Verified owner credentials card, profile completeness score with an active posting blocker for incomplete profiles, "Request Info Update" workflow, and 2-step OTP account deletion.
- **Partner Review Inspection:** Restaurant partners can inspect customer feedback, star ratings, and uploaded meal pictures directly from their dashboard and intelligence views to track food quality and customer satisfaction.
- **Hero Banner Designer:** Exclusive design suite for Gold Merchants to customize promotional hero banners with approval workflow.
- **Live Pickup Management:** High-visibility green status cards for confirmed orders with one-tap "Mark Ready for Pickup" and "Mark as Picked Up / Done" workflows.
- **Partner Notifications Center:** Dedicated inbox for real-time notifications on customer orders, promotional package approvals, and admin policy updates.

### 3. Admin Moderator
- **Admin Oversight Console:** Protected administrative suite restricted to accounts with the `admin` role.
- **Executive Analytics Dashboard:** Comprehensive platform analytics sheet featuring rescued meals counters, gross platform volume, active restaurant counts, revenue graphs, category distribution pie charts, and banner campaign statistics.
- **Partner Verification & Approvals:** Review incoming restaurant partner applications, inspect operational documents, and approve or reject submissions with one tap.
- **Surplus Offer Oversight:** Platform-wide monitoring of all active listings with immediate deactivation rights for expired or non-compliant posts.
- **User & Merchant Management:** Complete user directory with status toggles (`active` vs. `suspended`) to maintain platform integrity.
- **Promotional Campaign Management:** Audit and approve merchant-submitted hero banners and promotional boost runs.

---

## ⚡ Instant Quick-Fill Demo Credentials

SaveBite features built-in quick-fill credentials directly on the login screen, allowing developers and reviewers to test all 3 user roles instantly without manual typing or Supabase rate-limits:

| Role | Email | Password | Access Scope |
| :--- | :--- | :--- | :--- |
| **👤 Customer** | `customer@savebite.com` | `password` | Discovery feed, Search, Orders, Favorites, Profile |
| **🍽️ Restaurant** | `restaurant@savebite.com` | `password` | Partner portal, Café Intelligence, Posts, Pickup flow |
| **⚡ Admin** | `admin@savebite.com` | `admin` | Moderation console, Partner approvals, Platform analytics |

---

## 🛠️ Tech Stack

| Technology | Purpose |
| :--- | :--- |
| **[Flutter](https://flutter.dev)** (Dart 3.x) | High-performance cross-platform UI toolkit targeting Android, iOS, Web, and Desktop |
| **[Material Design 3](https://m3.material.io)** | Design system with custom Crimson Red (`#D32F2F`), Warm Amber, and Deep Charcoal palette |
| **[Flutter Riverpod](https://riverpod.dev)** (`v3.4.3`) | Reactive, compile-safe state management, dependency injection, and state caching |
| **[GoRouter](https://pub.dev/packages/go_router)** (`v18.0.2`) | Declarative URL routing, role-based auth guards, deep linking, and `StatefulShellRoute` |
| **[Supabase Flutter](https://supabase.com)** (`v2.17.2`) | PostgreSQL database with Row Level Security (RLS), Auth, and Object Storage |
| **[Geolocator](https://pub.dev/packages/geolocator)** (`v14.1.1`) | Cross-platform GPS location detection and permissions handling |
| **[Geocoding](https://pub.dev/packages/geocoding)** (`v4.0.0`) | Reverse geocoding for human-readable address resolution |
| **[Shared Preferences](https://pub.dev/packages/shared_preferences)** (`v2.5.5`) | Local key-value cache for offline preferences, account persistence, and demo state |
| **[Image Picker](https://pub.dev/packages/image_picker)** (`v1.2.3`) | Image selection from gallery and camera for avatars and meal photos |

---

## 🏛️ Architecture & Design Pattern

SaveBite is engineered using a **Feature-First Architecture** combined with a unidirectional data flow and strict separation of concerns:

```
┌────────────────────────────────────────────────────────┐
│                   Presentation Layer                   │
│   (Screens, Stateful Shells, Modal Sheets, Theme)     │
└───────────────────────────┬────────────────────────────┘
                            │ listens to state / dispatches actions
┌───────────────────────────▼────────────────────────────┐
│                    Controller Layer                    │
│   (Riverpod Notifiers, StateNotifiers, AsyncValue)     │
└───────────────────────────┬────────────────────────────┘
                            │ delegates business logic
┌───────────────────────────▼────────────────────────────┐
│                    Repository Layer                    │
│   (Data Abstraction, Fallback Caching, Error Mapping)  │
└───────────────────────────┬────────────────────────────┘
                            │ executes queries / API calls
┌───────────────────────────▼────────────────────────────┐
│                   Data Source Layer                    │
│         (Supabase PostgreSQL, Auth, S3 Storage)        │
└────────────────────────────────────────────────────────┘
```

### Architectural Principles:
1. **Decoupled UI:** Widgets never communicate with data sources directly; they consume view states exposed by Riverpod controllers.
2. **Offline Resilience & Demo Fallback:** Repositories implement transparent demo fallback caching (`CustomerOfferRepository`, `AuthRepository`). If running in offline mode or against a fresh Supabase instance, the app seamlessly serves realistic mock records so testing is never blocked.
3. **Modal & Dialog Hierarchy:** Global `rootNavigatorKey` ensures modal bottom sheets and confirmation dialogs always render above bottom navigation bars and floating controls.

---

## 🛡️ Route Guards & Security Matrix

Navigation routes are dynamically guarded by `AppRouterNotifier` based on the user's authenticated profile role:

| Route Path | Customer | Restaurant Partner | Admin Moderator | Unauthenticated |
| :--- | :---: | :---: | :---: | :---: |
| `/login`, `/register`, `/forgot-password` | Redirects to Home | Redirects to Dashboard | Redirects to Admin | Allowed |
| `/customer/**` (Home, Search, Orders, Profile) | **Allowed** | Redirects to Dashboard | Redirects to Admin | Redirects to Login |
| `/restaurant/**` (Dashboard, Offers, Posts) | Redirects to Home | **Allowed** | Redirects to Admin | Redirects to Login |
| `/admin/**` (Approvals, Analytics, Users) | Redirects to Home | Redirects to Dashboard | **Allowed** | Redirects to Login |

---

## 📂 Folder Structure

```
lib/
├── core/
│   ├── constants/        # App colors, typography constants, Supabase keys
│   ├── errors/           # Custom exception models and failure handlers
│   ├── router/           # GoRouter configuration, AppRoutes, and auth guards
│   ├── supabase/         # Supabase client initializers and lifecycle setup
│   ├── theme/            # Material 3 theme data, color schemes, card styles
│   ├── utils/            # Price & discount calculators, validators, formatters
│   └── widgets/          # Shared atomic widgets (buttons, text fields, badges, animations)
│
├── features/
│   ├── admin/            # Admin moderation console, analytics sheets, partner approvals
│   ├── auth/             # Login, customer & restaurant registration, forgot password
│   ├── customer/         # Discovery feed, hot deals, search, orders, profile, favorites
│   ├── restaurant/       # Partner portal, café intelligence, posts, offers, pickup flows
│   └── shared/           # Splash screen, cross-feature models (PromoBanner), shared cards
│
└── main.dart             # Application root entry point with ProviderScope
```

---

## 🗄️ Database & Storage Schema

The PostgreSQL database is hosted on Supabase and protected with strict Row Level Security (RLS) policies:

### 1. `profiles` Table
Stores user credentials and platform roles tied to Supabase Auth UUIDs.
- `id` (UUID, Primary Key, references `auth.users.id`)
- `email` (TEXT, unique)
- `full_name` (TEXT)
- `phone` (TEXT)
- `role` (TEXT: `customer` | `restaurant` | `admin`)
- `avatar_url` (TEXT, optional)
- `is_active` (BOOLEAN, default: `true`)
- `created_at` / `updated_at` (TIMESTAMP WITH TIME ZONE)

### 2. `restaurants` Table
Stores restaurant partner metadata, operating schedule, and approval states.
- `id` (UUID, Primary Key)
- `owner_id` (UUID, references `profiles.id`)
- `name` (TEXT)
- `description` (TEXT)
- `phone` (TEXT)
- `address` (TEXT)
- `division` / `area` (TEXT)
- `image_url` (TEXT)
- `cuisine_type` (TEXT)
- `opening_time` / `closing_time` (TIME)
- `status` (TEXT: `pending` | `approved` | `rejected` | `suspended`)
- `created_at` / `updated_at` (TIMESTAMP WITH TIME ZONE)

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
- `available_from` / `available_until` (TIMESTAMP WITH TIME ZONE)
- `is_active` (BOOLEAN, default: `true`)
- `created_at` / `updated_at` (TIMESTAMP WITH TIME ZONE)

### 4. `orders` Table
Tracks customer surplus meal reservations and live pickup status.
- `id` (UUID, Primary Key)
- `customer_id` (UUID, references `profiles.id`)
- `restaurant_id` (UUID, references `restaurants.id`)
- `offer_id` (UUID, references `offers.id`)
- `quantity` (INTEGER)
- `total_price` (NUMERIC)
- `status` (TEXT: `pending` | `confirmed` | `ready_for_pickup` | `picked_up` | `cancelled`)
- `pickup_deadline` (TIMESTAMP WITH TIME ZONE)
- `created_at` (TIMESTAMP WITH TIME ZONE)

### 5. `promo_banners` Table
Manages active hero promotional banners displayed across the customer feed.
- `id` (TEXT / UUID, Primary Key)
- `title` (TEXT)
- `subtitle` (TEXT)
- `image_url` (TEXT)
- `badge_text` (TEXT)
- `action_url` (TEXT)
- `is_active` (BOOLEAN, default: `true`)
- `priority` (INTEGER)

### 6. `reviews` Table
Stores customer reviews, 1-to-5 star ratings, and food photo attachments with verified takeaway rescue badges.
- `id` (UUID, Primary Key)
- `order_id` (UUID, references `orders.id`, UNIQUE constraint)
- `customer_id` (UUID, references `profiles.id`)
- `restaurant_id` (UUID, references `restaurants.id`)
- `offer_id` (UUID, references `offers.id`, optional)
- `rating` (NUMERIC(2,1), range `1.0` to `5.0`)
- `comment` (TEXT, customer feedback description)
- `image_url` (TEXT, optional attached food picture)
- `is_verified` (BOOLEAN, default: `true` for completed pickup orders)
- `created_at` / `updated_at` (TIMESTAMP WITH TIME ZONE)

### Supabase Storage Buckets
- `avatars`: User profile photos.
- `restaurant-images`: Restaurant storefront and interior imagery.
- `offer-images`: Food photos for surplus meal listings.
- `banner-images`: Hero promotional banner assets.
- `review-images`: Customer-uploaded food review photographs.

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.4` or later)
- [Dart SDK](https://dart.dev/get-dart)
- [Git](https://git-scm.com/)
- Android Studio, Xcode, or Google Chrome (depending on your target platform)

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

SaveBite connects to Supabase via standard public environment variables. You can configure live backend credentials at runtime using `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
```

> ⚠️ **Security Notice:**  
> Never include the Supabase `service_role` secret in Flutter client code or check it into version control. Only supply the public `anon` key.

### Running the App

- **On Android Emulator / Device:**
  ```bash
  flutter run
  ```
  *(Windows developers can run `run_app_on_emulator.bat` to automatically launch the configured Android emulator and start the app.)*

- **On Google Chrome (Web):**
  ```bash
  flutter run -d chrome
  ```

- **On Windows Desktop:**
  ```bash
  flutter run -d windows
  ```

---

## 🧪 Testing & Quality Assurance

SaveBite enforces strong automated test coverage across models, repositories, business logic, and widget trees.

### Run Automated Test Suite
```bash
flutter test
```
*Current test suite: **134 passing tests** verifying authentication states, price calculators, repository query filters, order pickup transitions, modal sheet routing, and UI widget flows.*

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

1. **Surplus Offer Visibility Rule:**  
   An offer is visible to customers **only if**:
   - `restaurant.status == 'approved'`
   - `offer.is_active == true`
   - `currentTime < offer.available_until`
   - `offer.quantity > 0`

2. **Pricing & Discount Integrity:**  
   - `original_price > 0` and `discounted_price > 0`
   - `discounted_price <= original_price`
   - Discount percentage is calculated dynamically:
     $$\text{Discount \%} = \left(\frac{\text{original\_price} - \text{discounted\_price}}{\text{original\_price}}\right) \times 100$$

3. **Currency & Localization:**  
   - Prices are formatted in Bangladeshi Taka (`৳` BDT).
   - District navigation natively supports Bangladesh administrative divisions (*Dhaka, Chittagong, Sylhet, etc.*) and prime culinary zones (*Dhanmondi, Gulshan, Banani, Mirpur, Uttara*).

4. **Pickup Lifecycle Progression:**  
   $$\text{Pending} \longrightarrow \text{Confirmed} \longrightarrow \text{Ready for Pickup} \longrightarrow \text{Picked Up (Completed)}$$

5. **Data Fallback Resiliency:**  
   When running offline or against unseeded backends, repositories automatically supply realistic demo records so all UI workflows, charts, and interactions function flawlessly.

---

## 🗺️ Scope & Roadmap

### ✅ Completed Milestones
- [x] Multi-role authentication (Customer, Restaurant, Admin) with Google Sign-In & quick demo fill
- [x] Stateful shell navigation with persistent bottom bar state
- [x] Dynamic hero promotional banner carousel with custom presets
- [x] Customer discovery feed with category chips, countdowns, and discount tags
- [x] Division and area geolocation filters with GPS sheet
- [x] Hot Deals screen spotlighting 45%+ OFF surplus drops
- [x] Real-time search with debouncing and multi-attribute filters
- [x] Food offer details with portion disclosures and pickup deadline timers
- [x] Restaurant profile screen with operating schedule and active menu
- [x] Customer orders sheet with real-time pickup status pipeline
- [x] Customer favorites bookmarking system
- [x] Customer profile editing with monogram avatar fallbacks
- [x] Restaurant onboarding workflow with KYC validation
- [x] Restaurant partner portal with 5-tab floating pill navigation
- [x] Café Intelligence business analytics and Top Sellers breakdown
- [x] Surplus posts manager with live quantity adjustment and "Done" toggle
- [x] Merchant promotional boost packages (Banner & Boost) with Payment Portal sheet
- [x] Hero Banner Designer for Gold Merchants
- [x] Live pickup order management with high-visibility status cards
- [x] Partner notifications center
- [x] Admin oversight console with platform analytics, partner approvals, and user moderation
- [x] Material Design 3 design system with responsive layouts and custom loading animations
- [x] 134 automated unit, widget, and flow tests passing with zero errors

### 🔮 Future Roadmap
- [ ] Push notifications for instant flash surplus drops
- [ ] QR code generator and merchant scanner for instant pickup verification
- [ ] Integrated digital payment gateway webhooks (bKash, Nagad, Cards)
- [ ] Interactive live map view with geolocation clustering
- [ ] Customer reviews, ratings, and verified review badges
- [ ] Multi-branch restaurant management for enterprise food chains

---

## 🤝 Contributing

Contributions, feedback, and feature requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more details.
