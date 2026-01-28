import 'package:json_annotation/json_annotation.dart';

part 'location_models.g.dart';

enum LocationSource {
  gps,
  network,
  passive,
}

enum DutyEventType {
  start,
  end,
}

enum GeofenceEventType {
  enter,
  exit,
}

@JsonSerializable()
class LocationPoint {
  final double latitude;
  final double longitude;

  LocationPoint({
    required this.latitude,
    required this.longitude,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) =>
      _$LocationPointFromJson(json);

  Map<String, dynamic> toJson() => _$LocationPointToJson(this);
}

@JsonSerializable()
class LocationUpdate {
  final String agentId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final DateTime timestamp;
  final int? batteryLevel;
  final LocationSource source;

  LocationUpdate({
    required this.agentId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.timestamp,
    this.batteryLevel,
    required this.source,
  });

  factory LocationUpdate.fromJson(Map<String, dynamic> json) =>
      _$LocationUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$LocationUpdateToJson(this);
}

@JsonSerializable()
class DutyEvent {
  final String agentId;
  final DutyEventType eventType;
  final DateTime timestamp;
  final LocationPoint? location;

  DutyEvent({
    required this.agentId,
    required this.eventType,
    required this.timestamp,
    this.location,
  });

  factory DutyEvent.fromJson(Map<String, dynamic> json) =>
      _$DutyEventFromJson(json);

  Map<String, dynamic> toJson() => _$DutyEventToJson(this);
}

@JsonSerializable()
class GeofenceEvent {
  final String agentId;
  final String shopId;
  final String shopName;
  final GeofenceEventType eventType;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double distance;

  GeofenceEvent({
    required this.agentId,
    required this.shopId,
    required this.shopName,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.distance,
  });

  factory GeofenceEvent.fromJson(Map<String, dynamic> json) =>
      _$GeofenceEventFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceEventToJson(this);
}

@JsonSerializable()
class ShopLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  ShopLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory ShopLocation.fromJson(Map<String, dynamic> json) =>
      _$ShopLocationFromJson(json);

  Map<String, dynamic> toJson() => _$ShopLocationToJson(this);
}

@JsonSerializable()
class AgentLocationHistory {
  final String agentId;
  final String agentName;
  final List<LocationUpdate> locations;
  final DateTime? lastSeen;
  final bool isOnDuty;
  final DateTime? dutyStartTime;

  AgentLocationHistory({
    required this.agentId,
    required this.agentName,
    required this.locations,
    this.lastSeen,
    required this.isOnDuty,
    this.dutyStartTime,
  });

  factory AgentLocationHistory.fromJson(Map<String, dynamic> json) =>
      _$AgentLocationHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$AgentLocationHistoryToJson(this);
}

@JsonSerializable()
class LocationAlert {
  final String id;
  final String agentId;
  final String agentName;
  final AlertType alertType;
  final String message;
  final DateTime timestamp;
  final LocationPoint? location;
  final bool isResolved;

  LocationAlert({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.alertType,
    required this.message,
    required this.timestamp,
    this.location,
    required this.isResolved,
  });

  factory LocationAlert.fromJson(Map<String, dynamic> json) =>
      _$LocationAlertFromJson(json);

  Map<String, dynamic> toJson() => _$LocationAlertToJson(this);
}

enum AlertType {
  noUpdate,
  outOfTerritory,
  mockLocation,
  lowBattery,
  geofenceEntry,
  geofenceExit,
}