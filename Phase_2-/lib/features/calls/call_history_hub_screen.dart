import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import 'transporter_call_history_screen.dart';
import 'call_history_screen.dart';

class CallHistoryHubScreen extends StatefulWidget {
  const CallHistoryHubScreen({Key? key}) : super(key: key);

  @override
  State<CallHistoryHubScreen> createState() => _CallHistoryHubScreenState();
}

class _CallHistoryHubScreenState extends State<CallHistoryHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 48,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'My Calls', icon: Icon(Icons.phone_callback, size: 20)),
              Tab(
                  text: 'Transporters',
                  icon: Icon(Icons.local_shipping, size: 20)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CallHistoryScreen(),
          TransporterListScreen(),
        ],
      ),
    );
  }
}

class TransporterListScreen extends StatefulWidget {
  const TransporterListScreen({Key? key}) : super(key: key);

  @override
  State<TransporterListScreen> createState() => _TransporterListScreenState();
}

class _TransporterListScreenState extends State<TransporterListScreen> {
  List<Map<String, dynamic>> _transporters = [];
  List<Map<String, dynamic>> _filteredTransporters = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransporters();
    _searchController.addListener(_filterTransporters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransporters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch transporters with call history
      final transporters =
          await Phase2ApiService.getTransportersWithCallHistory();

      setState(() {
        _transporters = transporters;
        _filteredTransporters = _transporters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTransporters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTransporters = _transporters;
      } else {
        _filteredTransporters = _transporters.where((t) {
          final name = t['name']?.toString().toLowerCase() ?? '';
          final tmid = t['tmid']?.toString().toLowerCase() ?? '';
          final company = t['company']?.toString().toLowerCase() ?? '';
          return name.contains(query) ||
              tmid.contains(query) ||
              company.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search transporters...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),

        // Transporter list
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransporters,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredTransporters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty
                  ? Icons.local_shipping
                  : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No transporters found'
                  : 'No results for "${_searchController.text}"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransporters,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTransporters.length,
        itemBuilder: (context, index) {
          final transporter = _filteredTransporters[index];
          return _TransporterCard(
            transporter: transporter,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransporterCallHistoryScreen(
                    transporterTmid: transporter['tmid'],
                    transporterName: transporter['name'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TransporterCard extends StatelessWidget {
  final Map<String, dynamic> transporter;
  final VoidCallback onTap;

  const _TransporterCard({
    Key? key,
    required this.transporter,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final callCount = transporter['callCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon with badge
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  if (callCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          callCount > 99 ? '99+' : callCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transporter['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (transporter['company'] != null)
                      Text(
                        transporter['company'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      transporter['tmid'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$callCount call${callCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.softGray,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
