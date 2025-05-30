import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:fixitpro/providers/admin_provider.dart';

class ManageServicesScreen extends StatefulWidget {
  static const String routeName = '/admin/manage-services';

  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
    });

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.fetchServices();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final services = adminProvider.services;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Services')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadServices,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            services.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No services available.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: services.length,
                                  itemBuilder: (context, index) {
                                    final service = services[index];
                                    return _buildServiceCard(service);
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddServiceDialog(context);
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Services List',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // Show filter options
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          service.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${service.type.displayName}',
              style: const TextStyle(fontSize: 12),
            ),
            if (service.type.includesMaterial)
              Text(
                'Includes Material Options',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              service.imageUrl.isNotEmpty
                  ? Image.network(
                    service.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                  )
                  : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[300],
                    child: const Icon(Icons.home_repair_service),
                  ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showEditServiceDialog(context, service);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteServiceConfirmation(context, service);
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: ${service.description}'),
                const SizedBox(height: 8),
                Text('Unit: ${service.unit.toString().split('.').last}'),
                const SizedBox(height: 8),
                Text(
                  'Includes Material: ${service.includesMaterial ? 'Yes' : 'No'}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tiers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildTiersList(service),
                const SizedBox(height: 16),
                if (service.includesMaterial) ...[
                  const Text(
                    'Material Designs',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildDesignsList(service),
                ],
                const SizedBox(height: 16),
                OverflowBar(
                  alignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showAddTierDialog(context, service),
                      icon: const Icon(Icons.price_change),
                      label: const Text('Add Tier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    if (service.type.includesMaterial)
                      OutlinedButton.icon(
                        onPressed: () => _showAddDesignDialog(context, service),
                        icon: const Icon(Icons.design_services),
                        label: const Text('Add Design'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed:
                          () =>
                              _showDeleteServiceConfirmation(context, service),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTiersList(ServiceModel service) {
    if (service.tiers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'No tiers available.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: service.tiers.length,
      itemBuilder: (context, index) {
        final tier = service.tiers[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.blue[50],
          child: ListTile(
            title: Text(
              tier.tier.toString().split('.').last.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price: ₹${tier.price.toStringAsFixed(2)}'),
                Text('Warranty: ${tier.warrantyMonths} months'),
                if (tier.features.isNotEmpty)
                  Text('Features: ${tier.features.join(", ")}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Show confirmation dialog to delete tier
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesignsList(ServiceModel service) {
    if (service.designs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'No designs available.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: service.designs.length,
      itemBuilder: (context, index) {
        final design = service.designs[index];
        return Card(
          color: Colors.green[50],
          child: Column(
            children: [
              Expanded(
                child:
                    design.imageUrl.isNotEmpty
                        ? Image.network(
                          design.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.image_not_supported,
                                size: 50,
                              ),
                        )
                        : const Icon(Icons.image_not_supported, size: 50),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      design.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('₹${design.pricePerUnit.toStringAsFixed(2)} per unit'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            // Show confirmation dialog to delete design
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    final basicPriceController = TextEditingController();
    final standardPriceController = TextEditingController();
    final premiumPriceController = TextEditingController();

    // Default terms for each tier
    final Map<String, List<String>> defaultTerms = {
      'basic': ['Basic service', 'Standard tools', '1 month warranty'],
      'standard': [
        'Basic service',
        'Premium tools',
        'Faster service',
        '3 months warranty',
      ],
      'premium': [
        'Basic service',
        'Premium tools',
        'Priority service',
        'Free maintenance',
        '6 months warranty',
      ],
    };

    ServiceTypeModel selectedType = ServiceTypeModel.repair;
    MeasurementUnit selectedUnit = MeasurementUnit.sqft;
    bool includesMaterial = false;
    String categoryId = "default"; // Default category

    // Placeholder image URL if user doesn't provide one
    final defaultImageUrl =
        "https://placehold.co/600x400/orange/white?text=Home+Repair+Service";

    // Load service types first
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    adminProvider.fetchServiceTypes();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (BuildContext context, StateSetter setState) => AlertDialog(
                  title: const Text('Add New Service'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Service Title*',
                          ),
                        ),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description*',
                          ),
                          maxLines: 3,
                        ),
                        TextField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            hintText: 'Optional: URL to service image',
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<ServiceTypeModel>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Service Type*',
                          ),
                          items:
                              Provider.of<AdminProvider>(
                                context,
                              ).serviceTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.displayName),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedType = value;
                                includesMaterial = value.includesMaterial;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MeasurementUnit>(
                          value: selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Measurement Unit*',
                          ),
                          items:
                              MeasurementUnit.values.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(
                                    unit == MeasurementUnit.sqft
                                        ? 'Square Feet (sqft)'
                                        : 'Inches (inch)',
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedUnit = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Includes Material'),
                          subtitle: Text(
                            'This value is automatically set based on the selected service type (${selectedType.displayName})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          value: includesMaterial,
                          onChanged:
                              null, // Make it read-only since it's set by the service type
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Basic Tier Price*',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextFormField(
                          controller: basicPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter basic tier price',
                            prefixText: '\$',
                          ),
                          onChanged: (value) {
                            // Handle price input validation
                          },
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
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // If no image URL is provided, use the default placeholder
                        final imageUrl =
                            imageUrlController.text.isEmpty
                                ? defaultImageUrl
                                : imageUrlController.text;

                        // Create service
                        final service = ServiceModel(
                          id: '',
                          title: titleController.text,
                          description: descriptionController.text,
                          type: selectedType,
                          unit: selectedUnit,
                          includesMaterial: selectedType.includesMaterial,
                          imageUrl: imageUrl,
                          categoryId: categoryId,
                        );

                        final adminProvider = Provider.of<AdminProvider>(
                          context,
                          listen: false,
                        );
                        final success = await adminProvider.addService(service);

                        if (!mounted) return;

                        if (success) {
                          // Find newly created service
                          final createdService = adminProvider.services
                              .firstWhere(
                                (s) => s.title == service.title,
                                orElse: () => service,
                              );

                          // Add pricing tiers to the service
                          List<Future<bool>> tierAdditions = [];

                          // Add Basic Tier (required)
                          tierAdditions.add(
                            _addTierToService(
                              context,
                              createdService.id,
                              TierType.basic,
                              double.parse(basicPriceController.text),
                              1, // 1 month warranty
                              defaultTerms['basic']!,
                            ),
                          );

                          // Add Standard Tier (if price provided)
                          if (standardPriceController.text.isNotEmpty) {
                            tierAdditions.add(
                              _addTierToService(
                                context,
                                createdService.id,
                                TierType.standard,
                                double.parse(standardPriceController.text),
                                3, // 3 months warranty
                                defaultTerms['standard']!,
                              ),
                            );
                          }

                          // Add Premium Tier (if price provided)
                          if (premiumPriceController.text.isNotEmpty) {
                            tierAdditions.add(
                              _addTierToService(
                                context,
                                createdService.id,
                                TierType.premium,
                                double.parse(premiumPriceController.text),
                                6, // 6 months warranty
                                defaultTerms['premium']!,
                              ),
                            );
                          }

                          // Wait for all tier additions to complete
                          await Future.wait(tierAdditions);

                          if (!mounted) return;

                          // Close dialog and show success message
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Service with pricing tiers added successfully!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Refresh the services list
                          _loadServices();
                        } else {
                          if (!mounted) return;

                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to add service: ${adminProvider.error ?? "Unknown error"}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Add Service'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Helper method to add tier to a service
  Future<bool> _addTierToService(
    BuildContext context,
    String serviceId,
    TierType tierType,
    double price,
    int warrantyMonths,
    List<String> features,
  ) async {
    // Capture provider before the async gap
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    // Now use the captured provider without context
    final tier = TierPricing(
      id: '',
      serviceId: serviceId,
      tier: tierType,
      price: price,
      warrantyMonths: warrantyMonths,
      features: features,
    );
    return await adminProvider.addTierPricing(serviceId, tier);
  }

  void _showEditServiceDialog(BuildContext context, ServiceModel service) {
    final titleController = TextEditingController(text: service.title);
    final descriptionController = TextEditingController(
      text: service.description,
    );
    final imageUrlController = TextEditingController(text: service.imageUrl);
    var selectedType = service.type;
    var selectedUnit = service.unit;
    var includesMaterial = service.includesMaterial;

    // Load service types first
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    adminProvider.fetchServiceTypes();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Edit Service'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Service Title',
                          ),
                        ),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          maxLines: 3,
                        ),
                        TextField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ServiceTypeModel>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Service Type',
                          ),
                          items:
                              Provider.of<AdminProvider>(
                                context,
                              ).serviceTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.displayName),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedType = value;
                                includesMaterial = value.includesMaterial;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MeasurementUnit>(
                          value: selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Measurement Unit',
                          ),
                          items:
                              MeasurementUnit.values.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit.toString().split('.').last),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedUnit = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Includes Material'),
                          subtitle: Text(
                            'This value is automatically set based on the selected service type (${selectedType.displayName})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          value: includesMaterial,
                          onChanged:
                              null, // Make it read-only since it's set by the service type
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
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Create updated service
                        final updatedService = ServiceModel(
                          id: service.id,
                          title: titleController.text,
                          description: descriptionController.text,
                          type: selectedType,
                          unit: selectedUnit,
                          includesMaterial:
                              selectedType
                                  .includesMaterial, // Get from type, not switch
                          imageUrl: imageUrlController.text,
                          tiers: service.tiers,
                          designs: service.designs,
                          categoryId: service.categoryId,
                        );

                        // Capture context and provider before async gap
                        final currentContext = context;
                        final adminProvider = Provider.of<AdminProvider>(
                          currentContext,
                          listen: false,
                        );

                        final success = await adminProvider.updateService(
                          updatedService,
                        );

                        if (!mounted) return;

                        Navigator.of(currentContext).pop();
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Service updated successfully'
                                  : 'Failed to update service: ${adminProvider.error ?? "Unknown error"}',
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

  void _showAddTierDialog(BuildContext context, ServiceModel service) {
    final priceController = TextEditingController();
    final warrantyController = TextEditingController();
    final featuresController = TextEditingController();
    final visitChargeController = TextEditingController();
    var selectedTier = TierType.basic;
    List<TierType> tierTypes = TierType.values;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Tier Pricing'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<TierType>(
                    value: selectedTier,
                    decoration: const InputDecoration(labelText: 'Tier Type'),
                    items:
                        tierTypes.map((tier) {
                          return DropdownMenuItem(
                            value: tier,
                            child: Text(
                              tier.toString().split('.').last.toUpperCase(),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedTier = value;
                      }
                    },
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price (₹)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: visitChargeController,
                    decoration: const InputDecoration(
                      labelText: 'Visit Charge (₹)',
                      hintText: 'Amount to be paid upfront for booking',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: warrantyController,
                    decoration: const InputDecoration(
                      labelText: 'Warranty (months)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: featuresController,
                    decoration: const InputDecoration(
                      labelText: 'Features (comma separated)',
                    ),
                    maxLines: 3,
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
                  if (priceController.text.isEmpty ||
                      warrantyController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill price and warranty'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Parse features
                  List<String> features = [];
                  if (featuresController.text.isNotEmpty) {
                    features =
                        featuresController.text
                            .split(',')
                            .map((e) => e.trim())
                            .toList();
                  }

                  // Capture context and provider before async gap
                  final currentContext = context;
                  final adminProvider = Provider.of<AdminProvider>(
                    currentContext,
                    listen: false,
                  );

                  final tier = TierPricing(
                    id: '',
                    serviceId: service.id,
                    tier: selectedTier,
                    price: double.parse(priceController.text),
                    warrantyMonths: int.parse(warrantyController.text),
                    features: features,
                    visitCharge:
                        visitChargeController.text.isNotEmpty
                            ? double.parse(visitChargeController.text)
                            : 0.0,
                  );

                  final success = await adminProvider.addTierPricing(
                    service.id,
                    tier,
                  );

                  if (!mounted) return;
                  Navigator.of(currentContext).pop();
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Tier added successfully'
                            : 'Failed to add tier: ${adminProvider.error ?? "Unknown error"}',
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

  void _showAddDesignDialog(BuildContext context, ServiceModel service) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Material Design'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Design Name'),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per unit (₹)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(labelText: 'Image URL'),
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
                      priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill name and price'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Capture the context and provider before async gap
                  final currentContext = context;
                  final adminProvider = Provider.of<AdminProvider>(
                    currentContext,
                    listen: false,
                  );

                  final design = MaterialDesign(
                    id: '',
                    serviceId: service.id,
                    name: nameController.text,
                    pricePerUnit: double.parse(priceController.text),
                    imageUrl: imageUrlController.text,
                  );

                  final success = await adminProvider.addMaterialDesign(
                    service.id,
                    design,
                  );

                  // Use mounted check before accessing context after async gap
                  if (!mounted) return;

                  Navigator.of(currentContext).pop();
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Design added successfully'
                            : 'Failed to add design: ${adminProvider.error ?? "Unknown error"}',
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

  void _showDeleteServiceConfirmation(
    BuildContext context,
    ServiceModel service,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Service'),
            content: const Text(
              'Are you sure you want to delete this service? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Capture context and provider before async gap
                  final currentContext = context;
                  final adminProvider = Provider.of<AdminProvider>(
                    currentContext,
                    listen: false,
                  );

                  final success = await adminProvider.deleteService(service.id);

                  // Use mounted check before accessing context after async gap
                  if (!mounted) return;

                  Navigator.of(currentContext).pop();
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Service deleted successfully'
                            : 'Failed to delete service: ${adminProvider.error ?? "Unknown error"}',
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
