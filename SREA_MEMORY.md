# SREA Project Memory – Complete Restoration File (Ultra‑Detailed)
> **Last updated:** May 11, 2026
> **Purpose:** Paste into a new chat to restore full context instantly.

---

## 1. Project Overview – The Big Picture

- **Full name:** San Rafael Emergency Alert System (SREA)
- **Client:** Municipal Disaster Risk Reduction and Management Office (MDRRMO), San Rafael, Bulacan, Philippines.
- **Goal:** Two mobile apps – one for residents/non‑residents to report emergencies and receive alerts, one for responders to manage incidents. A future admin web panel for MDRRMO staff.
- **Current stage (May 11, 2026):**
  - **User app** – fully integrated with real Laravel backend. All features (auth, incident reporting, polygon geofence, photo upload, profile, emergency call, alerts, announcements, traffic, notifications) work with real data. Resident can now see the assigned responder's name on their incident detail screen.
  - **Responder app** – fully integrated. All endpoints connected, authenticated, and tested. Profile picture upload working. App bar shows SREA logo with RESPONDER badge beside it.
  - **Laravel backend** – 100% ready. All endpoints built, migrations applied, seeded with test data.
  - **Admin panel** – not started.
  - **Push notifications** – not started.
- **Why this memory file exists:** So that in a new chat, the assistant doesn't waste time rediscovering architecture, file locations, or why certain fixes were applied. Every decision is documented here.

---

## 2. Tech Stack – Complete with Version Rationales

| Category | Technology | Version | Why chosen |
|----------|------------|---------|-------------|
| **Mobile framework** | Flutter | 3.27+, SDK `^3.11.4` | Cross‑platform, fast development, hot reload |
| **Language** | Dart | 3.6+ | Null safety, modern async, good integration |
| **Shared UI** | Local package `srea_shared` | – | Reuse widgets across two apps, centralised responsive theme |
| **Backend** | Laravel | 11.x | Easy API scaffolding, Sanctum built‑in, stable |
| **Database** | MySQL | 8.0 | Relational, used by client, full‑text search ready |
| **Authentication** | Laravel Sanctum | ^4.0 | Simple token auth, works with mobile, no OAuth complexity |
| **HTTP client** | `dio` | ^5.9.2 | Interceptors, form data, file upload, timeout control |
| **Secure storage** | `flutter_secure_storage` | ^10.0.0 | Encrypted Android SharedPreferences, iOS Keychain |
| **Image picker** | `image_picker` | ^1.2.1 | Camera + gallery, no external permissions hassle |
| **Image compression** | `flutter_image_compress` | ^2.1.0 | Reduces upload size (quality 70) – saves bandwidth |
| **Location** | `geolocator` + `geocoding` | ^14.0.2, ^4.0.0 | Get current coordinates, reverse geocoding (fallback) |
| **Maps** | `flutter_map` + `latlong2` | ^8.3.0, ^0.9.1 | Lightweight, no API key needed for OSM |
| **Polygon geofence** | Point‑in‑polygon custom logic | – | 34 barangay polygons – accurate barangay detection without GPS drift |
| **URL launcher** | `url_launcher` | ^6.3.2 | Dial phone, open external maps, email |
| **Date formatting** | `intl` | ^0.20.2 | Localised date strings |
| **Fonts** | `google_fonts` | ^8.0.2 | Plus Jakarta Sans (modern), Montserrat 900 italic (logo only) |
| **Responsive design** | Custom MediaQuery scaling | – | No fixed pixel values; all sizes relative to screen width |

---

## 3. Architecture – One Backend, Three Clients (Detailed)

```
                  ┌─────────────────────────────────────────────┐
                  │           Laravel Backend (admin_backend)    │
                  │  - routes/api.php (REST)                     │
                  │  - Sanctum token authentication              │
                  │  - MySQL database                            │
                  └─────────────────────────────────────────────┘
                                    │
            ┌───────────────────────┼───────────────────────────┐
            │                       │                           │
            ▼                       ▼                           ▼
   ┌─────────────────┐    ┌─────────────────┐        ┌─────────────────┐
   │ mobile_user_app │    │mobile_responder │        │ Admin Web Panel │
   │   (Flutter)     │    │   _app (Flutter) │        │   (not started) │
   │ - residents     │    │ - responders    │        │ - MDRRMO staff  │
   │ - non-residents │    │ - only responders│       │ - manage all    │
   └─────────────────┘    └─────────────────┘        └─────────────────┘
```

### User Roles (single `users` table)

