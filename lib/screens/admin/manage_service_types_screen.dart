import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:fixitpro/providers/admin_provider.dart';

class ManageServiceTypesScreen extends StatefulWidget {
  static const String routeName = '/admin/manage-service-types';

  const ManageServiceTypesScreen({super.key});

  @override
  State<ManageServiceTypesScreen> createState() =>
      _ManageServiceTypesScreenState();
}

class _ManageServiceTypesScreenState extends State<ManageServiceTypesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceTypes();
  }

  Future<void> _loadServiceTypes() async {
    setState(() {
      _isLoading = true;
    });

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.fetchServiceTypes();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final serviceTypes = adminProvider.serviceTypes;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Service Types')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadServiceTypes,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            serviceTypes.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No service types available.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: serviceTypes.length,
                                  itemBuilder: (context, index) {
                                    final serviceType = serviceTypes[index];
                                    return _buildServiceTypeCard(serviceType);
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddServiceTypeDialog(context);
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Service Types List',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildServiceTypeCard(ServiceTypeModel serviceType) {
    // Check if this is a default service type
    final isDefaultType =
        ServiceTypeModel.defaults
            .where((type) => type.id == serviceType.id)
            .isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0x1A2196F3), // Colors.blue with opacity 0.1
            shape: BoxShape.circle,
          ),
          child:
              serviceType.imageUrl.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.network(
                      serviceType.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.miscellaneous_services,
                            color: Colors.blue,
                          ),
                    ),
                  )
                  : const Icon(
                    Icons.miscellaneous_services,
                    color: Colors.blue,
                  ),
        ),
        title: Text(
          serviceType.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${serviceType.id}'),
            Text('Name: ${serviceType.name}'),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Includes Material: ${serviceType.includesMaterial ? 'Yes' : 'No'}',
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message:
                      'When enabled, services using this type will have material options available',
                  child: const Icon(Icons.info_outline, size: 16),
                ),
              ],
            ),
            if (serviceType.imageUrl.isNotEmpty)
              Text(
                'Custom Icon: Yes',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (isDefaultType)
              const Text(
                'Default Type (Cannot be modified)',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing:
            isDefaultType
                ? const Icon(Icons.lock, color: Colors.grey)
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed:
                          () =>
                              _showEditServiceTypeDialog(context, serviceType),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed:
                          () => _showDeleteConfirmationDialog(
                            context,
                            serviceType,
                          ),
                    ),
                  ],
                ),
      ),
    );
  }

  void _showAddServiceTypeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final displayNameController = TextEditingController();
    final imageUrlController = TextEditingController();
    bool includesMaterial = false;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Service Type'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Service Type Name*',
                      hintText: 'E.g. consultation',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name*',
                      hintText: 'E.g. Consultation',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Icon URL (Optional)',
                      hintText: 'https://example.com/icon.png',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Includes Material'),
                    subtitle: const Text(
                      'If enabled, services using this type will have material options available for selection',
                      style: TextStyle(fontSize: 12),
                    ),
                    leading: Checkbox(
                      value: includesMaterial,
                      onChanged: (value) {
                        setState(() {
                          includesMaterial = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      displayNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Create service type
                  final serviceType = ServiceTypeModel(
                    id: '',
                    name: nameController.text.trim().toLowerCase(),
                    displayName: displayNameController.text.trim(),
                    includesMaterial: includesMaterial,
                    imageUrl: imageUrlController.text.trim(),
                  );

                  final adminProvider = Provider.of<AdminProvider>(
                    context,
                    listen: false,
                  );
                  final success = await adminProvider.addServiceType(
                    serviceType,
                  );

                  if (!mounted) return;
                  Navigator.of(context).pop();

                  // Show success or error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Service type added successfully'
                            : 'Failed to add service type: ${adminProvider.error ?? "Unknown error"}',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditServiceTypeDialog(
    BuildContext context,
    ServiceTypeModel serviceType,
  ) {
    final nameController = TextEditingController(text: serviceType.name);
    final displayNameController = TextEditingController(
      text: serviceType.displayName,
    );
    final imageUrlController = TextEditingController(
      text: serviceType.imageUrl,
    );
    bool includesMaterial = serviceType.includesMaterial;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Edit Service Type'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Service Type Name*',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name*',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Icon URL (Optional)',
                            hintText: 'https://example.com/icon.png',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Includes Material'),
                          subtitle: const Text(
                            'If enabled, services using this type will have material options available for selection',
                            style: TextStyle(fontSize: 12),
                          ),
                          leading: Checkbox(
                            value: includesMaterial,
                            onChanged: (value) {
                              setState(() {
                                includesMaterial = value ?? false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            displayNameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Update service type
                        final updatedServiceType = ServiceTypeModel(
                          id: serviceType.id,
                          name: nameController.text.trim().toLowerCase(),
                          displayName: displayNameController.text.trim(),
                          includesMaterial: includesMaterial,
                          imageUrl: imageUrlController.text.trim(),
                        );

                        final adminProvider = Provider.of<AdminProvider>(
                          context,
                          listen: false,
                        );
                        final success = await adminProvider.updateServiceType(
                          updatedServiceType,
                        );

                        if (!mounted) return;
                        Navigator.of(context).pop();

                        // Show success or error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Service type updated successfully'
                                  : 'Failed to update service type: ${adminProvider.error ?? "Unknown error"}',
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                      child: const Text('Update'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    ServiceTypeModel serviceType,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Service Type'),
            content: Text(
              'Are you sure you want to delete service type "${serviceType.displayName}"? '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final adminProvider = Provider.of<AdminProvider>(
                    context,
                    listen: false,
                  );
                  final success = await adminProvider.deleteServiceType(
                    serviceType.id,
                  );

                  if (!mounted) return;
                  Navigator.of(context).pop();

                  // Show success or error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Service type deleted successfully'
                            : 'Failed to delete service type: ${adminProvider.error ?? "Unknown error"}',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
