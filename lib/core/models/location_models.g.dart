// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationPoint _$LocationPointFromJson(Map<String, dynamic> json) =>
    LocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$LocationPointToJson(LocationPoint instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

LocationUpdate _$LocationUpdateFromJson(Map<String, dynamic> json) =>
    LocationUpdate(
      agentId: json['agentId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      batteryLevel: json['batteryLevel'] as int?,
      source: $enumDecode(_$LocationSourceEnumMap, json['source']),
    );

Map<String, dynamic> _$LocationUpdateToJson(LocationUpdate instance) =>
    <String, dynamic>{
      'agentId': instance.agentId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'speed': instance.speed,
      'heading': instance.heading,
      'timestamp': instance.timestamp.toIso8601String(),
      'batteryLevel': instance.batteryLevel,
      'source': _$LocationSourceEnumMap[instance.source]!,
    };

const _$LocationSourceEnumMap = {
  LocationSource.gps: 'gps',
  LocationSource.network: 'network',
  LocationSource.passive: 'passive',
};

DutyEvent _$DutyEventFromJson(Map<String, dynamic> json) => DutyEvent(
      agentId: json['agentId'] as String,
      eventType: $enumDecode(_$DutyEventTypeEnumMap, json['eventType']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: json['location'] == null
          ? null
          : LocationPoint.fromJson(json['location'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DutyEventToJson(DutyEvent instance) => <String, dynamic>{
      'agentId': instance.agentId,
      'eventType': _$DutyEventTypeEnumMap[instance.eventType]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'location': instance.location?.toJson(),
    };

const _$DutyEventTypeEnumMap = {
  DutyEventType.start: 'start',
  DutyEventType.end: 'end',
};

GeofenceEvent _$GeofenceEventFromJson(Map<String, dynamic> json) =>
    GeofenceEvent(
      agentId: json['agentId'] as String,
      shopId: json['shopId'] as String,
      shopName: json['shopName'] as String,
      eventType: $enumDecode(_$GeofenceEventTypeEnumMap, json['eventType']),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      distance: (json['distance'] as num).toDouble(),
    );

Map<String, dynamic> _$GeofenceEventToJson(GeofenceEvent instance) =>
    <String, dynamic>{
      'agentId': instance.agentId,
      'shopId': instance.shopId,
      'shopName': instance.shopName,
      'eventType': _$GeofenceEventTypeEnumMap[instance.eventType]!,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp.toIso8601String(),
      'distance': instance.distance,
    };

const _$GeofenceEventTypeEnumMap = {
  GeofenceEventType.enter: 'enter',
  GeofenceEventType.exit: 'exit',
};

ShopLocation _$ShopLocationFromJson(Map<String, dynamic> json) => ShopLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$ShopLocationToJson(ShopLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

AgentLocationHistory _$AgentLocationHistoryFromJson(
        Map<String, dynamic> json) =>
    AgentLocationHistory(
      agentId: json['agentId'] as String,
      agentName: json['agentName'] as String,
      locations: (json['locations'] as List<dynamic>)
          .map((e) => LocationUpdate.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.parse(json['lastSeen'] as String),
      isOnDuty: json['isOnDuty'] as bool,
      dutyStartTime: json['dutyStartTime'] == null
          ? null
          : DateTime.parse(json['dutyStartTime'] as String),
    );

Map<String, dynamic> _$AgentLocationHistoryToJson(
        AgentLocationHistory instance) =>
    <String, dynamic>{
      'agentId': instance.agentId,
      'agentName': instance.agentName,
      'locations': instance.locations.map((e) => e.toJson()).toList(),
      'lastSeen': instance.lastSeen?.toIso8601String(),
      'isOnDuty': instance.isOnDuty,
      'dutyStartTime': instance.dutyStartTime?.toIso8601String(),
    };

LocationAlert _$LocationAlertFromJson(Map<String, dynamic> json) =>
    LocationAlert(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      agentName: json['agentName'] as String,
      alertType: $enumDecode(_$AlertTypeEnumMap, json['alertType']),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: json['location'] == null
          ? null
          : LocationPoint.fromJson(json['location'] as Map<String, dynamic>),
      isResolved: json['isResolved'] as bool,
    );

Map<String, dynamic> _$LocationAlertToJson(LocationAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'agentId': instance.agentId,
      'agentName': instance.agentName,
      'alertType': _$AlertTypeEnumMap[instance.alertType]!,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'location': instance.location?.toJson(),
      'isResolved': instance.isResolved,
    };

const _$AlertTypeEnumMap = {
  AlertType.noUpdate: 'noUpdate',
  AlertType.outOfTerritory: 'outOfTerritory',
  AlertType.mockLocation: 'mockLocation',
  AlertType.lowBattery: 'lowBattery',
  AlertType.geofenceEntry: 'geofenceEntry',
  AlertType.geofenceExit: 'geofenceExit',
};

T $enumDecode<T>(
  Map<T, Object> enumValues,
  Object? source, {
  T? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, source);
    },
  ).key;
}