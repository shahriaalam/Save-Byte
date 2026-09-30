# **SaveBite V1**

## **Surplus Food Discovery Platform**

### **Document Version**

V1.0

### **Product Type**

Flutter mobile application with Supabase backend  
---

# **1\. Product Overview**

SaveBite is a platform that allows restaurants to publish safe, edible surplus food at discounted prices so customers can discover affordable food before the restaurant's closing/availability time.  
V1 has three user roles:

1. Customer  
2. Restaurant

3. Admin

The core V1 workflow is intentionally simple:  
Restaurant  
    ↓  
Creates food offer  
    ↓  
Publishes offer  
    ↓  
Admin can moderate offer  
    ↓  
Customer sees offer  
    ↓  
Customer views food/restaurant details

There is NO ordering or payment system in V1.  
---

# **2\. V1 Product Goal**

The purpose of V1 is to validate the basic marketplace concept:  
> Can restaurants easily publish surplus food, and can customers easily discover it?  
The application should be simple, stable, secure, and polished.  
Do not add unnecessary features.  
---

# **3\. User Roles**

## **3.1 Customer**

Customers can:

* Register  
* Login  
* Logout  
* View available food offers  
* Search food  
* Filter food by category  
* View food details  
* View restaurant details  
* View restaurant's active offers  
* Manage their own profile

Customers cannot:

* Create offers  
* Edit offers  
* Delete offers  
* Manage restaurants  
* Manage users  
* Access admin functionality

---

# **3.2 Restaurant**

Restaurants can:

* Register  
* Login  
* Logout  
* Create restaurant profile  
* Edit restaurant profile  
* Upload restaurant image  
* Create food offers  
* Edit their own offers  
* Activate/deactivate their own offers  
* Delete their own offers  
* Upload food images  
* View their own offers

Restaurants cannot:

* Modify another restaurant  
* Modify another restaurant's offers  
* Modify customers  
* Modify admins  
* Approve themselves  
* Access admin functionality

---

# **3.3 Admin**

Admin is the platform moderator.  
Admin can:

### **Users**

* View all users  
* Search users  
* View user details  
* Disable/enable users

### **Restaurants**

* View all restaurants  
* View restaurant details  
* Approve restaurant  
* Reject restaurant  
* Suspend restaurant  
* Reactivate restaurant  
* Remove/deactivate restaurant

### **Food Offers**

* View all offers  
* Search offers  
* Remove an offer  
* Deactivate an offer  
* Reactivate an offer if appropriate

Admin cannot directly impersonate users.  
---

# **4\. Scope of V1**

## **Included**

### **Authentication**

* Customer registration  
* Restaurant registration  
* Login  
* Logout  
* Password reset  
* Session persistence

### **Customer**

* Home  
* Search  
* Category filtering  
* Food details  
* Restaurant details  
* Profile

### **Restaurant**

* Restaurant profile  
* Restaurant dashboard  
* Create offer  
* Edit offer  
* Delete offer  
* Activate/deactivate offer

### **Admin**

* Admin dashboard  
* User management  
* Restaurant management  
* Offer management  
* Search  
* Suspend/deactivate functionality

### **Backend**

* Supabase Auth  
* PostgreSQL  
* Supabase Storage  
* Row Level Security

---

# **5\. Explicitly NOT Included**

Do not implement:

* Food ordering  
* Reservation  
* Cart  
* Payment  
* Delivery  
* QR code  
* QR scanner  
* Reviews  
* Ratings  
* Favorites  
* Push notifications  
* Chat  
* Maps  
* Live location  
* Restaurant analytics  
* Customer analytics  
* Revenue analytics  
* Coupons  
* Loyalty  
* Recommendations  
* Subscriptions  
* Commission calculation  
* Multiple restaurant branches  
* Advanced reporting  
* Messaging

These are future versions.  
Do not create fake/placeholder implementations for them.  
---

# **6\. Technology Stack**

Use:

* Flutter  
* Dart  
* Material 3  
* Riverpod  
* GoRouter  
* Supabase  
* PostgreSQL  
* Supabase Auth  
* Supabase Storage

Use current stable package versions compatible with the project's Flutter SDK.  
Avoid unnecessary dependencies.  
---

