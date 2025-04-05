import 'package:flutter/material.dart';
import 'package:location_sharing_app/models/contact.dart';
import 'package:location_sharing_app/services/firestore_service.dart';
import 'package:provider/provider.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Contacts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: Provider.of<FirestoreService>(context).getUserContacts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final contacts = snapshot.data!.docs
              .map((doc) => Contact.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Add by email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _isLoading ? null : _addContact,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      title: Text(contact.name),
                      subtitle: Text(contact.email),
                      trailing: Switch(
                        value: contact.sharingEnabled,
                        onChanged: (value) => _toggleSharing(contact, value),
                      ),
                      onTap: () => _showGeofenceDialog(contact),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addContact() async {
    if (_emailController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .addContact(_emailController.text.trim());
      _emailController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add contact: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSharing(Contact contact, bool value) async {
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .updateContactSharing(contact.id, value);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update sharing: ${e.toString()}')),
      );
    }
  }

  Future<void> _showGeofenceDialog(Contact contact) async {
    // TODO: Implement geofence configuration dialog
  }
}