import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/providers/service_provider.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:fixitpro/screens/home/service_detail_screen.dart';

class ServicesByCategoryScreen extends StatelessWidget {
  static const String routeName = '/services-by-category';

  final String categoryId;
  final String categoryName;

  const ServicesByCategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.primaryColor,
        elevation: 0,
      ),
      body: Consumer<ServiceProvider>(
        builder: (context, serviceProvider, child) {
          // Get services based on the category type
          List<ServiceModel> services;

          // Handle both legacy and new service types
          if (categoryId == 'all') {
            services = serviceProvider.services;
          } else if (categoryId == 'installation' ||
              categoryId == 'repair' ||
              categoryId == 'installationWithMaterial') {
            // These are default service types, use ID-based lookup
            services = serviceProvider.getServicesByTypeId(categoryId);
          } else {
            // This might be a custom service type
            services = serviceProvider.getServicesByTypeId(categoryId);

            // If no services found, fallback to category ID from model
            if (services.isEmpty) {
              services = serviceProvider.getServicesByCategory(categoryId);
            }
          }

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No services available in this category',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Services', style: AppConstants.subheadingStyle),
                const SizedBox(height: 8),
                Text(
                  'Choose from our professional ${categoryName.toLowerCase()} services',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _buildServiceListItem(context, service);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceListItem(BuildContext context, ServiceModel service) {
    // Get the basic tier price if available
    String priceText = 'Price not set';
    if (service.tiers.isNotEmpty) {
      final basicTier = service.tiers.firstWhere(
        (tier) => tier.tier == TierType.basic,
        orElse: () => service.tiers.first,
      );
      priceText = '₹${basicTier.price.toStringAsFixed(0)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Select this service and navigate to detail
          Provider.of<ServiceProvider>(
            context,
            listen: false,
          ).selectService(service);
          Navigator.pushNamed(context, ServiceDetailScreen.routeName);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  child:
                      service.imageUrl.isNotEmpty
                          ? Image.network(
                            service.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                          )
                          : const Icon(
                            Icons.home_repair_service,
                            size: 40,
                            color: Colors.grey,
                          ),
                ),
              ),
              const SizedBox(width: 16),
              // Service info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            priceText,
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Service type badge
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            service.type.displayName,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'View Details',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppConstants.primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
