import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/checkin_model.dart';
import '../models/user_model.dart';
import '../models/contact_model.dart';

class FirestoreService {
  FirebaseFirestore? _firestore;
  
  FirestoreService() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      print('⚠️ Firestore не доступний: $e');
      _firestore = null;
    }
  }
  
  bool get isAvailable => _firestore != null;

  // Зберегти чекін
  Future<void> saveCheckin(CheckinModel checkin) async {
    if (_firestore == null) {
      print('⚠️ Firestore не доступний - чекін збережено тільки локально');
      return;
    }
    
    try {
      await _firestore!.collection('checkins').doc(checkin.id).set(
        checkin.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Save checkin error: $e');
      rethrow;
    }
  }

  // Отримати останній чекін користувача
  Future<CheckinModel?> getLastCheckin(String userId) async {
    if (_firestore == null) return null;
    
    try {
      final snapshot = await _firestore!
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return CheckinModel.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      print('Get last checkin error: $e');
      return null;
    }
  }

  // Отримати чекіни для користувача (які він отримує від інших)
  Stream<List<CheckinModel>> getCheckinsForUser(String userId) {
    if (_firestore == null) {
      return Stream.value([]);
    }
    
    return _firestore!
        .collection('checkins')
        .where('recipientIds', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CheckinModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Позначити чекін як прочитаний
  Future<void> markCheckinAsRead(String checkinId, String userId) async {
    if (_firestore == null) return;
    
    try {
      await _firestore!.collection('checkins').doc(checkinId).update({
        'readBy.$userId': true,
      });
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  // Додати контакт
  Future<void> addContact(String userId, String contactId) async {
    if (_firestore == null) {
      print('⚠️ Firestore не доступний');
      return;
    }
    
    try {
      await _firestore!.collection('users').doc(userId).update({
        'contactIds': FieldValue.arrayUnion([contactId]),
      });
    } catch (e) {
      print('Add contact error: $e');
      rethrow;
    }
  }

  // Видалити контакт
  Future<void> removeContact(String userId, String contactId) async {
    if (_firestore == null) return;
    
    try {
      await _firestore!.collection('users').doc(userId).update({
        'contactIds': FieldValue.arrayRemove([contactId]),
      });
    } catch (e) {
      print('Remove contact error: $e');
    }
  }

  // Отримати інформацію про користувача
  Future<UserModel?> getUser(String userId) async {
    if (_firestore == null) return null;
    
    try {
      final doc = await _firestore!.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  // Отримати список контактів
  Future<List<ContactModel>> getContacts(String userId) async {
    if (_firestore == null) return [];
    
    try {
      final userDoc = await _firestore!.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final user = UserModel.fromFirestore(userDoc.data()!, userDoc.id);
      final contactIds = user.contactIds;

      if (contactIds.isEmpty) return [];

      final contacts = <ContactModel>[];
      for (final contactId in contactIds) {
        final contactDoc = await _firestore!.collection('users').doc(contactId).get();
        if (contactDoc.exists) {
          final contactUser = UserModel.fromFirestore(contactDoc.data()!, contactDoc.id);
          contacts.add(ContactModel.fromUserModel(contactUser));
        }
      }

      return contacts;
    } catch (e) {
      print('Get contacts error: $e');
      return [];
    }
  }

  // Оновити push-токен
  Future<void> updatePushToken(String userId, String token) async {
    if (_firestore == null) return;
    
    try {
      await _firestore!.collection('users').doc(userId).update({
        'pushToken': token,
      });
    } catch (e) {
      print('Update push token error: $e');
    }
  }

  // Оновити профіль користувача
  Future<void> updateUserProfile(UserModel user) async {
    if (_firestore == null) {
      print('⚠️ Firestore не доступний');
      return;
    }
    
    try {
      await _firestore!.collection('users').doc(user.id).update(
        user.toFirestore(),
      );
    } catch (e) {
      print('Update user profile error: $e');
      rethrow;
    }
  }
}
