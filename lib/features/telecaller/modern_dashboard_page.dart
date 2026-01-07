// import 'dart:math' as math;
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../../core/services/telecaller_service.dart';
// import '../../core/services/subscription_service.dart';
// import '../../core/services/real_auth_service.dart';

// class ModernDashboardPage extends StatefulWidget {
//   const ModernDashboardPage({super.key});

//   @override
//   State<ModernDashboardPage> createState() => _ModernDashboardPageState();
// }

// class _ModernDashboardPageState extends State<ModernDashboardPage>
//     with TickerProviderStateMixin {
//   late ScrollController _scrollController;
//   late AnimationController _fadeController;
//   late TextEditingController _searchController;
//   double _scrollOffset = 0;
  
//   // Dashboard data
//   Map<String, int> _dashboardStats = {};
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     _searchController = TextEditingController();
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
    
//     _scrollController.addListener(_onScroll);
//     _loadDashboardData();
    
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fadeController.forward();
//     });
//   }

//   void _onScroll() {
//     setState(() {
//       _scrollOffset = _scrollController.offset;
//     });
//   }

//   Future<void> _loadDashboardData() async {
//     setState(() => _isLoading = true);
    
//     try {
//       final stats = await TelecallerService.instance.getDashboardStats(period: 'today');
      
//       if (mounted) {
//         setState(() {
//           _dashboardStats = stats;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error loading data: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _searchController.dispose();
//     _fadeController.dispose();
//     super.dispose();
//   }

//   String _getUserName() {
//     final user = RealAuthService.instance.currentUser;
//     if (user != null) {
//       final nameParts = user.name.split(' ');
//       return nameParts.first;
//     }
//     return 'User';
//   }

//   String _getGreeting() {
//     final hour = DateTime.now().hour;
//     if (hour < 12) return 'Good Morning';
//     if (hour < 17) return 'Good Afternoon';
//     return 'Good Evening';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F7),
//       extendBodyBehindAppBar: true,
//       appBar: _buildModernAppBar(),
//       body: RefreshIndicator(
//         onRefresh: _loadDashboardData,
//         color: Colors.black,
//         child: CustomScrollView(
//           controller: _scrollController,
//           physics: const BouncingScrollPhysics(),
//           slivers: [
//             // Hero Header
//             SliverToBoxAdapter(
//               child: _buildHeroHeader(),
//             ),
            
//             // Search Bar
//             SliverToBoxAdapter(
//               child: _buildSearchBar(),
//             ),
            
//             // Modern KPI Cards
//             SliverToBoxAdapter(
//               child: _buildModernKPISection(),
//             ),
            
//             // Analytics Chart
//             SliverToBoxAdapter(
//               child: _buildAnalyticsChart(),
//             ),
            
//             // Bottom padding
//             const SliverToBoxAdapter(
//               child: SizedBox(height: 100),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildModernAppBar() {
//     final opacity = (_scrollOffset / 100).clamp(0.0, 1.0);
    
//     return AppBar(
//       backgroundColor: Color.lerp(
//         Colors.transparent,
//         const Color(0xFFF5F5F7).withOpacity(0.95),
//         opacity,
//       ),
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
//         color: Colors.black,
//         onPressed: () => Navigator.pop(context),
//       ),
//       title: Opacity(
//         opacity: opacity,
//         child: const Text(
//           'Modern Dashboard',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 17,
//             fontWeight: FontWeight.w600,
//             letterSpacing: -0.3,
//           ),
//         ),
//       ),
//       centerTitle: true,
//       flexibleSpace: ClipRRect(
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Container(color: Colors.transparent),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeroHeader() {
//     return Container(
//       padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 60, 24, 32),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Colors.black,
//             Colors.grey.shade900,
//           ],
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             _getGreeting(),
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.7),
//               fontSize: 15,
//               fontWeight: FontWeight.w500,
//               letterSpacing: 0.5,
//             ),
//           ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
//           const SizedBox(height: 4),
//           Text(
//             _getUserName(),
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 34,
//               fontWeight: FontWeight.w700,
//               letterSpacing: -1,
//               height: 1.1,
//             ),
//           ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(begin: -0.2),
//           const SizedBox(height: 24),
//           _buildQuickStats(),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickStats() {
//     final totalCalls = _dashboardStats['total_calls'] ?? 0;
//     final connectedCalls = _dashboardStats['connected_calls'] ?? 0;
//     final successRate = totalCalls > 0 
//         ? ((connectedCalls / totalCalls) * 100).toStringAsFixed(0)
//         : '0';
    
