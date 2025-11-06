import 'package:flutter/material.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class TransporterCallHistoryScreen extends StatefulWidget {
  final String transporterTmid;
  final String transporterName;

  const TransporterCallHistoryScreen({
    Key? key,
    required this.transporterTmid,
    required this.transporterName,
  }) : super(key: key);

  @override
  State<TransporterCallHistoryScreen> createState() => _TransporterCallHistoryScreenState();
}

class _TransporterCallHistoryScreenState extends State<TransporterCallHistoryScreen> {
  List<Map<String, dynamic>> _callHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await Phase2ApiService.getTransporterCallHistory(widget.transporterTmid);
      setState(() {
        _callHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCallRecord(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Call Record'),
        content: const Text('Are you sure you want to delete this call record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Phase2ApiService.deleteJobBrief(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call record deleted successfully')),
        );
        _loadCallHistory();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _editCallRecord(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => _EditCallRecordDialog(
        record: record,
        onSave: () {
          Navigator.pop(context);
          _loadCallHistory();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Call History', style: TextStyle(fontSize: 18)),
            Text(
              widget.transporterName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCallHistory,
          ),
        ],
      ),
      body: _buildBody(),
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
              onPressed: _loadCallHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_callHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No call history found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _callHistory.length,
      itemBuilder: (context, index) {
        final record = _callHistory[index];
        return _CallHistoryCard(
          record: record,
          onEdit: () => _editCallRecord(record),
          onDelete: () => _deleteCallRecord(record['id']),
        );
      },
    );
  }
}

