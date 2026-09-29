import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking.dart';
import '../models/car.dart';
import '../models/purchase.dart';
import '../utils/format.dart';
import 'auth_service.dart';

/// Replaces UserProfileManager, FavoritesManager, RentalManager and
/// PurchaseHistoryManager from the iOS app.
///
/// Everything is saved per user on the phone (SharedPreferences) and, when
/// Firebase is configured, also synced to Firestore under users/{uid}/...
/// using the same collections the iOS app uses.
class AppData extends ChangeNotifier {
  AppData._();
  static final AppData instance = AppData._();

  late SharedPreferences _prefs;
  String _userKey = 'default';
  final _random = Random();

  // Profile
  String fullName = '';
  String email = '';
  String phoneNumber = ''; // 10 digits after +63, e.g. 9171234567
  String licenseInfo = ''; // driver's license number
  DateTime? licenseExpiry;
  String city = '';
  String joinedDate = '';
  Uint8List? profileImage;

  // Preferences
  bool bookingReminders = true;
  bool promotions = false;
  PaymentMethod defaultPayment = PaymentMethod.cash;

  // Lists
  List<Car> favorites = [];
  List<CarBooking> bookings = [];
  List<PurchaseHistoryItem> purchases = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  AuthService get _auth => AuthService.instance;
  bool get _firebase => _auth.firebaseEnabled && _auth.uid != null;
  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(_auth.uid);

  String _k(String name) => 'u:$_userKey:$name';
  static String _keyFor(String email, String name) => 'u:${email.trim().toLowerCase()}:$name';

  // ------------------------------------------------------------ derived

  String get firstName {
    final n = fullName.trim();
    if (n.isEmpty) return 'there';
    return n.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get phoneDisplay => phoneNumber.length == 10
      ? '+63 ${phoneNumber.substring(0, 3)} ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}'
      : (phoneNumber.isEmpty ? '' : phoneNumber);

  bool get isLicenseExpired => licenseExpiry != null && licenseExpiry!.isBefore(DateTime.now());

  /// Needed before booking: phone, license number and a valid license.
  bool get isProfileComplete =>
      fullName.trim().isNotEmpty && phoneNumber.length == 10 && licenseInfo.trim().isNotEmpty && !isLicenseExpired;

  List<String> get missingProfileItems => [
        if (phoneNumber.length != 10) 'mobile number',
        if (licenseInfo.trim().isEmpty) "driver's license number",
        if (isLicenseExpired) "valid (non-expired) driver's license",
      ];

  int get completedTrips => bookings.where((b) => b.status == 'Completed').length;
  int get activeTrips => bookings.where((b) => b.status == 'Active' || b.status == 'Upcoming').length;

  int get totalSpent => purchases
      .where((p) => p.status == 'Paid' || p.status == 'Pay at pick-up')
      .fold(0, (sum, p) => sum + p.amount);

  // ------------------------------------------------------------ load / reset

  /// Saves name/phone right after sign-up so they appear after first login.
  Future<void> seedProfile({required String email, required String fullName, required String phone}) async {
    await _prefs.setString(
      _keyFor(email, 'profile'),
      jsonEncode({
        'fullName': fullName,
        'email': email.trim(),
        'phoneNumber': phone,
        'joinedDate': dateLong(DateTime.now()),
      }),
    );
  }

  /// Call after login / app start with an existing session.
  Future<void> loadForCurrentUser() async {
    _userKey = (_auth.email ?? 'default').toLowerCase();

    final profile = _readMap(_k('profile'));
    fullName = (profile['fullName'] as String?) ?? _auth.displayName ?? '';
    email = _auth.email ?? (profile['email'] as String?) ?? '';
    phoneNumber = (profile['phoneNumber'] as String?) ?? '';
    licenseInfo = (profile['licenseInfo'] as String?) ?? '';
    final exp = profile['licenseExpiry'];
    licenseExpiry = exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt()) : null;
    city = (profile['city'] as String?) ?? '';
    joinedDate = (profile['joinedDate'] as String?) ??
        _auth.joinedDate ??
        dateLong(_auth.firebaseCreationTime ?? DateTime.now());
    if (fullName.isEmpty) fullName = email.split('@').first;

    final prefs = _readMap(_k('prefs'));
    bookingReminders = (prefs['bookingReminders'] as bool?) ?? true;
    promotions = (prefs['promotions'] as bool?) ?? false;
    defaultPayment = PaymentMethod.fromLabel((prefs['defaultPayment'] as String?) ?? 'Cash');

    final photo = _prefs.getString(_k('photo'));
    profileImage = photo == null ? null : base64Decode(photo);

    favorites = _readList(_k('favorites')).map(Car.fromJson).toList();
    bookings = _readList(_k('bookings')).map(CarBooking.fromJson).toList();
    purchases = _readList(_k('purchases')).map(PurchaseHistoryItem.fromJson).toList();
    await _saveProfile();
    notifyListeners();

    // Sync from Firestore in the background (doesn't block login on slow internet).
    if (_firebase) {
      _loadFromFirestore();
    }
  }

