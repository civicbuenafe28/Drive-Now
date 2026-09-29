/// Car model — port of Car.swift + CarSpecification.swift.
class Car {
  final String name;
  final String pricePerDay; // e.g. "₱2,500"
  final String imageName; // file name in assets/images without extension
  final int rating;
  final String category;

  const Car({
    required this.name,
    required this.pricePerDay,
    required this.imageName,
    required this.rating,
    required this.category,
  });

  /// Stable id (the Swift version used a random UUID per launch).
  String get id => name;

  String get imagePath => 'assets/images/$imageName.png';

  double get priceAsDouble =>
      double.tryParse(pricePerDay.replaceAll('₱', '').replaceAll(',', '')) ?? 0;

  double get clampedRating => rating > 5 ? 5 : rating.toDouble();

  bool belongsToCategory(String c) => category.toLowerCase() == c.toLowerCase();

  bool get isPremium => clampedRating >= 4.0;

  String get priceTier {
    final p = priceAsDouble;
    if (p < 3000) return 'Budget';
    if (p < 6000) return 'Standard';
    if (p < 10000) return 'Premium';
    return 'Luxury';
  }

  CarSpecification get specifications => CarSpecification(this);

  String get brand => name.split(' ').first;

  String get description {
    final spec = specifications;
    switch (category) {
      case 'SUV':
        return 'The $name is a roomy ${spec.seats}-seater SUV built for family trips, '
            'long drives and weekend getaways — comfortable on the highway and confident on rough roads.';
      case 'Sedan':
        return 'The $name is a fuel-efficient, easy-to-drive sedan — ideal for city errands, '
            'business meetings and smooth daily commutes.';
      case 'Pickup':
        return 'The $name is a tough, dependable pickup with plenty of cargo space — perfect for moving, '
            'provincial trips and heavy-duty work.';
      case 'Luxury':
        return 'Arrive in style with the $name — premium leather interior, a whisper-quiet cabin and '
            'first-class comfort for weddings, VIP transport and special occasions.';
      case 'Sports':
        return 'Feel the thrill with the $name — sharp handling, powerful acceleration and head-turning '
            'looks for an unforgettable drive.';
      case 'Van':
        return 'The $name seats up to ${spec.seats} passengers — the go-to choice for group '
            'tours, airport transfers, outings and big family events.';
      default:
        return 'A reliable ride for every trip.';
    }
  }

