import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/services/phase2_auth_service.dart';

class CallFeedbackModal extends StatefulWidget {
  final String userType; // 'transporter' or 'driver'
  final String userName;
  final String userTmid;
  final String? transporterTmid;
  final String? jobId;
  final Function(String feedback, String matchStatus, String notes) onSubmit;

  const CallFeedbackModal({
    super.key,
    required this.userType,
    required this.userName,
    required this.userTmid,
    this.transporterTmid,
    this.jobId,
    required this.onSubmit,
  });

  @override
  State<CallFeedbackModal> createState() => _CallFeedbackModalState();
}

class _CallFeedbackModalState extends State<CallFeedbackModal> {
  String? _selectedFeedback;
  String? _selectedMatchStatus;
  final TextEditingController _notesController = TextEditingController();
  File? _selectedRecordingFile;
  String? _selectedRecordingName;
  bool _isUploadingRecording = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickRecording() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'wma', 'amr', 'opus', '3gp'],
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
    if (_selectedRecordingFile == null || widget.jobId == null) {
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

      print('Uploading recording: ${_selectedRecordingFile!.path}');
      print('Job ID: ${widget.jobId}');
      print('Caller ID: $callerId');
      print('Driver TMID: ${widget.userTmid}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://truckmitr.com/truckmitr-app/api/phase2_upload_driver_recording_api_debug.php'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'recording',
        _selectedRecordingFile!.path,
      ));

      request.fields['job_id'] = widget.jobId!;
      request.fields['caller_id'] = callerId.toString();
      request.fields['driver_tmid'] = widget.userTmid;

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
    } catch (e, stackTrace) {
      print('Upload error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingRecording = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Call Feedback',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      Text(
                        '${widget.userName} • ${widget.userTmid}',
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
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    '1. Connected',
                    Icons.check_circle_outline,
                    Colors.green,
                    [
                      'Interview Done',
                      'Not Selected',
                      'Will Confirm Later',
                      'Match Making Done',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    '2. Call Back',
                    Icons.phone_callback_outlined,
                    Colors.orange,
                    [
                      'Ringing',
                      'Call Busy',
                      'Switched Off',
                      'Not Reachable',
                      'Disconnected',
                      'Didn\'t Pick',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    '3. Call Back Later',
                    Icons.schedule_outlined,
                    Colors.blue,
                    [
                      'Busy Right Now',
                      'Call Tomorrow Morning',
                      'Call in Evening',
                      'Call After 2 Days',
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '4. Match Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMatchStatusChip('Selected'),
                      _buildMatchStatusChip('Not Selected'),
                      _buildMatchStatusChip('Pending'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '5. Additional Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter any remarks or follow-up details...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.userType == 'driver' && widget.jobId != null) ...[
                    const Text(
                      'Call Recording (Optional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
                                onPressed: _isUploadingRecording
                                    ? null
                                    : _uploadRecording,
                                icon: _isUploadingRecording
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.cloud_upload, size: 18),
                                label: Text(_isUploadingRecording
                                    ? 'Uploading...'
                                    : 'Upload Recording'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              onPressed: _pickRecording,
                              icon: const Icon(Icons.attach_file, size: 18),
                              label: const Text('Select Recording File'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side:
                                    const BorderSide(color: AppColors.primary),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select audio file from your device storage',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedFeedback != null
                          ? () {
                              widget.onSubmit(
                                _selectedFeedback!,
                                _selectedMatchStatus ?? '',
                                _notesController.text,
                              );
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((option) => _buildFeedbackChip(option, color))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFeedbackChip(String label, Color color) {
    final isSelected = _selectedFeedback == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeedback = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchStatusChip(String label) {
    final isSelected = _selectedMatchStatus == label;
    final color = label == 'Selected'
        ? Colors.green
        : label == 'Not Selected'
            ? Colors.red
            : Colors.orange;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMatchStatus = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
