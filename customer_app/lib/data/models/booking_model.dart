class BookingModel {
  final int id;
  final int barber;
  final String? barberName;
  final String? barberAvatar;
  final int salon;
  final String salonName;
  final String? salonImage;
  final String? serviceName;
  final List<BookingService> services;
  final String date;
  final String startTime;
  final String? endTime;
  final int totalDuration;
  final double totalPrice;
  final double discountAmount;
  final double finalPrice;
  final String status;
  final String source;
  final String? notes;
  final String createdAt;
  final bool hasReview;
  final String? barberCover;
  final String? barberSpecialization;
  final double barberRating;
  final String? salonCover;
  final String? salonAddress;
  final double? salonLatitude;
  final double? salonLongitude;

  const BookingModel({
    required this.id,
    required this.barber,
    this.barberName,
    this.barberAvatar,
    required this.salon,
    required this.salonName,
    this.salonImage,
    this.serviceName,
    required this.services,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.totalDuration,
    required this.totalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.status,
    required this.source,
    this.notes,
    required this.createdAt,
    this.hasReview = false,
    this.barberCover,
    this.barberSpecialization,
    this.barberRating = 0.0,
    this.salonCover,
    this.salonAddress,
    this.salonLatitude,
    this.salonLongitude,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final services = (json['services'] as List? ?? []).map((s) => BookingService.fromJson(s)).toList();
    return BookingModel(
      id: json['id'],
      barber: json['barber'] ?? 0,
      barberName: json['barber_name'],
      barberAvatar: json['barber_avatar'],
      salon: json['salon'] ?? 0,
      salonName: json['salon_name'] ?? '',
      salonImage: json['salon_cover'],
      serviceName: services.isNotEmpty ? services.first.name : json['service_name'],
      services: services,
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      totalDuration: json['total_duration'] ?? 0,
      totalPrice: (json['total_price'] ?? json['final_price'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      finalPrice: (json['final_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      source: json['source'] ?? 'app',
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      hasReview: json['has_review'] as bool? ?? false,
      barberCover: json['barber_cover'],
      barberSpecialization: json['barber_specialization'],
      barberRating: (json['barber_rating'] as num?)?.toDouble() ?? 0.0,
      salonCover: json['salon_cover'],
      salonAddress: json['salon_address'],
      salonLatitude: (json['salon_latitude'] as num?)?.toDouble(),
      salonLongitude: (json['salon_longitude'] as num?)?.toDouble(),
    );
  }

  String get statusLabel {
    const labels = {
      'pending': 'Kutilmoqda',
      'confirmed': 'Tasdiqlangan',
      'in_progress': 'Davom etmoqda',
      'completed': 'Bajarildi',
      'cancelled': 'Bekor qilindi',
      'no_show': 'Kelmadi',
    };
    return labels[status] ?? status;
  }

  int get salonId => salon;

  bool get isUpcoming => status == 'pending' || status == 'confirmed';
  bool get isActive => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canCancel => isUpcoming;
}

class BookingService {
  final int id;
  final String name;
  final double price;
  final int duration;

  const BookingService({required this.id, required this.name, required this.price, required this.duration});

  factory BookingService.fromJson(Map<String, dynamic> json) => BookingService(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    duration: json['duration_minutes'] ?? json['duration'] ?? 0,
  );
}

class TimeSlotModel {
  final String startTime;
  final String endTime;
  final bool isAvailable;

  const TimeSlotModel({required this.startTime, required this.endTime, required this.isAvailable});

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) => TimeSlotModel(
    startTime: json['start_time'] ?? '',
    endTime: json['end_time'] ?? '',
    isAvailable: json['is_available'] ?? true,
  );
}
