import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajj_umrah_guide/features/mataf_sae/domain/models/ritual_counter_type.dart';
import 'package:hajj_umrah_guide/features/mataf_sae/domain/services/mataf_tracker_service.dart';
import 'package:hajj_umrah_guide/features/mataf_sae/presentation/bloc/mataf_sae_bloc.dart';

class FakeMatafTrackerService extends MatafTrackerService {
  FakeMatafTrackerService() : super();

  @override
  Stream<MatafTelemetry> get telemetry => const Stream.empty();

  @override
  Future<bool> start() async => true;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  group('MatafSaeBloc', () {
    blocTest<MatafSaeBloc, MatafSaeState>(
      'switches to Sa’i and resets the counter',
      build: () => MatafSaeBloc(trackerService: FakeMatafTrackerService()),
      seed: () => const MatafSaeState(circuit: 4),
      act: (bloc) => bloc.add(const SelectRitual(RitualCounterType.sae)),
      expect: () => [
        const MatafSaeState(ritual: RitualCounterType.sae),
      ],
    );

    blocTest<MatafSaeBloc, MatafSaeState>(
      'increments to seven and never exceeds seven',
      build: () => MatafSaeBloc(trackerService: FakeMatafTrackerService()),
      act: (bloc) {
        for (var i = 0; i < 8; i++) {
          bloc.add(const IncrementCircuit());
        }
      },
      expect: () => [
        const MatafSaeState(circuit: 1),
        const MatafSaeState(circuit: 2),
        const MatafSaeState(circuit: 3),
        const MatafSaeState(circuit: 4),
        const MatafSaeState(circuit: 5),
        const MatafSaeState(circuit: 6),
        const MatafSaeState(circuit: 7),
      ],
    );
  });
}
