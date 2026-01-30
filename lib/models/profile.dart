class Profile {
  final String userId;
  final String email;
  final String? fullName;
  final String? phone;
  final String? address;
  final String? city;
  final String? pincode;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.userId,
    required this.email,
    this.fullName,
    this.phone,
    this.address,
    this.city,
    this.pincode,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert Profile to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'city': city,
      'pincode': pincode,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create Profile from JSON (Supabase response)
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Create a copy with modified fields
  Profile copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? phone,
    String? address,
    String? city,
    String? pincode,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
