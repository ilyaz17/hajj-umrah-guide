import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajj_umrah_guide/core/models/geo_zone.dart';
import 'package:hajj_umrah_guide/features/geofencing/domain/geofence_service.dart';
import 'package:hajj_umrah_guide/features/ritual_tracker/presentation/bloc/ritual_tracker_bloc.dart';

class FakeGeofenceService extends GeofenceService {
  FakeGeofenceService() : super();
  @override
  Stream<GeofenceEvent> get events => const Stream.empty();
  @override
  Future<void> dispose() async {}
}

void main() {
  const zone = GeoZone(
    id: 'mina', name: 'Mina', latitude: 21.4, longitude: 39.9,
    enterRadiusMeters: 100, exitRadiusMeters: 150, message: 'Mina',
  );

  group('RitualTrackerBloc', () {
    blocTest<RitualTrackerBloc, RitualTrackerState>(
      'increments and caps circuit at 7',
      build: () => RitualTrackerBloc(geofenceService: FakeGeofenceService()),
      act: (bloc) {
        for (var i = 0; i < 8; i++) bloc.add(const IncrementCircuit());
      },
      expect: () => [
        const RitualTrackerState(circuit: 1),
        const RitualTrackerState(circuit: 2),
        const RitualTrackerState(circuit: 3),
        const RitualTrackerState(circuit: 4),
        const RitualTrackerState(circuit: 5),
        const RitualTrackerState(circuit: 6),
        const RitualTrackerState(circuit: 7),
      ],
    );

    blocTest<RitualTrackerBloc, RitualTrackerState>(
      'activates a zone on entry',
      build: () => RitualTrackerBloc(geofenceService: FakeGeofenceService()),
      act: (bloc) => bloc.add(const GeofenceUpdated(GeofenceEvent(zone: zone, distanceMeters: 42, entered: true))),
      expect: () => [
        const RitualTrackerState(activeZone: zone, lastDistanceMeters: 42, message: 'Mina'),
      ],
    );
  });
}
