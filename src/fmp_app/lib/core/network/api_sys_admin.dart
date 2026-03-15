import 'package:dio/dio.dart';
import 'package:fmp_app/core/network/api_client.dart';

class ApiSysAdmin {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getActiveUsers() async {
    try {
      final response = await _client.dio.get('/sysadmin/users');
      final usersList = response.data['users'] as List;
      return usersList.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching sysadmin users: $e");
      return [];
    }
  }

  Future<bool> updateUserRole(String id, String role) async {
    try {
      final response = await _client.dio.put('/sysadmin/users/$id/role', data: {'role': role});
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating user role: $e");
      return false;
    }
  }

  Future<bool> toggleUserStatus(String id, bool isActive) async {
    try {
      final response = await _client.dio.put('/sysadmin/users/$id/status', data: {'isActive': isActive});
      return response.statusCode == 200;
    } catch (e) {
      print("Error toggling user status: $e");
      return false;
    }
  }

  Future<bool> resetUserPassword(String id, String newPasswordHash) async {
    try {
      final response = await _client.dio.post('/sysadmin/users/$id/reset-password', data: {'newPasswordHash': newPasswordHash});
      return response.statusCode == 200;
    } catch (e) {
      print("Error resetting user password: $e");
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await _client.dio.delete('/sysadmin/users/$id');
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }
}
