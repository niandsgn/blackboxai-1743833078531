import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location_sharing_app/models/contact.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update current user's location in Firestore
  Future<void> updateUserLocation(double lat, double lng) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'location': GeoPoint(lat, lng),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update location: ${e.toString()}');
    }
  }

  // Get stream of user's contacts
  Stream<QuerySnapshot> getUserContacts() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .snapshots();
  }

  // Get stream of contacts' locations
  Stream<List<Contact>> getContactsLocations(List<String> contactIds) {
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: contactIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Contact.fromMap(doc.data()!, doc.id))
            .toList());
  }

  // Add a new contact
  Future<void> addContact(String email) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Find user by email
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('User not found');
      }

      final contactId = query.docs.first.id;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .set({'email': email, 'sharingEnabled': true});
    } catch (e) {
      throw Exception('Failed to add contact: ${e.toString()}');
    }
  }

  // Update contact sharing status
  Future<void> updateContactSharing(String contactId, bool enabled) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .update({'sharingEnabled': enabled});
    } catch (e) {
      throw Exception('Failed to update sharing: ${e.toString()}');
    }
  }

  // Update contact geofence settings
  Future<void> updateContactGeofence(
    String contactId,
    double lat,
    double lng,
    double radius,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .update({
        'geofenceCenter': [lat, lng],
        'geofenceRadius': radius,
      });
    } catch (e) {
      throw Exception('Failed to update geofence: ${e.toString()}');
    }
  }
}