| Role | Allowed in | Permissions |
|------|------------|-------------|
| `resident` | mobile_user_app | Report incidents, view alerts/announcements/traffic, emergency call, complete profile |
| `non_resident` | mobile_user_app | Same as resident but cannot become verified; badge shows "Non‑Resident" |
| `responder` | mobile_responder_app | View all incidents, respond, reassign, resolve, add notes |
| `admin` | future admin panel | Full CRUD on users, incidents, content |

### Login Restriction (`client_type` parameter)

| `client_type` | Allowed roles |
|---------------|---------------|
| `user`        | `resident`, `non_resident` |
| `responder`   | `responder`, `admin` |
| `admin`       | `admin` |

---

## 4. Monorepo Folder Structure – Every File Explained

```
C:/Users/user/flutter_projects/srea_system/
│
├── admin_backend/                 ← Laravel root
│   ├── app/
│   │   ├── Http/Controllers/Api/
│   │   │   ├── AuthController.php          – login, logout, user profile (includes incident counts for responders)
│   │   │   ├── UserController.php          – update profile, upload profile image (saves absolute URL to DB)
│   │   │   ├── IncidentController.php      – responder endpoints: index, show, respond, reassign, resolve, updateNotes
│   │   │   └── User/
│   │   │       ├── AlertController.php
│   │   │       ├── AnnouncementController.php
│   │   │       ├── TrafficController.php
│   │   │       ├── EmergencyCallController.php
│   │   │       ├── IncidentController.php       – store, myIncidents, show (user app, eager loads assignedTo)
│   │   │       └── UploadController.php         – incident photos ONLY → relative path, NOT profile pictures
│   │   └── Models/
│   │       ├── User.php         – $fillable includes profile_image (REQUIRED or upload silently fails)
│   │       ├── Incident.php     – relationships: reporter(), assignedTo(), responder() (alias), escalatedBy()
│   │       ├── Alert.php
│   │       ├── Announcement.php
│   │       ├── TrafficAdvisory.php
│   │       └── EmergencyCall.php
│   ├── database/migrations/
│   │   ├── 0001_01_01_000000_create_users_table.php
│   │   ├── 2026_04_29_063608_add_role_and_barangay_to_users_table.php
│   │   ├── 2026_04_29_063750_create_incidents_table.php
│   │   ├── 2026_04_29_075558_create_alerts_table.php
│   │   ├── 2026_04_29_075559_create_announcements_table.php
│   │   ├── 2026_04_29_075559_create_traffic_advisories_table.php
│   │   ├── 2026_04_29_075602_create_emergency_calls_table.php
│   │   └── 2026_05_03_062559_add_profile_image_to_users_table.php
│   └── routes/api.php
│
├── mobile_responder_app/
│   ├── lib/
│   │   ├── main.dart             – entry point, AuthCheckScreen (checks stored token on startup)
│   │   ├── models/
│   │   │   └── incident_report_model.dart  – includes assignedToName, responderNotes, escalation fields
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart           – navigates to HomeScreen (NOT IncidentListScreen) on success
│   │   │   │   ├── forgot_password_screen.dart
│   │   │   │   └── reset_password_screen.dart
│   │   │   ├── home_screen.dart                – IndexedStack (IncidentListScreen, ProfileScreen), app bar with SREA logo + RESPONDER badge (beside logo) + bell icon, bottom nav
│   │   │   ├── incident_list_screen.dart       – NO Scaffold (lives inside HomeScreen); uses ColoredBox for background; SreaDropdown wrapped in Material (self-contained)
│   │   │   ├── incident_detail_screen.dart     – detail, action buttons, map, full-screen photo
│   │   │   ├── profile_screen.dart             – StatefulWidget; fetches real user data; profile picture upload; real incident counts; tappable stat cards
│   │   │   └── notifications_screen.dart       – mock data
│   │   └── services/
│   │       └── api_service.dart                – all API methods including uploadProfileImage, compressImage, getFullImageUrl
│   └── pubspec.yaml
│
├── mobile_user_app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   │   └── incident_report_model.dart  – includes assignedToName field (shows responder name to resident)
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   ├── forgot_password_screen.dart
│   │   │   │   └── reset_password_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── profile_screen.dart             – profile picture upload, gender normalisation fix
│   │   │   ├── incident_reports_screen.dart    – maps assignedToName from json['assigned_to']['name']
│   │   │   ├── incident_report_detail_screen.dart  – shows assigned responder name with "On it" badge, or "Awaiting assignment" placeholder
│   │   │   ├── report_incident_screen.dart
│   │   │   ├── announcements_screen.dart
│   │   │   ├── traffic_advisories_screen.dart
│   │   │   ├── notifications_screen.dart
│   │   │   └── ...
│   │   ├── services/
│   │   │   └── api_service.dart
│   │   └── widgets/
│   │       ├── srea_sidebar.dart
│   │       └── srea_bottom_nav.dart
│   └── pubspec.yaml
│
└── srea_shared/
    ├── lib/
    │   ├── srea_shared.dart
    │   ├── theme/
    │   │   ├── colors.dart
    │   │   ├── typography.dart    – responsive, requires BuildContext
    │   │   ├── spacing.dart       – responsive, requires BuildContext
    │   │   └── radius.dart        – static constants
    │   └── widgets/
    │       ├── srea_button.dart
    │       ├── srea_input.dart    – CRITICAL FIX: SreaDropdown wraps DropdownButtonFormField in Material(color: Colors.transparent); uses value: not initialValue:
    │       ├── srea_radio_option.dart
    │       ├── srea_image_upload.dart
    │       ├── srea_badge.dart
    │       └── srea_card.dart
    └── pubspec.yaml
```