# **7\. Architecture**

Use a feature-first architecture with clear separation of responsibilities.  
Recommended architecture:  
UI  
 ↓  
Controller / Riverpod Provider  
 ↓  
Repository  
 ↓  
Supabase

The UI must not directly execute Supabase database queries.  
Example:  
OfferDetailsScreen  
       ↓  
OfferController  
       ↓  
OfferRepository  
       ↓  
Supabase

---

# **8\. Project Folder Structure**

Use:  
lib/  
│  
├── core/  
│   ├── constants/  
│   ├── errors/  
│   ├── router/  
│   ├── theme/  
│   ├── utils/  
│   └── widgets/  
│  
├── features/  
│   │  
│   ├── auth/  
│   │   ├── data/  
│   │   ├── domain/  
│   │   └── presentation/  
│   │  
│   ├── customer/  
│   │   ├── home/  
│   │   ├── search/  
│   │   ├── offers/  
│   │   ├── restaurants/  
│   │   └── profile/  
│   │  
│   ├── restaurant/  
│   │   ├── dashboard/  
│   │   ├── offers/  
│   │   ├── profile/  
│   │   └── settings/  
│   │  
│   ├── admin/  
│   │   ├── dashboard/  
│   │   ├── users/  
│   │   ├── restaurants/  
│   │   └── offers/  
│   │  
│   └── shared/  
│       ├── models/  
│       ├── repositories/  
│       └── widgets/  
│  
└── main.dart

Do not create giant files.  
Do not put all screens inside one folder.  
Do not put all database queries inside UI files.  
---

# **9\. Database Design**

Use PostgreSQL through Supabase.  
The core tables are:  
profiles  
restaurants  
offers

Optional supporting tables may be added only when genuinely required.  
Keep V1 database simple.  
---

# **10\. Profiles Table**

Table:  
profiles

Fields:  
id              UUID PRIMARY KEY  
email           TEXT  
full\_name       TEXT  
phone           TEXT  
role            TEXT  
avatar\_url      TEXT  
is\_active       BOOLEAN  
created\_at      TIMESTAMP  
updated\_at      TIMESTAMP

Role values:  
customer  
restaurant  
admin

`id` must match the authenticated Supabase user's ID.  
Default:  
is\_active \= true

---

# **11\. Restaurants Table**

Table:  
restaurants

Fields:  
id              UUID PRIMARY KEY  
owner\_id        UUID  
name            TEXT  
description     TEXT  
phone           TEXT  
address         TEXT  
image\_url       TEXT  
cuisine\_type    TEXT  
opening\_time    TIME  
closing\_time    TIME  
status          TEXT  
created\_at      TIMESTAMP  
updated\_at      TIMESTAMP

Restaurant status:  
pending  
approved  
rejected  
suspended

Relationship:  
profiles.id  
    ↓  
restaurants.owner\_id

V1 supports one restaurant per restaurant owner.  
Do not implement branches.  
---

# **12\. Offers Table**

Table:  
offers

Fields:  
id                  UUID PRIMARY KEY  
restaurant\_id       UUID  
title               TEXT  
description         TEXT  
image\_url           TEXT  
category            TEXT  
original\_price      NUMERIC  
discounted\_price    NUMERIC  
quantity            INTEGER  
available\_from      TIMESTAMP  
available\_until     TIMESTAMP  
is\_active           BOOLEAN  
created\_at          TIMESTAMP  
updated\_at          TIMESTAMP

Relationship:  
restaurants.id  
       ↓  
offers.restaurant\_id

---

# **13\. Offer Rules**

An offer is visible to customers only when:  
restaurant.status \= approved

AND:  
offer.is\_active \= true

AND:  
current\_time \< offer.available\_until

An offer must not be displayed to customers if:

* restaurant is suspended

* restaurant is rejected

* restaurant is removed

* offer is inactive

* offer availability has ended

Do not delete expired offers automatically.  
---

# **14\. Price Rules**

Original price:  
\> 0

Discounted price:  
\> 0

Discounted price:  
\<= original price

Example:  
Original: ৳500  
Discount: ৳250

Savings: ৳250  
Discount: 50%

