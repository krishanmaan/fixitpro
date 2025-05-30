import 'package:flutter/material.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fixitpro/screens/service/service_detail_screen.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    // Adjust sizes based on screen size
    final double titleFontSize = AppConstants.getResponsiveFontSize(
      context,
      isSmallScreen ? 15 : 16,
    );
    final double bodyFontSize = AppConstants.getResponsiveFontSize(
      context,
      isSmallScreen ? 13 : 14,
    );
    final double badgeFontSize = AppConstants.getResponsiveFontSize(
      context,
      isSmallScreen ? 11 : 12,
    );
    final double iconSize = isSmallScreen ? 14.0 : 16.0;
    final double padding = isSmallScreen ? 12.0 : 16.0;
    final double cardRadius = isSmallScreen ? 10.0 : 16.0;
    final double cardElevation = 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        clipBehavior: Clip.antiAlias,
        elevation: cardElevation,
        child: InkWell(
          onTap:
              onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailScreen(service: service),
                  ),
                );
              },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service image with type indicator
              Stack(
                children: [
                  Hero(
                    tag: 'service_image_${service.id}',
                    child: SizedBox(
                      height: isSmallScreen ? 120 : 140,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: service.imageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppConstants.primaryColor.withAlpha(178),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        errorWidget:
                            (ctx, url, error) => Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: Icon(
                                  Icons.home_repair_service,
                                  size: isSmallScreen ? 32 : 40,
                                  color: AppConstants.primaryColor.withAlpha(
                                    77,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                  // Service type badge
                  Positioned(
                    top: isSmallScreen ? 8 : 12,
                    right: isSmallScreen ? 8 : 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 10,
                        vertical: isSmallScreen ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(
                          isSmallScreen ? 12 : 16,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getServiceTypeLabel(service.type),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: badgeFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay at the bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(77),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Service details
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            service.title,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        color: AppConstants.lightTextColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.currency_rupee,
                              size: iconSize,
                              color: AppConstants.primaryColor,
                            ),
                            Text(
                              'Starts at ${getBasicTierPrice()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                                fontSize: bodyFontSize,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 10,
                            vertical: isSmallScreen ? 4 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              isSmallScreen ? 8 : 10,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: isSmallScreen ? 12 : 14,
                                color: AppConstants.primaryColor,
                              ),
                              SizedBox(width: isSmallScreen ? 3 : 4),
                              Text(
                                'Book Now',
                                style: TextStyle(
                                  fontSize: badgeFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
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

  // Helper method to get the basic tier price
  String getBasicTierPrice() {
    if (service.tiers.isEmpty) {
      return 'N/A';
    }

    // Find the basic tier or the cheapest tier
    final basicTier = service.tiers.firstWhere(
      (tier) => tier.tier == TierType.basic,
      orElse: () => service.tiers.reduce((a, b) => a.price < b.price ? a : b),
    );

    return '₹${basicTier.price.toStringAsFixed(0)}/sq.ft';
  }

  // Helper method to get service type label
  String _getServiceTypeLabel(ServiceTypeModel type) {
    return type.displayName;
  }
}

class ServiceCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ServiceCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    // Adjust sizes based on screen size
    final double iconSize = isSmallScreen ? 26.0 : 30.0;
    final double containerSize = isSmallScreen ? 50.0 : 60.0;
    final double fontSize = AppConstants.getResponsiveFontSize(context, 14);
    final double padding = isSmallScreen ? 12.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: AppConstants.whiteColor,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13), // 0.05 * 255 = ~13
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: color.withAlpha(26), // 0.1 * 255 = ~26
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            SizedBox(height: isSmallScreen ? 6.0 : 8.0),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
