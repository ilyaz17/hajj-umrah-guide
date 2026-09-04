import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../../core/models/geo_zone.dart';

class GeofenceEvent {
  const GeofenceEvent({required this.zone, required this.distanceMeters, required this.entered});
  final GeoZone zone;
  final double distanceMeters;
  final bool entered;
}

class GeofenceService {
  GeofenceService({GeolocatorPlatform? geolocator}) : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;
  final _events = StreamController<GeofenceEvent>.broadcast();
  StreamSubscription<Position>? _subscription;
  List<GeoZone> _zones = const [];
  final Set<String> _inside = <String>{};

  Stream<GeofenceEvent> get events => _events.stream;

  Future<void> start(List<GeoZone> zones) async {
    _zones = List.unmodifiable(zones);
    if (!await _ensurePermission()) return;
    await _subscription?.cancel();
    _subscription = _geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 20),
    ).listen(_handlePosition, onError: _events.addError);
  }

  void _handlePosition(Position position) {
    for (final zone in _zones) {
      final distance = haversineMeters(position.latitude, position.longitude, zone.latitude, zone.longitude);
      final wasInside = _inside.contains(zone.id);
      final nowInside = wasInside ? distance <= zone.exitRadiusMeters : distance <= zone.enterRadiusMeters;
      if (nowInside != wasInside) {
        if (nowInside) {
          _inside.add(zone.id);
        } else {
          _inside.remove(zone.id);
        }
        _events.add(GeofenceEvent(zone: zone, distanceMeters: distance, entered: nowInside));
      }
    }
  }

  Future<bool> _ensurePermission() async {
    if (!await _geolocator.isLocationServiceEnabled()) return false;
    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await _geolocator.requestPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _events.close();
  }

  static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _radians(lat2 - lat1);
    final dLon = _radians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(lat1)) * math.cos(_radians(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