---

## 5. Responsive Theme System

All spacing and typography **require `BuildContext`** and scale with screen width.

### Scaling
- **Base width:** 375. Scale factor = `(width / 375).clamp(0.85, 1.1)`.

### `spacing.dart`
```dart
static double xs(BuildContext context)   // 4pt scaled
static double sm(BuildContext context)   // 8pt scaled
static double md(BuildContext context)   // 16pt scaled
static double lg(BuildContext context)   // 24pt scaled
static double xl(BuildContext context)   // 32pt scaled
static double xxl(BuildContext context)  // 48pt scaled
// Also: inputGap, inputLabelGap, sectionHeaderGap, sectionGap,
// cardGap, avatarGap, iconGap, listItemGap
// EdgeInsets: screenPadding, cardPadding, cardPaddingSmall, inputPadding
```

### `typography.dart`
```dart
static TextStyle headlineLarge(BuildContext context)
static TextStyle headlineSmall(BuildContext context)
static TextStyle titleLarge(BuildContext context)
static TextStyle bodyLarge(BuildContext context)
static TextStyle bodySmall(BuildContext context)
static TextStyle label(BuildContext context)
```

### `radius.dart` – static constants
```dart
static const double xs=4, sm=8, md=12, lg=16, xl=24, full=999
static BorderRadius get button, card, input, bottomSheet, modal, avatar, pill
```

### Key color tokens
| Token | Usage |
|---|---|
| `primary` / `primaryDark` / `primaryLight` | Main blue brand |
| `critical`, `high`, `medium`, `low` | Alert severity |
| `textPrimary`, `textSecondary`, `textHint`, `textOnPrimary` | Text |
| `surface`, `surfaceVariant`, `background`, `divider` | Layout |
| `error`, `buttonUpdate`, `buttonReport` | Actions |
| `bottomNavInactive` | Sidebar/nav inactive |
| `shadowColor` | Box shadows |

---

## 6. Critical Backend Rules

### `User.php` — `$fillable` MUST include `profile_image`

```php
protected $fillable = [
    'name', 'email', 'password', 'role', 'barangay', 'is_verified',
    'phone', 'gender', 'birth_date', 'street', 'province', 'municipality',
    'valid_id_type', 'valid_id_photo',
    'profile_image',  // ← WITHOUT THIS, update() silently does nothing
];
```

If `profile_image` is missing from `$fillable`, `$user->update(['profile_image' => $url])` is silently blocked by Laravel's mass assignment protection. The column stays `null`, no error is thrown.

### `UserController::uploadProfileImage` — returns and saves absolute URL

```php
public function uploadProfileImage(Request $request)
{
    $request->validate(['image' => 'required|image|mimes:jpeg,png,jpg|max:2048']);
    $file = $request->file('image');
    $filename = 'profile_' . $request->user()->id . '_' . time() . '.' . $file->getClientOriginalExtension();
    $path = $file->storeAs('profile_images', $filename, 'public');
    $url = url(Storage::url($path));  // absolute URL
    $request->user()->update(['profile_image' => $url]);
    return response()->json(['profile_image' => $url]);
}
```

### `UploadController::uploadImage` — incident photos ONLY

Saves to `incident_photos/`, returns relative path in `photo_path` key. **Do NOT use for profile pictures.**

