import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Поточний користувач
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Симуляція входу через Дія ID (в реальності - OAuth 2.0)
  Future<UserCredential?> signInWithDiaID(String email, String name) async {
    try {
      // В production тут буде OAuth flow з Дія ID
      // Зараз використовуємо email/password для тестування
      
      UserCredential credential;
      
      try {
        // Спробувати увійти
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: 'diaid_temp_password', // Тимчасовий пароль
        );
      } catch (e) {
        // Якщо користувача немає - створити
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: 'diaid_temp_password',
        );
        
        // Створити профіль у Firestore
        final userModel = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(credential.user!.uid).set(
          userModel.toFirestore(),
        );
      }
      
      return credential;
    } catch (e) {
      print('Auth error: $e');
      return null;
    }
  }

  // Симуляція входу через BankID
  Future<UserCredential?> signInWithBankID(String phone, String name) async {
    try {
      // В production - інтеграція з BankID API
      final email = '$phone@bankid.temp'; // Тимчасово
      return await signInWithDiaID(email, name);
    } catch (e) {
      print('BankID auth error: $e');
      return null;
    }
  }

  // Вихід
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Видалення акаунту
  Future<void> deleteAccount() async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    try {
      // Видалити дані з Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Видалити всі чекіни
      final checkins = await _firestore
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in checkins.docs) {
        await doc.reference.delete();
      }
      
      // Видалити акаунт Firebase Auth
      await currentUser?.delete();
    } catch (e) {
      print('Delete account error: $e');
      rethrow;
    }
  }

  // Отримати профіль користувача
  Future<UserModel?> getUserProfile() async {
    final userId = currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Get user profile error: $e');
      return null;
    }
  }
}
