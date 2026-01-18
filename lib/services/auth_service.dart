import 'dart:async';
import '../models/user_model.dart';
import 'local_storage_service.dart';

/// Локальна модель користувача (без Firebase)
class LocalUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime createdAt;

  LocalUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LocalUser.fromJson(Map<String, dynamic> json) {
    return LocalUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  UserModel toUserModel() {
    return UserModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      createdAt: createdAt,
      contactIds: [],
    );
  }
}

/// Локальна система аутентифікації (без Firebase)
class AuthService {
  static const String _userKey = 'current_user';
  
  LocalUser? _currentUser;
  final StreamController<LocalUser?> _authStateController = StreamController<LocalUser?>.broadcast();
  LocalStorageService? _localStorage;

  // Ініціалізація (потрібно викликати після ініціалізації LocalStorageService)
  void initialize(LocalStorageService localStorage) {
    _localStorage = localStorage;
    _loadUser();
  }

  // Поточний користувач
  LocalUser? get currentUser => _currentUser;
  
  // Stream змін стану аутентифікації
  Stream<LocalUser?> get authStateChanges => _authStateController.stream;

  // Завантажити користувача з локального сховища
  Future<void> _loadUser() async {
    if (_localStorage == null) return;
    
    try {
      final userData = _localStorage!.getSetting(_userKey);
      if (userData != null && userData is Map) {
        _currentUser = LocalUser.fromJson(Map<String, dynamic>.from(userData));
        _authStateController.add(_currentUser);
      } else {
        _authStateController.add(null);
      }
    } catch (e) {
      print('⚠️ Load user error: $e');
      _authStateController.add(null);
    }
  }

  // Зберегти користувача локально
  Future<void> _saveUser(LocalUser user) async {
    if (_localStorage == null) return;
    
    try {
      await _localStorage!.saveSetting(_userKey, user.toJson());
      _currentUser = user;
      _authStateController.add(user);
    } catch (e) {
      print('⚠️ Save user error: $e');
    }
  }

  // Симуляція входу через Дія ID
  Future<bool> signInWithDiaID(String email, String name) async {
    try {
      // Генеруємо унікальний ID на основі email
      final userId = _generateUserId(email);
      
      final user = LocalUser(
        id: userId,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );
      
      await _saveUser(user);
      print('✅ User signed in: $name ($email)');
      return true;
    } catch (e) {
      print('❌ Sign in error: $e');
      return false;
    }
  }

  // Симуляція входу через BankID
  Future<bool> signInWithBankID(String phone, String name) async {
    try {
      // Генеруємо унікальний ID на основі телефону
      final userId = _generateUserId(phone);
      final email = '$phone@bankid.local';
      
      final user = LocalUser(
        id: userId,
        name: name,
        email: email,
        phone: phone,
        createdAt: DateTime.now(),
      );
      
      await _saveUser(user);
      print('✅ User signed in via BankID: $name ($phone)');
      return true;
    } catch (e) {
      print('❌ BankID sign in error: $e');
      return false;
    }
  }

  // Генерувати унікальний ID користувача
  String _generateUserId(String identifier) {
    // Простий хеш на основі ідентифікатора
    return identifier.hashCode.abs().toString();
  }

  // Вихід
  Future<void> signOut() async {
    if (_localStorage == null) return;
    
    try {
      await _localStorage!.removeSetting(_userKey);
      _currentUser = null;
      _authStateController.add(null);
      print('✅ User signed out');
    } catch (e) {
      print('⚠️ Sign out error: $e');
    }
  }

  // Видалення акаунту
  Future<void> deleteAccount() async {
    if (_localStorage == null) return;
    
    try {
      await _localStorage!.removeSetting(_userKey);
      // Тут можна також видалити всі чекіни та контакти користувача
      _currentUser = null;
      _authStateController.add(null);
      print('✅ Account deleted');
    } catch (e) {
      print('⚠️ Delete account error: $e');
      rethrow;
    }
  }

  // Отримати профіль користувача
  Future<UserModel?> getUserProfile() async {
    if (_currentUser == null) return null;
    return _currentUser!.toUserModel();
  }

  // Отримати ID поточного користувача
  String? get userId => _currentUser?.id;

  // Звільнити ресурси
  void dispose() {
    _authStateController.close();
  }
}
