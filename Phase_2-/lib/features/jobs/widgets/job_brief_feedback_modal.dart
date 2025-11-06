import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../models/job_model.dart';
import '../../../core/services/phase2_api_service.dart';
import '../../../core/services/phase2_auth_service.dart';

void showJobBriefFeedbackModal({
  required BuildContext context,
  required JobModel job,
  VoidCallback? onSubmit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => JobBriefFeedbackModal(
      job: job,
      onSubmit: onSubmit,
    ),
  );
}

class JobBriefFeedbackModal extends StatefulWidget {
  final JobModel job;
  final VoidCallback? onSubmit;

  const JobBriefFeedbackModal({
    super.key,
    required this.job,
    this.onSubmit,
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

  String _esiPf = 'No';
  String _rehneKiSuvidha = 'No';
  String _fastTagRoadKharcha = 'Company';

  // Recording upload
  File? _selectedRecordingFile;
  String? _selectedRecordingName;
  bool _isUploadingRecording = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with job data
    _nameController.text = widget.job.transporterName;
    _jobLocationController.text = widget.job.jobLocation;
    _vehicleTypeController.text = widget.job.vehicleType;
    _licenseTypeController.text = widget.job.typeOfLicense;
    _experienceController.text = widget.job.requiredExperience;
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

  Future<void> _uploadRecording() async {
    if (_selectedRecordingFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a recording file first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isUploadingRecording = true);

    try {
      final callerId = await Phase2AuthService.getUserId();

      print('=== TRANSPORTER RECORDING UPLOAD ===');
      print('Uploading recording: ${_selectedRecordingFile!.path}');
      print('Job ID: ${widget.job.jobId}');
      print('Caller ID: $callerId');
      print('Transporter TMID: ${widget.job.transporterTmid}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://truckmitr.com/truckmitr-app/api/phase2_upload_transporter_recording_api_debug.php'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'recording',
        _selectedRecordingFile!.path,
      ));

      request.fields['job_id'] = widget.job.jobId;
      request.fields['caller_id'] = callerId.toString();
      request.fields['transporter_tmid'] = widget.job.transporterTmid;

      print('Sending request...');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = response.body;
        if (responseData.contains('success')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recording uploaded successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            setState(() {
              _selectedRecordingFile = null;
              _selectedRecordingName = null;
            });
          }
        } else {
          throw Exception('Server returned error: $responseData');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingRecording = false);
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
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
        callStatusFeedback:
            'Connected: Details Received', // Auto-set since this form only opens for Details Received
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job brief saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSubmit?.call();
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingRecording ? null : _uploadRecording,
                    icon: _isUploadingRecording
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cloud_upload, size: 18),
                    label: Text(_isUploadingRecording
                        ? 'Uploading...'
                        : 'Upload Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
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
                  'Upload transporter call recording (MP3, WAV, M4A, etc.)',
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
