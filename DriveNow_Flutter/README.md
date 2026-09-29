# DriveNow – Flutter (Android) version

Flutter version of the SwiftUI iOS app in `../DriveNow` — same cars, prices,
images and Firebase backend, with a redesigned, more professional UI.

## What's in version 2.0

**Redesigned UI** — layered navy theme, Poppins font, gradient buttons, floating pill
navigation bar, consistent cards, dialogs, bottom sheets and snackbars.

| Area | Improvements |
|---|---|
| Home | Greeting + avatar, **"All" category** (plus SUV, Sedan, Pickup, Luxury, Sports, Van with counts), search by name/brand/category, filter & sort sheet (price, rating, max price, seats), Top Rated carousel, 2-column car grid with favorite hearts |
| Car details | Large car stage, spec tiles, description, features, "good to know", similar cars, sticky price + Book Now bar |
| Registration | Inline validation, PH mobile number, password strength meter + checklist, confirm password, Terms/Privacy agreement |
| Login | Validation, "Remember me", forgot password (email reset link with Firebase) |
| Booking | Date-range picker + times, map search for pick-up location, inline payment choice, price breakdown, profile-completeness check (mobile + driver's license), double-booking warning, confirmation page with booking reference |
| Payments | GCash with MPIN boxes; card payment with live card preview, card-number (Luhn) check, brand detection, expiry validation, receipt sheet. Test card: `4242 4242 4242 4242` |
| My Rentals | Upcoming / Active / Past tabs, cancelled bookings kept in history, refund status, trip timeline, owner contact copy |
| Profile | Stats (trips, upcoming, favorites, spent), edit profile with photo (camera/gallery/remove), LTO license number + expiry, unsaved-changes guard |
| Settings | Notification toggles, default payment method, cloud/offline status, clear history, terms/privacy |
| Security | Change password with strength checklist, forgot-current-password email |
| Delete account | Shows exactly what will be deleted, optional reason, password + acknowledgement, final confirmation, wipes cloud **and** phone data |

## Project layout

```
lib/
  main.dart, theme.dart          app entry + design tokens
  models/                        Car, CarBooking, PaymentMethod, PurchaseHistoryItem
  services/                      AuthService (Firebase or offline), AppData (profile, bookings, favorites…)
  widgets/ui.dart                buttons, fields, cards, dialogs, snackbars…
  widgets/car_widgets.dart       car cards, favorite button, spec tiles
  screens/                       every screen
```

---

## Run it on your Android phone

### 1. One-time computer setup
1. Install Flutter: <https://docs.flutter.dev/get-started/install> (choose Android).
2. Install Android Studio (it brings the Android SDK), then run `flutter doctor`
   and fix anything it lists under **Android toolchain**
   (usually `flutter doctor --android-licenses`).

### 2. Prepare your phone
1. **Settings → About phone** → tap **Build number** 7 times (turns on Developer options).
2. **Settings → Developer options** → turn on **USB debugging**.
3. Plug the phone into the computer with a USB cable and tap **Allow** on the phone.
4. Check it's detected: `flutter devices`

### 3. Set up this project (only once)
Open a terminal **in this `DriveNow_Flutter` folder** and run:

- **Windows:** `setup_android.bat`
- **Mac / Linux:** `./setup_android.sh`

This generates the `android/` folder for your Flutter version, downloads the
packages, and applies DriveNow's settings (internet permission, app name,
icon, minimum Android version).

### 4. Run
```
flutter run
```

> **Updating to this version?** Run `flutter pub get` once (new package for "Remember me"),
> then `flutter run`.
>
> **Updating from version 1?** If you already ran the setup script before, you don't
> need to run it again — just run `flutter pub get` (to pick up the new font) and then
> `flutter run`. Requires Flutter 3.27 or newer (`flutter --version`).
The app installs and opens on your phone. Press `r` in the terminal to hot-reload
after editing code.

**Want an APK to keep on the phone?**
```
flutter build apk --release
```
The file is at `build/app/outputs/flutter-apk/app-release.apk` – copy it to the
phone and open it to install (allow "Install unknown apps" when asked).

---

## Accounts: offline mode vs Firebase

The app works **right away** in **offline mode**: sign-up, login, favorites,
bookings, purchase history and profile are saved on the phone.
(The welcome screen shows "Offline mode · accounts are saved on this phone".)

To use the **same Firebase project as the iOS app** (`drivenow-b63f5`), so accounts
created on the iPhone also work on Android:

```
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=drivenow-b63f5 --platforms=android
flutter run
```
`flutterfire configure` registers the Android app in Firebase, adds
`google-services.json`, and replaces `lib/firebase_options.dart`.
(Needs the Firebase CLI – `npm install -g firebase-tools` – and access to the
Firebase project.) The app detects Firebase automatically and syncs favorites,
bookings and purchase history to Firestore under `users/{uid}/…`, same as iOS.

## Remember me

Tick **Remember me** on the Login screen and your email **and** password are saved
encrypted on the phone (Android Keystore via `flutter_secure_storage`). Next time the
Login screen fills them in. Unticking it deletes the saved login immediately.

## Notes
- The map uses OpenStreetMap tiles and address lookup, so no Google Maps API key
  is needed. The phone needs internet for the map.
- GCash and credit card payments are simulated, same as the iOS app.
- Changing the email in **Settings** changes the profile display only; the login
  email stays the same (same as iOS).