### `User/IncidentController::myIncidents` and `show` — must eager load `assignedTo`

```php
$incidents = Incident::with(['reporter', 'assignedTo'])
    ->where('user_id', $request->user()->id)
    ->orderBy('reported_at', 'desc')
    ->get();
```

The Flutter user app reads `json['assigned_to']['name']` to show the responder's name. This only works if `assignedTo` is eager loaded.

### `AuthController::user` — returns incident counts for responders

```php
if ($user->isResponder()) {
    $data['incidents_handled'] = Incident::where('assigned_to', $user->id)
        ->where('status', 'Resolved')->count();
    $data['active_incidents'] = Incident::whereIn('status', ['Pending', 'Under Review'])
        ->count(); // system-wide, not filtered by assigned_to
} else {
    $data['incidents_handled'] = 0;
    $data['active_incidents'] = 0;
}
```

### `Incident.php` — relationships

```php
public function reporter()    { return $this->belongsTo(User::class, 'user_id'); }
public function assignedTo()  { return $this->belongsTo(User::class, 'assigned_to'); }
public function responder()   { return $this->belongsTo(User::class, 'assigned_to'); } // alias
public function escalatedBy() { return $this->belongsTo(User::class, 'escalated_by'); }
```

---

## 7. Profile Picture Upload — Architecture & Rules

### Two upload endpoints — NEVER mix them up

| | `uploadProfileImage` | `uploadImage` |
|---|---|---|
| **Flutter method** | `api.uploadProfileImage(File)` | `api.uploadImage(File)` |
| **Laravel controller** | `UserController::uploadProfileImage` | `UploadController::uploadImage` |
| **API route** | `POST /user/upload-profile-image` | `POST /user/upload-image` |
| **Saves to** | `profile_images/` | `incident_photos/` |
| **Returns** | Absolute URL in `profile_image` key | Relative path in `photo_path` key |
| **Updates DB** | ✅ Yes — saves to `users.profile_image` | ❌ No |
| **Use for** | Profile pictures only | Incident report photos only |

### Flutter upload flow (both apps — same pattern)

```dart
final absoluteUrl = await api.uploadProfileImage(compressed);
setState(() => _profileImageUrl = absoluteUrl);
// For user app, also notify sidebar:
widget.onProfileImageUpdated?.call(absoluteUrl);
```

### `getFullImageUrl` in both `api_service.dart` files

```dart
String? getFullImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;  // already absolute
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return '$baseImageUrl$normalizedPath';
}
```

---

## 8. `SreaDropdown` — Critical Fix (affects both apps)

**File:** `srea_shared/lib/widgets/srea_input.dart`

`DropdownButtonFormField` requires a `Material` ancestor AND uses `value:` not `initialValue:`.

```dart
Material(
  color: Colors.transparent,  // invisible, just provides Material ancestor
  child: DropdownButtonFormField<T>(
    value: effectiveValue,    // NOT initialValue — that param doesn't exist here
    ...
  ),
),
```

Without the `Material` wrapper, the dropdown crashes with "No Material widget found" when used inside `IndexedStack` or pushed as a standalone route. `Colors.transparent` ensures no visual change.

The `effectiveValue` guard prevents assertion errors:
```dart
final isValidValue = value == null || items.contains(value);
final effectiveValue = isValidValue ? value : null;
```

---

## 9. `IncidentListScreen` — Important Structural Note

`IncidentListScreen` has **NO `Scaffold`**. It is designed to live inside `HomeScreen`'s `IndexedStack`.

- ✅ Correct: `HomeScreen` → `IndexedStack` → `IncidentListScreen`
- ✅ Correct (when pushed standalone): Wrap in a `Scaffold` with app bar manually
- ❌ Wrong: `Navigator.push(... IncidentListScreen())` directly without a Scaffold wrapper

When pushing standalone (e.g. from profile stat cards):
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => Scaffold(
    backgroundColor: SreaColors.background,
    appBar: AppBar(
      backgroundColor: SreaColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: SreaColors.textOnPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Active Incidents', style: SreaText.titleLarge(context).copyWith(color: SreaColors.textOnPrimary)),
    ),
    body: const IncidentListScreen(initialFilter: 'active'),
  ),
));
```

The screen uses `ColoredBox(color: SreaColors.background)` as its root (not `Material`) to avoid creating a new `Material` layer that would hide the app bar.

---

## 10. Responder App — Home Screen App Bar

**File:** `mobile_responder_app/lib/screens/home_screen.dart`

The RESPONDER badge is placed **beside** (not below) the SREA logo using a `Row`:

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    RichText(...), // SREA logo
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: SreaRadius.pill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text('RESPONDER', style: ... fontSize: 9, fontWeight: w700, letterSpacing: 0.8),
        ],
      ),
    ),
  ],
)
```

