import 'package:flutter/material.dart';

class LogsView extends StatelessWidget {
  const LogsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.white,
          child: Row(
            children: [
              // FIX 2: Wrapped chips in an Expanded + SingleChildScrollView to prevent overflow
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const _FilterChip(label: "All Logs", isSelected: true),
                      const SizedBox(width: 8),
                      const _FilterChip(label: "Errors", isSelected: false),
                      const SizedBox(width: 8),
                      const _FilterChip(label: "Warnings", isSelected: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.download, size: 18),
                label: const Text("Export"),
                style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                onPressed: () {},
              )
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 50,
            itemBuilder: (context, index) {
              final isError = index % 7 == 0;
              final isWarning = index % 5 == 0 && !isError;
              
              Color statusColor = Colors.blue;
              Color bgColor = Colors.blue.shade50;
              IconData icon = Icons.info_outline;
              String title = "User Login Success";
              
              if (isError) {
                statusColor = Colors.red;
                bgColor = Colors.red.shade50;
                icon = Icons.error_outline;
                title = "Database Connection Timeout";
              } else if (isWarning) {
                statusColor = Colors.orange;
                bgColor = Colors.orange.shade50;
                icon = Icons.warning_amber;
                title = "High API Latency Detected";
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: bgColor, // FIX 1: Applied your calculated background color here!
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                // FIX 3: Used IntrinsicHeight and CrossAxisAlignment.stretch so the colored bar expands dynamically
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12), 
                            bottomLeft: Radius.circular(12)
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(icon, color: statusColor, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "15:3$index:04 PST", 
                                    style: TextStyle(
                                      fontFamily: 'monospace', 
                                      color: Colors.grey.shade500, 
                                      fontSize: 12
                                    )
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isError ? "Connection refused by target machine 192.168.1.$index" 
                                  : isWarning ? "Response time degraded to 2.4s for endpoint /api/v1/drivers" 
                                  : "Auth token issued for user ID ${400 + index} from IP 10.0.0.$index",
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _Tag(text: "Server-0${(index % 3) + 1}"),
                                  const SizedBox(width: 8),
                                  _Tag(text: isError ? "db-cluster" : isWarning ? "gateway" : "auth-service"),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.indigo : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontFamily: 'monospace'),
      ),
    );
  }
}