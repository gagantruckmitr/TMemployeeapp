import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme/app_colors.dart';

class ProfileCompletionDetailsScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userType;

  const ProfileCompletionDetailsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userType,
  });

  @override
  State<ProfileCompletionDetailsScreen> createState() => _ProfileCompletionDetailsScreenState();
}

class _ProfileCompletionDetailsScreenState extends State<ProfileCompletionDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadProfileCompletion();
  }

  Future<void> _loadProfileCompletion() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://truckmitr.com/truckmitr-app/api/phase2_profile_completion_api.php?user_id=${widget.userId}&user_type=${widget.userType}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _profileData = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load profile';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      appBar: AppBar(
        title: Text(
          '${widget.userName} - Profile',
          style: const TextStyle(color: AppColors.darkGray),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBeige),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildErrorView()
              : _buildProfileView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfileCompletion,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    final percentage = _profileData!['percentage'] as int;
    final filledFields = _profileData!['filledFields'] as int;
    final totalFields = _profileData!['totalFields'] as int;
    final completion = _profileData!['completion'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mediumBeige),
            ),
            child: Column(
              children: [
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getCompletionColor(percentage),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Profile Completion',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: AppColors.lightBeige,
                  valueColor: AlwaysStoppedAnimation(_getCompletionColor(percentage)),
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Text(
                  '$filledFields of $totalFields fields completed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Field Categories
          ...completion.entries.map((entry) {
            return _buildCategorySection(entry.key, entry.value as List);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, List fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.mediumBeige),
          ),
          child: Column(
            children: fields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value as Map<String, dynamic>;
              final isLast = index == fields.length - 1;
              
              return Column(
                children: [
                  _buildFieldRow(field),
                  if (!isLast) Divider(color: AppColors.mediumBeige, height: 1),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFieldRow(Map<String, dynamic> field) {
    final label = field['label'] as String;
    final status = field['status'] as String;
    final value = field['value'];
    final isComplete = status == 'complete';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.cancel,
            color: isComplete ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                if (isComplete && value != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    value.toString().length > 50
                        ? '${value.toString().substring(0, 50)}...'
                        : value.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (!isComplete) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Missing',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}
