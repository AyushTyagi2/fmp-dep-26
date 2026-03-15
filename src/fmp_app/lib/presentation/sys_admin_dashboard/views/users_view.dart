import 'package:flutter/material.dart';
import 'package:fmp_app/core/network/api_sys_admin.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final ApiSysAdmin _apiSysAdmin = ApiSysAdmin();
  List<Map<String, dynamic>> _usersList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await _apiSysAdmin.getActiveUsers();
    setState(() {
      _usersList = users;
      _isLoading = false;
    });
  }

  Future<void> _performAction(String action, Map<String, dynamic> user) async {
    final String userId = user['id'];
    
    try {
      if (action == 'Suspend Account' || action == 'Activate Account') {
        final newStatus = action == 'Activate Account';
        final success = await _apiSysAdmin.toggleUserStatus(userId, newStatus);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User status updated successfully")));
          _fetchUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update status")));
        }
      } else if (action == 'Reset Password') {
          final TextEditingController passwordController = TextEditingController();
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter a new password for this user:'),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'New Password'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true), 
                  child: const Text('Reset', style: TextStyle(color: Colors.blue))
                ),
              ],
            ),
          );

          if (confirm == true && passwordController.text.isNotEmpty) {
            // In a real app, hash this before sending if not using HTTPS (or if backend expects hash)
            // Assuming backend expects a raw string and hashes it, or we send a basic pseudo-hash here
            final newHash = passwordController.text; // Simplification for now
            final success = await _apiSysAdmin.resetUserPassword(userId, newHash);
            if (success) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password reset successfully")));
            } else {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to reset password")));
            }
          }
      } else if (action == 'Make SysAdmin' || action == 'Make User') {
        final newRole = action == 'Make SysAdmin' ? 'SYSADMIN' : 'USER';
        final success = await _apiSysAdmin.updateUserRole(userId, newRole);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Role updated successfully")));
           _fetchUsers();
        } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update role")));
        }
      } else if (action == 'Delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this user? This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        
        if (confirm == true) {
          final success = await _apiSysAdmin.deleteUser(userId);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User deleted successfully")));
            _fetchUsers();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete user")));
          }
        }
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
    }
  }

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
                  border: BorderSide(color: Colors.grey.shade200)
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.black87), 
                  onPressed: () {}
                ),
              ),
               const SizedBox(width: 12),
               Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: BorderSide(color: Colors.grey.shade200)
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black87), 
                  onPressed: _fetchUsers
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _usersList.isEmpty 
              ? const Center(child: Text("No users found"))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _usersList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = _usersList[index];
                    final String name = user['name'] ?? 'Unknown User';
                    final String role = user['role'] ?? 'USER';
                    final String status = user['status'] ?? 'Active';
                    final bool isActive = status == 'Active';
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: BorderSide(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "?", 
                            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)
                          )
                        ),
                        title: Row(
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: role == 'SYSADMIN' ? Colors.red.shade50 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: role == 'SYSADMIN' ? Colors.red.shade700 : Colors.blue.shade700,
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
                                isActive ? Icons.check_circle : Icons.cancel, 
                                size: 14, 
                                color: isActive ? Colors.green : Colors.red
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Status: $status | Phone: ${user['phone'] ?? 'N/A'}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) => _performAction(value, user),
                          itemBuilder: (BuildContext context) {
                            return {
                              'View Profile', 
                              isActive ? 'Suspend Account' : 'Activate Account', 
                              role == 'SYSADMIN' ? 'Make User' : 'Make SysAdmin',
                              'Reset Password',
                              'Delete'
                            }.map((String choice) {
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