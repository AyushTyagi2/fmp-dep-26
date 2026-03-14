import 'package:flutter/material.dart';

class QueueView extends StatelessWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Active Job Queues", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Monitor and manage background processing tasks.", style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Refresh"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _QueueCard(
                title: "Driver Payout Processing",
                queueId: "Q-9482-PAY",
                status: "processing",
                progress: 0.65,
                itemsProcessed: 450,
                totalItems: 690,
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              _QueueCard(
                title: "Daily Backup & Archiving",
                queueId: "Q-9483-BKP",
                status: "queued",
                progress: 0.0,
                itemsProcessed: 0,
                totalItems: 1,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              _QueueCard(
                title: "Invoice Generation (End of Month)",
                queueId: "Q-9480-INV",
                status: "failed",
                progress: 0.4,
                itemsProcessed: 1200,
                totalItems: 3000,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              _QueueCard(
                title: "Geohash Resolution Cache",
                queueId: "Q-9481-GEO",
                status: "completed",
                progress: 1.0,
                itemsProcessed: 5000,
                totalItems: 5000,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QueueCard extends StatelessWidget {
  final String title;
  final String queueId;
  final String status;
  final double progress;
  final int itemsProcessed;
  final int totalItems;
  final Color color;

  const _QueueCard({
    required this.title,
    required this.queueId,
    required this.status,
    required this.progress,
    required this.itemsProcessed,
    required this.totalItems,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    IconData statusIcon = Icons.hourglass_empty;
    if (status == 'processing') statusIcon = Icons.autorenew;
    if (status == 'failed') statusIcon = Icons.error_outline;
    if (status == 'completed') statusIcon = Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: BorderSide(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(queueId, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey.shade800)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                "$itemsProcessed / $totalItems",
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'processing')
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.pause, size: 18),
                  label: const Text("Pause"),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              if (status == 'failed')
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Retry"),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              if (status != 'completed')
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text("Kill"),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          )
        ],
      ),
    );
  }
}