//     return Row(
//       children: [
//         Expanded(
//           child: _buildQuickStatCard(
//             'Success Rate',
//             '$successRate%',
//             Icons.trending_up_rounded,
//             Colors.green,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _buildQuickStatCard(
//             'Total Calls',
//             totalCalls.toString(),
//             Icons.phone_rounded,
//             Colors.blue,
//           ),
//         ),
//       ],
//     ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.3);
//   }

//   Widget _buildQuickStatCard(String label, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.1),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(height: 12),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 28,
//               fontWeight: FontWeight.w700,
//               letterSpacing: -0.5,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.7),
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 20,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: TextField(
//           controller: _searchController,
//           decoration: InputDecoration(
//             hintText: 'Search here...',
//             hintStyle: TextStyle(
//               color: Colors.grey.shade400,
//               fontSize: 15,
//               fontWeight: FontWeight.w400,
//             ),
//             prefixIcon: Icon(
//               Icons.search_rounded,
//               color: Colors.grey.shade600,
//               size: 22,
//             ),
//             suffixIcon: _searchController.text.isNotEmpty
//                 ? IconButton(
//                     icon: Icon(
//                       Icons.clear_rounded,
//                       color: Colors.grey.shade600,
//                       size: 20,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _searchController.clear();
//                       });
//                     },
//                   )
//                 : null,
//             border: InputBorder.none,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 20,
//               vertical: 16,
//             ),
//           ),
//           style: const TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.w500,
//           ),
//           onChanged: (value) {
//             setState(() {});
//           },
//         ),
//       ),
//     ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.2);
//   }

//   Widget _buildModernKPISection() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Performance Metrics',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.w700,
//               letterSpacing: -0.5,
//             ),
//           ),
//           const SizedBox(height: 20),
          
//           // Row 1: Today Fresh Leads & Today Connected
//           Row(
//             children: [
//               Expanded(
//                 child: _buildModernKPICard(
//                   title: 'Today Fresh Leads',
//                   value: (_dashboardStats['fresh_leads'] ?? 0).toString(),
//                   icon: '🆕',
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                   ),
//                   delay: 0,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildModernKPICard(
//                   title: 'Today Connected',
//                   value: (_dashboardStats['connected_calls'] ?? 0).toString(),
//                   icon: '✅',
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
//                   ),
//                   delay: 100,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
          
//           // Row 2: Today Not Connected & Today Call Back
//           Row(
//             children: [
//               Expanded(
//                 child: _buildModernKPICard(
//                   title: 'Today Not Connected',
//                   value: (_dashboardStats['not_connected_calls'] ?? 0).toString(),
//                   icon: '❌',
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFFEB3349), Color(0xFFF45C43)],
//                   ),
//                   delay: 200,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildModernKPICard(
//                   title: 'Today Call Back',
//                   value: (_dashboardStats['callbacks_scheduled'] ?? 0).toString(),
//                   icon: '🔔',
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
//                   ),
//                   delay: 300,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
          
//           // Row 3: Back Log (Full Width)
//           _buildModernKPICard(
//             title: 'Back Log',
//             value: (_dashboardStats['pending_calls'] ?? 0).toString(),
//             icon: '📋',
//             gradient: const LinearGradient(
//               colors: [Color(0xFF4E54C8), Color(0xFF8F94FB)],
//             ),
//             delay: 400,
//             isFullWidth: true,
//           ),
          
