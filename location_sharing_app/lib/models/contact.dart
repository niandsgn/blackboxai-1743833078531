class Contact {
  final String id;
  final String name;
  final String email;
  final bool sharingEnabled;
  final List<double>? geofenceCenter;
  final double? geofenceRadius;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    this.sharingEnabled = false,
    this.geofenceCenter,
    this.geofenceRadius,
  });

  factory Contact.fromMap(Map<String, dynamic> data, String id) {
    return Contact(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      sharingEnabled: data['sharingEnabled'] ?? false,
      geofenceCenter: data['geofenceCenter'] != null
          ? List<double>.from(data['geofenceCenter'])
          : null,
      geofenceRadius: data['geofenceRadius']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'sharingEnabled': sharingEnabled,
      'geofenceCenter': geofenceCenter,
      'geofenceRadius': geofenceRadius,
    };
  }
}