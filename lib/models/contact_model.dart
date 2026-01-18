import 'user_model.dart';

class ContactModel {
  final String id;
  final String name;
  final String? avatar;
  final String? pushToken;
  final DateTime? lastCheckin;
  final bool isActive;

  ContactModel({
    required this.id,
    required this.name,
    this.avatar,
    this.pushToken,
    this.lastCheckin,
    this.isActive = true,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      pushToken: json['pushToken'],
      lastCheckin: json['lastCheckin'] != null
          ? DateTime.parse(json['lastCheckin'])
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  factory ContactModel.fromUserModel(UserModel user) {
    return ContactModel(
      id: user.id,
      name: user.name,
      pushToken: user.pushToken,
      isActive: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      if (pushToken != null) 'pushToken': pushToken,
      if (lastCheckin != null) 'lastCheckin': lastCheckin!.toIso8601String(),
      'isActive': isActive,
    };
  }

  ContactModel copyWith({
    String? name,
    String? avatar,
    String? pushToken,
    DateTime? lastCheckin,
    bool? isActive,
  }) {
    return ContactModel(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      pushToken: pushToken ?? this.pushToken,
      lastCheckin: lastCheckin ?? this.lastCheckin,
      isActive: isActive ?? this.isActive,
    );
  }
}
