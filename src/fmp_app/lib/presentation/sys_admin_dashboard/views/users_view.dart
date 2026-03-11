import 'package:flutter/material.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search users...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: 20,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(child: Text("U$index")),
                title: Text("User Name #$index"),
                subtitle: Text(index % 2 == 0 ? "Driver • Verified" : "Sender • Pending"),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$value User #$index")));
                  },
                  itemBuilder: (BuildContext context) {
                    return {'View Profile', 'Suspend', 'Delete'}.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}