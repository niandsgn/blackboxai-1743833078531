import 'package:flutter/material.dart';
import 'package:location_sharing_app/models/contact.dart';
import 'package:location_sharing_app/services/firestore_service.dart';
import 'package:provider/provider.dart';

class ContactService {
  final BuildContext context;

  ContactService(this.context);
  Future<List<Contact>> getContacts() async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final snapshot = await firestore.getUserContacts().first;
    return snapshot.docs
        .map((doc) => Contact.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> addContact(String email) async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    await firestore.addContact(email);
  }

  Future<void> updateContactSharing(String contactId, bool enabled) async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    await firestore.updateContactSharing(contactId, enabled);
  }

  Future<void> updateGeofence(
    String contactId,
    double lat,
    double lng,
    double radius,
  ) async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    await firestore.updateContactGeofence(contactId, lat, lng, radius);
  }
}