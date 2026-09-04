import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/geo_zone.dart';
import '../../geofencing/domain/geofence_service.dart';

e sealed class RitualTrackerEvent extends Equatable {
  const RitualTrackerEvent();
  @override
  List<Object?> get props => [];
}

final class GeofenceUpdated extends RitualTrackerEvent {
  const GeofenceUpdated(this.event);
  final GeofenceEvent event;
  @override
  List<Object?> get props => [event.zone.id, event.distanceMeters, event.entered];
}

final class IncrementCircuit extends RitualTrackerEvent {
  const IncrementCircuit();
}

final class DecrementCircuit extends RitualTrackerEvent {
  const DecrementCircuit();
}

final class ResetCircuits extends RitualTrackerEvent {
  const ResetCircuits();
}

class RitualTrackerState extends Equatable {
  const RitualTrackerState({this.activeZone, this.circuit = 0, this.lastDistanceMeters, this.message});

  final GeoZone? activeZone;
  final int circuit;
  final double? lastDistanceMeters;
  final String? message;

  RitualTrackerState copyWith({GeoZone? activeZone, bool clearZone = false, int? circuit, double? lastDistanceMeters, String? message}) =>
      RitualTrackerState(
        activeZone: clearZone ? null : activeZone ?? this.activeZone,
        circuit: circuit ?? this.circuit,
        lastDistanceMeters: lastDistanceMeters ?? this.lastDistanceMeters,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props => [activeZone, circuit, lastDistanceMeters, message];
}

class RitualTrackerBloc extends Bloc<RitualTrackerEvent, RitualTrackerState> {
  RitualTrackerBloc({required GeofenceService geofenceService}) : _geofenceService = geofenceService, super(const RitualTrackerState()) {
    on<GeofenceUpdated>(_onGeofenceUpdated);
    on<IncrementCircuit>(_onIncrement);
    on<DecrementCircuit>(_onDecrement);
    on<ResetCircuits>((event, emit) => emit(state.copyWith(circuit: 0)));
    _subscription = geofenceService.events.listen((event) => add(GeofenceUpdated(event)));
  }

  final GeofenceService _geofenceService;
  StreamSubscription<GeofenceEvent>? _subscription;

  void _onGeofenceUpdated(GeofenceUpdated event, Emitter<RitualTrackerState> emit) {
    emit(state.copyWith(
      activeZone: event.event.entered ? event.event.zone : null,
      clearZone: !event.event.entered,
      lastDistanceMeters: event.event.distanceMeters,
      message: event.event.entered ? event.event.zone.message : null,
    ));
  }

  void _onIncrement(IncrementCircuit event, Emitter<RitualTrackerState> emit) {
    if (state.circuit < 7) emit(state.copyWith(circuit: state.circuit + 1));
  }

  void _onDecrement(DecrementCircuit event, Emitter<RitualTrackerState> emit) {
    if (state.circuit > 0) emit(state.copyWith(circuit: state.circuit - 1));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _geofenceService.dispose();
    return super.close();
  }
}