Calculate savings in the application.  
Do not unnecessarily store calculated savings.  
Discount formula:  
((original\_price \- discounted\_price) / original\_price) \* 100

---

# **15\. Quantity Rules**

Quantity must be:  
\> 0

V1 does not implement real-time inventory deduction because customers cannot order or reserve food yet.  
The quantity is informational.  
Example:  
8 portions available

---

# **16\. Authentication**

Use Supabase Auth.  
Support:

* Email/password registration

* Email/password login

* Logout

* Password reset

* Persistent sessions

Registration flow:  
Create account  
       ↓  
Select role  
       ↓  
Customer OR Restaurant  
       ↓  
Create Supabase Auth user  
       ↓  
Create profiles record  
       ↓  
Route to appropriate application

Do NOT allow a user to register themselves as an admin.  
Admin accounts must be created securely by an existing administrator or through a controlled database/bootstrap process.  
Never expose an "Admin" option on the public registration screen.  
---

# **17\. Admin Bootstrap**

The first admin must be created securely.  
Possible development approach:

1. Create a normal Supabase Auth account.

2. Set the corresponding profile role to `admin` through a secure database migration/SQL script.

Do NOT allow:  
role \= admin

to be submitted from the Flutter registration form.  
Do NOT put a service-role key inside the Flutter application.  
---

# **18\. Role-Based Routing**

After authentication:  
role \== customer  
    ↓  
Customer application

role \== restaurant  
    ↓  
Restaurant application

role \== admin  
    ↓  
Admin application

Unauthenticated:  
Login

Do not rely only on hiding UI buttons.  
Backend RLS must also enforce authorization.  
---

# **19\. Customer Application**

Customer navigation:  
Home  
Search  
Profile

---

# **20\. Customer Home**

Home screen:  
Good evening 👋

Find affordable food near you

\[ Search food or restaurant \]

Available Food

\--------------------------------

Food Image

Chicken Biryani  
Rahman's Kitchen

৳150   ৳250  
Save ৳100

Available until 10:00 PM

\--------------------------------

Food Image

Beef Burger  
Burger House

৳120   ৳200  
Save ৳80

Available until 9:30 PM

\--------------------------------

Show active offers only.  
---

# **21\. Offer Card**

Create reusable:  
OfferCard

Display:

* Food image

* Food title

* Restaurant name

* Discounted price

* Original price

* Savings

* Availability end time

* Category

Optional:

* Discount percentage

Do not display an order button.  
---

# **22\. Customer Offer Details**

Screen:  
Food Image

Chicken Biryani

Rahman's Kitchen

৳150

Original price: ৳250

Save ৳100

Description

Fresh chicken biryani available  
at a discounted price.

Available quantity:  
8

Available:  
8:00 PM – 10:00 PM

Category:  
Rice

\[View Restaurant\]

There is no ordering functionality.  
---

# **23\. Restaurant Details**

Show:  
Restaurant image

Rahman's Kitchen

Description

Cuisine

Address

Opening hours

Available Offers

Below:  
Chicken Biryani  
৳150

Beef Tehari  
৳180

Chicken Roast  
৳200

Only active offers should be displayed.  
---

# **24\. Search**

Search should support:  
Food name  
Restaurant name  
Category

Example:  
Search: biryani

Results:  
Chicken Biryani  
Beef Biryani  
Kacchi Biryani

Search should be performed efficiently.  
Do not download the entire database unnecessarily.  
---

# **25\. Categories**

V1 categories:  
Rice  
Burger  
Pizza  
Bakery  
Snacks  
Drinks  
Dessert  
Other

Restaurant selects one category when creating an offer.  
Customer can filter by category.  
---

# **26\. Customer Profile**

Display:  
Profile image

Full name  
Email  
Phone

\[Edit Profile\]

\[Logout\]

Customer can update:

* name

* phone

* profile image

Customer cannot modify:

* role

* account status

* another user's profile

---

# **27\. Restaurant Application**

Restaurant navigation:  
Dashboard  
My Offers  
Profile

---

# **28\. Restaurant Dashboard**

Display:  
Good evening 👋

Restaurant Name

Active Offers  
3

\--------------------------------

Chicken Biryani  
৳150  
8 available

\[Edit\]

