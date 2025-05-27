import 'package:flutter/material.dart';

import 'package:fixitpro/constants/app_constants.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  static const String routeName = '/admin/analytics';

  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  final List<String> _periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  int _selectedPeriodIndex = 2; // Default to Monthly

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    // In a real app, you would load analytics data from your provider
    // await Provider.of<AdminProvider>(context, listen: false).fetchAnalytics();

    // For now, we'll use sample data
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Bookings'), Tab(text: 'Revenue')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildPeriodSelector(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildBookingsTab(), _buildRevenueTab()],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_periods.length, (index) {
          final isSelected = index == _selectedPeriodIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(
                _periods[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              selected: isSelected,
              selectedColor: AppConstants.primaryColor,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriodIndex = index;
                  });
                  _loadAnalyticsData();
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBookingsTab() {
    // Sample data for bookings chart
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          const Text(
            'Booking Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBookingsChart(),
          const SizedBox(height: 24),
          const Text(
            'Service Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildServiceDistributionChart(),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    // Sample data for revenue chart
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueSummaryCards(),
          const SizedBox(height: 24),
          const Text(
            'Revenue Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          const Text(
            'Revenue by Service Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRevenueByCategoryChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Bookings',
            value: '158',
            trend: '+12%',
            trendUp: true,
            icon: Icons.book_online,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Completion Rate',
            value: '92%',
            trend: '+5%',
            trendUp: true,
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueSummaryCards() {
    final formatter = NumberFormat.currency(symbol: '₹');
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Revenue',
            value: formatter.format(458500),
            trend: '+8%',
            trendUp: true,
            icon: Icons.payments,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Avg. Order Value',
            value: formatter.format(3200),
            trend: '+3%',
            trendUp: true,
            icon: Icons.shopping_cart,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String trend,
    required bool trendUp,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                  color: trendUp ? Colors.green : Colors.red,
                  size: 16,
                ),
                Text(
                  trend,
                  style: TextStyle(
                    color: trendUp ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' vs last period',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsChart() {
    // Sample data for monthly bookings
    final List<FlSpot> spots = [
      const FlSpot(0, 30),
      const FlSpot(1, 45),
      const FlSpot(2, 40),
      const FlSpot(3, 60),
      const FlSpot(4, 75),
      const FlSpot(5, 65),
      const FlSpot(6, 85),
      const FlSpot(7, 70),
      const FlSpot(8, 85),
      const FlSpot(9, 95),
      const FlSpot(10, 90),
      const FlSpot(11, 105),
    ];

    // X-axis labels for months
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= months.length) {
                    return const Text('');
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      months[value.toInt()],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          minX: 0,
          maxX: 11,
          minY: 0,
          maxY: 120,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withAlpha(51), // 0.2 * 255 = ~51
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDistributionChart() {
    // Sample data for service distribution
    final List<PieChartSectionData> sections = [
      PieChartSectionData(
        value: 40,
        title: '40%',
        color: Colors.blue,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: 25,
        title: '25%',
        color: Colors.green,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: 20,
        title: '20%',
        color: Colors.orange,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: 15,
        title: '15%',
        color: Colors.red,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildServiceLegend('AC Repair', Colors.blue, '40%'),
        _buildServiceLegend('Plumbing', Colors.green, '25%'),
        _buildServiceLegend('Electrical', Colors.orange, '20%'),
        _buildServiceLegend('Other', Colors.red, '15%'),
      ],
    );
  }

  Widget _buildServiceLegend(String title, Color color, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final currencyFormat = NumberFormat.compactCurrency(symbol: '₹');

    // Sample data for monthly revenue
    final List<BarChartGroupData> barGroups = List.generate(12, (index) {
      final double value =
          [
            45000.0,
            65000.0,
            58000.0,
            75000.0,
            90000.0,
            85000.0,
            100000.0,
            92000.0,
            110000.0,
            105000.0,
            120000.0,
            140000.0,
          ][index];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Colors.purple,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });

    // X-axis labels for months
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 150000,
          barGroups: barGroups,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= months.length) {
                    return const Text('');
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      months[value.toInt()],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    currencyFormat.format(value),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueByCategoryChart() {
    final formatter = NumberFormat.currency(symbol: '₹');

    // Sample data for category revenue
    final List<double> data = [240000, 160000, 80000, 53000];
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
    ];
    final List<String> categories = [
      'AC Repair',
      'Plumbing',
      'Electrical',
      'Other',
    ];

    return Column(
      children: [
        for (int i = 0; i < data.length; i++)
          _buildCategoryRevenueItem(
            categories[i],
            formatter.format(data[i]),
            colors[i],
            data[i] / data.reduce((a, b) => a + b),
          ),
      ],
    );
  }

  Widget _buildCategoryRevenueItem(
    String category,
    String revenue,
    Color color,
    double ratio,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                revenue,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
