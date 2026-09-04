enum RitualCounterType {
  tawaf,
  sae,
}

extension RitualCounterTypeX on RitualCounterType {
  String get label => switch (this) {
        RitualCounterType.tawaf => 'Tawaf',
        RitualCounterType.sae => 'Sa’i',
      };

  String get startPoint => switch (this) {
        RitualCounterType.tawaf => 'Black Stone (Hajar al-Aswad)',
        RitualCounterType.sae => 'Safa',
      };

  String get endPoint => switch (this) {
        RitualCounterType.tawaf => 'Black Stone (Hajar al-Aswad)',
        RitualCounterType.sae => 'Marwah',
      };
}
