import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityLogService {
  ActivityLogService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> logEvent({
    required String type,
    required String title,
    String? message,
    Map<String, dynamic>? metadata,
    String? actorUid,
    String? actorName,
    String? actorEmail,
    String? subjectUid,
    String? subjectName,
    String? subjectEmail,
  }) async {
    final user = _auth.currentUser;
    final resolvedActorUid = (actorUid ?? user?.uid ?? '').trim();
    final resolvedActorName = (actorName ??
            user?.displayName ??
            user?.email ??
            'Unknown')
        .trim();
    final resolvedActorEmail = (actorEmail ?? user?.email ?? '').trim();

    await _firestore.collection('activity_logs').add({
      'type': type,
      'title': title,
      'message': message ?? '',
      'actorUid': resolvedActorUid,
      'actorName': resolvedActorName.isEmpty ? 'Unknown' : resolvedActorName,
      'actorEmail': resolvedActorEmail,
      'subjectUid': (subjectUid ?? '').trim(),
      'subjectName': (subjectName ?? '').trim(),
      'subjectEmail': (subjectEmail ?? '').trim(),
      'metadata': metadata ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'clientCreatedAt': DateTime.now().toIso8601String(),
    });
  }
}
