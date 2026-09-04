import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/services/ritual_audio_service.dart';
import '../../domain/models/circuit_guidance.dart';
import '../../domain/models/ritual_counter_type.dart';
import '../../domain/services/mataf_tracker_service.dart';

sealed class MatafSaeEvent extends Equatable {
  const MatafSaeEvent();

  @override
  List<Object?> get props => [];
}

final class SelectRitual extends MatafSaeEvent {
  const SelectRitual(this.ritual);
  final RitualCounterType ritual;

  @override
  List<Object?> get props => [ritual];
}

final class StartTracking extends MatafSaeEvent {
  const StartTracking();
}

final class StopTracking extends MatafSaeEvent {
  const StopTracking();
}

final class TelemetryReceived extends MatafSaeEvent {
  const TelemetryReceived(this.telemetry);
  final MatafTelemetry telemetry;

  @override
  List<Object?> get props => [telemetry.position.timestamp, telemetry.totalDistanceMeters, telemetry.headingDegrees];
}

final class IncrementCircuit extends MatafSaeEvent {
  const IncrementCircuit();
}

final class DecrementCircuit extends MatafSaeEvent {
  const DecrementCircuit();
}

final class ResetCircuit extends MatafSaeEvent {
  const ResetCircuit();
}

final class ToggleArabic extends MatafSaeEvent {
  const ToggleArabic();
}

final class ToggleTransliteration extends MatafSaeEvent {
  const ToggleTransliteration();
}

final class ToggleAudio extends MatafSaeEvent {
  const ToggleAudio();
}

final class SpeakGuidance extends MatafSaeEvent {
  const SpeakGuidance();
}

class MatafSaeState extends Equatable {
  const MatafSaeState({
    this.ritual = RitualCounterType.tawaf,
    this.circuit = 0,
    this.tracking = false,
    this.manualOverride = true,
    this.showArabic = true,
    this.showTransliteration = true,
    this.audioEnabled = false,
    this.distanceMeters = 0,
    this.lastDeltaMeters = 0,
    this.headingDegrees,
    this.latitude,
    this.longitude,
    this.errorMessage,
  });

  final RitualCounterType ritual;
  final int circuit;
  final bool tracking;
  final bool manualOverride;
  final bool showArabic;
  final bool showTransliteration;
  final bool audioEnabled;
  final double distanceMeters;
  final double lastDeltaMeters;
  final double? headingDegrees;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  CircuitGuidance get guidance => guidanceForCircuit(ritual, circuit);
  int get completed => circuit;
  bool get complete => circuit == 7;

  MatafSaeState copyWith({
    RitualCounterType? ritual,
    int? circuit,
    bool? tracking,
    bool? manualOverride,
    bool? showArabic,
    bool? showTransliteration,
    bool? audioEnabled,
    double? distanceMeters,
    double? lastDeltaMeters,
    double? headingDegrees,
    double? latitude,
    double? longitude,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MatafSaeState(
      ritual: ritual ?? this.ritual,
      circuit: circuit ?? this.circuit,
      tracking: tracking ?? this.tracking,
      manualOverride: manualOverride ?? this.manualOverride,
      showArabic: showArabic ?? this.showArabic,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      lastDeltaMeters: lastDeltaMeters ?? this.lastDeltaMeters,
      headingDegrees: headingDegrees ?? this.headingDegrees,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        ritual,
        circuit,
        tracking,
        manualOverride,
        showArabic,
        showTransliteration,
        audioEnabled,
        distanceMeters,
        lastDeltaMeters,
        headingDegrees,
        latitude,
        longitude,
        errorMessage,
      ];
}

class MatafSaeBloc extends Bloc<MatafSaeEvent, MatafSaeState> {
  MatafSaeBloc({
    required MatafTrackerService trackerService,
    RitualAudioService? audioService,
  })  : _trackerService = trackerService,
        _audioService = audioService ?? RitualAudioService(),
        super(const MatafSaeState()) {
    on<SelectRitual>(_onSelectRitual);
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<TelemetryReceived>(_onTelemetryReceived);
    on<IncrementCircuit>(_onIncrement);
    on<DecrementCircuit>(_onDecrement);
    on<ResetCircuit>(_onReset);
    on<ToggleArabic>((event, emit) => emit(state.copyWith(showArabic: !state.showArabic)));
    on<ToggleTransliteration>((event, emit) => emit(state.copyWith(showTransliteration: !state.showTransliteration)));
    on<ToggleAudio>(_onToggleAudio);
    on<SpeakGuidance>(_onSpeakGuidance);
    _subscription = _trackerService.telemetry.listen((telemetry) => add(TelemetryReceived(telemetry)));
  }

  final MatafTrackerService _trackerService;
  final RitualAudioService _audioService;
  StreamSubscription<MatafTelemetry>? _subscription;

  void _onSelectRitual(SelectRitual event, Emitter<MatafSaeState> emit) {
    emit(state.copyWith(ritual: event.ritual, circuit: 0, distanceMeters: 0, clearError: true));
    _trackerService.resetDistance();
  }

  Future<void> _onStartTracking(StartTracking event, Emitter<MatafSaeState> emit) async {
    final started = await _trackerService.start();
    emit(state.copyWith(
      tracking: started,
      errorMessage: started ? null : 'Location permission or location services are unavailable.',
      clearError: started,
    ));
  }

  Future<void> _onStopTracking(StopTracking event, Emitter<MatafSaeState> emit) async {
    await _trackerService.stop();
    emit(state.copyWith(tracking: false));
  }

  void _onTelemetryReceived(TelemetryReceived event, Emitter<MatafSaeState> emit) {
    final telemetry = event.telemetry;
    emit(state.copyWith(
      distanceMeters: telemetry.totalDistanceMeters,
      lastDeltaMeters: telemetry.deltaMeters,
      headingDegrees: telemetry.headingDegrees,
      latitude: telemetry.position.latitude,
      longitude: telemetry.position.longitude,
      clearError: true,
    ));
  }

  void _onIncrement(IncrementCircuit event, Emitter<MatafSaeState> emit) {
    if (state.circuit < 7) emit(state.copyWith(circuit: state.circuit + 1));
  }

  void _onDecrement(DecrementCircuit event, Emitter<MatafSaeState> emit) {
    if (state.circuit > 0) emit(state.copyWith(circuit: state.circuit - 1));
  }

  void _onReset(ResetCircuit event, Emitter<MatafSaeState> emit) {
    _trackerService.resetDistance();
    emit(state.copyWith(circuit: 0, distanceMeters: 0, lastDeltaMeters: 0));
  }

  Future<void> _onToggleAudio(ToggleAudio event, Emitter<MatafSaeState> emit) async {
    final enabled = !state.audioEnabled;
    emit(state.copyWith(audioEnabled: enabled));
    if (enabled) {
      await _audioService.configure();
      await _speakCurrentGuidance();
    } else {
      await _audioService.stop();
    }
  }

  Future<void> _onSpeakGuidance(SpeakGuidance event, Emitter<MatafSaeState> emit) async {
    if (!state.audioEnabled) return;
    await _speakCurrentGuidance();
  }

  Future<void> _speakCurrentGuidance() async {
    final guidance = state.guidance;
    final text = '${guidance.title}. ${guidance.sunnah} ${guidance.guidance}';
    await _audioService.speak(text);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _trackerService.dispose();
    await _audioService.dispose();
    return super.close();
  }
}