Standard `kToolbarHeight` — no need for custom `toolbarHeight` since it's a single-line Row.

---

## 11. Responder Profile Screen

**File:** `mobile_responder_app/lib/screens/profile_screen.dart`

Converted from `StatelessWidget` to `StatefulWidget`. Key features:
- `_loadProfile()` on `initState` — fetches real user data via `api.getUser()`
- Reads `_user['name']`, `_user['email']`, `_user['incidents_handled']`, `_user['active_incidents']`
- Profile picture: `ClipOval` + `Image.network` with `cacheWidth: 200, cacheHeight: 200`
- Camera button overlay (bottom-right of avatar) opens bottom sheet (camera/gallery)
- Upload flow: `api.compressImage()` → `api.uploadProfileImage()` → `setState`
- Spinner shown inside avatar while uploading (`_isUploadingImage`)
- Logout calls `api.logout()` before navigating
- Stat cards navigate to standalone `IncidentListScreen` wrapped in `Scaffold`

---

## 12. Responder `api_service.dart` — Required Methods

The responder `api_service.dart` must include these methods (added during profile picture implementation):

```dart
// Needed imports
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cross_file/cross_file.dart';

// Methods
String? getFullImageUrl(String? path) { ... }
Future<String> uploadProfileImage(File imageFile) async { ... } // POST /user/upload-profile-image
Future<File> compressImage(File file) async { ... }            // local compression, quality 70
```

These are the same implementations as the user app's `api_service.dart`.

---

## 13. User App — Resident Sees Assigned Responder

**Feature:** Residents can see who is handling their incident report.

### How it works

1. **Backend** — `User/IncidentController::myIncidents` and `show` already eager load `assignedTo`:
   ```php
   Incident::with(['reporter', 'assignedTo'])->...
   ```
   The JSON response includes `assigned_to: { id, name, email, role, ... }` when assigned.

2. **Model** — `incident_report_model.dart` (user app) has `assignedToName` field:
   ```dart
   final String? assignedToName;
   ```

3. **Mapping** — `incident_reports_screen.dart` reads it:
   ```dart
   assignedToName: json['assigned_to'] != null
       ? (json['assigned_to']['name'] as String?)
       : null,
   ```

4. **Detail screen** — `incident_report_detail_screen.dart` shows:
   - If assigned: blue card with shield icon, responder name, "On it" green badge
   - If not assigned: muted "Awaiting responder assignment" placeholder

```dart
if (report.assignedToName != null && report.assignedToName!.isNotEmpty)
  Container(
    // blue card with responder name and "On it" badge
  )
else
  Container(
    // muted "Awaiting responder assignment"
  ),
```

---

## 14. Gender Dropdown Pre-fill Fix (User App Profile)

**File:** `mobile_user_app/lib/screens/profile_screen.dart`

The gender dropdown was not pre-filled because the API might return different casing (e.g. `"male"` vs `"Male"`). Fix: case-insensitive match against dropdown options.

```dart
// In _initializeControllers() and in the Edit button's setState:
final rawGender = _user['gender']?.toString();
_selectedGender = rawGender != null
    ? _genderOptions.firstWhere(
        (o) => o.toLowerCase() == rawGender.toLowerCase(),
        orElse: () => rawGender,
      )
    : null;
```

---

## 15. Navigation Rules

| Action | Method | Reason |
|--------|--------|--------|
| Login → Home | `pushReplacement` | Can't go back to login |
| Logout | `pushAndRemoveUntil` | Clears entire stack |
| Post-reset-password | `pushAndRemoveUntil` | Clears entire stack |
| Home → Profile/Detail | `push` + `.then(_loadData)` | Can go back |
| Profile stats → IncidentList | `push` with inline `Scaffold` | `IncidentListScreen` has no `Scaffold` |

**Critical responder app rule:** Always navigate to `HomeScreen` after login, never directly to `IncidentListScreen`.

---

## 16. Environment Setup

### Starting the backend
```bash
cd C:/Users/user/flutter_projects/srea_system/admin_backend
php artisan serve --host=127.0.0.1 --port=8080
```

### ADB reverse (USB debugging)
```bash
adb reverse tcp:8080 tcp:8080
```

