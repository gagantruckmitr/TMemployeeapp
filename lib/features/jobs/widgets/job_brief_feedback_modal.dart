import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/job_model.dart';
import '../../../core/services/phase2_api_service.dart';
import '../../../core/services/phase2_auth_service.dart';

import '../../../core/services/manual_call_service.dart';

void showJobBriefFeedbackModal({
  required BuildContext context,
  required JobModel job,
  String? jobBriefId,
  VoidCallback? onSubmit,
  bool hideCallStatusFields = false,
  String? preSelectedCallStatus,
  String? preSelectedCallFeedback,
  String? preSelectedRemarks,
  bool isManualCall = false,
}) {
  print('🔵 showJobBriefFeedbackModal called');
  print('🔵 Job ID: ${job.jobId}');
  print('🔵 Job Brief ID: $jobBriefId');
  print('🔵 Is Manual Call: $isManualCall');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return PopScope(
        canPop: false,
        child: JobBriefFeedbackModal(
          job: job,
          jobBriefId: jobBriefId,
          onSubmit: onSubmit,
          hideCallStatusFields: hideCallStatusFields,
          preSelectedCallStatus: preSelectedCallStatus,
          preSelectedCallFeedback: preSelectedCallFeedback,
          preSelectedRemarks: preSelectedRemarks,
          isManualCall: isManualCall,
        ),
      );
    },
  );
}

class JobBriefFeedbackModal extends StatefulWidget {
  final JobModel job;
  final String? jobBriefId;
  final VoidCallback? onSubmit;
  final bool hideCallStatusFields;
  final String? preSelectedCallStatus;
  final String? preSelectedCallFeedback;
  final String? preSelectedRemarks;
  final bool isManualCall;

  const JobBriefFeedbackModal({
    super.key,
    required this.job,
    this.jobBriefId,
    this.onSubmit,
    this.hideCallStatusFields = false,
    this.preSelectedCallStatus,
    this.preSelectedCallFeedback,
    this.preSelectedRemarks,
    this.isManualCall = false,
  });

  @override
  State<JobBriefFeedbackModal> createState() => _JobBriefFeedbackModalState();
}

