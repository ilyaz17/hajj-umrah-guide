import 'package:equatable/equatable.dart';

class PilgrimageSite extends Equatable {
  const PilgrimageSite({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.type,
    this.description,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String type;
  final String? description;

  @override
  List<Object?> get props => [id, name, latitude, longitude, radiusMeters, type, description];
}