\--------------------------------

Beef Burger  
৳120  
5 available

\[Edit\]

\--------------------------------

\[ \+ Create Offer \]

Do not display revenue or order statistics in V1.  
---

# **29\. Restaurant Profile**

Restaurant can create/edit:  
Restaurant name  
Description  
Phone  
Address  
Cuisine type  
Opening time  
Closing time  
Restaurant image

Restaurant status should be visible:  
Pending  
Approved  
Suspended  
Rejected

If pending/rejected/suspended, clearly explain that the restaurant's offers are not visible to customers.  
---

# **30\. Restaurant Registration**

Restaurant registration:  
Name  
Email  
Password  
Phone

Restaurant name  
Restaurant description  
Address  
Cuisine type

\[Create Restaurant Account\]

After registration:  
status \= pending

The restaurant cannot publish customer-visible offers until approved by an admin.  
---

# **31\. Restaurant Approval**

Admin must approve restaurants before customers can see their offers.  
Workflow:  
Restaurant registers  
       ↓  
status \= pending  
       ↓  
Admin reviews  
       ↓  
Approve  
       ↓  
status \= approved  
       ↓  
Restaurant becomes visible

Reject:  
status \= rejected

Suspend:  
status \= suspended

---

# **32\. Create Offer**

Restaurant form:  
Food image  
\[Upload\]

Food name  
\[\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\]

Description  
\[\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\]

Category  
\[Select\]

Original price  
\[\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\]

Discounted price  
\[\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\]

Quantity  
\[\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\]

Available from  
\[Date & Time\]

Available until  
\[Date & Time\]

\[Publish Offer\]

---

# **33\. Create Offer Validation**

Required:

* Food name

* Description

* Category

* Original price

* Discounted price

* Quantity

* Available from

* Available until

Validation:  
title \!= empty

description \!= empty

original\_price \> 0

discounted\_price \> 0

discounted\_price \<= original\_price

quantity \> 0

available\_until \> available\_from

Image is optional.  
---

# **34\. Restaurant Offer Management**

Restaurant can:  
Create  
Read  
Update  
Deactivate  
Reactivate  
Delete

But only for its own offers.  
Example:  
My Offers

ACTIVE

Chicken Biryani  
৳150  
\[Edit\] \[Deactivate\]

INACTIVE

Beef Burger  
৳120  
\[Edit\] \[Activate\]

---

# **35\. Admin Application**

Admin navigation:  
Dashboard  
Users  
Restaurants  
Offers

Keep the admin UI simple.  
---

# **36\. Admin Dashboard**

V1 dashboard:  
Admin Dashboard

Users  
125

Restaurants  
18

Pending Restaurants  
3

Active Offers  
42

These are simple counts only.  
No advanced analytics.  
---

# **37\. Admin Users Screen**

Display:  
Users

\[ Search users \]

\--------------------------------

Rahim Ahmed  
Customer  
Active

\[View\]

\--------------------------------

Karim Restaurant  
Restaurant  
Active

\[View\]

Admin can:

* Search

* View user

* Disable user

* Enable user

Do not allow admin to change user role through the normal UI in V1.  
Role changes should remain a controlled administrative/database operation.  
---

# **38\. Disable User**

When admin disables a user:  
profiles.is\_active \= false

A disabled user must not be able to use the application normally.  
At login/session handling:  
if profile.is\_active \== false  
    deny application access

Their historical data should NOT be deleted.  
Prefer soft-disable over destructive deletion.  
---

# **39\. Admin Restaurant Screen**

Display:  
Restaurants

\[ Search \]

Pending  
Approved  
Suspended  
Rejected

\--------------------------------

Rahman's Kitchen  
Pending

\[View\]

Admin can:

* View

* Approve

* Reject

* Suspend

* Reactivate

---

# **40\. Restaurant Actions**

## **Approve**

pending → approved

## **Reject**

pending → rejected

## **Suspend**

approved → suspended

## **Reactivate**

suspended → approved

Do not permanently delete restaurants in V1 unless absolutely necessary.  
Use status changes instead.  
---

# **41\. What Happens When Restaurant Is Suspended?**