//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildModernKPICard({
//     required String title,
//     required String value,
//     required String icon,
//     required Gradient gradient,
//     required int delay,
//     bool isFullWidth = false,
//   }) {
//     return Container(
//       padding: EdgeInsets.all(isFullWidth ? 24 : 20),
//       decoration: BoxDecoration(
//         gradient: gradient,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: isFullWidth
//           ? Row(
//               children: [
//                 Text(icon, style: const TextStyle(fontSize: 40)),
//                 const SizedBox(width: 20),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.9),
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         value,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 36,
//                           fontWeight: FontWeight.w700,
//                           letterSpacing: -1,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             )
//           : Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(icon, style: const TextStyle(fontSize: 32)),
//                 const SizedBox(height: 16),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 32,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: -1,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.9),
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: 0.3,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//     ).animate().fadeIn(duration: 600.ms, delay: Duration(milliseconds: 800 + delay))
//         .slideY(begin: 0.3);
//   }

//   Widget _buildAnalyticsChart() {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 20,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Call Analytics',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: -0.5,
//               ),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               height: 200,
//               child: _buildModernChart(),
//             ),
//           ],
//         ),
//       ),
//     ).animate().fadeIn(duration: 600.ms, delay: 1400.ms).slideY(begin: 0.3);
//   }

//   Widget _buildModernChart() {
//     final totalCalls = (_dashboardStats['total_calls'] ?? 0).toDouble();
//     final connectedCalls = (_dashboardStats['connected_calls'] ?? 0).toDouble();
//     final notConnectedCalls = (_dashboardStats['not_connected_calls'] ?? 0).toDouble();
//     final callbacks = (_dashboardStats['callbacks_scheduled'] ?? 0).toDouble();
    
//     final maxValue = [totalCalls, connectedCalls, notConnectedCalls, callbacks]
//         .reduce(math.max);
//     final maxY = maxValue > 0 ? (maxValue * 1.2).ceilToDouble() : 10.0;

//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         maxY: maxY,
//         minY: 0,
//         barTouchData: BarTouchData(
//           enabled: true,
//           touchTooltipData: BarTouchTooltipData(
//             getTooltipColor: (group) => Colors.black.withOpacity(0.8),
//             tooltipPadding: const EdgeInsets.all(8),
//             tooltipRoundedRadius: 8,
//             getTooltipItem: (group, groupIndex, rod, rodIndex) {
//               const labels = ['Total', 'Connected', 'Not Connected', 'Callbacks'];
//               return BarTooltipItem(
//                 '${labels[group.x.toInt()]}\n${rod.toY.round()}',
//                 const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 12,
//                 ),
//               );
//             },
//           ),
//         ),
//         titlesData: FlTitlesData(
//           show: true,
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               getTitlesWidget: (value, meta) {
//                 const labels = ['Total', 'Connected', 'Not Conn.', 'Callbacks'];
//                 if (value.toInt() < labels.length) {
//                   return Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       labels[value.toInt()],
//                       style: const TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   );
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//           ),
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 40,
//               getTitlesWidget: (value, meta) {
//                 return Text(
//                   value.toInt().toString(),
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: Colors.grey.shade600,
//                   ),
//                 );
//               },
//             ),
//           ),
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         borderData: FlBorderData(show: false),
//         gridData: FlGridData(
//           show: true,
//           drawVerticalLine: false,
//           horizontalInterval: maxY / 5,
//           getDrawingHorizontalLine: (value) {
//             return FlLine(
//               color: Colors.grey.shade200,
//               strokeWidth: 1,
//             );
//           },
//         ),
//         barGroups: [
//           _buildBarGroup(0, totalCalls, const Color(0xFF667EEA)),
//           _buildBarGroup(1, connectedCalls, const Color(0xFF11998E)),
//           _buildBarGroup(2, notConnectedCalls, const Color(0xFFEB3349)),
//           _buildBarGroup(3, callbacks, const Color(0xFFF093FB)),
//         ],
//       ),
//     );
//   }

//   BarChartGroupData _buildBarGroup(int x, double y, Color color) {
//     return BarChartGroupData(
//       x: x,
//       barRods: [
//         BarChartRodData(
//           toY: y,
//           color: color,
//           width: 20,
//           borderRadius: const BorderRadius.only(
//             topLeft: Radius.circular(6),
//             topRight: Radius.circular(6),
//           ),
//         ),
//       ],
//     );
//   }
// }