  List<String> get features {
    const base = ['Air conditioning', 'Bluetooth audio', 'Comprehensive insurance'];
    switch (category) {
      case 'SUV':
        return [...base, 'Roof rails', 'Rear camera', '3-row seating'];
      case 'Sedan':
        return [...base, 'Fuel efficient', 'Apple CarPlay / Android Auto', 'Keyless entry'];
      case 'Pickup':
        return [...base, '4x4 capable', 'Cargo bed', 'Tow hitch'];
      case 'Luxury':
        return [...base, 'Leather seats', 'Premium sound', 'Climate control'];
      case 'Sports':
        return [...base, 'Sport mode', 'Performance tires', 'Launch control'];
      case 'Van':
        return [...base, 'Rear A/C', 'Sliding doors', 'Large luggage space'];
      default:
        return base;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pricePerDay': pricePerDay,
        'imageName': imageName,
        'rating': rating,
        'category': category,
      };

  factory Car.fromJson(Map<String, dynamic> j) => Car(
        name: j['name'] as String,
        pricePerDay: j['pricePerDay'] as String,
        imageName: j['imageName'] as String,
        rating: (j['rating'] as num).toInt(),
        category: j['category'] as String,
      );

  @override
  bool operator ==(Object other) => other is Car && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class CarSpecification {
  final Car car;
  CarSpecification(this.car);

  static const availableModels = ['2024', '2023', '2022', '2021'];
  static const transmissionTypes = ['Manual', 'Automatic'];

  // Deterministic hash so the same car always shows the same specs.
  int get _stableHash {
    var h = 0;
    for (final unit in car.name.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h;
  }

  List<String> get fuelTypes {
    if (car.belongsToCategory('Sports')) return ['Gasoline'];
    if (car.belongsToCategory('Pickup')) return ['Petrol', 'Diesel'];
    if (car.belongsToCategory('SUV') && car.name == 'Toyota Hycross') {
      return ['Hybrid'];
    }
    return ['Petrol', 'Diesel', 'Hybrid'];
  }

  String get seatCapacity {
    switch (car.category) {
      case 'SUV':
        return car.name == 'Hyundai Creta' ? '5 Seats' : '7 Seats';
      case 'Sedan':
        return '4 Seats';
      case 'Pickup':
        return car.name == 'Ford F-150' ? '2 Seats' : '5 Seats';
      case 'Luxury':
        return '4 Seats';
      case 'Sports':
        return '2 Seats';
      case 'Van':
        return '12 Seats';
      default:
        return 'Unknown';
    }
  }

  int get seats => int.tryParse(seatCapacity.split(' ').first) ?? 4;

  String get modelYear => availableModels[_stableHash % availableModels.length];
  String get fuelType => fuelTypes.isNotEmpty ? fuelTypes.first : 'Petrol';
  String get transmission =>
      transmissionTypes[_stableHash % transmissionTypes.length];

  Map<String, String> getSpecifications() => {
        'Model': modelYear,
        'Seat Capacity': seatCapacity,
        'Fuel': fuelType,
        'Transmission': transmission,
      };
}

class CarCatalog {
  static const categories = ['SUV', 'Sedan', 'Pickup', 'Luxury', 'Sports', 'Van'];

  /// Categories shown on the home screen (with "All" first).
  static const homeCategories = ['All', ...categories];

  static const cars = <Car>[
    Car(name: 'Toyota Innova HyCross', pricePerDay: '₱2,500', imageName: 'toyota-innova', rating: 4, category: 'SUV'),
    Car(name: 'Toyota Fortuner', pricePerDay: '₱3,000', imageName: 'toyota-fortuner', rating: 4, category: 'SUV'),
    Car(name: 'Hyundai Creta', pricePerDay: '₱2,800', imageName: 'hyundai-creta', rating: 4, category: 'SUV'),
    Car(name: 'Ford Everest', pricePerDay: '₱3,500', imageName: 'ford-everest', rating: 5, category: 'SUV'),
    Car(name: 'Mitsubishi Montero', pricePerDay: '₱3,200', imageName: 'mitsubishi-montero', rating: 4, category: 'SUV'),

    Car(name: 'Honda Civic', pricePerDay: '₱2,000', imageName: 'honda-civic', rating: 5, category: 'Sedan'),
    Car(name: 'Toyota Camry', pricePerDay: '₱2,400', imageName: 'toyota-camry', rating: 4, category: 'Sedan'),
    Car(name: 'Nissan Sentra', pricePerDay: '₱1,900', imageName: 'nissan-sentra', rating: 3, category: 'Sedan'),
    Car(name: 'Mazda 3', pricePerDay: '₱2,100', imageName: 'mazda-3', rating: 4, category: 'Sedan'),
    Car(name: 'Subaru Impreza', pricePerDay: '₱2,300', imageName: 'subaru-impreza', rating: 5, category: 'Sedan'),

    Car(name: 'Ford F-150', pricePerDay: '₱4,000', imageName: 'ford-f150', rating: 3, category: 'Pickup'),
    Car(name: 'Toyota Hilux', pricePerDay: '₱3,800', imageName: 'toyota-hilux', rating: 4, category: 'Pickup'),
    Car(name: 'Nissan Navara', pricePerDay: '₱3,700', imageName: 'nissan-navara', rating: 4, category: 'Pickup'),
    Car(name: 'Isuzu D-Max', pricePerDay: '₱3,600', imageName: 'isuzu-dmax', rating: 5, category: 'Pickup'),
    Car(name: 'Mitsubishi Strada', pricePerDay: '₱3,500', imageName: 'mitsubishi-strada', rating: 4, category: 'Pickup'),

    Car(name: 'Mercedes-Benz S-Class', pricePerDay: '₱10,000', imageName: 'mercedes-s-class', rating: 5, category: 'Luxury'),
    Car(name: 'BMW 7 Series', pricePerDay: '₱9,500', imageName: 'bmw-7-series', rating: 5, category: 'Luxury'),
    Car(name: 'Audi A8', pricePerDay: '₱9,000', imageName: 'audi-a8', rating: 4, category: 'Luxury'),
    Car(name: 'Lexus LS', pricePerDay: '₱8,800', imageName: 'lexus-ls', rating: 5, category: 'Luxury'),
    Car(name: 'Jaguar XJ', pricePerDay: '₱8,500', imageName: 'jaguar-xj', rating: 4, category: 'Luxury'),

    Car(name: 'Ford Mustang GT', pricePerDay: '₱7,000', imageName: 'ford-mustang', rating: 5, category: 'Sports'),
    Car(name: 'Chevrolet Camaro', pricePerDay: '₱6,800', imageName: 'chevrolet-camaro', rating: 4, category: 'Sports'),
    Car(name: 'Nissan GT-R', pricePerDay: '₱12,000', imageName: 'nissan-gtr', rating: 5, category: 'Sports'),
    Car(name: 'Porsche 911', pricePerDay: '₱15,000', imageName: 'porsche-911', rating: 5, category: 'Sports'),
    Car(name: 'Toyota Supra', pricePerDay: '₱7,500', imageName: 'toyota-supra', rating: 4, category: 'Sports'),

    Car(name: 'Toyota Hiace', pricePerDay: '₱3,500', imageName: 'toyota-hiace', rating: 4, category: 'Van'),
    Car(name: 'Ford Transit', pricePerDay: '₱3,200', imageName: 'ford-transit', rating: 3, category: 'Van'),
    Car(name: 'Nissan Urvan', pricePerDay: '₱3,000', imageName: 'nissan-urvan', rating: 4, category: 'Van'),
    Car(name: 'Hyundai Starex', pricePerDay: '₱2,900', imageName: 'hyundai-starex', rating: 3, category: 'Van'),
    Car(name: 'Foton Traveller XL', pricePerDay: '₱3,300', imageName: 'foton-xl', rating: 5, category: 'Van'),
  ];

  static Car? byName(String name) {
    for (final c in cars) {
      if (c.name == name) return c;
    }
    return null;
  }
}
