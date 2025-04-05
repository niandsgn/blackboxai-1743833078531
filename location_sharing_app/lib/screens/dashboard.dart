import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_sharing_app/services/auth_service.dart';
import 'package:location_sharing_app/services/firestore_service.dart';
import 'package:location_sharing_app/services/location_service.dart';
import 'package:provider/provider.dart';
import 'package:location_sharing_app/screens/contacts/contact_list.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  bool _isSharing = false;
  Position? _currentPosition;
  StreamSubscription? _contactsSubscription;
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadContacts();
  }

  @override
  void dispose() {
    _contactsSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final position = await Provider.of<LocationService>(context, listen: false)
          .getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
      _updateCameraPosition();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    }
  }

  void _updateCameraPosition() {
    if (_currentPosition != null && _mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  void _loadContacts() {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    _contactsSubscription = firestoreService.getUserContacts().listen((snapshot) {
      final contactIds = snapshot.docs.map((doc) => doc.id).toList();
      if (contactIds.isNotEmpty) {
        firestoreService.getContactsLocations(contactIds).listen((contacts) {
          setState(() {
            _markers = contacts
                .where((contact) => contact.sharingEnabled)
                .map((contact) => Marker(
                      markerId: MarkerId(contact.id),
                      position: LatLng(
                        contact.geofenceCenter?[0] ?? _currentPosition?.latitude ?? 0,
                        contact.geofenceCenter?[1] ?? _currentPosition?.longitude ?? 0,
                      ),
                      infoWindow: InfoWindow(
                        title: contact.name,
                        snippet: contact.sharingEnabled ? 'Sharing location' : 'Not sharing',
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        contact.sharingEnabled 
                            ? BitmapDescriptor.hueBlue
                            : BitmapDescriptor.hueRed,
                      ),
                    ))
                .toSet();
          });
        });
      }
    });
  }

  void _toggleSharing() {
    setState(() {
      _isSharing = !_isSharing;
    });
    
    final locationService = Provider.of<LocationService>(context, listen: false);
    if (_isSharing) {
      locationService.startSharingLocation(context);
    } else {
      locationService.stopSharingLocation();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSharing
              ? 'Location sharing activated'
              : 'Location sharing deactivated',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Sharing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 15,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                });
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'contacts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactListScreen(),
                ),
              );
            },
            child: const Icon(Icons.contacts),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'sharing',
            onPressed: _toggleSharing,
            child: Icon(_isSharing ? Icons.location_off : Icons.location_on),
          ),
        ],
      ),
    );
  }
}