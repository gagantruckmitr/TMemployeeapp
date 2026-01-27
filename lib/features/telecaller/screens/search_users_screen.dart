import 'package:flutter/material.dart';
// import '../../core/config/api_config.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/driver_contact_card.dart';
import '../widgets/search_filter_sheet.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<DriverContact> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';
  SearchFilters _filters = SearchFilters();

  @override
  void initState() {
    super.initState();
    // Auto-focus search bar when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    // Allow search with filters even if query is empty
    if (query.trim().isEmpty && !_filters.hasActiveFilters) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
    });

    try {
      // Get bearer token from login session
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Please login again to search users';
          _isLoading = false;
        });
        return;
      }

      // Build URL with search query
      final uri = Uri.parse(ApiConfig.paymentsSearchApi).replace(queryParameters: {'search': query.trim()});

      print('🔍 Searching users: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> usersJson = data['users'] ?? [];

          print('✅ Found ${usersJson.length} users');

          // Debug: Print first user's call_logs structure
          if (usersJson.isNotEmpty) {
            final firstUser = usersJson[0] as Map<String, dynamic>;
            print('📋 First user keys: ${firstUser.keys.toList()}');

            // Check for call_logs in full_details
            final fullDetails =
                firstUser['full_details'] as Map<String, dynamic>?;
            if (fullDetails != null) {
              print('📋 full_details keys: ${fullDetails.keys.toList()}');
              if (fullDetails['call_logs'] != null) {
                final callLogs = fullDetails['call_logs'] as List;
                if (callLogs.isNotEmpty) {
                  print(
                    '📋 First call_log keys: ${(callLogs[0] as Map).keys.toList()}',
                  );
                  print('📋 First call_log data: ${callLogs[0]}');
                }
              }
            }

            // Also check root level call_history
            if (firstUser['call_history'] != null) {
              final callHistory = firstUser['call_history'] as List;
              if (callHistory.isNotEmpty) {
                print(
                  '📋 Root call_history keys: ${(callHistory[0] as Map).keys.toList()}',
                );
                print('📋 Root call_history data: ${callHistory[0]}');
              }
            }
          }

          setState(() {
            _searchResults = usersJson
                .map((json) => _mapJsonToDriverContact(json))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to search users';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Search error: $e');
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
        _isLoading = false;
      });
    }
  }

  DriverContact _mapJsonToDriverContact(Map<String, dynamic> json) {
    // Use the existing factory method that handles the telehead API format
    return DriverContact.fromBacklogJson(json);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search Users',
          style: AppTheme.headingMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.black87),
                onPressed: _showFilterSheet,
              ),
              if (_filters.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_filters.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search by phone, TMID, email, city,',
                hintStyle: AppTheme.bodyLarge.copyWith(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {}); // Update UI for clear button
              },
              onSubmitted: _performSearch,
            ),
          ),

          // Results Count
          if (_hasSearched && !_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    '${_searchResults.length} results found',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      'Swipe to see actions',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Search Results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _performSearch(_searchController.text),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Search Database',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search for drivers and transporters\nby name, phone, email, city or TMID',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No Results Found',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final contact = _searchResults[index];
        return DriverContactCard(
          contact: contact,
          onCallPressed: () => _handleCall(contact),
          isCallInProgress: false,
          showPhoneNumber: true,
        );
      },
    );
  }

  void _handleCall(DriverContact contact) {
    HapticFeedback.mediumImpact();
    // Navigate to call screen or initiate call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${contact.name}...'),
        backgroundColor: AppTheme.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SearchFilterSheet(
          initialFilters: _filters,
          onApply: (filters) {
            setState(() {
              _filters = filters;
            });
            // Re-run search with new filters (even if search query is empty)
            if (filters.hasActiveFilters || _searchController.text.isNotEmpty) {
              _performSearch(_searchController.text);
            }
          },
        ),
      ),
    );
  }
}
