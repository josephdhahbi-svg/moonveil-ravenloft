import 'package:flutter/material.dart';
import '../services/art_production_service.dart';

/// Displays the production queue, NOT a count of bundled PNG files.
class ArtProductionDashboardScreen extends StatelessWidget {
  const ArtProductionDashboardScreen({super.key, required this.artService});
  final ArtProductionService artService;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Art production queue', style: Theme.of(context).textTheme.titleLarge),
      Text('Approved requests: ${artService.approvedRequestCount} · Reviewed requests: ${artService.reviewedCount}'),
      const Text('Bundled PNG totals require a separate asset audit.'),
      for (final request in artService.queue)
        Card(child: ListTile(
          title: Text(request.title),
          subtitle: Text('${request.category.name} · priority ${request.priority} · ${request.status.name}'),
          trailing: request.assetPath == null
            ? const Icon(Icons.pending_outlined)
            : const Icon(Icons.image_outlined),
        )),
      if (artService.queue.isEmpty)
        const Text('No art requests queued on this device.'),
    ],
  );
}