Immediately hide its offers from customers.  
Existing offers remain in the database.  
The restaurant owner can see:  
Your restaurant is currently suspended.

Your offers are not visible to customers.  
Please contact the platform administrator.

The restaurant cannot create new active customer-visible offers while suspended.  
---

# **42\. Admin Offer Management**

Admin screen:  
Offers

\[ Search \]

\--------------------------------

Chicken Biryani  
Rahman's Kitchen  
৳150

Active

\[View\] \[Deactivate\]

Admin can:

* View offer

* Deactivate offer

* Reactivate offer where appropriate

* Delete offer if necessary

---

# **43\. Admin Deactivating an Offer**

When admin deactivates an offer:  
offers.is\_active \= false

Customer cannot see it.  
Restaurant can see:  
This offer has been deactivated by an administrator.

The restaurant should not automatically reactivate an admin-deactivated offer.  
This requires an additional concept.  
---

# **44\. Offer Moderation Fields**

To properly distinguish restaurant-controlled deactivation from admin moderation, add:  
is\_active BOOLEAN  
admin\_blocked BOOLEAN

Offer visibility requires:  
is\_active \= true  
AND  
admin\_blocked \= false  
AND  
restaurant.status \= approved  
AND  
available\_until \> current\_time

Restaurant can change:  
is\_active

Restaurant cannot change:  
admin\_blocked

Admin can change:  
admin\_blocked

This prevents a restaurant from immediately reactivating an offer that an admin blocked.  
---

# **45\. Restaurant Moderation Fields**

Restaurant table should also support:  
status

Admin controls status.  
Restaurant cannot change its own approval/suspension status.  
---

# **46\. Security Model**

Security is critical.  
Do NOT trust:  
Flutter UI

for authorization.  
Authorization must be enforced by Supabase/PostgreSQL RLS.  
---

# **47\. Customer RLS**

Customers can:

### **Read**

* approved restaurants

* active customer-visible offers

### **Update**

* own profile

Customers cannot:

* create offers

* modify offers

* delete offers

* modify restaurants

* modify users

* modify admin data

---

# **48\. Restaurant RLS**

Restaurant owners can:

### **Read**

* own restaurant

* own offers

### **Create**

* own restaurant offers

### **Update**

* own restaurant

* own offers

### **Delete**

* own offers

Restaurant owner can change:  
is\_active

Restaurant owner cannot change:  
admin\_blocked

Restaurant owner cannot change:  
status

---

# **49\. Admin RLS**

Admin can:

* Read all profiles

* Read all restaurants

* Read all offers

* Update allowed moderation fields

* Disable/enable users

* Approve/reject/suspend restaurants

* Block/unblock offers

Admin authorization must be based on a secure server/database role.  
Do not trust:  
role \== admin

from client-provided data.  
---

# **50\. Important Security Rule**

Never put the Supabase service-role key inside Flutter.  
The Flutter application may contain the Supabase anonymous/public key as appropriate for Supabase client usage, but privileged service credentials must remain server-side.  
---

# **51\. Storage**

Use Supabase Storage buckets:  
avatars  
restaurant-images  
offer-images

Recommended organization:  
avatars/{user\_id}/profile.jpg

restaurant-images/{restaurant\_id}/image.jpg

offer-images/{restaurant\_id}/{offer\_id}/image.jpg

Storage policies must ensure users cannot arbitrarily overwrite another user's private assets.  
Public/read access should be designed intentionally.  
---

# **52\. Loading States**

Every screen that loads backend data must have:  
Loading  
Success  
Empty  
Error

Example:  
Loading...

Empty:  
No offers available right now.

Error:  
Unable to load offers.  
Please try again.

---

# **53\. Error Handling**

Handle:

* Network failure

* Authentication failure

* Session expiration

* Permission denied

* Database failure

* Image upload failure

* Invalid input

* Restaurant not approved

* Restaurant suspended

* Offer unavailable

Never display raw Supabase/PostgreSQL exceptions to users.  
---

# **54\. Search UX**

Search bar:  
\[ 🔍 Search food or restaurant \]

Search should support:

* Food title

* Restaurant name

Category filter:  
All  
Rice  
Burger  
Pizza  
Bakery  
Snacks  
Drinks  
Dessert  
Other

