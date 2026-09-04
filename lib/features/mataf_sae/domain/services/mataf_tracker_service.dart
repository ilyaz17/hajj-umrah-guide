import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MatafTelemetry {
  const MatafTelemetry({
    required this.position,
    required this.deltaMeters,
    required this.totalDistanceMeters,
    this.headingDegrees,
  });

  final Position position;
  final double deltaMeters;
  final double totalDistanceMeters;
  final double? headingDegrees;
}

class MatafTrackerService {
  MatafTrackerService({
    GeolocatorPlatform? geolocator,
    Stream<MagnetometerEvent>? magnetometerStream,
  })  : _geolocator = geolocator ?? GeolocatorPlatform.instance,
        _magnetometerStream = magnetometerStream ?? magnetometerEventStream();

  final GeolocatorPlatform _geolocator;
  final Stream<MagnetometerEvent> _magnetometerStream;
  final _telemetryController = StreamController<MatafTelemetry>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  Position? _lastPosition;
  double _totalDistanceMeters = 0;
  double? _headingDegrees;
  bool _running = false;

  Stream<MatafTelemetry> get telemetry => _telemetryController.stream;
  bool get isRunning => _running;

  Future<bool> start() async {
    if (_running) return true;
    if (!await _ensurePermission()) return false;

    _running = true;
    _positionSubscription = _geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen(_handlePosition, onError: _telemetryController.addError);

    _magnetometerSubscription = _magnetometerStream.listen(
      _handleMagnetometer,
      onError: _telemetryController.addError,
    );
    return true;
  }

  void resetDistance() {
    _lastPosition = null;
    _totalDistanceMeters = 0;
  }

  Future<void> stop() async {
    _running = false;
    await _positionSubscription?.cancel();
    await _magnetometerSubscription?.cancel();
    _positionSubscription = null;
    _magnetometerSubscription = null;
  }

  void _handlePosition(Position position) {
    final previous = _lastPosition;
    final delta = previous == null
        ? 0.0
        : haversineMeters(
            previous.latitude,
            previous.longitude,
            position.latitude,
            position.longitude,
          );

    if (delta <= 50) {
      _totalDistanceMeters += delta;
    }
    _lastPosition = position;

    _telemetryController.add(MatafTelemetry(
      position: position,
      deltaMeters: delta,
      totalDistanceMeters: _totalDistanceMeters,
      headingDegrees: _headingDegrees,
    ));
  }

  void _handleMagnetometer(MagnetometerEvent event) {
    final radians = math.atan2(event.y, event.x);
    var degrees = radians * 180 / math.pi;
    if (degrees < 0) degrees += 360;

    // Low-pass smoothing reduces compass jitter while preserving direction changes.
    final previous = _headingDegrees;
    if (previous == null) {
      _headingDegrees = degrees;
    } else {
      final delta = ((degrees - previous + 540) % 360) - 180;
      _headingDegrees = (previous + delta * 0.2 + 360) % 360;
    }
  }

  Future<bool> _ensurePermission() async {
    if (!await _geolocator.isLocationServiceEnabled()) return false;
    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<void> dispose() async {
    await stop();
    await _telemetryController.close();
  }

  static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _radians(lat2 - lat1);
    final dLon = _radians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
