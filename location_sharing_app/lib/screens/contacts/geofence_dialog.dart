import 'package:flutter/material.dart';
import 'package:location_sharing_app/models/contact.dart';
import 'package:provider/provider.dart';
import 'package:location_sharing_app/services/geofence_service.dart';

class GeofenceDialog extends StatefulWidget {
  final Contact contact;

  const GeofenceDialog({super.key, required this.contact});

  @override
  State<GeofenceDialog> createState() => _GeofenceDialogState();
}

class _GeofenceDialogState extends State<GeofenceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _radiusController = TextEditingController(text: '100');
  double? _latitude;
  double? _longitude;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Geofence for ${widget.contact.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _radiusController,
              decoration: const InputDecoration(
                labelText: 'Radius (meters)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a radius';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            if (_latitude != null && _longitude != null)
              Text('Location: $_latitude, $_longitude'),
            ElevatedButton(
              onPressed: _selectLocation,
              child: const Text('Select Location'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveGeofence,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectLocation() async {
    final selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        _latitude = selectedLocation.latitude;
        _longitude = selectedLocation.longitude;
      });
    }
  }

  Future<void> _saveGeofence() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    try {
      await Provider.of<GeofenceService>(context, listen: false).addGeofence(
        widget.contact.id,
        _latitude!,
        _longitude!,
        double.parse(_radiusController.text),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save geofence: ${e.toString()}')),
      );
    }
  }
}