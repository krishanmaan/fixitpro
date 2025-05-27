import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:fixitpro/providers/service_provider.dart';
import 'package:fixitpro/screens/booking/booking_screen.dart';
import 'package:fixitpro/widgets/custom_button.dart';

class ServiceDetailScreen extends StatefulWidget {
  static const String routeName = '/service-detail';

  const ServiceDetailScreen({super.key});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  TierType _selectedTier = TierType.basic;
  MaterialDesign? _selectedDesign;
  double _areaValue = 100.0; // Default area value in sq.ft.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serviceProvider = Provider.of<ServiceProvider>(
        context,
        listen: false,
      );
      // Select basic tier by default
      serviceProvider.selectTier(_selectedTier);
    });
  }

  void _selectTier(TierType tier) {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    serviceProvider.selectTier(tier);
    setState(() {
      _selectedTier = tier;
    });
  }

  void _selectDesign(MaterialDesign design) {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    serviceProvider.selectDesign(design);
    setState(() {
      _selectedDesign = design;
    });
  }

  void _navigateToBooking() {
    Navigator.pushNamed(context, BookingScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final service = serviceProvider.selectedService;

    if (service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Details')),
        body: const Center(child: Text('Service not found')),
      );
    }

    // Get the tier pricing
    final basicTier = service.tiers.firstWhere(
      (tier) => tier.tier == TierType.basic,
      orElse:
          () =>
              service.tiers.isNotEmpty
                  ? service.tiers.first
                  : TierPricing(
                    id: '',
                    serviceId: service.id,
                    tier: TierType.basic,
                    price: 0,
                    warrantyMonths: 0,
                    features: [],
                  ),
    );

    // Calculate total price based on area and selected options
    final double totalPrice = serviceProvider.calculateTotalPrice(_areaValue);

    final hasDesigns = service.includesMaterial && service.designs.isNotEmpty;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(service.title),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey.shade200,
                child:
                    service.imageUrl.isNotEmpty
                        ? Image.network(
                          service.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.home_repair_service,
                                size: 60,
                                color: Colors.grey,
                              ),
                        )
                        : const Icon(
                          Icons.home_repair_service,
                          size: 60,
                          color: Colors.grey,
                        ),
              ),
            ),

            // Service details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(
                            alpha: 0.1 * 255,
                            red: ((AppConstants.primaryColor.r * 255.0).round() & 0xff).toDouble(),
                            green: ((AppConstants.primaryColor.g * 255.0).round() & 0xff).toDouble(),
                            blue: ((AppConstants.primaryColor.b * 255.0).round() & 0xff).toDouble(),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹${basicTier.price}/${service.unit == MeasurementUnit.sqft ? 'sq.ft' : 'inch'}',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Service Type: ${_getServiceTypeLabel(service.type)}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'About this service',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (service.tiers.length > 1) ...[
                    const Text(
                      'Select Quality Tier',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTierSelector(service),
                    const SizedBox(height: 20),
                  ],

                  // Area estimation
                  const Text(
                    'Estimate Area',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drag the slider to estimate the area in ${service.unit == MeasurementUnit.sqft ? 'square feet' : 'inches'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        '50',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Slider(
                          value: _areaValue,
                          min: 50,
                          max: 500,
                          divisions: 45,
                          activeColor: AppConstants.primaryColor,
                          label: _areaValue.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _areaValue = value;
                            });
                          },
                        ),
                      ),
                      const Text(
                        '500',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_areaValue.round()} ${service.unit == MeasurementUnit.sqft ? 'sq.ft' : 'inches'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  // Material designs if applicable
                  if (hasDesigns) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Select Material (Optional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedDesign != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDesign = null;
                                // Deselect design in provider too
                                final serviceProvider =
                                    Provider.of<ServiceProvider>(
                                      context,
                                      listen: false,
                                    );
                                serviceProvider.selectDesign(null);
                              });
                            },
                            child: const Text(
                              "(Clear selection)",
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: service.designs.length,
                        itemBuilder: (context, index) {
                          final design = service.designs[index];
                          final isSelected = _selectedDesign?.id == design.id;

                          return GestureDetector(
                            onTap: () => _selectDesign(design),
                            child: Container(
                              width: 130,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? AppConstants.primaryColor
                                          : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(9),
                                      topRight: Radius.circular(9),
                                    ),
                                    child: Container(
                                      height: 80,
                                      width: double.infinity,
                                      color: Colors.grey.shade200,
                                      child:
                                          design.imageUrl.isNotEmpty
                                              ? Image.network(
                                                design.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.image,
                                                      color: Colors.grey,
                                                    ),
                                              )
                                              : const Icon(
                                                Icons.image,
                                                color: Colors.grey,
                                              ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          design.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '₹${design.pricePerUnit}/${service.unit == MeasurementUnit.sqft ? 'sq.ft' : 'inch'}',
                                          style: TextStyle(
                                            color: AppConstants.primaryColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // Space for bottom sheet
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.1 * 255,
                red: 0.0,
                green: 0.0,
                blue: 0.0,
              ),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show visit charge note if applicable
            if (serviceProvider.getSelectedTierPricing()?.visitCharge != null &&
                serviceProvider.getSelectedTierPricing()!.visitCharge > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              color: AppConstants.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Payment Breakdown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Visit Charge:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₹${serviceProvider.getSelectedTierPricing()!.visitCharge.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Service Charge:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₹${(totalPrice - serviceProvider.getSelectedTierPricing()!.visitCharge).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade800,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You will pay only the visit charge (₹${serviceProvider.getSelectedTierPricing()!.visitCharge.toStringAsFixed(0)}) to confirm your booking. Service charge will be collected after service completion.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total Estimate',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '₹${totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: CustomButton(
                    text:
                        serviceProvider.getSelectedTierPricing()?.visitCharge !=
                                    null &&
                                serviceProvider
                                        .getSelectedTierPricing()!
                                        .visitCharge >
                                    0
                            ? 'Pay ₹${serviceProvider.getSelectedTierPricing()!.visitCharge.toStringAsFixed(0)} & Book'
                            : 'Book Now',
                    onPressed: _navigateToBooking,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierSelector(ServiceModel service) {
    // Extract and sort tiers
    final tiers = [...service.tiers]
      ..sort((a, b) => a.tier.index.compareTo(b.tier.index));

    return Container(
      height: 120, // Increased height for visit charge info
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children:
            tiers.map((tier) {
              final isSelected = _selectedTier == tier.tier;
              final tierLabel = _getTierTypeLabel(tier.tier);
              final hasVisitCharge = tier.visitCharge > 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _selectTier(tier.tier),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppConstants.primaryColor
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    margin: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tierLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${tier.price}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.grey,
                          ),
                        ),
                        if (hasVisitCharge) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 12,
                                color:
                                    isSelected ? Colors.white70 : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Visit: ₹${tier.visitCharge.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      isSelected
                                          ? Colors.white70
                                          : Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Service: ₹${(tier.price - tier.visitCharge).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  isSelected
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  String _getServiceTypeLabel(ServiceTypeModel type) {
    return type.displayName;
  }

  String _getTierTypeLabel(TierType type) {
    switch (type) {
      case TierType.basic:
        return 'Basic';
      case TierType.standard:
        return 'Standard';
      case TierType.premium:
        return 'Premium';
    }
  }
}
