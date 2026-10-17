import 'package:flutter/material.dart';
import 'storage/moonveil_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoonveilApp());
}

class MoonveilApp extends StatelessWidget {
  const MoonveilApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Moonveil Universe',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8A75E6),
        brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: const VesperHome(),
  );
}

class VesperHome extends StatefulWidget {
  const VesperHome({super.key});
  @override
  State<VesperHome> createState() => _VesperHomeState();
}

class _VesperHomeState extends State<VesperHome> {
  MoonveilDatabase? _storage;
  Map<String, dynamic>? _checkpoint;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final storage = await MoonveilDatabase.open('vesper');
      final checkpoint = await storage.loadCharacter('vesper-vane');
      if (!mounted) {
        await storage.close();
        return;
      }
      setState(() {
        _storage = storage;
        _checkpoint = checkpoint;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _storage?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Moonveil Universe')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: SelectableText('Database error: $_error'))
            : _checkpoint == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_stories, size: 72),
                    SizedBox(height: 20),
                    Text('Vesper Vane', style: TextStyle(fontSize: 28)),
                    SizedBox(height: 12),
                    Text('No verified checkpoint imported yet. Your existing campaign has not been reset.',
                      textAlign: TextAlign.center),
                  ],
                )
              : ListView(
                  children: [
                    const Icon(Icons.nightlight_round, size: 70),
                    const SizedBox(height: 12),
                    Text('${_checkpoint!['name'] ?? 'Vesper Vane'}',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    for (final field in ['level', 'hp', 'ac', 'xp', 'location'])
                      Card(child: ListTile(
                        title: Text(field.toUpperCase()),
                        subtitle: Text('${_checkpoint![field] ?? 'Not recorded'}'),
                      )),
                  ],
                ),
      ),
    ),
  );
}
