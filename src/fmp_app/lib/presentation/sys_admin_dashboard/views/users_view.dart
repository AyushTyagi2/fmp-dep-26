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
                    hintText: "Search users by name, email, or ID...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.indigo.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.black87), 
                  onPressed: () {}
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 20,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final isDriver = index % 2 == 0;
              final isVerified = index % 3 != 0;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.withOpacity(0.1),
                    child: Text(
                      "U$index", 
                      style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)
                    )
                  ),
                  title: Row(
                    children: [
                      Text("User Name #$index", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDriver ? Colors.blue.shade50 : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isDriver ? "Driver" : "Sender",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDriver ? Colors.blue.shade700 : Colors.purple.shade700,
                          ),
                        ),
                      )
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          isVerified ? Icons.check_circle : Icons.pending, 
                          size: 14, 
                          color: isVerified ? Colors.green : Colors.orange
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVerified ? "Verified User" : "Pending Verification",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$value User #$index")));
                    },
                    itemBuilder: (BuildContext context) {
                      return {'View Profile', 'Suspend Account', 'Delete'}.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(
                            choice, 
                            style: TextStyle(color: choice == 'Delete' ? Colors.red : Colors.black87)
                          ),
                        );
                      }).toList();
                    },
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