### Running apps
```bash
flutter clean && flutter pub get && flutter run
```

### Wi-Fi (no USB)
Change `baseImageUrl` in both `api_service.dart` files to your PC's local IP (e.g. `http://192.168.1.100:8080`).

---

## 17. Current Status (May 11, 2026)

| Component | Status | Notes |
|-----------|--------|-------|
| `srea_shared` | ✅ Complete | Dropdown fix applied, all widgets responsive |
| User app — all screens | ✅ Complete | All integrated with real API |
| User app — resident sees responder | ✅ Complete | Shows assigned responder name in incident detail |
| Responder app — all screens | ✅ Complete | Fully integrated |
| Responder app — profile picture | ✅ Complete | Upload, display, persist |
| Responder app — app bar badge | ✅ Complete | RESPONDER badge beside SREA logo |
| Responder app — notifications | ⚠️ Mock | Not needed for MVP |
| Laravel backend | ✅ Complete | All endpoints tested |
| Admin panel | ❌ Not started | – |
| Push notifications | ❌ Not started | – |

---

## 18. Next Steps (Ordered)

1. **Deploy backend** to a live server for client testing.
2. **Build admin panel** (Filament) for MDRRMO to manage users, verify residents, moderate content.
3. **Push notifications** (FCM) — real-time alerts for both apps.
4. **Real-time incident updates** (WebSockets/Pusher) for responder app.
5. **Polish and final QA** before handover.

---

## 19. Known Issues & Fixes Applied (Complete History)

| Issue | Root Cause | Fix | Date |
|-------|-----------|-----|------|
| Profile picture `null` after upload | `profile_image` missing from `$fillable` in `User.php` | Added `'profile_image'` to `$fillable` | May 9 |
| Profile picture used wrong endpoint | `_uploadImage()` called incident endpoint | Changed to `api.uploadProfileImage()` | May 9 |
| Gender dropdown not pre-filled | Casing mismatch from API | Case-insensitive match in `_initializeControllers` and Edit button `setState` | May 9 |
| Responder dropdown crash | `initialValue` param doesn't exist on `DropdownButtonFormField` + missing `Material` ancestor | Changed to `value:`, wrapped in `Material(color: Colors.transparent)` in `srea_input.dart` | May 10 |
| Responder missing app bar after login | `login_screen.dart` navigated to `IncidentListScreen` (no Scaffold) instead of `HomeScreen` | Changed navigation target to `HomeScreen` | May 10 |
| IncidentListScreen black background | `Material()` wrapper with no color set defaulted to transparent/black | Replaced with `ColoredBox(color: SreaColors.background)` | May 10 |
| Profile stat cards crash (dropdown) | `IncidentListScreen` pushed without `Scaffold` | Wrapped in inline `Scaffold` with app bar | May 10 |
| Responder profile picture upload | `uploadProfileImage`, `compressImage`, `getFullImageUrl` missing from responder `api_service.dart` | Added all three methods + required imports | May 11 |
| RESPONDER badge under logo | Used `Column` layout | Changed to `Row` — badge now beside logo | May 11 |
| Resident can't see who handles their report | `assignedToName` not in user app model or detail screen | Added field to model, mapped from `assigned_to.name` in API response, displayed in detail screen | May 11 |
| `escalated_by` type mismatch | Backend returns `int`, model expects `String?` | Added `.toString()` | May 10 |
| Image memory warnings | No `cacheWidth`/`cacheHeight` | Added to all `Image.network` thumbnails | May 10 |
| `.withOpacity()` deprecated | Flutter deprecation | Replaced all with `.withValues(alpha:)` | May 9–10 |
| Laravel `Route [login] not defined` | Missing `Accept: application/json` header | Added in Dio interceptor | May 9 |
| Non-resident showing wrong badge | Missing `'Non-Resident'` case | Added to sidebar and home screen | May 9 |
| Registration not storing token | `register()` not saving token | Fixed in `api_service.dart` | May 9 |
| Barangay auto-fill inaccurate | Reverse geocoding text matching | Replaced with polygon-based point-in-polygon | May 9 |
| Incident photo URL broken | Relative path not resolved | Used `getFullImageUrl()` helper | May 9 |
| Duplicate migration `photo_path` | Extra migration file | Deleted file | May 10 |
| Missing Android INTERNET permission | Not in AndroidManifest | Added permission + `usesCleartextTraffic` | May 10 |

---

## 20. Memory File Purpose

Paste this file at the start of any new conversation to restore full SREA project context.

**Last updated:** May 11, 2026
