import 'package:flutter_test/flutter_test.dart';
import 'package:hajj_umrah_guide/features/geofencing/domain/geofence_service.dart';

void main() {
  group('GeofenceService.haversineMeters', () {
    test('returns zero for identical coordinates', () {
      expect(GeofenceService.haversineMeters(21.4225, 39.8262, 21.4225, 39.8262), closeTo(0, 0.001));
    });

    test('calculates a realistic short distance', () {
      final distance = GeofenceService.haversineMeters(21.4225, 39.8262, 21.4235, 39.8262);
      expect(distance, greaterThan(100));
      expect(distance, lessThan(120));
    });
  });
}