Keep search simple in V1.  
---

# **55\. UI Design**

Use Material 3\.  
Brand direction:  
Primary: Emerald/Green  
Secondary: Warm Orange  
Background: Warm White  
Text: Dark Charcoal

The UI should communicate:

* Affordable

* Fresh

* Sustainable

* Simple

* Trustworthy

Do not overuse environmental imagery.  
Food should remain the visual focus.  
---

# **56\. Reusable Components**

Create:  
OfferCard  
RestaurantCard  
AdminUserCard  
AdminRestaurantCard  
AdminOfferCard

PriceDisplay  
DiscountBadge  
CategoryChip  
SearchBar

PrimaryButton  
SecondaryButton  
AppTextField

LoadingState  
EmptyState  
ErrorState

ConfirmDialog  
StatusBadge

Use these throughout the application.  
---

# **57\. Confirmation Dialogs**

Destructive actions must require confirmation.  
Example:  
Deactivate Offer?

This offer will no longer be  
visible to customers.

\[Cancel\] \[Deactivate\]

For admin:  
Suspend Restaurant?

All offers from this restaurant  
will be hidden from customers.

\[Cancel\] \[Suspend\]

---

# **58\. Soft Delete Principle**

Do not permanently delete important records whenever possible.  
Prefer:  
is\_active \= false

or:  
status \= suspended

This keeps the system recoverable.  
For V1, deletion can exist for restaurant-owned offers, but admin moderation should primarily use deactivation/blocking.  
---

# **59\. Data Validation**

Backend validation is required in addition to Flutter validation.  
Do not assume that Flutter validation is enough.  
Validate:

* prices

* quantity

* dates

* role

* ownership

* status transitions

at the database/backend level where appropriate.  
---

# **60\. Database Indexes**

Create indexes for common queries.  
At minimum:  
offers.restaurant\_id

offers.category

offers.is\_active

offers.available\_until

restaurants.owner\_id

restaurants.status

profiles.role

profiles.is\_active

Consider composite indexes for the actual customer feed query.  
Do not create unnecessary indexes.  
---

# **61\. Customer Feed Query**

Customer feed should only return:  
approved restaurant  
\+  
active offer  
\+  
not admin blocked  
\+  
not expired

Conceptually:  
restaurants.status \= approved

AND offers.is\_active \= true

AND offers.admin\_blocked \= false

AND offers.available\_until \> now

The exact implementation should be optimized in PostgreSQL/Supabase rather than repeatedly filtering huge datasets in Flutter.  
---

# **62\. Restaurant Offer Visibility**

A restaurant owner should see:  
Active  
Inactive  
Admin Blocked  
Expired

Example:  
Chicken Biryani  
ACTIVE

Beef Burger  
INACTIVE

Pizza  
ADMIN BLOCKED

Cake  
EXPIRED

This helps restaurant owners understand why a post isn't visible.  
---

# **63\. Admin Audit Fields**

For moderation, add useful fields.  
Restaurants:  
approved\_at  
suspended\_at

Offers:  
blocked\_at  
blocked\_reason

Profiles:  
disabled\_at

These fields make the system easier to debug and demonstrate good engineering practice.  
---

# **64\. Admin Block Reason**

When admin blocks an offer:  
Block Offer

Reason:

\[\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\]

\[Cancel\] \[Block Offer\]

Store:  
blocked\_reason  
blocked\_at

Do not expose private admin notes unnecessarily to customers.  
Restaurant may see:  
This offer has been removed from public listing by an administrator.

Optionally show a short moderation reason to the restaurant.  
---

# **65\. Restaurant Approval Reason**

If rejected:  
Restaurant application rejected.

Reason:  
\[provided by admin\]

Add:  
rejection\_reason

to the restaurant table.  
---

# **66\. Admin Dashboard Counts**

Only simple counts:  
Total Users

Total Restaurants

Pending Restaurants

Approved Restaurants

Suspended Restaurants

Active Offers

Blocked Offers

No charts in V1.  
---

# **67\. Testing Requirements**

Write unit tests for:

* price calculation

* discount calculation

* offer validation

* role validation

* offer visibility rules

Widget tests for:

* Login

* Register

* OfferCard

* Create Offer