  void clearInMemory() {
    _userKey = 'default';
    fullName = email = phoneNumber = licenseInfo = joinedDate = city = '';
    licenseExpiry = null;
    profileImage = null;
    favorites = [];
    bookings = [];
    purchases = [];
    bookingReminders = true;
    promotions = false;
    defaultPayment = PaymentMethod.cash;
    notifyListeners();
  }

  /// Removes everything stored on this phone for the current user.
  Future<void> deleteLocalDataForCurrentUser() async {
    for (final name in ['profile', 'prefs', 'photo', 'favorites', 'bookings', 'purchases']) {
      await _prefs.remove(_k(name));
    }
    clearInMemory();
  }

  /// Deletes the user's Firestore data (bookings, favorites, purchase history,
  /// profile). Must run while the user is still signed in.
  Future<void> deleteRemoteData() async {
    if (!_firebase) return;
    for (final sub in ['bookings', 'favorites', 'purchaseHistory']) {
      try {
        final snap = await _userDoc.collection(sub).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('Error deleting $sub: $e');
      }
    }
    try {
      await _userDoc.delete();
    } catch (e) {
      debugPrint('Error deleting user doc: $e');
    }
  }

  // ---------------------------------------------------------------- profile

  Future<void> saveProfile({
    required String fullName,
    required String phoneNumber,
    required String licenseInfo,
    required DateTime? licenseExpiry,
    required String city,
  }) async {
    this.fullName = fullName.trim();
    this.phoneNumber = phoneNumber;
    this.licenseInfo = licenseInfo.trim().toUpperCase();
    this.licenseExpiry = licenseExpiry;
    this.city = city.trim();
    await _saveProfile();
    await _auth.updateDisplayName(this.fullName);
    if (_firebase) {
      try {
        await _userDoc.set({
          'fullName': this.fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'city': this.city,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving profile to Firestore: $e');
      }
    }
    notifyListeners();
  }

  Future<void> setProfileImage(Uint8List? bytes) async {
    profileImage = bytes;
    if (bytes == null) {
      await _prefs.remove(_k('photo'));
    } else {
      await _prefs.setString(_k('photo'), base64Encode(bytes));
    }
    notifyListeners();
  }

  Future<void> _saveProfile() => _prefs.setString(
        _k('profile'),
        jsonEncode({
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'licenseInfo': licenseInfo,
          'licenseExpiry': licenseExpiry?.millisecondsSinceEpoch,
          'city': city,
          'joinedDate': joinedDate,
        }),
      );

  // ------------------------------------------------------------ preferences

  Future<void> setPreferences({bool? bookingReminders, bool? promotions, PaymentMethod? defaultPayment}) async {
    if (bookingReminders != null) this.bookingReminders = bookingReminders;
    if (promotions != null) this.promotions = promotions;
    if (defaultPayment != null) this.defaultPayment = defaultPayment;
    notifyListeners();
    await _prefs.setString(
      _k('prefs'),
      jsonEncode({
        'bookingReminders': this.bookingReminders,
        'promotions': this.promotions,
        'defaultPayment': this.defaultPayment.label,
      }),
    );
  }

  /// Clears favorites + purchase log + past rentals (keeps upcoming/active ones).
  Future<void> clearHistory() async {
    bookings.removeWhere((b) => b.isPast);
    purchases = purchases.where((p) => bookings.any((b) => 'p${b.id}' == p.id)).toList();
    notifyListeners();
    await _saveBookings();
    await _savePurchases();
  }

  // -------------------------------------------------------------- favorites

  bool isFavorite(Car car) => favorites.any((c) => c.id == car.id);

  /// Returns true if the car is now a favorite.
  Future<bool> toggleFavorite(Car car) async {
    final nowFav = !isFavorite(car);
    if (nowFav) {
      favorites.add(car);
    } else {
      favorites.removeWhere((c) => c.id == car.id);
    }
    notifyListeners();
    await _writeList(_k('favorites'), favorites.map((c) => c.toJson()).toList());
    if (_firebase) {
      try {
        await _userDoc.collection('favorites').doc('favoritesList').set({
          'cars': favorites.map((c) => c.toJson()).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error saving favorites to Firestore: $e');
      }
    }
    return nowFav;
  }

  // --------------------------------------------------------------- bookings

  String newTransactionId(PaymentMethod method) {
    final prefix = switch (method) {
      PaymentMethod.creditCard => 'CC',
      PaymentMethod.gcash => 'GC',
      PaymentMethod.cash => 'CS',
    };
    return '$prefix${100000 + _random.nextInt(900000)}';
  }

  /// An existing (not cancelled/completed) booking of the same car that
  /// overlaps the requested dates, if any.
  CarBooking? overlappingBooking(Car car, DateTime start, DateTime end) {
    for (final b in bookings) {
      if (b.carName != car.name || b.isPast) continue;
      if (start.isBefore(b.returnDate) && end.isAfter(b.pickUpDate)) return b;
    }
    return null;
  }

  /// Saves the rental + the purchase log entry (BookingScreen.finalizeBooking).
  Future<CarBooking> addBooking({
    required Car car,
    required DateTime pickUpDate,
    required DateTime returnDate,
    required String location,
    required PaymentMethod method,
    required int totalAmount,
    String? transactionId,
  }) async {
    final now = DateTime.now();
    final txn = transactionId ?? newTransactionId(method);
    final booking = CarBooking(
      id: '${now.microsecondsSinceEpoch}${_random.nextInt(9999)}',
      carName: car.name,
      imageName: car.imageName,
      pricePerDay: car.pricePerDay,
      pickUpDate: pickUpDate,
      returnDate: returnDate,
      location: location,
      createdAt: now,
      paymentMethod: method.label,
      transactionId: txn,
    );
    final purchase = PurchaseHistoryItem(
      id: 'p${booking.id}',
      paymentMethod: method.label,
      date: now,
      carName: car.name,
      totalAmount: totalAmount.toString(),
      transactionID: txn,
    );

    bookings.add(booking);
    purchases.insert(0, purchase);
    notifyListeners();
    await _saveBookings();
    await _savePurchases();

    if (_firebase) {
      try {
        final ref = await _userDoc.collection('bookings').add({
          'bookingId': booking.id,
          'carName': car.name,
          'carCategory': car.category,
          'carPricePerDay': car.pricePerDay,
          'imageName': car.imageName,
          'pickUpDate': Timestamp.fromDate(pickUpDate),
          'returnDate': Timestamp.fromDate(returnDate),
          'location': location,
          'totalAmount': totalAmount.toString(),
          'rentalDays': calendarDaysBetween(pickUpDate, returnDate),
          'paymentMethod': method.label,
          'transactionId': txn,
          'cancelled': false,
          'bookingDate': Timestamp.fromDate(now),
        });
        booking.firestoreId = ref.id;
        await _saveBookings();
      } catch (e) {
        debugPrint('Error saving booking to Firestore: $e');
      }
      await _syncPurchase(purchase);
    }
    return booking;
  }

  /// Cancels (keeps it in history as "Cancelled") and refunds the payment.
  Future<void> cancelBooking(CarBooking booking) async {
    booking.cancelled = true;
    booking.cancelledAt = DateTime.now();
    PurchaseHistoryItem? purchase;
    for (final p in purchases) {
      if (p.id == 'p${booking.id}') purchase = p;
    }
    if (purchase != null) {
      purchase.status = purchase.paymentMethod == 'Cash' ? 'Cancelled' : 'Refunded';
    }
    notifyListeners();
    await _saveBookings();
    await _savePurchases();

    if (_firebase) {
      if (booking.firestoreId != null) {
        try {
          await _userDoc.collection('bookings').doc(booking.firestoreId).update({
            'cancelled': true,
            'cancelledAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Error cancelling booking in Firestore: $e');
        }
      }
      if (purchase != null) await _syncPurchase(purchase);
    }
  }

  PurchaseHistoryItem? purchaseFor(CarBooking booking) {
    for (final p in purchases) {
      if (p.id == 'p${booking.id}') return p;
    }
    return null;
  }

  List<CarBooking> get bookingsNewestFirst =>
      [...bookings]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _saveBookings() => _writeList(_k('bookings'), bookings.map((b) => b.toJson()).toList());

  Future<void> _savePurchases() => _writeList(_k('purchases'), purchases.map((p) => p.toJson()).toList());

  Future<void> _syncPurchase(PurchaseHistoryItem p) async {
    try {
      await _userDoc.collection('purchaseHistory').doc(p.id).set({
        'id': p.id,
        'paymentMethod': p.paymentMethod,
        'date': Timestamp.fromDate(p.date),
        'carName': p.carName,
        'totalAmount': p.totalAmount,
        'transactionID': p.transactionID,
        'status': p.status,
      });
    } catch (e) {
      debugPrint('Error saving purchase to Firestore: $e');
    }
  }

  // -------------------------------------------------------------- Firestore

  Future<void> _loadFromFirestore() async {
    // Favorites
    try {
      final snap = await _userDoc.collection('favorites').doc('favoritesList').get();
      final cars = snap.data()?['cars'];
      if (cars is List) {
        final loaded = <Car>[];
        for (final item in cars) {
          try {
            loaded.add(Car.fromJson(Map<String, dynamic>.from(item as Map)));
          } catch (_) {}
        }
        favorites = loaded;
        await _writeList(_k('favorites'), favorites.map((c) => c.toJson()).toList());
      }
    } catch (e) {
      debugPrint('Error loading favorites from Firestore: $e');
    }

    // Purchase history
    try {
      final snap = await _userDoc.collection('purchaseHistory').orderBy('date', descending: true).get();
      if (snap.docs.isNotEmpty) {
        final loaded = <PurchaseHistoryItem>[];
        for (final doc in snap.docs) {
          final d = doc.data();
          final ts = d['date'];
          if (ts is! Timestamp) continue;
          loaded.add(PurchaseHistoryItem(
            id: (d['id'] as String?) ?? doc.id,
            paymentMethod: (d['paymentMethod'] as String?) ?? 'Cash',
            date: ts.toDate(),
            carName: (d['carName'] as String?) ?? '',
            totalAmount: (d['totalAmount'] ?? '0').toString(),
            transactionID: (d['transactionID'] as String?) ?? '',
            status: d['status'] as String?,
          ));
        }
        purchases = loaded;
        await _savePurchases();
      }
    } catch (e) {
      debugPrint('Error loading purchase history from Firestore: $e');
    }

    // Bookings
    try {
      final snap = await _userDoc.collection('bookings').orderBy('bookingDate', descending: true).get();
      if (snap.docs.isNotEmpty) {
        final loaded = <CarBooking>[];
        for (final doc in snap.docs) {
          final d = doc.data();
          final pick = d['pickUpDate'];
          final ret = d['returnDate'];
          final created = d['bookingDate'];
          final cancelledAt = d['cancelledAt'];
          if (pick is! Timestamp || ret is! Timestamp) continue;
          final carName = (d['carName'] as String?) ?? '';
          final catalogCar = CarCatalog.byName(carName);
          loaded.add(CarBooking(
            id: (d['bookingId'] as String?) ?? doc.id,
            carName: carName,
            imageName: (d['imageName'] as String?) ?? catalogCar?.imageName ?? '',
            pricePerDay: (d['carPricePerDay'] as String?) ?? catalogCar?.pricePerDay ?? '₱0',
            pickUpDate: pick.toDate(),
            returnDate: ret.toDate(),
            location: (d['location'] as String?) ?? '',
            createdAt: created is Timestamp ? created.toDate() : pick.toDate(),
            paymentMethod: (d['paymentMethod'] as String?) ?? 'Cash',
            transactionId: d['transactionId'] as String?,
            cancelled: (d['cancelled'] as bool?) ?? false,
            cancelledAt: cancelledAt is Timestamp ? cancelledAt.toDate() : null,
            firestoreId: doc.id,
          ));
        }
        bookings = loaded;
        await _saveBookings();
      }
    } catch (e) {
      debugPrint('Error loading bookings from Firestore: $e');
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------- helpers

  Map<String, dynamic> _readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) => _prefs.setString(key, jsonEncode(list));
}
