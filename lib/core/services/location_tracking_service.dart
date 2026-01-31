import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_models.dart';
import '../../features/margdarshak/services/margdarshak_api_service.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  static LocationTrackingService get instance => _instance;

  // Tracking state
  bool _isOnDuty = false;
  bool _isTracking = false;
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  Position? _lastKnownPosition;
  DateTime? _dutyStartTime;
  DateTime? _dutyEndTime;

  // Settings
  static const int _foregroundUpdateInterval = 30; // seconds
  static const double _accuracyThreshold = 100.0; // meters
  static const double _geofenceRadius = 100.0; // meters for shop check-ins

  // Callbacks
  Function(LocationUpdate)? onLocationUpdate;
  Function(GeofenceEvent)? onGeofenceEvent;
  Function(String)? onError;

  // Getters
  bool get isOnDuty => _isOnDuty;
  bool get isTracking => _isTracking;
  Position? get lastKnownPosition => _lastKnownPosition;
  DateTime? get dutyStartTime => _dutyStartTime;
  DateTime? get dutyEndTime => _dutyEndTime;

  /// Initialize location tracking service
  Future<bool> initialize() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        onError?.call('Location services are disabled');
        return false;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          onError?.call('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        onError?.call('Location permissions are permanently denied');
        return false;
      }

      // Request background location permission for Android
      if (Platform.isAndroid) {
        final backgroundPermission = await Permission.locationAlways.request();
        if (!backgroundPermission.isGranted) {
          debugPrint('Background location permission not granted');
        }
      }

      return true;
    } catch (e) {
      onError?.call('Failed to initialize location service: $e');
      return false;
    }
  }

  /// Start duty and begin location tracking
  Future<bool> startDuty({required File image, String? address}) async {
    if (_isOnDuty) return true;

    try {
      final initialized = await initialize();
      if (!initialized) return false;

      _isOnDuty = true;
      _dutyStartTime = DateTime.now();
      _dutyEndTime = null;

      // Start location tracking
      await _startLocationTracking();

      // Send duty start event to server (using current location)
      // Note: _sendDutyEvent now needs to handle the image and address
      // We wait for the first location fixed if not available
      if (_lastKnownPosition == null) {
        try {
          _lastKnownPosition = await Geolocator.getCurrentPosition();
        } catch (e) {
          debugPrint('Could not get current location for start duty');
        }
      }

      // Fetch address if specific address not provided
      if (address == null && _lastKnownPosition != null) {
        address = await _getAddress(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
        );
      }

      await _sendDutyEvent(DutyEventType.start, image: image, address: address);

      debugPrint('🟢 Duty started at ${_dutyStartTime}');
      return true;
    } catch (e) {
      String message = e.toString().replaceAll('Exception: ', '');
      onError?.call(message);
      _isOnDuty = false; // Revert state
      _stopLocationTracking();
      return false;
    }
  }

  /// End duty and stop location tracking
  Future<bool> endDuty({required File image, String? address}) async {
    if (!_isOnDuty) return true;

    try {
      _isOnDuty = false;
      _dutyEndTime = DateTime.now();

      // Stop location tracking
      await _stopLocationTracking();

      // Fetch address if not provided (using last known position)
      if (address == null && _lastKnownPosition != null) {
        address = await _getAddress(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
        );
      }

      // Send duty end event to server
      await _sendDutyEvent(DutyEventType.end, image: image, address: address);

      debugPrint('🔴 Duty ended at ${_dutyEndTime}');
      return true;
    } catch (e) {
      String message = e.toString().replaceAll('Exception: ', '');
      onError?.call(message);
      return false;
    }
  }

  /// Start location tracking
  Future<void> _startLocationTracking() async {
    if (_isTracking) return;

    _isTracking = true;

    // Configure location settings
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update when moved 10 meters
    );

    // Start position stream
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          _handlePositionUpdate,
          onError: (error) {
            onError?.call('Location stream error: $error');
          },
        );

    // Also start periodic updates as backup
    _startPeriodicUpdates();
  }

  /// Stop location tracking
  Future<void> _stopLocationTracking() async {
    _isTracking = false;

    await _positionStream?.cancel();
    _positionStream = null;

    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// Start periodic location updates
  void _startPeriodicUpdates() {
    final interval = Duration(seconds: _foregroundUpdateInterval);

    _locationTimer = Timer.periodic(interval, (timer) async {
      if (!_isOnDuty || !_isTracking) {
        timer.cancel();
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _handlePositionUpdate(position);
      } catch (e) {
        debugPrint('Periodic location update failed: $e');
      }
    });
  }

  /// Handle position updates
  Future<void> _handlePositionUpdate(Position position) async {
    // Filter out inaccurate readings
    if (position.accuracy > _accuracyThreshold) {
      debugPrint('Ignoring inaccurate location: ${position.accuracy}m');
      return;
    }

    // Detect potential mock locations (basic check)
    if (_isLikelyMockLocation(position)) {
      onError?.call('Mock location detected');
      return;
    }

    _lastKnownPosition = position;

    // Create location update
    final locationUpdate = LocationUpdate(
      agentId: _getCurrentAgentId(),
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      // Filter out speed noise (less than ~1.8 km/h)
      speed: position.speed < 0.5 ? 0.0 : position.speed,
      heading: position.heading,
      timestamp: DateTime.now(),
      batteryLevel: await _getBatteryLevel(), // Actually fetch battery level
      source: LocationSource.gps,
    );

    // Send to server
    _sendLocationUpdate(locationUpdate);

    // Trigger callback
    onLocationUpdate?.call(locationUpdate);

    // Check for geofence events
    _checkGeofences(position);
  }

  /// Check for geofence events (shop visits)
  void _checkGeofences(Position position) {
    // This would check against known shop locations
    // For now, we'll simulate with mock data
    final mockShops = _getMockShopLocations();

    for (final shop in mockShops) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        shop.latitude,
        shop.longitude,
      );

      if (distance <= _geofenceRadius) {
        final geofenceEvent = GeofenceEvent(
          agentId: _getCurrentAgentId(),
          shopId: shop.id,
          shopName: shop.name,
          eventType: GeofenceEventType.enter,
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          distance: distance,
        );

        onGeofenceEvent?.call(geofenceEvent);
        _sendGeofenceEvent(geofenceEvent);
      }
    }
  }

  /// Basic mock location detection
  bool _isLikelyMockLocation(Position position) {
    if (_lastKnownPosition == null) return false;

    // Check for impossible speed (teleportation)
    final distance = Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    final timeDiff = DateTime.now()
        .difference(
          DateTime.fromMillisecondsSinceEpoch(
            _lastKnownPosition!.timestamp.millisecondsSinceEpoch,
          ),
        )
        .inSeconds;

    if (timeDiff > 0) {
      final speed = distance / timeDiff; // m/s
      const maxReasonableSpeed = 50.0; // 50 m/s = 180 km/h

      if (speed > maxReasonableSpeed) {
        debugPrint(
          'Suspicious speed detected: ${speed.toStringAsFixed(2)} m/s',
        );
        return true;
      }
    }

    return false;
  }

  /// Send location update to server
  Future<void> _sendLocationUpdate(LocationUpdate update) async {
    try {
      await MargdarshakApiService().updateRealtimeLocation(
        latitude: update.latitude,
        longitude: update.longitude,
        accuracy: update.accuracy,
        speed: update.speed,
        heading: update.heading,
        batteryLevel: update.batteryLevel,
        // We could reverse geocode here but it might be expensive
        // leaving address as null for periodic updates unless necessary
      );
      debugPrint('Sending location update: ${update.toJson()}');
    } catch (e) {
      debugPrint('Failed to send location update: $e');
    }
  }

  /// Send duty event to server
  Future<void> _sendDutyEvent(
    DutyEventType eventType, {
    required File image,
    String? address,
  }) async {
    try {
      if (_lastKnownPosition == null) {
        throw Exception('Location not available for duty event');
      }

      await MargdarshakApiService().startStopDuty(
        status: eventType == DutyEventType.start ? 'start' : 'stop',
        latitude: _lastKnownPosition!.latitude,
        longitude: _lastKnownPosition!.longitude,
        image: image,
        locationAddress: address,
      );

      debugPrint('Sent duty event: $eventType');
    } catch (e) {
      debugPrint('Failed to send duty event: $e');
      rethrow; // Rethrow to notify UI
    }
  }

  /// Send geofence event to server
  Future<void> _sendGeofenceEvent(GeofenceEvent event) async {
    try {
      // TODO: Replace with actual API call
      // await ApiService.post('/agent/geofence', event.toJson());
      debugPrint('Sending geofence event: ${event.toJson()}');
    } catch (e) {
      debugPrint('Failed to send geofence event: $e');
    }
  }

  /// Get current agent ID (from auth service)
  String _getCurrentAgentId() {
    // This would get the actual agent ID from your auth service
    return 'agent_123'; // Mock for now
  }

  /// Get battery level using battery_plus
  Future<int> _getBatteryLevel() async {
    try {
      final Battery battery = Battery();
      return await battery.batteryLevel;
    } catch (e) {
      debugPrint('Failed to get battery level: $e');
      return 0;
    }
  }

  /// Get mock shop locations for geofencing
  List<ShopLocation> _getMockShopLocations() {
    return [
      ShopLocation(
        id: '1',
        name: 'Sharma Dhaba',
        latitude: 18.5204,
        longitude: 73.8567,
      ),
      ShopLocation(
        id: '2',
        name: 'Quick Fix Puncture',
        latitude: 18.5104,
        longitude: 73.8467,
      ),
    ];
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      final initialized = await initialize();
      if (!initialized) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      onError?.call('Failed to get current location: $e');
      return null;
    }
  }

  /// Calculate distance to shop
  double? getDistanceToShop(double shopLat, double shopLng) {
    if (_lastKnownPosition == null) return null;

    return Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      shopLat,
      shopLng,
    );
  }

  /// Get address from coordinates
  Future<String?> _getAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Format: Name, SubLocality, Locality, AdministrativeArea
        // Example: Connaught Place, New Delhi
        List<String> parts = [];
        if (place.name != null && place.name!.isNotEmpty)
          parts.add(place.name!);
        if (place.subLocality != null &&
            place.subLocality!.isNotEmpty &&
            place.subLocality != place.name) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty)
          parts.add(place.locality!);
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }

        return parts.join(', ');
      }
    } catch (e) {
      debugPrint('Failed to get address: $e');
    }
    return null;
  }

  /// Dispose resources
  void dispose() {
    _stopLocationTracking();
  }
}
