import 'package:flutter/material.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/user_model.dart';
import 'package:fixitpro/services/address_service.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class AddressScreen extends StatefulWidget {
  static const String routeName = '/addresses';

  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final AddressService _addressService = AddressService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      body: StreamBuilder<List<SavedAddress>>(
        stream: _addressService.getAddressesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading addresses: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final addresses = snapshot.data ?? [];

          if (addresses.isEmpty) {
            return const Center(
              child: Text(
                'No addresses saved yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _buildAddressCard(address, addresses);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditAddressDialog(context);
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddressCard(SavedAddress address, List<SavedAddress> addresses) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withAlpha(
                          (0.1 * 255).round(),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        address.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    if (addresses.indexOf(address) == 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        _showAddEditAddressDialog(context, address: address);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        _showDeleteAddressDialog(context, address);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.address,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            // Show location on map preview
            Container(
              margin: const EdgeInsets.only(top: 16),
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    _buildMapPreview(address),
                    // Location marker overlay
                    Center(
                      child: Icon(
                        Icons.location_on,
                        color: AppConstants.primaryColor,
                        size: 36,
                      ),
                    ),
                    // Clickable transparent overlay
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showMapFullScreen(context, address),
                        child: Container(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPreview(SavedAddress address) {
    // In a real implementation, you would use GoogleMap widget here
    return Container(
      color: Colors.grey[200],
      child: Center(child: Icon(Icons.map, size: 48, color: Colors.grey[400])),
    );
  }

  void _showMapFullScreen(BuildContext context, SavedAddress address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(address.label),
                backgroundColor: AppConstants.primaryColor,
              ),
              body: Stack(
                children: [
                  // In a real implementation, you would use GoogleMap widget here
                  Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Map View',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Location details card
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              address.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(address.address),
                            const SizedBox(height: 8),
                            Text(
                              'Coordinates: ${address.latitude.toStringAsFixed(6)}, ${address.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  void _showAddEditAddressDialog(
    BuildContext context, {
    SavedAddress? address,
  }) {
    final isEditing = address != null;
    final labelController = TextEditingController(
      text: isEditing ? address.label : '',
    );
    final addressController = TextEditingController(
      text: isEditing ? address.address : '',
    );

    // Default to current location or a fixed position if editing
    double latitude = isEditing ? address.latitude : 28.7041;
    double longitude = isEditing ? address.longitude : 77.1025;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label (e.g., Home, Office)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Full Address',
                      hintText: 'Street, City, State, ZIP',
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showLocationPicker(
                        context,
                        initialLatitude: latitude,
                        initialLongitude: longitude,
                        onLocationSelected: (lat, lng, address) {
                          latitude = lat;
                          longitude = lng;
                          if (address.isNotEmpty) {
                            addressController.text = address;
                          }
                        },
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Choose on Map'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validate input
                  if (labelController.text.isEmpty ||
                      addressController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  final newAddress = SavedAddress(
                    id: isEditing ? address.id : const Uuid().v4(),
                    label: labelController.text,
                    address: addressController.text,
                    latitude: latitude,
                    longitude: longitude,
                  );

                  final success = await _addressService.saveAddress(newAddress);

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address saved successfully'),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to save address'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
    );
  }

  void _showLocationPicker(
    BuildContext context, {
    required double initialLatitude,
    required double initialLongitude,
    required Function(double, double, String) onLocationSelected,
  }) {
    LatLng selectedLocation = LatLng(initialLatitude, initialLongitude);
    String selectedAddress = '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Pick Location'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // In a real implementation, you would use GoogleMap widget here
                        Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.map,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        // Center marker
                        Center(
                          child: Icon(
                            Icons.location_on,
                            color: AppConstants.primaryColor,
                            size: 48,
                          ),
                        ),
                        // Instructions text
                        Positioned(
                          top: 16,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.black54,
                            child: const Text(
                              'Tap to select location',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      selectedAddress =
                          'Lat: ${selectedLocation.latitude.toStringAsFixed(6)}, '
                          'Lng: ${selectedLocation.longitude.toStringAsFixed(6)}';
                      onLocationSelected(
                        selectedLocation.latitude,
                        selectedLocation.longitude,
                        selectedAddress,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Confirm Location'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showDeleteAddressDialog(BuildContext context, SavedAddress address) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Address'),
            content: Text(
              'Are you sure you want to delete your ${address.label} address?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final success = await _addressService.deleteAddress(
                    address.id,
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address deleted successfully'),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete address'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
