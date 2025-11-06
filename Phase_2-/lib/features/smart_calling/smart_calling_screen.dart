import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/dummy_data.dart';
import 'widgets/driver_card.dart';
import 'widgets/transporter_job_card.dart';
import 'widgets/call_bar.dart';

class SmartCallingScreen extends StatefulWidget {
  const SmartCallingScreen({super.key});

  @override
  State<SmartCallingScreen> createState() => _SmartCallingScreenState();
}

class _SmartCallingScreenState extends State<SmartCallingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCallActive = false;
  String? _activeCallName;

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

  void _handleCall(String name, String phone) {
    setState(() {
      _isCallActive = true;
      _activeCallName = name;
    });

    // Simulate call duration
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isCallActive = false;
          _activeCallName = null;
        });
        _showFeedbackDialog();
      }
    });
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Call Feedback', style: TextStyle(color: AppColors.darkGray)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Add notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Calling'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.slateBlue,
          labelColor: AppColors.slateBlue,
          unselectedLabelColor: AppColors.softGray,
          tabs: const [
            Tab(text: 'Driver View'),
            Tab(text: 'Transporter View'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildDriverView(),
              _buildTransporterView(),
            ],
          ),
          
          // Call Bar
          if (_isCallActive)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CallBar(
                callerName: _activeCallName ?? '',
                onEndCall: () {
                  setState(() {
                    _isCallActive = false;
                    _activeCallName = null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: DummyData.drivers.length,
      itemBuilder: (context, index) {
        final driver = DummyData.drivers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DriverCard(
            driver: driver,
            onCall: () => _handleCall(driver['name'], driver['phone']),
          ),
        );
      },
    );
  }

  Widget _buildTransporterView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: DummyData.transporters.length,
      itemBuilder: (context, index) {
        final transporter = DummyData.transporters[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TransporterJobCard(
            transporter: transporter,
            onCall: () => _handleCall(transporter['name'], transporter['phone']),
          ),
        );
      },
    );
  }
}
