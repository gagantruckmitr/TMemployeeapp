import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/audio_player_widget.dart';
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
  State<TransporterCallHistoryScreen> createState() =>
      _TransporterCallHistoryScreenState();
}

class _TransporterCallHistoryScreenState
    extends State<TransporterCallHistoryScreen> {
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
      final history = await Phase2ApiService.getTransporterCallHistory(
          widget.transporterTmid);
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
        content:
            const Text('Are you sure you want to delete this call record?'),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditJobBriefModal(
        record: record,
        transporterTmid: widget.transporterTmid,
        onSave: () {
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
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
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
            Text(dateStr,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            if (record['callerName'] != null)
              Text(
                'Called by: ${record['callerName']}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            // Recording indicator
            if (record['callRecording'] != null &&
                record['callRecording'].toString().isNotEmpty)
              Row(
                children: [
                  Icon(Icons.mic, size: 12, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Recording available',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                // Call Status Feedback - Show prominently at top
                if (record['callStatusFeedback'] != null &&
                    record['callStatusFeedback'].toString().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(record['callStatusFeedback'])
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(record['callStatusFeedback'])
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(record['callStatusFeedback']),
                          color: _getStatusColor(record['callStatusFeedback']),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Call Status',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record['callStatusFeedback'].toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(
                                      record['callStatusFeedback']),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Basic Information Section
                _buildSectionHeader('Basic Information'),
                _buildDetailRow('Name', record['name']),
                _buildDetailRow('Job Location', record['jobLocation']),
                _buildDetailRow('Route', record['route']),
                const SizedBox(height: 12),

                // Vehicle & License Section
                _buildSectionHeader('Vehicle & License'),
                _buildDetailRow('Vehicle Type', record['vehicleType']),
                _buildDetailRow('License Type', record['licenseType']),
                _buildDetailRow('Experience', record['experience']),
                const SizedBox(height: 12),

                // Salary Details Section
                if (record['salaryFixed'] != null ||
                    record['salaryVariable'] != null) ...[
                  _buildSectionHeader('Salary Details'),
                  if (record['salaryFixed'] != null)
                    _buildDetailRow(
                        'Fixed Salary', '₹${record['salaryFixed']}'),
                  if (record['salaryVariable'] != null)
                    _buildDetailRow(
                        'Variable Salary', '₹${record['salaryVariable']}'),
                  const SizedBox(height: 12),
                ],

                // Benefits & Allowances Section
                _buildSectionHeader('Benefits & Allowances'),
                _buildDetailRow('ESI/PF', record['esiPf']),
                if (record['foodAllowance'] != null)
                  _buildDetailRow(
                      'Food Allowance', '₹${record['foodAllowance']}'),
                if (record['tripIncentive'] != null)
                  _buildDetailRow(
                      'Trip Incentive', '₹${record['tripIncentive']}'),
                _buildDetailRow('Rehne Ki Suvidha', record['rehneKiSuvidha']),
                const SizedBox(height: 12),

                // Other Details Section
                _buildSectionHeader('Other Details'),
                _buildDetailRow('Mileage', record['mileage']),
                _buildDetailRow('FASTag/Road Kharcha',
                    _formatFastTagValue(record['fastTagRoadKharcha'])),

                // Call Recording Player
                if (record['callRecording'] != null &&
                    record['callRecording'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.audiotrack,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Call Recording',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AudioPlayerWidget(
                    recordingUrl: record['callRecording'].toString(),
                  ),
                ],
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

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('connected') && statusStr.contains('details')) {
      return Colors.green;
    } else if (statusStr.contains('not connected')) {
      return Colors.red;
    } else if (statusStr.contains('hire from other')) {
      return Colors.orange;
    } else if (statusStr.contains('not genuine')) {
      return Colors.red.shade700;
    } else if (statusStr.contains('driver')) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  IconData _getStatusIcon(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('connected') && statusStr.contains('details')) {
      return Icons.check_circle;
    } else if (statusStr.contains('not connected')) {
      return Icons.phone_missed;
    } else if (statusStr.contains('hire from other')) {
      return Icons.info;
    } else if (statusStr.contains('not genuine')) {
      return Icons.warning;
    } else if (statusStr.contains('driver')) {
      return Icons.person;
    }
    return Icons.phone;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty)
      return const SizedBox.shrink();

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

class _EditJobBriefModal extends StatefulWidget {
  final Map<String, dynamic> record;
  final String transporterTmid;
  final VoidCallback onSave;

  const _EditJobBriefModal({
    Key? key,
    required this.record,
    required this.transporterTmid,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_EditJobBriefModal> createState() => _EditJobBriefModalState();
}

class _EditJobBriefModalState extends State<_EditJobBriefModal> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _jobLocationController;
  late TextEditingController _routeController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _licenseTypeController;
  late TextEditingController _experienceController;
  late TextEditingController _salaryFixedController;
  late TextEditingController _salaryVariableController;
  late TextEditingController _foodAllowanceController;
  late TextEditingController _tripIncentiveController;
  late TextEditingController _mileageController;

  String _esiPf = 'No';
  String _rehneKiSuvidha = 'No';
  String _fastTagRoadKharcha = 'Company';
  String _callStatusFeedback = 'Connected: Details Received';

  // Recording upload
  File? _selectedRecordingFile;
  String? _selectedRecordingName;

  // Call status options
  final List<String> _callStatusOptions = [
    'Connected: Details Received',
    'Connected: Not Interested',
    'Connected: Hire from other source',
    'Connected: Not a Genuine Transporter',
    'Connected: He is Driver, mistakenly registered as Transporter',
    'Not Connected: Ringing / Call Busy',
    'Not Connected: Switched Off / Not Reachable',
    'Not Connected: Wrong Number',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.record['name'] ?? '');
    _jobLocationController =
        TextEditingController(text: widget.record['jobLocation'] ?? '');
    _routeController =
        TextEditingController(text: widget.record['route'] ?? '');
    _vehicleTypeController =
        TextEditingController(text: widget.record['vehicleType'] ?? '');
    _licenseTypeController =
        TextEditingController(text: widget.record['licenseType'] ?? '');
    _experienceController =
        TextEditingController(text: widget.record['experience'] ?? '');
    _salaryFixedController = TextEditingController(
        text: widget.record['salaryFixed']?.toString() ?? '');
    _salaryVariableController = TextEditingController(
        text: widget.record['salaryVariable']?.toString() ?? '');
    _foodAllowanceController = TextEditingController(
        text: widget.record['foodAllowance']?.toString() ?? '');
    _tripIncentiveController = TextEditingController(
        text: widget.record['tripIncentive']?.toString() ?? '');
    _mileageController =
        TextEditingController(text: widget.record['mileage'] ?? '');

    _esiPf = widget.record['esiPf'] ?? 'No';
    _rehneKiSuvidha = widget.record['rehneKiSuvidha'] ?? 'No';
    _callStatusFeedback = widget.record['callStatusFeedback'] ?? 
        'Connected: Details Received';

    // Handle fastTagRoadKharcha
    final fastTagValue =
        widget.record['fastTagRoadKharcha']?.toString() ?? 'Company';
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
    _vehicleTypeController.dispose();
    _licenseTypeController.dispose();
    _experienceController.dispose();
    _salaryFixedController.dispose();
    _salaryVariableController.dispose();
    _foodAllowanceController.dispose();
    _tripIncentiveController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _pickRecording() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'wav',
          'm4a',
          'aac',
          'ogg',
          'flac',
          'wma',
          'amr',
          'opus',
          '3gp'
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedRecordingFile = File(result.files.single.path!);
          _selectedRecordingName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String? recordingUrl;

      // First, upload recording if selected
      if (_selectedRecordingFile != null) {
        try {
          final callerId = await Phase2AuthService.getUserId();

          print('=== Recording Upload Debug ===');
          print('Job ID: ${widget.record['jobId']}');
          print('Caller ID: $callerId');
          print('Transporter TMID: ${widget.transporterTmid}');
          print('File path: ${_selectedRecordingFile!.path}');

          var request = http.MultipartRequest(
            'POST',
            Uri.parse(
                'https://truckmitr.com/truckmitr-app/api/phase2_upload_driver_recording_api.php'),
          );

          request.files.add(await http.MultipartFile.fromPath(
            'recording',
            _selectedRecordingFile!.path,
          ));

          request.fields['job_id'] = widget.record['jobId'] ?? '';
          request.fields['caller_id'] = callerId.toString();
          request.fields['transporter_tmid'] = widget.transporterTmid;

          print('Request fields: ${request.fields}');

          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          print('Response status: ${response.statusCode}');
          print('Response body: ${response.body}');

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            print('Response data: $responseData');

            if (responseData['success'] == true) {
              if (responseData['data'] != null &&
                  responseData['data']['url'] != null) {
                recordingUrl = responseData['data']['url'];
                print('Recording URL: $recordingUrl');
              } else {
                print('Warning: Success but no URL in response');
              }
            } else {
              print('Upload failed: ${responseData['message']}');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Recording upload failed: ${responseData['message']}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } else {
            print('HTTP error: ${response.statusCode}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Recording upload failed: HTTP ${response.statusCode}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } catch (e) {
          print('Recording upload exception: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Recording upload error: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Then update job brief
      await Phase2ApiService.updateJobBrief(
        id: widget.record['id'],
        name: _nameController.text.trim(),
        jobLocation: _jobLocationController.text.trim(),
        route: _routeController.text.trim(),
        vehicleType: _vehicleTypeController.text.trim(),
        licenseType: _licenseTypeController.text.trim(),
        experience: _experienceController.text.trim(),
        salaryFixed: _salaryFixedController.text.isEmpty
            ? null
            : double.tryParse(_salaryFixedController.text),
        salaryVariable: _salaryVariableController.text.isEmpty
            ? null
            : double.tryParse(_salaryVariableController.text),
        esiPf: _esiPf,
        foodAllowance: _foodAllowanceController.text.isEmpty
            ? null
            : double.tryParse(_foodAllowanceController.text),
        tripIncentive: _tripIncentiveController.text.isEmpty
            ? null
            : double.tryParse(_tripIncentiveController.text),
        rehneKiSuvidha: _rehneKiSuvidha,
        mileage: _mileageController.text.trim(),
        fastTagRoadKharcha: _fastTagRoadKharcha,
        callStatusFeedback: _callStatusFeedback,
        callRecording: recordingUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(recordingUrl != null
                ? 'Job brief and recording updated successfully'
                : 'Job brief updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSection('Basic Information', [
                    _buildTextField('Name', _nameController, required: true),
                    _buildTextField('Job Location', _jobLocationController),
                    _buildTextField('Route', _routeController, maxLines: 2),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Vehicle & License', [
                    _buildTextField('Vehicle Type', _vehicleTypeController),
                    _buildTextField('License Type', _licenseTypeController),
                    _buildTextField('Experience', _experienceController),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Salary Details', [
                    _buildTextField('Fixed Salary', _salaryFixedController,
                        keyboardType: TextInputType.number, prefix: '₹'),
                    _buildTextField(
                        'Variable Salary', _salaryVariableController,
                        keyboardType: TextInputType.number, prefix: '₹'),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Benefits & Allowances', [
                    _buildDropdown('ESI/PF', _esiPf, ['Yes', 'No'],
                        (val) => setState(() => _esiPf = val!)),
                    _buildTextField('Food Allowance', _foodAllowanceController,
                        keyboardType: TextInputType.number, prefix: '₹'),
                    _buildTextField('Trip Incentive', _tripIncentiveController,
                        keyboardType: TextInputType.number, prefix: '₹'),
                    _buildDropdown(
                        'Rehne Ki Suvidha',
                        _rehneKiSuvidha,
                        ['Yes', 'No'],
                        (val) => setState(() => _rehneKiSuvidha = val!)),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Other Details', [
                    _buildTextField('Mileage', _mileageController),
                    _buildDropdown(
                        'FASTag/Road Kharcha',
                        _fastTagRoadKharcha,
                        ['Company', 'Driver'],
                        (val) => setState(() => _fastTagRoadKharcha = val!)),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Call Status', [
                    _buildDropdown(
                        'Call Status Feedback',
                        _callStatusFeedback,
                        _callStatusOptions,
                        (val) => setState(() => _callStatusFeedback = val!)),
                  ]),
                  const SizedBox(height: 20),
                  _buildRecordingUploadSection(),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Job Brief',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray,
                      ),
                    ),
                    Text(
                      'Job ID: ${widget.record['jobId'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          prefixText: prefix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: required
            ? (value) => value?.isEmpty ?? true ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRecordingUploadSection() {
    final hasExistingRecording = widget.record['callRecording'] != null &&
        widget.record['callRecording'].toString().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Call Recording',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),

        // Show existing recording player if available
        if (hasExistingRecording && _selectedRecordingFile == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Current Recording',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AudioPlayerWidget(
                  recordingUrl: widget.record['callRecording'].toString(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickRecording,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Replace Recording'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Show new recording selection
        if (_selectedRecordingFile != null || !hasExistingRecording) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                if (_selectedRecordingName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.audiotrack,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedRecordingName!,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedRecordingFile = null;
                            _selectedRecordingName = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasExistingRecording
                        ? 'This will replace the existing recording'
                        : 'Recording will be uploaded when you update',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickRecording,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text(hasExistingRecording
                          ? 'Replace Recording'
                          : 'Select Recording File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select transporter call recording (MP3, WAV, M4A, etc.)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _selectedRecordingFile != null
                    ? 'Update & Upload Recording'
                    : 'Update Job Brief',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
