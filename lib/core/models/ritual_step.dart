import 'package:equatable/equatable.dart';

enum PilgrimageType { umrah, hajjTamattu, hajjQiran, hajjIfrad }

class RitualStep extends Equatable {
  const RitualStep({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.pilgrimageTypes,
    this.duaArabic,
    this.duaTransliteration,
  });

  final String id;
  final String title;
  final String description;
  final int order;
  final Set<PilgrimageType> pilgrimageTypes;
  final String? duaArabic;
  final String? duaTransliteration;

  @override
  List<Object?> get props => [id, title, description, order, pilgrimageTypes, duaArabic, duaTransliteration];
}
