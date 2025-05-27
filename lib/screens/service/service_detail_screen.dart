import 'package:flutter/material.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/providers/service_provider.dart';
import 'package:fixitpro/screens/booking/booking_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(service.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                service.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 60),
                    ),
                  );
                },
              ),
            ),

            // Service details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Tier pricing section
                  Text(
                    'Available Tiers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Create tier cards for each tier
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: service.tiers.length,
                    itemBuilder: (context, index) {
                      final tier = service.tiers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTierTitle(tier.tier),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.currency_rupee, size: 16),
                                  Text(
                                    '${tier.price.toString()}/${service.unit.toString().split('.').last}',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (tier.features.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Features:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...tier.features
                                        .map(
                                          (feature) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text(feature)),
                                              ],
                                            ),
                                          ),
                                        )
                                        ,
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Text(
                                'Warranty: ${tier.warrantyMonths} months',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Material designs section (if applicable)
                  if (service.designs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Available Designs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: service.designs.length,
                        itemBuilder: (context, index) {
                          final design = service.designs[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 80,
                                  width: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      design.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  design.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '₹${design.pricePerUnit}/unit',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              // Set the selected service in the provider
              final serviceProvider = Provider.of<ServiceProvider>(
                context,
                listen: false,
              );
              serviceProvider.selectService(service);

              // Navigate to booking screen
              Navigator.pushNamed(context, BookingScreen.routeName);
            },
            child: const Text('Book Now'),
          ),
        ),
      ),
    );
  }

  // Helper method to get tier title based on enum
  String _getTierTitle(TierType tierType) {
    switch (tierType) {
      case TierType.basic:
        return 'Basic';
      case TierType.standard:
        return 'Standard';
      case TierType.premium:
        return 'Premium';
    
    }
  }
}