* Customer Home

* Admin restaurant list

* Admin offer list

Integration tests for:

* Customer registration

* Restaurant registration

* Restaurant creates offer

* Customer sees offer

* Admin approves restaurant

* Admin blocks offer

* Restaurant cannot modify another restaurant's offer

* Customer cannot create an offer

* Disabled user cannot access the application

---

# **68\. Critical Security Tests**

Verify:  
Customer → cannot create offer

Customer → cannot edit offer

Customer → cannot modify restaurant

Restaurant A → cannot edit Restaurant B's offer

Restaurant → cannot approve itself

Restaurant → cannot change its status

Restaurant → cannot change admin\_blocked

Normal user → cannot become admin

Disabled user → cannot use application

Admin → can moderate users/restaurants/offers

These tests are mandatory.  
---

# **69\. Development Milestones**

Build in this order.

## **Milestone 1**

Project foundation:

* Flutter

* theme

* routing

* architecture

* Riverpod

* Supabase configuration

---

## **Milestone 2**

Authentication:

* Customer signup

* Restaurant signup

* Login

* Logout

* Password reset

* Role routing

* Session management

---

## **Milestone 3**

Database:

* profiles

* restaurants

* offers

* migrations

* relationships

* indexes

* RLS

---

## **Milestone 4**

Restaurant:

* restaurant profile  
* dashboard  
* create offer  
* edit offer  
* activate/deactivate  
* delete offer  
* image upload

---

## **Milestone 5**

Customer:

* home  
* offer cards  
* offer details  
* restaurant details  
* search  
* categories

---

## **Milestone 6**

Admin:

* admin dashboard  
* users  
* restaurants  
* offers  
* approve  
* reject  
* suspend  
* reactivate  
* disable user  
* enable user  
* block offer  
* unblock offer

---

## **Milestone 7**

Polish:

* loading states  
* empty states  
* error states  
* validation  
* confirmation dialogs  
* image optimization  
* responsive UI  
* dark mode if desired

---

## **Milestone 8**

Testing:

* unit tests  
* widget tests  
* integration tests  
* RLS/security tests

---

# **70\. Definition of Done**

V1 is complete when:

## **Customer**

* Registration works

* Login works

* Logout works

* Home works

* Offers display correctly

* Search works

* Category filtering works

* Offer details work

* Restaurant details work

* Profile works

## **Restaurant**

* Registration works

* Login works

* Restaurant profile works

* Restaurant can create offers

* Restaurant can upload images

* Restaurant can edit offers

* Restaurant can deactivate offers

* Restaurant can reactivate offers

* Restaurant can delete offers

* Restaurant sees moderation status

## **Admin**

* Login works

* Dashboard works

* User list works

* User search works

* User disable/enable works

* Restaurant list works

* Restaurant search works

* Restaurant approval works

* Restaurant rejection works

* Restaurant suspension works

* Restaurant reactivation works

* Offer list works

* Offer search works

* Offer blocking works

* Offer unblocking works

## **Security**

* RLS enabled

* Customer permissions restricted

* Restaurant ownership enforced

* Admin permissions enforced

* Admin cannot be created through public signup

* Disabled users cannot access the application

* Service-role key is never exposed

## **Quality**

* `flutter analyze` passes

* Tests pass

* No major runtime errors

* No major TODO placeholders

* No duplicate business logic

* No giant widgets

* Loading/empty/error states exist

* Application is usable on Android

---

# **71\. AI Coding Agent Rules**

The AI coding agent MUST follow these rules.

### **Rule 1**

Do not build the entire application in one response.  
Implement one milestone at a time.

### **Rule 2**

Before changing existing code, inspect the relevant files.

### **Rule 3**

Do not overwrite working functionality unnecessarily.

### **Rule 4**

Do not create duplicate models, repositories, providers, or services.

### **Rule 5**

Do not put Supabase queries directly inside widgets.

### **Rule 6**

Do not bypass Row Level Security.

### **Rule 7**

Never expose service-role credentials.

### **Rule 8**

Do not implement features outside V1 scope.

### **Rule 9**

After every milestone run:  
flutter analyze  
flutter test

### **Rule 10**

Fix errors before moving to the next milestone.

