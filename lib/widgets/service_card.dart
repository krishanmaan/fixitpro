import 'package:flutter/material.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fixitpro/screens/service/service_detail_screen.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: service.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ),
            ),

            // Service Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Title
                    Text(
                      service.title,
                      style: TextStyle(
                        fontSize: AppConstants.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Service Description
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: AppConstants.getResponsiveFontSize(context, 12),
                        color: AppConstants.lightTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Service Type Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getServiceTypeIcon(service.type),
                            size: 14,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            service.type.displayName,
                            style: TextStyle(
                              fontSize: AppConstants.getResponsiveFontSize(context, 12),
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  IconData _getServiceTypeIcon(ServiceTypeModel type) {
    switch (type.id) {
      case 'repair':
        return Icons.build;
      case 'installation':
        return Icons.settings;
      case 'maintenance':
        return Icons.handyman;
      default:
        return Icons.miscellaneous_services;
    }
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
