import 'ritual_counter_type.dart';

class CircuitGuidance {
  const CircuitGuidance({
    required this.ritual,
    required this.circuit,
    required this.title,
    required this.sunnah,
    required this.guidance,
    this.arabic,
    this.transliteration,
  });

  final RitualCounterType ritual;
  final int circuit;
  final String title;
  final String sunnah;
  final String guidance;
  final String? arabic;
  final String? transliteration;
}

const _generalTawafDua = CircuitGuidance(
  ritual: RitualCounterType.tawaf,
  circuit: 0,
  title: 'General Tawaf guidance',
  sunnah: 'There is no authentic dua prescribed for each individual Tawaf round.',
  guidance: 'Make dhikr, Qur’an recitation, and personal dua. Between the Yemeni Corner and the Black Stone, the well-known supplication may be recited.',
  arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
  transliteration: 'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina adhab an-nar.',
);

const tawafGuidance = <CircuitGuidance>[
  CircuitGuidance(
    ritual: RitualCounterType.tawaf,
    circuit: 1,
    title: 'Round 1',
    sunnah: 'Begin at the Black Stone and keep the Ka’bah on your left.',
    guidance: 'Say Allahu Akbar when aligning with the Black Stone if possible. Continue with dhikr and personal dua.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.tawaf,
    circuit: 2,
    title: 'Round 2',
    sunnah: 'Continue counter-clockwise around the Ka’bah.',
    guidance: 'There is no fixed dua for this round. Choose authentic dhikr or make personal dua.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.tawaf,
    circuit: 3,
    title: 'Round 3',
    sunnah: 'Maintain calmness and avoid harming or pushing others.',
    guidance: 'There is no fixed dua for this round. Keep the worship focused and avoid blocking the flow of pilgrims.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.tawaf,
    circuit: 4,
    title: 'Round 4',
    sunnah: 'Continue with humility, remembrance, and personal supplication.',
    guidance: 'There is no fixed dua for this round. Recite Qur’an, make dhikr, or ask Allah for what is beneficial.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.tawaf,
    circuit: 5,
    title: 'Round 5',
    sunnah: 'Keep the Ka’bah to your left and complete the circuit without shortcuts through the crowd.',
    guidance: 'There is no fixed dua for this round. Continue your chosen authentic remembrance or personal dua.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.tawaf,
    circuit: 6,
    title: 'Round 6',
    sunnah: 'Continue steadily and preserve the sanctity and safety of fellow pilgrims.',
    guidance: 'There is no fixed dua for this round. Stay present and continue worship calmly.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.tawaf,
    circuit: 7,
    title: 'Round 7',
    sunnah: 'Complete the seventh circuit at the Black Stone.',
    guidance: 'Finish the seventh round, then follow the applicable guidance for prayer at Maqam Ibrahim and the remaining rites.',
  ),
];

const saeGuidance = <CircuitGuidance>[
  CircuitGuidance(
    ritual: RitualCounterType.sae,
    circuit: 1,
    title: 'Journey 1: Safa → Marwah',
    sunnah: 'Begin at Safa and face the Qiblah when making the opening remembrance.',
    guidance: 'Recite the prescribed remembrance at Safa, then make personal dua. Walk toward Marwah.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.sae,
    circuit: 2,
    title: 'Journey 2: Marwah → Safa',
    sunnah: 'Return toward Safa; this counts as the second journey.',
    guidance: 'Make dhikr and personal dua while walking. Do not assign a special dua to this journey.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.sae,
    circuit: 3,
    title: 'Journey 3: Safa → Marwah',
    sunnah: 'Continue the Sa’i route and follow the marked green-light area guidance where applicable.',
    guidance: 'Men may walk briskly between the green markers when safe; women continue at a normal walking pace.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.sae,
    circuit: 4,
    title: 'Journey 4: Marwah → Safa',
    sunnah: 'Keep the journey focused on remembrance and supplication.',
    guidance: 'There is no fixed dua for this journey. Continue dhikr and personal dua.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.sae,
    circuit: 5,
    title: 'Journey 5: Safa → Marwah',
    sunnah: 'Continue the established route without cutting across restricted areas.',
    guidance: 'Maintain a safe pace and continue authentic dhikr or personal supplication.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.sae,
    circuit: 6,
    title: 'Journey 6: Marwah → Safa',
    sunnah: 'This is the sixth journey; keep the direction consistent with the marked path.',
    guidance: 'Continue calmly toward Safa. There is no fixed dua for this journey.',
  ),
  CircuitGuidance(
    ritual: RitualCounterType.sae,
    circuit: 7,
    title: 'Journey 7: Safa → Marwah',
    sunnah: 'Complete the seventh journey at Marwah.',
    guidance: 'After completing Sa’i, follow the applicable guidance for hair trimming or shaving to complete Umrah.',
  ),
];

List<CircuitGuidance> guidanceFor(RitualCounterType ritual) => ritual == RitualCounterType.tawaf ? tawafGuidance : saeGuidance;

CircuitGuidance guidanceForCircuit(RitualCounterType ritual, int circuit) {
  if (circuit < 1 || circuit > 7) return _generalTawafDua;
  return guidanceFor(ritual)[circuit - 1];
}