### **Rule 11**

Database changes must be represented as migrations.

### **Rule 12**

Never silently change database schema.

### **Rule 13**

Use strongly requirement is ambiguous, inspect the existing architecture and choose the simplest implementation consistent with this specification typed Dart models.

### **Rule 14**

Business logic must be testable independently from UI.

### **Rule 15**

Use reusable widgets.

### **Rule 16**

All asynchronous operations need loading/error handling.

### **Rule 17**

Destructive actions require confirmation.

### **Rule 18**

Use soft deletion/moderation where appropriate.

### **Rule 19**

Do not trust client-provided roles or ownership.

### **Rule 20**

If a requirement is ambiguous, inspect the existing architecture and choose the simplest implementation consistent with this specification rather than adding new complexity.  
---

# **72\. AI Agent Starting Instruction**

When starting the project, the AI agent should first:

1. Inspect the Flutter environment.

2. Inspect the existing project files.

3. Check Flutter/Dart versions.

4. Create/verify project architecture.

5. Configure dependencies.

6. Configure Supabase.

7. Create the first database migration.

8. Implement authentication.

9. Run analyzer/tests.

10. Report the completed milestone.

The agent must NOT proceed to future milestones automatically.  
---

# **73\. V1 Final User Flow**

## **Customer**

Open App  
    ↓  
Login/Register  
    ↓  
Customer Home  
    ↓  
See available discounted food  
    ↓  
Search/filter  
    ↓  
Open food  
    ↓  
See details  
    ↓  
See restaurant

## **Restaurant**

Open App  
    ↓  
Register/Login  
    ↓  
Restaurant pending approval  
    ↓  
Admin approves  
    ↓  
Restaurant Dashboard  
    ↓  
Create Offer  
    ↓  
Publish  
    ↓  
Offer becomes visible

## **Admin**

Login  
    ↓  
Admin Dashboard  
    ↓  
Review pending restaurants  
    ↓  
Approve / Reject  
    ↓  
Monitor offers  
    ↓  
Block problematic offers  
    ↓  
Manage users  
    ↓  
Suspend problematic restaurants

---

# **74\. Core Product Principle**

V1 should answer one question:  
> Can SaveBite successfully connect restaurants with customers looking for discounted surplus food?  
Everything that does not help answer that question should be postponed.  
The application should prioritize:

1. Simplicity  
2. Reliability  
3. Security  
4. Clean UI  
5. Good architecture  
6. Correct role permissions

Do not sacrifice these for additional features.

### **How to give this to your AI agent**

I recommend **not** telling your agent:  
> “Build this whole document.”  
Instead, put the document into something like `PROJECT_SPEC.md` and give your agent this initial instruction:  
Read PROJECT\_SPEC.md completely.

You are developing SaveBite V1 according to that specification.

Do NOT implement the entire application at once.

Start with Milestone 1 only.

Before coding:  
1\. Inspect the existing project.  
2\. Inspect Flutter/Dart versions.  
3\. Inspect existing files and dependencies.  
4\. Identify anything that conflicts with PROJECT\_SPEC.md.

Then implement Milestone 1\.

After implementation:  
1\. Run dart format.  
2\. Run flutter analyze.  
3\. Run flutter test.  
4\. Fix all errors.  
5\. Summarize exactly what changed.  
6\. Do not start Milestone 2\.

Follow the architecture, security, role, and scope rules in PROJECT\_SPEC.md.  
Do not add features that are outside V1.

Then, once Milestone 1 is genuinely working, tell it:  
Milestone 1 is complete.

Now implement Milestone 2 from PROJECT\_SPEC.md only.

Inspect the current code first.  
Do not rewrite working code unnecessarily.  
Do not implement Milestone 3 or later.

After implementation, run formatting, flutter analyze, and tests.  
Fix all errors before reporting completion.

This **milestone-by-milestone approach is especially important when you're new**. It lets you understand what the AI is building instead of ending up with 50 files and no idea how the application works.  
And I would keep **V1 exactly at this scope**. The moment you have the three roles working and this loop works:  
**Admin approves restaurant → Restaurant posts discounted food → Customer discovers it → Admin can moderate it**  
you have a complete, presentable first version.

