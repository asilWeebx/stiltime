class SalonModel {
  final int id;
  final String name;
  final String type;
  final String? logo;
  final String? coverImage;
  final String address;
  final String regionName;
  final String districtName;
  final double rating;
  final int totalReviews;
  final int totalBookings;
  final List<String> categoryNames;
  final bool isVerified;
  final bool isFeatured;
  final bool acceptsOnlineBooking;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;
  final String? categoryName;
  final String? phone;
  final int? reviewCount;
  final List<String>? images;
  final bool isOpen;

  const SalonModel({
    required this.id,
    required this.name,
    required this.type,
    this.logo,
    this.coverImage,
    required this.address,
    required this.regionName,
    required this.districtName,
    required this.rating,
    required this.totalReviews,
    required this.totalBookings,
    required this.categoryNames,
    required this.isVerified,
    required this.isFeatured,
    required this.acceptsOnlineBooking,
    required this.isFavorite,
    this.latitude,
    this.longitude,
    this.categoryName,
    this.phone,
    this.reviewCount,
    this.images,
    this.isOpen = true,
  });

  factory SalonModel.fromJson(Map<String, dynamic> json) => SalonModel(
    id: json['id'],
    name: json['name'] ?? '',
    type: json['type'] ?? '',
    logo: json['logo'],
    coverImage: json['cover_image'],
    address: json['address'] ?? '',
    regionName: json['region_name'] ?? '',
    districtName: json['district_name'] ?? '',
    rating: (json['rating'] ?? 0).toDouble(),
    totalReviews: json['total_reviews'] ?? 0,
    totalBookings: json['total_bookings'] ?? 0,
    categoryNames: List<String>.from(json['category_names'] ?? []),
    isVerified: json['is_verified'] ?? false,
    isFeatured: json['is_featured'] ?? false,
    acceptsOnlineBooking: json['accepts_online_booking'] ?? true,
    isFavorite: json['is_favorite'] ?? false,
    latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
    longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    categoryName: json['category_name'],
    phone: json['phone'],
    reviewCount: json['review_count'] ?? json['total_reviews'],
    images: json['images'] != null
        ? (json['images'] as List)
            .map((i) => i is Map ? (i['image'] as String? ?? '') : i.toString())
            .where((s) => s.isNotEmpty)
            .toList()
        : null,
    isOpen: json['is_open'] ?? true,
  );

  String get typeLabel {
    const labels = {
      'barbershop': 'Sartaroshxona',
      'beauty_salon': "Go'zallik saloni",
      'nail': 'Tirnoq saloni',
      'spa': 'Spa',
    };
    return labels[type] ?? type;
  }
}

class ServiceModel {
  final int id;
  final String name;
  final double price;
  final double? priceMax;
  final int duration;
  final String? image;
  final String? categoryName;
  bool isSelected;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    this.priceMax,
    required this.duration,
    this.image,
    this.categoryName,
    this.isSelected = false,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json['id'],
    name: json['name'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    priceMax: json['price_max'] != null ? double.tryParse(json['price_max'].toString()) : null,
    duration: json['duration'] ?? 30,
    image: json['image'],
    categoryName: json['category_name'],
  );

  String get priceText {
    if (priceMax != null) return '${price.toStringAsFixed(0)} – ${priceMax!.toStringAsFixed(0)} so\'m';
    return '${price.toStringAsFixed(0)} so\'m';
  }

  String get durationText {
    if (duration >= 60) return '${duration ~/ 60} soat ${duration % 60 > 0 ? '${duration % 60} daq' : ''}';
    return '$duration daqiqa';
  }
}
