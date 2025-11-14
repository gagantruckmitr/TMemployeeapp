import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme/app_colors.dart';
import '../widgets/progress_ring_avatar.dart';

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
  State<ProfileCompletionDetailsScreen> createState() =>
      _ProfileCompletionDetailsScreenState();
}

class _ProfileCompletionDetailsScreenState
    extends State<ProfileCompletionDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String _error = '';
  int _selectedTabIndex = 0;
  List<String> _tabCategories = [];

  @override
  void initState() {
    super.initState();
    _loadProfileCompletion();
  }

  String? _profileImageUrl;

  Future<void> _loadProfileCompletion() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final url = 'https://truckmitr.com/truckmitr-app/api/phase2_profile_completion_api.php?user_id=${widget.userId}&user_type=${widget.userType}';
      print('=== PROFILE COMPLETION API CALL ===');
      print('URL: $url');
      print('user_id: ${widget.userId}');
      print('user_type: ${widget.userType}');
      
      final response = await http.get(Uri.parse(url));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('===================================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final completion = data['data']['completion'] as Map<String, dynamic>;
          setState(() {
            _profileData = data['data'];
            _profileImageUrl = data['data']['profileImageUrl'];
            _tabCategories = completion.keys.toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load profile';
            _isLoading = false;
          });
        }
      } else {
        // Try to get error message from response body
        String errorMsg = 'Server error: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMsg = errorData['message'];
          }
          // Add debug info if available
          if (errorData['received_user_id'] != null) {
            errorMsg += '\nReceived user_id: ${errorData['received_user_id']}';
          }
        } catch (e) {
          // If can't parse, use default error
        }
        setState(() {
          _error = errorMsg;
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

    return Column(
      children: [
        // Profile Avatar Header - Clean & Minimal
        _buildAvatarHeader(percentage, filledFields, totalFields),

        // Horizontal Scrollable Tabs
        Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: _tabCategories.length,
            itemBuilder: (context, index) {
              final category = _tabCategories[index];
              final isSelected = index == _selectedTabIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      _formatCategoryName(category),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Selected Category Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSelectedCategoryContent(completion),
          ),
        ),
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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              widget.userName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCategoryName(String category) {
    // Convert category names to more readable format
    switch (category.toLowerCase()) {
      case 'basic info':
      case 'basicinfo':
      case 'basic_info':
        return 'Basic Info';
      case 'professional':
      case 'professional details':
        return 'Professional';
      case 'income':
      case 'income details':
        return 'Income';
      case 'documents':
      case 'upload documents':
        return 'Documents';
      case 'driving':
      case 'driving details':
        return 'Driving';
      case 'vehicle':
      case 'vehicle details':
        return 'Vehicle';
      case 'personal':
      case 'personal details':
        return 'Personal';
      default:
        return category;
    }
  }

  Widget _buildSelectedCategoryContent(Map<String, dynamic> completion) {
    if (_tabCategories.isEmpty || _selectedTabIndex >= _tabCategories.length) {
      return const Center(child: Text('No data available'));
    }

    final selectedCategory = _tabCategories[_selectedTabIndex];
    final fields = completion[selectedCategory] as List;

    return Container(
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
              if (!isLast)
                const Divider(color: AppColors.mediumBeige, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvatarHeader(int percentage, int filledFields, int totalFields) {
    return Container(
      padding: const EdgeInsets.only(top: 32, bottom: 32),
      child: Column(
        children: [
          // Large Profile Avatar with Progress Ring
          ProgressRingAvatar(
            profileImageUrl: _profileImageUrl,
            userName: widget.userName,
            profileCompletion: percentage,
            size: 120,
            onTap: () {
              if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
                // Show full-screen image viewer
                _showFullScreenImage(context, _profileImageUrl!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No profile photo available'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // Large Percentage Display - Clean & Minimal
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: percentage >= 80
                  ? Colors.green
                  : percentage >= 50
                      ? const Color(0xFFFFA726)
                      : const Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }
}
