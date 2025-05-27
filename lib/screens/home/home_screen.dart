import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:fixitpro/providers/auth_provider.dart';
import 'package:fixitpro/providers/service_provider.dart';
import 'package:fixitpro/screens/home/service_detail_screen.dart';
import 'package:fixitpro/screens/home/services_by_category_screen.dart';
import 'package:fixitpro/widgets/service_card.dart';
import 'package:fixitpro/widgets/custom_text_field.dart';
import 'package:fixitpro/widgets/custom_appbar.dart';
import 'package:fixitpro/widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<ServiceModel> _filteredServices = [];
  List<ServiceTypeModel> _serviceTypes = [];

  @override
  void initState() {
    super.initState();
    _loadServices();

    _searchController.addListener(() {
      _filterServices(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      // Force refresh to ensure we get latest services added by admin
      await serviceProvider.loadServices(forceRefresh: true);

      // Get service types that have services
      _serviceTypes = serviceProvider.getServiceTypesWithServices();
    } catch (e) {
      // Log error but continue with whatever services might be in memory
      debugPrint('Error refreshing services: $e');
    }

    // Always update UI with whatever services are available
    setState(() {
      _filteredServices = serviceProvider.services;
      _isLoading = false;
    });
  }

  void _filterServices(String query) {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );

    if (query.isEmpty) {
      setState(() {
        _filteredServices = serviceProvider.services;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();

    setState(() {
      _filteredServices =
          serviceProvider.services.where((service) {
            return service.title.toLowerCase().contains(lowercaseQuery) ||
                service.description.toLowerCase().contains(lowercaseQuery);
          }).toList();
    });
  }

  void _navigateToServiceDetail(ServiceModel service) {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    serviceProvider.selectService(service);
    Navigator.pushNamed(context, ServiceDetailScreen.routeName);
  }

  void _navigateToServicesByType(ServiceTypeModel type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ServicesByCategoryScreen(
              categoryId: type.id,
              categoryName: type.displayName,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Get device size for responsiveness
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: const UserDashboardAppBar(),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadServices,
                  child: CustomScrollView(
                    slivers: [
                      // Greeting and Search
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: AppConstants.getResponsivePadding(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${user?.name.split(' ').first ?? 'User'}!',
                                style: AppConstants.getResponsiveHeadingStyle(
                                  context,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'What service do you need today?',
                                style: AppConstants.getResponsiveSmallTextStyle(
                                  context,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SearchTextField(
                                controller: _searchController,
                                hint: 'Search for services...',
                                onClear: () {
                                  _searchController.clear();
                                  _filterServices('');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // If user is searching, show search results
                      if (_searchController.text.isNotEmpty) ...[
                        _buildCategoryHeader(
                          'Search Results (${_filteredServices.length})',
                        ),
                        _buildServicesList(_filteredServices),
                      ],

                      // Otherwise show only service type cards
                      if (_searchController.text.isEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  AppConstants.getResponsivePadding(
                                    context,
                                  ).left,
                              vertical: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service Categories',
                                  style:
                                      AppConstants.getResponsiveSubheadingStyle(
                                        context,
                                      ),
                                ),
                                const SizedBox(height: 16),

                                // Display service types in a grid layout
                                GridView.count(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  crossAxisCount: isSmallScreen ? 1 : 2,
                                  childAspectRatio: isSmallScreen ? 1.2 : 0.85,
                                  crossAxisSpacing: isSmallScreen ? 8 : 16,
                                  mainAxisSpacing: isSmallScreen ? 8 : 16,
                                  padding: const EdgeInsets.only(bottom: 16),
                                  children:
                                      _serviceTypes.map((type) {
                                        // Get icon and color based on service type
                                        IconData icon;
                                        Color color;

                                        // Map service type to icon and color
                                        if (type.id == 'repair') {
                                          icon = Icons.build;
                                          color = Colors.orange;
                                        } else if (type.id == 'installation') {
                                          icon = Icons.handyman;
                                          color = Colors.blue;
                                        } else if (type.id ==
                                            'installationWithMaterial') {
                                          icon = Icons.inventory;
                                          color = Colors.green;
                                        } else {
                                          // Default for custom types
                                          icon = Icons.miscellaneous_services;
                                          color = Colors.purple;
                                        }

                                        return _buildServiceTypeCard(
                                          type: type,
                                          icon: icon,
                                          color: color,
                                          onTap:
                                              () => _navigateToServicesByType(
                                                type,
                                              ),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildCategoryHeader(String title, {VoidCallback? onViewAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppConstants.getResponsivePadding(context).left,
          24,
          AppConstants.getResponsivePadding(context).right,
          16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppConstants.getResponsiveSubheadingStyle(context),
            ),
            if (onViewAll != null)
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: AppConstants.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList(List<ServiceModel> servicesList) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final crossAxisCount = isSmallScreen ? 1 : 2;

    if (servicesList.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.getResponsivePadding(context).left,
          ),
          child: Center(
            child: Text(
              'No services available in this category',
              style: TextStyle(
                color: Colors.grey,
                fontSize: AppConstants.getResponsiveFontSize(context, 14),
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.getResponsivePadding(context).left,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isSmallScreen ? 1.0 : 0.75,
          crossAxisSpacing: isSmallScreen ? 8 : 16,
          mainAxisSpacing: isSmallScreen ? 8 : 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final service = servicesList[index];
          return ServiceCard(
            service: service,
            onTap: () => _navigateToServiceDetail(service),
          );
        }, childCount: servicesList.length),
      ),
    );
  }

  Widget _buildServiceTypeCard({
    required ServiceTypeModel type,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final bool hasCustomImage = type.imageUrl.isNotEmpty;
    final double iconSize = isSmallScreen ? 36.0 : 40.0;
    final fontSize = AppConstants.getResponsiveFontSize(context, 16);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with colored background or custom image
            Container(
              width: isSmallScreen ? 64 : 72,
              height: isSmallScreen ? 64 : 72,
              padding:
                  hasCustomImage
                      ? EdgeInsets.zero
                      : EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color:
                    hasCustomImage ? Colors.transparent : color.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child:
                  hasCustomImage
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                          isSmallScreen ? 32 : 36,
                        ),
                        child: Image.network(
                          type.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  Icon(icon, color: color, size: iconSize),
                        ),
                      )
                      : Icon(icon, color: color, size: iconSize),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            // Service type name
            Text(
              type.displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
            ),
            // Material indicator if applicable
            if (type.includesMaterial)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: isSmallScreen ? 1 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Material Included',
                    style: TextStyle(
                      fontSize: AppConstants.getResponsiveFontSize(context, 10),
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
