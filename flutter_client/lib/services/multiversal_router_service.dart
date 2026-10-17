import 'package:flutter/material.dart';
import '../storage/moonveil_database.dart';

/// Only these campaign partitions may be opened. Never copy save rows across.
class MultiversalRouterService {
  static const sectors = <String, String>{
    'vesper': 'The Barovian Mists',
    'alice': "Alice Z'ress Archives",
  };

  static Future<MoonveilDatabase> openSector(String sector) {
    if (!sectors.containsKey(sector)) {
      throw ArgumentError.value(sector, 'sector', 'Unknown sector');
    }
    return MoonveilDatabase.open(sector);
  }

  static Future<void> showSector(BuildContext context, String sector) async {
    if (!sectors.containsKey(sector)) {
      throw ArgumentError.value(sector, 'sector');
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(sectors[sector]!)),
        body: Center(child: Text(
          sector == 'alice'
              ? 'Reference archive: no playable checkpoint has been verified.'
              : 'Return to Vesper dashboard to continue her saved campaign.',
          textAlign: TextAlign.center,
        )),
      ),
    ));
  }
}