class _CallHistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CallHistoryCard({
    Key? key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(record['createdAt'] ?? '');
    final dateStr = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.phone, color: AppColors.primary),
        ),
        title: Text(
          record['jobTitle'] ?? 'Job Brief',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record['companyName'] != null)
              Text(record['companyName'], style: const TextStyle(fontSize: 12)),
            Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            if (record['callerName'] != null)
              Text(
                'Called by: ${record['callerName']}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              color: AppColors.primary,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
              color: Colors.red,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Name', record['name']),
                _buildDetailRow('Job Location', record['jobLocation']),
                _buildDetailRow('Route', record['route']),
                _buildDetailRow('Vehicle Type', record['vehicleType']),
                _buildDetailRow('License Type', record['licenseType']),
                _buildDetailRow('Experience', record['experience']),
                if (record['salaryFixed'] != null)
                  _buildDetailRow('Fixed Salary', '₹${record['salaryFixed']}'),
                if (record['salaryVariable'] != null)
                  _buildDetailRow('Variable Salary', '₹${record['salaryVariable']}'),
                _buildDetailRow('ESI/PF', record['esiPf']),
                if (record['foodAllowance'] != null)
                  _buildDetailRow('Food Allowance', '₹${record['foodAllowance']}'),
                if (record['tripIncentive'] != null)
                  _buildDetailRow('Trip Incentive', '₹${record['tripIncentive']}'),
                _buildDetailRow('Rehne Ki Suvidha', record['rehneKiSuvidha']),
                _buildDetailRow('Mileage', record['mileage']),
                _buildDetailRow('Fast Tag/Road Kharcha', _formatFastTagValue(record['fastTagRoadKharcha'])),
                _buildDetailRow('Call Status', record['callStatusFeedback']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFastTagValue(dynamic value) {
    if (value == null) return 'Company';
    final strValue = value.toString();
    if (strValue == '0.00' || strValue == '0') return 'Company';
    if (strValue == 'Company' || strValue == 'Driver') return strValue;
    return 'Company';
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditCallRecordDialog extends StatefulWidget {
  final Map<String, dynamic> record;
  final VoidCallback onSave;

  const _EditCallRecordDialog({
    Key? key,
    required this.record,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_EditCallRecordDialog> createState() => _EditCallRecordDialogState();
}

class _EditCallRecordDialogState extends State<_EditCallRecordDialog> {
  late TextEditingController _nameController;
  late TextEditingController _jobLocationController;
  late TextEditingController _routeController;
  late TextEditingController _salaryFixedController;
  late TextEditingController _salaryVariableController;
  late TextEditingController _foodAllowanceController;
  late TextEditingController _tripIncentiveController;
  late TextEditingController _mileageController;
  late TextEditingController _callStatusController;
  
  String _esiPf = 'No';
  String _rehneKiSuvidha = 'No';
  String _fastTagRoadKharcha = 'Company';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.record['name']);
    _jobLocationController = TextEditingController(text: widget.record['jobLocation']);
    _routeController = TextEditingController(text: widget.record['route']);
    _salaryFixedController = TextEditingController(text: widget.record['salaryFixed']?.toString() ?? '');
    _salaryVariableController = TextEditingController(text: widget.record['salaryVariable']?.toString() ?? '');
    _foodAllowanceController = TextEditingController(text: widget.record['foodAllowance']?.toString() ?? '');
    _tripIncentiveController = TextEditingController(text: widget.record['tripIncentive']?.toString() ?? '');
    _mileageController = TextEditingController(text: widget.record['mileage']);
    _callStatusController = TextEditingController(text: widget.record['callStatusFeedback']);
    
    _esiPf = widget.record['esiPf'] ?? 'No';
    _rehneKiSuvidha = widget.record['rehneKiSuvidha'] ?? 'No';
    
    // Handle fastTagRoadKharcha - convert numeric values to proper string
    final fastTagValue = widget.record['fastTagRoadKharcha']?.toString() ?? 'Company';
    if (fastTagValue == '0.00' || fastTagValue == '0') {
      _fastTagRoadKharcha = 'Company';
    } else if (fastTagValue == 'Company' || fastTagValue == 'Driver') {
      _fastTagRoadKharcha = fastTagValue;
    } else {
      _fastTagRoadKharcha = 'Company';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobLocationController.dispose();
    _routeController.dispose();
    _salaryFixedController.dispose();
    _salaryVariableController.dispose();
    _foodAllowanceController.dispose();
    _tripIncentiveController.dispose();
    _mileageController.dispose();
    _callStatusController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      await Phase2ApiService.updateJobBrief(
        id: widget.record['id'],
        name: _nameController.text.trim(),
        jobLocation: _jobLocationController.text.trim(),
        route: _routeController.text.trim(),
        salaryFixed: double.tryParse(_salaryFixedController.text),
        salaryVariable: double.tryParse(_salaryVariableController.text),
        esiPf: _esiPf,
        foodAllowance: double.tryParse(_foodAllowanceController.text),
        tripIncentive: double.tryParse(_tripIncentiveController.text),
        rehneKiSuvidha: _rehneKiSuvidha,
        mileage: _mileageController.text.trim(),
        fastTagRoadKharcha: _fastTagRoadKharcha,
        callStatusFeedback: _callStatusController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call record updated successfully')),
        );
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Call Record'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jobLocationController,
              decoration: const InputDecoration(labelText: 'Job Location'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _routeController,
              decoration: const InputDecoration(labelText: 'Route'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _salaryFixedController,
              decoration: const InputDecoration(labelText: 'Fixed Salary'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _salaryVariableController,
              decoration: const InputDecoration(labelText: 'Variable Salary'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _esiPf,
              decoration: const InputDecoration(labelText: 'ESI/PF'),
              items: ['Yes', 'No'].map((value) {
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
              onChanged: (value) => setState(() => _esiPf = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _foodAllowanceController,
              decoration: const InputDecoration(labelText: 'Food Allowance'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tripIncentiveController,
              decoration: const InputDecoration(labelText: 'Trip Incentive'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _rehneKiSuvidha,
              decoration: const InputDecoration(labelText: 'Rehne Ki Suvidha'),
              items: ['Yes', 'No'].map((value) {
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
              onChanged: (value) => setState(() => _rehneKiSuvidha = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mileageController,
              decoration: const InputDecoration(labelText: 'Mileage'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _fastTagRoadKharcha,
              decoration: const InputDecoration(labelText: 'Fast Tag/Road Kharcha'),
              items: ['Company', 'Driver'].map((value) {
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
              onChanged: (value) => setState(() => _fastTagRoadKharcha = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _callStatusController,
              decoration: const InputDecoration(labelText: 'Call Status Feedback'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
