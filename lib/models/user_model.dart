class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime createdAt;
  final List<String> contactIds;
  final String? pushToken;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.createdAt,
    this.contactIds = const [],
    this.pushToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      contactIds: List<String>.from(json['contactIds'] ?? []),
      pushToken: json['pushToken'],
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      contactIds: List<String>.from(data['contactIds'] ?? []),
      pushToken: data['pushToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'contactIds': contactIds,
      if (pushToken != null) 'pushToken': pushToken,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'createdAt': createdAt,
      'contactIds': contactIds,
      if (pushToken != null) 'pushToken': pushToken,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    List<String>? contactIds,
    String? pushToken,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt,
      contactIds: contactIds ?? this.contactIds,
      pushToken: pushToken ?? this.pushToken,
    );
  }
}
