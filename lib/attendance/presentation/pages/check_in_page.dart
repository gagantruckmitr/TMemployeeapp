import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/tasksuite_auth_service.dart';
import '../providers/attendance_provider.dart';

class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key});

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  File? _selfieImage;
  final ImagePicker _picker = ImagePicker();

  // Location variables
  Position? _currentPosition;
  String? _currentAddress;
  String _locationStatus = 'Getting location...';
  bool _isGettingLocation = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationStatus = 'Getting location...';
      _isGettingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Please enable location services';
          _isGettingLocation = false;
        });

        // Show snackbar with option to open settings
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location services are disabled'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Enable',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Location permission denied';
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Location permission permanently denied';
          _isGettingLocation = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please enable location permission in app settings',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // Get current position directly
      setState(() {
        _locationStatus = 'Fetching GPS coordinates...';
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(
        '📍 Location obtained: ${position.latitude}, ${position.longitude}',
      );

      // Get address from coordinates
      String address =
          'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          print('📍 Address: $address');
        }
      } catch (e) {
        print('⚠️ Address lookup failed: $e');
        // Keep the coordinates as address
      }

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentAddress = address;
          _locationStatus = 'Location acquired ✓';
          _isGettingLocation = false;
        });
      }
    } catch (e) {
      print('❌ Location error: $e');
      if (mounted) {
        setState(() {
          _locationStatus = 'Failed to get location';
          _isGettingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location error: ${e.toString().split(':').last.trim()}',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selfieImage = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking selfie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime time) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[time.weekday - 1]}, ${time.day} ${months[time.month - 1]} ${time.year}';
  }

  Future<String?> _getEmployeeId() async {
    // Try to get employee ID from TaskSuite auth first
    final taskSuiteUser = TaskSuiteAuthService.instance.user;
    if (taskSuiteUser != null && taskSuiteUser['id'] != null) {
      return taskSuiteUser['id'].toString();
    }

    // Try to get employee ID from current user
    final user = RealAuthService.instance.currentUser;
    if (user != null && user.employeeDetails?.empId != null) {
      return user.employeeDetails!.empId;
    }

    // Fallback to user id
    if (user != null) {
      return user.id;
    }

    // Try from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? prefs.getString('emp_id');
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceStateProvider);
    final bool canCheckIn = _selfieImage != null && _currentPosition != null;
    final bool canCheckOut = _currentPosition != null && !_isGettingLocation;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      attendanceState.isCheckedIn
                          ? 'Check Out Your Presence'
                          : 'Check In Your Presence',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            // Selfie Area
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accentBlue.withOpacity(0.95),
                      width: 12,
                    ),
                  ),
                ),
                if (_selfieImage != null)
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 4,
                      ),
                      image: DecorationImage(
                        image: FileImage(_selfieImage!),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _takeSelfie,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.cardBackground,
                            border: Border.all(
                              color: AppTheme.accentBlue.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to Take Selfie',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Required for attendance',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (_selfieImage != null)
              TextButton.icon(
                onPressed: _takeSelfie,
                icon: Icon(Icons.refresh, color: AppTheme.accentBlue, size: 20),
                label: Text(
                  'Retake Selfie',
                  style: TextStyle(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Location Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _currentPosition != null
                            ? Icons.location_on
                            : Icons.location_searching,
                        color: _currentPosition != null
                            ? AppTheme.primaryGreen
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentPosition != null
                            ? 'Location acquired'
                            : _locationStatus,
                        style: TextStyle(
                          color: _currentPosition != null
                              ? AppTheme.primaryGreen
                              : Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if (_currentPosition != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _currentAddress ?? 'Fetching address...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_currentPosition!.accuracy > 0)
                      Text(
                        'Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(0)}m',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date & Time
            Text(
              _formatDate(_currentTime),
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            Text(
              _formatTime(_currentTime),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const Spacer(),

            // Swipe Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _SwipeToCheckIn(
                isCheckedIn: attendanceState.isCheckedIn,
                isEnabled: attendanceState.isCheckedIn
                    ? canCheckOut
                    : canCheckIn,
                onSwipeComplete: () async {
                  if (attendanceState.isCheckedIn && !canCheckOut) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fetching location... Please wait'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  if (!attendanceState.isCheckedIn && !canCheckIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please take a selfie and allow location access',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final employeeId = await _getEmployeeId();

                  if (employeeId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Employee ID not found'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final wasCheckedIn = attendanceState.isCheckedIn;

                  if (wasCheckedIn) {
                    await ref
                        .read(attendanceStateProvider.notifier)
                        .checkOut(
                          employeeId,
                          latitude: _currentPosition?.latitude,
                          longitude: _currentPosition?.longitude,
                          locationAccuracy: _currentPosition?.accuracy,
                          address: _currentAddress,
                        );
                  } else {
                    await ref
                        .read(attendanceStateProvider.notifier)
                        .checkIn(
                          employeeId,
                          selfiePath: _selfieImage?.path,
                          latitude: _currentPosition?.latitude,
                          longitude: _currentPosition?.longitude,
                          locationAccuracy: _currentPosition?.accuracy,
                          address: _currentAddress,
                        );
                  }

                  final newState = ref.read(attendanceStateProvider);

                  if (!mounted) return;

                  if (newState.errorMessage != null) {
                    final isInfo = newState.errorMessage!
                        .toLowerCase()
                        .contains('already');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(newState.errorMessage!),
                        backgroundColor: isInfo
                            ? AppTheme.accentBlue
                            : Colors.red,
                      ),
                    );
                  } else if (newState.successMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(newState.successMessage!),
                        backgroundColor: AppTheme.accentBlue,
                      ),
                    );
                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (mounted) context.pop();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _SwipeToCheckIn remains exactly the same as your original
class _SwipeToCheckIn extends StatefulWidget {
  final VoidCallback onSwipeComplete;
  final bool isCheckedIn;
  final bool isEnabled;

  const _SwipeToCheckIn({
    required this.onSwipeComplete,
    required this.isCheckedIn,
    this.isEnabled = true,
  });

  @override
  State<_SwipeToCheckIn> createState() => _SwipeToCheckInState();
}

class _SwipeToCheckInState extends State<_SwipeToCheckIn> {
  double _dragPosition = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final buttonSize = 60.0;
        final maxDrag = containerWidth - buttonSize - 10;
        final progress = maxDrag > 0 ? _dragPosition / maxDrag : 0.0;
        final swipeColor = widget.isCheckedIn
            ? Colors.orange
            : AppTheme.primaryGreen;

        return Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(35),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _dragPosition + 70,
                height: 70,
                decoration: BoxDecoration(
                  color: swipeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              Center(
                child: Text(
                  widget.isCheckedIn
                      ? 'Swipe to Punch Out'
                      : 'Swipe to Punch In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isEnabled
                        ? AppTheme.textPrimary.withOpacity(1 - progress)
                        : AppTheme.textSecondary.withOpacity(0.5),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                left: _dragPosition + 5,
                top: 5,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.isEnabled
                      ? (details) {
                          setState(() {
                            _dragPosition = (_dragPosition + details.delta.dx)
                                .clamp(0.0, maxDrag);
                          });
                        }
                      : null,
                  onHorizontalDragEnd: widget.isEnabled
                      ? (details) {
                          if (_dragPosition > maxDrag * 0.8) {
                            setState(() {
                              _dragPosition = maxDrag;
                            });
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              widget.onSwipeComplete,
                            );
                          } else {
                            setState(() {
                              _dragPosition = 0;
                            });
                          }
                        }
                      : null,
                  child: Opacity(
                    opacity: widget.isEnabled ? 1.0 : 0.5,
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        color: swipeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isCheckedIn ? Icons.logout : Icons.arrow_forward,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
