import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/ritual_counter_type.dart';
import '../../domain/services/mataf_tracker_service.dart';
import '../bloc/mataf_sae_bloc.dart';

const _green = Color(0xFF0B5D3B);
const _gold = Color(0xFFD4AF37);

class MatafSaeScreen extends StatelessWidget {
  const MatafSaeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MatafSaeBloc(trackerService: MatafTrackerService()),
      child: const _MatafSaeView(),
    );
  }
}

class _MatafSaeView extends StatelessWidget {
  const _MatafSaeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mataf & Sa’i Counter')),
      body: BlocConsumer<MatafSaeBloc, MatafSaeState>(
        listener: (context, state) {
          final error = state.errorMessage;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _RitualSelector(state: state),
              const SizedBox(height: 16),
              _CounterCard(state: state),
              const SizedBox(height: 16),
              _GuidanceCard(state: state),
              const SizedBox(height: 16),
              _DisplayOptions(state: state),
              const SizedBox(height: 16),
              _TelemetryCard(state: state),
              const SizedBox(height: 16),
              _ControlCard(state: state),
              const SizedBox(height: 12),
              const _AccuracyNotice(),
            ],
          );
        },
      ),
    );
  }
}

class _RitualSelector extends StatelessWidget {
  const _RitualSelector({required this.state});
  final MatafSaeState state;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<RitualCounterType>(
      segments: const [
        ButtonSegment(value: RitualCounterType.tawaf, icon: Icon(Icons.sync), label: Text('Tawaf')),
        ButtonSegment(value: RitualCounterType.sae, icon: Icon(Icons.directions_walk), label: Text('Sa’i')),
      ],
      selected: {state.ritual},
      onSelectionChanged: (selection) => context.read<MatafSaeBloc>().add(SelectRitual(selection.first)),
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: _gold.withValues(alpha: 0.75))),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({required this.state});
  final MatafSaeState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MatafSaeBloc>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(state.ritual.label, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _green, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: state.circuit / 7,
                    strokeWidth: 12,
                    backgroundColor: _green.withValues(alpha: 0.12),
                  ),
                ),
                Column(
                  children: [
                    Text('${state.circuit}', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: _green)),
                    const Text('of 7'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              state.circuit == 0 ? 'Ready to begin at ${state.ritual.startPoint}.' : state.complete ? 'Seven completed.' : '${7 - state.circuit} remaining.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: state.circuit == 0 ? null : () => bloc.add(const DecrementCircuit()), icon: const Icon(Icons.remove), label: const Text('Undo'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton.icon(onPressed: state.circuit == 7 ? null : () => bloc.add(const IncrementCircuit()), icon: const Icon(Icons.add), label: const Text('Complete round'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.state});
  final MatafSaeState state;

  @override
  Widget build(BuildContext context) {
    final guidance = state.guidance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_outlined, color: _green),
                const SizedBox(width: 8),
                Expanded(child: Text(guidance.title, style: Theme.of(context).textTheme.titleLarge)),
                if (state.audioEnabled)
                  IconButton(tooltip: 'Play guidance', onPressed: () => context.read<MatafSaeBloc>().add(const SpeakGuidance()), icon: const Icon(Icons.volume_up_outlined)),
              ],
            ),
            const SizedBox(height: 12),
            Text(guidance.sunnah, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(guidance.guidance),
            if (state.showArabic && guidance.arabic != null) ...[
              const Divider(height: 28),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(guidance.arabic!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.8)),
              ),
            ],
            if (state.showTransliteration && guidance.transliteration != null) ...[
              const SizedBox(height: 10),
              Text(guidance.transliteration!, style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisplayOptions extends StatelessWidget {
  const _DisplayOptions({required this.state});
  final MatafSaeState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MatafSaeBloc>();
    return Card(
      child: Column(
        children: [
          SwitchListTile(title: const Text('Arabic'), value: state.showArabic, onChanged: (_) => bloc.add(const ToggleArabic())),
          SwitchListTile(title: const Text('Transliteration'), value: state.showTransliteration, onChanged: (_) => bloc.add(const ToggleTransliteration())),
          SwitchListTile(title: const Text('Audio guidance'), subtitle: const Text('Uses the device text-to-speech engine'), value: state.audioEnabled, onChanged: (_) => bloc.add(const ToggleAudio())),
        ],
      ),
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({required this.state});
  final MatafSaeState state;

  @override
  Widget build(BuildContext context) {
    final heading = state.headingDegrees;
    final location = state.latitude == null ? 'Waiting for GPS…' : '${state.latitude!.toStringAsFixed(5)}, ${state.longitude!.toStringAsFixed(5)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.explore_outlined, color: _green), const SizedBox(width: 8), Text('Live movement assist', style: Theme.of(context).textTheme.titleMedium)]),
            const SizedBox(height: 12),
            _MetricRow(label: 'Heading', value: heading == null ? '—' : '${heading.round()}°'),
            _MetricRow(label: 'GPS distance tracked', value: '${state.distanceMeters.round()} m'),
            _MetricRow(label: 'Last GPS movement', value: '${state.lastDeltaMeters.toStringAsFixed(1)} m'),
            _MetricRow(label: 'Location', value: location),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]),
      );
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({required this.state});
  final MatafSaeState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MatafSaeBloc>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(child: FilledButton.icon(onPressed: state.tracking ? null : () => bloc.add(const StartTracking()), icon: const Icon(Icons.my_location), label: const Text('Start GPS'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: state.tracking ? () => bloc.add(const StopTracking()) : () => bloc.add(const ResetCircuit()), icon: Icon(state.tracking ? Icons.stop : Icons.restart_alt), label: Text(state.tracking ? 'Stop GPS' : 'Reset'))),
          ],
        ),
      ),
    );
  }
}

class _AccuracyNotice extends StatelessWidget {
  const _AccuracyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _gold.withValues(alpha: 0.12),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
      ),
      child: const Text(
        'GPS and compass readings are assistive only. They can drift indoors and around the Ka’bah. The counter never auto-completes a Tawaf or Sa’i journey; confirm each completed journey yourself.',
      ),
    );
  }
}
