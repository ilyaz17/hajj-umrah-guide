import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/data/default_geo_zones.dart';
import 'features/geofencing/domain/geofence_service.dart';
import 'features/ritual_tracker/presentation/bloc/ritual_tracker_bloc.dart';

const _green = Color(0xFF0B5D3B);
const _gold = Color(0xFFD4AF37);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HajjUmrahGuideApp());
}

class HajjUmrahGuideApp extends StatelessWidget {
  const HajjUmrahGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: _green).copyWith(secondary: _gold);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hajj & Umrah Guide',
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      home: BlocProvider(
        create: (_) {
          final bloc = RitualTrackerBloc(geofenceService: GeofenceService());
          bloc.startGeofencing(defaultGeoZones);
          return bloc;
        },
        child: const DashboardScreen(),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(child: Image.asset('assets/branding/hajj_umrah_guide.webp', width: 40, height: 40, fit: BoxFit.cover)),
            const SizedBox(width: 12),
            const Text('Hajj & Umrah Guide'),
          ],
        ),
      ),
      body: BlocBuilder<RitualTrackerBloc, RitualTrackerState>(
        builder: (context, state) {
          final zone = state.activeZone;
          final title = zone?.name ?? 'At Home';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  ClipOval(child: Image.asset('assets/branding/hajj_umrah_guide.webp', width: 72, height: 72, fit: BoxFit.cover)),
                  const SizedBox(width: 16),
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
                ]),
                const SizedBox(height: 12),
                Text(state.message ?? 'Prepare your pilgrimage, browse offline sites, or start a ritual.'),
                if (state.lastDistanceMeters != null) ...[
                  const SizedBox(height: 8),
                  Text('${state.lastDistanceMeters!.round()} m from zone center'),
                ],
              ]))),
              const SizedBox(height: 16),
              Card(child: ListTile(
                title: const Text('Tawaf / Sa’i circuits'),
                subtitle: Text('${state.circuit} of 7 completed'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(onPressed: state.circuit == 0 ? null : () => context.read<RitualTrackerBloc>().add(const DecrementCircuit()), icon: const Icon(Icons.remove)),
                  IconButton(onPressed: state.circuit == 7 ? null : () => context.read<RitualTrackerBloc>().add(const IncrementCircuit()), icon: const Icon(Icons.add)),
                ]),
              )),
              const SizedBox(height: 12),
              const _DashboardAction(icon: Icons.map_outlined, title: 'Sacred Sites Map', subtitle: 'Offline-ready map and saved pins'),
              const _DashboardAction(icon: Icons.explore_outlined, title: 'Qibla & Compass', subtitle: 'Live heading using device sensors'),
              const _DashboardAction(icon: Icons.checklist_rtl, title: 'Ritual Companion', subtitle: 'Follow the validated pilgrimage sequence'),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right)));
}