class _JobBriefFeedbackModalState extends State<JobBriefFeedbackModal> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Controllers
  final _nameController = TextEditingController();
  final _jobLocationController = TextEditingController();
  final _routeController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _licenseTypeController = TextEditingController();
  final _experienceController = TextEditingController();
  final _salaryFixedController = TextEditingController();
  final _salaryVariableController = TextEditingController();
  final _foodAllowanceController = TextEditingController();
  final _tripIncentiveController = TextEditingController();
  final _mileageController = TextEditingController();
  final _requiredDriversController = TextEditingController();

  String _esiPf = 'Yes';
  String _rehneKiSuvidha = 'No';
  String _fastTagRoadKharcha = 'Company';
  String _callStatus = 'connected';
  String _callFeedback = 'Match Making Done';
  final _callRemarksController = TextEditingController();

  // Call status options
  final List<String> _callStatusOptions = [
    'connected',
    'not_connected',
    'callback_later',
  ];

  // Call feedback options
  final Map<String, List<String>> _callFeedbackOptions = {
    'connected': [
      'Match Making Done',
      'Details Received',
      'Not Interested',
      'Hire from other source',
      'Not a Genuine Transporter',
      'He is Driver, mistakenly registered as Transporter',
      'Hired from TruckMitr',
      'Close Job',
    ],
    'not_connected': [
      'Ringing / Call Busy',
      'Switched Off / Not Reachable',
      'Wrong Number',
    ],
    'callback_later': [
      'Busy Right Now',
      'Call Tomorrow Morning',
      'Call in Evening',
      'Call After 2 Days',
    ],
  };

  File? _selectedRecordingFile;
  String? _selectedRecordingName;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.job.transporterName;
    _jobLocationController.text = widget.job.jobLocation;
    _vehicleTypeController.text = widget.job.vehicleType;
    _licenseTypeController.text = widget.job.typeOfLicense;
    _experienceController.text = widget.job.requiredExperience;

    if (widget.preSelectedCallStatus != null) {
      _callStatus = widget.preSelectedCallStatus!;
    }
    if (widget.preSelectedCallFeedback != null) {
      _callFeedback = widget.preSelectedCallFeedback!;
    }
    if (widget.preSelectedRemarks != null &&
        widget.preSelectedRemarks!.isNotEmpty) {
      _callRemarksController.text = widget.preSelectedRemarks!;
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
    _requiredDriversController.dispose();
    _callRemarksController.dispose();
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
          '3gp',
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

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String? recordingUrl;

      // Upload recording if present (legacy flow or manual flow fallback)
      if (_selectedRecordingFile != null && !widget.isManualCall) {
        // ... existing upload logic omitted for brevity, keeping manual flow logic separate ...
        try {
          final callerId = await Phase2AuthService.getUserId();
          var request = http.MultipartRequest(
            'POST',
            Uri.parse(
              '${ApiConfig.baseUrl}/phase2_upload_transporter_recording_api.php',
            ),
          );
          request.files.add(
            await http.MultipartFile.fromPath(
              'recording',
              _selectedRecordingFile!.path,
            ),
          );
          request.fields['job_id'] = widget.job.jobId;
          request.fields['caller_id'] = callerId.toString();
          request.fields['transporter_tmid'] = widget.job.transporterTmid;
          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);
          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            if (responseData['success'] == true &&
                responseData['data'] != null) {
              recordingUrl = responseData['data']['url'];
            }
          }
        } catch (e) {
          print('Recording upload failed: $e');
        }
      }

      String? successMessage;

      if (widget.isManualCall && widget.jobBriefId != null) {
        // Use Manual Call Service
        final result = await ManualCallService.updateJobBriefCall(
          id: int.tryParse(widget.jobBriefId!) ?? 0,
          name: _nameController.text,
          jobLocation: _jobLocationController.text,
          route: _routeController.text,
          vehicleType: _vehicleTypeController.text,
          licenseType: _licenseTypeController.text,
          experience: _experienceController.text,
          salaryFixed: _salaryFixedController.text,
          salaryVariable: _salaryVariableController.text.isEmpty
              ? '0'
              : _salaryVariableController.text,
          esiPf: _esiPf.toLowerCase(),
          foodAllowance: int.tryParse(_foodAllowanceController.text) ?? 0,
          tripIncentive: int.tryParse(_tripIncentiveController.text) ?? 0,
          rehneKiSuvidha: _rehneKiSuvidha.toLowerCase(),
          mileage: _mileageController.text,
          fastTagRoadKharcha: _fastTagRoadKharcha == 'Company'
              ? 0
              : 1, // API expects int?
          closedJob: 0,
          callStatus: _callStatus == 'Connected'
              ? 'connected'
              : _callStatus, // normalize
          callFeedback: _callFeedback,
          callRemarks: _callRemarksController.text,
          requiredDrivers: _requiredDriversController.text,
          callRecording:
              _selectedRecordingFile, // Manual service handles file directly
        );

        if (result['success'] == true || result['status'] == 'success') {
          successMessage = 'Manual call job brief updated successfully';
        } else {
          throw Exception(result['error'] ?? 'Unknown error');
        }
      } else if (widget.jobBriefId != null && widget.jobBriefId!.isNotEmpty) {
        final response = await Phase2ApiService.updateIVRCallJobBriefFeedback(
          jobBriefId: widget.jobBriefId!,
          name: _nameController.text,
          jobLocation: _jobLocationController.text,
          route: _routeController.text,
          vehicleType: _vehicleTypeController.text,
          licenseType: _licenseTypeController.text,
          experience: _experienceController.text,
          salaryFixed: _salaryFixedController.text,
          salaryVariable: _salaryVariableController.text,
          esiPf: _esiPf.toLowerCase(),
          foodAllowance: _foodAllowanceController.text,
          tripIncentive: _tripIncentiveController.text,
          rehneKiSuvidha: _rehneKiSuvidha.toLowerCase(),
          mileage: _mileageController.text,
          fastTagRoadKharcha: _fastTagRoadKharcha == 'Company' ? '0' : '1',
          closedJob: '0',
          callStatus: _callStatus,
          callFeedback: _callFeedback,
          callRecording: recordingUrl,
          callRemarks: _callRemarksController.text,
          requiredDrivers: _requiredDriversController.text,
        );
        successMessage =
            response['message'] ?? 'Job brief updated successfully';
      } else {
        // Then save job brief with recording URL (legacy method)
        await Phase2ApiService.saveJobBrief(
          uniqueId: widget.job.transporterTmid,
          jobId: widget.job.jobId,
          name: _nameController.text,
          jobLocation: _jobLocationController.text,
          route: _routeController.text,
          vehicleType: _vehicleTypeController.text,
          licenseType: _licenseTypeController.text,
          experience: _experienceController.text,
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
          mileage: _mileageController.text,
          fastTagRoadKharcha: _fastTagRoadKharcha,
          callStatusFeedback: '$_callStatus: $_callFeedback',
          callRecording: recordingUrl,
          requiredDrivers: _requiredDriversController.text,
        );
        successMessage = 'Job brief saved successfully';
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage ?? 'Job brief updated successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onSubmit?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                    _buildTextField(
                      'Required Drivers',
                      _requiredDriversController,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Vehicle & License', [
                    _buildTextField('Vehicle Type', _vehicleTypeController),
                    _buildTextField('License Type', _licenseTypeController),
                    _buildTextField('Experience', _experienceController),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Salary Details', [
                    _buildTextField(
                      'Fixed Salary',
                      _salaryFixedController,
                      keyboardType: TextInputType.number,
                      prefix: '₹',
                    ),
                    _buildTextField(
                      'Variable Salary',
                      _salaryVariableController,
                      keyboardType: TextInputType.number,
                      prefix: '₹',
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Benefits & Allowances', [
                    _buildDropdown('ESI/PF', _esiPf, [
                      'Yes',
                      'No',
                    ], (val) => setState(() => _esiPf = val!)),
                    _buildTextField(
                      'Food Allowance',
                      _foodAllowanceController,
                      keyboardType: TextInputType.number,
                      prefix: '₹',
                    ),
                    _buildTextField(
                      'Trip Incentive',
                      _tripIncentiveController,
                      keyboardType: TextInputType.number,
                      prefix: '₹',
                    ),
                    _buildDropdown(
                      'Rehne Ki Suvidha',
                      _rehneKiSuvidha,
                      ['Yes', 'No'],
                      (val) => setState(() => _rehneKiSuvidha = val!),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Other Details', [
                    _buildTextField('Mileage', _mileageController),
                    _buildDropdown(
                      'FASTag/Road Kharcha',
                      _fastTagRoadKharcha,
                      ['Company', 'Driver'],
                      (val) => setState(() => _fastTagRoadKharcha = val!),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  // Only show call status fields if not hidden
                  if (!widget.hideCallStatusFields) ...[
                    _buildSection('Call Status & Feedback', [
                      _buildDropdown(
                        'Call Status',
                        _callStatus,
                        _callStatusOptions,
                        (val) => setState(() {
                          _callStatus = val!;
                          // Reset feedback when status changes
                          _callFeedback = _callFeedbackOptions[val]!.first;
                        }),
                      ),
                      _buildDropdown(
                        'Call Feedback',
                        _callFeedback,
                        _callFeedbackOptions[_callStatus]!,
                        (val) => setState(() => _callFeedback = val!),
                      ),
                      _buildTextField(
                        'Call Remarks',
                        _callRemarksController,
                        maxLines: 2,
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],
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
                child: const Icon(Icons.assignment, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Job Brief Feedback',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray,
                      ),
                    ),
                    Text(
                      'Job ID: ${widget.job.jobId}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Required feedback indicator (no close button)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Call Recording (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
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
                    const Icon(
                      Icons.audiotrack,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
                  'Recording will be uploaded when you submit the form',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickRecording,
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: const Text('Select Recording File'),
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
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
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
            : const Text(
                'Submit Feedback',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
