import '../../../core/config/api_config.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../../../app/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';
import '../../../models/phase2_user_model.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/phase2_auth_service.dart';
import '../../../core/services/call_hit_service.dart';
import '../../../core/services/easygo_ivr_service.dart';
import '../../../core/utils/phone_masking_utils.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/easygo_ivr_call_helper.dart';
import '../../../widgets/error_handler.dart';

class CallHistoryScreen extends StatefulWidget {
  final String? initialFilter;
  final VoidCallback? onBack;

  const CallHistoryScreen({super.key, this.initialFilter, this.onBack});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<CallHistoryEntry>? _callHistory;
  int _totalRecords = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _filterStatus = 'all';
  String _filterFeedback = 'all';
  String _filterRemarks = 'all';
  String _filterDateRange = 'all';
  DateTime? _customDateFrom;
  DateTime? _customDateTo;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  Timer? _autoRefreshTimer;
  DateTime? _lastRefreshTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set initial filter if provided
    if (widget.initialFilter != null) {
      _filterStatus = widget.initialFilter!;
    }
    _loadCallHistory();

    // Start auto-refresh timer (refresh every 30 seconds)
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isLoading && !_isRefreshing) {
        debugPrint('🔄 ');
        _refreshData();
      }
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void didUpdateWidget(CallHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update filter if it changed
    if (widget.initialFilter != oldWidget.initialFilter &&
        widget.initialFilter != null) {
      setState(() {
        _filterStatus = widget.initialFilter!;
      });
      _loadCallHistory();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _stopAutoRefresh();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh immediately when app comes to foreground
      _refreshData();
      // Restart auto-refresh timer
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      // Stop auto-refresh when app goes to background to save resources
      _stopAutoRefresh();
    }
  }

  Future<void> _loadCallHistory() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Get current user and token from RealAuthService
      final currentUser = RealAuthService.instance.currentUser;
      final token = await RealAuthService.instance.getAuthToken();

      if (currentUser == null || token == null) {
        debugPrint('❌ User not logged in or token not available');
        if (mounted) {
          setState(() {
            _callHistory = [];
            _totalRecords = 0;
            _isLoading = false;
            _lastRefreshTime = DateTime.now();
          });
        }
        return;
      }

      final assignedToId = currentUser.id;
      debugPrint('📞 Loading call history for user ID: $assignedToId');

      // Call the new API endpoint
      final url =
          '${ApiConfig.laravelApiBase}/call-history/$assignedToId';
      debugPrint('🌐 API URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        // Handle direct array response (API returns [...] directly)
        List<dynamic> historyList = [];

        if (decodedResponse is List) {
          // API returns direct array
          debugPrint(
            '✅ API returned direct array with ${decodedResponse.length} items',
          );
          historyList = decodedResponse;
        } else if (decodedResponse is Map) {
          // API returns object with status/data
          debugPrint(
            '📊 API returned Map with keys: ${decodedResponse.keys.toList()}',
          );

          if (decodedResponse['status'] == true ||
              decodedResponse['success'] == true) {
            final data = decodedResponse['data'];
            if (data is List) {
              historyList = data;
            } else if (data is Map) {
              final dataMap = data as Map<String, dynamic>;
              if (dataMap.containsKey('call_logs')) {
                historyList = dataMap['call_logs'] as List<dynamic>? ?? [];
              } else if (dataMap.containsKey('calls')) {
                historyList = dataMap['calls'] as List<dynamic>? ?? [];
              } else if (dataMap.containsKey('history')) {
                historyList = dataMap['history'] as List<dynamic>? ?? [];
              } else if (dataMap.containsKey('records')) {
                historyList = dataMap['records'] as List<dynamic>? ?? [];
              } else {
                historyList = dataMap.values.whereType<Map>().toList();
              }
            }
          } else {
            debugPrint(
              '⚠️ API returned status=false: ${decodedResponse['message']}',
            );
          }
        }

        debugPrint('✅ Processing ${historyList.length} call history entries');

        // Log first item structure for debugging
        if (historyList.isNotEmpty) {
          debugPrint('📊 First item type: ${historyList[0]?.runtimeType}');
          if (historyList[0] is Map) {
            final firstItem = historyList[0] as Map;
            debugPrint('📊 First item keys: ${firstItem.keys.toList()}');
            debugPrint(
              '📱 Phone fields: phone_number=${firstItem['phone_number']}, mobile=${firstItem['mobile']}, user_mobile=${firstItem['user_mobile']}, phone=${firstItem['phone']}',
            );
          }
        }

        // Convert dynamic list to CallHistoryEntry list with error handling
        List<CallHistoryEntry> history = [];
        for (var i = 0; i < historyList.length; i++) {
          try {
            final item = historyList[i];

            // Skip if item is not a Map
            if (item is! Map) {
              debugPrint(
                '⚠️ Item $i is not a Map, skipping: ${item.runtimeType}',
              );
              continue;
            }

            // Parse call time - handle different formats
            DateTime callTime;
            try {
              if (item['call_time'] != null) {
                callTime = DateTime.parse(item['call_time'].toString());
              } else if (item['created_at'] != null) {
                callTime = DateTime.parse(item['created_at'].toString());
              } else if (item['call_initiated_at'] != null) {
                callTime = DateTime.parse(item['call_initiated_at'].toString());
              } else {
                callTime = DateTime.now();
              }
            } catch (e) {
              callTime = DateTime.now();
            }

            history.add(
              CallHistoryEntry(
                id: (item['id'] ?? item['call_id'] ?? '').toString(),
                driverId:
                    (item['driver_id'] ??
                            item['user_id'] ??
                            item['contact_id'] ??
                            '')
                        .toString(),
                tmid: (item['tmid'] ?? item['unique_id'] ?? '').toString(),
                driverName:
                    (item['driver_name'] ??
                            item['user_name'] ??
                            item['name'] ??
                            '')
                        .toString(),
                phoneNumber:
                    (item['phone_number'] ??
                            item['mobile'] ??
                            item['user_mobile'] ??
                            item['phone'] ??
                            item['client_number'] ??
                            '')
                        .toString(),
                process: item['process']?.toString(),
                status: _parseCallStatus(
                  (item['status'] ?? item['call_status'])?.toString(),
                ),
                callTime: callTime,
                duration: item['duration'] != null
                    ? int.tryParse(item['duration'].toString())
                    : (item['call_duration'] != null
                          ? int.tryParse(item['call_duration'].toString())
                          : (item['billsec'] != null
                              ? int.tryParse(item['billsec'].toString())
                              : null)),
                durationFormatted:
                    (item['duration_formatted'] ??
                            _formatDuration(
                              item['duration'] ?? item['call_duration'] ?? item['billsec'],
                            ))
                        .toString(),
                timeAgo: (item['time_ago'] ?? _getTimeAgo(callTime)).toString(),
                feedback:
                    item['feedback']?.toString() ??
                    item['call_feedback']?.toString(),
                remarks:
                    item['remarks']?.toString() ??
                    item['call_remarks']?.toString(),
                recordingUrl: _buildRecordingUrl(
                    item['recording_url'] ??
                    item['recording_file'] ??
                    item['call_recording'] ??
                    item['recfile']),
                manualCallRecordingUrl: item['manual_call_recording_url']
                    ?.toString(),
              ),
            );
          } catch (e) {
            debugPrint('❌ Error parsing item $i: $e');
            debugPrint('❌ Item content: ${historyList[i]}');
          }
        }

        debugPrint('✅ Successfully parsed ${history.length} entries');

        // Apply local filters
        history = _applyLocalFilters(history);

        if (mounted) {
          setState(() {
            _callHistory = history;
            _totalRecords = history.length;
            _isLoading = false;
            _lastRefreshTime = DateTime.now();
          });
        }
      } else {
        debugPrint('❌ HTTP Error ${response.statusCode}: ${response.body}');
        if (mounted) {
          setState(() {
            _callHistory = [];
            _totalRecords = 0;
            _isLoading = false;
            _lastRefreshTime = DateTime.now();
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading call history: $e');
      if (mounted) {
        setState(() {
          _callHistory = [];
          _totalRecords = 0;
          _isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    }
  }

  // Helper method to apply local filters
  List<CallHistoryEntry> _applyLocalFilters(List<CallHistoryEntry> history) {
    var filtered = history;

    // Filter by status
    if (_filterStatus != 'all') {
      filtered = filtered.where((entry) {
        final statusStr = _callStatusToString(entry.status).toLowerCase();
        return statusStr == _filterStatus.toLowerCase();
      }).toList();
    }

    // Filter by feedback
    if (_filterFeedback != 'all') {
      filtered = filtered.where((entry) {
        return entry.feedback?.toLowerCase() == _filterFeedback.toLowerCase();
      }).toList();
    }

    // Filter by remarks
    if (_filterRemarks == 'has_remarks') {
      filtered = filtered.where((entry) {
        return entry.remarks != null && entry.remarks!.isNotEmpty;
      }).toList();
    } else if (_filterRemarks == 'no_remarks') {
      filtered = filtered.where((entry) {
        return entry.remarks == null || entry.remarks!.isEmpty;
      }).toList();
    }

    // Filter by date range
    if (_filterDateRange != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (_filterDateRange == 'today') {
        filtered = filtered.where((entry) {
          final entryDate = DateTime(
            entry.callTime.year,
            entry.callTime.month,
            entry.callTime.day,
          );
          return entryDate == today;
        }).toList();
      } else if (_filterDateRange == 'yesterday') {
        final yesterday = today.subtract(const Duration(days: 1));
        filtered = filtered.where((entry) {
          final entryDate = DateTime(
            entry.callTime.year,
            entry.callTime.month,
            entry.callTime.day,
          );
          return entryDate == yesterday;
        }).toList();
      } else if (_filterDateRange == 'last_7_days') {
        final weekAgo = today.subtract(const Duration(days: 6));
        filtered = filtered.where((entry) {
          final entryDate = DateTime(
            entry.callTime.year,
            entry.callTime.month,
            entry.callTime.day,
          );
          return entryDate.isAfter(weekAgo.subtract(const Duration(days: 1))) &&
              entryDate.isBefore(today.add(const Duration(days: 1)));
        }).toList();
      } else if (_filterDateRange == 'last_30_days') {
        final monthAgo = today.subtract(const Duration(days: 29));
        filtered = filtered.where((entry) {
          final entryDate = DateTime(
            entry.callTime.year,
            entry.callTime.month,
            entry.callTime.day,
          );
          return entryDate.isAfter(
                monthAgo.subtract(const Duration(days: 1)),
              ) &&
              entryDate.isBefore(today.add(const Duration(days: 1)));
        }).toList();
      } else if (_filterDateRange == 'custom' &&
          _customDateFrom != null &&
          _customDateTo != null) {
        filtered = filtered.where((entry) {
          final entryDate = DateTime(
            entry.callTime.year,
            entry.callTime.month,
            entry.callTime.day,
          );
          return entryDate.isAfter(
                _customDateFrom!.subtract(const Duration(days: 1)),
              ) &&
              entryDate.isBefore(_customDateTo!.add(const Duration(days: 1)));
        }).toList();
      }
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      filtered = filtered.where((entry) {
        return entry.driverName.toLowerCase().contains(search) ||
            entry.phoneNumber.contains(search) ||
            entry.tmid.toLowerCase().contains(search);
      }).toList();
    }

    return filtered;
  }

  // Helper method to convert CallStatus to string
  String _callStatusToString(CallStatus status) {
    switch (status) {
      case CallStatus.connected:
        return 'connected';
      case CallStatus.callBack:
        return 'callback';
      case CallStatus.callBackLater:
        return 'callback_later';
      case CallStatus.notReachable:
        return 'not_reachable';
      case CallStatus.notInterested:
        return 'not_interested';
      case CallStatus.invalid:
        return 'invalid';
      case CallStatus.pending:
        return 'pending';
    }
  }

  // Helper method to format duration
  String _formatDuration(dynamic duration) {
    if (duration == null) return '0:00';
    final seconds = int.tryParse(duration.toString()) ?? 0;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Helper method to build full recording URL from recfile
  String? _buildRecordingUrl(dynamic recordingPath) {
    if (recordingPath == null) return null;
    final path = recordingPath.toString();
    if (path.isEmpty) return null;
    
    // If it's already a full URL, return as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    
    // Build full URL from recfile path
    // Base URL: https://client.easygoivr.com/monitor/
    return 'https://client.easygoivr.com/monitor/$path';
  }

  // Helper method to get time ago string
  String _getTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('dd MMM').format(time);
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      // Get current user and token from RealAuthService
      final currentUser = RealAuthService.instance.currentUser;
      final token = await RealAuthService.instance.getAuthToken();

      if (currentUser == null || token == null) {
        debugPrint('❌ User not logged in or token not available');
        if (mounted) {
          setState(() => _isRefreshing = false);
        }
        return;
      }

      final assignedToId = currentUser.id;
      debugPrint('🔄 Refreshing call history for user ID: $assignedToId');

      // Call the new API endpoint
      final url =
          '${ApiConfig.laravelApiBase}/call-history/$assignedToId';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Refresh Response status: ${response.statusCode}');
      debugPrint('📡 Refresh Response length: ${response.body.length}');

      // Log first 300 chars for debugging
      final previewLength = response.body.length > 300
          ? 300
          : response.body.length;
      debugPrint(
        '📡 Response preview: ${response.body.substring(0, previewLength)}',
      );

      if (response.statusCode == 200) {
        dynamic decodedResponse;
        try {
          decodedResponse = json.decode(response.body);
        } catch (e) {
          debugPrint('❌ JSON decode error: $e');
          if (mounted) setState(() => _isRefreshing = false);
          return;
        }

        // Handle direct array response (API returns [...] directly)
        List<dynamic> historyList = [];

        if (decodedResponse is List) {
          // API returns direct array
          debugPrint(
            '✅ Refresh: API returned direct array with ${decodedResponse.length} items',
          );
          historyList = decodedResponse;
        } else if (decodedResponse is Map) {
          // API returns object with status/data
          debugPrint(
            '📊 Refresh: API returned Map with keys: ${decodedResponse.keys.toList()}',
          );

          if (decodedResponse['status'] == true ||
              decodedResponse['success'] == true) {
            final data = decodedResponse['data'];
            if (data is List) {
              historyList = data;
            } else if (data is Map) {
              final dataMap = data as Map<String, dynamic>;
              if (dataMap.containsKey('call_logs')) {
                historyList = dataMap['call_logs'] as List<dynamic>? ?? [];
              } else if (dataMap.containsKey('calls')) {
                historyList = dataMap['calls'] as List<dynamic>? ?? [];
              } else if (dataMap.containsKey('history')) {
                historyList = dataMap['history'] as List<dynamic>? ?? [];
              } else if (dataMap.containsKey('records')) {
                historyList = dataMap['records'] as List<dynamic>? ?? [];
              } else {
                historyList = dataMap.values.whereType<Map>().toList();
              }
            }
          }
        }

        debugPrint('✅ Refresh: Processing ${historyList.length} items');

        // Convert dynamic list to CallHistoryEntry list with error handling
        List<CallHistoryEntry> history = [];
        for (var i = 0; i < historyList.length; i++) {
          try {
            final item = historyList[i];

            // Skip if item is not a Map
            if (item is! Map) continue;

            // Parse call time - handle different formats
            DateTime callTime;
            try {
              if (item['call_time'] != null) {
                callTime = DateTime.parse(item['call_time'].toString());
              } else if (item['created_at'] != null) {
                callTime = DateTime.parse(item['created_at'].toString());
              } else if (item['call_initiated_at'] != null) {
                callTime = DateTime.parse(item['call_initiated_at'].toString());
              } else {
                callTime = DateTime.now();
              }
            } catch (e) {
              callTime = DateTime.now();
            }

            history.add(
              CallHistoryEntry(
                id: (item['id'] ?? item['call_id'] ?? '').toString(),
                driverId:
                    (item['driver_id'] ??
                            item['user_id'] ??
                            item['contact_id'] ??
                            '')
                        .toString(),
                tmid: (item['tmid'] ?? item['unique_id'] ?? '').toString(),
                driverName:
                    (item['driver_name'] ??
                            item['user_name'] ??
                            item['name'] ??
                            '')
                        .toString(),
                phoneNumber:
                    (item['phone_number'] ??
                            item['mobile'] ??
                            item['user_mobile'] ??
                            item['phone'] ??
                            item['client_number'] ??
                            '')
                        .toString(),
                process: item['process']?.toString(),
                status: _parseCallStatus(
                  (item['status'] ?? item['call_status'])?.toString(),
                ),
                callTime: callTime,
                duration: item['duration'] != null
                    ? int.tryParse(item['duration'].toString())
                    : (item['call_duration'] != null
                          ? int.tryParse(item['call_duration'].toString())
                          : (item['billsec'] != null
                              ? int.tryParse(item['billsec'].toString())
                              : null)),
                durationFormatted:
                    (item['duration_formatted'] ??
                            _formatDuration(
                              item['duration'] ?? item['call_duration'] ?? item['billsec'],
                            ))
                        .toString(),
                timeAgo: (item['time_ago'] ?? _getTimeAgo(callTime)).toString(),
                feedback:
                    item['feedback']?.toString() ??
                    item['call_feedback']?.toString(),
                remarks:
                    item['remarks']?.toString() ??
                    item['call_remarks']?.toString(),
                recordingUrl: _buildRecordingUrl(
                    item['recording_url'] ??
                    item['recording_file'] ??
                    item['call_recording'] ??
                    item['recfile']),
                manualCallRecordingUrl: item['manual_call_recording_url']
                    ?.toString(),
              ),
            );
          } catch (e) {
            debugPrint('❌ Error parsing refresh item $i: $e');
          }
        }

        // Apply local filters
        history = _applyLocalFilters(history);

        if (mounted) {
          setState(() {
            _callHistory = history;
            _totalRecords = history.length;
            _isRefreshing = false;
            _lastRefreshTime = DateTime.now();
          });
        }
      } else {
        if (mounted) {
          setState(() => _isRefreshing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ErrorHandler.showError(context, e, onRetry: _refreshData);
      }
    }
  }

  CallStatus _parseCallStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'connected':
        return CallStatus.connected;
      case 'callback':
      case 'not_connected': // API stores 'not_connected' for callback/not reachable calls
        return CallStatus.callBack;
      case 'callback_later':
        return CallStatus.callBackLater;
      case 'not_reachable':
        return CallStatus.notReachable;
      case 'not_interested':
        return CallStatus.notInterested;
      case 'invalid':
        return CallStatus.invalid;
      case 'pending':
      case null:
      case '':
        return CallStatus.pending;
      default:
        return CallStatus.pending;
    }
  }

  void _onFilterChanged(String status) {
    if (_filterStatus != status) {
      setState(() {
        _filterStatus = status;
      });
      _loadCallHistory();
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => _FilterBottomSheet(
        initialFeedback: _filterFeedback,
        initialRemarks: _filterRemarks,
        onFeedbackChanged: (feedback) {
          setState(() {
            _filterFeedback = feedback;
          });
        },
        onRemarksChanged: (remarks) {
          setState(() {
            _filterRemarks = remarks;
          });
        },
        onApply: () {
          Navigator.pop(context);
          _loadCallHistory();
        },
      ),
    );
  }

  void _showDateFilterBottomSheet() async {
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

    final dateOptions = [
      {'label': 'All Time', 'value': 'all', 'icon': Icons.all_inclusive},
      {'label': 'Today', 'value': 'today', 'icon': Icons.today},
      {'label': 'Yesterday', 'value': 'yesterday', 'icon': Icons.history},
      {
        'label': 'Last 7 Days',
        'value': 'last_7_days',
        'icon': Icons.date_range,
      },
      {
        'label': 'Last 30 Days',
        'value': 'last_30_days',
        'icon': Icons.calendar_month,
      },
      {
        'label': 'Custom Range...',
        'value': 'custom',
        'icon': Icons.edit_calendar,
      },
    ];

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          MediaQuery.of(context).size.width - 200,
          MediaQuery.of(context).padding.top + 56,
          180,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      items: dateOptions.map((option) {
        final isSelected = _filterDateRange == option['value'];
        return PopupMenuItem<String>(
          value: option['value'] as String,
          child: Row(
            children: [
              Icon(
                option['icon'] as IconData,
                size: 18,
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option['label'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFF007AFF)
                        : Colors.black87,
                    letterSpacing: -0.24,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check, size: 18, color: Color(0xFF007AFF)),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      HapticFeedback.lightImpact();

      if (selected == 'custom') {
        // Show date range picker
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: _customDateFrom != null && _customDateTo != null
              ? DateTimeRange(start: _customDateFrom!, end: _customDateTo!)
              : null,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF007AFF),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _filterDateRange = 'custom';
            _customDateFrom = picked.start;
            _customDateTo = picked.end;
          });
          _loadCallHistory();
        }
      } else {
        setState(() {
          _filterDateRange = selected;
          _customDateFrom = null;
          _customDateTo = null;
        });
        _loadCallHistory();
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadCallHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Column(
        children: [
          _CallHistoryHeader(
            totalCalls: _totalRecords,
            onRefresh: _refreshData,
            isRefreshing: _isRefreshing,
            onFilterTap: _showFilterBottomSheet,
            onDateFilterTap: _showDateFilterBottomSheet,
            hasDateFilter: _filterDateRange != 'all',
            lastRefreshTime: _lastRefreshTime,
            onBack: widget.onBack,
          ),
          _SearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
          _FilterChips(
            selectedFilter: _filterStatus,
            onFilterChanged: _onFilterChanged,
          ),
          Expanded(
            child: _isLoading
                ? const _LoadingWidget()
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: (_callHistory?.isEmpty ?? true)
                        ? const _EmptyStateWidget()
                        : _CallHistoryList(
                            history: _callHistory!,
                            scrollController: _scrollController,
                            onUpdate: _refreshData,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CallHistoryHeader extends StatelessWidget {
  final int totalCalls;
  final VoidCallback onRefresh;
  final bool isRefreshing;
  final VoidCallback onFilterTap;
  final VoidCallback onDateFilterTap;
  final bool hasDateFilter;
  final DateTime? lastRefreshTime;
  final VoidCallback? onBack;

  const _CallHistoryHeader({
    required this.totalCalls,
    required this.onRefresh,
    required this.isRefreshing,
    required this.onFilterTap,
    required this.onDateFilterTap,
    required this.hasDateFilter,
    this.lastRefreshTime,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      // Slim padding - reduced vertical space
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white, // White background
      ),
      child: Row(
        children: [
          // iOS-style back button
          if (onBack != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onBack!();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chevron_left_rounded,
                      color: const Color(0xFF007AFF),
                      size: 28,
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(width: 8),

          // Title and count - compact
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Call History',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.41,
                  ),
                ),
                Text(
                  '$totalCalls calls${lastRefreshTime != null ? ' • ${_getTimeAgo(lastRefreshTime!)}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade500,
                    letterSpacing: -0.08,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons - compact
          _buildSmallIconButton(
            icon: Icons.calendar_today_rounded,
            onTap: onDateFilterTap,
            isActive: hasDateFilter,
          ),
          const SizedBox(width: 6),
          _buildSmallIconButton(
            icon: Icons.tune_rounded,
            onTap: onFilterTap,
            isActive: false,
          ),
          const SizedBox(width: 6),
          _buildSmallIconButton(
            icon: Icons.refresh_rounded,
            onTap: isRefreshing ? null : onRefresh,
            isActive: false,
            isLoading: isRefreshing,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isActive,
    bool isLoading = false,
  }) {
    const activeColor = Color(0xFF007AFF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                  ),
                )
              : Icon(
                  icon,
                  size: 16,
                  color: isActive ? activeColor : Colors.grey.shade600,
                ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inSeconds < 5) return 'just now';
    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    return '${difference.inHours}h ago';
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      color: Colors.white, // White background
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5EA), // iOS search bar background
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 17, letterSpacing: -0.41),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 17,
              letterSpacing: -0.41,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade500,
              size: 22,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: Icon(
                      Icons.cancel,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  )
                : null,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 12,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String initialFeedback;
  final String initialRemarks;
  final Function(String) onFeedbackChanged;
  final Function(String) onRemarksChanged;
  final VoidCallback onApply;

  const _FilterBottomSheet({
    required this.initialFeedback,
    required this.initialRemarks,
    required this.onFeedbackChanged,
    required this.onRemarksChanged,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String selectedFeedback;
  late String selectedRemarks;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Categorized feedback options based on the image
  static const List<Map<String, dynamic>> _subscriptionFeedbacks = [
    {
      'label': 'Agree for Subscription',
      'value': 'Agree for Subscription',
      'color': 0xFF34C759,
    },
    {
      'label': 'Agree for Subscription (Today)',
      'value': 'Agree for Subscription (Today)',
      'color': 0xFF30D158,
    },
    {
      'label': 'Agree for Subscription (Tomorrow)',
      'value': 'Agree for Subscription (Tomorrow)',
      'color': 0xFF32ADE6,
    },
    {
      'label': 'Already Subscribed',
      'value': 'Already Subscribed',
      'color': 0xFF00C7BE,
    },
    {
      'label': 'Wants to Think Before Subscribing',
      'value': 'Wants to Think Before Subscribing',
      'color': 0xFFFF9F0A,
    },
    {
      'label': 'Will Subscribe Later (No specific time)',
      'value': 'Will Subscribe Later (No specific time)',
      'color': 0xFFFFCC00,
    },
    {
      'label': 'Will Subscribe When Job Needed',
      'value': 'Will Subscribe When Job Needed',
      'color': 0xFFFF9500,
    },
  ];

  static const List<Map<String, dynamic>> _appIssueFeedbacks = [
    {'label': 'App Issue', 'value': 'App Issue', 'color': 0xFFFF3B30},
    {
      'label': "Doesn't Understand App",
      'value': "Doesn't Understand App",
      'color': 0xFFFF6961,
    },
    {
      'label': 'Needs Help in Profile',
      'value': 'Needs Help in Profile',
      'color': 0xFFFF9500,
    },
    {
      'label': 'Wants Demo Video',
      'value': 'Wants Demo Video',
      'color': 0xFF5856D6,
    },
  ];

  static const List<Map<String, dynamic>> _callStatusFeedbacks = [
    {'label': 'Not Interested', 'value': 'Not Interested', 'color': 0xFF8E8E93},
    {
      'label': 'Language Barrier',
      'value': 'Language Barrier',
      'color': 0xFFAF52DE,
    },
    {'label': 'Misbehave', 'value': 'Misbehave', 'color': 0xFFFF2D55},
    {
      'label': 'Internet Issue - Low Speed',
      'value': 'Internet Issue - Low Speed',
      'color': 0xFFFF9F0A,
    },
  ];

  static const List<Map<String, dynamic>> _driverTypeFeedbacks = [
    {
      'label': 'Driver - Cab | Bus',
      'value': 'Driver - Cab | Bus',
      'color': 0xFF007AFF,
    },
    {
      'label': 'Neither Transporter not Driver',
      'value': 'Neither Transporter not Driver',
      'color': 0xFF8E8E93,
    },
    {
      'label': 'Transporter but Registered as Driver',
      'value': 'Transporter but Registered as Driver',
      'color': 0xFF5856D6,
    },
  ];

  static const List<Map<String, dynamic>> _jobRelatedFeedbacks = [
    {'label': 'Need Load', 'value': 'Need Load', 'color': 0xFF34C759},
    {
      'label': 'Needs Job Urgently',
      'value': 'Needs Job Urgently',
      'color': 0xFFFF3B30,
    },
    {
      'label': 'Ready for Interview',
      'value': 'Ready for Interview',
      'color': 0xFF30D158,
    },
    {'label': 'No Money', 'value': 'No Money', 'color': 0xFFFF9500},
  ];

  @override
  void initState() {
    super.initState();
    selectedFeedback = widget.initialFeedback;
    selectedRemarks = widget.initialRemarks;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _allFeedbacks => [
    {'label': 'All Feedbacks', 'value': 'all', 'color': 0xFF007AFF},
    ..._subscriptionFeedbacks,
    ..._appIssueFeedbacks,
    ..._callStatusFeedbacks,
    ..._driverTypeFeedbacks,
    ..._jobRelatedFeedbacks,
  ];

  List<Map<String, dynamic>> get _filteredFeedbacks {
    if (_searchQuery.isEmpty) return _allFeedbacks;
    return _allFeedbacks
        .where(
          (f) => (f['label'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final remarkOptions = [
      {'label': 'All Remarks', 'value': 'all', 'color': 0xFF007AFF},
      {'label': 'Has Remarks', 'value': 'has_remarks', 'color': 0xFF34C759},
      {'label': 'No Remarks', 'value': 'no_remarks', 'color': 0xFF8E8E93},
    ];

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: Colors.white, // White background
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // iOS-style handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // iOS-style header with title and buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        selectedFeedback = 'all';
                        selectedRemarks = 'all';
                        _searchQuery = '';
                        _searchController.clear();
                      });
                      widget.onFeedbackChanged('all');
                      widget.onRemarksChanged('all');
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onApply();
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Search bar - iOS style
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          style: const TextStyle(fontSize: 17),
                          decoration: InputDecoration(
                            hintText: 'Search feedbacks',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 17,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade500,
                              size: 22,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      });
                                    },
                                    child: Icon(
                                      Icons.cancel,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Selected filter indicator
                    if (selectedFeedback != 'all')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selected: $selectedFeedback',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => selectedFeedback = 'all');
                                  widget.onFeedbackChanged('all');
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Colors.blue.shade700,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (selectedFeedback != 'all') const SizedBox(height: 16),

                    // Feedback Section Header
                    _buildSectionHeader('FEEDBACK'),

                    // iOS-style grouped list for feedbacks
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: _filteredFeedbacks.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final feedback = entry.value;
                          final isSelected =
                              selectedFeedback == feedback['value'];
                          final isFirst = index == 0;
                          final isLast = index == _filteredFeedbacks.length - 1;

                          return Column(
                            children: [
                              _buildAppleListTile(
                                label: feedback['label'] as String,
                                isSelected: isSelected,
                                color: Color(feedback['color'] as int),
                                isFirst: isFirst,
                                isLast: isLast,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    selectedFeedback =
                                        feedback['value'] as String;
                                  });
                                  widget.onFeedbackChanged(
                                    feedback['value'] as String,
                                  );
                                },
                              ),
                              if (!isLast)
                                Padding(
                                  padding: const EdgeInsets.only(left: 44),
                                  child: Divider(
                                    height: 0.5,
                                    thickness: 0.5,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Remarks Section Header
                    _buildSectionHeader('REMARKS'),

                    // iOS-style grouped list for remarks
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: remarkOptions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final remark = entry.value;
                          final isSelected = selectedRemarks == remark['value'];
                          final isFirst = index == 0;
                          final isLast = index == remarkOptions.length - 1;

                          return Column(
                            children: [
                              _buildAppleListTile(
                                label: remark['label'] as String,
                                isSelected: isSelected,
                                color: Color(remark['color'] as int),
                                isFirst: isFirst,
                                isLast: isLast,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    selectedRemarks = remark['value'] as String;
                                  });
                                  widget.onRemarksChanged(
                                    remark['value'] as String,
                                  );
                                },
                              ),
                              if (!isLast)
                                Padding(
                                  padding: const EdgeInsets.only(left: 44),
                                  child: Divider(
                                    height: 0.5,
                                    thickness: 0.5,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.grey.shade600,
          letterSpacing: -0.08,
        ),
      ),
    );
  }

  Widget _buildAppleListTile({
    required String label,
    required bool isSelected,
    required Color color,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(10) : Radius.zero,
          bottom: isLast ? const Radius.circular(10) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Color indicator dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              // Label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    letterSpacing: -0.41,
                  ),
                ),
              ),
              // Checkmark for selected
              if (isSelected)
                Icon(Icons.check, color: Colors.blue.shade600, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Connected', 'value': 'connected'},
      {'label': 'Not Connected', 'value': 'callback'},
      {'label': 'Call Back', 'value': 'callback_later'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      color: Colors.white, // White background
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5EA), // iOS segmented control background
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onFilterChanged(filter['value'] as String);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      filter['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF007AFF)
                            : Colors.grey.shade600,
                        letterSpacing: -0.08,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CallHistoryList extends StatelessWidget {
  final List<CallHistoryEntry> history;
  final ScrollController scrollController;
  final VoidCallback? onUpdate;

  const _CallHistoryList({
    required this.history,
    required this.scrollController,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return _CallHistoryCard(
          key: ValueKey(entry.id),
          entry: entry,
          onUpdate: onUpdate,
        );
      },
    );
  }
}

class _CallHistoryCard extends StatefulWidget {
  final CallHistoryEntry entry;
  final VoidCallback? onUpdate;

  const _CallHistoryCard({super.key, required this.entry, this.onUpdate});

  @override
  State<_CallHistoryCard> createState() => _CallHistoryCardState();
}

class _CallHistoryCardState extends State<_CallHistoryCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayRecording() async {
    final recordingUrl = widget.entry.anyRecordingUrl;
    if (recordingUrl == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => _isLoading = true);
        await _audioPlayer.play(UrlSource(recordingUrl));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor() {
    switch (widget.entry.status) {
      case CallStatus.connected:
        return Colors.green;
      case CallStatus.callBack:
        return Colors.orange;
      case CallStatus.callBackLater:
        return Colors.blue;
      case CallStatus.notReachable:
        return Colors.red;
      case CallStatus.notInterested:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.entry.status) {
      case CallStatus.connected:
        return Icons.check_circle;
      case CallStatus.callBack:
        return Icons.refresh;
      case CallStatus.callBackLater:
        return Icons.schedule;
      case CallStatus.notReachable:
        return Icons.phone_disabled;
      case CallStatus.notInterested:
        return Icons.cancel;
      default:
        return Icons.phone;
    }
  }

  Future<void> _makeCall() async {
    try {
      // Check both auth services for user
      final currentUser = RealAuthService.instance.currentUser;
      Phase2User? phase2User = await Phase2AuthService.getCurrentUser();

      // If RealAuthService has user but Phase2AuthService doesn't, create Phase2User from RealAuth data
      if (currentUser != null && phase2User == null) {
        print('🔄 Syncing user from RealAuthService to Phase2AuthService');
        // Create a Phase2User object from RealAuthService data
        phase2User = Phase2User(
          id: int.tryParse(currentUser.id) ?? 0,
          name: currentUser.name,
          mobile: currentUser.mobile,
          email: currentUser.email,
          role: currentUser.role,
          tcFor: '', // Not available in RealAuthService
          createdAt: DateTime.now().toIso8601String(),
        );
      }

      if (currentUser == null && phase2User == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show call type selection dialog
      final callType = await showDialog<String>(
        context: context,
        builder: (context) =>
            CallTypeSelectionDialog(driverName: widget.entry.driverName),
      );

      if (callType == null) return;

      // Log call hit
      await CallHitService.instance.logCallHit(
        contactId: widget.entry.driverId,
        contactName: widget.entry.driverName,
        contactType: 'driver',
        callType: callType,
        sourceScreen: 'telecaller_call_history',
        phoneNumber: widget.entry.phoneNumber,
      );

      // Use appropriate user ID based on which auth service has the user
      final callerId = currentUser != null
          ? (int.tryParse(currentUser.id) ?? 1)
          : (phase2User?.id ?? 1);
      final cleanPhone = widget.entry.phoneNumber.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      if (callType == 'manual') {
        // For manual calls, phone number might be hidden for privacy
        // The manual_call_api will fetch the actual number from database
        final result = await SmartCallingService.instance.initiateManualCall(
          driverMobile: cleanPhone.isEmpty ? widget.entry.driverId : cleanPhone,
          callerId: callerId,
          driverId: widget.entry.driverId,
          callSource: 'call_history_recall', // Mark as recall from history
        );

        if (result['success'] == true && mounted) {
          final driverMobileRaw = result['data']?['driver_mobile_raw'];
          final newCallLogId = result['data']?['call_log_id']?.toString();

          await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            // Use new call_log_id if available, otherwise use existing entry id
            _showUpdateFeedbackModal(
              callLogId: newCallLogId ?? widget.entry.id,
            );
          }
        }
      } else if (callType == 'easygo_ivr') {
        // For IVR calls, if phone number is empty, fetch it from database first
        String phoneToUse = widget.entry.phoneNumber;

        if (cleanPhone.isEmpty) {
          // Fetch phone number from database using the same API as manual calls
          final result = await SmartCallingService.instance.initiateManualCall(
            driverMobile: widget.entry.driverId,
            callerId: callerId,
            driverId: widget.entry.driverId,
          );

          if (result['success'] == true) {
            phoneToUse = result['data']?['driver_mobile_raw'] ?? '';
          }
        }

        await EasyGoIVRCallHelper.initiateCall(
          context: context,
          clientName: widget.entry.driverName,
          clientPhone: phoneToUse,
          clientId: widget.entry.driverId,
          tmid: widget.entry.tmid,
          contactType: 'driver',
          process: widget.entry.process ?? 'Driver Onboarding',
          callSource: 'call_history_recall', // Mark as recall from history
          onCallCompleted: (callLogId) {
            if (mounted) {
              // For IVR calls, use the newly created call log ID if available
              // Fallback to widget.entry.id only if callLogId is null (which shouldn't happen for successful calls)
              _showUpdateFeedbackModal(callLogId: callLogId ?? widget.entry.id);
            }
          },
        );
      }
    } catch (e) {
      print('❌ CALL HISTORY: Exception in _makeCall: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpdateFeedbackModal({String? callLogId}) {
    debugPrint(
      '🔵 [CallHistory] _showUpdateFeedbackModal called with callLogId: $callLogId',
    );
    debugPrint(
      '🔵 [CallHistory] mounted: $mounted, context.mounted: ${context.mounted}',
    );

    if (!mounted) {
      debugPrint('❌ [CallHistory] Widget not mounted, cannot show modal');
      return;
    }

    final contact = DriverContact(
      id: widget.entry.driverId,
      tmid: 'TM${widget.entry.driverId}',
      name: widget.entry.driverName,
      phoneNumber: widget.entry.phoneNumber,
      company: '',
      state: '',
      subscriptionStatus: SubscriptionStatus.inactive,
      status: widget.entry.status,
    );

    // Use provided callLogId or fall back to entry id
    final targetCallLogId = callLogId ?? widget.entry.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible:
          false, // detailed_screen: Prevent dismissing by tapping outside
      enableDrag: false, // detailed_screen: Prevent dragging to dismiss
      builder: (context) => PopScope(
        canPop: false, // Prevent back button dismissal
        child: CallFeedbackModal(
          contact: contact,
          referenceId: targetCallLogId,
          callDuration: widget.entry.duration,
          allowDismiss: false, // Hide close button
          onFeedbackSubmitted: (feedback) async {
            try {
              // Update feedback using the correct call_log_id
              await _updateFeedback(feedback, callLogId: targetCallLogId);

              // Close modal only after everything is done
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            } catch (e) {
              debugPrint('❌ Error in feedback submission: $e');
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _updateFeedback(
    CallFeedback feedback, {
    String? callLogId,
  }) async {
    String feedbackText = '';

    switch (feedback.status) {
      case CallStatus.connected:
        feedbackText = feedback.connectedFeedback?.displayName ?? 'Connected';
        break;
      case CallStatus.callBack:
        feedbackText = feedback.callBackReason?.displayName ?? 'Call Back';
        break;
      case CallStatus.callBackLater:
        feedbackText = feedback.callBackTime?.displayName ?? 'Call Back Later';
        break;
      case CallStatus.notReachable:
        feedbackText = 'Not Reachable';
        break;
      case CallStatus.notInterested:
        feedbackText = 'Not Interested';
        break;
      case CallStatus.invalid:
        feedbackText = 'Invalid Number';
        break;
      case CallStatus.pending:
        feedbackText = 'Pending';
        break;
    }

    // Use provided callLogId or fall back to entry id
    final targetCallLogId = callLogId ?? widget.entry.id;

    try {
      // Map status to string for API (matching smart_calling_page.dart logic)
      String statusString = 'not_connected';
      switch (feedback.status) {
        case CallStatus.connected:
          statusString = 'connected';
          break;
        case CallStatus.callBack:
          statusString = 'not_connected';
          break;
        case CallStatus.callBackLater:
          statusString = 'callback_later';
          break;
        case CallStatus.notReachable:
          statusString = 'not_connected';
          break;
        case CallStatus.notInterested:
          statusString = 'connected';
          break;
        case CallStatus.invalid:
          statusString = 'not_connected';
          break;
        case CallStatus.pending:
          statusString = 'not_connected';
          break;
      }

      debugPrint('🔵 Updating feedback via Live API:');
      debugPrint('   Call ID: $targetCallLogId');
      debugPrint('   Status: $statusString');
      debugPrint('   Feedback: $feedbackText');
      debugPrint('   Remarks: ${feedback.remarks}');

      // Use Live API for feedback update
      final callId = int.tryParse(targetCallLogId);
      bool success = false;
      String? errorMessage;

      if (callId != null) {
        final result = await EasyGoIVRService.updateCall(
          callId: callId,
          status: statusString,
          feedback: feedbackText,
          remarks: feedback.remarks,
          recordingFile: feedback.recordingFile?.path,
        );
        success = result['success'] == true;
        errorMessage = result['error']?.toString();
        debugPrint('🔵 Live API Response: $result');
      } else {
        debugPrint('❌ Invalid call ID: $targetCallLogId');
        errorMessage = 'Invalid call ID: $targetCallLogId';
      }

      if (success && mounted) {
        HapticFeedback.lightImpact();

        // Update local state IMMEDIATELY for instant UI feedback
        setState(() {
          // Update the entry's status and feedback in place
          widget.entry.status = feedback.status;
          widget.entry.feedback = feedbackText;
          widget.entry.remarks = feedback.remarks;
        });

        // Show success message immediately
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Feedback updated for ${widget.entry.driverName}'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh in background to sync with server (non-blocking)
        if (widget.onUpdate != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              widget.onUpdate!();
            }
          });
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Failed to update feedback: ${errorMessage ?? "Unknown error"}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime, String? timeAgo) {
    // Always show exact date and time - no "Today" or "Yesterday"
    return DateFormat('MMM dd, yyyy h:mm a').format(dateTime);
  }

  String _formatDuration(int? seconds, String? durationFormatted) {
    // Use API-provided duration_formatted if available
    if (durationFormatted != null &&
        durationFormatted.isNotEmpty &&
        durationFormatted != '0:00') {
      return durationFormatted;
    }

    if (seconds == null || seconds == 0) return '0:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getStatusDisplayName() {
    switch (widget.entry.status) {
      case CallStatus.connected:
        return 'CONNECTED';
      case CallStatus.callBack:
        return 'NOT CONNECTED';
      case CallStatus.callBackLater:
        return 'CALL BACK';
      case CallStatus.notReachable:
        return 'NOT REACHABLE';
      case CallStatus.notInterested:
        return 'NOT INTERESTED';
      case CallStatus.invalid:
        return 'INVALID';
      case CallStatus.pending:
        return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getStatusIcon(), color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.driverName,
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.entry.tmid.isNotEmpty
                            ? '${widget.entry.tmid} • ${widget.entry.processDisplayName}'
                            : 'TMID: ${widget.entry.driverId} • ${widget.entry.processDisplayName}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.indigo.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        PhoneMaskingUtils.maskPhoneNumber(
                          widget.entry.phoneNumber,
                        ),
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusDisplayName(),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time and Duration
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(
                        widget.entry.callTime,
                        widget.entry.timeAgo,
                      ),
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(
                        widget.entry.duration,
                        widget.entry.durationFormatted,
                      ),
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Feedback Section
                if (widget.entry.feedback != null &&
                    widget.entry.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feedback',
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.entry.feedback!,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.blue.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Remarks Section - Always show
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (widget.entry.remarks != null &&
                            widget.entry.remarks!.isNotEmpty)
                        ? Colors.amber.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          (widget.entry.remarks != null &&
                              widget.entry.remarks!.isNotEmpty)
                          ? Colors.amber.shade200
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color:
                            (widget.entry.remarks != null &&
                                widget.entry.remarks!.isNotEmpty)
                            ? Colors.amber.shade700
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Remarks',
                              style: AppTheme.bodySmall.copyWith(
                                color:
                                    (widget.entry.remarks != null &&
                                        widget.entry.remarks!.isNotEmpty)
                                    ? Colors.amber.shade700
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (widget.entry.remarks != null &&
                                      widget.entry.remarks!.isNotEmpty)
                                  ? widget.entry.remarks!
                                  : 'No remarks added',
                              style: AppTheme.bodyMedium.copyWith(
                                color:
                                    (widget.entry.remarks != null &&
                                        widget.entry.remarks!.isNotEmpty)
                                    ? Colors.amber.shade900
                                    : Colors.grey.shade400,
                                fontSize: 13,
                                fontStyle:
                                    (widget.entry.remarks == null ||
                                        widget.entry.remarks!.isEmpty)
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _makeCall,
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showUpdateFeedbackModal,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Update'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppTheme.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (widget.entry.hasRecording) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _isLoading ? null : _togglePlayRecording,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                                size: 32,
                              ),
                        color: Colors.purple,
                        tooltip: _isPlaying
                            ? 'Pause Recording'
                            : 'Play Recording',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.purple.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 60,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Call History',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your call logs will appear here\nonce you start making calls',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

// Call History Entry Model
class CallHistoryEntry {
  final String id;
  final String driverId;
  final String tmid;
  final String driverName;
  final String phoneNumber;
  CallStatus status; // Made mutable for instant UI updates
  final DateTime callTime;
  final int? duration;
  final String? durationFormatted;
  final String? timeAgo;
  String? feedback; // Made mutable for instant UI updates
  String? remarks; // Made mutable for instant UI updates
  final String? recordingUrl;
  final String? manualCallRecordingUrl;
  final String? process; // Process type: welcome, transporter, tollfree, etc.

  CallHistoryEntry({
    required this.id,
    required this.driverId,
    required this.tmid,
    required this.driverName,
    required this.phoneNumber,
    required this.status,
    required this.callTime,
    this.duration,
    this.durationFormatted,
    this.timeAgo,
    this.feedback,
    this.remarks,
    this.recordingUrl,
    this.manualCallRecordingUrl,
    this.process,
  });

  // Helper to get any available recording URL
  String? get anyRecordingUrl => manualCallRecordingUrl ?? recordingUrl;
  bool get hasRecording =>
      anyRecordingUrl != null && anyRecordingUrl!.isNotEmpty;

  // Helper to get display name for process
  String get processDisplayName {
    switch (process?.toLowerCase()) {
      case 'welcome':
      case 'driver':
        return 'Driver Onboarding';
      case 'transporter':
        return 'Transporter Onboarding';
      case 'tollfree':
        return 'Toll Free';
      default:
        return process ?? 'Unknown';
    }
  }
}

// Date Filter Bottom Sheet
class _DateFilterBottomSheet extends StatefulWidget {
  final String initialDateRange;
  final DateTime? customDateFrom;
  final DateTime? customDateTo;
  final Function(String, DateTime?, DateTime?) onDateRangeChanged;
  final VoidCallback onApply;

  const _DateFilterBottomSheet({
    required this.initialDateRange,
    this.customDateFrom,
    this.customDateTo,
    required this.onDateRangeChanged,
    required this.onApply,
  });

  @override
  State<_DateFilterBottomSheet> createState() => _DateFilterBottomSheetState();
}

class _DateFilterBottomSheetState extends State<_DateFilterBottomSheet> {
  late String selectedDateRange;
  DateTime? customDateFrom;
  DateTime? customDateTo;

  @override
  void initState() {
    super.initState();
    selectedDateRange = widget.initialDateRange;
    customDateFrom = widget.customDateFrom;
    customDateTo = widget.customDateTo;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customDateFrom != null && customDateTo != null
          ? DateTimeRange(start: customDateFrom!, end: customDateTo!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.purple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        customDateFrom = picked.start;
        customDateTo = picked.end;
        selectedDateRange = 'custom';
      });
      widget.onDateRangeChanged('custom', picked.start, picked.end);
    }
  }

  Widget _buildDateRangeChip(String label, String value, IconData icon) {
    final isSelected = selectedDateRange == value;
    return ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        setState(() {
          selectedDateRange = value;
          if (value != 'custom') {
            customDateFrom = null;
            customDateTo = null;
          }
        });
        widget.onDateRangeChanged(value, null, null);
      },
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.purple : Colors.grey.shade100,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateRangeChip() {
    final isSelected = selectedDateRange == 'custom';
    return ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        _selectDateRange();
      },
      icon: const Icon(Icons.calendar_month, size: 16),
      label: const Text(
        'Custom Range',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.purple : Colors.grey.shade100,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  String _getDateRangeLabel() {
    switch (selectedDateRange) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'last_7_days':
        return 'Last 7 Days';
      case 'last_30_days':
        return 'Last 30 Days';
      case 'custom':
        if (customDateFrom != null && customDateTo != null) {
          return '${DateFormat('MMM dd').format(customDateFrom!)} - ${DateFormat('MMM dd, yyyy').format(customDateTo!)}';
        }
        return 'Custom Range';
      default:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.purple,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Filter by Date',
                            style: AppTheme.headingMedium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Current Selection Display
                    if (selectedDateRange != 'all')
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              color: Colors.purple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Range',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getDateRangeLabel(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.purple.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Date Range Options
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Filters',
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildDateRangeChip(
                                'All Time',
                                'all',
                                Icons.all_inclusive,
                              ),
                              _buildDateRangeChip(
                                'Today',
                                'today',
                                Icons.today,
                              ),
                              _buildDateRangeChip(
                                'Yesterday',
                                'yesterday',
                                Icons.calendar_today,
                              ),
                              _buildDateRangeChip(
                                'Last 7 Days',
                                'last_7_days',
                                Icons.date_range,
                              ),
                              _buildDateRangeChip(
                                'Last 30 Days',
                                'last_30_days',
                                Icons.calendar_month,
                              ),
                              _buildCustomDateRangeChip(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Apply Button
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Apply Date Filter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
