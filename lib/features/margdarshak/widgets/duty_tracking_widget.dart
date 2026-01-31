import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_tracking_service.dart';
import '../../../core/models/location_models.dart';

class DutyTrackingWidget extends StatefulWidget {
  const DutyTrackingWidget({super.key});

  @override
  State<DutyTrackingWidget> createState() => _DutyTrackingWidgetState();
}

class _DutyTrackingWidgetState extends State<DutyTrackingWidget> {
  final LocationTrackingService _locationService =
      LocationTrackingService.instance;
  final MapController _mapController = MapController();
  bool _isLoading = false;
  LocationUpdate? _lastLocationUpdate;
  bool _shouldRecenter = true;

  @override
  void initState() {
    super.initState();
    _setupLocationCallbacks();
    // Check if we already have a location
    if (_locationService.lastKnownPosition != null) {
      final pos = _locationService.lastKnownPosition!;
      _lastLocationUpdate = LocationUpdate(
        agentId: 'current',
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        speed: pos.speed,
        heading: pos.heading,
        timestamp: DateTime.now(),
        source: LocationSource.gps,
      );
    }
  }

  void _setupLocationCallbacks() {
    _locationService.onLocationUpdate = (locationUpdate) {
      if (mounted) {
        setState(() {
          _lastLocationUpdate = locationUpdate;
        });

        if (_shouldRecenter && _locationService.isOnDuty) {
          _mapController.move(
            LatLng(locationUpdate.latitude, locationUpdate.longitude),
            15.0,
          );
        }
      }
    };

    _locationService.onError = (error) {
      if (mounted) {
        _showErrorSnackBar(error);
      }
    };

    _locationService.onGeofenceEvent = (geofenceEvent) {
      if (mounted) {
        _showGeofenceAlert(geofenceEvent);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _locationService.isOnDuty
            ? const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF757575), Color(0xFF9E9E9E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                (_locationService.isOnDuty
                        ? const Color(0xFF4CAF50)
                        : Colors.grey)
                    .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _locationService.isOnDuty
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _locationService.isOnDuty ? 'On Duty' : 'Off Duty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStatusSubtitle(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_locationService.isOnDuty && _locationService.isTracking)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .fadeIn(duration: 1000.ms)
                          .then()
                          .fadeOut(duration: 1000.ms),
                      const SizedBox(width: 6),
                      const Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Live Map view
          if (_locationService.isOnDuty && _lastLocationUpdate != null) ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        _lastLocationUpdate!.latitude,
                        _lastLocationUpdate!.longitude,
                      ),
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () {
                        _mapController.move(
                          LatLng(
                            _lastLocationUpdate!.latitude,
                            _lastLocationUpdate!.longitude,
                          ),
                          15.0,
                        );
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.tmemployee.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _lastLocationUpdate!.latitude,
                              _lastLocationUpdate!.longitude,
                            ),
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Recenter button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        if (_lastLocationUpdate != null) {
                          _mapController.move(
                            LatLng(
                              _lastLocationUpdate!.latitude,
                              _lastLocationUpdate!.longitude,
                            ),
                            15.0,
                          );
                          setState(() => _shouldRecenter = true);
                        }
                      },
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Location Info Text
          if (_lastLocationUpdate != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.gps_fixed_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_lastLocationUpdate!.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        'Lng: ${_lastLocationUpdate!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.speed_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Speed: ${(_lastLocationUpdate!.speed * 3.6).toStringAsFixed(1)} km/h',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Accuracy: ${_lastLocationUpdate!.accuracy.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleDuty,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _locationService.isOnDuty
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      size: 20,
                    ),
              label: Text(
                _locationService.isOnDuty ? 'End Duty' : 'Start Duty',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _locationService.isOnDuty
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Battery Warning
          if (_locationService.isOnDuty &&
              _lastLocationUpdate?.batteryLevel != null) ...[
            const SizedBox(height: 12),
            if (_lastLocationUpdate!.batteryLevel! < 20)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.battery_alert_rounded,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Low battery: ${_lastLocationUpdate!.batteryLevel}%',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  String _getStatusSubtitle() {
    if (_locationService.isOnDuty) {
      final startTime = _locationService.dutyStartTime;
      if (startTime != null) {
        final duration = DateTime.now().difference(startTime);
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;
        return 'Active for ${hours}h ${minutes}m';
      }
      return 'Location tracking active';
    } else {
      final endTime = _locationService.dutyEndTime;
      if (endTime != null) {
        return 'Last duty ended at ${_formatTime(endTime)}';
      }
      return 'Tap to start tracking';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleDuty() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_locationService.isOnDuty) {
        success = await _locationService.endDuty();
        if (success) {
          _showSuccessSnackBar('Duty ended successfully');
        }
      } else {
        // Show consent dialog first
        final consent = await _showConsentDialog();
        if (!consent) {
          setState(() => _isLoading = false);
          return;
        }

        success = await _locationService.startDuty();
        if (success) {
          _showSuccessSnackBar('Duty started - Location tracking active');
          // Initial map recenter
          if (_lastLocationUpdate != null && mounted) {
            _mapController.move(
              LatLng(
                _lastLocationUpdate!.latitude,
                _lastLocationUpdate!.longitude,
              ),
              15.0,
            );
          }
        }
      }

      if (!success) {
        _showErrorSnackBar(
          'Failed to ${_locationService.isOnDuty ? 'end' : 'start'} duty',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showConsentDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Tracking Consent'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We collect your location while you are on duty to:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Text('• Support field operations'),
                Text('• Verify shop visits'),
                Text('• Calculate accurate payouts'),
                Text('• Ensure agent safety'),
                SizedBox(height: 12),
                Text(
                  'Location is only tracked during duty hours and can be stopped anytime.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Decline'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept & Start'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showGeofenceAlert(GeofenceEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shop Visit Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are near ${event.shopName}'),
            const SizedBox(height: 8),
            Text('Distance: ${event.distance.toStringAsFixed(0)}m'),
            const SizedBox(height: 12),
            const Text('Would you like to check in?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle check-in logic
            },
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }
}
