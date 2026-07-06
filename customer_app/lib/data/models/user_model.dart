class UserModel {
  final int id;
  final String phone;
  final String fullName;
  final String email;
  final String? avatar;
  final String gender;
  final String? dateOfBirth;
  final String role;
  final String language;
  final bool isVerified;
  final int reminderMinutes;
  final bool notificationBooking;
  final bool notificationPromotions;
  final bool notificationReminders;
  final int loyaltyPoints;
  final String? referralCode;
  final bool isVip;

  const UserModel({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.email,
    this.avatar,
    required this.gender,
    this.dateOfBirth,
    required this.role,
    required this.language,
    required this.isVerified,
    required this.reminderMinutes,
    required this.notificationBooking,
    required this.notificationPromotions,
    required this.notificationReminders,
    this.loyaltyPoints = 0,
    this.referralCode,
    this.isVip = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
    phone: json['phone']?.toString() ?? '',
    fullName: json['full_name'] ?? '',
    email: json['email'] ?? '',
    avatar: json['avatar'],
    gender: json['gender'] ?? '',
    dateOfBirth: json['date_of_birth'],
    role: json['role'] ?? 'customer',
    language: json['language'] ?? 'uz',
    isVerified: json['is_verified'] ?? false,
    reminderMinutes: json['reminder_minutes'] ?? 30,
    notificationBooking: json['notification_booking'] ?? true,
    notificationPromotions: json['notification_promotions'] ?? true,
    notificationReminders: json['notification_reminders'] ?? true,
    loyaltyPoints: json['loyalty_points'] ?? 0,
    referralCode: json['referral_code'],
    isVip: json['is_vip'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'phone': phone, 'full_name': fullName, 'email': email,
    'avatar': avatar, 'gender': gender, 'date_of_birth': dateOfBirth,
    'role': role, 'language': language, 'is_verified': isVerified,
    'reminder_minutes': reminderMinutes,
    'notification_booking': notificationBooking,
    'notification_promotions': notificationPromotions,
    'notification_reminders': notificationReminders,
    'loyalty_points': loyaltyPoints,
    'referral_code': referralCode,
    'is_vip': isVip,
  };

  UserModel copyWith({
    String? fullName, String? email, String? avatar,
    String? gender, String? dateOfBirth, String? language,
    int? reminderMinutes, bool? notificationBooking,
    bool? notificationPromotions, bool? notificationReminders,
  }) => UserModel(
    id: id, phone: phone,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    avatar: avatar ?? this.avatar,
    gender: gender ?? this.gender,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    role: role, language: language ?? this.language,
    isVerified: isVerified,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    notificationBooking: notificationBooking ?? this.notificationBooking,
    notificationPromotions: notificationPromotions ?? this.notificationPromotions,
    notificationReminders: notificationReminders ?? this.notificationReminders,
  );
}
