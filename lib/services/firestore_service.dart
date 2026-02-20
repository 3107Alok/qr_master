
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/history_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save or Update User Profile (Mobile, DOB)
  Future<void> saveUserProfile({String? mobile, String? dob}) async {
    final user = _auth.currentUser;
    if (user != null) {
      final docRef = _db.collection('users').doc(user.uid);
      
      final Map<String, dynamic> data = {
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastSeen': FieldValue.serverTimestamp(),
      };

      if (mobile != null) data['mobile'] = mobile;
      if (dob != null) data['dob'] = dob;

      await docRef.set(data, SetOptions(merge: true));
    }
  }

  // Get User Profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }

  // Sync Local History to Cloud
  Future<void> syncHistory(List<HistoryItem> localItems) async {
    final user = _auth.currentUser;
    if (user != null) {
      final batch = _db.batch();
      final collection = _db.collection('users').doc(user.uid).collection('history');

      // We only upload, assuming local is source of truth for new items
      // In a real app, you'd implement 2-way sync with IDs.
      for (final item in localItems) {
        // Use data+timestamp as a crude ID to avoid duplicates if possible, 
        // or just let Firestore generate IDs and potential dupes for now.
        // Better: Check if exists. For now, we'll add.
        final docRef = collection.doc('${item.timestamp.millisecondsSinceEpoch}');
        batch.set(docRef, item.toJson());
      }
      
      await batch.commit();
    }
  }

  // Add Single History Item
  Future<void> addHistoryItem(HistoryItem item) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .doc('${item.timestamp.millisecondsSinceEpoch}')
          .set(item.toJson());
    }
  }

  // Stream History from Cloud
  Stream<List<HistoryItem>> getHistoryStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _db
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
           // Firestore stores Timestamp, we need to convert back to string/int if needed
           // OR standard implementation handles standard JSON.
           // HistoryItem.fromJson expects 'timestamp' string in ISO8601 usually if from SharedPrefs
           // Let's ensure compatibility.
           final data = doc.data();
           return HistoryItem.fromJson(data);
        }).toList();
      });
    }
    return Stream.value([]);
  }
}
