import 'dart:async';
import 'package:flutter/material.dart';
import '../models/copilot_sync_telemetry.dart';
import '../services/copilot_sync_event_bus.dart';
import 'copilot_sync_hud.dart';

class CopilotSyncListener extends StatefulWidget {
  const CopilotSyncListener({super.key, required this.child});
  final Widget child;
  @override
  State<CopilotSyncListener> createState() => _CopilotSyncListenerState();
}

class _CopilotSyncListenerState extends State<CopilotSyncListener> {
  CopilotSyncTelemetry? _telemetry;
  StreamSubscription<CopilotSyncTelemetry>? _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = CopilotSyncEventBus.instance.stream.listen((value) {
      if (mounted) setState(() => _telemetry = value);
    });
  }
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    if (_telemetry != null) CopilotSyncHUD(telemetry: _telemetry!),
    Expanded(child: widget.child),
  ]);
}
