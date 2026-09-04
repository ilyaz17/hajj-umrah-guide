import 'package:equatable/equatable.dart';

class GeoZone extends Equatable {
  const GeoZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.enterRadiusMeters,
    required this.exitRadiusMeters,
    required this.message,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double enterRadiusMeters;
  final double exitRadiusMeters;
  final String message;

  @override
  List<Object> get props => [id, name, latitude, longitude, enterRadiusMeters, exitRadiusMeters, message];
}
