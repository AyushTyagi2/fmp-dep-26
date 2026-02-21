import 'package:flutter/material.dart';

class LogsView extends StatelessWidget {
  const LogsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 50,
      itemBuilder: (context, index) {
        final isError = index % 5 == 0;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isError ? Colors.red[50] : Colors.white,
          child: ListTile(
            leading: Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red : Colors.green,
            ),
            title: Text(isError ? "Connection Timeout" : "User Login Success"),
            subtitle: Text("2024-02-17 15:3$index • Server 1"),
            trailing: const Icon(Icons.more_vert),
          ),
        );
      },
    );
  }
}
