import 'package:flutter_test/flutter_test.dart';
import 'package:drivenow/models/booking.dart';
import 'package:drivenow/models/car.dart';
import 'package:drivenow/screens/credit_card_payment_screen.dart';
import 'package:drivenow/screens/edit_profile_screen.dart';
import 'package:drivenow/screens/signup_screen.dart';
import 'package:drivenow/utils/format.dart';
import 'package:drivenow/widgets/ui.dart';

void main() {
  test('car price parsing, tiers and All category', () {
    final car = CarCatalog.cars.firstWhere((c) => c.name == 'Porsche 911');
    expect(car.priceAsDouble, 15000);
    expect(car.priceTier, 'Luxury');
    expect(car.isPremium, isTrue);
    expect(CarCatalog.homeCategories.first, 'All');
    expect(CarCatalog.cars.length, 30);
  });

  test('booking counts calendar days, reference and cancellation', () {
    final b = CarBooking(
      id: '1727000000123456',
      carName: 'Honda Civic',
      imageName: 'honda-civic',
      pricePerDay: '₱2,000',
      pickUpDate: DateTime.now().add(const Duration(days: 2)),
      returnDate: DateTime.now().add(const Duration(days: 5)),
      location: 'Lucena City',
      createdAt: DateTime.now(),
    );
    expect(b.rentalDays, 3);
    expect(b.totalCost, 6000);
    expect(b.status, 'Upcoming');
    expect(b.canBeCancelled, isTrue);
    expect(b.reference, 'DN-123456');
    b.cancelled = true;
    expect(b.status, 'Cancelled');
    expect(b.canBeCancelled, isFalse);
  });

  test('peso formatting', () {
    expect(peso(7500), '₱7,500');
    expect(peso(15000), '₱15,000');
    expect(peso(1234567), '₱1,234,567');
  });

  test('password rules', () {
    expect(PasswordRules.allMet('abc'), isFalse);
    expect(PasswordRules.allMet('Password1'), isTrue);
  });

  test('form validators', () {
    expect(validatePhMobile('9171234567'), isNull);
    expect(validatePhMobile('8171234567'), isNotNull);
    expect(validatePhMobile('', required: false), isNull);
    expect(validateFullName('Juan Dela Cruz'), isNull);
    expect(validateFullName('Juan'), isNotNull);
    expect(validateLicense('N01-23-456789'), isNull);
    expect(validateLicense('12345'), isNotNull);
  });

  test('card checks', () {
    expect(luhnValid('4242424242424242'), isTrue);
    expect(luhnValid('4242424242424241'), isFalse);
    expect(cardBrand('4242'), 'VISA');
    expect(cardBrand('5555'), 'Mastercard');
  });
}
