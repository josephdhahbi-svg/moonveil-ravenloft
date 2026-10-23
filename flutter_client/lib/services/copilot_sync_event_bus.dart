import 'dart:async';
import '../models/copilot_sync_telemetry.dart';

/// In-process notifications only; does not transmit data to Copilot.
class CopilotSyncEventBus {
  CopilotSyncEventBus._();
  static final instance = CopilotSyncEventBus._();
  final _controller = StreamController<CopilotSyncTelemetry>.broadcast();
  Stream<CopilotSyncTelemetry> get stream => _controller.stream;
  void dispatch(CopilotSyncTelemetry telemetry) {
    if (!_controller.isClosed) _controller.add(telemetry);
  }
}
