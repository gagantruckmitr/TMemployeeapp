import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme/app_theme.dart';
import '../core/services/real_auth_service.dart';
import '../core/services/tasksuite_auth_service.dart';
import '../core/constants/api_constants.dart';
import 'presentation/pages/check_in_page.dart';
import 'presentation/pages/attendance_history_page.dart';

/// Main Attendance Screen - Entry point for attendance feature
/// Shows current attendance status and quick actions
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isLoading = true;
  bool _authError = false;
  String? _employeeId;
  Map<String, dynamic>? _todayAttendance;
  List<dynamic> _allAttendance = [];
  int _totalPresent = 0;
  int _totalAbsent = 0;
  String _avgCheckIn = '--:--';

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
      _authError = false;
    });

    try {
      // Initialize TaskSuite auth service
      await TaskSuiteAuthService.instance.initialize();

      // Get employee ID - use TaskSuite user ID if available
      String? employeeId;
      final taskSuiteUser = TaskSuiteAuthService.instance.user;
      if (taskSuiteUser != null && taskSuiteUser['id'] != null) {
        employeeId = taskSuiteUser['id'].toString();
      } else {
        employeeId = await _getEmployeeId();
      }
      print('📍 Employee ID: $employeeId');

      if (employeeId == null) {
        print('❌ No employee ID found!');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _employeeId = employeeId;
      });

      // Get TaskSuite token
      final token = await TaskSuiteAuthService.instance.getToken();
      print('🔑 TaskSuite Token available: ${token != null}');

      if (token == null) {
        print('⚠️ No TaskSuite token - need to login');
        setState(() {
          _isLoading = false;
          _authError = true;
        });
        return;
      }

      // Fetch attendance data from API with TaskSuite token
      await _fetchAttendanceFromApi(token, employeeId);
    } catch (e) {
      print('❌ Error loading attendance: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAttendanceFromApi(String token, String employeeId) async {
    try {
      final url = ApiConstants.attendance(employeeId);
      print('📡 Fetching from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.headersWithToken(token),
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 401) {
        // Unauthenticated - need TaskSuite login
        print('❌ TaskSuite authentication required');
        setState(() {
          _authError = true;
        });
        return;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> records = data['data']['data'] ?? [];
          print('📋 Total records: ${records.length}');

          // Get today's date
          final now = DateTime.now();
          final todayStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

          // Find today's attendance
          Map<String, dynamic>? todayRecord;
          try {
            todayRecord = records.firstWhere((record) {
              final recordDate = record['date']?.toString() ?? '';
              final checkInTime = record['checkin_time']?.toString() ?? '';
              return recordDate == todayStr || checkInTime.startsWith(todayStr);
            });
            print('✅ Today\'s attendance found: $todayRecord');
          } catch (e) {
            print('ℹ️ No attendance for today');
          }

          // Calculate stats for current month
          int presentCount = 0;
          int totalMinutes = 0;
          int validCheckIns = 0;

          for (var record in records) {
            final checkInTime = record['checkin_time'];
            if (checkInTime != null) {
              try {
                final dateTime = DateTime.parse(checkInTime);
                // Current month only
                if (dateTime.year == now.year && dateTime.month == now.month) {
                  presentCount++;
                  final minutesSinceMidnight =
                      dateTime.hour * 60 + dateTime.minute;
                  totalMinutes += minutesSinceMidnight;
                  validCheckIns++;
                }
              } catch (e) {
                print('Error parsing date: $e');
              }
            }
          }

          // Calculate average check-in time
          String avgCheckIn = '--:--';
          if (validCheckIns > 0) {
            final avgMinutes = (totalMinutes / validCheckIns).round();
            final avgHour = avgMinutes ~/ 60;
            final avgMinute = avgMinutes % 60;
            final displayHour = avgHour > 12
                ? avgHour - 12
                : (avgHour == 0 ? 12 : avgHour);
            final period = avgHour >= 12 ? 'PM' : 'AM';
            avgCheckIn =
                '${displayHour.toString().padLeft(2, '0')}:${avgMinute.toString().padLeft(2, '0')} $period';
          }

          // Calculate working days (exclude Sundays)
          int workingDays = 0;
          for (int day = 1; day <= now.day; day++) {
            final date = DateTime(now.year, now.month, day);
            if (date.weekday != DateTime.sunday) {
              workingDays++;
            }
          }

          setState(() {
            _todayAttendance = todayRecord;
            _allAttendance = records;
            _totalPresent = presentCount;
            _totalAbsent = workingDays - presentCount;
            _avgCheckIn = avgCheckIn;
          });

          print(
            '📈 Stats - Present: $presentCount, Absent: ${workingDays - presentCount}, Avg: $avgCheckIn',
          );
        }
      } else {
        print('❌ API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fetch error: $e');
    }
  }

  Future<String?> _getEmployeeId() async {
    // Try to get employee ID from current user
    final user = RealAuthService.instance.currentUser;
    print(
      '👤 Current user: ${user?.name}, ID: ${user?.id}, EmpId: ${user?.employeeDetails?.empId}',
    );

    if (user != null && user.employeeDetails?.empId != null) {
      return user.employeeDetails!.empId;
    }

    // Fallback to user id
    if (user != null && user.id != null) {
      return user.id;
    }

    // Try from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final empId = prefs.getString('emp_id');
    print('🔍 From prefs - user_id: $userId, emp_id: $empId');

    return empId ?? userId;
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatTimeFromString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    try {
      final time = DateTime.parse(timeStr);
      return _formatTime(time);
    } catch (e) {
      return '--:--';
    }
  }

  bool _isCheckedIn() {
    if (_todayAttendance == null) return false;
    return _todayAttendance!['checkin_time'] != null &&
        _todayAttendance!['checkout_time'] == null;
  }

  Future<void> _showTaskSuiteLogin() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isDialogLoading = false;

    // Pre-fill email if available
    final storedEmail = await TaskSuiteAuthService.instance.getStoredEmail();
    if (storedEmail != null) {
      emailController.text = storedEmail;
    } else {
      final user = RealAuthService.instance.currentUser;
      if (user != null && user.email != null) {
        emailController.text = user.email!;
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('TaskSuite Login'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your TaskSuite HRMS credentials to continue.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  if (isDialogLoading) ...[
                    SizedBox(height: 16),
                    CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
            actions: [
              if (!isDialogLoading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              if (!isDialogLoading)
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      setDialogState(() => isDialogLoading = true);

                      final result = await TaskSuiteAuthService.instance.login(
                        emailController.text.trim(),
                        passwordController.text,
                      );

                      if (!mounted) return;

                      setDialogState(() => isDialogLoading = false);

                      if (result.success) {
                        Navigator.pop(context); // Close dialog
                        _loadAttendanceData(); // Reload data
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.error ?? 'Login failed'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Login'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = RealAuthService.instance.currentUser;
    final userName = user?.name ?? 'User';

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Attendance',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.accentBlue),
            onPressed: _loadAttendanceData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.history, color: AppTheme.accentBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceHistoryPage(),
                ),
              );
            },
            tooltip: 'Attendance History',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentBlue),
                  SizedBox(height: 16),
                  Text('Loading attendance data...'),
                ],
              ),
            )
          : _authError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 80, color: Colors.orange),
                    SizedBox(height: 24),
                    Text(
                      'TaskSuite Login Required',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Please login with your TaskSuite HRMS credentials to access attendance.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showTaskSuiteLogin,
                      icon: Icon(Icons.login),
                      label: Text('Login to TaskSuite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadAttendanceData,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAttendanceData,
              color: AppTheme.accentBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentBlue,
                            const Color(0xFF5A8DEE),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentBlue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCheckedIn()
                                      ? Icons.check_circle
                                      : Icons.schedule,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCheckedIn()
                                      ? 'Currently Working'
                                      : 'Not Checked In',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Today's Attendance Card
                    Text(
                      'Today\'s Attendance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _TimeCard(
                                  icon: Icons.login_rounded,
                                  label: 'Check In',
                                  time: _formatTimeFromString(
                                    _todayAttendance?['checkin_time'],
                                  ),
                                  color: AppTheme.primaryGreen,
                                  isActive:
                                      _todayAttendance?['checkin_time'] != null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _TimeCard(
                                  icon: Icons.logout_rounded,
                                  label: 'Check Out',
                                  time: _formatTimeFromString(
                                    _todayAttendance?['checkout_time'],
                                  ),
                                  color: Colors.orange,
                                  isActive:
                                      _todayAttendance?['checkout_time'] !=
                                      null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CheckInPage(),
                                  ),
                                );
                                // Refresh after returning from check-in page
                                _loadAttendanceData();
                              },
                              icon: Icon(
                                _isCheckedIn()
                                    ? Icons.logout
                                    : Icons.fingerprint,
                              ),
                              label: Text(
                                _isCheckedIn()
                                    ? 'Check Out Now'
                                    : 'Check In Now',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isCheckedIn()
                                    ? Colors.orange
                                    : AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Section
                    Text(
                      'This Month\'s Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle_outline,
                            label: 'Present',
                            value: '$_totalPresent',
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.cancel_outlined,
                            label: 'Absent',
                            value: '$_totalAbsent',
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.access_time,
                            label: 'Avg Check-in',
                            value: _avgCheckIn,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.calendar_today,
                            label: 'Total Records',
                            value: '${_allAttendance.length}',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _QuickActionTile(
                      icon: Icons.history,
                      title: 'View Attendance History',
                      subtitle: 'Check your past attendance records',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AttendanceHistoryPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}

class _TimeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;
  final bool isActive;

  const _TimeCard({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isActive ? color : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.accentBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
