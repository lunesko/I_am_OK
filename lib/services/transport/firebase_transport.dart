import '../../models/checkin_model.dart';
import '../firestore_service.dart';

/// Транспорт через Firebase (Firestore + FCM). Обгортка над FirestoreService.
class FirebaseTransport {
  final FirestoreService _firestore;

  FirebaseTransport(this._firestore);

  /// Відправити чек-ін через Firestore. FCM відправляється Cloud Function.
  Future<void> sendCheckin(CheckinModel checkin) async {
    await _firestore.saveCheckin(checkin);
  }
}
