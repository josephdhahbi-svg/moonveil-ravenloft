import 'package:shared_preferences/shared_preferences.dart';
import 'moonveil_encounter_codec.dart';
import 'moonveil_encounter_engine.dart';

/// Explicit opt-in encounter checkpoint storage, isolated from character DBs.
/// Keys are campaign scoped; this class never opens or writes SQLite.
class MoonveilEncounterStore {
  const MoonveilEncounterStore(this.campaignId);
  final String campaignId;

  String get key {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(campaignId)) {
      throw ArgumentError.value(campaignId, 'campaignId', 'Invalid campaign');
    }
    return 'moonveil.encounters.v1.$campaignId';
  }

  Future<void> save(MoonveilEncounter encounter) async {
    final data = MoonveilEncounterCodec.encode(encounter);
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(key, data)) {
      throw StateError('Encounter checkpoint could not be saved');
    }
  }

  Future<MoonveilEncounter?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final data = preferences.getString(key);
    if (data == null) return null;
    return MoonveilEncounterCodec.decode(data);
  }

  Future<bool> hasCheckpoint() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.containsKey(key);
  }

  Future<void> deleteCheckpoint() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.remove(key)) {
      throw StateError('Encounter checkpoint could not be deleted');
    }
  }
}
